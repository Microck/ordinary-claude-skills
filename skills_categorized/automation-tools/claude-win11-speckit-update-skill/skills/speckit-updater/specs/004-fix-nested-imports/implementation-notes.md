# Implementation Notes: Fix Module Function Availability

**Feature**: Fix Module Function Availability
**Branch**: `004-fix-nested-imports`
**Started**: 2025-10-20
**Status**: In Progress

## Baseline Test Results (Before Fix)

**Test Run**: 2025-10-20
**PowerShell Version**: 7.5.3
**Pester Version**: 5.7.1

**Summary**:
- Tests Passed: 160
- Tests Failed: 69
- Tests Skipped: 10
- Tests Total: 239

**Root Cause Confirmed**:
The error `The term 'Get-SpecKitManifest' is not recognized` appears consistently in integration tests, confirming the nested module import issue where functions imported within module scope are not available in the orchestrator scope.

**Key Error Message**:
```
Error: The term 'Get-SpecKitManifest' is not recognized as a name of a cmdlet, function, script file, or executable program.
Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
```

This error occurs because `ManifestManager.psm1` contains nested `Import-Module` statements (lines 19-21) that load `HashUtils` into the module's internal scope instead of the orchestrator's scope.

## Implementation Progress

### Phase 1: Setup & Prerequisites ✅ COMPLETE
- [x] T001: Verified PowerShell 7.5.3 and Pester 5.7.1 installed
- [x] T002: Ran baseline test suite (160 passing, 69 failing due to nested import bug)
- [x] T003: Documented baseline results
- [ ] T004: Create backup of module files (next step)

### Phase 2: Foundational (Audit) - PENDING
### Phase 3: User Story 1 (Fix Critical Bug) ✅ COMPLETE
- [x] T016: Removed nested imports from ManifestManager.psm1
- [x] T017: Removed nested imports from BackupManager.psm1
- [x] T018: Removed nested imports from ConflictDetector.psm1
- [x] T019-T022: Updated orchestrator with tiered import structure and inline documentation
- [x] T023: Ran all unit tests - **21 more tests passing** (160→181), **21 fewer failures** (69→48)

**Key Success**: The error `'Get-SpecKitManifest' is not recognized` is ELIMINATED!

**Test Results After Fix**:
- Tests Passed: 181 (was 160) ✅ +21
- Tests Failed: 48 (was 69) ✅ -21
- Tests Skipped: 10
- Total: 239

The remaining failures are related to other issues (missing parameters in function signatures), not the nested import scope isolation bug.
### Phase 4: User Story 2 (Add Prevention) - PENDING
### Phase 5: User Story 3 (Add Governance) - PENDING
### Phase 6: Final Validation - PENDING

## Audit Findings (Phase 2)

**Modules with nested imports**:

1. **ManifestManager.psm1** (lines 20-21):
   - Line 20: `Import-Module (Join-Path $modulesPath "HashUtils.psm1") -Force`
   - Line 21: `Import-Module (Join-Path $modulesPath "GitHubApiClient.psm1") -Force`

2. **BackupManager.psm1** (line 18):
   - Line 18: `Import-Module $ManifestManagerPath -Force`

3. **ConflictDetector.psm1** (lines 19-20):
   - Line 19: `Import-Module (Join-Path $modulesPath "HashUtils.psm1") -Force`
   - Line 20: `Import-Module (Join-Path $modulesPath "ManifestManager.psm1") -Force`

**Modules WITHOUT nested imports** (clean):
- HashUtils.psm1 ✅
- VSCodeIntegration.psm1 ✅
- GitHubApiClient.psm1 ✅

**Total violations found**: 5 Import-Module statements across 3 modules

## Next Steps

1. ✅ Complete T004: Create backup of all 6 module files
2. ✅ Complete Phase 2: Audit complete - found violations in 3 modules
3. Begin Phase 3: Remove nested imports from ManifestManager, BackupManager, ConflictDetector
4. Update orchestrator with tiered import structure
5. Add lint check and integration tests

## Notes

- All test failures are related to the same root cause (nested imports)
- Once modules are fixed, expect significant improvement in test pass rate
- The fix is well-scoped and low-risk (removing imports, not changing logic)
