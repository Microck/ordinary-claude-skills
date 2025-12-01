#Requires -Version 7.0

<#
.SYNOPSIS
    Conflict detection for SpecKit Safe Update Skill.

.DESCRIPTION
    Detects file customizations, upstream changes, and conflicts between versions.
    Provides functions to analyze file states and determine appropriate update actions.

.NOTES
    Module Name: ConflictDetector
    Author: SpecKit Safe Update Team
    Version: 1.0
#>

# Import dependencies
$modulesPath = $PSScriptRoot
Import-Module (Join-Path $modulesPath "HashUtils.psm1") -Force
Import-Module (Join-Path $modulesPath "ManifestManager.psm1") -Force

<#
.SYNOPSIS
    Gets the state of a single file for update analysis.

.DESCRIPTION
    Analyzes a file by comparing its current hash with the original (from manifest)
    and upstream (from new version) hashes. Determines if the file is customized,
    has upstream changes, is conflicted, and what action should be taken.

.PARAMETER FilePath
    Path to the file (relative to project root).

.PARAMETER OriginalHash
    The hash from when the file was originally installed (from manifest).

.PARAMETER UpstreamHash
    The hash from the new upstream version. $null if file was removed upstream.

.PARAMETER IsOfficial
    Whether this is an official SpecKit file.

.OUTPUTS
    Hashtable
    FileState object with properties:
    - Path: File path
    - CurrentHash: Current file hash ($null if file doesn't exist)
    - OriginalHash: Original hash from manifest
    - UpstreamHash: Upstream hash from new version
    - IsCustomized: Whether file differs from original
    - HasUpstreamChanges: Whether upstream version differs from original
    - IsConflict: Whether both customized and has upstream changes
    - IsOfficial: Whether this is an official SpecKit file
    - Action: Recommended action (add/remove/merge/preserve/update/skip)

.EXAMPLE
    $state = Get-FileState -FilePath ".claude/commands/plan.md" `
                            -OriginalHash "sha256:ABC..." `
                            -UpstreamHash "sha256:DEF..." `
                            -IsOfficial $true

.NOTES
    Action Logic:
    - add: File doesn't exist locally but exists upstream (new file)
    - remove: File exists locally but removed upstream (and not customized)
    - preserve: File is customized (keep user's version)
    - merge: File is customized AND has upstream changes (conflict)
    - update: File not customized but has upstream changes
    - skip: No changes detected
#>
function Get-FileState {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter()]
        [AllowNull()]
        [string]$OriginalHash,

        [Parameter()]
        [AllowNull()]
        [string]$UpstreamHash,

        [Parameter(Mandatory)]
        [bool]$IsOfficial
    )

    try {
        Write-Verbose "Analyzing file state: $FilePath"

        # Compute current hash if file exists
        $currentHash = if (Test-Path $FilePath -PathType Leaf) {
            Get-NormalizedHash -FilePath $FilePath
        } else {
            $null
        }

        # Determine states
        $isCustomized = if ($currentHash -and $OriginalHash) {
            -not (Compare-FileHashes -Hash1 $currentHash -Hash2 $OriginalHash)
        } else {
            $false
        }

        $hasUpstreamChanges = if ($OriginalHash -and $UpstreamHash) {
            -not (Compare-FileHashes -Hash1 $OriginalHash -Hash2 $UpstreamHash)
        } elseif (-not $OriginalHash -and $UpstreamHash) {
            # New file in upstream
            $true
        } elseif ($OriginalHash -and -not $UpstreamHash) {
            # File removed in upstream
            $true
        } else {
            $false
        }

        $isConflict = $isCustomized -and $hasUpstreamChanges

        # Determine action
        $action = if (-not $currentHash) {
            # File doesn't exist locally
            if ($UpstreamHash) {
                'add'  # New file from upstream
            } else {
                'skip'  # File doesn't exist anywhere
            }
        }
        elseif (-not $UpstreamHash) {
            # File removed upstream
            if ($isCustomized) {
                'preserve'  # Keep customized version
            } else {
                'remove'  # Remove unmodified file
            }
        }
        elseif ($isConflict) {
            'merge'  # Both modified - requires manual merge
        }
        elseif ($isCustomized) {
            'preserve'  # User modified, no upstream change
        }
        elseif ($hasUpstreamChanges) {
            'update'  # Not modified, upstream changed
        }
        else {
            'skip'  # No changes
        }

        Write-Verbose "  Current: $($currentHash ? ($currentHash.Length -gt 15 ? $currentHash.Substring(0, 15) + '...' : $currentHash) : 'missing')"
        Write-Verbose "  Original: $($OriginalHash ? ($OriginalHash.Length -gt 15 ? $OriginalHash.Substring(0, 15) + '...' : $OriginalHash) : 'none')"
        Write-Verbose "  Upstream: $($UpstreamHash ? ($UpstreamHash.Length -gt 15 ? $UpstreamHash.Substring(0, 15) + '...' : $UpstreamHash) : 'none')"
        Write-Verbose "  Customized: $isCustomized | Upstream Changes: $hasUpstreamChanges | Action: $action"

        return @{
            Path = $FilePath
            CurrentHash = $currentHash
            OriginalHash = $OriginalHash
            UpstreamHash = $UpstreamHash
            IsCustomized = $isCustomized
            HasUpstreamChanges = $hasUpstreamChanges
            IsConflict = $isConflict
            IsOfficial = $IsOfficial
            Action = $action
        }
    }
    catch {
        throw "Failed to get file state for '$FilePath': $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Gets the state of all tracked files in the manifest.

.DESCRIPTION
    Analyzes all files tracked in the manifest plus any new files in upstream templates.
    For each file, computes the current hash and compares with original and upstream
    to determine the appropriate update action.

.PARAMETER Manifest
    The manifest object from Get-SpecKitManifest.

.PARAMETER UpstreamTemplates
    Hashtable of upstream template files (path => content string).

.OUTPUTS
    Array of FileState hashtables (from Get-FileState).

.EXAMPLE
    $manifest = Get-SpecKitManifest
    $upstream = Download-SpecKitTemplates -Version "v0.0.72"
    $states = Get-AllFileStates -Manifest $manifest -UpstreamTemplates $upstream

.NOTES
    Creates temporary files to hash upstream content.
    Handles both tracked files and new upstream files.
#>
function Get-AllFileStates {
    [CmdletBinding()]
    [OutputType([hashtable[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [PSCustomObject]$Manifest,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]$UpstreamTemplates
    )

    try {
        Write-Verbose "Analyzing all file states"
        $fileStates = @()
        $processedPaths = @{}

        # Create temp directory for upstream content hashing
        $tempDir = Join-Path $env:TEMP "speckit-upstream-$(Get-Random)"
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

        try {
            # Check tracked files
            foreach ($trackedFile in $Manifest.tracked_files) {
                Write-Verbose "Processing tracked file: $($trackedFile.path)"

                # Get upstream hash if file exists in upstream
                $upstreamHash = $null
                if ($UpstreamTemplates.ContainsKey($trackedFile.path)) {
                    # Write upstream content to temp file to hash it
                    $tempFile = Join-Path $tempDir "temp-$(Get-Random).txt"
                    $UpstreamTemplates[$trackedFile.path] | Set-Content -Path $tempFile -Encoding utf8 -Force
                    $upstreamHash = Get-NormalizedHash -FilePath $tempFile
                    Remove-Item $tempFile -Force
                }

                $state = Get-FileState `
                    -FilePath $trackedFile.path `
                    -OriginalHash $trackedFile.original_hash `
                    -UpstreamHash $upstreamHash `
                    -IsOfficial $trackedFile.is_official

                $fileStates += $state
                $processedPaths[$trackedFile.path] = $true
            }

            # Check for new files in upstream (not in manifest)
            foreach ($upstreamPath in $UpstreamTemplates.Keys) {
                if (-not $processedPaths.ContainsKey($upstreamPath)) {
                    Write-Verbose "Processing new upstream file: $upstreamPath"

                    # Write upstream content to temp file to hash it
                    $tempFile = Join-Path $tempDir "temp-$(Get-Random).txt"
                    $UpstreamTemplates[$upstreamPath] | Set-Content -Path $tempFile -Encoding utf8 -Force
                    $upstreamHash = Get-NormalizedHash -FilePath $tempFile
                    Remove-Item $tempFile -Force

                    # New file: no original hash
                    $state = Get-FileState `
                        -FilePath $upstreamPath `
                        -OriginalHash $null `
                        -UpstreamHash $upstreamHash `
                        -IsOfficial $true

                    $fileStates += $state
                }
            }

            Write-Verbose "Analyzed $($fileStates.Count) files"
            return $fileStates
        }
        finally {
            # Cleanup temp directory
            if (Test-Path $tempDir) {
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    catch {
        throw "Failed to get all file states: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Tests if a file has been customized from its original state.

.DESCRIPTION
    Simple wrapper that computes the current normalized hash and compares it
    to the original hash from the manifest.

.PARAMETER FilePath
    Path to the file to check.

.PARAMETER OriginalHash
    The original hash from when the file was installed (from manifest).

.OUTPUTS
    Boolean
    $true if file is customized (hash differs), $false otherwise.

.EXAMPLE
    $isCustomized = Test-FileCustomized -FilePath ".claude/commands/plan.md" `
                                         -OriginalHash "sha256:ABC..."

.NOTES
    Returns $false if file doesn't exist or if OriginalHash is null/empty.
#>
function Test-FileCustomized {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter()]
        [AllowNull()]
        [string]$OriginalHash
    )

    try {
        # If no original hash, can't determine customization
        if (-not $OriginalHash) {
            Write-Verbose "No original hash provided for $FilePath"
            return $false
        }

        # If file doesn't exist, not customized
        if (-not (Test-Path $FilePath -PathType Leaf)) {
            Write-Verbose "File does not exist: $FilePath"
            return $false
        }

        # Compute current hash and compare
        $currentHash = Get-NormalizedHash -FilePath $FilePath
        $isCustomized = -not (Compare-FileHashes -Hash1 $currentHash -Hash2 $OriginalHash)

        Write-Verbose "$FilePath is $(if ($isCustomized) { 'customized' } else { 'not customized' })"
        return $isCustomized
    }
    catch {
        throw "Failed to test if file is customized '$FilePath': $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Finds custom (non-official) command files.

.DESCRIPTION
    Scans the .claude/commands/ directory for *.md files and filters out
    official SpecKit commands, returning only custom user-created commands.

.PARAMETER ProjectRoot
    The root directory of the SpecKit project.

.PARAMETER OfficialCommands
    Array of official command filenames (e.g., "speckit.plan.md").

.OUTPUTS
    String[]
    Array of custom command filenames.

.EXAMPLE
    $official = @("speckit.plan.md", "speckit.specify.md")
    $custom = Find-CustomCommands -ProjectRoot $PWD -OfficialCommands $official

.NOTES
    Returns empty array if .claude/commands/ doesn't exist.
    Only scans for *.md files.
#>
function Find-CustomCommands {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ProjectRoot,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]]$OfficialCommands
    )

    try {
        $commandsDir = Join-Path $ProjectRoot ".claude/commands"

        Write-Verbose "Scanning for custom commands in: $commandsDir"

        if (-not (Test-Path $commandsDir -PathType Container)) {
            Write-Verbose "Commands directory does not exist"
            return @()
        }

        $customCommands = Get-ChildItem $commandsDir -Filter "*.md" -File | Where-Object {
            $OfficialCommands -notcontains $_.Name
        } | ForEach-Object {
            $_.Name
        }

        Write-Verbose "Found $($customCommands.Count) custom commands"
        return @($customCommands)
    }
    catch {
        throw "Failed to find custom commands: $($_.Exception.Message)"
    }
}

# Export module members
Export-ModuleMember -Function @(
    'Get-FileState',
    'Get-AllFileStates',
    'Test-FileCustomized',
    'Find-CustomCommands'
)
