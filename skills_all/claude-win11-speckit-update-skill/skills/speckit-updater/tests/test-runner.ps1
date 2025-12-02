#Requires -Version 7.0

<#
.SYNOPSIS
    Runs all Pester tests for SpecKit Safe Update Skill

.DESCRIPTION
    Executes unit and integration tests with code coverage reporting
#>

[CmdletBinding()]
param(
    [switch]$Unit,
    [switch]$Integration,
    [switch]$Coverage
)

# Ensure Pester is available
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Host "Installing Pester..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
}

Import-Module Pester -MinimumVersion 5.0

# Module Import Compliance Check
# Validates that no .psm1 files contain Import-Module statements (prevents scope isolation bugs)
function Test-ModuleImportCompliance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModulesPath
    )

    $violations = @()
    $moduleFiles = Get-ChildItem -Path $ModulesPath -Filter "*.psm1" -ErrorAction SilentlyContinue

    if (-not $moduleFiles) {
        Write-Warning "No module files found in $ModulesPath"
        return $true
    }

    foreach ($file in $moduleFiles) {
        $content = Get-Content -Path $file.FullName -Raw
        $lines = $content -split "`n"

        for ($i = 0; $i -lt $lines.Count; $i++) {
            # Skip comment lines
            if ($lines[$i] -match '^\s*#') { continue }

            # Check for Import-Module statements (case-insensitive)
            if ($lines[$i] -match '^\s*Import-Module\s') {
                $violations += [PSCustomObject]@{
                    File = $file.Name
                    Line = $i + 1
                    Content = $lines[$i].Trim()
                }
            }
        }
    }

    if ($violations.Count -gt 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "Module Import Compliance Check FAILED" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "Found $($violations.Count) violation(s):" -ForegroundColor Red
        foreach ($violation in $violations) {
            Write-Host "  $($violation.File):$($violation.Line) - $($violation.Content)" -ForegroundColor Yellow
        }
        Write-Host ""
        Write-Host "Modules MUST NOT import other modules. All imports should be managed by the orchestrator." -ForegroundColor Red
        Write-Host "See .specify/memory/constitution.md - PowerShell Standards - Module Import Rules" -ForegroundColor Cyan
        Write-Host ""
        return $false
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "✓ Module import compliance check PASSED" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "No nested imports found in $($moduleFiles.Count) module(s)" -ForegroundColor Green
    Write-Host ""
    return $true
}

# Run lint check before tests
Write-Host "`nValidating module import compliance..." -ForegroundColor Cyan
$modulesPath = Join-Path $PSScriptRoot "../scripts/modules"
if (-not (Test-ModuleImportCompliance -ModulesPath $modulesPath)) {
    Write-Error "Lint check failed. Fix violations before running tests."
    exit 1
}

$config = New-PesterConfiguration

# Set paths
if ($Unit) {
    $config.Run.Path = "$PSScriptRoot/unit"
}
elseif ($Integration) {
    $config.Run.Path = "$PSScriptRoot/integration"
}
else {
    $config.Run.Path = "$PSScriptRoot"
}

# Output configuration
$config.Output.Verbosity = 'Detailed'

# Code coverage
if ($Coverage) {
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = "$PSScriptRoot/../scripts/**/*.ps1", "$PSScriptRoot/../scripts/**/*.psm1"
    $config.CodeCoverage.OutputPath = "$PSScriptRoot/coverage/coverage.xml"
}

# Run tests
Write-Host "`n=== Running Tests ===" -ForegroundColor Cyan
$result = Invoke-Pester -Configuration $config

# Exit with appropriate code
if ($result.FailedCount -gt 0) {
    exit 1
}
exit 0
