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

# Dependencies: HashUtils, ManifestManager
# All module imports are managed by the orchestrator script (update-orchestrator.ps1)
# Do NOT add Import-Module statements here - they create scope isolation issues

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
        [bool]$IsOfficial,

        [Parameter()]
        [bool]$ManifestCustomized = $false
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
        # Trust the manifest's customized flag if set, otherwise compare hashes
        $isCustomized = if ($ManifestCustomized) {
            # Manifest explicitly marks this as customized (e.g., from -AssumeAllCustomized)
            $true
        } elseif ($currentHash -and $OriginalHash) {
            # Compare current vs original hash
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
        [hashtable]$UpstreamTemplates,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ProjectRoot
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

                # Construct absolute path for file operations
                $absolutePath = Join-Path $ProjectRoot $trackedFile.path

                $state = Get-FileState `
                    -FilePath $absolutePath `
                    -OriginalHash $trackedFile.original_hash `
                    -UpstreamHash $upstreamHash `
                    -IsOfficial $trackedFile.is_official `
                    -ManifestCustomized $trackedFile.customized

                # Replace absolute path with relative path in the state for consistency
                $state.path = $trackedFile.path

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

                    # Construct absolute path for file operations
                    $absolutePath = Join-Path $ProjectRoot $upstreamPath

                    # New file: no original hash
                    $state = Get-FileState `
                        -FilePath $absolutePath `
                        -OriginalHash $null `
                        -UpstreamHash $upstreamHash `
                        -IsOfficial $true

                    # Replace absolute path with relative path in the state for consistency
                    $state.path = $upstreamPath

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

function Build-DiffSection {
    param(
        [hashtable]$Section,
        [array]$CurrentLines,
        [array]$IncomingLines,
        [int]$ContextLines
    )

    if ($Section.CurrentLines.Count -gt 0) {
        $currentStart = $Section.CurrentLines[0]
        $currentEnd = $Section.CurrentLines[-1]
    } else {
        $currentStart = 1
        $currentEnd = 0
    }

    if ($Section.IncomingLines.Count -gt 0) {
        $incomingStart = $Section.IncomingLines[0]
        $incomingEnd = $Section.IncomingLines[-1]
    } else {
        $incomingStart = 1
        $incomingEnd = 0
    }

    $currentStartWithContext = [Math]::Max(1, $currentStart - $ContextLines)
    $currentEndWithContext = [Math]::Min($CurrentLines.Count, $currentEnd + $ContextLines)
    $incomingStartWithContext = [Math]::Max(1, $incomingStart - $ContextLines)
    $incomingEndWithContext = [Math]::Min($IncomingLines.Count, $incomingEnd + $ContextLines)

    if ($currentEndWithContext -gt 0 -and $CurrentLines.Count -gt 0) {
        $startIdx = $currentStartWithContext - 1
        $endIdx = $currentEndWithContext - 1
        $currentContent = ($CurrentLines[$startIdx..$endIdx]) -join "`n"
    } else {
        $currentContent = ""
    }

    if ($incomingEndWithContext -gt 0 -and $IncomingLines.Count -gt 0) {
        $startIdx = $incomingStartWithContext - 1
        $endIdx = $incomingEndWithContext - 1
        $incomingContent = ($IncomingLines[$startIdx..$endIdx]) -join "`n"
    } else {
        $incomingContent = ""
    }

    return @{
        SectionNumber = $Section.SectionNumber
        CurrentStartLine = $currentStartWithContext
        CurrentEndLine = $currentEndWithContext
        IncomingStartLine = $incomingStartWithContext
        IncomingEndLine = $incomingEndWithContext
        CurrentContent = $currentContent
        IncomingContent = $incomingContent
        ChangeType = $Section.ChangeType
    }
}

function Get-UnchangedRanges {
    param(
        [int]$TotalLines,
        [array]$DiffSections
    )

    $result = @()
    $lastEnd = 0

    $sorted = $DiffSections | Sort-Object -Property CurrentStartLine

    foreach ($sec in $sorted) {
        $start = $lastEnd + 1
        $end = $sec.CurrentStartLine - 1

        if ($end -ge $start) {
            $range = @{
                StartLine = $start
                EndLine = $end
                LineCount = $end - $start + 1
                Description = $null
            }
            $result += $range
        }

        $lastEnd = $sec.CurrentEndLine
    }

    if ($lastEnd -lt $TotalLines) {
        $range = @{
            StartLine = $lastEnd + 1
            EndLine = $TotalLines
            LineCount = $TotalLines - $lastEnd
            Description = $null
        }
        $result += $range
    }

    return $result
}

<#
.SYNOPSIS
    Compares two file contents and returns changed sections with line numbers.

.DESCRIPTION
    Uses PowerShell's Compare-Object to find differences between two file versions.
    Groups consecutive changed lines into logical sections (DiffSection entities).
    Identifies unchanged line ranges (UnchangedRange entities).
    Returns a ComparisonResult hashtable with all comparison data.

.PARAMETER CurrentContent
    The current file content (user's version). Must be normalized.

.PARAMETER IncomingContent
    The incoming file content from upstream (new version). Must be normalized.

.PARAMETER ContextLines
    Number of context lines to include before/after each changed section.
    Default: 3 (matches Git diff standard).

.EXAMPLE
    $result = Compare-FileSections -CurrentContent $current -IncomingContent $incoming

.OUTPUTS
    [hashtable] ComparisonResult with keys: Metadata, DiffSections, UnchangedRanges, TotalChangedLines, TotalUnchangedLines
#>
function Compare-FileSections {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$CurrentContent,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$IncomingContent,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 10)]
        [int]$ContextLines = 3
    )

    try {
        Write-Verbose "Comparing file sections with $ContextLines context lines"

        # Split into line arrays
        $currentLines = if ($CurrentContent) { $CurrentContent -split "`n" } else { @() }
        $incomingLines = if ($IncomingContent) { $IncomingContent -split "`n" } else { @() }

        Write-Verbose "  Current: $($currentLines.Count) lines"
        Write-Verbose "  Incoming: $($incomingLines.Count) lines"

        # Handle empty files
        if ($currentLines.Count -eq 0 -and $incomingLines.Count -eq 0) {
            return @{
                Metadata = @{ FileSize = 0 }
                DiffSections = @()
                UnchangedRanges = @()
                TotalChangedLines = 0
                TotalUnchangedLines = 0
            }
        }

        # Build hash map for quick line lookup
        $currentHash = @{}
        for ($i = 0; $i -lt $currentLines.Count; $i++) {
            $line = $currentLines[$i]
            if (-not $currentHash.ContainsKey($line)) {
                $currentHash[$line] = @()
            }
            $currentHash[$line] += $i + 1
        }

        # Identify changed line ranges
        $changedRanges = @()
        $inSection = $false
        $sectionStart = -1

        for ($i = 0; $i -lt $incomingLines.Count; $i++) {
            $lineNum = $i + 1
            $line = $incomingLines[$i]

            # Check if this line exists in current at the same position
            $isDifferent = $true
            if ($i -lt $currentLines.Count -and $currentLines[$i] -eq $line) {
                $isDifferent = $false
            }

            if ($isDifferent) {
                if (-not $inSection) {
                    $sectionStart = $lineNum
                    $inSection = $true
                }
            } else {
                if ($inSection) {
                    $changedRanges += @{
                        Start = $sectionStart
                        End = $lineNum - 1
                    }
                    $inSection = $false
                }
            }
        }

        # Close final section if needed
        if ($inSection) {
            $changedRanges += @{
                Start = $sectionStart
                End = $incomingLines.Count
            }
        }

        # Build diff sections with context
        $diffSections = @()
        $sectionNumber = 1

        foreach ($range in $changedRanges) {
            $currentStart = [Math]::Max(1, $range.Start - $ContextLines)
            $currentEnd = [Math]::Min($currentLines.Count, $range.End + $ContextLines)
            $incomingStart = [Math]::Max(1, $range.Start - $ContextLines)
            $incomingEnd = [Math]::Min($incomingLines.Count, $range.End + $ContextLines)

            if ($currentEnd -gt 0 -and $currentLines.Count -gt 0) {
                $startIdx = $currentStart - 1
                $endIdx = $currentEnd - 1
                $currentContent = ($currentLines[$startIdx..$endIdx]) -join "`n"
            } else {
                $currentContent = ""
            }

            if ($incomingEnd -gt 0 -and $incomingLines.Count -gt 0) {
                $startIdx = $incomingStart - 1
                $endIdx = $incomingEnd - 1
                $incomingContent = ($incomingLines[$startIdx..$endIdx]) -join "`n"
            } else {
                $incomingContent = ""
            }

            $diffSections += @{
                SectionNumber = $sectionNumber
                CurrentStartLine = $currentStart
                CurrentEndLine = $currentEnd
                IncomingStartLine = $incomingStart
                IncomingEndLine = $incomingEnd
                CurrentContent = $currentContent
                IncomingContent = $incomingContent
                ChangeType = 'Modified'
            }

            $sectionNumber++
        }

        # Identify unchanged ranges (inverse of diff sections)
        $unchangedRanges = Get-UnchangedRanges -TotalLines $currentLines.Count -DiffSections $diffSections

        $totalChangedLines = ($diffSections | ForEach-Object {
            ($_.CurrentEndLine - $_.CurrentStartLine + 1)
        } | Measure-Object -Sum).Sum ?? 0

        $totalUnchangedLines = ($unchangedRanges | ForEach-Object {
            $_.LineCount
        } | Measure-Object -Sum).Sum ?? 0

        Write-Verbose "  Diff sections: $($diffSections.Count)"
        Write-Verbose "  Unchanged ranges: $($unchangedRanges.Count)"
        Write-Verbose "  Changed lines: $totalChangedLines, Unchanged lines: $totalUnchangedLines"

        return @{
            Metadata = @{ FileSize = $currentLines.Count }
            DiffSections = $diffSections
            UnchangedRanges = $unchangedRanges
            TotalChangedLines = $totalChangedLines
            TotalUnchangedLines = $totalUnchangedLines
        }
    }
    catch {
        throw "Failed to compare file sections: $($_.Exception.Message)"
    }
}

function Write-ConflictMarkers {
    <#
    .SYNOPSIS
        Writes Git-style conflict markers to a file for VSCode native conflict resolution.

    .DESCRIPTION
        Creates a file with Git-style 3-way merge conflict markers containing:
        - Current version (user's local modifications)
        - Base version (original from manifest)
        - Incoming version (new upstream version)

        VSCode automatically detects these markers and displays CodeLens actions
        for conflict resolution (Accept Current, Accept Incoming, Accept Both, Compare).

    .PARAMETER FilePath
        Target file path to write conflict markers to (absolute or relative to current directory).

    .PARAMETER CurrentContent
        User's local version content.

    .PARAMETER BaseContent
        Original version content from manifest.

    .PARAMETER IncomingContent
        New upstream version content.

    .PARAMETER OriginalVersion
        Original SpecKit version label (e.g., "v0.0.71").

    .PARAMETER NewVersion
        New SpecKit version label (e.g., "v0.0.72").

    .OUTPUTS
        None. Writes conflict markers to file.

    .EXAMPLE
        Write-ConflictMarkers -FilePath ".claude/commands/speckit.plan.md" `
                              -CurrentContent $current -BaseContent $base -IncomingContent $incoming `
                              -OriginalVersion "v0.0.71" -NewVersion "v0.0.72"

    .NOTES
        - Markers must start at column 1 (no indentation) for VSCode recognition
        - Content is written with UTF-8 encoding
        - Line endings are normalized to CRLF on Windows, LF on Unix
        - If incoming content contains conflict marker syntax, it should be escaped (future enhancement)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,

        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$CurrentContent,

        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$BaseContent,

        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$IncomingContent,

        [Parameter(Mandatory=$true)]
        [string]$OriginalVersion,

        [Parameter(Mandatory=$true)]
        [string]$NewVersion
    )

    try {
        Write-Verbose "Writing conflict markers to: $FilePath"

        # Construct 3-way conflict marker block
        # Format matches Git's conflict marker syntax for VSCode recognition
        $conflictBlock = @"
<<<<<<< Current (Your Version)
$CurrentContent
||||||| Base ($OriginalVersion)
$BaseContent
=======
$IncomingContent
>>>>>>> Incoming ($NewVersion)
"@

        # Write to file with UTF-8 encoding (no BOM for cross-platform compatibility)
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($FilePath, $conflictBlock, $utf8NoBom)

        Write-Verbose "Conflict markers written successfully"
    }
    catch {
        throw "Failed to write conflict markers to $FilePath`: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Generates a Markdown diff file showing only changed sections.

.DESCRIPTION
    Takes a ComparisonResult hashtable and generates a structured Markdown diff file
    with side-by-side comparison of changed sections. Includes file header, section
    comparisons, and unchanged section summary. Writes to .specify/.tmp-conflicts/
    directory and displays path to user.

.PARAMETER FilePath
    The path to the conflicting file (relative to project root).

.PARAMETER ComparisonResult
    ComparisonResult hashtable from Compare-FileSections with DiffSections and
    UnchangedRanges.

.PARAMETER OriginalVersion
    Version identifier for the current version (e.g., "v0.0.71").

.PARAMETER NewVersion
    Version identifier for the incoming version (e.g., "v0.0.72").

.PARAMETER TmpConflictsDir
    Optional path to temporary conflicts directory. Default: ".specify/.tmp-conflicts"

.EXAMPLE
    Write-SideBySideDiff -FilePath ".specify/templates/tasks-template.md" `
                         -ComparisonResult $comparisonResult `
                         -OriginalVersion "v0.0.71" `
                         -NewVersion "v0.0.72"
#>
function Write-SideBySideDiff {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [hashtable]$ComparisonResult,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OriginalVersion,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NewVersion,

        [Parameter(Mandatory = $false)]
        [string]$TmpConflictsDir = ".specify/.tmp-conflicts"
    )

    try {
        Write-Verbose "Generating side-by-side diff for: $FilePath"

        # Resolve to absolute path and create temp conflicts directory if needed
        $resolvedDir = if ([System.IO.Path]::IsPathRooted($TmpConflictsDir)) {
            $TmpConflictsDir
        } else {
            Join-Path (Get-Location) $TmpConflictsDir
        }

        if (-not (Test-Path $resolvedDir)) {
            New-Item -ItemType Directory -Path $resolvedDir -Force | Out-Null
            Write-Verbose "  Created directory: $resolvedDir"
        }

        $TmpConflictsDir = $resolvedDir

        # Extract filename and determine language hint
        $fileName = Split-Path -Leaf $FilePath
        $extension = [System.IO.Path]::GetExtension($FilePath)
        $languageHint = switch ($extension) {
            '.md'    { 'markdown' }
            '.ps1'   { 'powershell' }
            '.json'  { 'json' }
            '.yaml'  { 'yaml' }
            '.yml'   { 'yaml' }
            default  { '' }
        }

        # Build diff file path
        $diffFileName = "$([System.IO.Path]::GetFileNameWithoutExtension($fileName)).diff.md"
        $diffFilePath = Join-Path $TmpConflictsDir $diffFileName

        Write-Verbose "  Diff file: $diffFilePath"
        Write-Verbose "  Language hint: $languageHint"

        # Build diff content
        $sb = New-Object System.Text.StringBuilder

        # Header
        [void]$sb.AppendLine("# Conflict Resolution: $fileName")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("**Your Version**: $OriginalVersion")
        [void]$sb.AppendLine("**Incoming Version**: $NewVersion")
        [void]$sb.AppendLine("**File Path**: ``$FilePath``")
        [void]$sb.AppendLine("**File Size**: $($ComparisonResult.Metadata.FileSize) lines")
        [void]$sb.AppendLine("**Changed Sections**: $($ComparisonResult.DiffSections.Count)")
        [void]$sb.AppendLine("**Total Changed Lines**: $($ComparisonResult.TotalChangedLines)")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("---")
        [void]$sb.AppendLine("")

        # Changed sections
        foreach ($section in $ComparisonResult.DiffSections) {
            [void]$sb.AppendLine("## Changed Section $($section.SectionNumber)")
            [void]$sb.AppendLine("")
            [void]$sb.AppendLine("### Your Version (Lines $($section.CurrentStartLine)-$($section.CurrentEndLine))")
            [void]$sb.AppendLine("")
            [void]$sb.AppendLine("``````$languageHint")
            [void]$sb.AppendLine($section.CurrentContent)
            [void]$sb.AppendLine("``````")
            [void]$sb.AppendLine("")
            [void]$sb.AppendLine("### Incoming Version (Lines $($section.IncomingStartLine)-$($section.IncomingEndLine))")
            [void]$sb.AppendLine("")
            [void]$sb.AppendLine("``````$languageHint")
            [void]$sb.AppendLine($section.IncomingContent)
            [void]$sb.AppendLine("``````")
            [void]$sb.AppendLine("")
            [void]$sb.AppendLine("---")
            [void]$sb.AppendLine("")
        }

        # Unchanged sections summary
        if ($ComparisonResult.UnchangedRanges.Count -gt 0) {
            [void]$sb.AppendLine("## Unchanged Sections")
            [void]$sb.AppendLine("")
            [void]$sb.AppendLine("The following sections are identical in both versions:")
            [void]$sb.AppendLine("")

            foreach ($range in $ComparisonResult.UnchangedRanges) {
                [void]$sb.AppendLine("- Lines $($range.StartLine)-$($range.EndLine) ($($range.LineCount) lines)")
            }

            [void]$sb.AppendLine("")
            [void]$sb.AppendLine("---")
            [void]$sb.AppendLine("")
        }

        # Footer
        [void]$sb.AppendLine("**Note**: This diff file was automatically generated by the SpecKit Safe Update Skill.")
        [void]$sb.AppendLine("To resolve this conflict, review the changed sections above and manually edit the file")
        [void]$sb.AppendLine("to keep your preferred version or create a hybrid.")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("After resolving, delete this diff file or it will be cleaned up automatically on the")
        [void]$sb.AppendLine("next successful update.")

        # Write file with UTF-8 encoding (no BOM)
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($diffFilePath, $sb.ToString(), $utf8NoBom)

        Write-Host "Review detailed diff: $diffFilePath" -ForegroundColor Cyan
        Write-Verbose "  Diff file written successfully"
    }
    catch {
        throw "Failed to write side-by-side diff: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Writes conflict resolution based on file size (smart diff vs. standard markers).

.DESCRIPTION
    For large files (>100 lines), generates a side-by-side diff file showing only
    changed sections in Markdown format. For small files (≤100 lines), uses standard
    Git conflict markers. Falls back to Git markers on any error.

.PARAMETER FilePath
    The path to the conflicting file (relative to project root).

.PARAMETER CurrentContent
    The current file content (user's version). Must be normalized.

.PARAMETER BaseContent
    The base file content from manifest (original version). May be empty.

.PARAMETER IncomingContent
    The incoming file content from upstream (new version). Must be normalized.

.PARAMETER OriginalVersion
    Version identifier for the base/current version (e.g., "v0.0.71").

.PARAMETER NewVersion
    Version identifier for the incoming version (e.g., "v0.0.72").

.EXAMPLE
    Write-SmartConflictResolution -FilePath ".specify/templates/tasks-template.md" `
                                   -CurrentContent $currentVersion `
                                   -BaseContent $baseVersion `
                                   -IncomingContent $incomingVersion `
                                   -OriginalVersion "v0.0.71" `
                                   -NewVersion "v0.0.72"
#>
function Write-SmartConflictResolution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$CurrentContent,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$BaseContent,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$IncomingContent,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OriginalVersion,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NewVersion
    )

    try {
        Write-Verbose "Analyzing conflict for: $FilePath"

        # Count lines in current content
        $lineCount = if ($CurrentContent) { ($CurrentContent -split "`n").Count } else { 0 }
        Write-Verbose "  File size: $lineCount lines"

        # Decide resolution method based on file size
        if ($lineCount -le 100) {
            Write-Verbose "  Using Git conflict markers (file ≤100 lines)"
            Write-Host "Conflict detected in: $FilePath (using Git markers)" -ForegroundColor Yellow

            Write-ConflictMarkers -FilePath $FilePath `
                                  -CurrentContent $CurrentContent `
                                  -BaseContent $BaseContent `
                                  -IncomingContent $IncomingContent `
                                  -OriginalVersion $OriginalVersion `
                                  -NewVersion $NewVersion
        }
        else {
            Write-Verbose "  Using smart diff generation (file >100 lines)"
            Write-Host "Large file conflict detected in: $FilePath" -ForegroundColor Yellow

            # Generate comparison result
            $comparisonResult = Compare-FileSections -CurrentContent $CurrentContent `
                                                     -IncomingContent $IncomingContent

            # Generate side-by-side diff file
            Write-SideBySideDiff -FilePath $FilePath `
                                 -ComparisonResult $comparisonResult `
                                 -OriginalVersion $OriginalVersion `
                                 -NewVersion $NewVersion
        }
    }
    catch {
        Write-Warning "Diff generation failed: $($_.Exception.Message)"
        Write-Warning "Falling back to standard Git conflict markers"
        Write-Verbose "  Error details: $($_.Exception | Out-String)"

        # Fallback to Git markers
        Write-ConflictMarkers -FilePath $FilePath `
                              -CurrentContent $CurrentContent `
                              -BaseContent $BaseContent `
                              -IncomingContent $IncomingContent `
                              -OriginalVersion $OriginalVersion `
                              -NewVersion $NewVersion
    }
}

function Remove-ConflictDiffFiles {
    <#
    .SYNOPSIS
        Removes temporary conflict diff files after successful update.

    .DESCRIPTION
        Cleans up the .specify/.tmp-conflicts/ directory that contains
        side-by-side diff files generated during conflict resolution.

        This function should ONLY be called after a successful update.
        On rollback, diff files should be preserved for debugging purposes.

    .PARAMETER ProjectRoot
        Path to the SpecKit project root directory.

    .PARAMETER TmpConflictsDir
        Path to the temporary conflicts directory. Defaults to ".specify/.tmp-conflicts".
        Can be absolute or relative to ProjectRoot.

    .EXAMPLE
        Remove-ConflictDiffFiles -ProjectRoot $PWD

        Removes all diff files from .specify/.tmp-conflicts/ directory.

    .EXAMPLE
        Remove-ConflictDiffFiles -ProjectRoot "C:\Projects\MyApp" -TmpConflictsDir ".specify/.tmp-conflicts"

        Removes diff files from the specified directory.

    .NOTES
        - Failures are logged as warnings but do not throw exceptions
        - If directory doesn't exist, function returns successfully (idempotent)
        - Entire .tmp-conflicts directory is removed, not individual files
        - Safe to call multiple times
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $false)]
        [string]$TmpConflictsDir = ".specify/.tmp-conflicts"
    )

    try {
        # Resolve to absolute path
        $resolvedDir = if ([System.IO.Path]::IsPathRooted($TmpConflictsDir)) {
            $TmpConflictsDir
        } else {
            Join-Path $ProjectRoot $TmpConflictsDir
        }

        # Check if directory exists
        if (Test-Path $resolvedDir) {
            Write-Verbose "Removing temporary conflict diff directory: $resolvedDir"

            # Remove entire directory
            Remove-Item -Path $resolvedDir -Recurse -Force -ErrorAction Stop

            Write-Verbose "Successfully removed conflict diff directory"
        } else {
            Write-Verbose "Conflict diff directory does not exist: $resolvedDir (nothing to clean up)"
        }
    }
    catch {
        # Log warning but don't fail the update
        Write-Warning "Failed to clean up conflict diff files: $($_.Exception.Message)"
        Write-Verbose "Cleanup failure is non-fatal - continuing"
    }
}

# Export module members
Export-ModuleMember -Function @(
    'Get-FileState',
    'Get-AllFileStates',
    'Test-FileCustomized',
    'Find-CustomCommands',
    'Write-ConflictMarkers',
    'Compare-FileSections',
    'Write-SideBySideDiff',
    'Write-SmartConflictResolution',
    'Remove-ConflictDiffFiles'
)
