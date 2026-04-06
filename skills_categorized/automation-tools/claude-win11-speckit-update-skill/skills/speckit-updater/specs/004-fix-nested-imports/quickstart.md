# Phase 1: Quickstart - Manual Testing Guide

**Feature**: Fix Module Function Availability
**Date**: 2025-10-20
**Audience**: Developers, QA testers, Code reviewers

## Purpose

This guide provides step-by-step instructions for manually testing the nested import fix. Use this to verify the fix works correctly before committing changes and to reproduce issues if regressions occur.

## Prerequisites

- Windows 11 with PowerShell 7.x installed
- Git repository cloned: `claude-Win11-SpecKit-Safe-Update-Skill`
- Test SpecKit project (any project with `.specify/` directory) for end-to-end testing
- Branch checked out: `004-fix-nested-imports`

## Quick Verification (5 minutes)

### 1. Verify Lint Check Works

**Test that the lint check detects nested imports:**

```powershell
# From repository root
cd c:\Users\bobby\src\claude-Win11-SpecKit-Safe-Update-Skill

# Run test-runner to trigger lint check
.\tests\test-runner.ps1
```

**Expected Result**: Lint check should PASS (after fix applied) with message:
```
✓ Module import compliance check passed (no nested imports found)
```

**If violations exist** (before fix):
```
Module import compliance check FAILED. Found X violation(s):
  ManifestManager.psm1:19 - Import-Module (Join-Path $PSScriptRoot "HashUtils.psm1") -Force
  ...
```

---

### 2. Verify Module Functions Are Available

**Test that all module functions are accessible in orchestrator scope:**

```powershell
# From repository root
cd c:\Users\bobby\src\claude-Win11-SpecKit-Safe-Update-Skill

# Load modules the same way orchestrator does
$modulesPath = ".\scripts\modules"

Import-Module (Join-Path $modulesPath "HashUtils.psm1") -Force
Import-Module (Join-Path $modulesPath "GitHubApiClient.psm1") -Force
Import-Module (Join-Path $modulesPath "VSCodeIntegration.psm1") -Force
Import-Module (Join-Path $modulesPath "ManifestManager.psm1") -Force
Import-Module (Join-Path $modulesPath "BackupManager.psm1") -Force
Import-Module (Join-Path $modulesPath "ConflictDetector.psm1") -Force

# Verify functions are available
Get-Command -Module HashUtils
Get-Command -Module ManifestManager
Get-Command -Module BackupManager
Get-Command -Module ConflictDetector
Get-Command -Module GitHubApiClient
Get-Command -Module VSCodeIntegration
```

**Expected Result**: Each `Get-Command` should list the module's exported functions without errors.

**Example output**:
```
CommandType     Name                    Version    Source
-----------     ----                    -------    ------
Function        Get-NormalizedHash      0.0        HashUtils
Function        Compare-FileHashes      0.0        HashUtils
Function        Get-SpecKitManifest     0.0        ManifestManager
...
```

---

### 3. Verify Cross-Module Function Calls Work

**Test that modules can call functions from their dependencies:**

```powershell
# From PowerShell session with modules loaded (step 2)

# Test: ManifestManager → HashUtils.Get-NormalizedHash
$testFile = New-TemporaryFile
"test content" | Out-File -FilePath $testFile.FullName
$hash = Get-NormalizedHash -FilePath $testFile.FullName
Write-Host "Hash computed: $hash" -ForegroundColor Green
Remove-Item $testFile.FullName

# Test should complete without "command not recognized" errors
```

**Expected Result**: Hash computed successfully (e.g., `sha256:9f86d081...`), no errors.

---

## Comprehensive Testing (30 minutes)

### 4. Run Full Unit Test Suite

**Verify all existing unit tests still pass:**

```powershell
# From repository root
.\tests\test-runner.ps1 -Unit
```

**Expected Result**:
- Lint check passes
- All 132 unit tests pass (or same pass count as before fix)
- No new failures introduced

**If failures occur**: Investigate whether fix broke module functionality. Check error messages for scope-related issues.

---

### 5. Run Integration Tests

**Verify new cross-module integration tests pass:**

```powershell
# From repository root
.\tests\test-runner.ps1 -Integration
```

**Expected Result**:
- Lint check passes
- `UpdateOrchestrator.Tests.ps1` passes (existing tests)
- `ModuleDependencies.Tests.ps1` passes (new tests added by this fix)

**Key tests to check**:
- "Module Function Availability" context: All modules' functions accessible
- "Cross-Module Function Calls" context: All dependency calls work
- "Dependency Order Enforcement" context: Wrong order causes clear error

---

### 6. End-to-End Skill Execution Test

**Test the full `/speckit-update` workflow in Claude Code:**

#### Setup Test Project

```powershell
# Navigate to a SpecKit project (must have .specify/ directory)
cd c:\Users\bobby\src\tw\webapp-admin-portal  # Replace with your test project
```

#### Test in Claude Code (Preferred)

1. Open test project in VSCode with Claude Code extension
2. Run command: `/speckit-update -CheckOnly`
3. Observe output

**Expected Result**:
```
SpecKit Safe Update v1.0
======================================

Validating prerequisites...
Prerequisites validated successfully

========================================
STEP 3: Load or Create Manifest
========================================

Loading manifest...
Manifest loaded successfully

[... continues through all 15 steps without errors ...]
```

**Critical Check**: No "command not recognized" errors at any step.

#### Test via Direct Script Execution

```powershell
# From test project directory
pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\bobby\.claude\skills\speckit-updater\scripts\update-orchestrator.ps1" -CheckOnly
```

**Expected Result**: Same as Claude Code test above.

---

### 7. Negative Test: Verify Lint Check Catches Violations

**Test that the lint check correctly detects violations:**

#### Intentionally Introduce Violation

```powershell
# Edit a module file (e.g., HashUtils.psm1) to add a nested import
# Add this line temporarily:
# Import-Module SomeModule -Force

# Run test-runner
.\tests\test-runner.ps1
```

**Expected Result**: Lint check FAILS with clear error message:
```
Module import compliance check FAILED. Found 1 violation(s):
  HashUtils.psm1:XX - Import-Module SomeModule -Force

Modules must NOT import other modules. All imports should be managed by the orchestrator.
See .specify/memory/constitution.md - PowerShell Standards - Module Export Rules
```

#### Revert Change

```powershell
# Remove the temporary Import-Module line
# Run test-runner again to verify it passes
.\tests\test-runner.ps1
```

---

## Troubleshooting

### Issue: "Command not recognized" errors persist

**Symptoms**: After applying fix, orchestrator still throws "The term 'Get-SpecKitManifest' is not recognized" errors.

**Diagnosis**:
1. Check if modules were imported correctly:
   ```powershell
   Get-Module HashUtils, ManifestManager, BackupManager, ConflictDetector, GitHubApiClient, VSCodeIntegration
   ```
   Should list all 6 modules.

2. Check if functions are exported:
   ```powershell
   Get-Command -Module ManifestManager
   ```
   Should list exported functions.

3. Check if `Export-ModuleMember` is present in module files:
   ```powershell
   Select-String -Path ".\scripts\modules\*.psm1" -Pattern "Export-ModuleMember"
   ```
   Each module should have exactly one `Export-ModuleMember -Function` statement.

**Solution**: Verify `Export-ModuleMember` lines are correct in all modules (no typos in function names).

---

### Issue: Lint check shows false positives

**Symptoms**: Lint check reports violations in comments or strings.

**Diagnosis**: Check the reported line numbers. If they're in comment blocks, the regex pattern needs refinement.

**Solution**: Update the regex in `Test-ModuleImportCompliance` to ignore commented lines:
```powershell
# Exclude lines starting with # (comments)
if ($lines[$i] -match '^\s*#') { continue }
```

---

### Issue: Tests fail with "module not found" errors

**Symptoms**: Integration tests fail because modules can't be imported.

**Diagnosis**: Check file paths in test scripts. Paths should be relative to repository root.

**Solution**: Verify paths in test files use `$PSScriptRoot` correctly:
```powershell
$modulesPath = Join-Path $PSScriptRoot "../../scripts/modules"
```

---

## Success Criteria Checklist

Before marking this fix as complete, verify:

- [ ] Lint check passes: Zero `.psm1` files contain `Import-Module` statements
- [ ] All 132 unit tests pass
- [ ] All integration tests pass (including new ModuleDependencies.Tests.ps1)
- [ ] `/speckit-update -CheckOnly` completes without errors in Claude Code
- [ ] All module functions are accessible via `Get-Command -Module [ModuleName]`
- [ ] Cross-module function calls work (e.g., ManifestManager → Get-NormalizedHash)
- [ ] Negative test: Lint check correctly detects and blocks violations
- [ ] Orchestrator has inline documentation for import order
- [ ] Constitution updated with Module Import Rules section
- [ ] CLAUDE.md and CONTRIBUTING.md updated with pattern

---

## Regression Testing

**After Deployment**: Repeat steps 1-6 to ensure no regressions. Key areas to watch:

1. **Module loading time**: Should remain < 5 seconds
2. **Orchestrator steps**: All 15 steps complete successfully
3. **Conflict resolution**: 3-way merge workflow still works (uses VSCodeIntegration)
4. **Backup/restore**: Rollback mechanism unaffected

---

## Manual Test Log Template

Use this template to document manual testing results:

```markdown
## Test Execution Log

**Tester**: [Your Name]
**Date**: [YYYY-MM-DD]
**Branch**: 004-fix-nested-imports
**Commit**: [Git commit SHA]

### Quick Verification
- [ ] Lint check: PASS / FAIL
- [ ] Module functions available: PASS / FAIL
- [ ] Cross-module calls: PASS / FAIL

### Comprehensive Testing
- [ ] Unit tests: XXX passing / YYY failing
- [ ] Integration tests: XXX passing / YYY failing
- [ ] End-to-end skill execution: PASS / FAIL
- [ ] Negative test (lint violation): PASS / FAIL

### Issues Found
- Issue 1: [Description]
- Issue 2: [Description]

### Notes
[Any observations, performance issues, or recommendations]
```

---

## Next Steps After Manual Testing

1. If all tests pass → Proceed to Phase 2 (`/speckit.tasks`) to generate implementation tasks
2. If tests fail → Document failures, revise fix, re-test
3. If ready for review → Create PR, attach test log, request code review
