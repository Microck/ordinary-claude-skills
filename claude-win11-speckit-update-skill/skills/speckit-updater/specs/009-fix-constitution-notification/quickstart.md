# Quickstart: Constitution Notification Bug Fix

**Feature**: 009-fix-constitution-notification
**Date**: 2025-10-22
**Audience**: Developers testing or modifying the constitution notification logic

## Overview

This guide provides quick commands for testing the bug fix that adds hash verification to Step 12 of the update orchestrator. Use this guide to validate that false positive notifications are eliminated while real changes are still detected.

## Prerequisites

- PowerShell 7+ installed (`pwsh.exe`)
- Git repository cloned locally
- Test SpecKit project with `.specify/` directory
- Windows Terminal (recommended for emoji display)

## Quick Test: Validate Bug Fix

### 1. Test False Positive Scenario (Hashes Match)

**Objective**: Verify no notification shown when constitution file unchanged

```powershell
# Navigate to project with .specify/ directory
cd C:\path\to\speckit-project

# Create backup with identical constitution
$backupPath = ".specify/backups/test-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path "$backupPath/.specify/memory" -Force | Out-Null
Copy-Item .specify/memory/constitution.md "$backupPath/.specify/memory/constitution.md"

# Run orchestrator with verbose logging
& "C:\path\to\skill\scripts\update-orchestrator.ps1" -CheckOnly -Verbose

# Expected output (in verbose mode):
# VERBOSE: Constitution hash comparison:
# VERBOSE:   CurrentHash=sha256:abc123...
# VERBOSE:   BackupHash=sha256:abc123...
# VERBOSE:   Changed=False
# VERBOSE: Constitution marked as updated but content unchanged - skipping notification

# Verify: NO constitution notification displayed
```

✅ **Pass Criteria**: No "📋 Constitution Template Updated" or "⚠️ Constitution Conflict" message shown

### 2. Test Real Change Scenario (Hashes Differ)

**Objective**: Verify informational notification shown when constitution actually changed

```powershell
# Modify backup constitution to simulate upstream change
Add-Content "$backupPath/.specify/memory/constitution.md" "`n`n# Test amendment"

# Run orchestrator again
& "C:\path\to\skill\scripts\update-orchestrator.ps1" -CheckOnly -Verbose

# Expected output:
# VERBOSE: Constitution hash comparison:
# VERBOSE:   CurrentHash=sha256:abc123...
# VERBOSE:   BackupHash=sha256:def456...  (different!)
# VERBOSE:   Changed=True
#
# ℹ️  Constitution Template Updated
# The constitution template was cleanly updated (no conflicts).
# OPTIONAL: Review changes by running:
#   /speckit.constitution C:\...\backups\test-...\\.specify\memory\constitution.md
```

✅ **Pass Criteria**:
- ℹ️ emoji displayed (information icon)
- Cyan/gray colors used
- "OPTIONAL" label visible
- Backup path included in command

### 3. Test Conflict Scenario (Required Action)

**Objective**: Verify urgent notification shown for conflicts

```powershell
# Simulate conflict by marking constitution as "ConflictsResolved"
# (This requires modifying orchestrator temporarily or using integration tests)

# Expected output:
# ⚠️  Constitution Conflict Detected
# The constitution has conflicts requiring manual resolution.
# REQUIRED: Run the following command:
#   /speckit.constitution C:\...\backups\...\\.specify\memory\constitution.md
```

✅ **Pass Criteria**:
- ⚠️ emoji displayed (warning icon)
- Red/yellow colors used
- "REQUIRED" label visible
- Message clearly distinguishes from optional updates

## Running Automated Tests

### All Tests

```powershell
cd C:\path\to\skill
.\tests\test-runner.ps1
```

Expected output:
```
Executing all tests
[+] Tests passed: XXX
[+] Tests failed: 0
```

### Integration Tests Only

```powershell
.\tests\test-runner.ps1 -Integration
```

**New Test Cases** (added for this bug fix):
- `Constitution marked updated but identical hashes → no notification`
- `Constitution cleanly updated with differing hashes → informational notification`
- `Constitution conflict with differing hashes → required action notification`
- `Constitution conflict but identical hashes → no notification`

### Unit Tests Only

```powershell
.\tests\test-runner.ps1 -Unit
```

**Note**: No new unit tests required. Existing `HashUtils.Tests.ps1` already validates `Get-NormalizedHash`.

### Verbose Test Output

```powershell
.\tests\test-runner.ps1 -Integration -Verbose
```

Use verbose mode to see detailed test execution and mock function calls.

## Debugging Tips

### Enable Verbose Logging

See hash comparison details in real-time:

```powershell
$VerbosePreference = 'Continue'
& .\scripts\update-orchestrator.ps1 -CheckOnly
```

**Expected verbose output structure**:
```
VERBOSE: Step 12: Checking for constitution updates...
VERBOSE: Constitution hash comparison:
VERBOSE:   CurrentPath=C:\...\\.specify\memory\constitution.md
VERBOSE:   BackupPath=C:\...\\.specify\backups\20251022-080753\\.specify\memory\constitution.md
VERBOSE:   CurrentHash=sha256:a1b2c3...
VERBOSE:   BackupHash=sha256:a1b2c3...
VERBOSE:   Changed=False
VERBOSE: Constitution marked as updated but content unchanged - skipping notification
```

### Check Emoji Rendering

If emoji not displaying correctly:

```powershell
# Test emoji support in current terminal
Write-Host "⚠️ Warning test" -ForegroundColor Red
Write-Host "ℹ️ Info test" -ForegroundColor Cyan

# Expected: Icons display correctly with colors
```

**Troubleshooting**:
- **Windows Terminal**: Settings → Profiles → Advanced → Text Rendering → Use built-in text renderer
- **VSCode Terminal**: Settings → Terminal › Integrated › Gpu Acceleration → "on"
- **Legacy PowerShell ISE**: Not supported (requires PowerShell 7+)

### Manually Inspect Hashes

Compare hashes manually to verify normalization:

```powershell
Import-Module .\scripts\modules\HashUtils.psm1 -Force

$hash1 = Get-NormalizedHash -FilePath ".specify/memory/constitution.md"
$hash2 = Get-NormalizedHash -FilePath ".specify/backups/20251022-080753/.specify/memory/constitution.md"

Write-Host "Current: $hash1"
Write-Host "Backup:  $hash2"
Write-Host "Match: $($hash1 -eq $hash2)"
```

### Performance Benchmarking

Measure Step 12 execution time:

```powershell
# Time entire orchestrator
Measure-Command {
    & .\scripts\update-orchestrator.ps1 -CheckOnly
}

# Expected: TotalMilliseconds < 5000 (entire orchestrator)
# Step 12 specifically: < 200ms (measured in verbose output if timing added)
```

### Force Error Scenarios

**Test fail-safe behavior**:

```powershell
# Test 1: Delete backup constitution
Remove-Item ".specify/backups/test-*/. specify/memory/constitution.md" -Force

# Run orchestrator - should show notification (fail-safe)
& .\scripts\update-orchestrator.ps1 -CheckOnly -Verbose

# Expected: "No backup constitution found - assuming changed" + notification shown

# Test 2: Lock constitution file (simulate file in use)
$file = [System.IO.File]::Open(".specify/memory/constitution.md", 'Open', 'Read', 'None')
& .\scripts\update-orchestrator.ps1 -CheckOnly -Verbose
$file.Close()

# Expected: Exception caught, "Constitution hash comparison failed" + notification shown
```

## Common Issues

### Issue: Emoji Display as Boxes or Question Marks

**Symptoms**:
```
[?][?]  Constitution Template Updated  (instead of ℹ️)
```

**Solution**:
1. Verify PowerShell version: `$PSVersionTable.PSVersion` (must be 7.0+)
2. Update Windows Terminal to latest version
3. Change terminal font to one with Unicode support (e.g., Cascadia Code, Consolas)
4. Check Settings → Profiles → Appearance → Font Face

### Issue: Hashes Always Differ Despite Identical Files

**Symptoms**:
- Visual diff shows no changes
- Hashes are different (`$hash1 -ne $hash2`)

**Solution**:
Check for line ending differences (should be handled by normalization, but verify):

```powershell
# Convert file to LF line endings
$content = Get-Content ".specify/memory/constitution.md" -Raw
$normalized = $content -replace "`r`n", "`n"
Set-Content ".specify/memory/constitution.md" -Value $normalized -NoNewline
```

**Root Cause**: `Get-NormalizedHash` should handle this automatically. If issue persists, check HashUtils module implementation.

### Issue: Test-Path Returns False for Backup Constitution

**Symptoms**:
```
VERBOSE: No backup constitution found - assuming changed
```

**Diagnosis**:
```powershell
# Verify backup directory exists
Test-Path ".specify/backups/test-*"

# Verify constitution exists in backup
Get-ChildItem ".specify/backups/test-*/.specify/memory/" -Recurse

# Check $backupPath variable value (in debugger or verbose output)
```

**Solution**:
- Ensure backup created in Step 8 before Step 12 runs
- Verify no file system errors during backup creation
- Check permissions on `.specify/backups/` directory

### Issue: Notification Still Showing for Identical Files

**Symptoms**: Bug fix not working as expected

**Diagnosis Checklist**:
1. ✅ Verify code changes applied to Step 12 (lines 677-707)
2. ✅ Confirm hash comparison logic added (`$currentHash -ne $backupHash`)
3. ✅ Check verbose output shows "Changed=False"
4. ✅ Verify conditional: `if ($actualChangeDetected)` wraps notification code

**Solution**: Re-read implementation plan and verify all code changes applied correctly.

## Manual Testing Checklist

Before submitting PR, validate:

- [ ] False positive eliminated (identical hashes → no notification)
- [ ] Real changes detected (different hashes → notification shown)
- [ ] Conflict notifications use ⚠️ emoji + red/yellow colors + "REQUIRED"
- [ ] Clean update notifications use ℹ️ emoji + cyan/gray colors + "OPTIONAL"
- [ ] Verbose logging shows structured key-value format
- [ ] Backup path included in notification command
- [ ] Fail-safe behavior works (missing backup → notification shown)
- [ ] Performance acceptable (Step 12 < 200ms)
- [ ] All integration tests pass
- [ ] Documentation updated (CLAUDE.md, CHANGELOG.md)

## Performance Validation

```powershell
# Measure hash computation time
Measure-Command {
    Get-NormalizedHash -FilePath ".specify/memory/constitution.md"
}
# Expected: < 100ms (typical file <50KB)

# Measure Step 12 overall (requires timing instrumentation in code)
# Expected: < 200ms total (2 hash computations + comparison + logging)
```

## Integration with CI/CD (Future)

```powershell
# Run tests in CI pipeline
$testResult = & .\tests\test-runner.ps1 -Integration -PassThru

if ($testResult.FailedCount -gt 0) {
    Write-Error "Integration tests failed: $($testResult.FailedCount) failures"
    exit 1
}

Write-Host "All tests passed: $($testResult.PassedCount) tests"
exit 0
```

## Next Steps

After validating locally:

1. **Submit PR** with changes to:
   - `scripts/update-orchestrator.ps1` (Step 12)
   - `tests/integration/UpdateOrchestrator.Tests.ps1` (4 new test cases)
   - `CLAUDE.md` (Constitution Update Notification section)
   - `CHANGELOG.md` (Fixed entry)

2. **Request code review** focusing on:
   - Hash comparison logic correctness
   - Error handling completeness
   - Accessibility (emoji + color + text labels)
   - Performance impact

3. **Validate with real project** after merging:
   - Test with actual SpecKit project (v0.0.0 → latest)
   - Monitor user feedback for false positives
   - Track support request reduction metrics

## Support

**Issues**: Report bugs at https://github.com/NotMyself/claude-win11-speckit-update-skill/issues
**Documentation**: See [CLAUDE.md](../../CLAUDE.md) for full project guidance
