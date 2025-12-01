# Implementation Plan: Fix Installation Flow to Respect -Proceed Flag

**Branch**: `011-fix-install-proceed-flag` | **Date**: 2025-10-23 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/011-fix-install-proceed-flag/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Fix the installation workflow to respect the `-Proceed` flag in conversational approval pattern. Currently, when users run `/speckit-update` in a project without SpecKit installed, the validation helper ignores the `-Proceed` flag and shows the installation prompt twice. This completely blocks fresh SpecKit installations.

**Technical Approach**: Add `-Proceed` parameter to `Invoke-PreUpdateValidation.ps1`, update installation detection logic to check the flag, pass parameter from orchestrator, and change error behavior from `throw` to `exit 0` for graceful conversational workflow.

## Technical Context

**Language/Version**: PowerShell 7.0+
**Primary Dependencies**: Pester 5.x (testing only - no new runtime dependencies)
**Storage**: N/A (file system operations only)
**Testing**: Pester 5.x with unit tests in `tests/unit/` and integration tests in `tests/integration/`
**Target Platform**: Windows 11 (PowerShell Core 7.0+)
**Project Type**: Single project (PowerShell skill)
**Performance Goals**: N/A (bug fix with no performance impact - same execution path)
**Constraints**: Text-only I/O (stdout/stderr), no GUI, conversational workflow pattern required
**Scale/Scope**: Bug fix affecting 2 files, ~20 lines of code changed

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### ✅ Principle I: Modular Architecture (NON-NEGOTIABLE)

**Status**: PASS

- All business logic remains in modules (no changes to `.psm1` files)
- Only helper function (`Invoke-PreUpdateValidation.ps1`) and orchestrator modified
- Helper remains thin orchestration wrapper with no business logic
- No new modules created

**Verification**: Changes limited to parameter handling and conditional flow in helper function.

### ✅ Principle II: Fail-Fast with Rollback (NON-NEGOTIABLE)

**Status**: PASS

- Bug fix does not affect transactional update process
- Installation flow happens BEFORE file modifications (during validation step)
- No rollback needed at validation stage
- Changes to exit behavior (`exit 0` vs `throw`) improve graceful degradation

**Verification**: Installation detection happens in Step 3 (prerequisites validation), before backup/modification steps.

### ✅ Principle III: Customization Detection via Normalized Hashing

**Status**: PASS - NOT APPLICABLE

- Bug fix does not affect hashing or customization detection logic
- No changes to `HashUtils.psm1` or manifest comparison logic

### ✅ Principle IV: User Confirmation Required

**Status**: PASS

- Bug fix IMPLEMENTS this principle correctly
- Current behavior violates this principle by showing prompt twice
- Fix ensures single confirmation request per installation

**Verification**: Installation prompt shown once on first invocation without `-Proceed`, proceeds on second invocation with `-Proceed`.

### ✅ Principle V: Testing Discipline

**Status**: PASS

- Unit tests will be added/updated for `Invoke-PreUpdateValidation` parameter handling
- Integration tests will be added for end-to-end installation flow
- Both success and error paths covered

**Verification**: Test plan documented in bug report (lines 238-361) includes unit and integration tests.

### ✅ Principle VI: Architectural Verification Before Suggestions

**Status**: PASS

- Solution respects text-only I/O constraint (no GUI assumptions)
- Uses approved conversational workflow pattern (output summary → Claude presents → user approves → re-invoke with flag)
- No VSCode UI assumptions, no GUI cmdlets, no IPC expectations
- Pattern already validated in update flow (lines 381-409)

**Verification**: Bug fix follows EXACT pattern from working update flow, which already respects text-only I/O constraint.

### Post-Phase 1 Re-check

All principles remain PASS after design phase. No new complexity introduced.

## Project Structure

### Documentation (this feature)

```
specs/011-fix-install-proceed-flag/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output - NOT NEEDED (no unknowns, reference implementation exists)
├── data-model.md        # Phase 1 output - NOT NEEDED (no data structures changed)
├── quickstart.md        # Phase 1 output (developer testing guide)
├── contracts/           # Phase 1 output - NOT NEEDED (no APIs changed)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```
scripts/
├── update-orchestrator.ps1              # MODIFY: Pass -Proceed to validation helper (line 189)
├── helpers/
│   └── Invoke-PreUpdateValidation.ps1   # MODIFY: Add -Proceed param, update installation logic (lines 20, 206-221)
└── modules/
    └── (no changes to modules)

tests/
├── unit/
│   └── Invoke-PreUpdateValidation.Tests.ps1   # ADD: Tests for -Proceed parameter handling
└── integration/
    └── UpdateOrchestrator.Tests.ps1           # MODIFY: Add installation flow test cases

docs/
└── bugs/
    └── 008-install-proceed-flag-ignored.md    # Reference: Complete bug report with proposed solution
```

**Structure Decision**: Single project structure (existing). This is a surgical bug fix affecting only the validation helper and orchestrator. No new files created, only modifications to 2 existing scripts and additions to test suites.

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

**N/A** - All constitution checks pass. No violations to justify.

## Phase 0: Research & Unknowns

**Status**: SKIPPED

**Rationale**: This is a well-defined bug fix with:
- Complete bug report documenting root cause (lines 51-97)
- Proposed solution with exact code changes (lines 139-223)
- Reference implementation in update flow (lines 381-409 in update-orchestrator.ps1)
- No unknowns or technical uncertainties
- No new technologies or patterns required

**Reference Implementation**: Update flow `-Proceed` handling (update-orchestrator.ps1:381-409) provides proven pattern.

**Decision**: Proceed directly to Phase 1 design using reference implementation as guide.

## Phase 1: Design & Contracts

### Design Overview

**Goal**: Make installation flow match update flow's `-Proceed` handling pattern.

**Change Summary**:
1. Add `-Proceed` switch parameter to `Invoke-PreUpdateValidation` function
2. Update installation detection logic to check flag before prompting/exiting
3. Pass `-Proceed` parameter from orchestrator to helper
4. Change exit behavior from `throw` (error) to `exit 0` (graceful)

### Design Artifacts

#### 1. data-model.md

**Status**: NOT NEEDED

**Rationale**: No data structures changed. This bug fix only affects control flow (parameter passing and conditional logic). Manifest schema unchanged.

#### 2. contracts/

**Status**: NOT NEEDED

**Rationale**: No API contracts changed. This is internal PowerShell script behavior, not external API. Parameter addition is backward compatible (optional switch parameter).

#### 3. quickstart.md

**Status**: REQUIRED

**Content**: Developer testing guide for verifying the fix manually before running automated tests.

**Location**: `specs/011-fix-install-proceed-flag/quickstart.md`

### Post-Design Constitution Re-check

Rechecking all principles after design phase:

- ✅ **Principle I (Modular Architecture)**: No changes to module architecture
- ✅ **Principle II (Fail-Fast with Rollback)**: Improved graceful degradation with `exit 0`
- ✅ **Principle III (Normalized Hashing)**: Not affected
- ✅ **Principle IV (User Confirmation)**: Fixed to work correctly (single prompt)
- ✅ **Principle V (Testing Discipline)**: Tests planned and documented
- ✅ **Principle VI (Architectural Verification)**: Solution respects text-only I/O constraint

**Result**: All principles PASS after design. No new violations introduced.

## Phase 2: Implementation Tasks

**Status**: NOT CREATED BY THIS COMMAND

**Note**: Phase 2 tasks generation is handled by `/speckit.tasks` command, which runs after this plan is complete.

**Expected Task Categories**:
- **Code Changes**: Modify 2 files (orchestrator, validation helper)
- **Test Additions**: Add unit tests, add integration tests
- **Documentation Updates**: Update CLAUDE.md, SKILL.md, CHANGELOG.md
- **Manual Verification**: Test fresh installation workflow end-to-end

## Next Steps

1. ✅ Review this implementation plan
2. ⏭️ Run `/speckit.tasks` to generate dependency-ordered task list
3. ⏭️ Run `/speckit.implement` to execute tasks
4. ⏭️ Run test suite to verify fix
5. ⏭️ Create pull request with fix

## References

- **Bug Report**: [docs/bugs/008-install-proceed-flag-ignored.md](../../docs/bugs/008-install-proceed-flag-ignored.md)
- **Affected Files**:
  - [scripts/helpers/Invoke-PreUpdateValidation.ps1](../../scripts/helpers/Invoke-PreUpdateValidation.ps1) (primary)
  - [scripts/update-orchestrator.ps1](../../scripts/update-orchestrator.ps1) (secondary)
- **Reference Implementation**: Update flow pattern in [scripts/update-orchestrator.ps1:381-409](../../scripts/update-orchestrator.ps1#L381-L409)
- **Constitution**: [.specify/memory/constitution.md](../../.specify/memory/constitution.md)
