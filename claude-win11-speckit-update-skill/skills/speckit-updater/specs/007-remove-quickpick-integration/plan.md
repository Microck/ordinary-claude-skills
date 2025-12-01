# Implementation Plan: Remove VSCode QuickPick Integration

**Branch**: `007-remove-quickpick-integration` | **Date**: 2025-10-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/007-remove-quickpick-integration/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Remove the non-functional `Show-QuickPick` function from VSCodeIntegration.psm1 and replace interactive prompt workflows with a conversational approval pattern where the skill outputs summary text for Claude to present, user approves via chat, and Claude passes confirmation to the skill. Implement Git-style conflict markers as the primary conflict resolution mechanism, eliminating dependency on `code --merge` external process invocation.

**Key Technical Changes**:
- Remove `Show-QuickPick` function (lines 55-143) from VSCodeIntegration.psm1
- Remove `-Auto` flag from update-orchestrator.ps1
- Replace Read-Host prompts with summary text output + approval parameter
- Implement Git conflict marker writer for merge conflicts
- Update documentation to reflect text-only I/O constraint

## Technical Context

**Language/Version**: PowerShell 7+ (existing project standard)
**Primary Dependencies**: None (removing code, not adding dependencies)
**Storage**: File system (`.specify/manifest.json`, conflict markers in `.md` files)
**Testing**: Pester 5.x (existing test framework)
**Target Platform**: Windows 11, Claude Code (VSCode Extension + CLI)
**Project Type**: Single project (PowerShell skill)
**Performance Goals**: Summary output < 2s, approval workflow < 5s end-to-end
**Constraints**: Text-only I/O (stdout/stderr); no GUI or IPC with VSCode extension host
**Scale/Scope**: ~150 LOC removal, ~50 LOC additions (conflict markers), 3 modules affected, 15 tests affected

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Modular Architecture ✅ PASS

**Compliance**:
- VSCodeIntegration.psm1 remains self-contained after removing Show-QuickPick
- New conflict marker logic will be added to ConflictDetector.psm1 (appropriate module)
- Get-UpdateConfirmation.ps1 (helper) remains thin orchestration wrapper
- No business logic moved outside modules

**Actions**:
- Remove Show-QuickPick function from VSCodeIntegration.psm1
- Update Export-ModuleMember to remove Show-QuickPick
- Add `Write-ConflictMarkers` function to ConflictDetector.psm1
- Update Get-UpdateConfirmation.ps1 to output summary text instead of calling Show-QuickPick

### Principle II: Fail-Fast with Rollback ✅ PASS

**Compliance**:
- No changes to rollback mechanism
- Conflict marker writing happens during file update phase (already within rollback scope)
- If conflict marker write fails, existing rollback logic handles it

**Actions**:
- None required (feature maintains existing rollback architecture)

### Principle III: Customization Detection via Normalized Hashing ✅ PASS

**Compliance**:
- No changes to hash normalization logic
- Conflict detection still uses normalized hashes to compare base/current/incoming versions

**Actions**:
- None required (feature does not affect hashing logic)

### Principle IV: User Confirmation Required ⚠️ MODIFIED (Justified)

**Current State**: Requires explicit confirmation via VSCode Quick Pick UI

**Proposed Change**: Confirmation via conversational workflow (skill outputs summary → Claude presents → user approves via chat → Claude re-invokes with approval parameter)

**Justification**: Quick Pick UI is architecturally impossible (violates Principle VI - cannot access VSCode UI from PowerShell subprocess). Conversational workflow achieves same user confirmation requirement through text-only I/O.

**Actions**:
- Remove Quick Pick confirmation logic
- Add summary output generation (structured text to stdout)
- Add `-Confirm` parameter (or similar) for Claude to pass after approval
- Update documentation to reflect new confirmation pattern

### Principle V: Testing Discipline ✅ PASS

**Compliance**:
- Remove tests for Show-QuickPick function (no longer exists)
- Add tests for conflict marker writing
- Add integration tests for summary output format
- Add tests for approval parameter handling

**Actions**:
- Delete `Show-QuickPick` tests from tests/unit/VSCodeIntegration.Tests.ps1
- Add `Write-ConflictMarkers` tests to tests/unit/ConflictDetector.Tests.ps1
- Add integration tests to tests/integration/UpdateOrchestrator.Tests.ps1
- Verify test coverage remains ≥80% for modified modules

### Principle VI: Architectural Verification Before Suggestions ✅ PASS (This Feature Fixes Violation!)

**Original Violation**: Show-QuickPick attempted to return sentinel hashtable for Claude Code extension to intercept, assuming IPC bridge exists between PowerShell subprocess and VSCode extension host. This violates Principle VI because:

- PowerShell process spawned via `pwsh -Command` has stdout/stderr text streams only
- No IPC mechanism exists for PowerShell objects to reach VSCode extension
- Suggestion assumed GUI access from CLI-only context

**This Feature's Compliance**: Removes architectural violation by:
- Eliminating assumption of VSCode UI access from PowerShell
- Using only text-based I/O (stdout) compatible with subprocess execution model
- Verifying `code --merge` availability at runtime before use, with fallback
- Documenting text-only I/O constraint in constitution and CLAUDE.md

**Actions**:
- Remove Show-QuickPick (eliminates architectural violation)
- Add runtime test for `code --merge` before attempting invocation
- Add fallback to Git conflict markers if `code --merge` unavailable
- Document I/O constraints in CLAUDE.md "Architectural Limitations" section

### Gate Summary

| Gate | Status | Notes |
|------|--------|-------|
| Modular Architecture | ✅ PASS | Code removal preserves module boundaries |
| Fail-Fast Rollback | ✅ PASS | No rollback changes needed |
| Normalized Hashing | ✅ PASS | No hash logic changes |
| User Confirmation | ⚠️ MODIFIED | Justified: Quick Pick architecturally impossible; conversational workflow equivalent |
| Testing Discipline | ✅ PASS | Tests updated for removed/added code |
| Architectural Verification | ✅ PASS | **This feature fixes the original violation!** |

**Overall**: ✅ **PASS WITH JUSTIFIED MODIFICATION** - Proceed to Phase 0

## Project Structure

### Documentation (this feature)

```
specs/007-remove-quickpick-integration/
├── spec.md              # Feature specification
├── plan.md              # This file (/speckit.plan output)
├── research.md          # Phase 0: Technical decisions
├── data-model.md        # Phase 1: Conflict marker format
├── quickstart.md        # Phase 1: Conversational workflow guide
├── contracts/           # Phase 1: Summary output schema
│   └── summary-output.schema.json
└── tasks.md             # Phase 2: NOT created by /speckit.plan
```

### Source Code (repository root)

```
scripts/
├── update-orchestrator.ps1        # MODIFY: Remove -Auto flag, add approval param
├── modules/
│   ├── VSCodeIntegration.psm1     # MODIFY: Remove Show-QuickPick (lines 55-143)
│   └── ConflictDetector.psm1      # MODIFY: Add Write-ConflictMarkers function
└── helpers/
    └── Get-UpdateConfirmation.ps1 # MODIFY: Remove Show-QuickPick calls, add summary output

tests/
├── unit/
│   ├── VSCodeIntegration.Tests.ps1  # MODIFY: Remove Show-QuickPick tests
│   └── ConflictDetector.Tests.ps1   # MODIFY: Add conflict marker tests
└── integration/
    └── UpdateOrchestrator.Tests.ps1  # MODIFY: Add approval workflow tests

docs/
└── bugs/
    └── 005-vscode-quickpick-architectural-limitation.md  # Reference (existing)

CLAUDE.md                            # MODIFY: Add architectural limitations section
SKILL.md                             # MODIFY: Document conversational workflow
.specify/memory/constitution.md      # MODIFY: Add text-only I/O principle
```

**Structure Decision**: Single project structure maintained. This is a refactoring feature affecting existing PowerShell modules (VSCodeIntegration, ConflictDetector) and helpers (Get-UpdateConfirmation). No new directories or projects needed.

## Complexity Tracking

*No constitution violations requiring justification. Principle IV modification is justified by architectural impossibility of original approach.*

---

## Post-Design Constitution Re-Evaluation

*GATE: Re-check after Phase 1 design completed.*

### Design Artifacts Generated

- ✅ `research.md` - Technical decisions documented
- ✅ `data-model.md` - Conflict marker format, summary output structure
- ✅ `contracts/summary-output.schema.json` - JSON schema for summary data
- ✅ `quickstart.md` - User guide for conversational workflow

### Constitution Compliance After Design

#### Principle I: Modular Architecture ✅ PASS

**Verification**:
- `Write-ConflictMarkers` function designed for ConflictDetector.psm1 (correct module)
- `New-UpdateSummary` function designed for Get-UpdateConfirmation.ps1 (helper, appropriate for orchestration)
- Module boundaries preserved
- No business logic leaked into orchestrator

**Design Artifacts**:
- data-model.md defines `Write-ConflictMarkers` signature (module function)
- data-model.md defines `New-UpdateSummary` signature (helper function)
- Separation maintained: module handles conflict marker writing, helper handles summary generation

#### Principle II: Fail-Fast with Rollback ✅ PASS

**Verification**:
- Conflict marker writing happens during file update phase (within rollback scope)
- No new failure points introduced outside rollback handling
- Existing backup/restore mechanism sufficient

#### Principle III: Customization Detection via Normalized Hashing ✅ PASS

**Verification**:
- Conflict detection still uses normalized hashes (no design changes to hash logic)
- data-model.md references CurrentHash, BaseHash, IncomingHash (all normalized)

#### Principle IV: User Confirmation Required ✅ PASS (Modified, Justified)

**Verification**:
- Conversational workflow design maintains user confirmation requirement
- quickstart.md documents approval flow: summary → Claude presents → user approves → proceed
- Summary output includes [PROMPT_FOR_APPROVAL] marker
- User can decline, ask questions, or approve

**Justification Remains Valid**: Architectural impossibility of Quick Pick UI; conversational workflow provides equivalent user control.

#### Principle V: Testing Discipline ✅ PASS

**Verification**:
- data-model.md includes "Validation & Testing" section with test cases
- Test cases defined for:
  - Conflict marker writing (basic, VSCode recognition, Unicode)
  - Summary output formatting (empty categories, multiple files)
  - Edge cases (nested markers, large files, binary files)

**Test Coverage Plan**:
- Unit tests: Write-ConflictMarkers (ConflictDetector.Tests.ps1)
- Unit tests: New-UpdateSummary (new test file or integration tests)
- Integration tests: Full approval workflow (UpdateOrchestrator.Tests.ps1)

#### Principle VI: Architectural Verification Before Suggestions ✅ PASS

**Verification**:
- research.md documents why Show-QuickPick failed (PowerShell subprocess I/O constraints)
- Design uses only text-based I/O (stdout Markdown output)
- Git conflict markers don't require external process invocation
- VSCode merge editor test is optional, with fallback to conflict markers

**Architectural Constraints Documented**:
- research.md Q1: "PowerShell subprocess can only communicate via text streams"
- research.md Q4: "Git conflict markers as primary; code --merge as optional enhancement"

### Gate Summary (Post-Design)

| Gate | Status | Changes from Initial Check |
|------|--------|---------------------------|
| Modular Architecture | ✅ PASS | Design confirmed module assignments |
| Fail-Fast Rollback | ✅ PASS | No changes; conflict markers within rollback scope |
| Normalized Hashing | ✅ PASS | No changes; design references existing hashes |
| User Confirmation | ✅ PASS (Modified) | Conversational workflow design validated |
| Testing Discipline | ✅ PASS | Test cases defined in data-model.md |
| Architectural Verification | ✅ PASS | I/O constraints documented; text-only design verified |

**Overall**: ✅ **PASS - Ready for Implementation** (Phase 2: `/speckit.tasks`)

### Design Quality Assessment

**Strengths**:
- Clear separation of concerns (modules vs helpers)
- Comprehensive edge case handling (Unicode, large files, nested markers)
- Backward compatibility considered (deprecate -Auto with warning)
- User experience prioritized (quickstart guide, clear examples)
- Validation strategy defined (test cases documented)

**Risks Identified & Mitigated**:
- **Risk**: Claude fails to parse summary Markdown
  - **Mitigation**: Structured headings, [PROMPT_FOR_APPROVAL] marker, JSON schema defined
- **Risk**: VSCode doesn't recognize conflict markers
  - **Mitigation**: Exact Git format specified, validation tests included
- **Risk**: Users confused by workflow change
  - **Mitigation**: Comprehensive quickstart.md, deprecation warnings, examples

**Dependencies**:
- None new (removing code, using existing PowerShell modules)

**Performance**:
- Summary generation < 500ms (per research.md)
- Conflict marker write < 50ms per file (per data-model.md)
- Within acceptable bounds for interactive workflow

### Next Steps

1. **Generate tasks** via `/speckit.tasks` command
2. **Implement** according to task breakdown
3. **Test** using test cases from data-model.md
4. **Document** architectural constraints in CLAUDE.md
5. **Update** constitution with text-only I/O principle


