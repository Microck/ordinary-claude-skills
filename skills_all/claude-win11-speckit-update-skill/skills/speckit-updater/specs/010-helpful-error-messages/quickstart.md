# Developer Quickstart: Helpful Error Messages Implementation

**Feature**: 010-helpful-error-messages
**Date**: 2025-10-22
**Estimated Implementation Time**: 1-2 hours

## Overview

This guide walks through implementing enhanced error messages for the `/speckit-update` command when run in non-SpecKit projects. The implementation is a small, focused enhancement to existing error handling.

## Prerequisites

- PowerShell 7+ installed
- Pester 5.x for testing (`Install-Module -Name Pester -Force`)
- SpecKit Safe Update Skill repository cloned
- Basic familiarity with PowerShell functions and here-strings

## Implementation Steps

### Step 1: Add Helper Functions (15 minutes)

Add two new helper functions to `scripts/helpers/Invoke-PreUpdateValidation.ps1`:

**Location**: After line 21 (after the param block, before the main validation logic)

**Function 1: Test-SpecKitCommandsAvailable**

```powershell
<#
.SYNOPSIS
    Checks if SpecKit commands are installed in Claude Code.

.DESCRIPTION
    Detects whether SpecKit slash commands exist in the user's .claude/commands/
    directory by checking for at least one official SpecKit command file.

.OUTPUTS
    [bool] True if any SpecKit command is found, False otherwise.

.EXAMPLE
    Test-SpecKitCommandsAvailable
    # Returns: $true or $false
#>
function Test-SpecKitCommandsAvailable {
    [CmdletBinding()]
    param()

    try {
        $claudeCommandsDir = Join-Path $env:USERPROFILE ".claude\commands"

        if (-not (Test-Path $claudeCommandsDir)) {
            Write-Verbose "Claude commands directory not found: $claudeCommandsDir"
            return $false
        }

        # Check for any of the core SpecKit commands
        $coreCommands = @(
            "speckit.constitution.md",
            "speckit.specify.md",
            "speckit.plan.md"
        )

        foreach ($cmd in $coreCommands) {
            $cmdPath = Join-Path $claudeCommandsDir $cmd
            if (Test-Path $cmdPath) {
                Write-Verbose "SpecKit command found: $cmdPath"
                return $true
            }
        }

        Write-Verbose "No SpecKit commands found in: $claudeCommandsDir"
        return $false
    }
    catch {
        Write-Verbose "Error checking for SpecKit commands: $($_.Exception.Message)"
        return $false
    }
}
```

**Function 2: Get-HelpfulSpecKitError**

```powershell
<#
.SYNOPSIS
    Generates a helpful error message for non-SpecKit projects.

.DESCRIPTION
    Creates context-aware error messages based on whether SpecKit commands are
    detected in the user's environment. Provides actionable next steps:
    - If commands available: Suggest running /speckit.constitution
    - If not available: Provide link to SpecKit documentation
    - If detection fails: Show both options as fallback

.OUTPUTS
    [string] Formatted error message with educational content and next steps.

.EXAMPLE
    Get-HelpfulSpecKitError
    # Returns multi-line error message string
#>
function Get-HelpfulSpecKitError {
    [CmdletBinding()]
    param()

    try {
        $hasSpecKitCommands = Test-SpecKitCommandsAvailable

        if ($hasSpecKitCommands) {
            # Variant A: Commands available - suggest initialization
            $message = @"
Not a SpecKit project (.specify/ directory not found)

SpecKit is a Claude Code workflow framework that helps build features with specs, plans, and tasks.

To initialize SpecKit in this project, run:

    /speckit.constitution

Then you can use /speckit-update to keep templates up to date.
"@
        }
        else {
            # Variant B: Commands not available - provide documentation link
            $message = @"
Not a SpecKit project (.specify/ directory not found)

SpecKit is a Claude Code workflow framework that helps build features with specs, plans, and tasks.

This updater requires SpecKit to be installed first.

Learn more: https://github.com/github/spec-kit
"@
        }

        return $message
    }
    catch {
        # Fallback: Show both options if detection fails
        Write-Verbose "Failed to detect SpecKit commands, using fallback message: $($_.Exception.Message)"

        $message = @"
Not a SpecKit project (.specify/ directory not found)

SpecKit is a Claude Code workflow framework that helps build features with specs, plans, and tasks.

If SpecKit is already installed:
  • Run: /speckit.constitution

If SpecKit is not installed:
  • Learn more: https://github.com/github/spec-kit
"@

        return $message
    }
}
```

### Step 2: Modify Error Detection Logic (5 minutes)

**Location**: Line 44-48 in `Invoke-PreUpdateValidation` function

**Replace**:
```powershell
# 2. Check if .specify/ directory exists
$specifyDir = Join-Path $ProjectRoot ".specify"
if (-not (Test-Path $specifyDir)) {
    $errors += "Not a SpecKit project (.specify/ directory not found)"
}
```

**With**:
```powershell
# 2. Check if .specify/ directory exists
$specifyDir = Join-Path $ProjectRoot ".specify"
if (-not (Test-Path $specifyDir)) {
    $helpfulError = Get-HelpfulSpecKitError
    $errors += $helpfulError
}
```

### Step 3: Add Unit Tests (20 minutes)

Create or update `tests/unit/Invoke-PreUpdateValidation.Tests.ps1`:

**Add test context for new functions**:

```powershell
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
```

### Step 4: Add Integration Test (15 minutes)

Add to `tests/integration/UpdateOrchestrator.Tests.ps1`:

```powershell
Describe "Non-SpecKit Project Error Handling" {
    It "Shows helpful error when .specify/ doesn't exist" {
        # Setup: Create temp directory without .specify/
        $testDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "test-no-speckit-$(Get-Random)")

        try {
            Push-Location $testDir

            # Execute update-orchestrator with -CheckOnly
            $output = & "$PSScriptRoot\..\..\scripts\update-orchestrator.ps1" -CheckOnly 2>&1 | Out-String

            # Assert: Error message contains helpful content
            $output | Should -Match "SpecKit is a Claude Code workflow framework"
            $output | Should -Match "(speckit\.constitution|github\.com/github/spec-kit)"
            $output | Should -Match "Not a SpecKit project"
        }
        finally {
            Pop-Location
            Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
```

### Step 5: Run Tests (10 minutes)

```powershell
# Run unit tests only
.\tests\test-runner.ps1 -Unit

# Run integration tests
.\tests\test-runner.ps1 -Integration

# Run all tests
.\tests\test-runner.ps1
```

**Expected Results**:
- All existing tests continue to pass (no regressions)
- New unit tests pass (6 tests for new functions)
- Integration test passes (helpful error displayed)

### Step 6: Manual Testing (10 minutes)

**Test Case 1: SpecKit commands available**
```powershell
# Ensure SpecKit skill is installed in your environment
cd C:\temp\test-project-without-speckit
/speckit-update

# Expected: Error message with /speckit.constitution suggestion
```

**Test Case 2: SpecKit not installed** (simulate)
```powershell
# Temporarily hide .claude\commands directory
mv $env:USERPROFILE\.claude\commands $env:USERPROFILE\.claude\commands.backup

cd C:\temp\test-project-without-speckit
/speckit-update

# Expected: Error message with documentation link

# Restore directory
mv $env:USERPROFILE\.claude\commands.backup $env:USERPROFILE\.claude\commands
```

**Test Case 3: Normal SpecKit project** (regression check)
```powershell
cd C:\path\to\speckit-project-with-specify-dir
/speckit-update --check-only

# Expected: Normal validation, no error about missing .specify/
```

### Step 7: Update Documentation (5 minutes)

**Add entry to CHANGELOG.md under [Unreleased]**:
```markdown
## [Unreleased]

### Added
- Helpful error messages when `/speckit-update` is run in non-SpecKit projects
  - Context-aware messages detect if SpecKit commands are installed
  - Suggests `/speckit.constitution` for users with SpecKit installed
  - Provides documentation link for users without SpecKit
  - Fixes #13
```

## File Checklist

After implementation, verify these files are modified:

- [ ] `scripts/helpers/Invoke-PreUpdateValidation.ps1` - Enhanced with 2 new functions
- [ ] `tests/unit/Invoke-PreUpdateValidation.Tests.ps1` - Added 6 new unit tests
- [ ] `tests/integration/UpdateOrchestrator.Tests.ps1` - Added 1 integration test
- [ ] `CHANGELOG.md` - Added entry under [Unreleased]

## Common Pitfalls

### Pitfall 1: Here-String Indentation
**Problem**: PowerShell here-strings preserve all whitespace, including leading spaces.

**Solution**: Start here-string delimiter (`@"`) on same line as assignment, end delimiter (`"@`) at column 0:
```powershell
$message = @"
Line 1
Line 2
"@
```

### Pitfall 2: Test-Path Mock Scope
**Problem**: Multiple `Test-Path` calls in same test require parameter-aware mocking.

**Solution**: Use parameter filters in Mock:
```powershell
Mock Test-Path {
    param($Path)
    if ($Path -match "\.claude\\commands$") { return $true }
    return $false
}
```

### Pitfall 3: Verbose Output in Tests
**Problem**: Tests might not see verbose output from functions.

**Solution**: Functions use `Write-Verbose` correctly; tests don't need to capture verbose stream for assertions.

## Testing Checklist

Before committing:

- [ ] All unit tests pass (`.\tests\test-runner.ps1 -Unit`)
- [ ] All integration tests pass (`.\tests\test-runner.ps1 -Integration`)
- [ ] Manual test: Commands available scenario works
- [ ] Manual test: Commands not available scenario works
- [ ] Manual test: Normal SpecKit project still works (no regression)
- [ ] Code follows PowerShell style guidelines (PascalCase functions, camelCase variables)
- [ ] Comment-based help added to new functions
- [ ] CHANGELOG.md updated

## Next Steps

After implementation is complete and tests pass:

1. Commit changes with message: `feat: add helpful error messages for non-SpecKit projects`
2. Run `/speckit.tasks` to generate task breakdown (if not already done)
3. Create pull request referencing issue #13
4. Request review from maintainers

## Support

If you encounter issues during implementation:

1. Check CLAUDE.md for repository architecture guidance
2. Review existing helper functions for patterns
3. Run tests with `-Verbose` flag for debugging output
4. Check GitHub issue #13 for additional context

**Estimated Total Time**: 1-2 hours for experienced PowerShell developers
