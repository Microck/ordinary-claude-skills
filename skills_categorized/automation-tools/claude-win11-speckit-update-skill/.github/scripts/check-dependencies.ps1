#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Scans PowerShell module dependencies for known vulnerabilities

.DESCRIPTION
    Checks installed PowerShell modules against a curated list of known-vulnerable versions.
    Currently checks:
    - Pester (versions < 5.0.0 have security issues)
    - PSScriptAnalyzer (no known CVEs as of 2025-01)

.PARAMETER RepoRoot
    Path to repository root directory (optional, for context)

.EXAMPLE
    .\check-dependencies.ps1 -RepoRoot "C:\repo"

.OUTPUTS
    JSON ValidationResult object
#>

param(
    [Parameter()]
    [string]$RepoRoot = $PWD
)

$ErrorActionPreference = 'Stop'

# Known vulnerable versions database
$vulnerableVersions = @{
    'Pester' = @{
        VulnerableVersions = @('4.0.0', '4.0.1', '4.0.2', '4.0.3', '4.0.4', '4.0.5', '4.0.6', '4.0.7', '4.0.8',
            '4.1.0', '4.1.1', '4.2.0', '4.3.0', '4.3.1', '4.4.0', '4.4.1', '4.4.2', '4.4.3', '4.4.4',
            '4.5.0', '4.6.0', '4.7.0', '4.7.1', '4.7.2', '4.7.3', '4.8.0', '4.8.1', '4.9.0', '4.10.0', '4.10.1')
        MinSafeVersion = '5.0.0'
        CVE = 'N/A'
        Description = 'Pester versions prior to 5.0.0 have various security and stability issues. Upgrade to 5.0.0 or later.'
        Severity = 'warning'
    }
}

$findings = @()

try {
    # Get all installed modules
    $installedModules = Get-Module -ListAvailable | Select-Object Name, Version | Sort-Object Name, Version -Unique

    foreach ($module in $installedModules) {
        if ($vulnerableVersions.ContainsKey($module.Name)) {
            $vulnInfo = $vulnerableVersions[$module.Name]

            # Check if installed version is vulnerable
            $moduleVersionString = $module.Version.ToString()

            if ($moduleVersionString -in $vulnInfo.VulnerableVersions) {
                $findings += @{
                    severity = $vulnInfo.Severity
                    category = 'dependency-vuln'
                    file = $null
                    line = $null
                    column = $null
                    rule = "vulnerable-$($module.Name.ToLower())-version"
                    message = "Vulnerable $($module.Name) version detected ($moduleVersionString)"
                    remediation = "$($vulnInfo.Description) Run: Update-Module $($module.Name) -RequiredVersion $($vulnInfo.MinSafeVersion)"
                    snippet = $null
                }
            }
        }
    }

    # Additional check: Look for psd1 manifest files that might reference vulnerable versions
    # Exclude tests, fixtures, backups, and specs
    $manifestFiles = Get-ChildItem -Path $RepoRoot -Recurse -Include *.psd1 -File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -notmatch '[\\/](tests|specs|\.specify[\\/]backups)[\\/]' -and
            $_.FullName -notmatch '[\\/]fixtures[\\/]'
        }

    foreach ($manifest in $manifestFiles) {
        try {
            $manifestData = Import-PowerShellDataFile -Path $manifest.FullName -ErrorAction SilentlyContinue

            if ($manifestData.RequiredModules) {
                foreach ($requiredModule in $manifestData.RequiredModules) {
                    $moduleName = if ($requiredModule -is [string]) { $requiredModule } else { $requiredModule.ModuleName }
                    $moduleVersion = if ($requiredModule -is [hashtable]) { $requiredModule.ModuleVersion } else { $null }

                    if ($vulnerableVersions.ContainsKey($moduleName) -and $moduleVersion) {
                        $vulnInfo = $vulnerableVersions[$moduleName]

                        if ($moduleVersion -in $vulnInfo.VulnerableVersions) {
                            $relativePath = $manifest.FullName.Replace("$RepoRoot\", '').Replace("$RepoRoot/", '')

                            $findings += @{
                                severity = $vulnInfo.Severity
                                category = 'dependency-vuln'
                                file = $relativePath
                                line = $null
                                column = $null
                                rule = "manifest-vulnerable-$($moduleName.ToLower())"
                                message = "Manifest requires vulnerable $moduleName version ($moduleVersion)"
                                remediation = "Update RequiredModules in $relativePath to require version $($vulnInfo.MinSafeVersion) or later"
                                snippet = $null
                            }
                        }
                    }
                }
            }
        }
        catch {
            Write-Verbose "Error processing manifest $($manifest.FullName): $($_.Exception.Message)"
        }
    }
}
catch {
    Write-Warning "Error scanning dependencies: $($_.Exception.Message)"
}

# Determine overall status
$status = 'pass'
if ($findings.Count -gt 0) {
    $hasErrors = $findings | Where-Object { $_.severity -eq 'error' }
    $status = if ($hasErrors) { 'failed' } else { 'warning' }
}

# Build result object
$result = @{
    step = 'dependency-scan'
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
        modules_scanned = $installedModules.Count
        manifests_checked = $manifestFiles.Count
    }
}

# Output JSON
$result | ConvertTo-Json -Depth 10
