# Implementation Plan: Fix Fatal Module Import Error

**Branch**: `003-fix-module-import-error` | **Date**: 2025-10-20 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/003-fix-module-import-error/spec.md`

## Summary

This plan addresses a **recurring architectural issue** causing fatal module import errors. The problem: helper scripts (`.ps1` files) incorrectly use `Export-ModuleMember`, which only works in module files (`.psm1`). The previous fix (PR #1) applied error suppression workarounds, masking the root cause. This fix eliminates the architectural confusion by removing `Export-ModuleMember` from all helper scripts and documenting the pattern to prevent recurrence.

**Key Insight from Ultrathinking**: The issue recurs because the workaround (error suppression) allows the antipattern to persist and propagate. Developers copy `Export-ModuleMember` from existing helpers into new helpers, adding more false-positive errors over time. The proper fix is architectural: establish clear boundaries between modules (import) and helpers (dot-source).

## Technical Context

**Language/Version**: PowerShell 7.0+
**Primary Dependencies**: None (pure PowerShell modules)
**Storage**: File system (`.specify/manifest.json`, backups)
**Testing**: Pester 5.x unit and integration tests
**Target Platform**: Windows 11 (primary), cross-platform PowerShell 7.x
**Project Type**: PowerShell skill (CLI automation tool)
**Performance Goals**: Module import <2 seconds, zero false-positive errors
**Constraints**: Must maintain backward compatibility with existing manifests and backups
**Scale/Scope**: 6 modules, 7 helper scripts, ~2500 LOC total

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Modular Architecture (NON-NEGOTIABLE)

**Status**: ⚠️ VIOLATION DETECTED (to be fixed by this feature)

**Current State**: Helper scripts contain `Export-ModuleMember` calls, creating architectural confusion:
- ✅ Modules correctly use `.psm1` format with `Export-ModuleMember`
- ❌ Helpers incorrectly use `Export-ModuleMember` in `.ps1` files (dot-sourced, not imported)
- ❌ Workaround in orchestrator suppresses resulting errors instead of fixing root cause

**Target State After This Fix**:
- ✅ All modules remain in `.psm1` format with proper `Export-ModuleMember`
- ✅ All helpers remove `Export-ModuleMember` entirely (dot-sourcing doesn't need it)
- ✅ Orchestrator removes error suppression workarounds (no longer needed)
- ✅ Documentation clearly distinguishes module vs. helper patterns

**Justification for Violation**: This is a **FIX** for an existing violation, not introducing a new one. The feature resolves the architectural confusion.

### Principle II: Fail-Fast with Rollback (NON-NEGOTIABLE)

**Status**: ✅ COMPLIANT

This fix does not affect rollback behavior. Module import happens before any file operations, so no rollback changes needed.

### Principle III: Customization Detection via Normalized Hashing

**Status**: ✅ COMPLIANT (N/A)

This fix does not affect hashing logic. No changes to `HashUtils.psm1` required.

### Principle IV: User Confirmation Required

**Status**: ✅ COMPLIANT (N/A)

This fix does not affect user confirmation flow. Module import occurs before user interaction.

### Principle V: Testing Discipline

**Status**: ✅ COMPLIANT

**Plan**:
- Extend existing `tests/unit/UpdateOrchestrator.ModuleImport.Tests.ps1` with additional test cases
- Add integration test verifying clean execution across all command-line parameters
- Add negative test case: verify real module syntax errors still cause fatal errors (not suppressed)

### PowerShell Standards

**Status**: ✅ COMPLIANT

**Changes Required**:
- Remove `Export-ModuleMember` from 7 helper scripts (adheres to dot-sourcing pattern)
- Update `CLAUDE.md` to document the module vs. helper distinction
- No function renames or style changes needed

### Testing Requirements

**Status**: ✅ COMPLIANT

**Test Plan**:
- Unit tests: Verify helpers load without errors after removing `Export-ModuleMember`
- Integration tests: Full orchestrator run with each parameter (`-CheckOnly`, `-Version`, etc.)
- Regression test: Verify modules still work correctly (no accidental exports removed)
- Negative test: Verify real syntax errors in modules/helpers still cause fatal errors

### Gates Summary

| Gate | Status | Action Required |
|------|--------|----------------|
| Modular Architecture | ⚠️ VIOLATION (fixing) | Remove `Export-ModuleMember` from helpers |
| Fail-Fast with Rollback | ✅ PASS | No changes to rollback logic |
| Customization Detection | ✅ PASS | No changes to hashing |
| User Confirmation | ✅ PASS | No changes to confirmation flow |
| Testing Discipline | ✅ PASS | Extend existing test suite |

**Overall Gate Status**: ✅ APPROVED - This feature fixes an existing architectural violation and aligns the codebase with Constitution Principle I.

## Project Structure

### Documentation (this feature)

```
specs/003-fix-module-import-error/
├── spec.md                  # Feature specification (completed)
├── plan.md                  # This file
├── research.md              # Root cause analysis and PowerShell module system research
├── data-model.md            # Module loading flow state model
├── quickstart.md            # Testing guide for this fix
└── checklists/
    └── requirements.md      # Quality validation checklist (completed)
```

### Source Code (repository root)

```
scripts/
├── update-orchestrator.ps1       # [MODIFY] Remove error suppression workarounds (lines 90-136)
├── modules/                      # [NO CHANGE] These correctly use Export-ModuleMember
│   ├── HashUtils.psm1
│   ├── VSCodeIntegration.psm1
│   ├── GitHubApiClient.psm1
│   ├── ManifestManager.psm1
│   ├── BackupManager.psm1
│   └── ConflictDetector.psm1
└── helpers/                      # [MODIFY] Remove Export-ModuleMember from all 7 files
    ├── Invoke-PreUpdateValidation.ps1          # [REMOVE line 180]
    ├── Show-UpdateSummary.ps1                  # [REMOVE line 159]
    ├── Show-UpdateReport.ps1                   # [REMOVE line 170]
    ├── Get-UpdateConfirmation.ps1              # [REMOVE line 136]
    ├── Invoke-ConflictResolutionWorkflow.ps1   # [REMOVE line 216]
    ├── Invoke-ThreeWayMerge.ps1                # [REMOVE line 182]
    └── Invoke-RollbackWorkflow.ps1             # [REMOVE line 196]

tests/
├── unit/
│   └── UpdateOrchestrator.ModuleImport.Tests.ps1   # [EXTEND] Add negative test cases
└── integration/
    └── UpdateOrchestrator.Tests.ps1                # [EXTEND] Test all parameters

docs/
└── bugs/
    └── 001-export-modulemember-fatal-error.md      # [REFERENCE] Original bug report

CLAUDE.md                    # [UPDATE] Document module vs. helper pattern
CHANGELOG.md                 # [UPDATE] Add fix under [Unreleased] → Fixed
```

**Structure Decision**: Single project structure (existing) maintained. No new directories or major refactoring needed. Changes are surgical: remove incorrect `Export-ModuleMember` calls from helpers and simplify orchestrator import logic.

## Complexity Tracking

*No violations that require justification. This feature resolves an existing architectural violation.*

---

## Phase 0: Research

**Output**: [research.md](research.md) - PowerShell module system deep dive and root cause analysis

**Research Questions**:
1. **Why does `Export-ModuleMember` fail in dot-sourced scripts?**
   - Investigate PowerShell's module context detection
   - Document the difference between `Import-Module` (module scope) and dot-sourcing (current scope)

2. **What are the best practices for PowerShell module/helper organization?**
   - Research official Microsoft documentation on module structure
   - Identify patterns from mature PowerShell projects (PSReadLine, Pester, etc.)

3. **Why did the workaround (error suppression) succeed initially?**
   - Analyze the interaction between `$ErrorActionPreference`, `-ErrorAction`, and `2>$null`
   - Understand why modules still loaded despite errors

4. **How can we prevent this pattern from recurring?**
   - Document clear guidelines in `CLAUDE.md`
   - Consider Pester tests that verify no `Export-ModuleMember` in `.ps1` files

**Dispatch Research Tasks**: Generate `research.md` consolidating findings from PowerShell documentation, bug report analysis, and code review.

---

## Phase 1: Design & Contracts

**Prerequisites**: `research.md` complete

### Design Artifacts

**Output 1**: [data-model.md](data-model.md) - Module loading flow state model

Define the state transitions for module/helper loading:
- **Module Import**: `Import-Module .psm1 → Module Scope → Export-ModuleMember → Functions Available`
- **Helper Dot-Source**: `. script.ps1 → Current Scope → Functions Available (no export needed)`
- **Error States**: Real syntax error vs. benign `Export-ModuleMember` error

**Output 2**: [quickstart.md](quickstart.md) - Testing guide

Provide step-by-step testing instructions:
1. Test module import succeeds without errors
2. Test all command-line parameters work correctly
3. Test that real syntax errors still cause fatal errors (not suppressed)
4. Verify verbose logging provides useful diagnostics

**Output 3**: No contracts needed - This is an internal refactoring, no API changes

### Agent Context Update

**Script**: `.specify/scripts/powershell/update-agent-context.ps1 -AgentType claude`

**Technology to Add**:
- PowerShell 7.x module system (Import-Module vs. dot-sourcing)
- Pester 5.x testing framework
- `$ErrorActionPreference` behavior

**Preserve**: Existing agent context about SpecKit integration, GitHub API client, manifest structure

---

## Phase 2: Task Generation

**IMPORTANT**: This phase is executed by `/speckit.tasks`, NOT by `/speckit.plan`.

This planning document provides the foundation for task generation. The `/speckit.tasks` command will use `spec.md`, `plan.md`, `research.md`, `data-model.md`, and `quickstart.md` to generate a detailed, dependency-ordered `tasks.md`.

---

## Implementation Notes

### Files to Modify (8 total)

1. **scripts/helpers/** (7 files) - Remove `Export-ModuleMember` line from each:
   - `Invoke-PreUpdateValidation.ps1` (line 180)
   - `Show-UpdateSummary.ps1` (line 159)
   - `Show-UpdateReport.ps1` (line 170)
   - `Get-UpdateConfirmation.ps1` (line 136)
   - `Invoke-ConflictResolutionWorkflow.ps1` (line 216)
   - `Invoke-ThreeWayMerge.ps1` (line 182)
   - `Invoke-RollbackWorkflow.ps1` (line 196)

2. **scripts/update-orchestrator.ps1** - Simplify import logic (lines 90-136):
   - Remove `$savedErrorPreference` save/restore pattern
   - Remove `-ErrorAction SilentlyContinue` from `Import-Module` calls
   - Remove `2>$null` redirection from helper dot-sourcing
   - Keep `-WarningAction SilentlyContinue` only for unapproved verb warnings (separate issue)
   - Simplify to standard import pattern with single try-catch for real errors

### Testing Strategy

**Unit Tests** (`tests/unit/UpdateOrchestrator.ModuleImport.Tests.ps1`):
- ✅ Modules load without errors
- ✅ Helpers load without errors
- ✅ All exported functions are available
- 🆕 **NEW**: Verify no `Export-ModuleMember` in any `.ps1` helper file (prevent regression)
- 🆕 **NEW**: Real syntax error in module causes fatal error (not suppressed)

**Integration Tests** (`tests/integration/UpdateOrchestrator.Tests.ps1`):
- ✅ Full orchestrator execution with `-CheckOnly`
- 🆕 **NEW**: Test all parameters: `-Version`, `-Force`, `-Rollback`, `-NoBackup`
- 🆕 **NEW**: Verify zero false-positive errors in output
- 🆕 **NEW**: Verify verbose mode shows module import diagnostics

### Performance Validation

- Current import time: ~380ms (with workarounds)
- Target import time: <2 seconds (Success Criteria SC-002)
- Expected: No performance change (removing `Export-ModuleMember` from helpers should not affect timing)

### Documentation Updates

**CLAUDE.md** - Add section under "Architecture":
```markdown
## Module vs. Helper Pattern

**Modules** (`.psm1` files):
- Imported with `Import-Module`
- Run in their own module scope
- MUST use `Export-ModuleMember` to export functions
- Example: `HashUtils.psm1`, `ManifestManager.psm1`

**Helpers** (`.ps1` files):
- Dot-sourced with `. script.ps1`
- Run in the caller's current scope
- MUST NOT use `Export-ModuleMember` (causes errors)
- Functions are automatically available after dot-sourcing
- Example: `Show-UpdateSummary.ps1`, `Get-UpdateConfirmation.ps1`

**Why This Matters**: `Export-ModuleMember` only works inside PowerShell module scope. Using it in dot-sourced scripts causes "Export-ModuleMember cmdlet can only be called from inside a module" errors.
```

**CHANGELOG.md** - Add under `[Unreleased]` → `Fixed`:
```markdown
- **BREAKING FIX**: Removed `Export-ModuleMember` from all helper scripts, eliminating recurring module import errors (#3)
  - Previous fix (#1) used error suppression workarounds, masking the root architectural issue
  - Helpers are dot-sourced (not imported), so `Export-ModuleMember` is incorrect and causes false errors
  - Simplified orchestrator import logic - no longer needs error suppression
  - Added documentation distinguishing module vs. helper patterns to prevent recurrence
```

---

## Success Criteria Validation

From [spec.md](spec.md), verify each success criterion:

- **SC-001**: Skill executes successfully 100% of the time → ✅ Test with all parameters
- **SC-002**: Module import completes in <2 seconds → ✅ Measure with `Measure-Command`
- **SC-003**: Zero false-positive errors in normal output → ✅ Verify no `Export-ModuleMember` errors
- **SC-004**: All parameters function correctly → ✅ Integration tests for each flag
- **SC-005**: Works across different PowerShell hosts → ✅ Test in pwsh.exe and VSCode terminal
- **SC-006**: Real errors produce clear messages with stack traces → ✅ Negative test with syntax error
- **SC-007**: Verbose mode provides diagnostic information → ✅ Test `-Verbose` flag output

---

## Risk Assessment

### Low Risk
- **Change Scope**: Removing 7 lines of code (one `Export-ModuleMember` per helper)
- **Backward Compatibility**: No API changes - helpers remain dot-sourced with same function names
- **Rollback**: Git revert is trivial if issues arise

### Testing Mitigation
- Comprehensive unit tests verify helpers still load correctly
- Integration tests verify end-to-end functionality preserved
- Negative tests ensure real errors still caught

### Documentation Mitigation
- Clear documentation prevents pattern from recurring
- Pester test can enforce "no `Export-ModuleMember` in `.ps1` files" rule

---

## Next Steps

1. Execute `/speckit.tasks` to generate detailed implementation tasks from this plan
2. Implement tasks in dependency order
3. Run full test suite (`./tests/test-runner.ps1`) before committing
4. Create PR with reference to original bug report (#1) and this spec (#3)

---

**Status**: Ready for Phase 0 (Research) and Phase 1 (Design)
