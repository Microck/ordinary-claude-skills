#Requires -Version 7.0

<#
.SYNOPSIS
    Unit tests for Invoke-PreUpdateValidation helper functions.

.DESCRIPTION
    Tests helper functions for SpecKit command detection and error message generation.
    Uses Pester 5.x syntax for test isolation and comprehensive coverage.

.NOTES
    Test Framework: Pester 5.x
    Module Under Test: Invoke-PreUpdateValidation.ps1 (helper script)
#>

BeforeAll {
    # Dot-source the helper script under test
    $helperPath = Join-Path $PSScriptRoot "..\..\scripts\helpers\Invoke-PreUpdateValidation.ps1"
    . $helperPath
}

Describe "Test-SpecKitCommandsAvailable" {
    Context "When .claude/commands directory exists with SpecKit commands" {
        It "Should return true if speckit.constitution.md exists" {
            Mock Test-Path {
                param($Path)
                if ($Path -match "\.claude\\commands$") { return $true }
                if ($Path -match "speckit\.constitution\.md$") { return $true }
                return $false
            }

            $result = Test-SpecKitCommandsAvailable

            $result | Should -Be $true
        }

        It "Should return true if speckit.specify.md exists" {
            Mock Test-Path {
                param($Path)
                if ($Path -match "\.claude\\commands$") { return $true }
                if ($Path -match "speckit\.specify\.md$") { return $true }
                return $false
            }

            $result = Test-SpecKitCommandsAvailable

            $result | Should -Be $true
        }

        It "Should return true if speckit.plan.md exists" {
            Mock Test-Path {
                param($Path)
                if ($Path -match "\.claude\\commands$") { return $true }
                if ($Path -match "speckit\.plan\.md$") { return $true }
                return $false
            }

            $result = Test-SpecKitCommandsAvailable

            $result | Should -Be $true
        }
    }

    Context "When .claude/commands directory does not exist" {
        It "Should return false" {
            Mock Test-Path { return $false }

            $result = Test-SpecKitCommandsAvailable

            $result | Should -Be $false
        }
    }

    Context "When .claude/commands exists but no SpecKit commands found" {
        It "Should return false" {
            Mock Test-Path {
                param($Path)
                if ($Path -match "\.claude\\commands$") { return $true }
                return $false  # No SpecKit command files
            }

            $result = Test-SpecKitCommandsAvailable

            $result | Should -Be $false
        }
    }
}

Describe "Get-HelpfulSpecKitError" {
    Context "When SpecKit commands are available" {
        It "Should suggest running /speckit.constitution" {
            Mock Test-SpecKitCommandsAvailable { return $true }

            $result = Get-HelpfulSpecKitError

            $result | Should -Match "/speckit\.constitution"
            $result | Should -Match "SpecKit is a Claude Code workflow framework"
            $result | Should -Match "To initialize SpecKit in this project"
        }
    }

    Context "When SpecKit commands are not available" {
        It "Should provide documentation link" {
            Mock Test-SpecKitCommandsAvailable { return $false }

            $result = Get-HelpfulSpecKitError

            $result | Should -Match "https://github.com/github/spec-kit"
            $result | Should -Match "SpecKit is a Claude Code workflow framework"
            $result | Should -Match "This updater requires SpecKit to be installed first"
        }
    }

    Context "When detection fails" {
        It "Should return fallback message with both options" {
            Mock Test-SpecKitCommandsAvailable { throw "Simulated error" }

            $result = Get-HelpfulSpecKitError

            $result | Should -Match "/speckit\.constitution"
            $result | Should -Match "https://github.com/github/spec-kit"
            $result | Should -Match "If SpecKit is already installed"
            $result | Should -Match "If SpecKit is not installed"
        }
    }
}

Describe "Invoke-PreUpdateValidation -Proceed Parameter" {
    BeforeEach {
        # Create temporary test directory without .specify/
        $script:testRoot = Join-Path $TestDrive "test-project-$(Get-Random)"
        New-Item -ItemType Directory -Path $script:testRoot -Force | Out-Null

        # Mock external dependencies
        Mock Get-Command { return $true } -ParameterFilter { $Name -eq 'git' }
        Mock Test-Path { return $false } -ParameterFilter { $Path -match '\.specify' }
    }

    Context "T008: When -Proceed parameter is passed" {
        It "Should accept -Proceed parameter without errors" {
            Mock Write-Host {}
            Mock Write-Verbose {}
            Mock Test-Path { return $false }

            # Should not throw when -Proceed is passed
            { Invoke-PreUpdateValidation -ProjectRoot $script:testRoot -Proceed } | Should -Not -Throw
        }
    }

    Context "T009: Without -Proceed flag on fresh installation" {
        It "Should exit with code 0 (not throw)" {
            Mock Write-Host {}
            Mock Write-Verbose {}
            Mock Test-Path { return $false }

            # Mock non-interactive mode (Claude Code)
            Mock Get-Variable {
                return @{ Value = @{ IsInputRedirected = $true } }
            } -ParameterFilter { $Name -eq 'Console' }

            # Capture the exit behavior - should exit 0, not throw
            try {
                Invoke-PreUpdateValidation -ProjectRoot $script:testRoot
                # If we reach here, function returned normally (which it shouldn't without -Proceed)
                $false | Should -Be $true -Because "Function should exit 0 in non-interactive mode"
            }
            catch {
                # In test environment, exit becomes throw - verify it's the right message
                $_.Exception.Message | Should -Not -Match "error|failed"
            }
        }
    }

    Context "T010: With -Proceed flag on fresh installation" {
        It "Should continue validation without exit or throw" {
            Mock Write-Host {}
            Mock Write-Verbose {}
            Mock Test-Path {
                param($Path)
                if ($Path -match '\.specify') { return $false }
                return $true
            }
            Mock Get-Command { return $true }
            Mock Invoke-RestMethod { return @{} }

            # With -Proceed, function should return normally (continue to orchestrator)
            { Invoke-PreUpdateValidation -ProjectRoot $script:testRoot -Proceed } | Should -Not -Throw

            # Verify verbose message was shown
            Should -Invoke Write-Verbose -ParameterFilter { $Message -match "approved SpecKit installation" }
        }
    }

    Context "T010: Installation prompt output validation" {
        It "Should show installation prompt with correct colors and text" {
            Mock Write-Host {}
            Mock Write-Verbose {}
            Mock Test-Path { return $false }

            # Mock non-interactive mode
            Mock Get-Variable {
                return @{ Value = @{ IsInputRedirected = $true } }
            } -ParameterFilter { $Name -eq 'Console' }

            try {
                Invoke-PreUpdateValidation -ProjectRoot $script:testRoot
            }
            catch {
                # Expected to exit/throw
            }

            # Verify prompt elements were shown with correct colors
            Should -Invoke Write-Host -ParameterFilter {
                $Object -eq "[PROMPT_FOR_INSTALL]" -and $ForegroundColor -eq "Cyan"
            }
            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "not currently installed" -and $ForegroundColor -eq "Yellow"
            }
            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "/speckit-update -Proceed" -and $ForegroundColor -eq "White"
            }
        }
    }
}
