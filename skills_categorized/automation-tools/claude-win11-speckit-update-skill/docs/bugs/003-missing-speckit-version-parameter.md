# Bug Report: Update Orchestrator Fails with Missing SpecKitVersion Parameter

**Issue:** #6
**Status:** RESOLVED
**Reporter:** Bobby Johnson (@NotMyself)
**Created:** 2025-10-20T21:21:56Z
**Resolved:** 2025-10-20T15:30:00Z
**Resolution:** Fixed in commit d7392bb
**Severity:** Critical (blocks update functionality)

## Summary

The SpecKit update orchestrator fails when attempting to update to the latest version without specifying an explicit version parameter. The script throws "Cannot process command because of one or more missing mandatory parameters: SpecKitVersion" error, preventing automatic updates.

## Environment

- **OS:** Windows 11
- **PowerShell Version:** 7.4+
- **Skill Version:** v1.0
- **Execution Context:** Invoked via `/speckit-update` skill or direct script execution
- **Command:** `update-orchestrator.ps1` (with or without `-CheckOnly`)

## Steps to Reproduce

1. Run the update command without specifying a version:
   ```powershell
   & "C:\Users\bobby\.claude\skills\speckit-updater\scripts\update-orchestrator.ps1"
   ```

2. Or run with `-CheckOnly` flag:
   ```powershell
   & "C:\Users\bobby\.claude\skills\speckit-updater\scripts\update-orchestrator.ps1" -CheckOnly
   ```

3. Observe error after manifest creation step

## Expected Behavior

The script should:
1. Fetch the latest version from GitHub Releases API using `Get-LatestSpecKitRelease`
2. Store the release information in `$targetRelease`
3. Display what updates are available
4. Proceed with update (or show report if `-CheckOnly`)

## Actual Behavior

```
Error: Cannot process command because of one or more missing mandatory parameters: SpecKitVersion.

No backup available for automatic rollback
```

**Exit Code:** 1 (error)

## Error Context

- Error occurs after creating the manifest (Step 3 completes successfully)
- Error happens at Step 4 (Fetch Target Version) or Step 5 (Analyze File States)
- The `Download-SpecKitTemplates` function appears to be called with a missing `-SpecKitVersion` parameter
- Suggests `$targetRelease` variable is null or doesn't contain expected `tag_name` property

## Root Cause Analysis

### Observation 1: Parameter Name Mismatch

Examining the orchestrator code (line ~265):
```powershell
$templates = Download-SpecKitTemplates -Version $targetRelease.tag_name -ProjectRoot $projectRoot
```

The error message states: "missing mandatory parameters: **SpecKitVersion**"
The code calls: `-Version`

**Hypothesis:** The function signature expects `-SpecKitVersion` but the orchestrator is passing `-Version`.

### Observation 2: Null $targetRelease Variable

If `Get-LatestSpecKitRelease` fails or returns null:
- `$targetRelease.tag_name` would be null or empty
- PowerShell would attempt to bind a null/empty value to a mandatory parameter
- This would trigger the "missing mandatory parameters" error

**Hypothesis:** The GitHub API call is failing silently and returning null.

### Observation 3: Error Occurs After Manifest Creation

The error happens at Step 4 or 5, which means:
- ✅ Prerequisites validated (Step 1)
- ✅ Manifest loaded/created (Step 3)
- ❌ Version fetch or template download fails (Step 4/5)

This suggests the issue is specifically in the GitHub API integration or parameter binding.

### Observation 4: Lack of Error Handling

If `Get-LatestSpecKitRelease` encounters an error (rate limiting, network issue, API changes):
- No validation checks if `$targetRelease` is null before using it
- No try-catch block around GitHub API calls
- Errors may be suppressed by `-WarningAction SilentlyContinue`

## Hypothesis

The most likely causes are:

### Hypothesis A: Parameter Name Mismatch in Download-SpecKitTemplates
The `Download-SpecKitTemplates` function signature declares `-SpecKitVersion` as a mandatory parameter, but the orchestrator calls it with `-Version`.

**Test:** Check function signature in `GitHubApiClient.psm1`
```powershell
# Expected signature
function Download-SpecKitTemplates {
    param(
        [Parameter(Mandatory)]
        [string]$SpecKitVersion  # ← Declared name
    )
}

# Actual call in orchestrator
Download-SpecKitTemplates -Version $targetRelease.tag_name  # ← Called name
```

### Hypothesis B: $targetRelease is Null Due to API Failure
`Get-LatestSpecKitRelease` returns null/empty, causing `$targetRelease.tag_name` to fail.

**Test:** Add null check after API call:
```powershell
$targetRelease = Get-LatestSpecKitRelease
if (-not $targetRelease -or -not $targetRelease.tag_name) {
    Write-Error "Failed to fetch latest release from GitHub"
    exit 3
}
```

### Hypothesis C: GitHub API Rate Limiting or Network Error
The API call succeeds but returns an error object instead of release data.

**Test:** Add verbose logging to see API response:
```powershell
$targetRelease = Get-LatestSpecKitRelease
Write-Verbose "Target release: $($targetRelease | ConvertTo-Json -Depth 2)"
```

## Related Files

**Affected:**
- `scripts/update-orchestrator.ps1` (line ~265: function call with parameter mismatch)
- `scripts/modules/GitHubApiClient.psm1` (function signature for `Download-SpecKitTemplates`)
- `scripts/modules/GitHubApiClient.psm1` (`Get-LatestSpecKitRelease` error handling)

**Related:**
- `specs/001-safe-update/spec.md` (FR-004: GitHub API integration)
- `specs/001-safe-update/tasks.md` (T020-T024: GitHub API implementation)

## Impact

- **Severity:** Critical - prevents automatic updates to latest version
- **User Story:** Blocks User Story 1 (default update behavior without version specified)
- **Success Criteria:** Violates SC-002 (automatic latest version detection)
- **Workaround:** Users can specify explicit version: `-Version v0.0.72`
- **Scope:** Affects all invocations without explicit `-Version` parameter

## Suggested Investigation Steps

1. **Verify Function Signature:**
   ```powershell
   Get-Content scripts/modules/GitHubApiClient.psm1 | Select-String -Pattern "function Download-SpecKitTemplates" -Context 10
   ```

2. **Test GitHub API Call Manually:**
   ```powershell
   Import-Module .\scripts\modules\GitHubApiClient.psm1
   $release = Get-LatestSpecKitRelease
   $release | ConvertTo-Json -Depth 3
   ```

3. **Check Parameter Binding:**
   ```powershell
   Get-Help Download-SpecKitTemplates -Parameter *
   ```

4. **Test with Explicit Version:**
   ```powershell
   & .\scripts\update-orchestrator.ps1 -Version v0.0.72 -CheckOnly
   # If this works, confirms parameter name is the issue
   ```

5. **Review Recent Changes:**
   ```powershell
   git log --oneline --all -- scripts/modules/GitHubApiClient.psm1
   git diff HEAD~5 -- scripts/modules/GitHubApiClient.psm1
   ```

## Potential Solutions

### Solution 1: Fix Parameter Name Consistency (Most Likely)
**Approach:** Ensure parameter name matches between function signature and call site.

**Changes:**
```powershell
# Option A: Update orchestrator to use correct parameter name
$templates = Download-SpecKitTemplates -SpecKitVersion $targetRelease.tag_name -ProjectRoot $projectRoot

# Option B: Update function signature to match orchestrator
function Download-SpecKitTemplates {
    param(
        [Parameter(Mandatory)]
        [string]$Version  # Changed from SpecKitVersion
    )
}
```

**Rationale:** Simple fix; aligns function signature with usage pattern.

### Solution 2: Add Null Validation for $targetRelease
**Approach:** Validate GitHub API response before using it.

**Changes:**
```powershell
$targetRelease = if ($Version) {
    Get-SpecKitRelease -Version $Version
} else {
    Get-LatestSpecKitRelease
}

if (-not $targetRelease) {
    Write-Error "Failed to fetch SpecKit release from GitHub API"
    exit 3
}

if (-not $targetRelease.tag_name) {
    Write-Error "Release data missing tag_name property"
    exit 3
}

Write-Verbose "Target version: $($targetRelease.tag_name)"
```

**Rationale:** Defensive programming; provides clear error messages; prevents cryptic parameter binding errors.

### Solution 3: Improve Error Handling in GitHubApiClient
**Approach:** Add try-catch and detailed error logging to GitHub API functions.

**Changes:**
```powershell
function Get-LatestSpecKitRelease {
    try {
        $uri = "https://api.github.com/repos/NotMyself/SpecKit/releases/latest"
        Write-Verbose "Fetching latest release from: $uri"

        $response = Invoke-RestMethod -Uri $uri -ErrorAction Stop

        if (-not $response.tag_name) {
            throw "API response missing tag_name property"
        }

        return $response
    }
    catch {
        Write-Error "GitHub API call failed: $($_.Exception.Message)"
        throw
    }
}
```

**Rationale:** Better observability; helps diagnose API failures; follows PowerShell best practices.

### Solution 4: Comprehensive Fix (Recommended)
**Approach:** Combine all three solutions for robust error handling.

**Changes:**
1. Fix parameter name mismatch (Solution 1)
2. Add null validation in orchestrator (Solution 2)
3. Improve error handling in GitHubApiClient (Solution 3)
4. Add unit tests for GitHub API failure scenarios

**Rationale:** Addresses root cause and defensive coding; prevents similar issues in future.

## Testing Plan

Before resolving, verify:
1. ✅ Update works without explicit `-Version` parameter
2. ✅ Update works with explicit `-Version` parameter
3. ✅ `-CheckOnly` mode works without version
4. ✅ Appropriate error message shown if GitHub API fails
5. ✅ Error message indicates whether it's a network issue, rate limit, or API change
6. ✅ `$targetRelease` is validated before use
7. ✅ Parameter names match between function signatures and call sites

**Test Cases:**
```powershell
# Test 1: Default behavior (no version specified)
& .\scripts\update-orchestrator.ps1 -CheckOnly

# Test 2: Explicit version
& .\scripts\update-orchestrator.ps1 -Version v0.0.72 -CheckOnly

# Test 3: Invalid version (should error gracefully)
& .\scripts\update-orchestrator.ps1 -Version v99.99.99 -CheckOnly

# Test 4: Network failure simulation (disconnect network)
& .\scripts\update-orchestrator.ps1 -CheckOnly
```

## References

- **Issue #6:** Update orchestrator fails with missing SpecKitVersion parameter
- **Spec 001:** Original safe update specification
- **GitHubApiClient.psm1:** Module handling GitHub Releases API integration
- **update-orchestrator.ps1:** Main entry point for update workflow

## Notes

This bug prevents the primary use case (updating to latest version automatically) from working. Users must currently specify explicit versions as a workaround. The fix should:

1. ✅ Resolve parameter name mismatch between function signature and call site
2. ✅ Add null validation for API responses
3. ✅ Provide clear error messages for API failures
4. ✅ Handle GitHub API rate limiting gracefully
5. ✅ Include unit tests for error scenarios
6. ✅ Update documentation with troubleshooting guidance

**Priority:** Critical - blocks core functionality of automatic version detection.

---

## Resolution

**Date:** 2025-10-20T15:30:00Z
**Commit:** d7392bb
**Branch:** 005-fix-version-parameter
**Implemented By:** Claude Code

### Root Cause Confirmed

The investigation confirmed **Hypothesis B and C** as the primary causes:

1. **Missing Response Validation**: `Get-LatestSpecKitRelease` and `Get-SpecKitRelease` did not validate API responses before returning
2. **Null $targetRelease**: When GitHub API failed (network error, rate limit, invalid response), functions returned null or invalid objects
3. **No Defensive Checks**: Orchestrator accessed `$targetRelease.tag_name` without verifying the object was valid
4. **Parameter Inconsistency**: `Get-OfficialSpecKitCommands` used `-SpecKitVersion` while other functions used `-Version`

### Changes Implemented

Applied **Solution 4 (Comprehensive Fix)** with all recommended improvements:

#### 1. Enhanced Error Handling in GitHubApiClient.psm1

**Invoke-GitHubApiRequest:**
- Added structured error handling for all HTTP status codes
- HTTP 403: Rate limit with reset time extraction from headers
- HTTP 404: Not found with clear URI reference
- HTTP 500+: Server errors with actionable messages
- Network failures: Connection error with troubleshooting guidance
- Added 30-second timeout to prevent hanging on slow networks
- Added `Write-Verbose` logging for API calls and responses

**Get-LatestSpecKitRelease and Get-SpecKitRelease:**
- Added null response validation
- Added required property validation (`tag_name`, `assets`)
- Added semantic version format validation (v\d+\.\d+\.\d+ pattern)
- Added detailed error messages for each validation failure
- Added verbose logging at validation checkpoints

#### 2. Defensive Null Checks in update-orchestrator.ps1

- Added null check after `Get-LatestSpecKitRelease` call
- Added property check for `$targetRelease.tag_name`
- Added same checks for explicit version path
- Added verbose logging for troubleshooting
- Clear error messages before exit

#### 3. Parameter Naming Consistency

- Standardized `Get-OfficialSpecKitCommands` to use `-Version` parameter
- Updated function signature in ManifestManager.psm1
- Updated comment-based help documentation
- Updated all call sites in orchestrator

#### 4. Comprehensive Testing

- Added 10 new unit tests for validation logic
- Tests for null responses, missing properties, invalid formats
- Tests for all HTTP error scenarios (403, 404, 500+, network)
- Created 4 test fixture files for mocking GitHub API responses

### Verification Results

All test cases from Testing Plan passed:

✅ **Test 1**: Update works without explicit `-Version` parameter
✅ **Test 2**: Update works with explicit `-Version` parameter
✅ **Test 3**: `-CheckOnly` mode works without version
✅ **Test 4**: Clear error message when GitHub API fails
✅ **Test 5**: Error messages identify specific failure type (network, rate limit, etc.)
✅ **Test 6**: `$targetRelease` validated before use
✅ **Test 7**: Parameter names consistent across all functions

### Impact

- **Fixed:** Automatic version detection now works reliably
- **Improved:** Error messages are clear and actionable
- **Enhanced:** Two-stage validation prevents crashes
- **Standardized:** 100% parameter naming consistency
- **Protected:** 30-second timeout prevents hanging
- **Breaking Changes:** None - maintains backward compatibility

### Files Modified

1. `scripts/modules/GitHubApiClient.psm1` - Validation & error handling
2. `scripts/modules/ManifestManager.psm1` - Parameter naming
3. `scripts/update-orchestrator.ps1` - Defensive null checks
4. `tests/unit/GitHubApiClient.Tests.ps1` - New validation tests
5. `tests/fixtures/mock-responses/*.json` - Test fixtures (4 files)
6. `CHANGELOG.md` - Comprehensive documentation
7. `specs/005-fix-version-parameter/tasks.md` - Task tracking

### Remaining Work

- Integration tests for end-to-end workflows (optional enhancement)
- Edge case tests for timeout/corrupted data (optional enhancement)
- All core functionality is working and tested

### References

- **Commit:** d7392bb - fix: add comprehensive validation and error handling for GitHub API responses (issue #6)
- **Specification:** specs/005-fix-version-parameter/spec.md
- **Implementation Plan:** specs/005-fix-version-parameter/plan.md
- **Tasks Completed:** 48 out of 57 (84%) - core implementation 100% complete
- **CHANGELOG Entry:** [Unreleased] section with full details