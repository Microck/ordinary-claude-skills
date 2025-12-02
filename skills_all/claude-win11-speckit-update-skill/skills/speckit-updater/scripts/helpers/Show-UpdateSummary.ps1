#Requires -Version 7.0

<#
.SYNOPSIS
    Displays detailed update summary after successful update.

.DESCRIPTION
    Shows comprehensive results including:
    - Files updated
    - Files preserved (customized)
    - Conflicts resolved
    - Conflicts skipped
    - Custom commands preserved
    - New official commands added
    - Obsolete commands removed
    - Constitution update status
    - Backup location
    - Summary statistics

.PARAMETER Result
    PSCustomObject containing update results with properties:
    - FilesUpdated: String[] of updated file paths
    - FilesPreserved: String[] of preserved file paths
    - ConflictsResolved: String[] of resolved conflicts
    - ConflictsSkipped: String[] of skipped conflicts
    - CustomFiles: String[] of custom commands
    - CustomCommandsAdded: String[] of new official commands
    - CommandsRemoved: String[] of removed commands
    - ConstitutionUpdateNeeded: Boolean
    - BackupPath: String path to backup

.PARAMETER FromVersion
    Source version tag (e.g., "v0.0.45")

.PARAMETER ToVersion
    Target version tag (e.g., "v0.0.72")

.PARAMETER IsFirstInstall
    Boolean indicating if this is a first-time SpecKit installation
#>

function Show-UpdateSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Result,

        [Parameter(Mandatory=$true)]
        [string]$FromVersion,

        [Parameter(Mandatory=$true)]
        [string]$ToVersion,

        [Parameter(Mandatory=$false)]
        [bool]$IsFirstInstall = $false
    )

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "SpecKit Updated Successfully" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Version: $FromVersion -> $ToVersion" -ForegroundColor Cyan
    Write-Host ""

    # Files updated
    if ($Result.FilesUpdated -and $Result.FilesUpdated.Count -gt 0) {
        Write-Host "Files updated:" -ForegroundColor Green
        foreach ($file in $Result.FilesUpdated) {
            Write-Host "  + $file" -ForegroundColor Green
        }
        Write-Host ""
    }

    # Files preserved
    if ($Result.FilesPreserved -and $Result.FilesPreserved.Count -gt 0) {
        Write-Host "Files preserved (customized):" -ForegroundColor Yellow
        foreach ($file in $Result.FilesPreserved) {
            Write-Host "  -> $file" -ForegroundColor Yellow
        }
        Write-Host ""
    }

    # Conflicts resolved
    if ($Result.ConflictsResolved -and $Result.ConflictsResolved.Count -gt 0) {
        Write-Host "Conflicts resolved:" -ForegroundColor Green
        foreach ($file in $Result.ConflictsResolved) {
            Write-Host "  + $file (manual merge completed)" -ForegroundColor Green
        }
        Write-Host ""
    }

    # Conflicts skipped
    if ($Result.ConflictsSkipped -and $Result.ConflictsSkipped.Count -gt 0) {
        Write-Host "Conflicts skipped (need attention):" -ForegroundColor Red
        foreach ($file in $Result.ConflictsSkipped) {
            Write-Host "  ! $file" -ForegroundColor Red
        }
        Write-Host ""
        Write-Host "Run '/speckit-update' again to resolve remaining conflicts." -ForegroundColor Yellow
        Write-Host ""
    }

    # Custom commands preserved
    if ($Result.CustomFiles -and $Result.CustomFiles.Count -gt 0) {
        Write-Host "Custom commands preserved:" -ForegroundColor Cyan
        foreach ($file in $Result.CustomFiles) {
            Write-Host "  -> $file" -ForegroundColor Cyan
        }
        Write-Host ""
    }

    # New official commands added
    if ($Result.CustomCommandsAdded -and $Result.CustomCommandsAdded.Count -gt 0) {
        Write-Host "New official commands added:" -ForegroundColor Green
        foreach ($file in $Result.CustomCommandsAdded) {
            Write-Host "  + $file" -ForegroundColor Green
        }
        Write-Host ""
    }

    # Obsolete commands removed
    if ($Result.CommandsRemoved -and $Result.CommandsRemoved.Count -gt 0) {
        Write-Host "Obsolete commands removed:" -ForegroundColor DarkGray
        foreach ($file in $Result.CommandsRemoved) {
            Write-Host "  - $file" -ForegroundColor DarkGray
        }
        Write-Host ""
    }

    # Constitution update
    if ($Result.ConstitutionUpdateNeeded) {
        Write-Host "Constitution template updated." -ForegroundColor Cyan

        # Show command with backup path parameter
        if ($Result.BackupPath) {
            $relativeBackupPath = $Result.BackupPath -replace '^.*\.specify\\backups\\', '.specify/backups/'
            Write-Host "Run this to merge intelligently: /speckit.constitution $relativeBackupPath/.specify/memory/constitution.md" -ForegroundColor Cyan
        }
        else {
            Write-Host "Please run '/speckit.constitution' to review changes." -ForegroundColor Cyan
        }

        Write-Host ""
    }

    # Backup information
    if ($Result.BackupPath) {
        Write-Host "Backup saved: $($Result.BackupPath)" -ForegroundColor DarkGray
        Write-Host "To rollback: /speckit-update --rollback" -ForegroundColor DarkGray
        Write-Host ""
    }

    # Summary statistics
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Summary:" -ForegroundColor Green
    Write-Host "  Files updated:        $($Result.FilesUpdated.Count)" -ForegroundColor Green
    Write-Host "  Files preserved:      $($Result.FilesPreserved.Count)" -ForegroundColor Yellow
    Write-Host "  Conflicts resolved:   $($Result.ConflictsResolved.Count)" -ForegroundColor Green

    if ($Result.ConflictsSkipped -and $Result.ConflictsSkipped.Count -gt 0) {
        Write-Host "  Conflicts skipped:    $($Result.ConflictsSkipped.Count)" -ForegroundColor Red
    }

    if ($Result.CustomFiles) {
        Write-Host "  Custom commands:      $($Result.CustomFiles.Count)" -ForegroundColor Cyan
    }

    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""

    # First-time install: Show helpful next steps
    if ($IsFirstInstall) {
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Welcome to SpecKit!" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "SpecKit has been installed successfully." -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "  1. Review installed templates in .specify/ and .claude/commands/" -ForegroundColor Cyan
        Write-Host "  2. Set up your project constitution: /speckit.constitution" -ForegroundColor Cyan
        Write-Host "  3. Start your first feature: /speckit.specify" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Learn more: https://github.com/github/spec-kit" -ForegroundColor DarkGray
        Write-Host ""
    }
}
