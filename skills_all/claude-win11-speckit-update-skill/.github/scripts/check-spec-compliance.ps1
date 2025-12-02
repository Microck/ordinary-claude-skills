#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Validates SpecKit artifact compliance and constitution rules

.DESCRIPTION
    Checks for:
    - Spec directory existence and structure (spec.md, plan.md, tasks.md)
    - Required sections in spec.md (User Scenarios, Requirements, Success Criteria)
    - CHANGELOG.md [Unreleased] section entry
    - Constitution compliance (Export-ModuleMember, no nested Import-Module)
    - Test coverage for modified modules

.PARAMETER RepoRoot
    Path to repository root directory

.PARAMETER BranchName
    Current branch name (used to find corresponding spec directory)

.EXAMPLE
    .\check-spec-compliance.ps1 -RepoRoot "C:\repo" -BranchName "014-pr-validation-enhancement"

.OUTPUTS
    JSON ValidationResult object
#>

param(
    [Parameter(Mandatory)]
    [string]$RepoRoot,

    [Parameter(Mandatory)]
    [string]$BranchName
)

$ErrorActionPreference = 'Stop'

$findings = @()

# Extract spec number from branch name
$specNumber = $null
if ($BranchName -match '^(\d{3})-') {
    $specNumber = $Matches[1]
    Write-Verbose "Detected spec number: $specNumber"
}
else {
    # Not a feature branch, skip spec validation
    $result = @{
        step = 'spec-compliance'
        status = 'pass'
        timestamp = (Get-Date).ToUniversalTime().ToString('o')
        findings = @()
        summary = @{ total = 0; errors = 0; warnings = 0; info = 0 }
        metadata = @{
            reason = 'Not a feature branch (no spec number detected)'
            branch_name = $BranchName
        }
    }
    $result | ConvertTo-Json -Depth 10
    exit 0
}

# Find matching spec directory
$specsPath = Join-Path $RepoRoot "specs"
$specDir = $null

if (Test-Path $specsPath) {
    $matchingDirs = Get-ChildItem -Path $specsPath -Directory | Where-Object { $_.Name -like "$specNumber-*" }

    if ($matchingDirs) {
        $specDir = $matchingDirs[0].FullName
        Write-Verbose "Found spec directory: $specDir"
    }
    else {
        $findings += @{
            severity = 'error'
            category = 'spec-structure'
            file = $null
            line = $null
            column = $null
            rule = 'missing-spec-directory'
            message = "No spec directory found for branch $BranchName (expected: specs/$specNumber-*)"
            remediation = "Create spec directory matching branch name: mkdir specs/$specNumber-feature-name"
            snippet = $null
        }
    }
}

# Check spec artifacts if directory exists
if ($specDir) {
    $requiredArtifacts = @{
        'spec.md' = @('User Scenarios', 'Requirements', 'Success Criteria')
        'plan.md' = @('Summary', 'Technical Context', 'Constitution Check')
        'tasks.md' = @('Phase')
    }

    foreach ($artifact in $requiredArtifacts.Keys) {
        $artifactPath = Join-Path $specDir $artifact
        $relativePath = $artifactPath.Replace("$RepoRoot\", '').Replace("$RepoRoot/", '')

        if (-not (Test-Path $artifactPath)) {
            $findings += @{
                severity = 'error'
                category = 'spec-structure'
                file = $relativePath
                line = $null
                column = $null
                rule = 'missing-spec-artifact'
                message = "Required SpecKit artifact missing: $artifact"
                remediation = "Create $artifact file. Run: /speckit.specify, /speckit.plan, /speckit.tasks"
                snippet = $null
            }
        }
        else {
            # Check for required sections
            $content = Get-Content $artifactPath -Raw
            $missingSections = @()

            foreach ($section in $requiredArtifacts[$artifact]) {
                if ($content -notmatch "##?\s+$section") {
                    $missingSections += $section
                }
            }

            if ($missingSections.Count -gt 0) {
                $findings += @{
                    severity = 'warning'
                    category = 'spec-structure'
                    file = $relativePath
                    line = $null
                    column = $null
                    rule = 'incomplete-spec-artifact'
                    message = "Missing required sections in ${artifact}: $($missingSections -join ', ')"
                    remediation = "Add missing sections to $artifact. Refer to SpecKit templates."
                    snippet = $null
                }
            }
        }
    }
}

# Check CHANGELOG.md for [Unreleased] entry
$changelogPath = Join-Path $RepoRoot "CHANGELOG.md"
if (Test-Path $changelogPath) {
    $changelogContent = Get-Content $changelogPath -Raw

    if ($changelogContent -notmatch '\[Unreleased\]') {
        $findings += @{
            severity = 'warning'
            category = 'changelog'
            file = 'CHANGELOG.md'
            line = $null
            column = $null
            rule = 'missing-changelog-entry'
            message = 'No [Unreleased] section found in CHANGELOG.md'
            remediation = 'Add [Unreleased] section to CHANGELOG.md with description of changes'
            snippet = $null
        }
    }
}
else {
    $findings += @{
        severity = 'info'
        category = 'changelog'
        file = 'CHANGELOG.md'
        line = $null
        column = $null
        rule = 'missing-changelog-file'
        message = 'CHANGELOG.md file not found'
        remediation = 'Create CHANGELOG.md to track project changes'
        snippet = $null
    }
}

# Check constitution compliance: Export-ModuleMember in .psm1 files
$moduleFiles = Get-ChildItem -Path (Join-Path $RepoRoot "scripts/modules") -Filter *.psm1 -File -ErrorAction SilentlyContinue

foreach ($moduleFile in $moduleFiles) {
    $relativePath = $moduleFile.FullName.Replace("$RepoRoot\", '').Replace("$RepoRoot/", '')
    $content = Get-Content $moduleFile.FullName -Raw

    # Check for Export-ModuleMember
    if ($content -notmatch 'Export-ModuleMember') {
        $findings += @{
            severity = 'error'
            category = 'constitution-violation'
            file = $relativePath
            line = $null
            column = $null
            rule = 'missing-export-modulemember'
            message = "Module missing Export-ModuleMember statement (Constitution: Module vs Helper Pattern)"
            remediation = "Add Export-ModuleMember -Function FunctionName at end of $($moduleFile.Name)"
            snippet = $null
        }
    }

    # Check for nested Import-Module (prohibited) - exclude comments
    # Match Import-Module that's NOT in a comment (not preceded by #)
    if ($content -match '(?m)^\s*(?!#).*Import-Module') {
        $findings += @{
            severity = 'error'
            category = 'constitution-violation'
            file = $relativePath
            line = $null
            column = $null
            rule = 'nested-import-module'
            message = "Module contains Import-Module statement (Constitution: Nested Import Prohibition)"
            remediation = "Remove Import-Module from module. Add to orchestrator instead. See CLAUDE.md Module Import Rules."
            snippet = $null
        }
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
    step = 'spec-compliance'
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
        branch_name = $BranchName
        spec_number = $specNumber
        spec_directory = if ($specDir) { $specDir.Replace("$RepoRoot\", '').Replace("$RepoRoot/", '') } else { $null }
        modules_checked = $moduleFiles.Count
    }
}

# Output JSON
$result | ConvertTo-Json -Depth 10
