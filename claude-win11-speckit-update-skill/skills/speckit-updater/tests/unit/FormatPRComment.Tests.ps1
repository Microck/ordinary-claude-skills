BeforeAll {
    $scriptPath = Join-Path $PSScriptRoot "../../../../.github/scripts/format-pr-comment.ps1"
}

Describe "format-pr-comment" {
    Context "When formatting validation results with no findings" {
        It "Should generate clean pass comment" {
            # Arrange
            $inputJson = @{
                step = "security-scan"
                status = "pass"
                timestamp = "2025-10-25T14:32:00Z"
                findings = @()
                summary = @{
                    total = 0
                    errors = 0
                    warnings = 0
                    info = 0
                }
            } | ConvertTo-Json -Depth 10

            # Act
            $result = & $scriptPath -InputJson $inputJson -StepNumber 5 -StepName "Security Scan" -Emoji "LOCK"

            # Assert
            $result | Should -Match "<!-- pr-validation:step-5 -->"
            $result | Should -Match "## LOCK Step 5/6: Security Scan"
            $result | Should -Match "No issues found"
        }
    }

    Context "When formatting validation results with findings" {
        It "Should group findings by category" {
            # Arrange
            $inputJson = @{
                step = "security-scan"
                status = "warning"
                timestamp = "2025-10-25T14:32:00Z"
                findings = @(
                    @{
                        severity = "warning"
                        category = "secret"
                        file = "scripts/test.ps1"
                        line = 45
                        column = 12
                        rule = "aws-access-key"
                        message = "AWS Access Key detected"
                        remediation = "Use environment variables"
                        snippet = '$key = "AKIAIOSFODNN7EXAMPLE"'
                    },
                    @{
                        severity = "error"
                        category = "security-rule"
                        file = "scripts/bad.ps1"
                        line = 10
                        column = 5
                        rule = "PSAvoidUsingInvokeExpression"
                        message = "Avoid Invoke-Expression"
                        remediation = "Use ampersand operator instead"
                        snippet = 'Invoke-Expression $userInput'
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
            $result = & $scriptPath -InputJson $inputJson -StepNumber 5 -StepName "Security Scan" -Emoji "LOCK"

            # Assert
            $result | Should -Match "<!-- pr-validation:step-5 -->"
            $result | Should -Match "## LOCK Step 5/6: Security Scan"
            $result | Should -Match "### Summary"
            $result | Should -Match "Total findings"
            $result | Should -Match "secret"
            $result | Should -Match "security-rule"
            $result | Should -Match "aws-access-key"
            $result | Should -Match "PSAvoidUsingInvokeExpression"
        }

        It "Should include file locations with line numbers" {
            # Arrange
            $inputJson = @{
                step = "test"
                status = "warning"
                timestamp = "2025-10-25T14:32:00Z"
                findings = @(
                    @{
                        severity = "warning"
                        category = "test-category"
                        file = "scripts/example.ps1"
                        line = 100
                        column = 25
                        rule = "TestRule"
                        message = "Test message"
                        remediation = "Test remediation"
                        snippet = $null
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
            $result = & $scriptPath -InputJson $inputJson -StepNumber 3 -StepName "Test Step" -Emoji "CHECK"

            # Assert
            $result | Should -Match "scripts/example.ps1"
            $result | Should -Match "100"
        }

        It "Should include remediation guidance" {
            # Arrange
            $inputJson = @{
                step = "test"
                status = "warning"
                timestamp = "2025-10-25T14:32:00Z"
                findings = @(
                    @{
                        severity = "warning"
                        category = "test-category"
                        file = "test.ps1"
                        line = 1
                        column = $null
                        rule = "TestRule"
                        message = "Test message"
                        remediation = "Use proper method instead"
                        snippet = $null
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
            $result = & $scriptPath -InputJson $inputJson -StepNumber 3 -StepName "Test" -Emoji "CHECK"

            # Assert
            $result | Should -Match "Use proper method instead"
        }
    }

    Context "When handling edge cases" {
        It "Should handle missing timestamp by generating one" {
            # Arrange
            $inputJson = @{
                step = "test"
                status = "pass"
                findings = @()
                summary = @{
                    total = 0
                    errors = 0
                    warnings = 0
                    info = 0
                }
            } | ConvertTo-Json -Depth 10

            # Act
            $result = & $scriptPath -InputJson $inputJson -StepNumber 3 -StepName "Test" -Emoji "CHECK"

            # Assert
            $result | Should -Match "Last updated"
        }

        It "Should handle findings without file location" {
            # Arrange
            $inputJson = @{
                step = "test"
                status = "warning"
                timestamp = "2025-10-25T14:32:00Z"
                findings = @(
                    @{
                        severity = "warning"
                        category = "general"
                        file = $null
                        line = $null
                        column = $null
                        rule = "GeneralRule"
                        message = "General issue"
                        remediation = "Fix it"
                        snippet = $null
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
            $result = & $scriptPath -InputJson $inputJson -StepNumber 3 -StepName "Test" -Emoji "CHECK"

            # Assert
            $result | Should -Match "GeneralRule"
            $result | Should -Match "General issue"
        }
    }

    Context "When validating step numbers" {
        It "Should reject step numbers outside range 2-6" {
            # Arrange
            $inputJson = @{
                step = "test"
                status = "pass"
                findings = @()
                summary = @{ total = 0; errors = 0; warnings = 0; info = 0 }
            } | ConvertTo-Json -Depth 10

            # Act and Assert
            { & $scriptPath -InputJson $inputJson -StepNumber 1 -StepName "Test" -Emoji "X" } | Should -Throw
            { & $scriptPath -InputJson $inputJson -StepNumber 7 -StepName "Test" -Emoji "X" } | Should -Throw
        }

        It "Should accept valid step numbers 2-6" {
            # Arrange
            $inputJson = @{
                step = "test"
                status = "pass"
                findings = @()
                summary = @{ total = 0; errors = 0; warnings = 0; info = 0 }
            } | ConvertTo-Json -Depth 10

            # Act and Assert
            foreach ($stepNum in 2..6) {
                { & $scriptPath -InputJson $inputJson -StepNumber $stepNum -StepName "Test" -Emoji "X" } | Should -Not -Throw
            }
        }
    }
}
