#Requires -Version 7.0

<#
.SYNOPSIS
    Implements rollback workflow to restore from backup.

.DESCRIPTION
    Lists available backups, prompts user to select one,
    restores files from the selected backup, and updates manifest.

.PARAMETER ProjectRoot
    Path to project root directory

.OUTPUTS
    Exits script with status 0 on success, throws on failure
#>

function Invoke-RollbackWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ProjectRoot = $PWD
    )

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "SpecKit Rollback" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # Import BackupManager module
    $backupModulePath = Join-Path $PSScriptRoot "..\modules\BackupManager.psm1"
    if (-not (Test-Path $backupModulePath)) {
        throw "BackupManager module not found: $backupModulePath"
    }
    Import-Module $backupModulePath -Force

    # Get available backups
    try {
        $backups = Get-SpecKitBackups -ProjectRoot $ProjectRoot
    }
    catch {
        throw "Failed to retrieve backups: $($_.Exception.Message)"
    }

    if (-not $backups -or $backups.Count -eq 0) {
        Write-Host "No backups found." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Backup directory: $ProjectRoot\.specify\backups" -ForegroundColor DarkGray
        Write-Host ""
        throw "No backups available for rollback."
    }

    # Display available backups
    Write-Host "Available backups:" -ForegroundColor Green
    Write-Host ""

    for ($i = 0; $i -lt $backups.Count; $i++) {
        $backup = $backups[$i]
        Write-Host "  $($i + 1). $($backup.timestamp)" -ForegroundColor Cyan

        if ($backup.from_version -and $backup.to_version) {
            Write-Host "     Version: $($backup.from_version) -> $($backup.to_version)" -ForegroundColor DarkGray
        }

        if ($backup.path) {
            Write-Host "     Path: $($backup.path)" -ForegroundColor DarkGray
        }

        Write-Host ""
    }

    # Import VSCode integration for user prompts
    $vscodeModulePath = Join-Path $PSScriptRoot "..\modules\VSCodeIntegration.psm1"
    if (Test-Path $vscodeModulePath) {
        Import-Module $vscodeModulePath -Force
    }

    # Get user selection via console menu
    $selectedBackup = $null

    Write-Host "Select backup to restore (1-$($backups.Count)), or 0 to cancel: " -NoNewline -ForegroundColor Cyan
    $selection = Read-Host

    if ($selection -eq '0') {
        Write-Host "Rollback cancelled by user." -ForegroundColor Yellow
        exit 5
    }

    $selectedIndex = [int]$selection - 1
    if ($selectedIndex -ge 0 -and $selectedIndex -lt $backups.Count) {
        $selectedBackup = $backups[$selectedIndex]
    }

    if (-not $selectedBackup) {
        throw "Invalid backup selection."
    }

    # Confirm rollback
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Confirm Rollback" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "You are about to restore from:" -ForegroundColor Yellow
    Write-Host "  Timestamp: $($selectedBackup.timestamp)" -ForegroundColor Cyan
    if ($selectedBackup.from_version) {
        Write-Host "  Version:   $($selectedBackup.from_version)" -ForegroundColor Cyan
    }
    Write-Host ""
    Write-Host "WARNING: This will overwrite your current files!" -ForegroundColor Red
    Write-Host ""

    Write-Host "Proceed with rollback? (yes/no): " -NoNewline -ForegroundColor Cyan
    $confirm = Read-Host
    if ($confirm -ne 'yes') {
        Write-Host "Rollback cancelled by user. Type 'yes' to confirm." -ForegroundColor Yellow
        exit 5
    }

    # Perform rollback
    Write-Host ""
    Write-Host "Restoring from backup..." -ForegroundColor Cyan

    try {
        Restore-SpecKitBackup -ProjectRoot $ProjectRoot -BackupPath $selectedBackup.path

        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Rollback Successful" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Your SpecKit installation has been restored to:" -ForegroundColor Green
        Write-Host "  Timestamp: $($selectedBackup.timestamp)" -ForegroundColor Cyan
        if ($selectedBackup.from_version) {
            Write-Host "  Version:   $($selectedBackup.from_version)" -ForegroundColor Cyan
        }
        Write-Host ""
        Write-Host "All files have been restored from the backup." -ForegroundColor Green
        Write-Host ""
    }
    catch {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "Rollback Failed" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host ""
        throw "Rollback failed: $($_.Exception.Message)"
    }
}
