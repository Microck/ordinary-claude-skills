# Quickstart Guide: Testing Version Parameter Fix

**Feature**: `005-fix-version-parameter`
**Date**: 2025-10-20
**Phase**: 1 (Design & Contracts)

## Overview

This guide helps developers test the version parameter handling fix. The fix addresses the bug where running updates without an explicit version parameter fails with "missing mandatory parameters: SpecKitVersion" error.

## Prerequisites

- PowerShell 7.0+ installed
- Git installed
- Pester 5.x installed (`Install-Module -Name Pester -Force -SkipPublisherCheck`)
- Access to a SpecKit project directory (for integration testing)
- Network connectivity to GitHub API (for live API tests)

## Quick Test Commands

### 1. Run Unit Tests

Test the GitHubApiClient module in isolation:

```powershell
# Navigate to repository root
cd C:\Users\bobby\src\claude-Win11-SpecKit-Safe-Update-Skill

# Run only GitHubApiClient unit tests
Invoke-Pester -Path tests/unit/GitHubApiClient.Tests.ps1 -Output Detailed

# Run with verbose output to see all mocked scenarios
Invoke-Pester -Path tests/unit/GitHubApiClient.Tests.ps1 -Output Detailed -Verbose
```

### 2. Run Integration Tests

Test the full orchestrator workflow:

```powershell
# Run integration tests (includes API failure scenarios)
Invoke-Pester -Path tests/integration/UpdateOrchestrator.Tests.ps1 -Output Detailed

# Run all tests (unit + integration)
./tests/test-runner.ps1
```

### 3. Manual Testing (Check-Only Mode)

Test without making actual changes:

```powershell
# Navigate to a SpecKit project
cd C:\path\to\your\speckit\project

# Test default behavior (fetch latest version)
& "C:\Users\bobby\.claude\skills\speckit-updater\scripts\update-orchestrator.ps1" -CheckOnly -Verbose

# Test explicit version
& "C:\Users\bobby\.claude\skills\speckit-updater\scripts\update-orchestrator.ps1" -CheckOnly -Version v0.0.72 -Verbose
```

### 4. Test Error Scenarios

Simulate various failure modes to verify error messages:

```powershell
# Test with invalid version (should show clear error)
& "C:\Users\bobby\.claude\skills\speckit-updater\scripts\update-orchestrator.ps1" -CheckOnly -Version v99.99.99

# Test with network disconnected (manually disconnect, then):
& "C:\Users\bobby\.claude\skills\speckit-updater\scripts\update-orchestrator.ps1" -CheckOnly

# Test GitHub API rate limit (requires making 60+ requests first)
# This is difficult to test manually - use unit tests instead
```

## Testing Scenarios

### Scenario 1: Successful Latest Version Fetch

**Objective**: Verify automatic latest version detection works

**Steps**:
1. Navigate to a SpecKit project directory
2. Run: `& "path\to\update-orchestrator.ps1" -CheckOnly -Verbose`
3. Observe output

**Expected Results**:
```
SpecKit Safe Update v1.0
======================================

Validating prerequisites...
Prerequisites validated successfully

========================================
STEP 3: Load or Create Manifest
========================================

Loading manifest...
Current version: v0.0.71

========================================
STEP 4: Fetch Target Version
========================================

Fetching latest version from GitHub...
Latest version: v0.0.72

========================================
STEP 5: Analyze File States
========================================

Analyzing file changes...
[... file analysis output ...]

Exiting check-only mode
```

**Validation**:
- ✅ No errors thrown
- ✅ Latest version displayed (e.g., "v0.0.72")
- ✅ File analysis completes
- ✅ Exit code 0

---

### Scenario 2: Explicit Version Override

**Objective**: Verify explicit version specification works

**Steps**:
1. Navigate to a SpecKit project directory
2. Run: `& "path\to\update-orchestrator.ps1" -CheckOnly -Version v0.0.71 -Verbose`
3. Observe output

**Expected Results**:
```
Target version: v0.0.71 (specified)

[... proceeds with specified version ...]
```

**Validation**:
- ✅ Uses specified version instead of latest
- ✅ No GitHub API call to fetch latest (check verbose output)
- ✅ Exit code 0

---

### Scenario 3: Network Failure Handling

**Objective**: Verify clear error message when GitHub is unreachable

**Setup**: Disconnect network or block api.github.com in firewall

**Steps**:
1. Disconnect from network
2. Run: `& "path\to\update-orchestrator.ps1" -CheckOnly -Verbose`
3. Observe error message

**Expected Results**:
```
========================================
Update Failed
========================================

Error: Failed to connect to GitHub API. Check network connectivity: [details]

[Network error details]
```

**Validation**:
- ✅ Clear error message mentioning network connectivity
- ✅ No crash or stack trace
- ✅ Exit code 3 (network/API error)

---

### Scenario 4: Rate Limit Exceeded

**Objective**: Verify rate limit error message includes reset time

**Setup**: Make 60+ unauthenticated GitHub API requests to trigger rate limit (difficult to test manually)

**Alternative**: Use unit test with mocked rate limit response

**Expected Results** (from unit test):
```
Error: GitHub API rate limit exceeded. Resets at: [timestamp]. Please try again later.
```

**Validation**:
- ✅ Error mentions rate limit
- ✅ Includes reset time if available
- ✅ Suggests action ("try again later")
- ✅ Exit code 3

---

### Scenario 5: Invalid Version Specified

**Objective**: Verify error when specifying non-existent version

**Steps**:
1. Run: `& "path\to\update-orchestrator.ps1" -CheckOnly -Version v99.99.99 -Verbose`
2. Observe error message

**Expected Results**:
```
Error: GitHub resource not found. Verify repository and release exist: https://api.github.com/repos/github/spec-kit/releases/tags/v99.99.99
```

**Validation**:
- ✅ Clear 404 error message
- ✅ Includes the specific URL that failed
- ✅ Exit code 3

---

## Debugging Tips

### View Verbose Logging

Always use `-Verbose` flag for troubleshooting:

```powershell
& "path\to\update-orchestrator.ps1" -CheckOnly -Verbose
```

This shows:
- API endpoints being called
- Response validation steps
- Property existence checks
- Detailed error context

### Check Module Functions Directly

Test individual module functions in isolation:

```powershell
# Import the module
Import-Module "C:\Users\bobby\.claude\skills\speckit-updater\scripts\modules\GitHubApiClient.psm1" -Force

# Test Get-LatestSpecKitRelease
$release = Get-LatestSpecKitRelease -Verbose
$release | ConvertTo-Json -Depth 3

# Verify properties
Write-Host "Tag name: $($release.tag_name)"
Write-Host "Assets: $($release.assets.Count)"
```

### Examine GitHub API Directly

Compare module output with raw GitHub API:

```powershell
# Call GitHub API directly
$response = Invoke-RestMethod -Uri "https://api.github.com/repos/github/spec-kit/releases/latest"

# Check response structure
$response | Get-Member
$response | ConvertTo-Json -Depth 2
```

### Review Test Fixtures

Check what mock responses look like:

```powershell
# View mock successful release
Get-Content tests/fixtures/mock-responses/valid-release.json | ConvertFrom-Json

# View mock error scenarios
Get-Content tests/fixtures/mock-responses/missing-tag-name.json | ConvertFrom-Json
```

## Verification Checklist

After implementing the fix, verify:

### Functional Requirements (from spec.md)

- [ ] **FR-001**: Latest version fetched automatically when no version specified
- [ ] **FR-002**: GitHub API response validated before use
- [ ] **FR-003**: Clear error message when API is unreachable
- [ ] **FR-004**: Version identifier extracted correctly from API response
- [ ] **FR-005**: Consistent parameter naming (`-Version` vs `-SpecKitVersion`)
- [ ] **FR-006**: Rate limiting errors show reset time
- [ ] **FR-007**: Required data fields validated before access
- [ ] **FR-008**: Explicit version specification works
- [ ] **FR-009**: Diagnostic logging via `-Verbose`
- [ ] **FR-010**: Timeout scenarios handled

### Success Criteria (from spec.md)

- [ ] **SC-001**: Update without version parameter succeeds
- [ ] **SC-002**: Error messages appear within 3 seconds
- [ ] **SC-003**: 100% parameter name consistency
- [ ] **SC-004**: All API responses validated
- [ ] **SC-005**: Explicit version specification works
- [ ] **SC-006**: Error messages identify problem type
- [ ] **SC-007**: 95%+ success rate when API available

### Test Coverage

- [ ] Unit tests for `Get-LatestSpecKitRelease` with null response
- [ ] Unit tests for network failure scenarios
- [ ] Unit tests for rate limit handling
- [ ] Unit tests for missing `tag_name` property
- [ ] Unit tests for invalid version format
- [ ] Integration test for orchestrator with API failures
- [ ] Integration test for parameter name consistency

## Common Issues and Solutions

### Issue: "Module not found" when running tests

**Solution**:
```powershell
# Ensure you're in the repository root
cd C:\Users\bobby\src\claude-Win11-SpecKit-Safe-Update-Skill

# Import modules manually if needed
Import-Module .\scripts\modules\GitHubApiClient.psm1 -Force
```

### Issue: Tests fail with "Mock not found"

**Solution**: Ensure Pester 5.x is installed:
```powershell
Get-Module Pester -ListAvailable
# If version is < 5.0:
Install-Module Pester -Force -SkipPublisherCheck
```

### Issue: GitHub API returns unexpected structure

**Solution**: GitHub may update their API schema. Check current structure:
```powershell
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/github/spec-kit/releases/latest"
$release | Get-Member
```

## Next Steps

After testing the fix:

1. **Run full test suite**: `./tests/test-runner.ps1`
2. **Test in real SpecKit project**: Verify update workflow end-to-end
3. **Update CHANGELOG.md**: Document the bug fix
4. **Create PR**: Submit pull request with test results
5. **Update issue #6**: Close GitHub issue with verification notes

## Reference Links

- **Bug Report**: [docs/bugs/003-missing-speckit-version-parameter.md](../../../docs/bugs/003-missing-speckit-version-parameter.md)
- **Feature Spec**: [spec.md](spec.md)
- **Data Model**: [data-model.md](data-model.md)
- **GitHub Issue**: #6
