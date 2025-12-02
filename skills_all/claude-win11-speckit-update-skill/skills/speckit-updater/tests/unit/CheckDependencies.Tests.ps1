BeforeAll {
    $scriptPath = Join-Path $PSScriptRoot "../../../../.github/scripts/check-dependencies.ps1"
}

Describe "check-dependencies" {
    Context "When checking PowerShell module versions" {
        It "Should return valid JSON structure" {
            # Arrange/Act
            $result = & $scriptPath -RepoRoot $TestDrive | ConvertFrom-Json

            # Assert
            $result.step | Should -Be 'dependency-scan'
            $result.status | Should -Not -BeNullOrEmpty
            $result.timestamp | Should -Not -BeNullOrEmpty
            $result.findings | Should -Not -BeNull
            $result.summary | Should -Not -BeNull
        }

        It "Should pass when no vulnerable modules found" {
            # Arrange/Act
            $result = & $scriptPath -RepoRoot $TestDrive | ConvertFrom-Json

            # Assert
            # This test may pass or warn depending on installed modules
            $result.status | Should -BeIn @('pass', 'warning')
        }

        It "Should include metadata about scanned modules" {
            # Arrange/Act
            $result = & $scriptPath -RepoRoot $TestDrive | ConvertFrom-Json

            # Assert
            $result.metadata | Should -Not -BeNull
            $result.metadata.modules_scanned | Should -BeGreaterThan 0
        }
    }

    Context "When checking manifest files" {
        It "Should scan psd1 manifest files" {
            # Arrange
            $testRoot = Join-Path $TestDrive "dep-test"
            New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

            $manifestPath = Join-Path $testRoot "test.psd1"
            @"
@{
    ModuleVersion = '1.0.0'
    RequiredModules = @(
        @{ModuleName = 'Pester'; ModuleVersion = '4.0.0'}
    )
}
"@ | Set-Content -Path $manifestPath

            # Act
            $result = & $scriptPath -RepoRoot $testRoot | ConvertFrom-Json

            # Assert
            $result.metadata.manifests_checked | Should -BeGreaterThan 0
        }

        It "Should detect vulnerable versions in manifests" {
            # Arrange
            $testRoot = Join-Path $TestDrive "dep-test2"
            New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

            $manifestPath = Join-Path $testRoot "vulnerable.psd1"
            @"
@{
    ModuleVersion = '1.0.0'
    RequiredModules = @(
        @{ModuleName = 'Pester'; ModuleVersion = '4.10.1'}
    )
}
"@ | Set-Content -Path $manifestPath

            # Act
            $result = & $scriptPath -RepoRoot $testRoot | ConvertFrom-Json

            # Assert
            $result.status | Should -Be 'warning'
            $result.findings.Count | Should -BeGreaterThan 0
            $result.findings[0].category | Should -Be 'dependency-vuln'
        }
    }

    Context "When validating result structure" {
        It "Should have correct summary totals" {
            # Arrange/Act
            $result = & $scriptPath -RepoRoot $TestDrive | ConvertFrom-Json

            # Assert
            $expectedTotal = $result.summary.errors + $result.summary.warnings + $result.summary.info
            $result.summary.total | Should -Be $expectedTotal
        }
    }
}
