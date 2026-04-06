#Requires -Version 7.0

<#
.SYNOPSIS
    SpecKit Safe Update Orchestrator - Main entry point for safe SpecKit updates.

.DESCRIPTION
    Coordinates the complete update workflow:
    1. Validates prerequisites
    2. Handles rollback if requested
    3. Loads or creates manifest
    4. Fetches target version
    5. Analyzes file states
    6. Check-only mode (show report and exit)
    7. Gets user confirmation
    8. Creates backup
    9. Downloads templates
    10. Applies updates (fail-fast)
    11. Handles conflicts (Flow A)
    12. Updates constitution (notify to run /speckit.constitution)
    13. Updates manifest
    14. Cleans up old backups
    15. Shows success summary

.PARAMETER CheckOnly
    Show what would change without applying updates

.PARAMETER Version
    Update to specific release tag (e.g., "v0.0.72" or "0.0.72")

.PARAMETER Force
    Overwrite SpecKit files even if customized (preserves custom commands)

.PARAMETER Rollback
    Restore from previous backup

.PARAMETER NoBackup
    Skip backup creation (dangerous, not recommended)

.PARAMETER Proceed
    Internal flag passed by Claude Code after user approval via conversational workflow

.EXAMPLE
    .\update-orchestrator.ps1 -CheckOnly
    Check for updates without applying changes

.EXAMPLE
    .\update-orchestrator.ps1
    Interactive update with conversational confirmation workflow

.EXAMPLE
    .\update-orchestrator.ps1 -Version v0.0.72
    Update to specific version

.EXAMPLE
    .\update-orchestrator.ps1 -Rollback
    Restore from previous backup
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$CheckOnly,

    [Parameter(Mandatory=$false)]
    [string]$Version,

    [Parameter(Mandatory=$false)]
    [switch]$Force,

    [Parameter(Mandatory=$false)]
    [switch]$Rollback,

    [Parameter(Mandatory=$false)]
    [switch]$NoBackup,

    [Parameter(Mandatory=$false)]
    [switch]$Proceed,

    [Parameter(Mandatory=$false)]
    [switch]$Auto  # DEPRECATED: Use conversational workflow instead
)

# Set error action preference
$ErrorActionPreference = 'Stop'

# Backward compatibility: Handle deprecated -Auto flag
if ($Auto) {
    Write-Warning "The -Auto flag is deprecated and will be removed in a future version."
    Write-Warning "Please use the conversational approval workflow instead."
    Write-Warning "For now, treating -Auto as -Proceed for backward compatibility."
    Write-Host ""
    $Proceed = $true
}

# Store script start time
$startTime = Get-Date

# ========================================
# IMPORT MODULES
# ========================================

Write-Host ""
Write-Host "SpecKit Safe Update v1.0" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# ========================================
# MODULE IMPORTS
# ========================================
Write-Verbose "Importing PowerShell modules..."

try {
    $modulesPath = Join-Path $PSScriptRoot "modules"

    # Module Dependency Management (Tiered Import Structure)
    # IMPORTANT: Modules MUST NOT import other modules (creates scope isolation issues)
    # All imports are managed here in dependency order to ensure functions are available in orchestrator scope
    #
    # Dependency Graph:
    # - TIER 0 (no dependencies): HashUtils, GitHubApiClient, MarkdownMerger
    # - TIER 1 (depends on Tier 0): ManifestManager (uses HashUtils, GitHubApiClient), FingerprintDetector (uses HashUtils)
    # - TIER 2 (depends on Tier 1): BackupManager (uses ManifestManager), ConflictDetector (uses HashUtils, ManifestManager)

    # TIER 0: Foundation modules (no dependencies)
    # These must be imported first as other modules depend on them
    Import-Module (Join-Path $modulesPath "HashUtils.psm1") -Force -WarningAction SilentlyContinue
    Import-Module (Join-Path $modulesPath "GitHubApiClient.psm1") -Force -WarningAction SilentlyContinue
    Import-Module (Join-Path $modulesPath "MarkdownMerger.psm1") -Force -WarningAction SilentlyContinue

    # TIER 1: Modules depending on Tier 0
    # ManifestManager uses HashUtils.Get-NormalizedHash and GitHubApiClient functions
    # FingerprintDetector uses HashUtils.Get-NormalizedHash
    Import-Module (Join-Path $modulesPath "ManifestManager.psm1") -Force -WarningAction SilentlyContinue
    Import-Module (Join-Path $modulesPath "FingerprintDetector.psm1") -Force -WarningAction SilentlyContinue

    # TIER 2: Modules depending on Tier 1
    # BackupManager uses ManifestManager functions
    # ConflictDetector uses HashUtils and ManifestManager functions
    Import-Module (Join-Path $modulesPath "BackupManager.psm1") -Force -WarningAction SilentlyContinue
    Import-Module (Join-Path $modulesPath "ConflictDetector.psm1") -Force -WarningAction SilentlyContinue

    Write-Verbose "Modules imported successfully (8 modules in 3 tiers)"
}
catch {
    Write-Error "Failed to import modules: $($_.Exception.Message)"
    Write-Error $_.ScriptStackTrace
    exit 1
}

# ========================================
# HELPER IMPORTS
# ========================================
Write-Verbose "Loading helper scripts..."

try {
    $helpersPath = Join-Path $PSScriptRoot "helpers"

    . (Join-Path $helpersPath "Invoke-PreUpdateValidation.ps1")
    . (Join-Path $helpersPath "Show-UpdateSummary.ps1")
    . (Join-Path $helpersPath "Show-UpdateReport.ps1")
    . (Join-Path $helpersPath "Get-UpdateConfirmation.ps1")
    . (Join-Path $helpersPath "Invoke-ConflictResolutionWorkflow.ps1")
    . (Join-Path $helpersPath "Invoke-RollbackWorkflow.ps1")

    Write-Verbose "Helpers loaded successfully"
}
catch {
    Write-Error "Failed to load helper scripts: $($_.Exception.Message)"
    Write-Error $_.ScriptStackTrace
    exit 1
}

Write-Verbose "All modules and helpers loaded successfully"

# ========================================
# MAIN EXECUTION FLOW
# ========================================

# Variables to track for rollback
$backupPath = $null
$projectRoot = $PWD

try {
    # ========================================
    # STEP 1: Validate Prerequisites
    # ========================================
    Write-Verbose "Step 1: Validating prerequisites..."

    Invoke-PreUpdateValidation -ProjectRoot $projectRoot -Proceed:$Proceed

    # ========================================
    # STEP 2: Handle Rollback if Requested
    # ========================================
    if ($Rollback) {
        Write-Verbose "Step 2: Rollback mode requested"
        Invoke-RollbackWorkflow -ProjectRoot $projectRoot
        exit 0
    }

    Write-Verbose "Step 2: No rollback requested, continuing with update"

    # ========================================
    # STEP 2.5: Create .specify/ Directory Structure (First-Time Install)
    # ========================================
    $specifyDir = Join-Path $projectRoot ".specify"
    $isFirstInstall = -not (Test-Path $specifyDir)

    if ($isFirstInstall) {
        Write-Verbose "Step 2.5: Creating .specify/ directory structure for first-time install..."
        Write-Host "Creating .specify/ directory structure..." -ForegroundColor Cyan

        try {
            # Create directory structure
            $memoryDir = Join-Path $specifyDir "memory"
            $backupsDir = Join-Path $specifyDir "backups"

            New-Item -ItemType Directory -Path $specifyDir -Force | Out-Null
            New-Item -ItemType Directory -Path $memoryDir -Force | Out-Null
            New-Item -ItemType Directory -Path $backupsDir -Force | Out-Null

            Write-Host "Directory structure created successfully" -ForegroundColor Green
            Write-Host ""
        }
        catch {
            Write-Error "Failed to create .specify/ directory structure: $($_.Exception.Message)"
            exit 1
        }
    }

    # ========================================
    # STEP 3: Load Manifest (or prepare to create one)
    # ========================================
    Write-Verbose "Step 3: Loading manifest..."
    Write-Host "Loading manifest..." -ForegroundColor Cyan

    $manifest = Get-SpecKitManifest -ProjectRoot $projectRoot
    $needsManifestCreation = $false
    $detectedVersion = $null

    if (-not $manifest) {
        Write-Host "No manifest found." -ForegroundColor Yellow

        # NEW: Smart version detection for frictionless onboarding
        Write-Host "Detecting installed SpecKit version..." -ForegroundColor Cyan

        try {
            $detection = Get-InstalledSpecKitVersion -ProjectRoot $projectRoot -Verbose:$VerbosePreference

            if ($detection) {
                $detectedVersion = $detection.version_name
                $confidence = $detection.confidence
                $matchPct = $detection.match_percentage

                Write-Host ""
                Write-Host "✓ Version detected: $detectedVersion" -ForegroundColor Green
                Write-Host "  Confidence: $confidence ($matchPct% match)" -ForegroundColor $(
                    if ($confidence -eq "High") { "Green" }
                    elseif ($confidence -eq "Medium") { "Yellow" }
                    else { "Red" }
                )
                Write-Host "  Method: $($detection.detection_method)" -ForegroundColor Gray
                Write-Host ""

                if ($confidence -eq "Low") {
                    Write-Warning "Low confidence detection. Manifest will default to v0.0.0 (all files treated as customized)."
                    Write-Host ""
                    $detectedVersion = $null
                }
            }
            else {
                Write-Host "⚠ Could not detect version automatically" -ForegroundColor Yellow
                Write-Host "Manifest will default to v0.0.0 (all files treated as customized)" -ForegroundColor Yellow
                Write-Host ""
            }
        }
        catch {
            Write-Verbose "Version detection failed: $($_.Exception.Message)"
            Write-Host "⚠ Version detection failed, will use v0.0.0 default" -ForegroundColor Yellow
            Write-Host ""
        }

        $needsManifestCreation = $true
    }
    else {
        Write-Host "Manifest loaded: $($manifest.speckit_version)" -ForegroundColor Green
        Write-Host ""
    }

    # ========================================
    # STEP 4: Fetch Target Version
    # ========================================
    Write-Verbose "Step 4: Fetching target version..."
    Write-Host "Checking for updates..." -ForegroundColor Cyan

    try {
        if ($Version) {
            # Normalize version (add 'v' prefix if missing)
            $targetVersion = $Version
            if (-not $targetVersion.StartsWith('v')) {
                $targetVersion = "v$targetVersion"
            }

            Write-Verbose "Explicit version specified: $targetVersion"
            Write-Host "Target version: $targetVersion (specified)" -ForegroundColor Cyan
            $targetRelease = Get-SpecKitRelease -Version $targetVersion

            # Defensive null check for explicit version path
            if (-not $targetRelease) {
                throw "GitHub API returned empty response for version $targetVersion"
            }

            if (-not $targetRelease.tag_name) {
                throw "Release information missing version identifier (tag_name property)"
            }

            Write-Verbose "Explicit version validated: $($targetRelease.tag_name)"
        }
        else {
            Write-Verbose "No version specified, fetching latest from GitHub"
            $targetRelease = Get-LatestSpecKitRelease

            # Defensive null check after getting latest release
            if (-not $targetRelease) {
                throw "GitHub API returned empty response when fetching latest release"
            }

            if (-not $targetRelease.tag_name) {
                throw "Release information missing version identifier (tag_name property)"
            }

            Write-Verbose "Target version validated: $($targetRelease.tag_name)"
            Write-Host "Latest version: $($targetRelease.tag_name)" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Error "Failed to fetch release information: $($_.Exception.Message)"
        Write-Host ""
        Write-Host "Possible causes:" -ForegroundColor Yellow
        Write-Host "  - No internet connection" -ForegroundColor Yellow
        Write-Host "  - GitHub API rate limit exceeded" -ForegroundColor Yellow
        Write-Host "  - Invalid version specified" -ForegroundColor Yellow
        Write-Host ""
        exit 3
    }

    # ========================================
    # STEP 3.5: Create Manifest if needed (with detected or placeholder version)
    # ========================================
    if ($needsManifestCreation) {
        Write-Host ""

        if ($detectedVersion) {
            # Use detected version - enables smart merge for first-time users!
            Write-Verbose "Creating new manifest with detected version $detectedVersion"
            Write-Host "Creating new manifest with detected version: $detectedVersion" -ForegroundColor Cyan
            Write-Host "This enables smart merge - only actual customizations will be flagged as conflicts" -ForegroundColor Green
            Write-Host ""

            # Download the detected version's templates to get original hashes
            Write-Host "Downloading original templates for version $detectedVersion..." -ForegroundColor Cyan
            $templates = Download-SpecKitTemplates -Version $detectedVersion -DestinationPath ([System.IO.Path]::GetTempPath())

            # Create manifest with detected version (no AssumeAllCustomized flag)
            $manifest = New-SpecKitManifest -ProjectRoot $projectRoot -Version $detectedVersion

            Write-Host "Manifest created with smart version detection!" -ForegroundColor Green
            Write-Host "Detected version: $detectedVersion" -ForegroundColor Green
            Write-Host ""
        }
        else {
            # Fallback: Unknown version - assume all files are customized (safe default)
            Write-Verbose "Creating new manifest with placeholder version v0.0.0"
            Write-Host "Creating new manifest (version unknown - will update to $($targetRelease.tag_name))" -ForegroundColor Yellow
            Write-Host "This will scan your current .specify/ and .claude/ directories" -ForegroundColor Yellow
            Write-Host "and mark all files as customized (safe default)." -ForegroundColor Yellow
            Write-Host ""

            # Create manifest with placeholder version (unknown starting point), assuming all files are customized
            $manifest = New-SpecKitManifest -ProjectRoot $projectRoot -Version "v0.0.0" -AssumeAllCustomized

            Write-Host "Manifest created successfully" -ForegroundColor Green
            Write-Host "Current version marked as: $($manifest.speckit_version) (placeholder - will update to $($targetRelease.tag_name))" -ForegroundColor Green
            Write-Host ""
        }
    }

    # Check if already up to date
    if ($manifest.speckit_version -eq $targetRelease.tag_name -and -not $Force) {
        Write-Host ""
        Write-Host "Already up to date ($($manifest.speckit_version))" -ForegroundColor Green
        Write-Host ""
        exit 0
    }

    Write-Host ""

    # ========================================
    # STEP 5: Analyze File States
    # ========================================
    Write-Verbose "Step 5: Analyzing file states..."
    Write-Host "Analyzing file changes..." -ForegroundColor Cyan

    # Download templates for comparison
    $templates = Download-SpecKitTemplates -Version $targetRelease.tag_name -DestinationPath $projectRoot

    # Get all file states
    $fileStates = Get-AllFileStates -Manifest $manifest -UpstreamTemplates $templates -ProjectRoot $projectRoot

    # Find custom commands
    $officialCommands = Get-OfficialSpecKitCommands -Version $targetRelease.tag_name
    $customFiles = Find-CustomCommands -ProjectRoot $projectRoot -OfficialCommands $officialCommands

    Write-Host "Analysis complete" -ForegroundColor Green
    Write-Host ""

    # ========================================
    # STEP 6: Check-Only Mode
    # ========================================
    if ($CheckOnly) {
        Write-Verbose "Step 6: Check-only mode - showing report and exiting"

        Show-UpdateReport -FileStates $fileStates -CurrentVersion $manifest.speckit_version -TargetVersion $targetRelease.tag_name -CustomFiles $customFiles

        # Clean up temporary files and directories if we created them (don't leave repo in dirty state)
        if ($needsManifestCreation) {
            $specifyDir = Join-Path $projectRoot ".specify"
            if (Test-Path $specifyDir) {
                Write-Verbose "Removing temporary .specify directory created for check-only mode"
                Remove-Item $specifyDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        exit 0
    }

    Write-Verbose "Step 6: Not in check-only mode, continuing with update"

    # ========================================
    # STEP 7: Get User Confirmation
    # ========================================
    Write-Verbose "Step 7: Getting user confirmation..."

    if ($Proceed) {
        Write-Verbose "Proceed flag set, skipping confirmation prompt"
        Write-Host "Proceeding with update (approved via conversational workflow)..." -ForegroundColor Cyan
        Write-Host ""
    }
    else {
        $confirmed = Get-UpdateConfirmation -FileStates $fileStates -CurrentVersion $manifest.speckit_version -TargetVersion $targetRelease.tag_name -Proceed:$Proceed

        if (-not $confirmed) {
            # In non-interactive mode (Claude Code), this means waiting for user approval
            # In interactive mode, this means user explicitly declined
            # Either way, exit gracefully
            Write-Verbose "Confirmation not received, exiting"

            # Clean up temporary manifest if we created one (don't leave repo in dirty state)
            if ($needsManifestCreation) {
                $manifestPath = Join-Path $projectRoot ".specify/manifest.json"
                if (Test-Path $manifestPath) {
                    Write-Verbose "Removing temporary manifest created during update check"
                    Remove-Item $manifestPath -Force
                }
            }

            exit 0
        }

        Write-Host "Update confirmed. Proceeding..." -ForegroundColor Green
        Write-Host ""
    }

    # ========================================
    # STEP 8: Create Backup
    # ========================================
    if (-not $NoBackup) {
        Write-Verbose "Step 8: Creating backup..."
        Write-Host "Creating backup..." -ForegroundColor Cyan

        try {
            $backupPath = New-SpecKitBackup -ProjectRoot $projectRoot

            Write-Host "Backup created: $backupPath" -ForegroundColor Green
            Write-Host ""
        }
        catch {
            Write-Error "Failed to create backup: $($_.Exception.Message)"
            throw
        }
    }
    else {
        Write-Verbose "Step 8: Backup skipped (--no-backup flag)"
        Write-Host "WARNING: Skipping backup (--no-backup flag)" -ForegroundColor Red
        Write-Host ""
    }

    # ========================================
    # STEP 9: Templates Already Downloaded
    # ========================================
    Write-Verbose "Step 9: Templates already downloaded in step 5"

    # ========================================
    # STEP 10: Apply Updates (Fail-Fast)
    # ========================================
    Write-Verbose "Step 10: Applying updates..."
    Write-Host "Applying updates..." -ForegroundColor Cyan
    Write-Host ""

    $updateResult = [PSCustomObject]@{
        FilesUpdated = @()
        FilesPreserved = @()
        ConflictsResolved = @()
        ConflictsSkipped = @()
        CustomFiles = $customFiles
        CustomCommandsAdded = @()
        CommandsRemoved = @()
        ConstitutionUpdateNeeded = $false
        BackupPath = $backupPath
    }

    # Apply updates based on file states
    foreach ($fileState in $fileStates) {
        $filePath = Join-Path $projectRoot $fileState.path

        switch ($fileState.action) {
            'update' {
                # File is not customized or force flag is set - update it
                try {
                    Write-Host "  Updating: $($fileState.path)" -ForegroundColor Green

                    # Ensure directory exists
                    $directory = [System.IO.Path]::GetDirectoryName($filePath)
                    if (-not (Test-Path $directory)) {
                        New-Item -ItemType Directory -Path $directory -Force | Out-Null
                    }

                    # Write new content
                    $templates[$fileState.path] | Out-File -FilePath $filePath -Encoding utf8 -Force

                    $updateResult.FilesUpdated += $fileState.path
                }
                catch {
                    Write-Error "Failed to update $($fileState.path): $($_.Exception.Message)"
                    throw
                }
            }

            'preserve' {
                # File is customized and has no upstream changes - preserve it
                Write-Host "  Preserving: $($fileState.path) (customized)" -ForegroundColor Yellow
                $updateResult.FilesPreserved += $fileState.path
            }

            'add' {
                # New file in upstream - add it
                try {
                    Write-Host "  Adding: $($fileState.path)" -ForegroundColor Cyan

                    $directory = [System.IO.Path]::GetDirectoryName($filePath)
                    if (-not (Test-Path $directory)) {
                        New-Item -ItemType Directory -Path $directory -Force | Out-Null
                    }

                    $templates[$fileState.path] | Out-File -FilePath $filePath -Encoding utf8 -Force

                    $updateResult.CustomCommandsAdded += $fileState.path
                }
                catch {
                    Write-Error "Failed to add $($fileState.path): $($_.Exception.Message)"
                    throw
                }
            }

            'remove' {
                # File removed from upstream - remove it
                if (Test-Path $filePath) {
                    Write-Host "  Removing: $($fileState.path) (obsolete)" -ForegroundColor DarkGray
                    Remove-Item $filePath -Force
                    $updateResult.CommandsRemoved += $fileState.path
                }
            }

            'merge' {
                # Conflict - will handle in step 11
                Write-Verbose "  Conflict detected: $($fileState.path) (will handle in step 11)"
            }

            default {
                # Skip - no action needed
                Write-Verbose "  Skipping: $($fileState.path) (action: $($fileState.action))"
            }
        }
    }

    Write-Host ""
    Write-Host "Updates applied successfully" -ForegroundColor Green
    Write-Host ""

    # ========================================
    # STEP 11: Handle Conflicts
    # ========================================
    $conflicts = @($fileStates | Where-Object { $_.action -eq 'merge' })

    if ($conflicts.Count -gt 0) {
        Write-Verbose "Step 11: Handling $($conflicts.Count) conflict(s)..."

        # Check if running in non-interactive mode (Claude Code)
        try {
            $isInteractive = -not [Console]::IsInputRedirected
        }
        catch {
            $isInteractive = $true
        }

        if (-not $isInteractive) {
            # Non-interactive mode: Write Git conflict markers for VSCode resolution
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Yellow
            Write-Host "Conflicts Detected" -ForegroundColor Yellow
            Write-Host "========================================" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Running in non-interactive mode (Claude Code)." -ForegroundColor Yellow
            Write-Host "Writing Git conflict markers to $($conflicts.Count) conflicted files..." -ForegroundColor Yellow
            Write-Host ""

            $actualConflicts = @()
            $falsePositives = @()
            $constitutionConflicts = @()

            foreach ($conflict in $conflicts) {
                try {
                    $filePath = Join-Path $projectRoot $conflict.path

                    # Special handling for constitution.md
                    if ($conflict.path -eq '.specify/memory/constitution.md') {
                        Write-Host "  Constitution conflict detected - will use /speckit.constitution workflow" -ForegroundColor Yellow
                        $constitutionConflicts += $conflict.path

                        # Mark as requiring constitution update
                        $updateResult.ConstitutionUpdateNeeded = $true

                        # Add to conflicts resolved (will be handled by /speckit.constitution)
                        $updateResult.ConflictsResolved += $conflict.path
                        continue
                    }

                    # Read current content
                    $currentContent = if (Test-Path $filePath) {
                        Get-Content $filePath -Raw -Encoding utf8
                    } else {
                        ""
                    }

                    # Get upstream content
                    $incomingContent = if ($templates.ContainsKey($conflict.path)) {
                        $templates[$conflict.path]
                    } else {
                        ""
                    }

                    # Check if current and incoming are actually different (normalized)
                    $currentHash = if ($currentContent) {
                        # Write to temp file to hash it
                        $tempFile = Join-Path $env:TEMP "current-$(Get-Random).txt"
                        $currentContent | Set-Content -Path $tempFile -Encoding utf8 -Force
                        $hash = Get-NormalizedHash -FilePath $tempFile
                        Remove-Item $tempFile -Force
                        $hash
                    } else {
                        $null
                    }

                    $incomingHash = $conflict.UpstreamHash

                    # Compare hashes to see if there's a real conflict
                    $hasRealConflict = -not (Compare-FileHashes -Hash1 $currentHash -Hash2 $incomingHash)

                    if ($hasRealConflict) {
                        # Real conflict - use 3-way smart merge
                        $baseContent = ""

                        # Try to fetch base content from original version for true 3-way merge
                        if ($manifest.speckit_version -and $manifest.speckit_version -ne "v0.0.0") {
                            try {
                                Write-Verbose "Fetching base version file: $($conflict.path) from $($manifest.speckit_version)"
                                $baseContent = Get-SpecKitFile -Version $manifest.speckit_version -FilePath $conflict.path
                                if ($baseContent) {
                                    Write-Verbose "Base content fetched successfully ($($baseContent.Length) bytes)"
                                }
                            }
                            catch {
                                Write-Verbose "Could not fetch base content: $($_.Exception.Message)"
                            }
                        }

                        # Use 3-way smart merge for markdown files
                        if ($filePath -like "*.md") {
                            try {
                                Write-Verbose "Attempting smart merge for: $($conflict.path)"

                                # Create temp files for merge operation
                                $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "speckit-merge-$(New-Guid)"
                                New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

                                $basePath = Join-Path $tempDir "base.md"
                                $currentPath = Join-Path $tempDir "current.md"
                                $incomingPath = Join-Path $tempDir "incoming.md"
                                $outputPath = Join-Path $tempDir "merged.md"

                                # Write content to temp files
                                if ($baseContent) {
                                    $baseContent | Set-Content -Path $basePath -Encoding UTF8 -NoNewline
                                } else {
                                    "" | Set-Content -Path $basePath -Encoding UTF8 -NoNewline
                                }
                                $currentContent | Set-Content -Path $currentPath -Encoding UTF8 -NoNewline
                                $incomingContent | Set-Content -Path $incomingPath -Encoding UTF8 -NoNewline

                                # Perform 3-way merge
                                $mergeResult = Merge-MarkdownFiles `
                                    -BasePath $basePath `
                                    -CurrentPath $currentPath `
                                    -IncomingPath $incomingPath `
                                    -OutputPath $outputPath `
                                    -BaseVersion $manifest.speckit_version `
                                    -IncomingVersion $targetRelease.tag_name `
                                    -Verbose:$VerbosePreference

                                # Copy merged result to actual file
                                Copy-Item -Path $outputPath -Destination $filePath -Force

                                # Cleanup
                                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

                                if ($mergeResult.ConflictCount -eq 0) {
                                    Write-Host "  ✓ Clean merge: $($conflict.path) (no conflicts)" -ForegroundColor Green
                                } else {
                                    Write-Host "  ⚠ Merged with $($mergeResult.ConflictCount) conflict(s): $($conflict.path)" -ForegroundColor Yellow
                                    $actualConflicts += $conflict.path
                                }
                            }
                            catch {
                                Write-Warning "Smart merge failed for $($conflict.path), falling back to basic conflict markers: $($_.Exception.Message)"

                                # Fallback to basic conflict markers
                                Write-SmartConflictResolution `
                                    -FilePath $filePath `
                                    -CurrentContent $currentContent `
                                    -BaseContent $baseContent `
                                    -IncomingContent $incomingContent `
                                    -OriginalVersion $manifest.speckit_version `
                                    -NewVersion $targetRelease.tag_name

                                Write-Host "  Conflict resolution applied: $($conflict.path)" -ForegroundColor Cyan
                                $actualConflicts += $conflict.path
                            }
                        }
                        else {
                            # Non-markdown files: use basic conflict markers
                            Write-SmartConflictResolution `
                                -FilePath $filePath `
                                -CurrentContent $currentContent `
                                -BaseContent $baseContent `
                                -IncomingContent $incomingContent `
                                -OriginalVersion $manifest.speckit_version `
                                -NewVersion $targetRelease.tag_name

                            Write-Host "  Conflict resolution applied: $($conflict.path)" -ForegroundColor Cyan
                            $actualConflicts += $conflict.path
                        }
                    }
                    else {
                        # False positive - file is actually the same, just marked as customized
                        Write-Host "  No changes detected: $($conflict.path) (marked as not customized)" -ForegroundColor Green
                        $falsePositives += $conflict.path

                        # Update manifest to mark as not customized
                        $trackedFile = $manifest.tracked_files | Where-Object { $_.path -eq $conflict.path }
                        if ($trackedFile) {
                            $trackedFile.customized = $false
                            $trackedFile.original_hash = $incomingHash
                        }

                        # Add to resolved list
                        $updateResult.FilesUpdated += $conflict.path
                    }
                }
                catch {
                    Write-Warning "Failed to process conflict for $($conflict.path): $($_.Exception.Message)"
                    $actualConflicts += $conflict.path
                }
            }

            Write-Host ""
            if ($falsePositives.Count -gt 0) {
                Write-Host "False Positives Resolved:" -ForegroundColor Green
                Write-Host "  $($falsePositives.Count) files were marked as customized but are identical to upstream" -ForegroundColor Green
                Write-Host "  These have been automatically marked as not customized in the manifest" -ForegroundColor Green
                Write-Host ""
            }

            if ($constitutionConflicts.Count -gt 0) {
                Write-Host "Constitution Conflict Detected:" -ForegroundColor Yellow
                Write-Host "  Constitution.md has been customized and has upstream changes" -ForegroundColor Yellow
                Write-Host "  This will be handled by the /speckit.constitution workflow" -ForegroundColor Yellow
                Write-Host "  (Constitution conflicts are not suitable for Git conflict markers)" -ForegroundColor Yellow
                Write-Host ""
            }

            if ($actualConflicts.Count -gt 0) {
                Write-Host "Conflict markers written for $($actualConflicts.Count) file(s)." -ForegroundColor Yellow
                Write-Host ""
                Write-Host "Next Steps:" -ForegroundColor Cyan
                Write-Host "  1. Open the conflicted files in VSCode" -ForegroundColor Cyan
                Write-Host "  2. Use CodeLens actions to resolve conflicts:" -ForegroundColor Cyan
                Write-Host "     - Accept Current (keep your version)" -ForegroundColor Cyan
                Write-Host "     - Accept Incoming (use new version)" -ForegroundColor Cyan
                Write-Host "     - Accept Both (merge manually)" -ForegroundColor Cyan
                Write-Host "  3. Save the resolved files" -ForegroundColor Cyan
                Write-Host "  4. Commit the resolved files to git" -ForegroundColor Cyan
                Write-Host ""

                # Mark actual conflicts as skipped - user will resolve in VSCode
                $updateResult.ConflictsSkipped = $actualConflicts
            }
            elseif ($constitutionConflicts.Count -eq 0 -and $falsePositives.Count -gt 0) {
                Write-Host "All conflicts were false positives - no action needed!" -ForegroundColor Green
                Write-Host ""
            }
        }
        else {
            # Interactive mode: Use interactive workflow
            $conflictResult = Invoke-ConflictResolutionWorkflow -Conflicts $conflicts -Templates $templates -ProjectRoot $projectRoot

            $updateResult.ConflictsResolved = $conflictResult.Resolved + $conflictResult.KeptMine + $conflictResult.UsedNew
            $updateResult.ConflictsSkipped = $conflictResult.Skipped
        }
    }
    else {
        Write-Verbose "Step 11: No conflicts to resolve"
    }

    # ========================================
    # STEP 12: Update Constitution (Notify)
    # ========================================
    Write-Verbose "Step 12: Checking if constitution needs update..."

    # Check if constitution.md was updated or has conflicts
    $constitutionUpdated = $updateResult.FilesUpdated -contains '.specify/memory/constitution.md'
    $constitutionConflict = $updateResult.ConflictsResolved -contains '.specify/memory/constitution.md'

    if ($constitutionUpdated -or $constitutionConflict) {
        # Verify if constitution content actually changed by comparing hashes
        $constitutionPath = Join-Path $projectRoot '.specify/memory/constitution.md'
        $backupConstitutionPath = Join-Path $backupPath '.specify/memory/constitution.md'

        $actualChangeDetected = $false

        try {
            Write-Verbose "Constitution hash comparison:"
            Write-Verbose "  CurrentPath=$constitutionPath"
            Write-Verbose "  BackupPath=$backupConstitutionPath"

            # Check if both files exist
            if ((Test-Path $constitutionPath) -and (Test-Path $backupConstitutionPath)) {
                # Compute normalized hashes for both files
                $currentHash = Get-NormalizedHash -FilePath $constitutionPath
                $backupHash = Get-NormalizedHash -FilePath $backupConstitutionPath

                Write-Verbose "  CurrentHash=$currentHash"
                Write-Verbose "  BackupHash=$backupHash"

                # Compare hashes to detect actual content change
                $actualChangeDetected = ($currentHash -ne $backupHash)
                Write-Verbose "  Changed=$actualChangeDetected"

                if (-not $actualChangeDetected) {
                    Write-Verbose "Constitution marked as updated but content unchanged - skipping notification"
                }
            }
            elseif (-not (Test-Path $backupConstitutionPath)) {
                # Backup missing - fail-safe: show notification
                Write-Verbose "No backup constitution found - assuming changed (fail-safe)"
                $actualChangeDetected = $true
            }
            elseif (-not (Test-Path $constitutionPath)) {
                # Current constitution missing - edge case, skip notification
                Write-Verbose "Constitution not found in project - skipping notification"
                $actualChangeDetected = $false
            }
        }
        catch {
            # Hash comparison failed - fail-safe: show notification
            Write-Verbose "Constitution hash comparison failed:"
            Write-Verbose "  Error=$($_.Exception.GetType().Name)"
            Write-Verbose "  Message=$($_.Exception.Message)"
            Write-Verbose "  FilePath=$constitutionPath"
            Write-Verbose "  Action=Defaulting to showing notification (fail-safe)"
            $actualChangeDetected = $true
        }

        # Only show notification if content actually changed
        if ($actualChangeDetected) {
            # Determine notification type based on conflict status
            if ($constitutionConflict) {
                # REQUIRED action notification (conflict detected)
                $emojiIcon = "⚠️"
                $primaryColor = "Red"
                $secondaryColor = "Yellow"
                $actionLabel = "REQUIRED"
                $actionVerb = "Run the following command"
                $headerText = "Constitution Conflict Detected"
                $descriptionText = "The constitution has conflicts requiring manual resolution."
            }
            else {
                # OPTIONAL review notification (clean update)
                $emojiIcon = "ℹ️"
                $primaryColor = "Cyan"
                $secondaryColor = "Gray"
                $actionLabel = "OPTIONAL"
                $actionVerb = "Review changes by running"
                $headerText = "Constitution Template Updated"
                $descriptionText = "The constitution template was cleanly updated (no conflicts)."
            }

            # Display notification with differentiated styling
            Write-Host ""
            Write-Host "$emojiIcon  $headerText" -ForegroundColor $primaryColor
            Write-Host $descriptionText -ForegroundColor $secondaryColor
            Write-Host ""
            Write-Host "$actionLabel`: $actionVerb`:" -ForegroundColor $secondaryColor
            Write-Host "  /speckit.constitution $backupConstitutionPath" -ForegroundColor White
            Write-Host ""

            $updateResult.ConstitutionUpdateNeeded = $true
        }
    }

    # ========================================
    # STEP 13: Update Manifest
    # ========================================
    Write-Verbose "Step 13: Updating manifest..."
    Write-Host "Updating manifest..." -ForegroundColor Cyan

    try {
        Update-ManifestVersion -ProjectRoot $projectRoot -NewVersion $targetRelease.tag_name
        Update-FileHashes -ProjectRoot $projectRoot

        Write-Host "Manifest updated successfully" -ForegroundColor Green
        Write-Host ""
    }
    catch {
        Write-Error "Failed to update manifest: $($_.Exception.Message)"
        throw
    }

    # ========================================
    # STEP 13.5: Cleanup Temporary Conflict Diff Files
    # ========================================
    Write-Verbose "Step 13.5: Cleaning up temporary conflict diff files..."

    try {
        Remove-ConflictDiffFiles -ProjectRoot $projectRoot
        Write-Verbose "Conflict diff files cleaned up successfully"
    }
    catch {
        # Non-fatal - already logged as warning in function
        Write-Verbose "Cleanup completed with warnings (non-fatal)"
    }

    # ========================================
    # STEP 14: Cleanup Old Backups
    # ========================================
    Write-Verbose "Step 14: Cleaning up old backups..."

    try {
        $oldBackups = Remove-OldBackups -ProjectRoot $projectRoot -KeepCount 5 -WhatIf

        if ($oldBackups -and $oldBackups.Count -gt 0) {
            Write-Host "Old backups to clean up: $($oldBackups.Count)" -ForegroundColor Yellow

            # Ask user if they want to clean up
            Write-Host "Delete old backups? (Y/n): " -NoNewline -ForegroundColor Cyan
            $response = Read-Host
            $cleanup = ($response -ne 'n' -and $response -ne 'N')

            if ($cleanup) {
                Remove-OldBackups -ProjectRoot $projectRoot -KeepCount 5
                Write-Host "Old backups cleaned up" -ForegroundColor Green
            }
            else {
                Write-Host "Keeping old backups" -ForegroundColor Yellow
            }

            Write-Host ""
        }
    }
    catch {
        Write-Warning "Failed to cleanup old backups: $($_.Exception.Message)"
    }

    # ========================================
    # STEP 15: Show Success Summary
    # ========================================
    Write-Verbose "Step 15: Showing success summary..."

    Show-UpdateSummary -Result $updateResult -FromVersion $manifest.speckit_version -ToVersion $targetRelease.tag_name -IsFirstInstall $isFirstInstall

    # Calculate elapsed time
    $elapsedTime = (Get-Date) - $startTime
    Write-Host "Update completed in $([math]::Round($elapsedTime.TotalSeconds, 2)) seconds" -ForegroundColor DarkGray
    Write-Host ""

    exit 0
}
catch {
    # ========================================
    # ERROR HANDLING: Automatic Rollback
    # ========================================
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Update Failed" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""

    # Automatic rollback if backup exists
    if (-not $NoBackup -and $backupPath -and (Test-Path $backupPath)) {
        Write-Host "Attempting automatic rollback..." -ForegroundColor Yellow
        Write-Host ""

        try {
            Invoke-AutomaticRollback -ProjectRoot $projectRoot -BackupPath $backupPath

            Write-Host ""
            Write-Host "Rollback completed successfully" -ForegroundColor Green
            Write-Host "Your files have been restored to their previous state" -ForegroundColor Green
            Write-Host ""
        }
        catch {
            Write-Host ""
            Write-Host "Rollback failed: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host ""
            Write-Host "Your backup is still available at: $backupPath" -ForegroundColor Yellow
            Write-Host "You can manually restore by running:" -ForegroundColor Yellow
            Write-Host "  /speckit-update --rollback" -ForegroundColor Yellow
            Write-Host ""
        }

        exit 6
    }
    else {
        Write-Host "No backup available for automatic rollback" -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
}
