#Requires -Version 7.0

<#
.SYNOPSIS
    Displays detailed update report for --check-only mode.

.DESCRIPTION
    Shows what would happen during an update without applying changes:
    - Current and target versions
    - Files that would be updated (no conflicts)
    - Files with customizations (will preserve)
    - Conflicts detected (require manual merge)
    - Custom commands (always preserved)
    - New official commands (would be added)
    - Obsolete commands (would be removed)

.PARAMETER FileStates
    Array of FileState objects

.PARAMETER CurrentVersion
    Current SpecKit version tag

.PARAMETER TargetVersion
    Target SpecKit version tag

.PARAMETER CustomFiles
    Array of custom command file paths (optional)
#>

function Show-UpdateReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$FileStates,

        [Parameter(Mandatory=$true)]
        [string]$CurrentVersion,

        [Parameter(Mandatory=$true)]
        [string]$TargetVersion,

        [Parameter(Mandatory=$false)]
        [array]$CustomFiles = @()
    )

    # Categorize files
    $toUpdate = @($FileStates | Where-Object { $_.action -eq 'update' })
    $toPreserve = @($FileStates | Where-Object { $_.action -eq 'preserve' })
    $conflicts = @($FileStates | Where-Object { $_.action -eq 'merge' })
    $toAdd = @($FileStates | Where-Object { $_.action -eq 'add' })
    $toRemove = @($FileStates | Where-Object { $_.action -eq 'remove' })

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "SpecKit Update Check" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Current Version:  $CurrentVersion" -ForegroundColor Yellow
    Write-Host "Latest Version:   $TargetVersion" -ForegroundColor Green

    # Calculate version difference
    # Parse current version explicitly
    if ($CurrentVersion -match 'v?(\d+)\.(\d+)\.(\d+)') {
        $currentParts = @([int]$matches[1], [int]$matches[2], [int]$matches[3])
    }
    else {
        Write-Warning "Could not parse current version: $CurrentVersion"
        return
    }

    # Parse target version explicitly (separate from current)
    if ($TargetVersion -match 'v?(\d+)\.(\d+)\.(\d+)') {
        $targetParts = @([int]$matches[1], [int]$matches[2], [int]$matches[3])
    }
    else {
        Write-Warning "Could not parse target version: $TargetVersion"
        return
    }

    # Simple version comparison (assumes semantic versioning)
    if ($currentParts[2] -lt $targetParts[2]) {
        $patchDiff = $targetParts[2] - $currentParts[2]
        Write-Host "Available Update: $patchDiff patch version(s) behind" -ForegroundColor Yellow
    }
    elseif ($currentParts[1] -lt $targetParts[1]) {
        Write-Host "Available Update: Minor version update available" -ForegroundColor Yellow
    }
    elseif ($currentParts[0] -lt $targetParts[0]) {
        Write-Host "Available Update: Major version update available" -ForegroundColor Red
    }
    else {
        Write-Host "Status: Up to date" -ForegroundColor Green
    }

    Write-Host ""

    # Files that would update (no conflicts)
    if ($toUpdate.Count -gt 0) {
        Write-Host "Files that would update (no conflicts):" -ForegroundColor Green
        foreach ($file in $toUpdate) {
            Write-Host "  + $($file.path)" -ForegroundColor Green
        }
        Write-Host ""
    }

    # Files with customizations (will preserve)
    if ($toPreserve.Count -gt 0) {
        Write-Host "Files with customizations (will preserve):" -ForegroundColor Yellow
        foreach ($file in $toPreserve) {
            $reason = if ($file.path -match 'constitution\.md') {
                "(customized, will use /speckit.constitution)"
            }
            else {
                "(customized)"
            }
            Write-Host "  -> $($file.path) $reason" -ForegroundColor Yellow
        }
        Write-Host ""
    }

    # Conflicts detected (require manual merge)
    if ($conflicts.Count -gt 0) {
        Write-Host "Conflicts detected (require manual merge):" -ForegroundColor Red
        foreach ($conflict in $conflicts) {
            Write-Host "  ! $($conflict.path)" -ForegroundColor Red
            Write-Host "    You modified: Local customizations present" -ForegroundColor DarkGray
            Write-Host "    Upstream changed: New template version available" -ForegroundColor DarkGray
        }
        Write-Host ""
    }

    # New official commands to add
    if ($toAdd.Count -gt 0) {
        Write-Host "New official commands (would be added):" -ForegroundColor Cyan
        foreach ($file in $toAdd) {
            Write-Host "  + $($file.path)" -ForegroundColor Cyan
        }
        Write-Host ""
    }

    # Obsolete commands to remove
    if ($toRemove.Count -gt 0) {
        Write-Host "Obsolete commands (would be removed):" -ForegroundColor DarkGray
        foreach ($file in $toRemove) {
            Write-Host "  - $($file.path)" -ForegroundColor DarkGray
        }
        Write-Host ""
    }

    # Custom commands (always preserved)
    if ($CustomFiles.Count -gt 0) {
        Write-Host "Custom commands (always preserved):" -ForegroundColor Cyan
        foreach ($file in $CustomFiles) {
            Write-Host "  + $file" -ForegroundColor Cyan
        }
        Write-Host ""
    }

    # Summary
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "  Files to update:     $($toUpdate.Count)" -ForegroundColor Green
    Write-Host "  Files to preserve:   $($toPreserve.Count)" -ForegroundColor Yellow
    Write-Host "  Conflicts to merge:  $($conflicts.Count)" -ForegroundColor Red
    Write-Host "  Files to add:        $($toAdd.Count)" -ForegroundColor Cyan
    Write-Host "  Files to remove:     $($toRemove.Count)" -ForegroundColor DarkGray
    Write-Host "  Custom commands:     $($CustomFiles.Count)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # Instructions
    if ($toUpdate.Count -gt 0 -or $conflicts.Count -gt 0 -or $toAdd.Count -gt 0) {
        Write-Host "Run '/speckit-update' to apply updates." -ForegroundColor Green
    }
    else {
        Write-Host "No updates available. Your SpecKit installation is up to date." -ForegroundColor Green
    }

    Write-Host ""
}
