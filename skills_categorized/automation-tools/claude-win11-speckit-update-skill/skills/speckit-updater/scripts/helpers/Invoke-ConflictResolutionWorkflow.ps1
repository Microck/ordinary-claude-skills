#Requires -Version 7.0

<#
.SYNOPSIS
    Implements Flow A conflict resolution workflow.

.DESCRIPTION
    Guides user through conflicts one at a time:
    1. Shows list of all conflicts
    2. For each conflict, asks user: open merge editor, keep mine, use new, or skip
    3. Tracks resolved and skipped conflicts
    4. Returns summary of results

.PARAMETER Conflicts
    Array of conflict objects with properties:
    - path: Relative file path
    - currentHash: Hash of current file
    - upstreamHash: Hash of upstream file
    - originalHash: Hash from manifest

.PARAMETER Templates
    Hashtable of template content (path -> content)

.PARAMETER ProjectRoot
    Path to project root directory

.OUTPUTS
    PSCustomObject with:
    - Resolved: String[] of resolved conflict paths
    - Skipped: String[] of skipped conflict paths
    - KeptMine: String[] of "keep my version" paths
    - UsedNew: String[] of "use new version" paths
#>

function Invoke-ConflictResolutionWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$Conflicts,

        [Parameter(Mandatory=$true)]
        [hashtable]$Templates,

        [Parameter(Mandatory=$false)]
        [string]$ProjectRoot = $PWD
    )

    $resolved = @()
    $skipped = @()
    $keptMine = @()
    $usedNew = @()

    if ($Conflicts.Count -eq 0) {
        Write-Host "No conflicts to resolve." -ForegroundColor Green
        return [PSCustomObject]@{
            Resolved = @()
            Skipped = @()
            KeptMine = @()
            UsedNew = @()
        }
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Conflicts Detected" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "The following files have both local customizations AND upstream changes:" -ForegroundColor Yellow
    Write-Host ""

    foreach ($conflict in $Conflicts) {
        Write-Host "  ! $($conflict.path)" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "You can resolve each conflict by:" -ForegroundColor Cyan
    Write-Host "  1. Opening a 3-way merge editor (recommended)" -ForegroundColor Cyan
    Write-Host "  2. Keeping your version (discard upstream changes)" -ForegroundColor Cyan
    Write-Host "  3. Using the new version (discard your changes)" -ForegroundColor Cyan
    Write-Host "  4. Skipping for now (resolve later)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""

    # Note: This workflow is legacy and not currently used by the main orchestrator
    # The orchestrator uses automatic conflict resolution via MarkdownMerger and Write-SmartConflictResolution

    # Process each conflict (Flow A: one at a time)
    foreach ($conflict in $Conflicts) {
        Write-Host "----------------------------------------" -ForegroundColor DarkGray
        Write-Host "Conflict: $($conflict.path)" -ForegroundColor Yellow
        Write-Host "----------------------------------------" -ForegroundColor DarkGray
        Write-Host ""

        # Show what changed
        Write-Host "This file has been customized locally AND has upstream changes." -ForegroundColor Yellow
        Write-Host ""

        # Provide options
        $options = @(
            "Open merge editor (3-way merge)",
            "Keep my version (discard upstream changes)",
            "Use new version (discard my changes)",
            "Skip for now"
        )

        # Get user choice via console menu
        Write-Host "How to handle this conflict?" -ForegroundColor Cyan
        for ($i = 0; $i -lt $options.Count; $i++) {
            Write-Host "  $($i + 1). $($options[$i])" -ForegroundColor Cyan
        }
        Write-Host ""
        Write-Host "Enter choice (1-$($options.Count)): " -NoNewline -ForegroundColor Cyan
        $choiceInput = Read-Host
        $choice = $options[[int]$choiceInput - 1]

        # Handle user choice
        switch ($choice) {
            { $_ -match "merge editor" } {
                Write-Host "Opening merge editor for $($conflict.path)..." -ForegroundColor Cyan

                if (Get-Command Invoke-ThreeWayMerge -ErrorAction SilentlyContinue) {
                    try {
                        $mergeSuccess = Invoke-ThreeWayMerge -Conflict $conflict -Templates $Templates -ProjectRoot $ProjectRoot

                        if ($mergeSuccess) {
                            Write-Host "  Merge completed successfully" -ForegroundColor Green
                            $resolved += $conflict.path
                        }
                        else {
                            Write-Host "  Merge was cancelled or failed" -ForegroundColor Red
                            $skipped += $conflict.path
                        }
                    }
                    catch {
                        Write-Host "  Merge failed: $($_.Exception.Message)" -ForegroundColor Red
                        $skipped += $conflict.path
                    }
                }
                else {
                    Write-Host "  Merge editor not available" -ForegroundColor Red
                    $skipped += $conflict.path
                }
            }

            { $_ -match "Keep my version" } {
                Write-Host "  Keeping your version of $($conflict.path)" -ForegroundColor Yellow
                # No action needed - file already has user's version
                $keptMine += $conflict.path
            }

            { $_ -match "Use new version" } {
                Write-Host "  Using new version of $($conflict.path)" -ForegroundColor Yellow

                $filePath = Join-Path $ProjectRoot $conflict.path
                if ($Templates.ContainsKey($conflict.path)) {
                    try {
                        $Templates[$conflict.path] | Out-File -FilePath $filePath -Encoding utf8 -Force
                        Write-Host "  File updated successfully" -ForegroundColor Green
                        $usedNew += $conflict.path
                    }
                    catch {
                        Write-Host "  Failed to update file: $($_.Exception.Message)" -ForegroundColor Red
                        $skipped += $conflict.path
                    }
                }
                else {
                    Write-Host "  Template not found for $($conflict.path)" -ForegroundColor Red
                    $skipped += $conflict.path
                }
            }

            default {
                Write-Host "  Skipped $($conflict.path)" -ForegroundColor DarkGray
                $skipped += $conflict.path
            }
        }

        Write-Host ""
    }

    # Return results
    return [PSCustomObject]@{
        Resolved = $resolved
        Skipped = $skipped
        KeptMine = $keptMine
        UsedNew = $usedNew
    }
}
