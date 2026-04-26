#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Detects potential path traversal vulnerabilities in PowerShell files

.DESCRIPTION
    Performs static analysis to detect unsafe path construction patterns that could
    lead to path traversal vulnerabilities. Checks for:
    - Unsafe string concatenation with path separators
    - Unsafe string interpolation in paths
    - Direct use of ".." in path operations

    Safe patterns using Join-Path or [System.IO.Path]::Combine are not flagged.

.PARAMETER RepoRoot
    Path to repository root directory

.EXAMPLE
    .\check-path-security.ps1 -RepoRoot "C:\repo"

.OUTPUTS
    JSON ValidationResult object
#>

param(
    [Parameter(Mandatory)]
    [string]$RepoRoot
)

$ErrorActionPreference = 'Stop'

# Validation patterns for unsafe path operations
$unsafePatterns = @{
    'unsafe-concatenation' = @{
        Pattern = '\$\w+\s*\+\s*[''"][\\/]'
        Description = 'Unsafe path concatenation with string operator'
        Example = '$path + "\" + $input'
    }
    'unsafe-interpolation' = @{
        Pattern = '"\$\w+[\\/][^"]*"'
        Description = 'Unsafe path construction using string interpolation'
        Example = '"$basePath\$userInput"'
    }
    'dotdot-traversal' = @{
        Pattern = '\.Contains\([''"]\.\.[''"]\)'
        Description = 'Direct check for ".." traversal pattern'
        Example = '$path.Contains("..")'
    }
}

# Safe patterns to exclude from findings
$safePatterns = @(
    'Join-Path',
    '\[System\.IO\.Path\]::Combine',
    '\[IO\.Path\]::Combine'
)

$findings = @()

# Find all PowerShell files, excluding tests, fixtures, backups, and specs
$psFiles = Get-ChildItem -Path $RepoRoot -Recurse -Include *.ps1, *.psm1 -File -ErrorAction SilentlyContinue |
    Where-Object {
        $_.FullName -notmatch '[\\/](tests|specs|\.specify[\\/]backups)[\\/]' -and
        $_.FullName -notmatch '[\\/]fixtures[\\/]'
    }

foreach ($file in $psFiles) {
    $relativePath = $file.FullName.Replace("$RepoRoot\", '').Replace("$RepoRoot/", '')

    try {
        $content = Get-Content $file.FullName -Raw -ErrorAction Stop

        # Check each unsafe pattern
        foreach ($patternName in $unsafePatterns.Keys) {
            $pattern = $unsafePatterns[$patternName]

            if ($content -match $pattern.Pattern) {
                # Check if this line also uses a safe pattern
                $lines = $content -split "`n"
                $lineNumber = 0

                foreach ($line in $lines) {
                    $lineNumber++

                    if ($line -match $pattern.Pattern) {
                        # Check if line contains safe pattern
                        $isSafe = $false
                        foreach ($safePattern in $safePatterns) {
                            if ($line -match $safePattern) {
                                $isSafe = $true
                                break
                            }
                        }

                        if (-not $isSafe) {
                            $findings += @{
                                severity = 'warning'
                                category = 'path-traversal'
                                file = $relativePath
                                line = $lineNumber
                                column = $null
                                rule = $patternName
                                message = $pattern.Description
                                remediation = "Use Join-Path or [System.IO.Path]::Combine() instead of string concatenation. Example: Join-Path `$basePath `$userInput"
                                snippet = $line.Trim().Substring(0, [Math]::Min(100, $line.Trim().Length))
                            }
                        }
                    }
                }
            }
        }
    }
    catch {
        Write-Verbose "Error processing file $($file.FullName): $($_.Exception.Message)"
    }
}

# Determine overall status
$status = 'pass'
if ($findings.Count -gt 0) {
    $hasErrors = $findings | Where-Object { $_.severity -eq 'error' }
    $status = if ($hasErrors) { 'failed' } else { 'warning' }
}

# Build result object
$result = @{
    step = 'path-security'
    status = $status
    timestamp = (Get-Date).ToUniversalTime().ToString('o')
    findings = $findings
    summary = @{
        total = $findings.Count
        errors = ($findings | Where-Object { $_.severity -eq 'error' }).Count
        warnings = ($findings | Where-Object { $_.severity -eq 'warning' }).Count
        info = ($findings | Where-Object { $_.severity -eq 'info' }).Count
    }
    metadata = @{
        files_scanned = $psFiles.Count
        patterns_checked = $unsafePatterns.Count
    }
}

# Output JSON
$result | ConvertTo-Json -Depth 10
