#Requires -Version 7.0

<#
.SYNOPSIS
    Gets user confirmation to proceed with update.

.DESCRIPTION
    Generates a structured Markdown summary for Claude Code conversational workflow.
    Outputs summary to stdout for Claude to present to user, then waits for
    console confirmation if not in proceed mode.

.PARAMETER FileStates
    Array of FileState objects containing update information.

.PARAMETER CurrentVersion
    Current SpecKit version (e.g., "v0.0.45")

.PARAMETER TargetVersion
    Target SpecKit version (e.g., "v0.0.72")

.PARAMETER Proceed
    If true, skip confirmation prompt and return immediately (Claude already got approval)

.OUTPUTS
    Boolean: $true if user confirmed, $false if user cancelled.
#>

function New-UpdateSummary {
    <#
    .SYNOPSIS
        Generates structured Markdown summary for user approval.

    .DESCRIPTION
        Creates a formatted Markdown summary of proposed changes including:
        - Files to update, add, remove
        - Conflicts requiring manual merge
        - Files preserved (customized)
        - Backup location
        - Custom commands
        Includes [PROMPT_FOR_APPROVAL] marker for Claude Code to detect.

    .PARAMETER FileStates
        Array of FileState objects from conflict analysis.

    .PARAMETER CurrentVersion
        Current SpecKit version (e.g., "v0.0.71")

    .PARAMETER TargetVersion
        Target SpecKit version (e.g., "v0.0.72")

    .OUTPUTS
        String. Markdown-formatted summary with [PROMPT_FOR_APPROVAL] marker.

    .EXAMPLE
        $summary = New-UpdateSummary -FileStates $states -CurrentVersion "v0.0.71" -TargetVersion "v0.0.72"
        Write-Host $summary
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [array]$FileStates,

        [Parameter(Mandatory=$true)]
        [string]$CurrentVersion,

        [Parameter(Mandatory=$true)]
        [string]$TargetVersion
    )

    # Categorize file states
    $toUpdate = @($FileStates | Where-Object { $_.action -eq 'update' })
    $toAdd = @($FileStates | Where-Object { $_.action -eq 'add' })
    $toRemove = @($FileStates | Where-Object { $_.action -eq 'remove' })
    $conflicts = @($FileStates | Where-Object { $_.action -eq 'merge' })
    $toPreserve = @($FileStates | Where-Object { $_.action -eq 'preserve' })

    # Get custom commands (files in .claude/commands/ that aren't official SpecKit commands)
    $customCommands = @($FileStates | Where-Object {
        $_.path -like '.claude/commands/*' -and
        -not $_.is_official
    })

    # Build Markdown summary
    $markdown = @"
## SpecKit Update Summary

**Current Version**: $CurrentVersion
**Available Version**: $TargetVersion

"@

    # Add Files to Update section
    if ($toUpdate.Count -gt 0) {
        $markdown += "### Files to Update ($($toUpdate.Count))`n"
        foreach ($file in $toUpdate) {
            $markdown += "- $($file.path)`n"
        }
        $markdown += "`n"
    }

    # Add Files to Add section
    if ($toAdd.Count -gt 0) {
        $markdown += "### Files to Add ($($toAdd.Count))`n"
        foreach ($file in $toAdd) {
            $markdown += "- $($file.path)`n"
        }
        $markdown += "`n"
    }

    # Add Files to Remove section
    if ($toRemove.Count -gt 0) {
        $markdown += "### Files to Remove ($($toRemove.Count))`n"
        foreach ($file in $toRemove) {
            $markdown += "- $($file.path)`n"
        }
        $markdown += "`n"
    }

    # Add Conflicts Detected section
    if ($conflicts.Count -gt 0) {
        $markdown += "### Conflicts Detected ($($conflicts.Count))`n"
        foreach ($file in $conflicts) {
            $markdown += "- $($file.path)`n"
            # Note: For full implementation, would need userChangeSummary and upstreamChangeSummary
            # For now, using placeholder text
            $markdown += "  * Local: File has been customized`n"
            $markdown += "  * Upstream: New version available`n"
        }
        $markdown += "`n"
    }

    # Add Files Preserved section
    if ($toPreserve.Count -gt 0) {
        $markdown += "### Files Preserved (Customized) ($($toPreserve.Count))`n"
        foreach ($file in $toPreserve) {
            $markdown += "- $($file.path)`n"
        }
        $markdown += "`n"
    }

    # Add Backup Location (will be created during update)
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $backupPath = ".specify/backups/$timestamp/"
    $markdown += "### Backup Location`n"
    $markdown += "$backupPath`n"
    $markdown += "`n"

    # Add Custom Commands section
    if ($customCommands.Count -gt 0) {
        $markdown += "### Custom Commands ($($customCommands.Count))`n"
        foreach ($file in $customCommands) {
            $markdown += "- $($file.path)`n"
        }
        $markdown += "`n"
    }

    # Add approval marker
    $markdown += "---`n"
    $markdown += "[PROMPT_FOR_APPROVAL]`n"

    return $markdown
}

function Get-UpdateConfirmation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$FileStates,

        [Parameter(Mandatory=$false)]
        [string]$CurrentVersion = "unknown",

        [Parameter(Mandatory=$false)]
        [string]$TargetVersion = "latest",

        [Parameter(Mandatory=$false)]
        [switch]$Proceed
    )

    # Check if -Proceed was passed (Claude already got user approval)
    if ($Proceed) {
        Write-Verbose "Proceed flag set, skipping confirmation prompt"
        return $true
    }

    # Generate and output structured Markdown summary
    $summary = New-UpdateSummary -FileStates $FileStates -CurrentVersion $CurrentVersion -TargetVersion $TargetVersion

    # Output summary to stdout (Claude Code will parse this)
    Write-Host ""
    Write-Host $summary
    Write-Host ""

    # Check if running in non-interactive context (Claude Code)
    # In non-interactive mode, stdin is redirected/closed, so Read-Host would auto-complete
    try {
        $isInteractive = -not [Console]::IsInputRedirected
    }
    catch {
        # If IsInputRedirected not available (older PowerShell), assume interactive
        $isInteractive = $true
    }

    if (-not $isInteractive) {
        # Non-interactive mode (Claude Code): Show message and exit
        # Claude will re-invoke with -Proceed after getting user approval via chat
        Write-Host ""
        Write-Host "Running in non-interactive mode (Claude Code)." -ForegroundColor Yellow
        Write-Host "The summary above has been presented to the user for approval." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "To proceed after approval, re-run with: -Proceed" -ForegroundColor Cyan
        Write-Host "To cancel, simply don't re-run the command." -ForegroundColor Cyan
        Write-Host ""

        # Exit with code 0 (success) - not an error, just waiting for approval
        # The orchestrator should check if this returned false and exit gracefully
        return $false
    }

    # Interactive mode (terminal): Prompt for confirmation
    Write-Host "Proceed with update? (Y/n): " -NoNewline -ForegroundColor Cyan
    $response = Read-Host

    # Treat empty response as "yes" in interactive mode (user pressed Enter)
    if ([string]::IsNullOrWhiteSpace($response)) {
        Write-Verbose "Empty response in interactive mode, treating as 'yes'"
        return $true
    }

    return ($response -ne 'n' -and $response -ne 'N')
}
