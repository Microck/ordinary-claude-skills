#Requires -Version 7.0

<#
.SYNOPSIS
    Backup management module for SpecKit Safe Update Skill.

.DESCRIPTION
    Provides functions to create, restore, list, and manage backups of SpecKit project files.
    Backups include .specify/ and .claude/ directories, excluding the backups directory itself.

.NOTES
    Dependencies: ManifestManager.psm1 (Get-SpecKitManifest)
#>

# Import dependencies
$ManifestManagerPath = Join-Path $PSScriptRoot "ManifestManager.psm1"
if (Test-Path $ManifestManagerPath) {
    Import-Module $ManifestManagerPath -Force
}

<#
.SYNOPSIS
    Creates a timestamped backup of SpecKit project files.

.DESCRIPTION
    Creates a backup in .specify/backups/<timestamp>/ directory containing:
    - .specify/ directory (excluding backups directory itself)
    - .claude/ directory (if exists)

.PARAMETER ProjectRoot
    Root directory of the SpecKit project. Defaults to current directory.

.OUTPUTS
    String - Path to the created backup directory.

.EXAMPLE
    $backupPath = New-SpecKitBackup -ProjectRoot "C:\Projects\MyProject"
#>
function New-SpecKitBackup {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ProjectRoot = $PWD
    )

    Write-Verbose "Creating backup for project: $ProjectRoot"

    # Validate project root
    $specifyDir = Join-Path $ProjectRoot ".specify"
    if (-not (Test-Path $specifyDir)) {
        throw "Not a SpecKit project: .specify directory not found at $ProjectRoot"
    }

    # Generate timestamp
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    Write-Verbose "Using timestamp: $timestamp"

    # Create backup directory
    $backupDir = Join-Path $ProjectRoot ".specify/backups/$timestamp"
    Write-Verbose "Creating backup directory: $backupDir"

    try {
        New-Item -ItemType Directory -Path $backupDir -Force -ErrorAction Stop | Out-Null
    }
    catch {
        throw "Failed to create backup directory: $($_.Exception.Message)"
    }

    # Copy .specify/ directory (excluding backups)
    Write-Verbose "Backing up .specify/ directory..."
    $specifyBackup = Join-Path $backupDir ".specify"

    try {
        # Get all items in .specify except backups directory
        $itemsToCopy = Get-ChildItem -Path $specifyDir -Force | Where-Object {
            $_.Name -ne 'backups'
        }

        if ($itemsToCopy.Count -gt 0) {
            New-Item -ItemType Directory -Path $specifyBackup -Force | Out-Null

            foreach ($item in $itemsToCopy) {
                $destination = Join-Path $specifyBackup $item.Name
                if ($item.PSIsContainer) {
                    Copy-Item -Path $item.FullName -Destination $destination -Recurse -Force -ErrorAction Stop
                }
                else {
                    Copy-Item -Path $item.FullName -Destination $destination -Force -ErrorAction Stop
                }
            }
            Write-Verbose "Copied $($itemsToCopy.Count) items from .specify/"
        }
        else {
            Write-Warning ".specify/ directory is empty (excluding backups)"
        }
    }
    catch {
        # Cleanup failed backup
        Remove-Item -Path $backupDir -Recurse -Force -ErrorAction SilentlyContinue
        throw "Failed to backup .specify/ directory: $($_.Exception.Message)"
    }

    # Copy .claude/ directory if it exists
    $claudeDir = Join-Path $ProjectRoot ".claude"
    if (Test-Path $claudeDir) {
        Write-Verbose "Backing up .claude/ directory..."
        $claudeBackup = Join-Path $backupDir ".claude"

        try {
            Copy-Item -Path $claudeDir -Destination $claudeBackup -Recurse -Force -ErrorAction Stop
            Write-Verbose "Successfully backed up .claude/ directory"
        }
        catch {
            # Cleanup failed backup
            Remove-Item -Path $backupDir -Recurse -Force -ErrorAction SilentlyContinue
            throw "Failed to backup .claude/ directory: $($_.Exception.Message)"
        }
    }
    else {
        Write-Verbose ".claude/ directory not found, skipping"
    }

    Write-Host "Backup created: .specify/backups/$timestamp"

    return $backupDir
}

<#
.SYNOPSIS
    Restores SpecKit project files from a backup.

.DESCRIPTION
    Restores .specify/ and .claude/ directories from the specified backup path.
    WARNING: This operation overwrites current files.

.PARAMETER ProjectRoot
    Root directory of the SpecKit project. Defaults to current directory.

.PARAMETER BackupPath
    Full path to the backup directory to restore from.

.EXAMPLE
    Restore-SpecKitBackup -ProjectRoot "C:\Projects\MyProject" -BackupPath "C:\Projects\MyProject\.specify\backups\20250119-142210"
#>
function Restore-SpecKitBackup {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ProjectRoot = $PWD,

        [Parameter(Mandatory)]
        [string]$BackupPath
    )

    Write-Verbose "Restoring backup from: $BackupPath"

    # Validate backup path
    if (-not (Test-Path $BackupPath)) {
        throw "Backup not found: $BackupPath"
    }

    # Validate backup contains expected directories
    $specifyBackup = Join-Path $BackupPath ".specify"
    if (-not (Test-Path $specifyBackup)) {
        throw "Invalid backup: .specify directory not found in backup"
    }

    try {
        # Restore .specify/ directory
        Write-Verbose "Restoring .specify/ directory..."
        $specifyDest = Join-Path $ProjectRoot ".specify"

        # Remove current .specify/ directory (preserve backups)
        if (Test-Path $specifyDest) {
            # Preserve the backups directory
            $backupsDir = Join-Path $specifyDest "backups"
            $tempBackupsDir = $null

            if (Test-Path $backupsDir) {
                $tempBackupsDir = Join-Path $env:TEMP "speckit-backups-temp-$(Get-Random)"
                Write-Verbose "Temporarily moving backups directory to: $tempBackupsDir"
                Copy-Item -Path $backupsDir -Destination $tempBackupsDir -Recurse -Force -ErrorAction Stop
            }

            # Remove current .specify/
            Remove-Item -Path $specifyDest -Recurse -Force -ErrorAction Stop
            Write-Verbose "Removed current .specify/ directory"

            # Create new .specify/ directory
            New-Item -ItemType Directory -Path $specifyDest -Force | Out-Null

            # Copy contents from backup .specify/ (not the directory itself)
            Get-ChildItem -Path $specifyBackup -Force | ForEach-Object {
                $destination = Join-Path $specifyDest $_.Name
                Copy-Item -Path $_.FullName -Destination $destination -Recurse -Force -ErrorAction Stop
            }
            Write-Verbose "Restored .specify/ from backup"

            # Restore the backups directory
            if ($tempBackupsDir -and (Test-Path $tempBackupsDir)) {
                $restoredBackupsDir = Join-Path $specifyDest "backups"
                Copy-Item -Path "$tempBackupsDir" -Destination $restoredBackupsDir -Recurse -Force -ErrorAction Stop
                Remove-Item -Path $tempBackupsDir -Recurse -Force -ErrorAction SilentlyContinue
                Write-Verbose "Restored backups directory"
            }
        }
        else {
            # No existing .specify/, create it
            New-Item -ItemType Directory -Path $specifyDest -Force | Out-Null

            # Copy contents from backup
            Get-ChildItem -Path $specifyBackup -Force | ForEach-Object {
                $destination = Join-Path $specifyDest $_.Name
                Copy-Item -Path $_.FullName -Destination $destination -Recurse -Force -ErrorAction Stop
            }
            Write-Verbose "Restored .specify/ from backup (no existing directory)"
        }

        # Restore .claude/ directory if exists in backup
        $claudeBackup = Join-Path $BackupPath ".claude"
        if (Test-Path $claudeBackup) {
            Write-Verbose "Restoring .claude/ directory..."
            $claudeDest = Join-Path $ProjectRoot ".claude"

            # Remove current .claude/ directory if exists
            if (Test-Path $claudeDest) {
                Remove-Item -Path $claudeDest -Recurse -Force -ErrorAction Stop
                Write-Verbose "Removed current .claude/ directory"
            }

            # Copy backup .claude/
            Copy-Item -Path $claudeBackup -Destination $claudeDest -Recurse -Force -ErrorAction Stop
            Write-Verbose "Restored .claude/ from backup"
        }
        else {
            Write-Verbose ".claude/ directory not found in backup, skipping"
        }

        Write-Host "Successfully restored from backup: $BackupPath"
    }
    catch {
        throw "Failed to restore backup: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Lists all available backups for a SpecKit project.

.DESCRIPTION
    Scans the .specify/backups/ directory and returns metadata about each backup.
    Results are sorted by creation time, newest first.

.PARAMETER ProjectRoot
    Root directory of the SpecKit project. Defaults to current directory.

.OUTPUTS
    PSCustomObject[] - Array of backup metadata objects with properties:
    - Timestamp: Backup folder name (yyyyMMdd-HHmmss)
    - Path: Full path to backup directory
    - CreatedAt: DateTime when backup was created
    - SizeKB: Total size of backup in kilobytes

.EXAMPLE
    $backups = Get-SpecKitBackups -ProjectRoot "C:\Projects\MyProject"
    $backups | Format-Table Timestamp, CreatedAt, SizeKB
#>
function Get-SpecKitBackups {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ProjectRoot = $PWD
    )

    Write-Verbose "Listing backups for project: $ProjectRoot"

    $backupsDir = Join-Path $ProjectRoot ".specify/backups"

    if (-not (Test-Path $backupsDir)) {
        Write-Verbose "Backups directory not found: $backupsDir"
        return @()
    }

    try {
        $backupDirs = @(Get-ChildItem -Path $backupsDir -Directory -ErrorAction Stop)

        if ($backupDirs.Count -eq 0) {
            Write-Verbose "No backups found"
            return @()
        }

        $backups = @($backupDirs | ForEach-Object {
            $size = 0
            try {
                $size = (Get-ChildItem -Path $_.FullName -Recurse -File -ErrorAction SilentlyContinue |
                    Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                $sizeKB = [math]::Round($size / 1KB, 2)
            }
            catch {
                Write-Verbose "Failed to calculate size for backup: $($_.Name)"
                $sizeKB = 0
            }

            [PSCustomObject]@{
                Timestamp = $_.Name
                Path = $_.FullName
                CreatedAt = $_.CreationTime
                SizeKB = $sizeKB
            }
        } | Sort-Object CreatedAt -Descending)

        Write-Verbose "Found $($backups.Count) backup(s)"
        return ,$backups  # Force array return with comma operator
    }
    catch {
        Write-Warning "Failed to list backups: $($_.Exception.Message)"
        return @()
    }
}

<#
.SYNOPSIS
    Removes old backups, keeping only the most recent ones.

.DESCRIPTION
    Deletes old backups while preserving the specified number of most recent backups.
    Can run in WhatIf mode to preview what would be deleted without actually deleting.

.PARAMETER ProjectRoot
    Root directory of the SpecKit project. Defaults to current directory.

.PARAMETER KeepCount
    Number of most recent backups to keep. Defaults to 5.

.PARAMETER WhatIf
    If specified, returns list of backups that would be deleted without actually deleting them.

.OUTPUTS
    PSCustomObject[] - Array of backups that were deleted (or would be deleted in WhatIf mode).

.EXAMPLE
    # Preview what would be deleted
    $toDelete = Remove-OldBackups -ProjectRoot "C:\Projects\MyProject" -KeepCount 5 -WhatIf

    # Actually delete old backups
    Remove-OldBackups -ProjectRoot "C:\Projects\MyProject" -KeepCount 5
#>
function Remove-OldBackups {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ProjectRoot = $PWD,

        [Parameter()]
        [int]$KeepCount = 5,

        [Parameter()]
        [switch]$WhatIf
    )

    Write-Verbose "Checking for old backups (keep: $KeepCount, whatif: $($WhatIf.IsPresent))"

    $backups = @(Get-SpecKitBackups -ProjectRoot $ProjectRoot)

    if ($backups.Count -le $KeepCount) {
        Write-Verbose "Current backup count ($($backups.Count)) is within keep limit ($KeepCount)"
        return @()
    }

    # Keep newest $KeepCount backups, remove the rest
    $toRemove = @($backups | Select-Object -Skip $KeepCount)
    Write-Verbose "Identified $($toRemove.Count) backup(s) to remove"

    if ($WhatIf) {
        Write-Verbose "WhatIf mode: returning list without deleting"
        return ,$toRemove  # Force array return
    }

    # Delete old backups
    $removed = @()
    foreach ($backup in $toRemove) {
        try {
            Write-Verbose "Removing backup: $($backup.Timestamp)"
            Remove-Item -Path $backup.Path -Recurse -Force -ErrorAction Stop
            Write-Host "Removed old backup: $($backup.Timestamp)"
            $removed += $backup
        }
        catch {
            Write-Warning "Failed to remove backup $($backup.Timestamp): $($_.Exception.Message)"
        }
    }

    return ,$removed  # Force array return
}

<#
.SYNOPSIS
    Performs an automatic rollback during update failure.

.DESCRIPTION
    This function is called automatically when an update fails. It restores files from
    the specified backup and logs the rollback operation.

.PARAMETER ProjectRoot
    Root directory of the SpecKit project. Defaults to current directory.

.PARAMETER BackupPath
    Full path to the backup directory to restore from.

.EXAMPLE
    Invoke-AutomaticRollback -ProjectRoot "C:\Projects\MyProject" -BackupPath $backupPath
#>
function Invoke-AutomaticRollback {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ProjectRoot = $PWD,

        [Parameter(Mandatory)]
        [string]$BackupPath
    )

    Write-Host "AUTOMATIC ROLLBACK: Restoring from backup due to update failure..."
    Write-Verbose "Rollback backup path: $BackupPath"

    try {
        Restore-SpecKitBackup -ProjectRoot $ProjectRoot -BackupPath $BackupPath
        Write-Host "Automatic rollback completed successfully."
    }
    catch {
        Write-Error "CRITICAL: Automatic rollback failed: $($_.Exception.Message)"
        Write-Error "Your project may be in an inconsistent state."
        Write-Error "Manual restoration required from: $BackupPath"
        throw
    }
}

# Export module members
Export-ModuleMember -Function @(
    'New-SpecKitBackup',
    'Restore-SpecKitBackup',
    'Get-SpecKitBackups',
    'Remove-OldBackups',
    'Invoke-AutomaticRollback'
)
