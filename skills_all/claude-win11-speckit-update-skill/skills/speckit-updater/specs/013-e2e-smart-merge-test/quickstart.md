# Quickstart Guide: E2E Smart Merge Tests

**Feature**: End-to-End Smart Merge Test with Parallel Execution
**Date**: 2025-10-24
**Audience**: Developers, QA engineers, CI/CD maintainers

---

## Overview

The End-to-End Smart Merge Test suite validates the smart merge system across multiple SpecKit versions with parallel execution. It tests 15-20 version upgrade paths, injects test content (dad jokes), executes merges, and validates 100% data preservation.

**Key Features**:

- ✅ Parallel execution (4 threads) completes in <15 minutes
- ✅ 100% data preservation validation (zero tolerance for loss)
- ✅ Advanced semantic validation (9-point checklist) and command execution validation
- ✅ Deterministic test selection (reproducible with seed 42)
- ✅ Comprehensive reporting (per-merge and aggregate statistics)

---

## Prerequisites

### System Requirements

- **PowerShell**: 7.0+ (required for ForEach-Object -Parallel)
- **Pester**: 5.x (test framework)
- **Disk Space**: Minimum 500MB free (100MB threshold + temporary files)
- **RAM**: Minimum 4GB (for parallel execution)
- **Network**: Internet connection (to download SpecKit releases from GitHub)

### Optional (Recommended)

- **GitHub Personal Access Token**: Increases API rate limit from 60 to 5,000 requests/hour
  ```powershell
  $env:GITHUB_PAT = "ghp_YOUR_TOKEN_HERE"
  ```

### Verification

```powershell
# Check PowerShell version
$PSVersionTable.PSVersion  # Should be 7.0 or higher

# Check Pester version
Get-Module -ListAvailable Pester  # Should be 5.x

# Check disk space
(Get-PSDrive -Name C).Free / 1GB  # Should be > 0.5 GB

# Verify fingerprints database exists
Test-Path "data/speckit-fingerprints.json"  # Should return True
```

---

## Running the Test Suite

### Basic Usage

```powershell
# Navigate to repository root
cd C:\Users\bobby\src\claude\claude-win11-speckit-safe-update-skill

# Run E2E tests with default settings (4 parallel threads)
Invoke-Pester -Path tests/integration/SmartMerge.E2E.Tests.ps1
```

**Expected Output**:

```
Starting discovery in 1 files.
Discovery finished in 342ms.

Running tests from 'SmartMerge.E2E.Tests.ps1'
Describing End-to-End Smart Merge Test

  Context Parallel Merge Validation
    [+] Should successfully execute all merge tests in parallel  863407ms (14m 23s)

Tests completed in 14m 23s
Tests Passed: 1, Failed: 0, Skipped: 0, Inconclusive: 0
```

### Advanced Options

#### Adjust Parallel Thread Count

```powershell
# Run with 2 threads (slower, lower resource usage)
Invoke-Pester -Path tests/integration/SmartMerge.E2E.Tests.ps1 -Configuration @{
    Run = @{ ThrottleLimit = 2 }
}

# Run sequentially (no parallelism, useful for debugging)
Invoke-Pester -Path tests/integration/SmartMerge.E2E.Tests.ps1 -Configuration @{
    Run = @{ ThrottleLimit = 1 }
}
```

#### Enable Verbose Output

```powershell
# Show detailed progress during execution
Invoke-Pester -Path tests/integration/SmartMerge.E2E.Tests.ps1 -Verbose
```

#### Set GitHub Token

```powershell
# Avoid rate limiting (recommended for frequent test runs)
$env:GITHUB_PAT = "ghp_YOUR_TOKEN_HERE"
Invoke-Pester -Path tests/integration/SmartMerge.E2E.Tests.ps1
```

---

## Interpreting Test Results

### Successful Test Run

```
============================================================
End-to-End Smart Merge Test Report
============================================================

Summary:
  Total Tests: 18
  Passed: 18 (100.0%)
  Failed: 0
  Skipped: 0
  Timeout: 0
  Total Duration: 14m 23s

Dad Joke Preservation:
  Total Injected: 1,234
  Total Preserved: 1,234 (100.0%)
  Data Loss: 0 jokes

Advanced Validation:
  Semantic (9-point checklist):
    Passed: 216 / 216 (100.0%)
  Command Execution:
    Passed: 216 / 216 (100.0%)

Performance:
  Average Merge Time: 42.3s
  Fastest: v0.0.78 → v0.0.79 (28.1s)
  Slowest: v0.0.50 → v0.0.79 (61.2s)

Per-Merge Details:
  [01/18] v0.0.50 → v0.0.79: PASSED (42.3s) - Files: 12, Jokes: 67/67
  [02/18] v0.0.60 → v0.0.75: PASSED (38.7s) - Files: 12, Jokes: 68/68
  [03/18] v0.0.35 → v0.0.71: PASSED (45.1s) - Files: 12, Jokes: 65/65
  ...

============================================================
Result: ALL TESTS PASSED ✓
============================================================
```

### Understanding the Report

| Section | Meaning |
|---------|---------|
| **Total Tests** | Number of merge pairs tested (15-20) |
| **Passed** | Tests with 100% dad joke preservation, semantic validation, and valid merged files |
| **Failed** | Tests with data loss, semantic validation failures, or exceptions |
| **Skipped** | Tests bypassed due to prerequisites (corrupted templates, disk space) |
| **Timeout** | Tests exceeding 5-minute limit |
| **Dad Joke Preservation** | Critical metric - must be 100% for test pass |
| **Average Merge Time** | Mean execution time per test (target: <60s) |
| **Fastest/Slowest** | Performance bounds for optimization insights |
| **Per-Merge Details** | Individual test outcomes with file count and joke preservation |

---

## Failure Types

### Type 1: Data Loss (Critical Failure)

**Symptom**:

```
[05/18] v0.0.55 → v0.0.70: FAILED (48.2s) - Files: 12, Jokes: 64/67

Error: MERGE FAILURE: 3 dad jokes lost in .claude/commands/speckit.plan.md
```

**Meaning**: The smart merge system failed to preserve all injected test content. This is a **critical failure** indicating data loss.

**Root Cause**: Merge logic bug, conflict resolution issue, or unexpected file truncation.

**Action Required**: Investigate merge algorithm, check conflict markers, review file diff.

### Type 2: Timeout

**Symptom**:

```
[08/18] v0.0.42 → v0.0.79: TIMEOUT (300.0s) - Files: 12, Jokes: N/A

Error: Test exceeded 5-minute timeout limit
```

**Meaning**: Test hung or took too long, terminated after 5 minutes.

**Root Cause**: Infinite loop in merge logic, GitHub API hanging, or system resource exhaustion.

**Action Required**: Check logs for hang location, verify system resources, review merge orchestration code.

### Type 3: Skipped (Prerequisite Failure)

**Symptom**:

```
[12/18] v0.0.50 → v0.0.60: SKIPPED (2.1s) - Files: N/A, Jokes: N/A

Reason: Corrupted template - ZIP integrity validation failed
```

**Meaning**: Test was not executed due to failing prerequisite check.

**Root Cause**: Bad GitHub download, corrupted SpecKit release, or disk I/O error.

**Action Required**: Verify GitHub release integrity, retry download, check disk health.

### Type 4: GitHub API Failure

**Symptom**:

```
[03/18] v0.0.35 → v0.0.48: FAILED (1.5s) - Files: N/A, Jokes: N/A

Error: GitHub API error: 403 Forbidden - Rate limit exceeded
```

**Meaning**: Test failed due to GitHub API rate limiting or network issue.

**Root Cause**: Exceeded 60 requests/hour limit (unauthenticated) or network connectivity problem.

**Action Required**: Set `$env:GITHUB_PAT` to increase limit to 5,000 req/hour, or wait 1 hour for reset.

### Type 5: Disk Space Exhaustion

**Symptom**:

```
[15/18] v0.0.71 → v0.0.75: FAILED (0.3s) - Files: N/A, Jokes: N/A

Error: Insufficient disk space: 87MB available (minimum 100MB required)
```

**Meaning**: System ran out of disk space during test execution.

**Root Cause**: Disk full, too many parallel tests, or failed cleanup from previous run.

**Action Required**: Free up disk space, reduce parallel thread count, manually clean `C:\Temp\e2e-tests\`.

---

## Troubleshooting

### Issue: "GitHub API rate limit exceeded"

**Symptoms**:

- Multiple tests fail with "403 Forbidden" error
- Error message shows "X-RateLimit-Remaining: 0"

**Solution**:

1. **Option A: Wait for rate limit reset**
   - Rate limits reset on the hour (e.g., if exceeded at 2:45pm, resets at 3:00pm)
   - Check reset time in error message

2. **Option B: Use GitHub Personal Access Token (recommended)**
   ```powershell
   # Create token at https://github.com/settings/tokens
   # Requires no special scopes (public repo read access sufficient)
   $env:GITHUB_PAT = "ghp_YOUR_TOKEN_HERE"
   Invoke-Pester -Path tests/integration/SmartMerge.E2E.Tests.ps1
   ```

### Issue: "Fingerprints database missing or corrupted"

**Symptoms**:

- Test suite fails immediately with "File not found: data/speckit-fingerprints.json"
- Or: "Invalid JSON in fingerprints database"

**Solution**:

```powershell
# Verify file exists
Test-Path "data/speckit-fingerprints.json"

# If missing, restore from Git
git checkout data/speckit-fingerprints.json

# Validate JSON structure
Get-Content "data/speckit-fingerprints.json" | ConvertFrom-Json
```

### Issue: "Disk space exhaustion"

**Symptoms**:

- Tests fail with "Insufficient disk space" error
- Temp directories accumulating in `C:\Temp\e2e-tests\`

**Solution**:

```powershell
# Check available space
(Get-PSDrive -Name C).Free / 1GB

# Manual cleanup (if test crashed without cleanup)
Remove-Item -Path "C:\Temp\e2e-tests\test-*" -Recurse -Force

# Reduce parallel thread count (lower peak disk usage)
Invoke-Pester -Path tests/integration/SmartMerge.E2E.Tests.ps1 -Configuration @{
    Run = @{ ThrottleLimit = 2 }
}
```

### Issue: "PowerShell version too old"

**Symptoms**:

- Error: "ForEach-Object: A parameter cannot be found that matches parameter name 'Parallel'"

**Solution**:

```powershell
# Upgrade to PowerShell 7.0+
# Download from: https://github.com/PowerShell/PowerShell/releases

# Verify version after upgrade
pwsh --version  # Should show 7.0 or higher
```

### Issue: "Pester version incompatible"

**Symptoms**:

- Error: "Invoke-Pester: A parameter cannot be found that matches parameter name 'Configuration'"

**Solution**:

```powershell
# Install Pester 5.x
Install-Module -Name Pester -MinimumVersion 5.0 -Force -SkipPublisherCheck

# Verify version
Get-Module -ListAvailable Pester  # Should show 5.x
```

---

## Performance Tuning

### Adjusting Parallelism

**Default**: 4 threads (balanced performance and resource usage)

```powershell
# For faster machines (8+ cores, 16GB+ RAM)
# Increase to 6 threads (10-12 minute execution)
$config = [PesterConfiguration]::Default
$config.Run.ThrottleLimit = 6
Invoke-Pester -Path tests/integration/SmartMerge.E2E.Tests.ps1 -Configuration $config

# For resource-limited machines (4 cores, 4GB RAM)
# Decrease to 2 threads (20-25 minute execution)
$config.Run.ThrottleLimit = 2
Invoke-Pester -Path tests/integration/SmartMerge.E2E.Tests.ps1 -Configuration $config
```

**Tradeoffs**:

| Threads | Duration | RAM Usage | Disk Usage | GitHub API Calls |
|---------|----------|-----------|------------|------------------|
| 1 | ~45-60 min | ~1GB | ~10MB | Serial (no contention) |
| 2 | ~20-25 min | ~2GB | ~20MB | Moderate contention |
| 4 | **12-15 min** | **~4GB** | **~40MB** | **Balanced (default)** |
| 6 | ~10-12 min | ~6GB | ~60MB | Higher contention |

### Reducing Test Count

**Default**: 18 merge pairs (~40% coverage of 45 total pairs)

```powershell
# Edit test file to reduce pair count (faster feedback during development)
# In SmartMerge.E2E.Tests.ps1, change:
$mergePairs = Get-RandomMergePairs -Versions $versions -Count 10  # Instead of 18

# Execution time scales linearly with count:
# 10 pairs ≈ 7-8 minutes (with 4 threads)
# 18 pairs ≈ 12-15 minutes (with 4 threads)
```

### Optimizing GitHub API Calls

```powershell
# Use GitHub token to avoid rate limiting
$env:GITHUB_PAT = "ghp_YOUR_TOKEN_HERE"

# Mutex delay is 500ms (conservative)
# Could reduce to 250ms for faster execution (still within limits)
# Edit Install-SpecKitVersion in E2ETestHelpers.psm1:
Start-Sleep -Milliseconds 250  # Instead of 500
```

---

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: E2E Smart Merge Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  e2e-tests:
    runs-on: windows-latest
    timeout-minutes: 30

    steps:
      - uses: actions/checkout@v3

      - name: Setup PowerShell 7
        uses: actions/setup-powershell@v1
        with:
          powershell-version: '7.4'

      - name: Install Pester
        run: Install-Module -Name Pester -MinimumVersion 5.0 -Force -SkipPublisherCheck

      - name: Run E2E Tests
        env:
          GITHUB_PAT: ${{ secrets.GITHUB_TOKEN }}
        run: |
          Invoke-Pester -Path tests/integration/SmartMerge.E2E.Tests.ps1 `
                        -Output Detailed `
                        -Configuration @{
                          Run = @{ ThrottleLimit = 2 }  # Lower for CI resources
                        }

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: TestResults.xml
```

---

## Debugging Failed Tests

### Enable Detailed Logging

```powershell
# Run with maximum verbosity
$VerbosePreference = 'Continue'
Invoke-Pester -Path tests/integration/SmartMerge.E2E.Tests.ps1 -Verbose
```

### Preserve Test Artifacts

```powershell
# Modify test file to skip cleanup on failure
# In SmartMerge.E2E.Tests.ps1, edit finally block:
finally {
    if ($testResult.Status -eq 'Failed') {
        Write-Host "Test failed - preserving directory: $testDir"
        # Skip Remove-Item
    } else {
        Remove-Item -Path $testDir -Recurse -Force
    }
}
```

### Inspect Merged Files

```powershell
# Find preserved test directory
Get-ChildItem -Path "C:\Temp\e2e-tests\test-*" -Directory

# Navigate to specific test
cd "C:\Temp\e2e-tests\test-v0.0.50-abc123"

# Examine merged files
Get-Content ".claude/commands/speckit.plan.md"

# Look for conflict markers
Select-String -Path ".claude/commands/*.md" -Pattern "^<<<<<<<|^>>>>>>>"
```

---

## Frequently Asked Questions

### Q: How long should the test suite take?

**A**: With default settings (4 parallel threads, 18 merge pairs), expect 12-15 minutes. Sequential execution takes 45-60 minutes.

### Q: Can I run tests without internet access?

**A**: No, tests download real SpecKit releases from GitHub. Mocked/cached templates could be added in future.

### Q: What happens if I cancel the test suite mid-run?

**A**: Cleanup may not run, leaving orphaned directories in `C:\Temp\e2e-tests\`. Manually delete with:
```powershell
Remove-Item -Path "C:\Temp\e2e-tests\test-*" -Recurse -Force
```

### Q: Are test results deterministic?

**A**: Yes, using seed 42 for all randomization. Same versions and merge pairs selected every run.

### Q: Can I test a specific version pair?

**A**: Not directly via Invoke-Pester. Edit `SmartMerge.E2E.Tests.ps1` to hardcode specific pairs for debugging.

### Q: Why dad jokes?

**A**: They're distinguishable, harmless test content that's easy to detect after merge. Any unique text would work.

---

## Next Steps

- ✅ Run test suite to validate smart merge system
- ✅ Review test report to understand merge success rate
- ⏳ If failures occur, use troubleshooting guide
- ⏳ Integrate into CI/CD pipeline
- ⏳ Consider contributing improvements (caching, parallel optimization)

---

## Support

- **GitHub Issues**: https://github.com/NotMyself/claude-win11-speckit-update-skill/issues
- **Documentation**: See `specs/013-e2e-smart-merge-test/` directory
- **Slack/Discord**: [If applicable]

---

**Version**: 1.0 | **Last Updated**: 2025-10-24
