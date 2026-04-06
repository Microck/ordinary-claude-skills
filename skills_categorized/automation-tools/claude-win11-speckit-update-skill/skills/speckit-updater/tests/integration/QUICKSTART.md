# Integration Tests - Quick Start Guide

## Prerequisites

1. Install Pester (if not already installed):
   ```powershell
   Install-Module -Name Pester -Force -SkipPublisherCheck
   ```

2. Ensure PowerShell 7.0+ is installed:
   ```powershell
   $PSVersionTable.PSVersion
   # Should show 7.0 or higher
   ```

## Run All Tests (Recommended First Run)

From the repository root:

```powershell
# Navigate to repository root
cd C:\Users\bobby\src\claude-Win11-SpecKit-Safe-Update-Skill

# Run all integration tests with detailed output
Invoke-Pester -Path .\tests\integration\UpdateOrchestrator.Tests.ps1 -Output Detailed
```

## Expected Output

```
Starting discovery in 1 files.
Discovery found 8 tests in 245ms.
Running tests.

Describing Update Orchestrator Integration Tests
  Context Scenario 1: Standard Update (No Conflicts)
    [+] Should complete update successfully 2.34s (2.12s|226ms)
    [+] Should update manifest version 145ms (127ms|18ms)
    [+] Should create backup 98ms (89ms|9ms)
    [+] Should update files with new content 112ms (103ms|9ms)

  Context Scenario 2: Update with Customizations
    [+] Should preserve customized files 1.87s (1.75s|122ms)
    [+] Should update non-customized files 134ms (121ms|13ms)
    [+] Should mark customizations in manifest 156ms (144ms|12ms)

  ... (additional scenarios)

Tests completed in 42.5s
Tests Passed: 35, Failed: 0, Skipped: 0 NotRun: 0
```

## Run Specific Test Scenarios

```powershell
# Run only Standard Update tests (Scenario 1)
Invoke-Pester -Path .\tests\integration\UpdateOrchestrator.Tests.ps1 `
  -FullName "*Scenario 1*" -Output Detailed

# Run only Conflict Resolution tests (Scenario 3)
Invoke-Pester -Path .\tests\integration\UpdateOrchestrator.Tests.ps1 `
  -FullName "*Scenario 3*" -Output Detailed

# Run only Rollback tests (Scenario 6)
Invoke-Pester -Path .\tests\integration\UpdateOrchestrator.Tests.ps1 `
  -FullName "*Scenario 6*" -Output Detailed
```

## Validate Syntax Only

```powershell
# Quick syntax check without running tests
.\tests\integration\validate-syntax.ps1
```

## Troubleshooting

### Tests Fail Immediately

**Problem:** Module import errors

**Solution:**
```powershell
# Verify all modules exist
Get-ChildItem .\scripts\modules\*.psm1

# Should show:
# - HashUtils.psm1
# - VSCodeIntegration.psm1
# - GitHubApiClient.psm1
# - ManifestManager.psm1
# - BackupManager.psm1
# - ConflictDetector.psm1
```

### Tests Hang

**Problem:** Waiting for user input (mocks not working)

**Solution:**
```powershell
# Ensure you're using Pester 5.x (not older versions)
Get-Module Pester -ListAvailable

# If you see version 3.x or 4.x, update:
Install-Module -Name Pester -Force -SkipPublisherCheck
```

### Cleanup Errors

**Problem:** Test projects not cleaned up

**Solution:**
```powershell
# Manually clean up test projects in temp directory
Get-ChildItem $env:TEMP -Filter "test-project-*" -Directory |
  Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
```

## Understanding Test Results

### ✅ All Tests Pass

Great! The update orchestrator is working correctly across all scenarios.

### ❌ Some Tests Fail

1. **Check the failure message** - It will tell you which assertion failed
2. **Look at the scenario** - Read the test description to understand what should happen
3. **Check recent changes** - Did you modify orchestrator logic?
4. **Run with -Verbose** - Get detailed output:
   ```powershell
   Invoke-Pester -Path .\tests\integration\UpdateOrchestrator.Tests.ps1 -Output Detailed -Verbose
   ```

## Test Coverage

The integration tests cover these 8 main scenarios:

1. ✅ **Standard Update (No Conflicts)** - Happy path
2. ✅ **Update with Customizations** - Preserve user changes
3. ✅ **Update with Conflicts** - Merge conflicts
4. ✅ **First-Time Manifest** - Legacy projects
5. ✅ **Custom Commands** - Preserve custom commands
6. ✅ **Rollback on Failure** - Error recovery
7. ✅ **Backup Retention** - Cleanup old backups
8. ✅ **Command Lifecycle** - Add/remove commands

Plus additional scenarios:
- ✅ Check-Only Mode
- ✅ Force Mode
- ✅ Rollback Command
- ✅ Error Handling

## Next Steps

After running integration tests:

1. **Review results** - Ensure all scenarios pass
2. **Check coverage** - Run with code coverage enabled
3. **Test manually** - Run actual updates on test projects
4. **Update docs** - If you added new scenarios

## Full Documentation

For complete details, see:
- **README.md** - Comprehensive test documentation
- **specs/001-safe-update/plan.md** - Implementation plan (Phase 5)
- **UpdateOrchestrator.Tests.ps1** - Test source code with inline comments

## Questions?

- Check the main README: `README.md`
- Review the specification: `specs/001-safe-update/001-safe-update.md`
- See implementation plan: `specs/001-safe-update/plan.md`
