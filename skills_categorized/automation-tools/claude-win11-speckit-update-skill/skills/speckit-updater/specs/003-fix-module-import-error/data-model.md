# Data Model: Module Loading Flow State Model

**Feature**: Fix Fatal Module Import Error
**Branch**: `003-fix-module-import-error`
**Date**: 2025-10-20

## Overview

This document models the state transitions and error handling flow for PowerShell module and helper script loading in the SpecKit Safe Update Skill orchestrator. Understanding these states is critical for implementing the fix correctly and ensuring fail-fast behavior is preserved for real errors.

---

## Entity Definitions

### Module Import Context

Represents the execution environment during module/helper loading.

**Attributes**:
- `errorPreference`: String - Current `$ErrorActionPreference` value (`Stop`, `Continue`, `SilentlyContinue`)
- `moduleContextActive`: Boolean - Whether PowerShell is executing inside a module scope
- `importedModules`: Array<String> - List of successfully imported module names
- `loadedHelpers`: Array<String> - List of successfully dot-sourced helper names
- `errors`: Array<Error> - Collection of errors encountered during loading

**Relationships**:
- Contains 0..N `ModuleLoadResult`
- Contains 0..N `HelperLoadResult`
- Contains 0..N `LoadError`

---

### ModuleLoadResult

Represents the outcome of a single module import operation.

**Attributes**:
- `modulePath`: String - Absolute path to `.psm1` file
- `moduleName`: String - Module name (e.g., "HashUtils")
- `state`: Enum - Current state (`Loading`, `Loaded`, `Failed`)
- `exportedFunctions`: Array<String> - Functions successfully exported
- `loadTimeMs`: Integer - Time taken to load in milliseconds
- `errorDetails`: String? - Error message if `state` is `Failed`

**States**:
- **Loading**: `Import-Module` command executing
- **Loaded**: Module successfully imported, functions available
- **Failed**: Import failed due to real error (syntax, missing file, etc.)

**Validation Rules**:
- `modulePath` must end with `.psm1`
- `state == Loaded` implies `exportedFunctions.length > 0`
- `state == Failed` implies `errorDetails != null`

---

### HelperLoadResult

Represents the outcome of a single helper script dot-sourcing operation.

**Attributes**:
- `helperPath`: String - Absolute path to `.ps1` file
- `helperName`: String - Helper name (e.g., "Show-UpdateSummary")
- `state`: Enum - Current state (`Loading`, `Loaded`, `Failed`)
- `definedFunctions`: Array<String> - Functions defined in the script
- `loadTimeMs`: Integer - Time taken to load in milliseconds
- `errorDetails`: String? - Error message if `state` is `Failed`

**States**:
- **Loading**: Dot-sourcing (`. script.ps1`) executing
- **Loaded**: Helper script executed, functions available in caller scope
- **Failed**: Dot-sourcing failed due to real error (syntax, missing file, etc.)

**Validation Rules**:
- `helperPath` must end with `.ps1`
- `state == Loaded` implies `definedFunctions.length > 0`
- `state == Failed` implies `errorDetails != null`

---

### LoadError

Represents an error encountered during module/helper loading.

**Attributes**:
- `errorType`: Enum - Classification of error (`Syntax`, `FileNotFound`, `PermissionDenied`, `ExportModuleMember`, `Unknown`)
- `severity`: Enum - Impact level (`Fatal`, `Warning`, `Benign`)
- `source`: String - File path where error occurred
- `message`: String - Full error message
- `stackTrace`: String? - PowerShell stack trace (if available)
- `suppressible`: Boolean - Whether this error can be safely suppressed

**Error Type Definitions**:

| Error Type | Severity | Suppressible | Description |
|------------|----------|--------------|-------------|
| `Syntax` | Fatal | NO | PowerShell parsing error (invalid code) |
| `FileNotFound` | Fatal | NO | Module/helper file missing |
| `PermissionDenied` | Fatal | NO | Insufficient permissions to read file |
| `ExportModuleMember` | Benign | YES | `Export-ModuleMember` called outside module context |
| `UnapprovedVerb` | Warning | YES | Function uses non-standard PowerShell verb |
| `Unknown` | Fatal | NO | Unclassified error (treat as fatal) |

**Validation Rules**:
- `severity == Fatal` implies `suppressible == false`
- `severity == Benign` implies `suppressible == true`
- `errorType == ExportModuleMember` implies `severity == Benign`

---

## State Transition Diagrams

### Module Import Flow (Import-Module)

```
┌─────────┐
│  Start  │
└────┬────┘
     │
     v
┌─────────────────────────┐
│ Initialize Module       │
│ Context (*.psm1)        │
└────┬────────────────────┘
     │
     v
┌─────────────────────────┐
│ Parse PowerShell Code   │
└────┬────────────────────┘
     │
     ├──[Syntax Error]──────────────> [FATAL: Exit]
     │
     v
┌─────────────────────────┐
│ Execute Module Code     │
│ (functions defined)     │
└────┬────────────────────┘
     │
     v
┌─────────────────────────┐
│ Process                 │
│ Export-ModuleMember     │
└────┬────────────────────┘
     │
     ├──[Export Success]──> [Module Loaded]
     │
     ├──[Export Error]────> [Log Warning, Continue]
     │                      (functions still available)
     │
     v
┌─────────────────────────┐
│ Return Module Object    │
└────┬────────────────────┘
     │
     v
┌─────────┐
│  End    │
└─────────┘
```

**Key Insight**: `Export-ModuleMember` errors do NOT prevent function availability. Module still loads successfully.

---

### Helper Dot-Source Flow (. script.ps1)

```
┌─────────┐
│  Start  │
└────┬────┘
     │
     v
┌─────────────────────────┐
│ NO Module Context       │
│ (executes in caller     │
│  scope)                 │
└────┬────────────────────┘
     │
     v
┌─────────────────────────┐
│ Parse PowerShell Code   │
└────┬────────────────────┘
     │
     ├──[Syntax Error]──────────────> [FATAL: Exit]
     │
     v
┌─────────────────────────┐
│ Execute Script in       │
│ Caller Scope            │
│ (functions added to     │
│  caller's scope)        │
└────┬────────────────────┘
     │
     v
┌─────────────────────────┐
│ Encounter               │
│ Export-ModuleMember?    │
└────┬────────────────────┘
     │
     ├──[YES]──> ┌──────────────────────────┐
     │           │ Throw Error:             │
     │           │ "Export-ModuleMember     │
     │           │  cmdlet can only be      │
     │           │  called from inside a    │
     │           │  module"                 │
     │           └────┬─────────────────────┘
     │                │
     │                ├──[$ErrorActionPreference == 'Stop']──> [FATAL: Exit]
     │                │
     │                ├──[$ErrorActionPreference == 'Continue']──> [Log Error, Continue]
     │                │
     │                └──[-ErrorAction SilentlyContinue]──> [Suppress Error]
     │
     ├──[NO]───> [Functions Available]
     │
     v
┌─────────┐
│  End    │
└─────────┘
```

**Key Insight**: `Export-ModuleMember` in dot-sourced scripts throws error BUT functions are still available (already added to caller scope).

---

### Orchestrator Import Flow (Current - With Workaround)

```
┌─────────┐
│  Start  │
└────┬────┘
     │
     v
┌─────────────────────────────────┐
│ Set $ErrorActionPreference      │
│ = 'Stop' (line 76)              │
└────┬────────────────────────────┘
     │
     v
┌─────────────────────────────────┐
│ Save $ErrorActionPreference     │
│ Set to 'Continue' (line 95-96)  │
└────┬────────────────────────────┘
     │
     v
┌─────────────────────────────────┐
│ Import 6 Modules                │
│ with -ErrorAction               │
│ SilentlyContinue (lines 103-108)│
└────┬────────────────────────────┘
     │
     ├──[Real Error]──> [SUPPRESSED - BAD!]
     │
     ├──[Export-ModuleMember Error]──> [SUPPRESSED - Intended]
     │
     v
┌─────────────────────────────────┐
│ Restore $ErrorActionPreference  │
│ (line 111)                      │
└────┬────────────────────────────┘
     │
     v
┌─────────────────────────────────┐
│ Save $ErrorActionPreference     │
│ Set to 'Continue' (line 119-120)│
└────┬────────────────────────────┘
     │
     v
┌─────────────────────────────────┐
│ Dot-Source 7 Helpers            │
│ with 2>$null (lines 125-131)    │
└────┬────────────────────────────┘
     │
     ├──[Real Error]──> [SUPPRESSED - BAD!]
     │
     ├──[Export-ModuleMember Error]──> [SUPPRESSED - Intended]
     │
     v
┌─────────────────────────────────┐
│ Restore $ErrorActionPreference  │
│ (line 134)                      │
└────┬────────────────────────────┘
     │
     v
┌─────────┐
│  End    │
└─────────┘
```

**Problem**: Real errors are suppressed along with benign `Export-ModuleMember` errors. Violates fail-fast principle.

---

### Orchestrator Import Flow (Proposed - After Fix)

```
┌─────────┐
│  Start  │
└────┬────┘
     │
     v
┌─────────────────────────────────┐
│ Set $ErrorActionPreference      │
│ = 'Stop'                        │
└────┬────────────────────────────┘
     │
     v
┌─────────────────────────────────┐
│ Try {                           │
│   Import 6 Modules              │
│   (no Export-ModuleMember       │
│    in .psm1 files)              │
│ }                               │
└────┬────────────────────────────┘
     │
     ├──[Real Error]──────────────> [FATAL: Catch Block]
     │                               │
     │                               v
     │                         ┌─────────────────────┐
     │                         │ Validate Functions  │
     │                         │ Are Available       │
     │                         └──┬──────────────────┘
     │                            │
     │                            ├──[Missing]──> [Exit 1]
     │                            │
     │                            └──[Available]──> [Warning]
     │
     v
┌─────────────────────────────────┐
│ Try {                           │
│   Dot-Source 7 Helpers          │
│   (NO Export-ModuleMember       │
│    in .ps1 files)               │
│ }                               │
└────┬────────────────────────────┘
     │
     ├──[Real Error]──────────────> [FATAL: Catch Block]
     │                               │
     │                               v
     │                         ┌─────────────────────┐
     │                         │ Display Error with  │
     │                         │ Stack Trace         │
     │                         └──┬──────────────────┘
     │                            │
     │                            v
     │                         [Exit 1]
     │
     v
┌─────────────────────────────────┐
│ Verify All Functions Available  │
└────┬────────────────────────────┘
     │
     v
┌─────────┐
│  End    │
└─────────┘
```

**Improvement**: Real errors cause immediate fatal exit. No `Export-ModuleMember` errors occur (removed from helpers).

---

## Error Handling Decision Tree

```
┌──────────────────────┐
│ Error Encountered    │
│ During Import        │
└────┬─────────────────┘
     │
     v
   Is File Missing?
     │
     ├──[YES]──> [FATAL: File not found, exit 1]
     │
     v
   Is Syntax Error?
     │
     ├──[YES]──> [FATAL: Parse error, exit 1]
     │
     v
   Is Permission Denied?
     │
     ├──[YES]──> [FATAL: Access denied, exit 1]
     │
     v
   Is Export-ModuleMember
   in dot-sourced script?
     │
     ├──[YES]──> ┌──────────────────────────┐
     │           │ BEFORE FIX:              │
     │           │ Suppress error           │
     │           │                          │
     │           │ AFTER FIX:               │
     │           │ This case doesn't occur  │
     │           │ (removed from helpers)   │
     │           └──────────────────────────┘
     │
     v
   Is Unapproved Verb
   Warning?
     │
     ├──[YES]──> [WARNING: Suppress with -WarningAction]
     │
     v
   Unknown Error
     │
     └──> [FATAL: Log full error + stack trace, exit 1]
```

---

## Function Availability Validation

After imports complete, verify critical functions are available:

**Required Module Functions**:
- `Get-NormalizedHash` (HashUtils)
- `Compare-FileHashes` (HashUtils)
- `Get-ExecutionContext` (VSCodeIntegration)
- `Open-VSCodeMerge` (VSCodeIntegration)
- `Get-LatestSpecKitRelease` (GitHubApiClient)
- `Download-SpecKitTemplates` (GitHubApiClient)
- `Get-SpecKitManifest` (ManifestManager)
- `Set-SpecKitManifest` (ManifestManager)
- `New-SpecKitBackup` (BackupManager)
- `Restore-SpecKitBackup` (BackupManager)
- `Get-FileState` (ConflictDetector)
- `Get-FileStateAnalysis` (ConflictDetector)

**Required Helper Functions**:
- `Invoke-PreUpdateValidation`
- `Show-UpdateSummary`
- `Show-UpdateReport`
- `Get-UpdateConfirmation`
- `Invoke-ConflictResolutionWorkflow`
- `Invoke-ThreeWayMerge`
- `Invoke-RollbackWorkflow`

**Validation Logic** (pseudo-code):
```powershell
$missingFunctions = @()
foreach ($func in $requiredFunctions) {
    if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
        $missingFunctions += $func
    }
}

if ($missingFunctions.Count -gt 0) {
    Write-Error "Failed to load required functions: $($missingFunctions -join ', ')"
    exit 1
}
```

---

## Performance Metrics

Track and validate module loading performance:

**Measurement Points**:
- `startTime`: Before module imports begin
- `modulesLoaded`: After all 6 modules imported
- `helpersLoaded`: After all 7 helpers dot-sourced
- `validationComplete`: After function availability check
- `endTime`: Import phase complete

**Metrics**:
- `moduleLoadDuration`: `modulesLoaded - startTime`
- `helperLoadDuration`: `helpersLoaded - modulesLoaded`
- `validationDuration`: `validationComplete - helpersLoaded`
- `totalImportDuration`: `endTime - startTime`

**Success Criteria**:
- `totalImportDuration < 2000ms` (Success Criterion SC-002)
- `moduleLoadDuration < 1500ms` (target: most time spent here)
- `helperLoadDuration < 400ms` (target: helpers are small)
- `validationDuration < 100ms` (target: simple command check)

---

## State Persistence

No persistent state during module loading. All state is ephemeral:

**Not Persisted**:
- Module loading errors (logged to console only)
- Import duration metrics (measured per execution)
- Function availability status (checked at runtime)

**Why**: Module loading is a prerequisite step that must succeed before any persistent operations (manifest updates, file modifications) occur. If imports fail, the script exits immediately with no state changes.

---

## Testing Implications

### Unit Tests

**Test 1: Module Loading Success**
- **Setup**: All 6 modules present with valid syntax, no `Export-ModuleMember` issues
- **Action**: Import all modules
- **Assert**: All modules in `Loaded` state, all expected functions available

**Test 2: Helper Loading Success**
- **Setup**: All 7 helpers present with valid syntax, `Export-ModuleMember` removed
- **Action**: Dot-source all helpers
- **Assert**: All helpers in `Loaded` state, all expected functions available

**Test 3: Real Module Syntax Error (Negative Test)**
- **Setup**: Introduce syntax error in one module file
- **Action**: Attempt import
- **Assert**: Import fails with `Fatal` error, script exits with code 1

**Test 4: Missing Helper File (Negative Test)**
- **Setup**: Remove one helper file
- **Action**: Attempt dot-sourcing
- **Assert**: Dot-source fails with `Fatal` error, script exits with code 1

**Test 5: No Export-ModuleMember in Helpers (Regression Prevention)**
- **Setup**: All helper files
- **Action**: Scan file contents for `Export-ModuleMember`
- **Assert**: No matches found in any `.ps1` file in `scripts/helpers/`

### Integration Tests

**Test 1: Full Orchestrator Execution**
- **Setup**: Complete skill environment
- **Action**: Run `update-orchestrator.ps1 -CheckOnly`
- **Assert**: Imports succeed, orchestrator proceeds to main workflow

**Test 2: Performance Validation**
- **Setup**: Complete skill environment
- **Action**: Measure import duration with `Measure-Command`
- **Assert**: Total import time < 2 seconds

**Test 3: Error Propagation**
- **Setup**: Introduce real error in module after imports (e.g., invalid manifest path)
- **Action**: Run orchestrator
- **Assert**: Error caught and displayed with stack trace (error handling still works)

---

## Migration Path

### Step 1: Remove Export-ModuleMember from Helpers

For each of 7 helper files:
1. Locate `Export-ModuleMember -Function <FunctionName>` line
2. Delete the line entirely
3. Verify function remains defined in script (no other changes needed)

**Example** (`Show-UpdateSummary.ps1`):
```diff
  function Show-UpdateSummary {
      # ... implementation ...
  }

- Export-ModuleMember -Function Show-UpdateSummary
```

### Step 2: Simplify Orchestrator Import Logic

Replace lines 90-136 with simplified version:
```powershell
# ========================================
# MODULE IMPORTS
# ========================================
Write-Verbose "Importing PowerShell modules..."

try {
    $modulesPath = Join-Path $PSScriptRoot "modules"

    # Import modules (suppress unapproved verb warnings only)
    Import-Module (Join-Path $modulesPath "HashUtils.psm1") -Force -WarningAction SilentlyContinue
    Import-Module (Join-Path $modulesPath "VSCodeIntegration.psm1") -Force -WarningAction SilentlyContinue
    Import-Module (Join-Path $modulesPath "GitHubApiClient.psm1") -Force -WarningAction SilentlyContinue
    Import-Module (Join-Path $modulesPath "ManifestManager.psm1") -Force -WarningAction SilentlyContinue
    Import-Module (Join-Path $modulesPath "BackupManager.psm1") -Force -WarningAction SilentlyContinue
    Import-Module (Join-Path $modulesPath "ConflictDetector.psm1") -Force -WarningAction SilentlyContinue

    Write-Verbose "Modules imported successfully"
}
catch {
    Write-Error "Failed to import modules: $($_.Exception.Message)"
    Write-Error $_.ScriptStackTrace
    exit 1
}

# ========================================
# HELPER IMPORTS
# ========================================
Write-Verbose "Loading helper scripts..."

try {
    $helpersPath = Join-Path $PSScriptRoot "helpers"

    . (Join-Path $helpersPath "Invoke-PreUpdateValidation.ps1")
    . (Join-Path $helpersPath "Show-UpdateSummary.ps1")
    . (Join-Path $helpersPath "Show-UpdateReport.ps1")
    . (Join-Path $helpersPath "Get-UpdateConfirmation.ps1")
    . (Join-Path $helpersPath "Invoke-ConflictResolutionWorkflow.ps1")
    . (Join-Path $helpersPath "Invoke-ThreeWayMerge.ps1")
    . (Join-Path $helpersPath "Invoke-RollbackWorkflow.ps1")

    Write-Verbose "Helpers loaded successfully"
}
catch {
    Write-Error "Failed to load helper scripts: $($_.Exception.Message)"
    Write-Error $_.ScriptStackTrace
    exit 1
}

Write-Verbose "All modules and helpers loaded successfully"
```

**Changes**:
- ✅ Removed `$savedErrorPreference` save/restore
- ✅ Removed `-ErrorAction SilentlyContinue` from imports
- ✅ Removed `2>$null` redirection
- ✅ Kept `-WarningAction SilentlyContinue` (unapproved verbs)
- ✅ Added proper try-catch with stack trace logging
- ✅ Added verbose logging for diagnostics

### Step 3: Validate

Run comprehensive tests:
```powershell
# Unit tests
.\tests\test-runner.ps1 -Unit

# Integration tests
.\tests\test-runner.ps1 -Integration

# Manual test
.\scripts\update-orchestrator.ps1 -CheckOnly -Verbose
```

---

## Conclusion

This data model demonstrates that **`Export-ModuleMember` errors are benign** (functions still load), but **suppressing them masks real errors**. The fix removes the source of benign errors (incorrect `Export-ModuleMember` in helpers) and restores proper fail-fast error handling for real errors.

The state transitions show that module imports and dot-sourcing are fundamentally different operations with different scoping rules. Understanding this distinction is key to preventing recurrence.

**Next**: Proceed to `quickstart.md` for step-by-step testing guide.
