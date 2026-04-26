<#
.SYNOPSIS
    Unit tests for PowerShell code standards enforcement

.DESCRIPTION
    These tests enforce architectural patterns and coding standards across the codebase.
    Prevents regression of common issues like Export-ModuleMember misuse.
#>

BeforeAll {
    $ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
}

Describe "PowerShell Code Standards" {
    Context "Module vs. Helper Pattern Enforcement" {
        It "Helper scripts (.ps1) should NOT contain Export-ModuleMember" {
            $helpersPath = Join-Path $ProjectRoot "scripts\helpers"
            $helperFiles = Get-ChildItem $helpersPath -Filter "*.ps1"

            $violations = @()
            foreach ($file in $helperFiles) {
                $content = Get-Content $file.FullName -Raw
                if ($content -match 'Export-ModuleMember') {
                    $violations += $file.Name
                }
            }

            $violations | Should -BeNullOrEmpty -Because "Dot-sourced helper scripts should not use Export-ModuleMember (causes 'Export-ModuleMember cmdlet can only be called from inside a module' errors)"
        }

        It "Module files (.psm1) SHOULD contain Export-ModuleMember" {
            $modulesPath = Join-Path $ProjectRoot "scripts\modules"
            $moduleFiles = Get-ChildItem $modulesPath -Filter "*.psm1"

            foreach ($file in $moduleFiles) {
                $content = Get-Content $file.FullName -Raw
                $content | Should -Match 'Export-ModuleMember' -Because "Modules should explicitly export functions using Export-ModuleMember"
            }
        }

        It "All 6 helper scripts exist and have valid syntax" {
            $helpersPath = Join-Path $ProjectRoot "scripts\helpers"
            $expectedHelpers = @(
                "Invoke-PreUpdateValidation.ps1",
                "Show-UpdateSummary.ps1",
                "Show-UpdateReport.ps1",
                "Get-UpdateConfirmation.ps1",
                "Invoke-ConflictResolutionWorkflow.ps1",
                "Invoke-RollbackWorkflow.ps1"
            )

            foreach ($helperName in $expectedHelpers) {
                $helperPath = Join-Path $helpersPath $helperName
                Test-Path $helperPath | Should -BeTrue -Because "$helperName should exist"

                # Basic syntax validation - file should parse without errors
                { . $helperPath } | Should -Not -Throw -Because "$helperName should have valid PowerShell syntax"
            }
        }

        It "All 7 module files exist and have valid syntax" {
            $modulesPath = Join-Path $ProjectRoot "scripts\modules"
            $expectedModules = @(
                "HashUtils.psm1",
                "GitHubApiClient.psm1",
                "MarkdownMerger.psm1",
                "ManifestManager.psm1",
                "FingerprintDetector.psm1",
                "BackupManager.psm1",
                "ConflictDetector.psm1"
            )

            foreach ($moduleName in $expectedModules) {
                $modulePath = Join-Path $modulesPath $moduleName
                Test-Path $modulePath | Should -BeTrue -Because "$moduleName should exist"

                # Basic syntax validation - module should import without errors
                { Import-Module $modulePath -Force -ErrorAction Stop } | Should -Not -Throw -Because "$moduleName should have valid PowerShell syntax"
            }
        }
    }

    Context "Orchestrator Structure" {
        It "Orchestrator should have proper error handling for imports" {
            $orchestratorPath = Join-Path $ProjectRoot "scripts\update-orchestrator.ps1"
            $content = Get-Content $orchestratorPath -Raw

            # Should have try-catch blocks around imports
            $content | Should -Match 'try\s*\{[\s\S]*?Import-Module[\s\S]*?\}\s*catch' -Because "Module imports should be wrapped in try-catch for fail-fast behavior"
            $content | Should -Match 'try\s*\{[\s\S]*?\.\s.*helpers[\s\S]*?\}\s*catch' -Because "Helper dot-sourcing should be wrapped in try-catch for fail-fast behavior"
        }

        It "Orchestrator should use -WarningAction SilentlyContinue only (not -ErrorAction)" {
            $orchestratorPath = Join-Path $ProjectRoot "scripts\update-orchestrator.ps1"
            $content = Get-Content $orchestratorPath -Raw

            # Should suppress warnings but NOT errors
            $content | Should -Match 'WarningAction\s+SilentlyContinue' -Because "Unapproved verb warnings should be suppressed"

            # Should NOT have -ErrorAction SilentlyContinue on Import-Module (would mask real errors)
            $importLines = $content -split "`n" | Where-Object { $_ -match 'Import-Module.*\.psm1' }
            foreach ($line in $importLines) {
                $line | Should -Not -Match 'ErrorAction\s+SilentlyContinue' -Because "Error suppression masks real import failures"
            }
        }

        It "Orchestrator should NOT redirect stderr to null (2>)" {
            $orchestratorPath = Join-Path $ProjectRoot "scripts\update-orchestrator.ps1"
            $content = Get-Content $orchestratorPath -Raw

            # Check lines with dot-sourcing
            $dotSourceLines = $content -split "`n" | Where-Object { $_ -match '\.\s+\(Join-Path.*helpers' }
            foreach ($line in $dotSourceLines) {
                $line | Should -Not -Match '2>\s*\$null' -Because "Stderr redirection masks real errors from helper scripts"
            }
        }
    }
}
