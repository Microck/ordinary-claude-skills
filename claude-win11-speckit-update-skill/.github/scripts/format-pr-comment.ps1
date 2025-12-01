#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Formats validation results as a Markdown PR comment

.DESCRIPTION
    Takes ValidationResult JSON input and formats it as a well-structured Markdown comment
    with HTML markers for update-in-place behavior. Groups findings by category and
    includes status indicators, remediation guidance, and timestamps.

.PARAMETER InputJson
    JSON string containing ValidationResult object(s)

.PARAMETER StepNumber
    Step number (2-6) for marker generation

.PARAMETER StepName
    Human-readable step name (e.g., "Claude Security Scan")

.PARAMETER Emoji
    Emoji to use for visual status indication

.PARAMETER MaxFindings
    Maximum number of findings to display before truncating (default: 100)

.PARAMETER RunUrl
    GitHub Actions run URL for linking to full logs (optional)

.EXAMPLE
    $json = Get-Content result.json -Raw
    .\format-pr-comment.ps1 -InputJson $json -StepNumber 5 -StepName "Security Scan" -Emoji "LOCK" -RunUrl "https://github.com/..."

.OUTPUTS
    Markdown-formatted PR comment body with HTML marker
#>

param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [string]$InputJson,

    [Parameter(Mandatory)]
    [ValidateRange(2, 6)]
    [int]$StepNumber,

    [Parameter(Mandatory)]
    [string]$StepName,

    [Parameter(Mandatory)]
    [string]$Emoji,

    [Parameter()]
    [int]$MaxFindings = 100,

    [Parameter()]
    [string]$RunUrl = $null
)

$ErrorActionPreference = 'Stop'

# Parse input JSON
try {
    $validationResult = $InputJson | ConvertFrom-Json
}
catch {
    Write-Error "Failed to parse input JSON: $($_.Exception.Message)"
    exit 1
}

# Generate HTML marker
$marker = "<!-- pr-validation:step-$StepNumber -->"

# Map status to emoji indicators
$statusEmoji = switch ($validationResult.status) {
    'pass' { '✅' }
    'warning' { '⚠️' }
    'failed' { '❌' }
    default { 'ℹ️' }
}

# Build comment header
$comment = @"
$marker
## $Emoji Step $StepNumber/6: $StepName

**Status**: $statusEmoji **$($validationResult.status.ToUpper())**

"@

# Determine if truncation is needed
$totalFindings = $validationResult.findings.Count
$isTruncated = $totalFindings -gt $MaxFindings

# Add summary if findings exist
if ($totalFindings -gt 0) {
    $comment += "`n### Summary`n`n"
    $comment += "- **Total findings**: $($validationResult.summary.total)`n"

    if ($validationResult.summary.errors -gt 0) {
        $comment += "- **Errors**: $($validationResult.summary.errors)`n"
    }
    if ($validationResult.summary.warnings -gt 0) {
        $comment += "- **Warnings**: $($validationResult.summary.warnings)`n"
    }
    if ($validationResult.summary.info -gt 0) {
        $comment += "- **Info**: $($validationResult.summary.info)`n"
    }

    # Truncation notice
    if ($isTruncated) {
        $comment += "`n"
        $comment += "> ⚠️ **Output Truncated**: Showing first $MaxFindings of $totalFindings findings. "
        if ($RunUrl) {
            $comment += "View full output in workflow logs: [View Full Log]($RunUrl)`n"
        }
        else {
            $comment += "View full output in workflow logs.`n"
        }
    }

    $comment += "`n"
}
else {
    $comment += "`n**No issues found!** All checks passed successfully.`n`n"
}

# Group findings by category
if ($totalFindings -gt 0) {
    # Limit findings to MaxFindings if truncation is needed
    $findingsToDisplay = if ($isTruncated) {
        $validationResult.findings | Select-Object -First $MaxFindings
    }
    else {
        $validationResult.findings
    }

    $groupedFindings = $findingsToDisplay | Group-Object -Property category

    $displayedCount = 0
    foreach ($group in $groupedFindings) {
        $categoryName = $group.Name
        $categoryFindings = $group.Group

        # Category header
        $comment += "### $categoryName ($($categoryFindings.Count) finding(s))`n`n"

        # List each finding
        foreach ($finding in $categoryFindings) {
            $displayedCount++

            # Stop if we've reached the limit
            if ($displayedCount -gt $MaxFindings) {
                break
            }
            # Severity indicator
            $severityIcon = switch ($finding.severity) {
                'error' { '🔴' }
                'warning' { '🟡' }
                'info' { '🔵' }
                default { '-' }
            }

            # Build finding entry
            $comment += "$severityIcon **$($finding.rule)**`n"

            # File location
            if ($finding.file) {
                $location = "``$($finding.file)``"
                if ($finding.line) {
                    $location += ":$($finding.line)"
                    if ($finding.column) {
                        $location += ":$($finding.column)"
                    }
                }
                $comment += "  - **Location**: $location`n"
            }

            # Message
            $comment += "  - **Issue**: $($finding.message)`n"

            # Code snippet
            if ($finding.snippet) {
                $comment += "  - **Code**:`n"
                $comment += "    ``````powershell`n"
                $comment += "    $($finding.snippet)`n"
                $comment += "    ```````n"
            }

            # Remediation
            if ($finding.remediation) {
                $comment += "  - **Fix**: $($finding.remediation)`n"
            }

            $comment += "`n"
        }
    }
}

# Add footer
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Variable is used in string interpolation on line 197')]
$timestamp = if ($validationResult.timestamp) {
    $validationResult.timestamp
}
else {
    (Get-Date).ToUniversalTime().ToString('o')
}

$comment += "---`n"
$comment += "_Last updated: ${timestamp}_`n"

# Output the formatted comment
Write-Output $comment
