# Quickstart: Fix Module Import Error

**Feature**: Fix Module Import Error
**Branch**: 002-fix-module-import-error
**Target Audience**: Developers implementing and testing the bug fix

## Overview

This guide provides step-by-step instructions for implementing, testing, and validating the module import error fix.

## Prerequisites

- PowerShell 7.x installed (`pwsh --version`)
- Pester 5.x installed (`Get-Module -ListAvailable Pester`)
- Clone of the repository on branch `002-fix-module-import-error`
- Access to a SpecKit project for integration testing

## Implementation Steps

### Step 1: Review Current Behavior

Before implementing the fix, verify the current bug exists:

```powershell
# Navigate to repository root
cd C:\Users\bobby\src\claude-Win11-SpecKit-Safe-Update-Skill

# Run orchestrator with verbose logging to see current behavior
pwsh -ExecutionPolicy Bypass -File "scripts\update-orchestrator.ps1" -CheckOnly -Verbose
```

**Expected Output (Current Bug)**:
```
Failed to import modules: The Export-ModuleMember cmdlet can only be called from inside a module.
```

**Verify in Verbose Output**:
- All 6 modules actually load successfully (VERBOSE: Importing function...)
- Error occurs despite successful imports

### Step 2: Modify update-orchestrator.ps1

Open `scripts\update-orchestrator.ps1` and locate lines 90-124 (module import section).

**Current Code** (lines 90-106):

```powershell
try {
    # Import all required modules
    $modulesPath = Join-Path $PSScriptRoot "modules"

    Import-Module (Join-Path $modulesPath "HashUtils.psm1") -Force
    Import-Module (Join-Path $modulesPath "VSCodeIntegration.psm1") -Force
    Import-Module (Join-Path $modulesPath "GitHubApiClient.psm1") -Force
    Import-Module (Join-Path $modulesPath "ManifestManager.psm1") -Force
    Import-Module (Join-Path $modulesPath "BackupManager.psm1") -Force
    Import-Module (Join-Path $modulesPath "ConflictDetector.psm1") -Force

    # Import helper functions
    # ... (helpers section remains unchanged)

    Write-Verbose "All modules and helpers loaded successfully"
}
catch {
    Write-Error "Failed to import modules: $($_.Exception.Message)"
    exit 1
}
```

**Replace With** (implementation from [research.md](research.md)):

```powershell
try {
    # Temporarily suppress non-fatal errors during module import
    $savedErrorPreference = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'

    # Import all required modules
    $modulesPath = Join-Path $PSScriptRoot "modules"

    Write-Verbose "Importing PowerShell modules from: $modulesPath"

    Import-Module (Join-Path $modulesPath "HashUtils.psm1") -Force -WarningAction SilentlyContinue
    Import-Module (Join-Path $modulesPath "VSCodeIntegration.psm1") -Force -WarningAction SilentlyContinue
    Import-Module (Join-Path $modulesPath "GitHubApiClient.psm1") -Force -WarningAction SilentlyContinue
    Import-Module (Join-Path $modulesPath "ManifestManager.psm1") -Force -WarningAction SilentlyContinue
    Import-Module (Join-Path $modulesPath "BackupManager.psm1") -Force -WarningAction SilentlyContinue
    Import-Module (Join-Path $modulesPath "ConflictDetector.psm1") -Force -WarningAction SilentlyContinue

    # Restore strict error handling
    $ErrorActionPreference = $savedErrorPreference

    # Validate critical functions are available
    Write-Verbose "Validating module imports..."

    $requiredCommands = @(
        'Get-NormalizedHash',        # HashUtils
        'Get-ExecutionContext',       # VSCodeIntegration
        'Get-LatestSpecKitRelease',  # GitHubApiClient
        'Get-SpecKitManifest',       # ManifestManager
        'New-SpecKitBackup',         # BackupManager
        'Get-FileState'              # ConflictDetector
    )

    $missingCommands = $requiredCommands | Where-Object {
        -not (Get-Command $_ -ErrorAction SilentlyContinue)
    }

    if ($missingCommands.Count -gt 0) {
        Write-Error "Failed to import required commands: $($missingCommands -join ', ')"
        Write-Error "Module path: $modulesPath"
        Write-Error "Ensure all .psm1 files are present and not corrupted"
        exit 2  # Prerequisites not met
    }

    Write-Verbose "Module validation successful: $($requiredCommands.Count) critical functions available"

    # Import helper functions (unchanged)
    # ... (helpers section remains as-is)

    Write-Verbose "All modules and helpers loaded successfully"
}
catch {
    Write-Error "Critical error during module import: $($_.Exception.Message)"
    Write-Error "Stack trace: $($_.ScriptStackTrace)"
    exit 1
}
```

### Step 3: Test the Fix Manually

Run the orchestrator again to verify the fix works:

```powershell
# Test 1: Normal execution (should proceed without errors)
pwsh -ExecutionPolicy Bypass -File "scripts\update-orchestrator.ps1" -CheckOnly

# Test 2: Verbose logging (should show clean import messages)
pwsh -ExecutionPolicy Bypass -File "scripts\update-orchestrator.ps1" -CheckOnly -Verbose

# Test 3: From a SpecKit project directory
cd path\to\speckit-project
pwsh -ExecutionPolicy Bypass -File "C:\path\to\skill\scripts\update-orchestrator.ps1" -CheckOnly
```

**Expected Output (Fixed)**:
- No "Export-ModuleMember" error
- Script proceeds to prerequisite validation
- `-CheckOnly` mode displays update status
- Verbose output shows "Module validation successful: 6 critical functions available"

### Step 4: Test Error Handling

Simulate module failures to verify error handling works:

```powershell
# Test missing module file
cd scripts\modules
ren HashUtils.psm1 HashUtils.psm1.bak

# Run orchestrator (should fail with helpful error)
cd ..\..
pwsh -ExecutionPolicy Bypass -File "scripts\update-orchestrator.ps1" -CheckOnly

# Restore module file
cd scripts\modules
ren HashUtils.psm1.bak HashUtils.psm1
```

**Expected Output (Error Handling)**:
```
Failed to import required commands: Get-NormalizedHash
Module path: C:\...\scripts\modules
Ensure all .psm1 files are present and not corrupted
```

### Step 5: Run Automated Tests

Execute the test suite to verify fix doesn't break existing functionality:

```powershell
# Run all tests
.\tests\test-runner.ps1

# Run only unit tests
.\tests\test-runner.ps1 -Unit

# Run only integration tests
.\tests\test-runner.ps1 -Integration
```

**Expected Results**:
- All existing tests pass (no regressions)
- New tests for import validation pass (if added)

## Testing Checklist

Use this checklist to validate the fix comprehensively:

### Functional Testing

- [ ] **Normal Operation**: Orchestrator runs without errors with `-CheckOnly` flag
- [ ] **Verbose Logging**: `-Verbose` shows clean diagnostic output
- [ ] **All Parameters**: Test `-Version`, `-Force`, `-Rollback`, `-NoBackup` flags
- [ ] **Claude Code Integration**: Run `/speckit-update` command in Claude Code (if available)

### Error Handling Testing

- [ ] **Missing Module File**: Remove a `.psm1` file, verify error message includes file path
- [ ] **Corrupted Module**: Insert syntax error in module, verify error is caught
- [ ] **Partial Load**: Simulate scenario where module loads but function unavailable
- [ ] **PowerShell Version**: Test with PowerShell 7.x (primary), 5.1 if applicable

### Edge Case Testing

- [ ] **User Profile Interference**: Run with `-NoProfile` flag
- [ ] **Execution Policy**: Test with different execution policies (`Bypass`, `RemoteSigned`)
- [ ] **Different Hosts**: Test in pwsh.exe, VSCode terminal, Windows Terminal
- [ ] **Network Disconnected**: Ensure module import doesn't require network access

### Performance Testing

- [ ] **Import Speed**: Verify module import completes in under 2 seconds
- [ ] **Validation Overhead**: Confirm function checks add <100ms overhead

### Regression Testing

- [ ] **Existing Tests Pass**: All unit and integration tests pass
- [ ] **Helper Functions Load**: All helper scripts load correctly
- [ ] **Orchestrator Workflow**: Full update workflow proceeds past import phase

## Troubleshooting

### Issue: "Get-Command: The term 'Get-NormalizedHash' is not recognized"

**Cause**: Module failed to load, function not available

**Resolution**:
1. Check module file exists: `ls scripts\modules\HashUtils.psm1`
2. Verify module syntax: `pwsh -NoProfile -File scripts\modules\HashUtils.psm1`
3. Check PowerShell version: `$PSVersionTable.PSVersion` (must be 7.x)

### Issue: "Validation passes but orchestrator still fails later"

**Cause**: Missing function not in required functions list

**Resolution**:
1. Identify which function is missing from error message
2. Add to `$requiredCommands` array in update-orchestrator.ps1
3. Determine which module exports that function
4. Ensure module loads correctly

### Issue: "Tests fail with mocking errors"

**Cause**: Pester 5.x module scoping issues (known limitation)

**Resolution**:
- Verify fix works manually (integration test)
- Document test limitation in test file comments
- Tests may show false failures but real execution works

## Success Criteria Validation

Verify all success criteria from [spec.md](spec.md) are met:

| Criteria | Test Method | Status |
|----------|-------------|--------|
| SC-001: 100% success rate on Windows 11 + PS 7.x | Run orchestrator 10 times, verify 0 failures | ☐ |
| SC-002: Import completes in under 2 seconds | Measure with `Measure-Command` | ☐ |
| SC-003: Zero false-positive errors | Check output for Export-ModuleMember errors | ☐ |
| SC-004: Genuine failures have clear error messages | Simulate missing module, verify error quality | ☐ |
| SC-005: All functions remain available | Run `Get-Command <function>` for all 6 modules | ☐ |
| SC-006: Works via Claude Code `/speckit-update` | Test in Claude Code environment | ☐ |
| SC-007: Verbose logging provides diagnostics | Run with `-Verbose`, verify helpful output | ☐ |

## Next Steps

After completing this quickstart:

1. **Create Pull Request**: Submit fix with updated tests
2. **Update CHANGELOG.md**: Add entry under `[Unreleased]` → `### Fixed`
3. **Update Documentation**: If error messages changed, update README.md
4. **Manual QA**: Test on clean Windows 11 VM if available

## References

- **Bug Report**: [docs/bugs/BUG-REPORT-Export-ModuleMember-Error.md](../../docs/bugs/BUG-REPORT-Export-ModuleMember-Error.md)
- **Feature Spec**: [spec.md](spec.md)
- **Research**: [research.md](research.md)
- **Implementation Plan**: [plan.md](plan.md)
- **Constitution**: [.specify/memory/constitution.md](../../.specify/memory/constitution.md)
