BeforeAll {
    $repoRoot = Join-Path $PSScriptRoot "../.."
    $scriptsPath = Join-Path $repoRoot ".github/scripts"
}

Describe "PR Validation Workflow Integration" {
    Context "When running full security validation workflow" {
        It "Should detect path security issues in real codebase" {
            # Arrange
            $testRoot = Join-Path $TestDrive "security-workflow"
            New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

            $unsafeFile = Join-Path $testRoot "unsafe-code.ps1"
            Set-Content -Path $unsafeFile -Value @'
$basePath = "C:\temp"
$fullPath = $basePath + "\" + $userInput  # Unsafe concatenation
$data = Get-Content $fullPath
'@

            # Act
            $scriptPath = Join-Path $scriptsPath "check-path-security.ps1"
            $result = & $scriptPath -RepoRoot $testRoot | ConvertFrom-Json

            # Assert
            $result.status | Should -Be 'warning'
            $result.findings.Count | Should -BeGreaterThan 0
            $result.findings[0].rule | Should -Be 'unsafe-concatenation'
            $result.findings[0].file | Should -BeLike "*unsafe-code.ps1"
        }

        It "Should detect vulnerable dependencies in real project" {
            # Arrange
            $testRoot = Join-Path $TestDrive "dependency-workflow"
            New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

            $manifestFile = Join-Path $testRoot "test.psd1"
            Set-Content -Path $manifestFile -Value @'
@{
    ModuleVersion = '1.0.0'
    RequiredModules = @(
        @{ ModuleName = 'Pester'; ModuleVersion = '4.10.1' }
    )
}
'@

            # Act
            $scriptPath = Join-Path $scriptsPath "check-dependencies.ps1"
            $result = & $scriptPath -RepoRoot $testRoot | ConvertFrom-Json

            # Assert
            $result.status | Should -Be 'warning'
            $result.findings.Count | Should -BeGreaterThan 0
            $result.findings[0].rule | Should -Be 'vulnerable-dependency'
            $result.findings[0].message | Should -BeLike "*Pester*4.10.1*"
        }

        It "Should validate spec compliance for valid feature branch" {
            # Arrange
            $testRoot = Join-Path $TestDrive "spec-workflow"
            New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

            # Create valid spec structure
            $specDir = Join-Path $testRoot "specs/014-test-feature"
            New-Item -ItemType Directory -Path $specDir -Force | Out-Null

            Set-Content -Path (Join-Path $specDir "spec.md") -Value @'
# Feature Spec

## User Scenarios & Testing
Test scenarios here

## Requirements
- REQ-001: Something

## Success Criteria
- Criteria 1
'@

            Set-Content -Path (Join-Path $specDir "plan.md") -Value "# Plan content"
            Set-Content -Path (Join-Path $specDir "tasks.md") -Value "# Tasks content"

            # Create CHANGELOG.md
            Set-Content -Path (Join-Path $testRoot "CHANGELOG.md") -Value @'
# Changelog

## [Unreleased]
- Feature changes
'@

            # Act
            $scriptPath = Join-Path $scriptsPath "check-spec-compliance.ps1"
            $result = & $scriptPath -RepoRoot $testRoot -BranchName "014-test-feature" | ConvertFrom-Json

            # Assert
            $result.status | Should -Be 'pass'
            $result.findings.Count | Should -Be 0
        }

        It "Should detect missing spec artifacts" {
            # Arrange
            $testRoot = Join-Path $TestDrive "spec-workflow-invalid"
            New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

            # Create partial spec structure (missing tasks.md)
            $specDir = Join-Path $testRoot "specs/015-incomplete"
            New-Item -ItemType Directory -Path $specDir -Force | Out-Null

            Set-Content -Path (Join-Path $specDir "spec.md") -Value "# Spec"
            Set-Content -Path (Join-Path $specDir "plan.md") -Value "# Plan"

            # Act
            $scriptPath = Join-Path $scriptsPath "check-spec-compliance.ps1"
            $result = & $scriptPath -RepoRoot $testRoot -BranchName "015-incomplete" | ConvertFrom-Json

            # Assert
            $result.status | Should -Be 'warning'
            $result.findings | Where-Object { $_.rule -eq 'missing-artifact' } | Should -Not -BeNullOrEmpty
        }
    }

    Context "When formatting validation results as PR comments" {
        It "Should format pass result correctly" {
            # Arrange
            $validationResult = @{
                step = 'security-scan'
                status = 'pass'
                timestamp = (Get-Date).ToUniversalTime().ToString('o')
                findings = @()
                summary = @{
                    total = 0
                    errors = 0
                    warnings = 0
                    info = 0
                }
            } | ConvertTo-Json -Depth 10

            # Act
            $scriptPath = Join-Path $scriptsPath "format-pr-comment.ps1"
            $comment = $validationResult | & $scriptPath -StepNumber 5 -StepName "Security Scan" -Emoji "LOCK"

            # Assert
            $comment | Should -Match "<!-- pr-validation:step-5 -->"
            $comment | Should -Match "Step 5/6: Security Scan"
            $comment | Should -Match "\[PASS\]"
            $comment | Should -Match "No issues found"
        }

        It "Should format warning result with findings correctly" {
            # Arrange
            $validationResult = @{
                step = 'quality-checks'
                status = 'warning'
                timestamp = (Get-Date).ToUniversalTime().ToString('o')
                findings = @(
                    @{
                        severity = 'warning'
                        category = 'linting'
                        file = 'test.ps1'
                        line = 42
                        column = 10
                        rule = 'PSAvoidUsingCmdletAliases'
                        message = 'Avoid using cmdlet aliases'
                        remediation = 'Use full cmdlet name'
                        snippet = 'ls -Path .'
                    }
                )
                summary = @{
                    total = 1
                    errors = 0
                    warnings = 1
                    info = 0
                }
            } | ConvertTo-Json -Depth 10

            # Act
            $scriptPath = Join-Path $scriptsPath "format-pr-comment.ps1"
            $comment = $validationResult | & $scriptPath -StepNumber 3 -StepName "Quality Checks" -Emoji "CHECK"

            # Assert
            $comment | Should -Match "<!-- pr-validation:step-3 -->"
            $comment | Should -Match "\[WARN\]"
            $comment | Should -Match "PSAvoidUsingCmdletAliases"
            $comment | Should -Match "test.ps1:42:10"
            $comment | Should -Match "Avoid using cmdlet aliases"
        }

        It "Should format failed result with multiple findings correctly" {
            # Arrange
            $validationResult = @{
                step = 'spec-compliance'
                status = 'failed'
                timestamp = (Get-Date).ToUniversalTime().ToString('o')
                findings = @(
                    @{
                        severity = 'error'
                        category = 'spec-artifacts'
                        file = 'specs/016-feature'
                        line = $null
                        column = $null
                        rule = 'missing-artifact'
                        message = 'Missing tasks.md'
                        remediation = 'Run /speckit.tasks to generate tasks.md'
                        snippet = $null
                    },
                    @{
                        severity = 'warning'
                        category = 'changelog'
                        file = 'CHANGELOG.md'
                        line = $null
                        column = $null
                        rule = 'missing-unreleased'
                        message = 'CHANGELOG.md missing [Unreleased] section'
                        remediation = 'Add [Unreleased] section to CHANGELOG.md'
                        snippet = $null
                    }
                )
                summary = @{
                    total = 2
                    errors = 1
                    warnings = 1
                    info = 0
                }
            } | ConvertTo-Json -Depth 10

            # Act
            $scriptPath = Join-Path $scriptsPath "format-pr-comment.ps1"
            $comment = $validationResult | & $scriptPath -StepNumber 6 -StepName "Spec Compliance" -Emoji "CLIPBOARD"

            # Assert
            $comment | Should -Match "<!-- pr-validation:step-6 -->"
            $comment | Should -Match "\[FAIL\]"
            $comment | Should -Match "missing-artifact"
            $comment | Should -Match "missing-unreleased"
            $comment | Should -Match "Total findings: 2"
            $comment | Should -Match "Errors: 1"
            $comment | Should -Match "Warnings: 1"
        }
    }

    Context "When running complete validation workflow" {
        It "Should chain all validation steps successfully" {
            # Arrange
            $testRoot = Join-Path $TestDrive "full-workflow"
            New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

            # Create safe code
            $safeFile = Join-Path $testRoot "safe-code.ps1"
            Set-Content -Path $safeFile -Value @'
$basePath = "C:\temp"
$fullPath = Join-Path $basePath $userInput  # Safe usage
$data = Get-Content $fullPath
'@

            # Create valid spec
            $specDir = Join-Path $testRoot "specs/017-full-test"
            New-Item -ItemType Directory -Path $specDir -Force | Out-Null
            Set-Content -Path (Join-Path $specDir "spec.md") -Value @'
# Spec

## User Scenarios & Testing
Scenarios

## Requirements
- REQ-001: Test

## Success Criteria
- Pass
'@
            Set-Content -Path (Join-Path $specDir "plan.md") -Value "# Plan"
            Set-Content -Path (Join-Path $specDir "tasks.md") -Value "# Tasks"

            # Create CHANGELOG
            Set-Content -Path (Join-Path $testRoot "CHANGELOG.md") -Value @'
# Changelog

## [Unreleased]
- Changes
'@

            # Act - Run all validation scripts
            $pathSecurityScript = Join-Path $scriptsPath "check-path-security.ps1"
            $pathResult = & $pathSecurityScript -RepoRoot $testRoot | ConvertFrom-Json

            $dependencyScript = Join-Path $scriptsPath "check-dependencies.ps1"
            $depResult = & $dependencyScript -RepoRoot $testRoot | ConvertFrom-Json

            $specScript = Join-Path $scriptsPath "check-spec-compliance.ps1"
            $specResult = & $specScript -RepoRoot $testRoot -BranchName "017-full-test" | ConvertFrom-Json

            # Assert - All should pass
            $pathResult.status | Should -Be 'pass'
            $depResult.status | Should -Be 'pass'
            $specResult.status | Should -Be 'pass'

            # Format all results
            $formatScript = Join-Path $scriptsPath "format-pr-comment.ps1"

            $pathComment = ($pathResult | ConvertTo-Json -Depth 10) | & $formatScript -StepNumber 5 -StepName "Security" -Emoji "LOCK"
            $specComment = ($specResult | ConvertTo-Json -Depth 10) | & $formatScript -StepNumber 6 -StepName "Spec" -Emoji "CLIPBOARD"

            $pathComment | Should -Match "\[PASS\]"
            $specComment | Should -Match "\[PASS\]"
        }

        It "Should aggregate findings from multiple validation steps" {
            # Arrange
            $testRoot = Join-Path $TestDrive "aggregate-workflow"
            New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

            # Create code with multiple issues
            $unsafeFile1 = Join-Path $testRoot "unsafe1.ps1"
            Set-Content -Path $unsafeFile1 -Value '$path = $base + "\" + $input'

            $unsafeFile2 = Join-Path $testRoot "unsafe2.ps1"
            Set-Content -Path $unsafeFile2 -Value 'if ($path.Contains(".."))'

            # Act
            $scriptPath = Join-Path $scriptsPath "check-path-security.ps1"
            $result = & $scriptPath -RepoRoot $testRoot | ConvertFrom-Json

            # Assert - Should have findings from both files
            $result.findings.Count | Should -BeGreaterOrEqual 2
            $result.summary.total | Should -Be $result.findings.Count
            $result.status | Should -Be 'warning'
        }
    }

    Context "When handling edge cases in validation workflow" {
        It "Should handle empty repository gracefully" {
            # Arrange
            $testRoot = Join-Path $TestDrive "empty-repo"
            New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

            # Act
            $pathScript = Join-Path $scriptsPath "check-path-security.ps1"
            $pathResult = & $pathScript -RepoRoot $testRoot | ConvertFrom-Json

            $depScript = Join-Path $scriptsPath "check-dependencies.ps1"
            $depResult = & $depScript -RepoRoot $testRoot | ConvertFrom-Json

            # Assert
            $pathResult.status | Should -Be 'pass'
            $pathResult.findings.Count | Should -Be 0
            $depResult.status | Should -Be 'pass'
            $depResult.findings.Count | Should -Be 0
        }

        It "Should handle non-feature branch names gracefully" {
            # Arrange
            $testRoot = Join-Path $TestDrive "non-feature"
            New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

            # Act
            $scriptPath = Join-Path $scriptsPath "check-spec-compliance.ps1"
            $result = & $scriptPath -RepoRoot $testRoot -BranchName "bugfix-something" | ConvertFrom-Json

            # Assert
            $result.status | Should -Be 'pass'
            $result.findings.Count | Should -Be 0
            $result.summary.total | Should -Be 0
        }

        It "Should handle malformed JSON gracefully in format script" {
            # Arrange
            $invalidJson = '{ "status": "pass", invalid syntax }'

            # Act/Assert
            $scriptPath = Join-Path $scriptsPath "format-pr-comment.ps1"
            { $invalidJson | & $scriptPath -StepNumber 5 -StepName "Test" -Emoji "X" } | Should -Throw
        }

        It "Should include file location context in all findings" {
            # Arrange
            $testRoot = Join-Path $TestDrive "location-test"
            New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

            $testFile = Join-Path $testRoot "context.ps1"
            Set-Content -Path $testFile -Value @'
$line1 = "safe"
$line2 = $base + "\" + $input  # Line 2: unsafe
$line3 = "safe"
'@

            # Act
            $scriptPath = Join-Path $scriptsPath "check-path-security.ps1"
            $result = & $scriptPath -RepoRoot $testRoot | ConvertFrom-Json

            # Assert
            $result.findings[0].file | Should -BeLike "*context.ps1"
            $result.findings[0].line | Should -Be 2
            $result.findings[0].snippet | Should -BeLike '*$base + "\" + $input*'
        }
    }
}
