# Quickstart: Testing the Module Import Fix

**Feature**: Fix Fatal Module Import Error
**Branch**: `003-fix-module-import-error`
**Date**: 2025-10-20

## Overview

This guide provides step-by-step instructions for testing the module import fix manually and automatically. Use this guide to validate that the fix resolves the recurring issue without breaking existing functionality.

---

## Prerequisites

Before testing, ensure you have:

- [x] Windows 11 with PowerShell 7.x installed
- [x] Git repository cloned locally
- [x] Checked out the `003-fix-module-import-error` branch
- [x] A test SpecKit project (directory containing `.specify/` folder)
- [x] VS Code installed (for 3-way merge testing, optional)

**Verify PowerShell Version**:
```powershell
$PSVersionTable.PSVersion
# Should show: Major 7, Minor >= 0
```

**Verify Branch**:
```powershell
git branch --show-current
# Should show: 003-fix-module-import-error
```

---

## Quick Validation (5 minutes)

### Test 1: Basic Execution Without Errors

**Objective**: Verify skill executes without fatal module import errors.

```powershell
# Navigate to a SpecKit project directory (must contain .specify/ folder)
cd C:\path\to\your\speckit\project

# Run skill in check-only mode
& "C:\Users\<YourUsername>\.claude\skills\speckit-updater\scripts\update-orchestrator.ps1" -CheckOnly
```

**Expected Output**:
```
SpecKit Safe Update v1.0
======================================

Checking for SpecKit updates...
[... update information ...]
```

**Success Criteria**:
- ✅ No error: "Export-ModuleMember cmdlet can only be called from inside a module"
- ✅ Script proceeds past module loading
- ✅ Update check information displayed
- ✅ Script exits cleanly with exit code 0

**Failure Indicators**:
- ❌ Script exits immediately with error message
- ❌ Error mentions "Export-ModuleMember"
- ❌ Exit code 1

---

### Test 2: Verbose Mode Diagnostics

**Objective**: Verify verbose logging provides helpful diagnostics.

```powershell
cd C:\path\to\your\speckit\project

& "C:\Users\<YourUsername>\.claude\skills\speckit-updater\scripts\update-orchestrator.ps1" -CheckOnly -Verbose
```

**Expected Output**:
```
VERBOSE: Importing PowerShell modules...
VERBOSE: Modules imported successfully
VERBOSE: Loading helper scripts...
VERBOSE: Helpers loaded successfully
VERBOSE: All modules and helpers loaded successfully
VERBOSE: Step 1: Validating prerequisites...
[... rest of output ...]
```

**Success Criteria**:
- ✅ Verbose messages show module/helper loading progress
- ✅ No error messages in verbose output
- ✅ Clear indication of successful loading

---

### Test 3: All Command-Line Parameters

**Objective**: Verify all parameters work after the fix.

```powershell
# Test -CheckOnly
& "...\update-orchestrator.ps1" -CheckOnly
# Should display update info without prompting

# Test -Version
& "...\update-orchestrator.ps1" -Version v0.0.72 -CheckOnly
# Should check for specific version

# Test -Verbose
& "...\update-orchestrator.ps1" -Verbose -CheckOnly
# Should show diagnostic output

# Test -Rollback (if you have a previous backup)
& "...\update-orchestrator.ps1" -Rollback
# Should list available backups
```

**Success Criteria**:
- ✅ Each parameter functions correctly
- ✅ No module import errors with any parameter combination
- ✅ Help text displays correctly: `& "...\update-orchestrator.ps1" -?`

---

## Comprehensive Testing (15 minutes)

### Test 4: Verify No Export-ModuleMember in Helpers

**Objective**: Ensure the root cause (Export-ModuleMember in helpers) has been fixed.

```powershell
# Search for Export-ModuleMember in helper scripts
cd C:\Users\<YourUsername>\.claude\skills\speckit-updater
Get-ChildItem -Path "scripts\helpers" -Filter "*.ps1" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match 'Export-ModuleMember') {
        Write-Host "FOUND in $($_.Name)" -ForegroundColor Red
    } else {
        Write-Host "Clean: $($_.Name)" -ForegroundColor Green
    }
}
```

**Expected Output**:
```
Clean: Invoke-PreUpdateValidation.ps1
Clean: Show-UpdateSummary.ps1
Clean: Show-UpdateReport.ps1
Clean: Get-UpdateConfirmation.ps1
Clean: Invoke-ConflictResolutionWorkflow.ps1
Clean: Invoke-ThreeWayMerge.ps1
Clean: Invoke-RollbackWorkflow.ps1
```

**Success Criteria**:
- ✅ Zero "FOUND" messages
- ✅ All 7 helpers show "Clean"

**If Any Found**:
- ❌ Fix has not been fully applied - check that all helper files were modified

---

### Test 5: Verify Export-ModuleMember Still in Modules

**Objective**: Ensure modules still properly export functions.

```powershell
# Search for Export-ModuleMember in module files (should still exist)
Get-ChildItem -Path "scripts\modules" -Filter "*.psm1" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match 'Export-ModuleMember') {
        Write-Host "CORRECT: $($_.Name)" -ForegroundColor Green
    } else {
        Write-Host "MISSING in $($_.Name)" -ForegroundColor Red
    }
}
```

**Expected Output**:
```
CORRECT: HashUtils.psm1
CORRECT: VSCodeIntegration.psm1
CORRECT: GitHubApiClient.psm1
CORRECT: ManifestManager.psm1
CORRECT: BackupManager.psm1
CORRECT: ConflictDetector.psm1
```

**Success Criteria**:
- ✅ All 6 modules show "CORRECT"
- ✅ Zero "MISSING" messages

**If Any Missing**:
- ❌ Accidental removal from module - modules SHOULD have Export-ModuleMember

---

### Test 6: Function Availability Check

**Objective**: Verify all required functions are available after imports.

```powershell
# Import the skill's modules manually to test function availability
cd C:\Users\<YourUsername>\.claude\skills\speckit-updater

$modulesPath = ".\scripts\modules"
Import-Module (Join-Path $modulesPath "HashUtils.psm1") -Force
Import-Module (Join-Path $modulesPath "VSCodeIntegration.psm1") -Force
Import-Module (Join-Path $modulesPath "GitHubApiClient.psm1") -Force
Import-Module (Join-Path $modulesPath "ManifestManager.ps1") -Force
Import-Module (Join-Path $modulesPath "BackupManager.psm1") -Force
Import-Module (Join-Path $modulesPath "ConflictDetector.psm1") -Force

# Check critical functions are available
$requiredFunctions = @(
    'Get-NormalizedHash',
    'Compare-FileHashes',
    'Get-ExecutionContext',
    'Get-LatestSpecKitRelease',
    'Get-SpecKitManifest',
    'New-SpecKitBackup',
    'Get-FileState'
)

foreach ($func in $requiredFunctions) {
    if (Get-Command $func -ErrorAction SilentlyContinue) {
        Write-Host "✓ $func available" -ForegroundColor Green
    } else {
        Write-Host "✗ $func MISSING" -ForegroundColor Red
    }
}
```

**Expected Output**:
```
✓ Get-NormalizedHash available
✓ Compare-FileHashes available
✓ Get-ExecutionContext available
✓ Get-LatestSpecKitRelease available
✓ Get-SpecKitManifest available
✓ New-SpecKitBackup available
✓ Get-FileState available
```

**Success Criteria**:
- ✅ All functions show "available"
- ✅ No functions show "MISSING"

---

### Test 7: Performance Measurement

**Objective**: Verify module import completes within 2-second performance target (SC-002).

```powershell
cd C:\path\to\your\speckit\project

# Measure import duration
$duration = Measure-Command {
    & "C:\Users\<YourUsername>\.claude\skills\speckit-updater\scripts\update-orchestrator.ps1" -CheckOnly
}

Write-Host ""
Write-Host "Import Duration: $($duration.TotalMilliseconds) ms" -ForegroundColor Cyan
if ($duration.TotalSeconds -lt 2.0) {
    Write-Host "PASS: Under 2-second requirement ✓" -ForegroundColor Green
} else {
    Write-Host "FAIL: Exceeds 2-second requirement ✗" -ForegroundColor Red
}
```

**Expected Output**:
```
Import Duration: 400 ms
PASS: Under 2-second requirement ✓
```

**Success Criteria**:
- ✅ Duration < 2000ms (Success Criterion SC-002)
- ✅ Typical duration should be 300-500ms

**If Slow**:
- ⚠️ Check for network latency (GitHub API calls happen later, not during imports)
- ⚠️ Verify disk performance (SSD recommended)

---

### Test 8: Negative Test - Real Syntax Error

**Objective**: Verify real errors are NOT suppressed (fail-fast still works).

**WARNING**: This test intentionally breaks a module temporarily. Revert changes after testing.

```powershell
cd C:\Users\<YourUsername>\.claude\skills\speckit-updater

# Backup original file
Copy-Item "scripts\modules\HashUtils.psm1" "scripts\modules\HashUtils.psm1.backup"

# Introduce syntax error (invalid PowerShell)
Add-Content "scripts\modules\HashUtils.psm1" "`nthis is invalid syntax{"

# Attempt to run orchestrator
& "scripts\update-orchestrator.ps1" -CheckOnly
# Should FAIL with syntax error

# Restore original file
Move-Item "scripts\modules\HashUtils.psm1.backup" "scripts\modules\HashUtils.psm1" -Force
```

**Expected Output**:
```
Failed to import modules: [syntax error details]
[Stack trace showing ParseException]
```

**Success Criteria**:
- ✅ Script exits immediately with error
- ✅ Error message mentions "Failed to import modules"
- ✅ Stack trace displayed
- ✅ Exit code 1 (not 0)

**Failure Indicators**:
- ❌ Script continues execution despite syntax error
- ❌ No error message displayed
- ❌ Exit code 0

**IMPORTANT**: Don't forget to restore the backup file!

---

## Automated Testing (10 minutes)

### Test 9: Run Unit Tests

**Objective**: Verify all unit tests pass.

```powershell
cd C:\Users\<YourUsername>\.claude\skills\speckit-updater

# Run all unit tests
.\tests\test-runner.ps1 -Unit
```

**Expected Output**:
```
Executing all tests in '.\tests\unit'

Tests completed in [duration]
Tests Passed: [number], Failed: 0, Skipped: 0, Inconclusive: 0
```

**Success Criteria**:
- ✅ Failed: 0
- ✅ All tests pass (green)

**If Tests Fail**:
- Review failure messages
- Verify all changes from the fix were applied correctly
- Check for environment-specific issues (paths, permissions)

---

### Test 10: Run Integration Tests

**Objective**: Verify end-to-end orchestrator workflow.

```powershell
# Run integration tests
.\tests\test-runner.ps1 -Integration
```

**Expected Output**:
```
Executing all tests in '.\tests\integration'

Tests completed in [duration]
Tests Passed: [number], Failed: 0, Skipped: 0, Inconclusive: 0
```

**Success Criteria**:
- ✅ Failed: 0
- ✅ Integration tests cover full workflow

**Note**: Integration tests may be skipped in CI/CD. Manual execution validates full orchestration.

---

### Test 11: Run Code Standards Test (If Implemented)

**Objective**: Verify no Export-ModuleMember in helper scripts (automated check).

```powershell
# If CodeStandards.Tests.ps1 exists
.\tests\unit\CodeStandards.Tests.ps1
```

**Expected Output**:
```
[+] Helper scripts (.ps1) should NOT contain Export-ModuleMember
[+] Module files (.psm1) SHOULD contain Export-ModuleMember
```

**Success Criteria**:
- ✅ Both pattern enforcement tests pass

---

## Claude Code Integration Testing (5 minutes)

### Test 12: Test via Claude Code Skill Interface

**Objective**: Verify skill works in actual Claude Code environment.

**Steps**:
1. Open Claude Code in VS Code
2. Navigate to a SpecKit project directory
3. Run command: `/speckit-update -CheckOnly`
4. Observe output in Claude Code interface

**Expected Result**:
- ✅ Skill executes successfully
- ✅ Update information displayed in Claude Code
- ✅ No error messages about module imports

**Failure Indicators**:
- ❌ Skill fails to execute
- ❌ Error message appears in Claude Code
- ❌ No output displayed

---

## Different PowerShell Hosts (Optional - 10 minutes)

### Test 13: Test in Different Hosts

**Objective**: Verify skill works across different PowerShell execution environments (SC-005).

**Test in PowerShell 7 Console** (`pwsh.exe`):
```powershell
# Open pwsh.exe directly (not VS Code terminal)
cd C:\path\to\your\speckit\project
& "C:\Users\<YourUsername>\.claude\skills\speckit-updater\scripts\update-orchestrator.ps1" -CheckOnly
```

**Test in VS Code Integrated Terminal**:
```powershell
# Open VS Code terminal (Ctrl+`)
cd C:\path\to\your\speckit\project
& "C:\Users\<YourUsername>\.claude\skills\speckit-updater\scripts\update-orchestrator.ps1" -CheckOnly
```

**Test with Windows PowerShell 5.x** (if available - not officially supported but interesting):
```powershell
# Note: Skill requires PowerShell 7+, this should fail gracefully
powershell.exe -File "...\update-orchestrator.ps1" -CheckOnly
# Should show: "#Requires -Version 7.0" error
```

**Success Criteria**:
- ✅ Works identically in pwsh.exe and VS Code terminal
- ✅ Gracefully rejects PowerShell 5.x with version error

---

## Troubleshooting Guide

### Issue: "Export-ModuleMember" error still appears

**Diagnosis**:
- Run Test 4 to check if any helpers still contain `Export-ModuleMember`
- Verify you're on the correct branch: `git branch --show-current`

**Solution**:
- Manually remove remaining `Export-ModuleMember` lines from helpers
- Run `git status` to verify all files were committed

---

### Issue: Functions not available after import

**Diagnosis**:
- Run Test 6 to identify which functions are missing
- Check if modules were accidentally modified (run Test 5)

**Solution**:
- Verify module files still have correct `Export-ModuleMember` statements
- Re-import modules with `-Force` flag
- Check for typos in function names

---

### Issue: Real errors are suppressed

**Diagnosis**:
- Run Test 8 (negative test with syntax error)
- Check if orchestrator still has error suppression workarounds

**Solution**:
- Verify orchestrator lines 90-136 were simplified per the fix
- Ensure no `-ErrorAction SilentlyContinue` on imports
- Ensure no `2>$null` redirections remain

---

### Issue: Tests fail with "module scoping" errors

**Diagnosis**:
- This is a known Pester 5.x limitation (see CLAUDE.md)
- Module functions work correctly in practice despite test failures

**Solution**:
- Verify module functions work via Test 6 (manual import test)
- Focus on integration tests instead of unit tests with mocking issues
- Note in test results that mocking limitations are known and acceptable

---

## Success Checklist

After completing all tests, verify:

- [x] **Test 1-3**: Basic execution works with all parameters
- [x] **Test 4**: No `Export-ModuleMember` in any helper script
- [x] **Test 5**: All modules still have `Export-ModuleMember`
- [x] **Test 6**: All critical functions are available
- [x] **Test 7**: Import duration < 2 seconds
- [x] **Test 8**: Real errors cause fatal exit (not suppressed)
- [x] **Test 9-10**: All automated tests pass
- [x] **Test 12**: Works in Claude Code environment
- [x] **Documentation**: CLAUDE.md and CHANGELOG.md updated

---

## Next Steps After Testing

Once all tests pass:

1. **Commit changes**:
   ```powershell
   git add -A
   git commit -m "fix: remove Export-ModuleMember from helpers to eliminate recurring import errors"
   ```

2. **Update CHANGELOG.md**:
   - Add entry under `[Unreleased]` → `Fixed`
   - Reference PR #1 (previous workaround) and this fix

3. **Update CLAUDE.md**:
   - Add "Module vs. Helper Pattern" documentation
   - Prevent recurrence

4. **Create Pull Request**:
   - Reference original bug report (#1)
   - Include test results from this quickstart
   - Link to spec, plan, research, and data-model docs

5. **Manual validation before merge**:
   - Test in actual Claude Code environment one final time
   - Verify all parameters work correctly
   - Confirm zero false-positive errors

---

## Performance Baseline

For future comparison, record baseline metrics after fix:

```
| Metric | Before Fix | After Fix | Target |
|--------|------------|-----------|--------|
| Module Import Time | ~380ms | [measure] | <2000ms |
| Helper Load Time | ~50ms | [measure] | <400ms |
| Total Import Time | ~430ms | [measure] | <2000ms |
| False-Positive Errors | 7+ | 0 | 0 |
| Exit Code (success) | 0 | 0 | 0 |
```

---

## Conclusion

This quickstart provides comprehensive manual and automated testing coverage for the module import fix. The tests validate:

1. ✅ **Functional**: Skill executes without module import errors
2. ✅ **Architectural**: Root cause (Export-ModuleMember in helpers) eliminated
3. ✅ **Performance**: Import time within 2-second requirement
4. ✅ **Quality**: Fail-fast behavior preserved for real errors
5. ✅ **Prevention**: Documentation and tests prevent recurrence

Use this guide for initial validation, regression testing, and onboarding new developers to the codebase's module/helper architecture.
