# Bug Report: New-SpecKitManifest Still Uses -SpecKitVersion Parameter (Missed in #6 Fix)

**Issue:** #8
**Status:** OPEN
**Reporter:** Bobby Johnson (@NotMyself)
**Created:** 2025-10-20T22:31:50Z
**Resolved:** N/A
**Resolution:** N/A
**Severity:** High (blocks first-time users and new projects)

## Summary

The fix for issue #6 standardized parameter naming to `-Version` across all functions, but **missed updating `New-SpecKitManifest`** which still uses `-SpecKitVersion`. This causes the orchestrator to fail when creating a new manifest in projects that don't have an existing manifest.json file.

## Environment

- **OS:** Windows 11
- **PowerShell Version:** 7.4+
- **Skill Version:** v0.1.3+
- **Execution Context:** First-time update in SpecKit project without existing manifest
- **Command:** `update-orchestrator.ps1` (with or without `-CheckOnly`)

## Steps to Reproduce

1. Navigate to a SpecKit project that has no existing manifest:
   ```powershell
   cd <speckit-project-without-manifest>
   ```

2. Run update command:
   ```powershell
   & "path\to\update-orchestrator.ps1" -CheckOnly
   ```

3. Observe error after "Creating new manifest..." message

## Expected Behavior

The orchestrator should:
1. Detect missing manifest
2. Create new manifest successfully with current SpecKit version
3. Continue with update check process
4. Display available updates or check-only report

## Actual Behavior

```
No manifest found. Creating new manifest...

========================================
Update Failed
========================================

Error: Cannot process command because of one or more missing mandatory parameters: SpecKitVersion.
```

**Exit Code:** 1 (error)

## Error Context

- Error occurs at Step 3 (Load/Create Manifest)
- `New-SpecKitManifest` is called with missing `-SpecKitVersion` parameter
- The orchestrator doesn't pass the required parameter when calling the function
- Parameter binding fails because function signature expects old parameter name

## Root Cause Analysis

### Primary Issue: Incomplete Parameter Standardization

Issue #6 fixed the parameter naming in most functions but missed `New-SpecKitManifest` in ManifestManager.psm1.

### Affected Locations

**In `scripts/modules/ManifestManager.psm1`:**

**Location 1 - Line 126 (Parameter Declaration):**
```powershell
[Parameter(Mandatory)]
[ValidateNotNullOrEmpty()]
[string]$SpecKitVersion,  # ← Should be $Version
```
Function signature still declares old parameter name.

**Location 2 - Line 135 (Verbose Message):**
```powershell
Write-Verbose "Creating new manifest for SpecKit version $SpecKitVersion"
```
References old variable name.

**Location 3 - Line 138 (Function Call):**
```powershell
$officialCommands = Get-OfficialSpecKitCommands -SpecKitVersion $SpecKitVersion  # ← Should be -Version
```
Calls another function with old parameter name (though `Get-OfficialSpecKitCommands` was fixed in #6).

**Location 4 - Comment-Based Help:**
```powershell
.PARAMETER SpecKitVersion  # ← Should be Version
The version of SpecKit to initialize (e.g., "v0.0.72")
```
Documentation still references old parameter name.

**In `scripts/update-orchestrator.ps1`:**

**Location 5 - Line 200 (Function Call):**
```powershell
$manifest = New-SpecKitManifest -ProjectRoot $projectRoot -AssumeAllCustomized
# Missing: -Version $targetRelease.tag_name
```
Caller doesn't pass the version parameter at all, expecting the parameter name is now `-Version`.

### Why This Was Missed

The issue #6 fix focused on:
- `Get-OfficialSpecKitCommands` parameter renaming
- `Download-SpecKitTemplates` function calls
- GitHub API validation and error handling

It did not include a comprehensive search for all uses of `-SpecKitVersion` parameter across the codebase, missing the `New-SpecKitManifest` function which is only called when no manifest exists (less common scenario during development/testing).

## Related Files

**Affected:**
- [scripts/modules/ManifestManager.psm1:126](scripts/modules/ManifestManager.psm1#L126) - Function parameter declaration
- [scripts/modules/ManifestManager.psm1:135](scripts/modules/ManifestManager.psm1#L135) - Verbose logging
- [scripts/modules/ManifestManager.psm1:138](scripts/modules/ManifestManager.psm1#L138) - Function call
- [scripts/modules/ManifestManager.psm1](scripts/modules/ManifestManager.psm1) - Comment-based help
- [scripts/update-orchestrator.ps1:200](scripts/update-orchestrator.ps1#L200) - Missing parameter in call

**Related:**
- [specs/001-safe-update/spec.md](specs/001-safe-update/spec.md) - Original specification
- Issue #6 - Parameter standardization fix (should have included this function)

## Impact

- **Severity:** High - blocks all first-time users and any project without existing manifest
- **User Story:** Prevents new users from using the update skill at all
- **Scope:** Affects any project without `.specify/manifest.json` file
- **Workaround:** Manually create manifest.json with proper structure before running update
- **Related Issues:** Issue #6 - This is a regression/incomplete fix from that issue

## Hypothesis

### Root Cause: Incomplete Code Search During Issue #6 Fix

When fixing issue #6, the search pattern likely focused on:
- Direct calls to `Get-SpecKitRelease` and related API functions
- `Download-SpecKitTemplates` usage
- Parameter passing in orchestrator

But did not include:
- Comprehensive grep for all `-SpecKitVersion` occurrences
- All functions in ManifestManager.psm1
- Code paths only executed during first-run scenarios

### Verification

Can confirm with:
```powershell
# Search for all occurrences of "SpecKitVersion" in codebase
Get-ChildItem -Recurse -Filter *.ps1,*.psm1 | Select-String "SpecKitVersion"
```

Expected findings:
- `New-SpecKitManifest` parameter declaration
- `New-SpecKitManifest` verbose message
- `New-SpecKitManifest` internal function call
- Comment-based help documentation

## Suggested Investigation Steps

1. **Verify Current State:**
   ```powershell
   # Check New-SpecKitManifest function signature
   Get-Content scripts/modules/ManifestManager.psm1 | Select-String -Pattern "function New-SpecKitManifest" -Context 20
   ```

2. **Search for All Occurrences:**
   ```powershell
   # Find all remaining uses of old parameter name
   Select-String -Path scripts/**/*.ps1,scripts/**/*.psm1 -Pattern "SpecKitVersion" -CaseSensitive
   ```

3. **Check Orchestrator Call:**
   ```powershell
   # Verify how orchestrator calls New-SpecKitManifest
   Get-Content scripts/update-orchestrator.ps1 | Select-String -Pattern "New-SpecKitManifest" -Context 5
   ```

4. **Test Manifest Creation:**
   ```powershell
   # Create test project without manifest
   mkdir C:\temp\test-speckit-project\.specify
   cd C:\temp\test-speckit-project
   & "path\to\update-orchestrator.ps1" -CheckOnly -Verbose
   ```

## Potential Solutions

### Solution 1: Complete Parameter Renaming (Recommended)

**Approach:** Finish the work started in issue #6 by updating all remaining occurrences.

**Changes Required:**

**In ManifestManager.psm1:**

```powershell
# Change 1: Parameter declaration (line 126)
[Parameter(Mandatory)]
[ValidateNotNullOrEmpty()]
[string]$Version,  # Changed from $SpecKitVersion

# Change 2: Verbose message (line 135)
Write-Verbose "Creating new manifest for SpecKit version $Version"

# Change 3: Function call (line 138)
$officialCommands = Get-OfficialSpecKitCommands -Version $Version

# Change 4: Comment-based help
.PARAMETER Version
The version of SpecKit to initialize (e.g., "v0.0.72")
```

**In update-orchestrator.ps1:**

```powershell
# Change 5: Add missing parameter (line 200)
$manifest = New-SpecKitManifest `
    -ProjectRoot $projectRoot `
    -Version $targetRelease.tag_name `
    -AssumeAllCustomized
```

**Rationale:**
- Completes the standardization started in issue #6
- Maintains consistency across all functions
- Simple, straightforward fix
- No breaking changes (internal API only)

### Solution 2: Add Parameter Alias (Alternative)

**Approach:** Support both parameter names during transition period.

**Changes:**
```powershell
function New-SpecKitManifest {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('SpecKitVersion')]  # Add alias for backward compatibility
        [string]$Version
    )
}
```

**Rationale:**
- Provides backward compatibility if external scripts exist
- Allows gradual migration
- More complex than needed for internal-only API

**Recommendation:** Use Solution 1 (complete renaming) since this is an internal API with no external consumers.

## Testing Plan

Before marking as resolved, verify:

1. ✅ **New Project Test:** Update works in project without existing manifest
   ```powershell
   # Remove existing manifest
   Remove-Item .specify/manifest.json -ErrorAction SilentlyContinue
   # Run update
   & .\scripts\update-orchestrator.ps1 -CheckOnly -Verbose
   ```

2. ✅ **Existing Project Test:** Update still works with existing manifest
   ```powershell
   # Run with existing manifest
   & .\scripts\update-orchestrator.ps1 -CheckOnly
   ```

3. ✅ **Parameter Consistency:** All functions use `-Version` parameter
   ```powershell
   # Should return no results
   Select-String -Path scripts/**/*.psm1 -Pattern "param.*SpecKitVersion"
   ```

4. ✅ **Verbose Output:** Manifest creation messages are correct
   ```powershell
   # Check verbose output mentions "Version" not "SpecKitVersion"
   & .\scripts\update-orchestrator.ps1 -CheckOnly -Verbose
   ```

5. ✅ **Unit Tests:** ManifestManager tests pass
   ```powershell
   ./tests/test-runner.ps1 -Unit
   ```

**Test Cases:**

```powershell
# Test 1: First-time update (no manifest) - PRIMARY TEST CASE
cd <new-speckit-project>
& .\scripts\update-orchestrator.ps1 -CheckOnly

# Test 2: Update with existing manifest (regression test)
cd <existing-speckit-project>
& .\scripts\update-orchestrator.ps1 -CheckOnly

# Test 3: AssumeAllCustomized flag works
Remove-Item .specify/manifest.json
& .\scripts\update-orchestrator.ps1 -CheckOnly  # Should create manifest with all files marked customized

# Test 4: Explicit version parameter
Remove-Item .specify/manifest.json
& .\scripts\update-orchestrator.ps1 -Version v0.0.72 -CheckOnly
```

## References

- **Issue #8:** New-SpecKitManifest still uses -SpecKitVersion parameter (missed in #6 fix)
- **Issue #6:** Original parameter standardization work
- **PR #7:** Merged pull request for issue #6
- **Commit d7392bb:** Fix that should have included this function
- [ManifestManager.psm1](scripts/modules/ManifestManager.psm1) - Module containing affected function
- [update-orchestrator.ps1](scripts/update-orchestrator.ps1) - Orchestrator that calls the function

## Notes

This is a **regression bug** that slipped through the issue #6 fix because:
1. Testing likely focused on projects with existing manifests
2. Code search didn't comprehensively cover all parameter uses
3. `New-SpecKitManifest` is only called in first-run scenarios

The fix is straightforward but critical for first-time user experience. Users hitting this error cannot proceed with updates at all without manually creating a manifest.

**Priority:** High - Must fix before next release to avoid blocking new users.

**Recommended Actions:**
1. Apply Solution 1 (complete parameter renaming)
2. Add regression test for manifest creation
3. Add linting step to check for parameter naming consistency
4. Update CONTRIBUTING.md with parameter naming standards

---

## Resolution

**Date:** N/A
**Commit:** N/A
**Branch:** N/A
**Implemented By:** N/A

### Implementation Notes

(To be filled in when bug is resolved)
