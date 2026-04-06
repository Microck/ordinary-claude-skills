#Requires -Version 7.0

<#
.SYNOPSIS
    Validates PowerShell syntax for integration tests
#>

param(
    [string]$TestFile = "UpdateOrchestrator.Tests.ps1"
)

$testPath = Join-Path $PSScriptRoot $TestFile

Write-Host "Validating syntax for: $testPath"

try {
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $testPath,
        [ref]$null,
        [ref]$null
    )

    if ($ast) {
        Write-Host "Syntax validation: PASSED" -ForegroundColor Green
        Write-Host "File is valid PowerShell"
        exit 0
    }
    else {
        Write-Host "Syntax validation: FAILED" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "Syntax validation: ERROR" -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}
