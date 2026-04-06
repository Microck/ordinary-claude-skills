# Implementation Plan: Helpful Error Messages for Non-SpecKit Projects

**Branch**: `010-helpful-error-messages` | **Date**: 2025-10-22 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/010-helpful-error-messages/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

This feature enhances the `/speckit-update` command to provide helpful, actionable error messages when invoked in projects without SpecKit installed. Instead of cryptic errors, users will receive educational context about what SpecKit is, why it's required, and clear next steps based on their environment (whether SpecKit commands are already installed or not).

**Technical Approach**: Enhance existing error detection in the `Invoke-PreUpdateValidation.ps1` helper by adding context-aware error message generation. Create new helper functions to detect SpecKit command availability and generate two message variants: one for users with SpecKit commands installed (suggests `/speckit.constitution`), and one for users without (provides documentation link).

## Technical Context

**Language/Version**: PowerShell 7+
**Primary Dependencies**: None (pure enhancement to existing codebase)
**Storage**: File system for command detection (`.claude/commands/` directory)
**Testing**: Pester 5.x (unit and integration tests)
**Target Platform**: Windows (PowerShell 7+ via Claude Code extension)
**Project Type**: PowerShell skill (CLI-based, text-only I/O)
**Performance Goals**: Error message generation < 100ms (negligible impact on validation)
**Constraints**: Text-only I/O (no GUI), subprocess execution context, must work in both Claude Code and terminal
**Scale/Scope**: Single file modification with 2 new helper functions (~50 lines of code)

## Success Criteria Measurement Timeline

The spec defines 7 success criteria (SC-001 through SC-007). Implementation can validate 4 of these directly; 3 require post-launch observation:

**Testable During Implementation**:
- **SC-004**: Error message clarity (manual review against criteria in tasks.md T034)
- **SC-006**: Zero regression in behavior (automated test in tasks.md T031)
- **SC-007**: Correct rendering in terminal/VSCode (manual tests in tasks.md T029-T030)
- **SC-001** (partial): Qualitative review of message comprehension (full measurement post-launch)

**Post-Launch Metrics** (tracked after feature deployment):
- **SC-001**: 90% user comprehension (user surveys)
- **SC-002**: 80% support question reduction (GitHub issue analysis)
- **SC-003**: 50% conversion to SpecKit initialization (session analytics)
- **SC-005**: <5 minute time to successful initialization (user observation studies)

**Note**: Post-launch metrics will be tracked via GitHub Discussions surveys and issue activity analysis. No telemetry or analytics tracking is implemented in the code per FR-012 and Out of Scope requirements.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Modular Architecture ✅ PASS

**Assessment**: This feature enhances existing helper functions, not modules. The error message generation logic will be added to `Invoke-PreUpdateValidation.ps1` (a helper), which is the correct location for user-facing validation messages. No business logic is being added to helpers - this is purely presentational (error message formatting).

**Justification**: Helper functions are explicitly designed for "thin orchestration wrappers that call module functions and handle user interaction" (Constitution I). Error messages are user interaction, not business logic.

### Principle II: Fail-Fast with Rollback ✅ PASS

**Assessment**: This feature operates during the prerequisites validation phase (before any file operations). No rollback needed as no state changes occur during error message generation.

**Impact**: None - feature is read-only (file detection) with text output only.

### Principle III: Customization Detection via Normalized Hashing ✅ PASS

**Assessment**: Not applicable - feature does not involve file customization detection or hashing.

**Impact**: None.

### Principle IV: User Confirmation Required ✅ PASS

**Assessment**: This feature provides error messages when prerequisites fail. No destructive operations occur, so no confirmation needed. The feature improves the user experience when confirmation cannot proceed (project is not eligible for updates).

**Impact**: None - feature outputs error text and exits.

### Principle V: Testing Discipline ✅ PASS

**Requirements Met**:
- Unit tests will be added to existing `Invoke-PreUpdateValidation.Tests.ps1` for new helper functions
- Integration test will be added to `UpdateOrchestrator.Tests.ps1` for end-to-end behavior
- Both success paths (commands available/not available) will be tested
- Error paths (detection failures, permission issues) will be tested

**Test Coverage Plan**: 2 new unit tests for helper functions, 1 integration test for non-SpecKit project scenario.

### Principle VI: Architectural Verification Before Suggestions ✅ PASS

**Assessment**: This feature correctly respects the text-only I/O constraint documented in Constitution VI.

**Compliance**:
- ✅ Uses text output only (Write-Host, string concatenation)
- ✅ No VSCode UI assumptions (no Quick Pick, dialogs, or extension APIs)
- ✅ No PowerShell GUI cmdlets (no Out-GridView or WPF windows)
- ✅ File detection via standard PowerShell `Test-Path` (works in subprocess)
- ✅ Follows approved conversational workflow pattern (skill outputs error → user sees it → no re-invocation needed for errors)

**Text-Only I/O Verification**:
- Error messages constructed as multi-line strings using here-strings
- Output via standard error stream (Write-Error with formatted text)
- No sentinel objects or hashtables for UI interception
- No assumptions about VSCode extension host access

### PowerShell Standards ✅ PASS

**Code Style Compliance**:
- Function names will use approved verbs: `Get-HelpfulSpecKitError`, `Test-SpecKitCommandsAvailable`
- Variables will use camelCase: `$specifyDir`, `$hasSpecKitCommands`, `$errorMessage`
- Parameters will use PascalCase with type annotations
- Comment-based help will be added for new functions (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`)
- Error handling with try-catch where file operations occur

**Module Import Compliance**:
- No new modules created (enhancement to existing helper)
- No Import-Module statements added (helpers are dot-sourced)
- No violations of orchestrator-managed imports pattern

### Gate Result: ✅ ALL CHECKS PASSED

**Justification**: This is a straightforward enhancement to error messaging with no architectural complexity, no new patterns introduced, and full compliance with text-only I/O constraints.

## Project Structure

### Documentation (this feature)

```
specs/010-helpful-error-messages/
├── spec.md              # Feature specification (completed)
├── plan.md              # This file (/speckit.plan output)
├── research.md          # Phase 0 output (to be generated)
├── data-model.md        # N/A (no data model for this feature)
├── quickstart.md        # Phase 1 output (developer guide)
├── contracts/           # N/A (no API contracts for this feature)
└── checklists/
    └── requirements.md  # Specification quality checklist (completed)
```

### Source Code (repository root)

```
scripts/
├── helpers/
│   └── Invoke-PreUpdateValidation.ps1  # MODIFIED: Enhanced error message for .specify/ check
│
└── update-orchestrator.ps1              # No changes (calls helper as before)

tests/
├── unit/
│   └── Invoke-PreUpdateValidation.Tests.ps1  # MODIFIED: Add tests for new functions
│
└── integration/
    └── UpdateOrchestrator.Tests.ps1          # MODIFIED: Add non-SpecKit project test

docs/
└── PRDs/
    └── 002-Helpful-Error-Messages.md          # Source PRD (existing)

CHANGELOG.md                                   # MODIFIED: Add entry under [Unreleased]
```

**Structure Decision**: Single project structure (Option 1) applies. This is a small enhancement to existing error handling within the `scripts/helpers/` directory. No new modules or significant reorganization required.

**Files Modified**: 4 files total
- `scripts/helpers/Invoke-PreUpdateValidation.ps1` - Add error message generation logic
- `tests/unit/Invoke-PreUpdateValidation.Tests.ps1` - Add test coverage
- `tests/integration/UpdateOrchestrator.Tests.ps1` - Add integration test
- `CHANGELOG.md` - Add entry under [Unreleased]

**Files Created**: 0 (pure enhancement, no new files)

## Complexity Tracking

*No violations - this section is not applicable.*

---

## Phase 0: Research & Decisions

See [research.md](research.md) for detailed findings.

### Research Questions

1. **How should we detect SpecKit command availability?**
   - Decision needed: File system patterns to check
   - Research: `.claude/commands/` directory structure, SpecKit command naming conventions

2. **What fallback behavior should we use if command detection fails?**
   - Decision needed: Static message vs. detection error handling
   - Research: PowerShell error handling best practices, fail-safe messaging patterns

3. **What exact error message wording maximizes clarity?**
   - Decision needed: Message length, tone, formatting
   - Research: Error message UX best practices, existing error message patterns in codebase

4. **How do we ensure cross-platform compatibility?**
   - Decision needed: Path handling for `.claude/commands/` directory
   - Research: PowerShell environment variables, user profile paths on Windows

### Key Technical Decisions

*To be filled after research phase*

---

## Phase 1: Design Artifacts

### Data Model

**N/A**: This feature does not involve persistent data or entities. Error messages are ephemeral text output.

### API Contracts

**N/A**: This feature does not expose APIs or interfaces. It enhances internal error messaging within the validation workflow.

### Quickstart Guide

See [quickstart.md](quickstart.md) for developer implementation guide.

---

---

## Post-Phase 1 Constitution Re-Check

*Required gate after Phase 1 design artifacts are complete.*

### Re-Evaluation Summary

After completing Phase 0 (research) and Phase 1 (design artifacts), all constitution principles remain compliant:

**Principle I (Modular Architecture)**: ✅ CONFIRMED
- Design maintains helper function pattern for error messaging
- No business logic in helpers (only presentational error formatting)
- Two new helper functions: `Get-HelpfulSpecKitError`, `Test-SpecKitCommandsAvailable`
- Functions are stateless and side-effect free

**Principle II (Fail-Fast with Rollback)**: ✅ CONFIRMED
- Feature operates during read-only validation phase
- No file modifications occur
- No rollback mechanisms needed

**Principle III (Customization Detection via Normalized Hashing)**: ✅ N/A
- Feature does not involve file customization detection

**Principle IV (User Confirmation Required)**: ✅ CONFIRMED
- Error messages are informational only
- No confirmation prompts needed (operation exits after displaying error)

**Principle V (Testing Discipline)**: ✅ CONFIRMED
- Unit tests designed for both helper functions (6 test cases)
- Integration test covers end-to-end scenario (1 test case)
- Error path testing included (fallback message scenario)
- Quickstart guide includes comprehensive testing checklist

**Principle VI (Architectural Verification)**: ✅ CONFIRMED
- Design respects text-only I/O constraint
- Uses PowerShell here-strings for multi-line messages
- No GUI assumptions or VSCode extension API dependencies
- Standard `Test-Path` for file system checks (subprocess-compatible)
- Graceful error handling with try-catch fallback

**PowerShell Standards**: ✅ CONFIRMED
- Function naming follows approved verbs (Get-, Test-)
- Variable naming uses camelCase
- Comment-based help documented for all new functions
- Error handling with try-catch and verbose logging

### Final Gate Result: ✅ ALL PRINCIPLES CONFIRMED

**Design Validation**: The research and design artifacts confirm the initial assessment. No new architectural risks or complexity introduced. Implementation can proceed to task breakdown.

---

## Phase 2: Task Breakdown

*Tasks will be generated by `/speckit.tasks` command after plan approval.*

**Task Generation Readiness**: ✅ READY - All prerequisites complete:
- Phase 0 research resolved all technical decisions
- Phase 1 quickstart guide provides implementation blueprint
- Constitution check passed (initial and post-Phase 1 re-check)
- No blocking issues or unresolved questions

**Next Command**: Run `/speckit.tasks` to generate dependency-ordered task list for implementation.
