# Data Model: Fix False Constitution Update Notification

**Feature**: 009-fix-constitution-notification
**Date**: 2025-10-22
**Purpose**: Document data structures used in hash verification and notification logic

## Overview

This bug fix introduces minimal new data structures, primarily using in-memory variables within Step 12 scope. No persistent state or new entities are added to the manifest or file system.

## In-Memory Data Structures

### Hash Comparison State

**Scope**: Local to Step 12 (lines 677-707 of update-orchestrator.ps1)
**Lifetime**: Created at start of Step 12, discarded at end
**Purpose**: Store hash computation results and change detection flag

#### Variables

```powershell
# File paths
[string]$constitutionPath           # Current constitution file path
[string]$backupConstitutionPath     # Backup constitution file path

# Hash values
[string]$currentHash                # Normalized hash of current file (format: "sha256:HEX")
[string]$backupHash                 # Normalized hash of backup file (format: "sha256:HEX")

# Change detection
[bool]$actualChangeDetected         # True if hashes differ, false if identical

# Error tracking (optional, for verbose logging)
[bool]$hashComparisonError          # True if exception occurred during hash computation
```

#### State Transitions

```
Initial State: Variables uninitialized
    ↓
Check if constitution marked as updated/conflicted
    ↓ Yes
Construct file paths (Join-Path)
    ↓
Check if files exist (Test-Path)
    ↓ Both exist
Compute hashes (Get-NormalizedHash)
    ↓ Success
Compare hashes (string equality)
    ↓
Set $actualChangeDetected = ($currentHash -ne $backupHash)
    ↓
Display notification if $actualChangeDetected = true
    ↓
End of Step 12: Variables discarded
```

#### Edge Case Handling

| Condition | $actualChangeDetected Value | Rationale |
|-----------|----------------------------|-----------|
| Backup file missing | `true` | Fail-safe: show notification |
| Current file missing | `false` | Nothing to notify about |
| Hash computation throws exception | `true` | Fail-safe: show notification |
| Hashes identical | `false` | No real change, suppress notification |
| Hashes differ | `true` | Real change detected, show notification |

### Notification Context

**Scope**: Local to Step 12, within the `if ($actualChangeDetected)` block
**Lifetime**: Ephemeral (used immediately for Write-Host calls)
**Purpose**: Determine notification style (emoji, colors, wording)

#### Derivation Logic

```powershell
# Determine notification type
$constitutionConflict = $updateResult.ConflictsResolved -contains '.specify/memory/constitution.md'

if ($constitutionConflict) {
    # REQUIRED action notification (conflict detected)
    $emojiIcon = "⚠️"
    $primaryColor = "Red"
    $secondaryColor = "Yellow"
    $actionLabel = "REQUIRED"
    $actionVerb = "Run the following command"
} else {
    # OPTIONAL review notification (clean update)
    $emojiIcon = "ℹ️"
    $primaryColor = "Cyan"
    $secondaryColor = "Gray"
    $actionLabel = "OPTIONAL"
    $actionVerb = "Review changes by running"
}
```

#### Output Format

```powershell
# Conflict notification example
Write-Host "`n$emojiIcon  Constitution Conflict Detected" -ForegroundColor $primaryColor
Write-Host "The constitution has conflicts requiring manual resolution." -ForegroundColor $secondaryColor
Write-Host "$actionLabel: $actionVerb:" -ForegroundColor $secondaryColor
Write-Host "  /speckit.constitution $backupConstitutionPath" -ForegroundColor White

# Clean update notification example
Write-Host "`n$emojiIcon  Constitution Template Updated" -ForegroundColor $primaryColor
Write-Host "The constitution template was cleanly updated (no conflicts)." -ForegroundColor $secondaryColor
Write-Host "$actionLabel: $actionVerb:" -ForegroundColor $secondaryColor
Write-Host "  /speckit.constitution $backupConstitutionPath" -ForegroundColor White
```

## Existing Data Structures (No Modifications)

### $updateResult Object

**Defined in**: Step 4 of orchestrator
**Properties Used by Step 12**:
- `FilesUpdated` (array of strings) - File paths marked as updated
- `ConflictsResolved` (array of strings) - File paths with resolved conflicts
- `ConstitutionUpdateNeeded` (boolean) - Set by Step 12, read by Step 15

**Modification**: Step 12 sets `$updateResult.ConstitutionUpdateNeeded = $true` only when `$actualChangeDetected = true`

### Manifest Schema (No Changes)

**File**: `.specify/manifest.json`
**Relevant Fields**:
- `tracked_files[].path` - File paths for hash lookup (not used by this fix)
- `tracked_files[].original_hash` - Hash values (not used by this fix)

**Note**: This bug fix does NOT modify manifest structure. It only uses runtime hash computation for verification.

## Data Flow Diagram

```
Step 8: Create Backup
    ↓ (creates $backupPath)
    ↓
Step 10: Apply Updates
    ↓ (populates $updateResult.FilesUpdated)
    ↓
Step 11: Resolve Conflicts
    ↓ (populates $updateResult.ConflictsResolved)
    ↓
Step 12: Constitution Notification (MODIFIED)
    ↓
    Check if constitution in arrays? ──→ No ──→ Skip notification
    ↓ Yes
    ↓
    Construct file paths
    ↓
    Test-Path (both files exist)? ──→ No (backup missing) ──→ Set actualChangeDetected = true (fail-safe)
    ↓ Yes
    ↓
    Get-NormalizedHash (current)
    Get-NormalizedHash (backup)
    ↓
    Compare hashes ──→ Identical ──→ Set actualChangeDetected = false
    ↓ Different
    ↓
    Set actualChangeDetected = true
    ↓
    Determine notification type (conflict vs. clean_update)
    ↓
    Display notification with emoji/colors
    ↓
    Set $updateResult.ConstitutionUpdateNeeded = true
    ↓
Step 15: Display Summary
```

## Validation Rules

### Hash Comparison Validation

```powershell
# Validate hash format (defensive programming, optional)
if ($currentHash -notmatch '^sha256:[0-9a-f]{64}$') {
    Write-Verbose "Invalid hash format from Get-NormalizedHash: $currentHash"
    $actualChangeDetected = $true  # Fail-safe
}

# Validate hash inequality check
if ($currentHash -eq $backupHash) {
    $actualChangeDetected = $false
} else {
    $actualChangeDetected = $true
}
```

### File Path Validation

```powershell
# Ensure paths are absolute (Get-NormalizedHash may require absolute paths)
$constitutionPath = Join-Path $projectRoot '.specify/memory/constitution.md'
$constitutionPath = [System.IO.Path]::GetFullPath($constitutionPath)

# Validate existence before hash computation
if (-not (Test-Path $constitutionPath)) {
    Write-Verbose "Constitution file not found: $constitutionPath"
    # Don't set actualChangeDetected = true (nothing to notify about)
}
```

## Performance Considerations

### Memory Usage

- **Hash strings**: ~80 bytes each (`"sha256:"` + 64 hex chars)
- **File path strings**: ~200 bytes each (typical Windows path length)
- **Total Step 12 memory overhead**: <1 KB (negligible)

### Computational Complexity

- **Get-NormalizedHash**: O(n) where n = file size (~50KB → 10-30ms)
- **String comparison**: O(1) (<1ms for 64-character hex string)
- **Test-Path**: O(1) (file system metadata lookup, <5ms)
- **Total Step 12 time complexity**: O(n) but bounded by 100ms target

### Optimization Opportunities (Future)

1. **Cache hashes in memory**: If Step 12 runs multiple times in same session (unlikely)
2. **Parallel hash computation**: Compute current and backup hashes concurrently (minimal benefit for single file)
3. **Early exit**: Skip hash computation if neither FilesUpdated nor ConflictsResolved contain constitution (already implemented)

## Testing Data Requirements

### Unit Test Fixtures (Not Applicable)

This fix does not introduce new functions requiring unit tests. It modifies existing orchestrator logic tested via integration tests.

### Integration Test Scenarios

**Test Case 1**: Constitution marked updated, hashes identical
- **Setup**: Mock Get-NormalizedHash to return identical hash for both paths
- **Expected**: No notification displayed, `ConstitutionUpdateNeeded = false`

**Test Case 2**: Constitution cleanly updated, hashes differ
- **Setup**: Mock Get-NormalizedHash to return different hashes
- **Expected**: ℹ️ notification with "OPTIONAL" label

**Test Case 3**: Constitution conflict, hashes differ
- **Setup**: Mock ConflictsResolved array to contain constitution, different hashes
- **Expected**: ⚠️ notification with "REQUIRED" label

**Test Case 4**: Backup file missing, fail-safe behavior
- **Setup**: Mock Test-Path to return $false for backup path
- **Expected**: Notification displayed (fail-safe)

## Summary

This bug fix introduces **no persistent data structures** and minimal in-memory state. All new variables are local to Step 12 with lifetimes measured in milliseconds. The implementation is stateless, idempotent, and aligns with the existing orchestrator's functional programming style.

**No schema changes, no new files, no database migrations required.**
