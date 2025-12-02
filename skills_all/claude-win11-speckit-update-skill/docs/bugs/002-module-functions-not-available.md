# Bug Report: Module Functions Not Available After Import Despite Export-ModuleMember

**Issue:** #4
**Status:** OPEN
**Reporter:** Bobby Johnson (@NotMyself)
**Created:** 2025-10-20T19:49:21Z
**Severity:** Critical (blocks skill execution)

## Summary

The SpecKit Update skill fails to execute with "The term 'Get-SpecKitManifest' is not recognized" error, even though the `ManifestManager.psm1` module is imported with `-Force` flag and contains proper `Export-ModuleMember` declarations. This occurs after implementing PR #3 (fix for issue #1) which removed `Export-ModuleMember` from helper scripts.

## Environment

- **OS:** Windows 11
- **PowerShell Version:** 7.x (pwsh.exe)
- **Skill Version:** Based on spec 003-fix-module-import-error (post PR #3)
- **Execution Context:** Invoked via `/speckit-update` skill in Claude Code
- **Branch:** 003-fix-module-import-error (after implementation)

## Steps to Reproduce

1. Navigate to a SpecKit project directory containing `.specify/` folder:
   ```powershell
   cd c:\Users\BobbyJohnson\src\tw\webapp-admin-portal
   ```

2. Run the skill orchestrator directly:
   ```powershell
   pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\BobbyJohnson\.claude\skills\speckit-updater\scripts\update-orchestrator.ps1"
   ```

3. Observe error at Step 3 (Load or Create Manifest)

## Expected Behavior

After module import completes:
- All exported functions from `ManifestManager.psm1` should be available
- `Get-SpecKitManifest` function should be callable
- Orchestrator should proceed to load/create manifest without errors

## Actual Behavior

```
SpecKit Safe Update v1.0
======================================

Validating prerequisites...
Prerequisites validated successfully

========================================
STEP 3: Load or Create Manifest
========================================

Loading manifest...

========================================
Update Failed
========================================

Error: The term 'Get-SpecKitManifest' is not recognized as a name of a cmdlet, function, script file, or executable program.

No backup available for automatic rollback
```

**Exit Code:** 1 (error)

## Root Cause Analysis

### Observation 1: Module Import Appears Successful

The orchestrator output shows:
```
WARNING: The names of some imported commands from the module 'GitHubApiClient' include unapproved verbs...
Validating prerequisites...
Prerequisites validated successfully
```

This indicates:
- ✅ Modules load without fatal errors (no "Export-ModuleMember cmdlet can only be called from inside a module" error)
- ✅ Prerequisite validation completes (suggests basic functions work)
- ✅ Warning about unapproved verbs appears (GitHubApiClient module is recognized)

However, exported functions are **not available** in the calling scope when needed.

### Observation 2: Direct Module Import Works

Testing `HashUtils.psm1` directly in a PowerShell session:
```powershell
Import-Module 'C:\Users\BobbyJohnson\.claude\skills\speckit-updater\scripts\modules\HashUtils.psm1' -Verbose
Get-Command -Module HashUtils
```

**Result:**
```
CommandType     Name                    Version    Source
-----------     ----                    -------    ------
Function        Compare-FileHashes      0.0        HashUtils
Function        Get-NormalizedHash      0.0        HashUtils
```

✅ Functions are correctly exported and available when imported manually.

### Observation 3: ManifestManager Has Nested Imports

Examining `ManifestManager.psm1` (lines 19-21):
```powershell
# Import required modules
Import-Module (Join-Path $PSScriptRoot "HashUtils.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "GitHubApiClient.psm1") -Force
```

**Hypothesis:** Nested module imports may create scope isolation issues where:
1. `ManifestManager.psm1` imports `HashUtils.psm1` and `GitHubApiClient.psm1` into its own module scope
2. Functions from nested modules may not be available to `ManifestManager` functions
3. Even if available within the module, the orchestrator's import of `ManifestManager` may not propagate nested dependencies correctly

### Observation 4: Import Order in Orchestrator

Current import order in `scripts/update-orchestrator.ps1` (lines 96-106):
```powershell
Import-Module (Join-Path $modulesPath "HashUtils.psm1") -Force -WarningAction SilentlyContinue
Import-Module (Join-Path $modulesPath "VSCodeIntegration.psm1") -Force -WarningAction SilentlyContinue
Import-Module (Join-Path $modulesPath "GitHubApiClient.psm1") -Force -WarningAction SilentlyContinue
Import-Module (Join-Path $modulesPath "ManifestManager.psm1") -Force -WarningAction SilentlyContinue
Import-Module (Join-Path $modulesPath "BackupManager.psm1") -Force -WarningAction SilentlyContinue
Import-Module (Join-Path $modulesPath "ConflictDetector.psm1") -Force -WarningAction SilentlyContinue
```

✅ Dependencies (`HashUtils`, `GitHubApiClient`) are imported **before** `ManifestManager`, so order appears correct.

### Observation 5: Error Occurs at Runtime, Not Import Time

The error occurs when calling `Get-SpecKitManifest` at line ~160-165 in orchestrator:
```powershell
# Step 3: Load or create manifest
$manifest = Get-SpecKitManifest -ProjectRoot $projectRoot
```

This suggests:
- ✅ Import completes without throwing errors
- ❌ Function is not available in the orchestrator's scope when called

### Observation 6: Simplified Import Logic May Have Removed Necessary Behavior

PR #3 removed error suppression and simplified import logic. Changes included:
- **Removed:** `$savedErrorPreference` save/restore pattern
- **Removed:** `-ErrorAction SilentlyContinue` from `Import-Module` calls
- **Kept:** `-WarningAction SilentlyContinue` for unapproved verb warnings
- **Kept:** `-Force` flag on all imports

**Question:** Did the simplified import logic inadvertently break module function availability?

## Hypothesis

The most likely cause is one of the following:

### Hypothesis A: Nested Module Imports Create Scope Isolation
`ManifestManager.psm1` imports other modules internally. PowerShell may be:
1. Loading `HashUtils` and `GitHubApiClient` into `ManifestManager`'s module scope
2. Not propagating these functions to the orchestrator's calling scope
3. Making `ManifestManager`'s own functions unavailable due to dependency resolution issues

**Test:** Remove nested imports from `ManifestManager.psm1` and rely on orchestrator imports only.

### Hypothesis B: Module Export Visibility Issue
The `Export-ModuleMember` in `ManifestManager.psm1` may not be processing correctly due to:
1. Module scope confusion from nested imports
2. Timing issues with `-Force` flag
3. PowerShell session state corruption

**Test:** Add explicit `Get-Command -Module ManifestManager` check after import in orchestrator.

### Hypothesis C: Error Suppression Removal Exposed Latent Issue
The previous error suppression (PR #1) may have masked a real problem:
1. Modules were loading with errors that were suppressed
2. Some error handling was actually necessary for modules to work
3. Simplified import logic removed necessary error recovery

**Test:** Temporarily restore error suppression to see if functions become available.

## Related Files

**Affected:**
- `scripts/update-orchestrator.ps1` (lines 96-106: module imports, line ~160: function call)
- `scripts/modules/ManifestManager.psm1` (lines 19-21: nested imports, line 579: Export-ModuleMember)

**Related:**
- `specs/003-fix-module-import-error/tasks.md` (T006-T016 marked complete)
- `specs/003-fix-module-import-error/spec.md` (FR-001: modules must import without fatal errors)
- PR #3 (implementation of fix for issue #1)

## Impact

- **Severity:** Critical - skill cannot execute at all
- **User Story:** Blocks User Story 1 (T058 - test in Claude Code environment)
- **Success Criteria:** Violates SC-001 (100% execution success)
- **Workaround:** None currently available
- **Regression:** This worked in PR #1 (error suppression approach), broke in PR #3 (architectural fix)

## Suggested Investigation Steps

1. **Verify Export-ModuleMember Processing:**
   ```powershell
   Import-Module '...\ManifestManager.psm1' -Force -Verbose
   Get-Command -Module ManifestManager
   Get-Module ManifestManager | Select-Object -ExpandProperty ExportedFunctions
   ```

2. **Test Without Nested Imports:**
   - Comment out lines 19-21 in `ManifestManager.psm1`
   - Verify if orchestrator imports make functions available
   - If yes, nested imports are the problem

3. **Test Import Order Sensitivity:**
   - Try importing `ManifestManager` twice (once for dependencies, once for functions)
   - Try removing `-Force` flag from nested imports

4. **Add Diagnostic Logging:**
   ```powershell
   Write-Verbose "Modules loaded: $(Get-Module | Select-Object -ExpandProperty Name)"
   Write-Verbose "ManifestManager functions: $(Get-Command -Module ManifestManager | Select-Object -ExpandProperty Name)"
   ```

5. **Compare with Working Configuration:**
   - Check out commit from PR #1 (error suppression)
   - Verify function availability
   - Identify what changed that broke this

## Potential Solutions

### Solution 1: Remove Nested Imports from Modules (Recommended)
**Approach:** Modules should not import other modules; rely on orchestrator to establish dependencies.

**Changes:**
- Remove `Import-Module` statements from all module files (`.psm1`)
- Document dependency order in orchestrator
- Update constitution to prohibit nested module imports

**Rationale:** Follows PowerShell best practices; avoids scope confusion; orchestrator owns dependency graph.

### Solution 2: Use RequiredModules in Module Manifests
**Approach:** Create `.psd1` manifests for each module declaring dependencies.

**Changes:**
- Create `ManifestManager.psd1` with `RequiredModules = @('HashUtils', 'GitHubApiClient')`
- Import via manifest instead of `.psm1` file
- Update orchestrator to import `.psd1` files

**Rationale:** Proper PowerShell module structure; PowerShell handles dependency resolution.

### Solution 3: Explicit Global Scope Import
**Approach:** Force functions into global scope to ensure availability.

**Changes:**
- Add `-Global` parameter to `Import-Module` calls in orchestrator
- Update `Export-ModuleMember` to include `-Scope Global` (if supported)

**Rationale:** Guarantees function availability across scopes; may violate best practices.

### Solution 4: Restore Limited Error Suppression
**Approach:** Re-introduce error suppression only for module imports (not helpers).

**Changes:**
- Add `-ErrorAction Continue` back to module imports (not helpers)
- Keep helpers clean (no `Export-ModuleMember`, no error suppression needed)

**Rationale:** May fix the issue if error recovery was necessary; validates hypothesis C.

## Testing Plan

Before resolving, verify:
1. Module imports complete without errors
2. All exported functions are available in orchestrator scope: `Get-Command -Module ManifestManager`
3. Nested module dependencies resolve correctly
4. All 61 tasks from `tasks.md` still pass after fix
5. Success criteria SC-001 through SC-007 are met
6. No regression in helper script loading (should still have no `Export-ModuleMember`)

## References

- **Issue #1:** Original fatal Export-ModuleMember error
- **PR #1:** Error suppression workaround (worked but masked antipattern)
- **PR #3:** Architectural fix removing Export-ModuleMember from helpers (broke ManifestManager)
- **Spec 003:** Complete specification including constitution compliance

## Notes

This is a **regression introduced by PR #3**. While PR #3 correctly fixed the helper script issue, it may have inadvertently broken module function availability by simplifying import logic too aggressively. The solution must:
1. ✅ Keep helpers clean (no `Export-ModuleMember`)
2. ✅ Fix module function availability
3. ✅ Maintain architectural correctness (no workarounds)
4. ✅ Pass all 61 implementation tasks and 7 success criteria

**Priority:** Critical - blocks all skill functionality.
