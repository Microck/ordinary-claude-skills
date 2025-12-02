# Implementation Plan: Fix False Constitution Update Notification

**Branch**: `009-fix-constitution-notification` | **Date**: 2025-10-22 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/009-fix-constitution-notification/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

This bug fix addresses false positive constitution update notifications that confuse users and undermine trust in the tool. The core issue is that Step 12 of the update orchestrator displays notifications whenever `constitution.md` appears in the `FilesUpdated` or `ConflictsResolved` arrays, without verifying whether the file content actually changed.

**Technical Approach**: Add hash verification using the existing `Get-NormalizedHash` function to compare backup and current constitution files before displaying notifications. Differentiate notification styles using emoji/icons (⚠️ for conflicts requiring action, ℹ️ for optional updates) combined with color schemes for accessibility. Implement structured key-value logging format for debugging.

**Impact**: 100% elimination of false positives, <100ms performance overhead, improved accessibility, and clearer user guidance.

## Technical Context

**Language/Version**: PowerShell 7.x (Windows 11)
**Primary Dependencies**:
- Existing modules: HashUtils.psm1 (Get-NormalizedHash), ManifestManager.psm1
- PowerShell built-in cmdlets: Write-Host, Write-Verbose, Test-Path, Join-Path
- Git (for version control)

**Storage**: File-based (.specify/manifest.json, .specify/memory/constitution.md, .specify/backups/)
**Testing**: Pester 5.x (unit tests and integration tests)
**Target Platform**: Windows 11 (PowerShell 7+ subprocess, Claude Code execution context)
**Project Type**: PowerShell skill (CLI tool)
**Performance Goals**: Hash verification <100ms, total Step 12 processing <200ms
**Constraints**:
- Text-only I/O (no GUI, no VSCode extension APIs)
- Must maintain fail-safe behavior (show notification on error)
- Must preserve existing orchestrator workflow (Step 12 position)

**Scale/Scope**:
- Single file modification: scripts/update-orchestrator.ps1 (Step 12, lines 677-707)
- Test additions: 9 integration test cases in tests/integration/UpdateOrchestrator.Tests.ps1
- Documentation updates: CLAUDE.md, CHANGELOG.md

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Modular Architecture ✅ PASS

**Compliant**: This bug fix uses the existing `Get-NormalizedHash` function from HashUtils.psm1. All business logic (hash computation, normalization) remains in the module. The orchestrator only orchestrates: calls the function, compares results, and displays output.

**No new modules required**: The existing HashUtils.psm1 provides all necessary functionality.

### II. Fail-Fast with Rollback ✅ PASS

**Compliant**: This change only affects Step 12 (notification display), which occurs AFTER all file operations and manifest updates complete. No rollback logic is affected. The fail-safe behavior is preserved: if hash comparison fails (exception thrown), the system defaults to showing the notification (safe default).

**Error handling**: Added try-catch around hash comparison with verbose error logging and fail-safe fallback.

### III. Customization Detection via Normalized Hashing ✅ PASS

**Compliant**: This fix explicitly uses `Get-NormalizedHash` for hash comparison, which implements the required normalization rules (CRLF→LF, trim whitespace, remove BOM, SHA-256).

**Benefit**: This fix addresses a bug where normalization issues may have caused false positives. Using normalized hashing ensures constitution files marked as "updated" are truly changed.

### IV. User Confirmation Required ✅ PASS (Not Applicable)

**Not Applicable**: This change only affects notification display after the update completes. User confirmation already occurred in Step 7 (before any file modifications). This change does not introduce new destructive operations requiring confirmation.

### V. Testing Discipline ✅ PASS

**Compliant**: Nine integration test cases will be added to `tests/integration/UpdateOrchestrator.Tests.ps1`:
1. Constitution marked updated but hashes identical → no notification
2. Constitution marked updated but backup missing → notification shown (fail-safe)
3. Fresh install scenario (v0.0.0 to v0.0.78) with identical content → no notification
4. Constitution cleanly updated with differing hashes → ℹ️ informational notification
5. Clean update notification includes backup path parameter
6. Verbose logging shows structured key-value format
7. Constitution conflict with differing hashes → ⚠️ urgent notification
8. Constitution conflict but hashes match → no notification (prevents false positive)
9. Get-NormalizedHash throws exception → verbose error logged and notification shown (fail-safe)

**Test Strategy**: Integration tests will mock file system, manifest data, and hash functions to verify notification logic without requiring actual SpecKit projects.

### VI. Architectural Verification Before Suggestions ✅ PASS

**Text-Only I/O Compliant**: This solution respects the text-only I/O constraint:
- ✅ Uses Write-Host for colored terminal output (stdout)
- ✅ Uses Write-Verbose for structured logging (stdout)
- ✅ Does not attempt GUI, VSCode APIs, or IPC
- ✅ Emoji/icons (⚠️, ℹ️) are text characters displayable in any terminal

**No architectural violations**: The approach is compatible with PowerShell subprocess execution model used by Claude Code.

### Constitution Summary

**Result**: ✅ ALL GATES PASSED

No constitution violations. This is a low-risk bug fix that enhances existing functionality while respecting all architectural constraints.

## Project Structure

### Documentation (this feature)

```
specs/009-fix-constitution-notification/
├── spec.md              # Feature specification (completed)
├── plan.md              # This file (current)
├── research.md          # Phase 0 output (minimal - see below)
├── data-model.md        # Phase 1 output (minimal - see below)
├── quickstart.md        # Phase 1 output
├── checklists/
│   └── requirements.md  # Specification quality checklist (completed)
└── tasks.md             # Phase 2 output (created by /speckit.tasks command)
```

### Source Code (repository root)

```
scripts/
├── update-orchestrator.ps1          # PRIMARY MODIFICATION: Step 12 (lines 677-707)
├── modules/
│   ├── HashUtils.psm1               # EXISTING: Provides Get-NormalizedHash (no changes)
│   └── ManifestManager.psm1         # EXISTING: Provides manifest operations (no changes)
└── helpers/
    └── (no changes to helpers)

tests/
├── unit/
│   ├── HashUtils.Tests.ps1          # EXISTING: No changes needed (Get-NormalizedHash already tested)
│   └── ManifestManager.Tests.ps1    # EXISTING: No changes needed
└── integration/
    └── UpdateOrchestrator.Tests.ps1 # MODIFIED: Add 9 integration test cases for constitution notification

docs/
├── CLAUDE.md                        # MODIFIED: Update "Constitution Update Notification" section
└── bugs/
    └── 007-false-constitution-update-notification.md  # EXISTING: Bug report (reference)

CHANGELOG.md                         # MODIFIED: Add entry under "Fixed" section
```

**Structure Decision**: Single-project PowerShell skill using existing modular architecture. All changes confined to orchestrator script (Step 12) and integration tests. No new modules or helpers required.

## Complexity Tracking

*No constitution violations - this section is empty.*

## Phase 0: Research

Since this is a bug fix to existing, well-understood code with a clear solution path, research requirements are minimal.

### Research Questions

**Q1: Current Step 12 Implementation**
- **Objective**: Understand existing notification logic and integration points
- **Method**: Read scripts/update-orchestrator.ps1 lines 677-707
- **Deliverable**: Document current control flow, variables used, and notification format

**Q2: Get-NormalizedHash Function Signature**
- **Objective**: Verify function parameters and return format for hash comparison
- **Method**: Read scripts/modules/HashUtils.psm1, review existing unit tests
- **Deliverable**: Document function signature, expected inputs/outputs, error behavior

**Q3: Emoji/Icon Support in PowerShell**
- **Objective**: Verify PowerShell 7+ and Windows Terminal support UTF-8 emoji characters
- **Method**: Test `Write-Host "⚠️ Test"` and `Write-Host "ℹ️ Test"` in pwsh.exe
- **Deliverable**: Confirm emoji rendering, document any encoding requirements (UTF-8 BOM handling)

**Q4: Write-Verbose Structured Logging Pattern**
- **Objective**: Define key-value format for structured logging (timestamp, file paths, hashes)
- **Method**: Review existing verbose logging in orchestrator, check PowerShell best practices
- **Deliverable**: Document logging format template (e.g., "Key1=Value1; Key2=Value2; Key3=Value3")

**Q5: Backup Path Construction**
- **Objective**: Understand how $backupPath variable is set and used in Step 12
- **Method**: Trace $backupPath from Step 8 (backup creation) to Step 12
- **Deliverable**: Document backup path structure and availability guarantees

### Research Output Location

All research findings will be documented in [research.md](research.md) with the following structure:

```markdown
# Research: Fix False Constitution Update Notification

## R1: Current Step 12 Implementation
[Analysis of existing code...]

## R2: Get-NormalizedHash Function
[Function signature, parameters, return format...]

## R3: Emoji Support in PowerShell
[Testing results, encoding notes...]

## R4: Structured Logging Format
[Key-value template, examples...]

## R5: Backup Path Construction
[Path structure, availability analysis...]
```

## Phase 1: Design

### Data Model

This feature involves minimal data modeling since it modifies existing orchestrator logic. The following data structures are relevant:

**File**: [data-model.md](data-model.md)

#### Entity: Hash Comparison State (in-memory, Step 12 scope)

**Description**: Temporary state used during Step 12 to verify whether constitution file has actually changed.

**Attributes**:
- `constitutionPath` (string): Absolute path to current constitution file (`.specify/memory/constitution.md`)
- `backupConstitutionPath` (string): Absolute path to backup constitution file (`$backupPath/.specify/memory/constitution.md`)
- `currentHash` (string): Normalized SHA-256 hash of current constitution (format: `sha256:HEXSTRING`)
- `backupHash` (string): Normalized SHA-256 hash of backup constitution (format: `sha256:HEXSTRING`)
- `actualChangeDetected` (boolean): True if currentHash ≠ backupHash, false if identical
- `hashComparisonError` (boolean): True if hash computation threw exception, false if successful

**Lifecycle**: Created at start of Step 12, discarded at end of Step 12 (no persistence)

**Validation Rules**:
- If backup file doesn't exist, set `actualChangeDetected = true` (fail-safe)
- If hash computation throws exception, set `hashComparisonError = true` and `actualChangeDetected = true` (fail-safe)
- Log hash comparison details to Write-Verbose for debugging

#### Entity: Notification Context (in-memory, Step 12 scope)

**Description**: Information needed to format and display notification message to user.

**Attributes**:
- `notificationType` (enum): "conflict" or "clean_update"
- `severityLevel` (enum): "required" or "optional"
- `emojiIcon` (string): "⚠️" (conflict) or "ℹ️" (clean update)
- `colorScheme` (object):
  - `primaryColor` (string): "Red" (conflict) or "Cyan" (clean update)
  - `secondaryColor` (string): "Yellow" (conflict) or "Gray" (clean update)
- `backupPath` (string): Path to backup constitution for user reference

**Derivation Rules**:
- If `constitutionConflict = true` → notificationType="conflict", severityLevel="required", emojiIcon="⚠️", primaryColor="Red"
- If `constitutionUpdated = true` (and not conflict) → notificationType="clean_update", severityLevel="optional", emojiIcon="ℹ️", primaryColor="Cyan"

### API Contracts

**Not Applicable**: This is an internal PowerShell script modification with no external APIs or public interfaces. The orchestrator is invoked via CLI parameters by Claude Code.

**Internal Interface Changes**: None. Step 12 uses existing functions (`Get-NormalizedHash`, `Test-Path`, `Join-Path`, `Write-Host`, `Write-Verbose`) without modification.

### Quickstart Guide

**File**: [quickstart.md](quickstart.md)

This document provides a quick reference for developers testing or modifying the constitution notification logic.

```markdown
# Quickstart: Constitution Notification Bug Fix

## Testing the Fix Locally

### Prerequisites
- PowerShell 7+
- Git repository with .specify/ directory
- Test SpecKit project (or use existing project)

### Manual Testing Steps

1. **Create test scenario with false positive**:
   ```powershell
   # Create a backup with identical constitution
   $backupPath = ".specify/backups/test-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
   New-Item -ItemType Directory -Path $backupPath/.specify/memory -Force
   Copy-Item .specify/memory/constitution.md $backupPath/.specify/memory/constitution.md
   ```

2. **Run orchestrator with verbose logging**:
   ```powershell
   & .\scripts\update-orchestrator.ps1 -CheckOnly -Verbose
   ```

3. **Verify no notification shown** (expected: hashes match, no output)

4. **Create test scenario with real change**:
   ```powershell
   # Modify constitution in backup to simulate upstream change
   Add-Content $backupPath/.specify/memory/constitution.md "`n# Test change"
   ```

5. **Run orchestrator again**:
   ```powershell
   & .\scripts\update-orchestrator.ps1 -CheckOnly -Verbose
   ```

6. **Verify informational notification shown** (expected: ℹ️ icon, cyan/gray colors, "OPTIONAL" label)

### Running Automated Tests

```powershell
# Run all tests
.\tests\test-runner.ps1

# Run only integration tests
.\tests\test-runner.ps1 -Integration

# Run with verbose output
.\tests\test-runner.ps1 -Integration -Verbose
```

### Debugging Tips

**Enable verbose logging** to see hash comparison details:
```powershell
$VerbosePreference = 'Continue'
& .\scripts\update-orchestrator.ps1 -CheckOnly
```

**Expected verbose output**:
```
VERBOSE: Step 12: Checking for constitution updates...
VERBOSE: Constitution hash comparison:
VERBOSE:   CurrentPath=C:\...\\.specify\memory\constitution.md
VERBOSE:   BackupPath=C:\...\\.specify\backups\20251022-080753\\.specify\memory\constitution.md
VERBOSE:   CurrentHash=sha256:abc123...
VERBOSE:   BackupHash=sha256:abc123...
VERBOSE:   Changed=False
VERBOSE: Constitution marked as updated but content unchanged - skipping notification
```

### Common Issues

**Issue**: Emoji not displaying correctly
- **Solution**: Ensure terminal supports UTF-8. In Windows Terminal, check Settings → Profiles → Advanced → Text Rendering

**Issue**: Hashes always different despite identical files
- **Solution**: Check for line ending differences. Get-NormalizedHash should handle this, but verify with:
  ```powershell
  Get-Content file.md -Raw | % { $_ -replace "`r`n", "`n" } | Set-Content file.md -NoNewline
  ```

**Issue**: Test-Path returns false for backup constitution
- **Solution**: Verify backup was created in Step 8. Check $backupPath variable value with Write-Verbose.
```

## Phase 2: Task Planning

**Note**: Task planning is handled by the `/speckit.tasks` command, which generates `tasks.md`. This section documents the high-level implementation phases.

### Implementation Phases

**Phase A: Modify Orchestrator Step 12** (1-2 hours)
- Read current Step 12 implementation (lines 677-707)
- Add hash verification logic with try-catch error handling
- Update notification conditionals (only display if actualChangeDetected = true)
- Add structured verbose logging with key-value format
- Update notification messages with emoji/icons and differentiated wording

**Phase B: Add Integration Tests** (1-2 hours)
- Add test case: Constitution marked updated but identical hashes
- Add test case: Constitution cleanly updated with differing hashes
- Add test case: Constitution conflict with differing hashes
- Add test case: Constitution conflict but identical hashes (edge case)

**Phase C: Update Documentation** (30 minutes)
- Update CLAUDE.md "Constitution Update Notification" section
- Add entry to CHANGELOG.md under "Fixed"
- Verify CONTRIBUTING.md mentions running tests before committing

**Phase D: Manual Testing & Validation** (1 hour)
- Test with real SpecKit project (v0.0.0 → latest)
- Verify emoji rendering in Windows Terminal and PowerShell 7
- Verify verbose logging format
- Verify fail-safe behavior (delete backup, ensure notification still shows)
- Performance check (Step 12 processing time < 200ms)

### Success Criteria Validation

Each success criterion from the spec will be validated:

- **SC-001** (100% false positive elimination): Integration test verifies no notification when hashes match
- **SC-002** (100% real change detection): Integration test verifies notification when hashes differ
- **SC-003** (3-second user comprehension): Manual UX testing with emoji/icon labels
- **SC-004** (<100ms performance): Manual timing measurement of hash verification
- **SC-005** (95% user understanding): Post-release user feedback survey (deferred)
- **SC-006** (80% support reduction): Post-release metrics tracking (deferred)

## Risks & Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Emoji not rendering in all terminals | Medium | Low | Fallback: Use [!] and [i] text brackets if emoji support detection possible |
| Hash comparison performance exceeds 100ms target | Low | Very Low | Get-NormalizedHash is already optimized, constitution files typically <50KB |
| Backup path not available at Step 12 | High | Very Low | Fail-safe: Default to showing notification (existing behavior preserved) |
| False negatives (real changes not detected) | High | Very Low | Normalized hashing eliminates line-ending false negatives, SHA-256 collision rate negligible |

## Dependencies

### Internal Dependencies
- ✅ HashUtils.psm1 - Provides Get-NormalizedHash (already exists, no modifications needed)
- ✅ ManifestManager.psm1 - Provides manifest operations (already exists, no modifications needed)
- ✅ Backup creation (Step 8) - Must complete before Step 12 (already enforced in orchestrator)

### External Dependencies
- ✅ PowerShell 7+ - Already required by skill
- ✅ Windows Terminal or compatible UTF-8 terminal - Already recommended for Claude Code users
- ✅ Git - Already required by skill for version control

**No new dependencies introduced.**

## Post-Implementation Validation

After `/speckit.implement` completes, validate:

1. **Functional Correctness**:
   - [ ] All integration tests pass
   - [ ] Manual testing confirms false positives eliminated
   - [ ] Emoji/icons display correctly in Windows Terminal
   - [ ] Verbose logging shows structured key-value format

2. **Performance**:
   - [ ] Step 12 processing time < 200ms (measure with Measure-Command)
   - [ ] Hash verification < 100ms (measure within Step 12)

3. **Code Quality**:
   - [ ] No PowerShell linting warnings (`PSScriptAnalyzer`)
   - [ ] Comment-based help updated if needed
   - [ ] Error handling covers all edge cases (backup missing, hash error)

4. **Documentation**:
   - [ ] CLAUDE.md updated with new notification behavior
   - [ ] CHANGELOG.md entry added under "Fixed"
   - [ ] No outdated references to old notification behavior

5. **Accessibility**:
   - [ ] Color schemes meet contrast requirements (red/yellow, cyan/gray)
   - [ ] Emoji/icons provide visual distinction beyond color alone
   - [ ] "REQUIRED" and "OPTIONAL" text labels clearly visible

## Next Steps

1. **Run `/speckit.tasks`** to generate detailed task breakdown in `tasks.md`
2. **Begin Phase A implementation** (orchestrator modification)
3. **Run tests incrementally** after each phase
4. **Submit PR** with all changes (code + tests + docs)
5. **Validate with real-world project** before merging to main

---

**Plan Status**: ✅ Complete and ready for task generation
**Estimated Total Effort**: 4-6 hours (dev + test + docs)
**Risk Level**: Low (isolated bug fix with clear solution)
