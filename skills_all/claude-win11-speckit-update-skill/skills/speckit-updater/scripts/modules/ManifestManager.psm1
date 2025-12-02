#Requires -Version 7.0

<#
.SYNOPSIS
    Manifest management for SpecKit Safe Update Skill.

.DESCRIPTION
    Provides functions to create, read, update, and manage the SpecKit manifest file
    (.specify/manifest.json) which tracks version information, file hashes, and
    customization state.

.NOTES
    Module Name: ManifestManager
    Author: SpecKit Safe Update Team
    Version: 1.0
#>

# Dependencies: HashUtils, GitHubApiClient
# All module imports are managed by the orchestrator script (update-orchestrator.ps1)
# Do NOT add Import-Module statements here - they create scope isolation issues

# Script-level cache for official commands
$script:OfficialCommandsCache = @{}

<#
.SYNOPSIS
    Gets the SpecKit manifest from a project.

.DESCRIPTION
    Loads and validates the .specify/manifest.json file from the specified project root.
    Returns null if the manifest doesn't exist, or throws if the manifest is corrupted
    or has an unsupported schema version.

.PARAMETER ProjectRoot
    The root directory of the SpecKit project. Defaults to current directory.

.OUTPUTS
    PSCustomObject
    The manifest object, or $null if not found.

.EXAMPLE
    $manifest = Get-SpecKitManifest -ProjectRoot "C:\projects\my-app"
    if ($manifest) {
        Write-Host "Current version: $($manifest.speckit_version)"
    }

.NOTES
    Validates that the manifest schema version is "1.0".
    Throws if the manifest is corrupted or has an unsupported version.
#>
function Get-SpecKitManifest {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [string]$ProjectRoot = $PWD
    )

    $manifestPath = Join-Path $ProjectRoot ".specify/manifest.json"

    if (-not (Test-Path $manifestPath -PathType Leaf)) {
        Write-Verbose "Manifest not found at: $manifestPath"
        return $null
    }

    try {
        $content = Get-Content $manifestPath -Raw -ErrorAction Stop
        $manifest = $content | ConvertFrom-Json -ErrorAction Stop

        # Validate schema version
        if (-not $manifest.version) {
            throw "Manifest is missing required 'version' field"
        }

        if ($manifest.version -ne "1.0") {
            throw "Unsupported manifest schema version: $($manifest.version). Expected version 1.0"
        }

        Write-Verbose "Loaded manifest from: $manifestPath"
        return $manifest
    }
    catch {
        throw "Failed to load manifest from '$manifestPath': $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Creates a new SpecKit manifest file.

.DESCRIPTION
    Scans the .specify/ and .claude/commands/ directories, computes hashes for all files,
    and creates a new manifest.json file. Can optionally mark all files as customized
    (safe default for existing projects).

.PARAMETER ProjectRoot
    The root directory of the SpecKit project. Defaults to current directory.

.PARAMETER Version
    The SpecKit version tag (e.g., "v0.0.72") to associate with this manifest.

.PARAMETER AssumeAllCustomized
    If specified, marks all tracked files as customized. This is the safe default
    for existing projects to prevent accidental overwrites.

.OUTPUTS
    PSCustomObject
    The newly created manifest object.

.EXAMPLE
    New-SpecKitManifest -ProjectRoot $PWD -Version "v0.0.72" -AssumeAllCustomized

.NOTES
    Creates the manifest file at .specify/manifest.json.
    Requires HashUtils and GitHubApiClient modules.
#>
function New-SpecKitManifest {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [string]$ProjectRoot = $PWD,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Version,

        [Parameter()]
        [switch]$AssumeAllCustomized
    )

    try {
        $manifestPath = Join-Path $ProjectRoot ".specify/manifest.json"

        Write-Verbose "Creating new manifest for SpecKit version: $Version"

        # Get official commands for this version
        $officialCommands = Get-OfficialSpecKitCommands -Version $Version

        # Initialize collections
        $trackedFiles = @()
        $customFiles = @()

        # Scan .claude/commands/ directory
        $commandsDir = Join-Path $ProjectRoot ".claude/commands"
        if (Test-Path $commandsDir -PathType Container) {
            Write-Verbose "Scanning commands directory: $commandsDir"

            Get-ChildItem $commandsDir -Filter "*.md" -File | ForEach-Object {
                $relativePath = ".claude/commands/$($_.Name)"
                $hash = Get-NormalizedHash -FilePath $_.FullName
                $isOfficial = $officialCommands -contains $_.Name

                if ($isOfficial) {
                    $trackedFiles += @{
                        path = $relativePath
                        original_hash = $hash
                        customized = $AssumeAllCustomized.IsPresent
                        is_official = $true
                    }
                    Write-Verbose "  Tracked official: $relativePath"
                }
                else {
                    $customFiles += $relativePath
                    Write-Verbose "  Identified custom: $relativePath"
                }
            }
        }

        # Scan .specify/ directory (excluding manifest.json and backups)
        $specifyDir = Join-Path $ProjectRoot ".specify"
        if (Test-Path $specifyDir -PathType Container) {
            Write-Verbose "Scanning .specify directory: $specifyDir"

            Get-ChildItem $specifyDir -Recurse -File | Where-Object {
                $_.Name -ne "manifest.json" -and
                $_.FullName -notlike "*backups*" -and
                $_.FullName -notlike "*.tmp-merge*"
            } | ForEach-Object {
                $relativePath = $_.FullName.Substring($ProjectRoot.Length + 1) -replace '\\', '/'
                $hash = Get-NormalizedHash -FilePath $_.FullName

                $trackedFiles += @{
                    path = $relativePath
                    original_hash = $hash
                    customized = $AssumeAllCustomized.IsPresent
                    is_official = $true
                }
                Write-Verbose "  Tracked: $relativePath"
            }
        }

        # Create manifest object
        $now = (Get-Date).ToUniversalTime().ToString("o")
        $manifest = @{
            version = "1.0"
            speckit_version = $Version
            initialized_at = $now
            last_updated = $now
            agent = "claude-code"
            speckit_commands = $officialCommands
            tracked_files = $trackedFiles
            custom_files = $customFiles
            backup_history = @()
        }

        # Save manifest
        $manifestJson = $manifest | ConvertTo-Json -Depth 10
        Set-Content -Path $manifestPath -Value $manifestJson -Encoding utf8 -Force

        Write-Verbose "Manifest created at: $manifestPath"
        Write-Verbose "  Tracked files: $($trackedFiles.Count)"
        Write-Verbose "  Custom files: $($customFiles.Count)"

        # Return the loaded manifest
        return Get-SpecKitManifest -ProjectRoot $ProjectRoot
    }
    catch {
        throw "Failed to create manifest: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Gets the list of official SpecKit command filenames for a version.

.DESCRIPTION
    Fetches the official command list from GitHub by downloading the templates
    and extracting command filenames. Results are cached for performance.
    Falls back to a hardcoded list if GitHub is unavailable.

.PARAMETER Version
    The SpecKit version tag (e.g., "v0.0.72").

.OUTPUTS
    String[]
    Array of official command filenames (e.g., "speckit.plan.md").

.EXAMPLE
    $commands = Get-OfficialSpecKitCommands -Version "v0.0.72"

.NOTES
    Uses script-level cache to avoid repeated downloads.
    Fallback list is used if GitHub API is unavailable.
#>
function Get-OfficialSpecKitCommands {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Version
    )

    # Check cache
    if ($script:OfficialCommandsCache.ContainsKey($Version)) {
        Write-Verbose "Using cached official commands for version: $Version"
        return $script:OfficialCommandsCache[$Version]
    }

    # For placeholder version (v0.0.0), skip GitHub and use fallback immediately
    if ($Version -eq "v0.0.0") {
        Write-Verbose "Placeholder version detected, using fallback command list"
        $fallbackCommands = @(
            "speckit.constitution.md",
            "speckit.specify.md",
            "speckit.clarify.md",
            "speckit.plan.md",
            "speckit.tasks.md",
            "speckit.implement.md",
            "speckit.analyze.md",
            "speckit.checklist.md"
        )
        $script:OfficialCommandsCache[$Version] = $fallbackCommands
        return $fallbackCommands
    }

    try {
        Write-Verbose "Fetching official commands from GitHub for version: $Version"

        # Download templates to temporary location
        $tempDir = Join-Path $env:TEMP "speckit-manifest-$(Get-Random)"
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

        try {
            $templates = Download-SpecKitTemplates -Version $Version -DestinationPath $tempDir

            # Extract command filenames from .claude/commands/*.md
            $commands = $templates.Keys | Where-Object {
                $_ -like '.claude/commands/*.md' -or $_ -like 'claude/commands/*.md'
            } | ForEach-Object {
                Split-Path $_ -Leaf
            }

            if ($commands.Count -eq 0) {
                throw "No command files found in templates"
            }

            # Cache result
            $script:OfficialCommandsCache[$Version] = $commands

            Write-Verbose "Found $($commands.Count) official commands"
            return $commands
        }
        finally {
            # Cleanup temp directory
            if (Test-Path $tempDir) {
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    catch {
        # Fallback: known commands as of spec writing
        Write-Warning "Could not fetch official commands from GitHub: $($_.Exception.Message)"
        Write-Warning "Using fallback command list"

        $fallbackCommands = @(
            "speckit.constitution.md",
            "speckit.specify.md",
            "speckit.clarify.md",
            "speckit.plan.md",
            "speckit.tasks.md",
            "speckit.implement.md",
            "speckit.analyze.md",
            "speckit.checklist.md"
        )

        # Cache fallback result too
        $script:OfficialCommandsCache[$Version] = $fallbackCommands

        return $fallbackCommands
    }
}

<#
.SYNOPSIS
    Updates the SpecKit version in the manifest.

.DESCRIPTION
    Updates the speckit_version and last_updated fields in the manifest,
    while preserving all other data.

.PARAMETER ProjectRoot
    The root directory of the SpecKit project. Defaults to current directory.

.PARAMETER NewVersion
    The new SpecKit version tag (e.g., "v0.0.72").

.EXAMPLE
    Update-ManifestVersion -ProjectRoot $PWD -NewVersion "v0.0.72"

.NOTES
    Requires an existing manifest file.
#>
function Update-ManifestVersion {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ProjectRoot = $PWD,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$NewVersion
    )

    try {
        $manifest = Get-SpecKitManifest -ProjectRoot $ProjectRoot

        if (-not $manifest) {
            throw "No manifest found at project root: $ProjectRoot"
        }

        Write-Verbose "Updating manifest version from $($manifest.speckit_version) to $NewVersion"

        # Update fields
        $manifest.speckit_version = $NewVersion
        $manifest.last_updated = (Get-Date).ToUniversalTime().ToString("o")

        # Save manifest
        $manifestPath = Join-Path $ProjectRoot ".specify/manifest.json"
        $manifestJson = $manifest | ConvertTo-Json -Depth 10
        Set-Content -Path $manifestPath -Value $manifestJson -Encoding utf8 -Force

        Write-Verbose "Manifest version updated successfully"
    }
    catch {
        throw "Failed to update manifest version: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Adds a file to the manifest's tracked files list.

.DESCRIPTION
    Appends a new entry to the tracked_files array in the manifest.

.PARAMETER ProjectRoot
    The root directory of the SpecKit project. Defaults to current directory.

.PARAMETER FilePath
    The relative path of the file to track (e.g., ".claude/commands/custom.md").

.PARAMETER Hash
    The normalized hash of the file.

.PARAMETER IsOfficial
    Whether this is an official SpecKit file.

.EXAMPLE
    Add-TrackedFile -ProjectRoot $PWD -FilePath ".claude/commands/new.md" -Hash "sha256:ABC..." -IsOfficial $true

.NOTES
    Checks for duplicates before adding. If file path already exists, logs warning and returns without adding.
#>
function Add-TrackedFile {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ProjectRoot = $PWD,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Hash,

        [Parameter(Mandatory)]
        [bool]$IsOfficial
    )

    try {
        $manifest = Get-SpecKitManifest -ProjectRoot $ProjectRoot

        if (-not $manifest) {
            throw "No manifest found at project root: $ProjectRoot"
        }

        Write-Verbose "Adding tracked file: $FilePath"

        # Check for duplicate before adding
        $existingEntry = $manifest.tracked_files | Where-Object { $_.path -eq $FilePath }
        if ($existingEntry) {
            Write-Warning "File already tracked in manifest: $FilePath (skipping duplicate)"
            return
        }

        # Create new tracked file entry
        $newEntry = @{
            path = $FilePath
            original_hash = $Hash
            customized = $false
            is_official = $IsOfficial
        }

        # Convert to array if needed
        if ($manifest.tracked_files -isnot [System.Array]) {
            $manifest.tracked_files = @($manifest.tracked_files)
        }

        # Append to tracked files
        $manifest.tracked_files = @($manifest.tracked_files) + $newEntry

        # Save manifest
        $manifestPath = Join-Path $ProjectRoot ".specify/manifest.json"
        $manifestJson = $manifest | ConvertTo-Json -Depth 10
        Set-Content -Path $manifestPath -Value $manifestJson -Encoding utf8 -Force

        Write-Verbose "File added to manifest successfully"
    }
    catch {
        throw "Failed to add tracked file: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Removes a file from the manifest's tracked files list.

.DESCRIPTION
    Removes the entry for the specified file path from the tracked_files array.

.PARAMETER ProjectRoot
    The root directory of the SpecKit project. Defaults to current directory.

.PARAMETER FilePath
    The relative path of the file to remove (e.g., ".claude/commands/old.md").

.EXAMPLE
    Remove-TrackedFile -ProjectRoot $PWD -FilePath ".claude/commands/old.md"

.NOTES
    No error if file is not found in the manifest.
#>
function Remove-TrackedFile {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ProjectRoot = $PWD,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath
    )

    try {
        $manifest = Get-SpecKitManifest -ProjectRoot $ProjectRoot

        if (-not $manifest) {
            throw "No manifest found at project root: $ProjectRoot"
        }

        Write-Verbose "Removing tracked file: $FilePath"

        # Filter out the specified file
        $manifest.tracked_files = @($manifest.tracked_files | Where-Object { $_.path -ne $FilePath })

        # Save manifest
        $manifestPath = Join-Path $ProjectRoot ".specify/manifest.json"
        $manifestJson = $manifest | ConvertTo-Json -Depth 10
        Set-Content -Path $manifestPath -Value $manifestJson -Encoding utf8 -Force

        Write-Verbose "File removed from manifest successfully"
    }
    catch {
        throw "Failed to remove tracked file: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Recomputes all file hashes and updates customization flags.

.DESCRIPTION
    Iterates through all tracked files, recomputes their normalized hashes,
    and updates the customized flag by comparing current hash to original hash.

.PARAMETER ProjectRoot
    The root directory of the SpecKit project. Defaults to current directory.

.EXAMPLE
    Update-FileHashes -ProjectRoot $PWD

.NOTES
    This should be called after an update to ensure the manifest accurately
    reflects the current state of all tracked files.
#>
function Update-FileHashes {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ProjectRoot = $PWD
    )

    try {
        $manifest = Get-SpecKitManifest -ProjectRoot $ProjectRoot

        if (-not $manifest) {
            throw "No manifest found at project root: $ProjectRoot"
        }

        Write-Verbose "Updating file hashes for all tracked files"

        $updatedCount = 0

        foreach ($file in $manifest.tracked_files) {
            $fullPath = Join-Path $ProjectRoot $file.path

            if (Test-Path $fullPath -PathType Leaf) {
                # Compute current hash
                $currentHash = Get-NormalizedHash -FilePath $fullPath

                # Update customized flag (compare to original_hash)
                $file.customized = -not (Compare-FileHashes -Hash1 $currentHash -Hash2 $file.original_hash)

                $updatedCount++
                Write-Verbose "  Updated: $($file.path) (customized: $($file.customized))"
            }
            else {
                Write-Warning "Tracked file not found: $($file.path)"
            }
        }

        # Update last_updated timestamp
        $manifest.last_updated = (Get-Date).ToUniversalTime().ToString("o")

        # Save manifest
        $manifestPath = Join-Path $ProjectRoot ".specify/manifest.json"
        $manifestJson = $manifest | ConvertTo-Json -Depth 10
        Set-Content -Path $manifestPath -Value $manifestJson -Encoding utf8 -Force

        Write-Verbose "Updated hashes for $updatedCount files"
    }
    catch {
        throw "Failed to update file hashes: $($_.Exception.Message)"
    }
}

# Export module members
Export-ModuleMember -Function @(
    'Get-SpecKitManifest',
    'New-SpecKitManifest',
    'Get-OfficialSpecKitCommands',
    'Update-ManifestVersion',
    'Add-TrackedFile',
    'Remove-TrackedFile',
    'Update-FileHashes'
)
