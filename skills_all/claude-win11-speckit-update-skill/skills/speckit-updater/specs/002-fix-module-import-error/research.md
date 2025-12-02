# Research: Fix Module Import Error

**Feature**: Fix Module Import Error
**Branch**: 002-fix-module-import-error
**Date**: 2025-10-20

## Overview

This research document consolidates findings on PowerShell error handling patterns, module import validation, and best practices for distinguishing fatal from non-fatal errors in PowerShell 7.x.

## Research Questions

1. Why does `Export-ModuleMember` generate errors when called from `.psm1` files imported via direct file paths?
2. What are PowerShell best practices for handling non-terminating errors during module import?
3. How can we reliably validate that module functions are available post-import?
4. What error suppression techniques are appropriate for non-fatal PowerShell warnings?

## Findings

### 1. Export-ModuleMember Context Error

**Decision**: Keep existing `Export-ModuleMember` calls in modules; handle error in orchestrator

**Rationale**:

PowerShell's `Export-ModuleMember` cmdlet is sensitive to execution context. The error "Export-ModuleMember cmdlet can only be called from inside a module" occurs due to PowerShell's module loading mechanism when:

- Modules are imported via direct file path with `Import-Module path\to\file.psm1`
- PowerShell's script parser encounters `Export-ModuleMember` before fully establishing module context
- The error is a **non-terminating error** (does not stop execution)
- All module functions are successfully imported despite the error message

**Evidence from bug report**:
- Verbose output shows all 6 modules load successfully
- All functions are imported and available (Get-NormalizedHash, Get-ExecutionContext, etc.)
- Error appears in error stream but does not prevent module functionality

**Alternatives Considered**:

| Alternative | Rejected Because |
|-------------|------------------|
| Remove `Export-ModuleMember` from all modules | Violates Constitution's PowerShell Standards (Principle: "Explicitly export functions with Export-ModuleMember") |
| Create `.psd1` manifest files for each module | Too invasive; restructures entire project; violates FR-008 (keep existing structure) |
| Use `using module` instead of `Import-Module` | Requires PowerShell 5.0+ syntax; less flexible for dynamic paths |
| Import modules by name instead of path | Requires modules in `$env:PSModulePath`; not suitable for skill distribution |

**Implementation Approach**: Handle the non-terminating error gracefully in the orchestrator's try-catch block rather than modifying module structure.

### 2. PowerShell Error Handling Best Practices

**Decision**: Use post-import function validation instead of relying on try-catch success

**Rationale**:

PowerShell distinguishes between terminating and non-terminating errors:

- **Terminating Errors**: Stop execution, caught by try-catch
- **Non-Terminating Errors**: Written to error stream, continue execution, caught by try-catch when `$ErrorActionPreference = 'Stop'`

Current problem: `$ErrorActionPreference = 'Stop'` in update-orchestrator.ps1 converts the non-terminating Export-ModuleMember error into a terminating error, causing unnecessary exit.

**Best Practice Pattern**:

```powershell
# BAD: Relies on try-catch success
try {
    Import-Module $modulePath
    # If we reach here, assume success
}
catch {
    Write-Error "Import failed"
    exit 1
}

# GOOD: Validates post-import state
try {
    Import-Module $modulePath -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
}
finally {
    # Check if module actually loaded
    $requiredFunctions = @('Function1', 'Function2')
    $missingFunctions = $requiredFunctions | Where-Object {
        -not (Get-Command $_ -ErrorAction SilentlyContinue)
    }

    if ($missingFunctions.Count -gt 0) {
        Write-Error "Failed to load: $($missingFunctions -join ', ')"
        exit 1
    }
}
```

**Key Insight**: Testing for **presence of functions** is more reliable than testing for **absence of errors** when non-terminating errors are expected.

### 3. Module Function Validation Strategy

**Decision**: Create a definitive list of required functions and validate their availability post-import

**Rationale**:

Each of the 6 modules exports specific functions that the orchestrator depends on. By checking function availability using `Get-Command`, we can definitively determine if modules loaded correctly regardless of error messages.

**Required Functions by Module**:

| Module | Required Functions |
|--------|-------------------|
| HashUtils.psm1 | Get-NormalizedHash, Compare-FileHashes |
| VSCodeIntegration.psm1 | Get-ExecutionContext, Open-VSCodeDiff, Open-VSCodeMerge |
| GitHubApiClient.psm1 | Get-LatestSpecKitRelease, Get-SpecKitRelease, Download-SpecKitTemplates |
| ManifestManager.psm1 | Get-SpecKitManifest, Set-SpecKitManifest, New-SpecKitManifest, Update-ManifestVersion |
| BackupManager.psm1 | New-SpecKitBackup, Restore-SpecKitBackup, Get-BackupHistory, Remove-OldBackups |
| ConflictDetector.psm1 | Get-FileState, Compare-FileStates, Get-ConflictList |

**Validation Approach**:

```powershell
$requiredCommands = @(
    'Get-NormalizedHash',
    'Get-ExecutionContext',
    'Get-LatestSpecKitRelease',
    'Get-SpecKitManifest',
    'New-SpecKitBackup',
    'Get-FileState'
)

$missingCommands = $requiredCommands | Where-Object {
    -not (Get-Command $_ -ErrorAction SilentlyContinue)
}

if ($missingCommands.Count -gt 0) {
    Write-Error "Failed to import required commands: $($missingCommands -join ', ')"
    Write-Error "Check module files in: $modulesPath"
    exit 2  # Prerequisites not met
}
```

**Note**: We only need to check **one representative function per module** to confirm module loaded. Checking all functions would be redundant.

### 4. Error Suppression Techniques

**Decision**: Use `-ErrorAction SilentlyContinue` and `-WarningAction SilentlyContinue` during import, validate afterward

**Rationale**:

PowerShell provides multiple error handling parameters:

| Parameter | Effect | Use Case |
|-----------|--------|----------|
| `-ErrorAction Stop` | Convert non-terminating to terminating | Current approach (too strict) |
| `-ErrorAction Continue` | Display error, continue execution | Shows false-positive errors to user |
| `-ErrorAction SilentlyContinue` | Suppress error, continue execution | Hide expected non-fatal errors |
| `-WarningAction SilentlyContinue` | Suppress warnings | Hide unapproved verb warnings |

**Recommended Approach**:

```powershell
# Suppress expected errors during import
$ErrorActionPreference = 'SilentlyContinue'

Import-Module $modulePath -Force -WarningAction SilentlyContinue

# Restore strict error handling
$ErrorActionPreference = 'Stop'

# Validate actual import success
if (-not (Get-Command 'Get-NormalizedHash' -ErrorAction SilentlyContinue)) {
    Write-Error "Module import failed: HashUtils functions not available"
    exit 2
}
```

**Verbose Logging**: When `-Verbose` flag is used, we should still show import progress using `Write-Verbose` before suppressing errors, so diagnostics remain available.

### 5. Unapproved Verb Warnings

**Issue from bug report**:
```
WARNING: The names of some imported commands from the module 'GitHubApiClient'
include unapproved verbs that might make them less discoverable.
```

**Root Cause**: Function `Download-SpecKitTemplates` uses unapproved verb `Download`. PowerShell approved verbs are: Get, Set, New, Remove, Invoke, etc.

**Decision**: Suppress warnings with `-WarningAction SilentlyContinue` during import

**Alternatives Considered**:

| Alternative | Decision |
|-------------|----------|
| Rename `Download-SpecKitTemplates` to `Get-SpecKitTemplates` | Not part of this bug fix scope; can be addressed in future refactoring |
| Suppress warnings globally | Only suppress during import; restore normal warning behavior afterward |
| Ignore warnings entirely | Acceptable for user-facing output; diagnostics still available with `-Verbose` |

### 6. PowerShell Host Compatibility

**Research Question**: Does error behavior differ across PowerShell hosts?

**Finding**: The Export-ModuleMember error occurs consistently across:
- `pwsh.exe` (PowerShell 7.x standalone)
- VSCode integrated terminal (PowerShell 7.x)
- Claude Code skill invocation context

**Implication**: Fix must work in all contexts without host-specific logic.

## Implementation Summary

### Code Changes Required

**File**: `scripts/update-orchestrator.ps1`
**Lines**: 90-124 (module import section)

**Modification Pattern**:

```powershell
# BEFORE (lines 90-117)
try {
    Import-Module (Join-Path $modulesPath "HashUtils.psm1") -Force
    Import-Module (Join-Path $modulesPath "VSCodeIntegration.psm1") -Force
    # ... more imports ...

    Write-Verbose "All modules and helpers loaded successfully"
}
catch {
    Write-Error "Failed to import modules: $($_.Exception.Message)"
    exit 1
}

# AFTER
try {
    # Temporarily suppress non-fatal errors during import
    $savedErrorPreference = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'

    Write-Verbose "Importing PowerShell modules..."

    Import-Module (Join-Path $modulesPath "HashUtils.psm1") -Force -WarningAction SilentlyContinue
    Import-Module (Join-Path $modulesPath "VSCodeIntegration.psm1") -Force -WarningAction SilentlyContinue
    # ... more imports with same pattern ...

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

    Write-Verbose "All modules loaded successfully: $($requiredCommands.Count) functions available"

    # ... continue with helper imports ...
}
catch {
    Write-Error "Critical error during module import: $($_.Exception.Message)"
    Write-Error "Stack trace: $($_.ScriptStackTrace)"
    exit 1
}
```

### Testing Requirements

**Unit Tests** (`tests/unit/UpdateOrchestrator.Tests.ps1`):

```powershell
Describe "Module Import Validation" {
    Context "When all modules load successfully" {
        It "Should detect all required functions" {
            # Mock Get-Command to return success for all functions
            # Verify validation passes
        }
    }

    Context "When a module fails to load" {
        It "Should detect missing functions" {
            # Mock Get-Command to return null for one function
            # Verify validation fails with correct error
        }
    }

    Context "When Export-ModuleMember generates warnings" {
        It "Should not treat warnings as fatal errors" {
            # Verify script continues despite warnings
        }
    }
}
```

**Integration Tests** (`tests/integration/UpdateOrchestrator.Tests.ps1`):

```powershell
Describe "Orchestrator Module Import (Integration)" {
    It "Should load all modules without fatal errors" {
        # Run orchestrator with -Verbose
        # Verify exit code 0 or continues past import phase
    }

    It "Should provide helpful error when module file missing" {
        # Temporarily rename a module file
        # Verify error message includes file path
        # Restore file
    }
}
```

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| False positives (modules load but functions unavailable) | Low | High | Comprehensive function list covers all critical dependencies |
| Performance impact from Get-Command checks | Low | Low | Get-Command is fast (<10ms per check), 6 checks = ~60ms |
| Different error behavior in future PowerShell versions | Low | Medium | Validation approach works regardless of error messages |
| Breaking existing tests | Medium | Low | Existing tests may expect specific error messages; update test mocks |

## Conclusion

The fix is straightforward and localized:

1. **Suppress non-fatal errors** during module import using `-ErrorAction SilentlyContinue` and `-WarningAction SilentlyContinue`
2. **Validate post-import state** by checking for presence of required functions using `Get-Command`
3. **Provide actionable errors** when genuine failures occur (missing files, corrupted modules)
4. **Maintain diagnostics** by preserving `Write-Verbose` output for troubleshooting

This approach:
- ✅ Fixes the immediate bug (skill execution blocked)
- ✅ Improves error handling (distinguishes fatal from non-fatal)
- ✅ Maintains constitution compliance (no architecture changes)
- ✅ Preserves existing module structure (no refactoring required)
- ✅ Adds minimal performance overhead (<100ms)
- ✅ Works across all PowerShell hosts
