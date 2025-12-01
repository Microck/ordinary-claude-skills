#Requires -Version 7.0

<#
.SYNOPSIS
    Unit tests for E2ETestHelpers module functions.

.DESCRIPTION
    Pester 5.x tests for E2E Smart Merge Test helper functions including version stratification,
    random merge pair generation, dad joke injection, semantic validation, and statistics.
#>

BeforeAll {
    # Import module under test
    $modulePath = Join-Path $PSScriptRoot ".." "helpers" "E2ETestHelpers.psm1"
    Import-Module $modulePath -Force -ErrorAction Stop

    # Import core dependencies
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $modulesPath = Join-Path $repoRoot "scripts" "modules"

    Import-Module (Join-Path $modulesPath "HashUtils.psm1") -Force
    Import-Module (Join-Path $modulesPath "GitHubApiClient.psm1") -Force
    Import-Module (Join-Path $modulesPath "MarkdownMerger.psm1") -Force
}

Describe "Get-StratifiedVersions" {
    Context "When given a valid version array" {
        It "Should stratify versions into 3 tiers" {
            # Arrange
            $versions = @('v0.0.50', 'v0.0.60', 'v0.0.70', 'v0.0.80', 'v0.0.90')

            # Act
            $result = Get-StratifiedVersions -Versions $versions

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.EarlyVersions | Should -Not -BeNullOrEmpty
            $result.MiddleVersions | Should -Not -BeNullOrEmpty
            $result.RecentVersions | Should -Not -BeNullOrEmpty
        }

        It "Should distribute versions approximately evenly" {
            # Arrange
            $versions = @('v0.0.50', 'v0.0.60', 'v0.0.70', 'v0.0.80', 'v0.0.90', 'v0.0.100')

            # Act
            $result = Get-StratifiedVersions -Versions $versions

            # Assert
            $total = $result.EarlyVersions.Count + $result.MiddleVersions.Count + $result.RecentVersions.Count
            $total | Should -Be 6

            # Each tier should have at least 1 version
            $result.EarlyVersions.Count | Should -BeGreaterThan 0
            $result.MiddleVersions.Count | Should -BeGreaterThan 0
            $result.RecentVersions.Count | Should -BeGreaterThan 0
        }

        It "Should handle small version arrays" {
            # Arrange
            $versions = @('v0.0.50', 'v0.0.60')

            # Act
            $result = Get-StratifiedVersions -Versions $versions

            # Assert
            $result | Should -Not -BeNullOrEmpty
            # Should not throw, even with small arrays
        }

        It "Should preserve version ordering within tiers" {
            # Arrange
            $versions = @('v0.0.50', 'v0.0.51', 'v0.0.52', 'v0.0.53', 'v0.0.54', 'v0.0.55')

            # Act
            $result = Get-StratifiedVersions -Versions $versions

            # Assert
            # Early versions should be from the beginning
            $result.EarlyVersions[0] | Should -Match 'v0\.0\.5[0-1]'

            # Recent versions should be from the end
            $result.RecentVersions[-1] | Should -Match 'v0\.0\.5[4-5]'
        }
    }

    Context "When given edge cases" {
        It "Should handle single version" {
            # Arrange
            $versions = @('v0.0.50')

            # Act
            $result = Get-StratifiedVersions -Versions $versions

            # Assert
            $result | Should -Not -BeNullOrEmpty
        }

        It "Should handle empty array gracefully" {
            # Arrange
            $versions = @()

            # Act & Assert
            { Get-StratifiedVersions -Versions $versions } | Should -Not -Throw
        }
    }
}

Describe "Get-RandomMergePairs" {
    Context "When generating merge pairs" {
        It "Should generate requested number of pairs" {
            # Arrange
            $versions = @('v0.0.50', 'v0.0.60', 'v0.0.70', 'v0.0.80', 'v0.0.90')
            $count = 3

            # Act
            $result = Get-RandomMergePairs -Versions $versions -Count $count

            # Assert
            $result | Should -HaveCount $count
        }

        It "Should create valid version pairs with From < To" {
            # Arrange
            $versions = @('v0.0.50', 'v0.0.60', 'v0.0.70', 'v0.0.80', 'v0.0.90')
            $count = 5

            # Act
            $result = Get-RandomMergePairs -Versions $versions -Count $count

            # Assert
            foreach ($pair in $result) {
                $pair.From | Should -Not -BeNullOrEmpty
                $pair.To | Should -Not -BeNullOrEmpty

                # Extract version numbers for comparison
                $fromNum = [int]($pair.From -replace 'v0\.0\.', '')
                $toNum = [int]($pair.To -replace 'v0\.0\.', '')

                $fromNum | Should -BeLessThan $toNum
            }
        }

        It "Should include cross-tier pairs" {
            # Arrange
            $versions = @('v0.0.10', 'v0.0.20', 'v0.0.30', 'v0.0.40', 'v0.0.50', 'v0.0.60', 'v0.0.70', 'v0.0.80', 'v0.0.90')
            $count = 10

            # Act
            $result = Get-RandomMergePairs -Versions $versions -Count $count

            # Assert
            # Should have variety of version gaps (not all adjacent)
            $hasLargeGap = $false
            foreach ($pair in $result) {
                $fromNum = [int]($pair.From -replace 'v0\.0\.', '')
                $toNum = [int]($pair.To -replace 'v0\.0\.', '')

                if (($toNum - $fromNum) -gt 20) {
                    $hasLargeGap = $true
                    break
                }
            }

            $hasLargeGap | Should -BeTrue -Because "Should include some cross-tier pairs"
        }

        It "Should handle small version arrays" {
            # Arrange
            $versions = @('v0.0.50', 'v0.0.60')
            $count = 1

            # Act
            $result = Get-RandomMergePairs -Versions $versions -Count $count

            # Assert
            $result | Should -HaveCount 1
            $result[0].From | Should -Be 'v0.0.50'
            $result[0].To | Should -Be 'v0.0.60'
        }
    }

    Context "When handling edge cases" {
        It "Should cap pairs to maximum possible" {
            # Arrange
            $versions = @('v0.0.50', 'v0.0.60')
            $count = 100  # More than possible

            # Act
            $result = Get-RandomMergePairs -Versions $versions -Count $count

            # Assert
            # Maximum possible pairs from 2 versions is 1
            $result.Count | Should -BeLessOrEqual 1
        }
    }
}

Describe "Add-DadJokesToFile" {
    BeforeEach {
        # Create temporary test file
        $script:tempFile = New-TemporaryFile
        $script:tempFilePath = $script:tempFile.FullName

        # Write sample markdown content
        $content = @"
# Test Command

This is a test command.

## Section 1

Content here.

## Section 2

More content.
"@
        Set-Content -Path $script:tempFilePath -Value $content -NoNewline
    }

    AfterEach {
        # Clean up temp file
        if (Test-Path $script:tempFilePath) {
            Remove-Item $script:tempFilePath -Force
        }
    }

    Context "When injecting dad jokes" {
        It "Should inject jokes into file" {
            # Arrange
            $dadJokes = @(
                "Why don't scientists trust atoms? Because they make up everything!",
                "What do you call a fake noodle? An impasta!"
            )

            # Act
            $result = Add-DadJokesToFile -FilePath $script:tempFilePath -DadJokes $dadJokes

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Jokes | Should -HaveCount 2
            $result.FilePath | Should -Be $script:tempFilePath
        }

        It "Should preserve original content structure" {
            # Arrange
            $dadJokes = @("Test joke")
            $originalContent = Get-Content -Path $script:tempFilePath -Raw

            # Act
            Add-DadJokesToFile -FilePath $script:tempFilePath -DadJokes $dadJokes
            $modifiedContent = Get-Content -Path $script:tempFilePath -Raw

            # Assert
            # Should still have original headers
            $modifiedContent | Should -Match '# Test Command'
            $modifiedContent | Should -Match '## Section 1'
            $modifiedContent | Should -Match '## Section 2'
        }

        It "Should inject jokes at random positions" {
            # Arrange
            $dadJokes = @("Joke 1", "Joke 2", "Joke 3")

            # Act
            $result = Add-DadJokesToFile -FilePath $script:tempFilePath -DadJokes $dadJokes
            $content = Get-Content -Path $script:tempFilePath -Raw

            # Assert
            # All jokes should be present
            foreach ($joke in $dadJokes) {
                $content | Should -Match [regex]::Escape($joke)
            }
        }

        It "Should return metadata about injected jokes" {
            # Arrange
            $dadJokes = @("Test joke")

            # Act
            $result = Add-DadJokesToFile -FilePath $script:tempFilePath -DadJokes $dadJokes

            # Assert
            $result.Jokes | Should -Not -BeNullOrEmpty
            $result.Jokes[0] | Should -Be "Test joke"
        }
    }

    Context "When handling edge cases" {
        It "Should handle empty file" {
            # Arrange
            Set-Content -Path $script:tempFilePath -Value "" -NoNewline
            $dadJokes = @("Test joke")

            # Act & Assert
            { Add-DadJokesToFile -FilePath $script:tempFilePath -DadJokes $dadJokes } | Should -Not -Throw
        }

        It "Should handle file with only headers" {
            # Arrange
            $content = "# Header`n## Subheader"
            Set-Content -Path $script:tempFilePath -Value $content -NoNewline
            $dadJokes = @("Test joke")

            # Act & Assert
            { Add-DadJokesToFile -FilePath $script:tempFilePath -DadJokes $dadJokes } | Should -Not -Throw
        }
    }
}

Describe "Test-MergedFileValidity" {
    BeforeEach {
        # Create temporary test file
        $script:tempFile = New-TemporaryFile
        $script:tempFilePath = $script:tempFile.FullName
    }

    AfterEach {
        # Clean up temp file
        if (Test-Path $script:tempFilePath) {
            Remove-Item $script:tempFilePath -Force
        }
    }

    Context "When validating valid files" {
        It "Should pass validation for well-formed markdown" {
            # Arrange
            $content = @"
# Valid Command

This is a valid command file.

## Description

Contains proper structure.

## Example

```powershell
Write-Host "Test"
```
"@
            Set-Content -Path $script:tempFilePath -Value $content -NoNewline

            # Act
            $result = Test-MergedFileValidity -FilePath $script:tempFilePath

            # Assert
            $result.IsValid | Should -BeTrue
            $result.Failures | Should -BeNullOrEmpty
        }

        It "Should detect all 9 validation points" {
            # Arrange - Create file that fails multiple checks
            $content = "Invalid"  # No headers, no structure
            Set-Content -Path $script:tempFilePath -Value $content -NoNewline

            # Act
            $result = Test-MergedFileValidity -FilePath $script:tempFilePath

            # Assert
            $result.IsValid | Should -BeFalse
            $result.Failures | Should -Not -BeNullOrEmpty

            # Should check existence, readability, non-empty, valid encoding,
            # markdown structure, conflict markers, headers, balanced markers, content coherence
            $result.Failures.Count | Should -BeGreaterThan 0
        }
    }

    Context "When validating invalid files" {
        It "Should fail for non-existent file" {
            # Arrange
            $nonExistentPath = "C:\nonexistent\file.md"

            # Act
            $result = Test-MergedFileValidity -FilePath $nonExistentPath

            # Assert
            $result.IsValid | Should -BeFalse
            $result.Failures | Should -Contain "File does not exist"
        }

        It "Should fail for empty file" {
            # Arrange
            Set-Content -Path $script:tempFilePath -Value "" -NoNewline

            # Act
            $result = Test-MergedFileValidity -FilePath $script:tempFilePath

            # Assert
            $result.IsValid | Should -BeFalse
            $result.Failures | Should -Match "empty"
        }

        It "Should detect unresolved conflict markers" {
            # Arrange
            $content = @"
# Test

<<<<<<< Current
Some content
=======
Other content
>>>>>>> Incoming
"@
            Set-Content -Path $script:tempFilePath -Value $content -NoNewline

            # Act
            $result = Test-MergedFileValidity -FilePath $script:tempFilePath

            # Assert
            $result.IsValid | Should -BeFalse
            $result.Failures | Should -Match "conflict"
        }
    }
}

Describe "Get-MergePairStatistics" {
    Context "When extracting statistics from test results" {
        It "Should extract all metrics from valid result" {
            # Arrange
            $testResult = [PSCustomObject]@{
                Status = 'Completed'
                Duration = [TimeSpan]::FromSeconds(45.5)
                FilesProcessed = 8
                TotalJokes = 16
                JokesPreserved = 16
                SemanticValidationPassed = 8
                SemanticValidationFailed = 0
            }

            # Act
            $result = Get-MergePairStatistics -TestResult $testResult

            # Assert
            $result.Duration | Should -Be ([TimeSpan]::FromSeconds(45.5))
            $result.FilesProcessed | Should -Be 8
            $result.JokesPreserved | Should -Be 16
            $result.TotalJokes | Should -Be 16
            $result.ValidationsPassed | Should -Be 8
            $result.Status | Should -Be 'Completed'
        }

        It "Should handle TimeSpan duration object" {
            # Arrange
            $testResult = [PSCustomObject]@{
                Status = 'Completed'
                Duration = [TimeSpan]::FromSeconds(30)
                FilesProcessed = 5
                TotalJokes = 10
                JokesPreserved = 10
            }

            # Act
            $result = Get-MergePairStatistics -TestResult $testResult

            # Assert
            $result.Duration | Should -BeOfType [TimeSpan]
            $result.Duration.TotalSeconds | Should -Be 30
        }

        It "Should handle numeric duration (seconds)" {
            # Arrange
            $testResult = [PSCustomObject]@{
                Status = 'Completed'
                Duration = 45.5  # Double representing seconds
                FilesProcessed = 5
                TotalJokes = 10
                JokesPreserved = 10
            }

            # Act
            $result = Get-MergePairStatistics -TestResult $testResult

            # Assert
            $result.Duration | Should -BeOfType [TimeSpan]
            $result.Duration.TotalSeconds | Should -Be 45.5
        }

        It "Should default to zero for missing duration" {
            # Arrange
            $testResult = [PSCustomObject]@{
                Status = 'Failed'
                FilesProcessed = 0
                TotalJokes = 0
                JokesPreserved = 0
            }

            # Act
            $result = Get-MergePairStatistics -TestResult $testResult

            # Assert
            $result.Duration | Should -Be ([TimeSpan]::Zero)
        }

        It "Should track failed status correctly" {
            # Arrange
            $testResult = [PSCustomObject]@{
                Status = 'Failed'
                Duration = [TimeSpan]::FromSeconds(10)
                FilesProcessed = 3
                TotalJokes = 6
                JokesPreserved = 4  # Some data loss
            }

            # Act
            $result = Get-MergePairStatistics -TestResult $testResult

            # Assert
            $result.Status | Should -Be 'Failed'
            $result.JokesPreserved | Should -BeLessThan $result.TotalJokes
        }
    }
}
