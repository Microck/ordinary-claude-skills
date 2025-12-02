BeforeAll {
    $scriptPath = Join-Path $PSScriptRoot "../../../../.github/scripts/check-path-security.ps1"
}

Describe "check-path-security" {
    Context "When scanning for path traversal vulnerabilities" {
        It "Should detect unsafe string concatenation" {
            # Arrange
            $testRoot = Join-Path $TestDrive "path-test"
            New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

            $testFile = Join-Path $testRoot "unsafe-concat.ps1"
            Set-Content -Path $testFile -Value '$basePath + "\" + $userInput'

            # Act
            $result = & $scriptPath -RepoRoot $testRoot | ConvertFrom-Json

            # Assert
            $result.status | Should -Be 'warning'
            $result.findings.Count | Should -BeGreaterThan 0
            $result.findings[0].rule | Should -Be 'unsafe-concatenation'
        }

        It "Should detect unsafe string interpolation" {
            # Arrange
            $testRoot = Join-Path $TestDrive "path-test2"
            New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

            $testFile = Join-Path $testRoot "unsafe-interp.ps1"
            Set-Content -Path $testFile -Value '"$basePath\$userInput"'

            # Act
            $result = & $scriptPath -RepoRoot $testRoot | ConvertFrom-Json

            # Assert
            $result.status | Should -Be 'warning'
            $result.findings.Count | Should -BeGreaterThan 0
            $result.findings[0].rule | Should -Be 'unsafe-interpolation'
        }

        It "Should detect dotdot traversal checks" {
            # Arrange
            $testRoot = Join-Path $TestDrive "path-test3"
            New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

            $testFile = Join-Path $testRoot "dotdot.ps1"
            Set-Content -Path $testFile -Value '$path.Contains("..")'

            # Act
            $result = & $scriptPath -RepoRoot $testRoot | ConvertFrom-Json

            # Assert
            $result.status | Should -Be 'warning'
            $result.findings.Count | Should -BeGreaterThan 0
            $result.findings[0].rule | Should -Be 'dotdot-traversal'
        }

        It "Should not flag safe Join-Path usage" {
            # Arrange
            $testRoot = Join-Path $TestDrive "path-test4"
            New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

            $testFile = Join-Path $testRoot "safe.ps1"
            Set-Content -Path $testFile -Value 'Join-Path $basePath $userInput'

            # Act
            $result = & $scriptPath -RepoRoot $testRoot | ConvertFrom-Json

            # Assert
            $result.status | Should -Be 'pass'
            $result.findings.Count | Should -Be 0
        }

        It "Should pass when no unsafe patterns found" {
            # Arrange
            $testRoot = Join-Path $TestDrive "path-test5"
            New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

            $testFile = Join-Path $testRoot "clean.ps1"
            Set-Content -Path $testFile -Value 'Write-Host "Hello World"'

            # Act
            $result = & $scriptPath -RepoRoot $testRoot | ConvertFrom-Json

            # Assert
            $result.status | Should -Be 'pass'
            $result.findings.Count | Should -Be 0
            $result.summary.total | Should -Be 0
        }

        It "Should include file location in findings" {
            # Arrange
            $testRoot = Join-Path $TestDrive "path-test6"
            New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

            $testFile = Join-Path $testRoot "test.ps1"
            Set-Content -Path $testFile -Value '$badPath = $base + "\" + $input'

            # Act
            $result = & $scriptPath -RepoRoot $testRoot | ConvertFrom-Json

            # Assert
            $result.findings.Count | Should -BeGreaterThan 0
            $result.findings[0].file | Should -Not -BeNullOrEmpty
            $result.findings[0].line | Should -BeGreaterThan 0
        }
    }

    Context "When validating result structure" {
        It "Should return valid JSON structure" {
            # Arrange
            $testRoot = Join-Path $TestDrive "path-test7"
            New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

            # Act
            $result = & $scriptPath -RepoRoot $testRoot | ConvertFrom-Json

            # Assert
            $result.step | Should -Be 'path-security'
            $result.status | Should -Not -BeNullOrEmpty
            $result.timestamp | Should -Not -BeNullOrEmpty
            $result.PSObject.Properties['findings'] | Should -Not -BeNull
            $result.summary | Should -Not -BeNull
            $result.summary.total | Should -Be $result.findings.Count
        }
    }
}
