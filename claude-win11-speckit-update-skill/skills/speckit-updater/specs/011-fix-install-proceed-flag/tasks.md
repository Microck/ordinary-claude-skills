---
description: "Implementation tasks for fixing installation flow -Proceed flag bug"
---

# Tasks: Fix Installation Flow to Respect -Proceed Flag

**Input**: Design documents from `/specs/011-fix-install-proceed-flag/`
**Prerequisites**: plan.md (completed), spec.md (completed), quickstart.md (completed)

**Tests**: Test tasks are included as this is a bug fix requiring verification.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions
- **Single project**: `scripts/`, `tests/` at repository root
- This is a PowerShell skill with existing structure - all paths relative to repository root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: No setup needed - bug fix in existing codebase

**Status**: SKIPPED - All infrastructure already exists

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: No foundational changes needed - bug fix only

**Status**: SKIPPED - No blocking prerequisites for this bug fix

**Checkpoint**: Can proceed directly to user story implementation

---

## Phase 3: User Story 1 - Fresh SpecKit Installation via Conversational Workflow (Priority: P1) 🎯 MVP

**Goal**: Enable fresh SpecKit installations using two-phase conversational workflow (`/speckit-update` → view offer → `/speckit-update -Proceed` → install). Fix the core bug where `-Proceed` flag is ignored, causing double prompts and blocking 100% of fresh installations.

**Independent Test**: Run `/speckit-update` in a project without `.specify/` folder (shows prompt, exit 0), then run `/speckit-update -Proceed` (installs successfully). See quickstart.md scenarios 1-3.

### Implementation for User Story 1

- [X] T001 [US1] Add `-Proceed` switch parameter to function signature in scripts/helpers/Invoke-PreUpdateValidation.ps1
- [X] T002 [US1] Update installation detection logic to check `-Proceed` flag in scripts/helpers/Invoke-PreUpdateValidation.ps1 (lines 206-221)
- [X] T003 [US1] Change exit behavior from `throw` to `exit 0` when awaiting approval in scripts/helpers/Invoke-PreUpdateValidation.ps1
- [X] T004 [US1] Add conditional branch for `-Proceed` flag: if not set, show prompt and exit gracefully in scripts/helpers/Invoke-PreUpdateValidation.ps1
- [X] T005 [US1] Add conditional branch for `-Proceed` flag: if set, skip prompt and continue validation in scripts/helpers/Invoke-PreUpdateValidation.ps1
- [X] T006 [US1] Pass `-Proceed` parameter from orchestrator to validation helper using `-Proceed:$Proceed` syntax in scripts/update-orchestrator.ps1 (line 189)

### Tests for User Story 1

- [X] T007 [P] [US1] Create unit test file tests/unit/Invoke-PreUpdateValidation.Tests.ps1 if it doesn't exist
- [X] T008 [P] [US1] Add unit test: validation helper accepts `-Proceed` parameter without errors in tests/unit/Invoke-PreUpdateValidation.Tests.ps1
- [X] T009 [P] [US1] Add unit test: without `-Proceed`, installation detection exits with code 0 (not throw) in tests/unit/Invoke-PreUpdateValidation.Tests.ps1
- [X] T010 [P] [US1] Add unit test: with `-Proceed`, installation detection continues (no exit, no throw) in tests/unit/Invoke-PreUpdateValidation.Tests.ps1
- [X] T011 [US1] Add integration test: fresh installation flow without `-Proceed` shows prompt and exits gracefully in tests/integration/UpdateOrchestrator.Tests.ps1
- [X] T012 [US1] Add integration test: fresh installation flow with `-Proceed` completes installation successfully in tests/integration/UpdateOrchestrator.Tests.ps1
- [X] T013 [US1] Add integration test: direct proceed on first invocation works (scenario 3) in tests/integration/UpdateOrchestrator.Tests.ps1

**Checkpoint**: At this point, User Story 1 should be fully functional - fresh installations work with two-command workflow

---

## Phase 4: User Story 2 - Consistent Behavior Between Installation and Update Flows (Priority: P2)

**Goal**: Ensure installation flow `-Proceed` handling matches update flow pattern (lines 381-409 in update-orchestrator.ps1). Developer experience should be identical: first invocation shows summary, second with `-Proceed` executes.

**Independent Test**: Compare installation flow behavior with update flow behavior - both should show identical approval patterns. See quickstart.md scenario 4-5.

### Implementation for User Story 2

- [X] T014 [US2] Review update flow `-Proceed` pattern in scripts/update-orchestrator.ps1 (lines 381-409) and verify installation flow matches
- [X] T015 [US2] Ensure installation prompt format matches update prompt format (both use `[PROMPT_FOR_*]` markers) in scripts/helpers/Invoke-PreUpdateValidation.ps1
- [X] T016 [US2] Verify installation flow exits gracefully like update flow (code 0, not error) in scripts/helpers/Invoke-PreUpdateValidation.ps1

### Tests for User Story 2

- [X] T017 [P] [US2] Add integration test: existing SpecKit project shows no installation prompt in tests/integration/UpdateOrchestrator.Tests.ps1
- [X] T018 [P] [US2] Add integration test: multiple installations are idempotent (no duplicate installs) in tests/integration/UpdateOrchestrator.Tests.ps1
- [X] T019 [US2] Add comparison test: installation and update flows both handle `-Proceed` identically in tests/integration/UpdateOrchestrator.Tests.ps1

**Checkpoint**: At this point, installation and update flows should behave consistently - same UX patterns

---

## Phase 5: User Story 3 - Clear Error Prevention and User Guidance (Priority: P3)

**Goal**: Ensure installation prompt provides clear, actionable guidance. Users should never see confusing error messages. Exit behavior should be graceful (`exit 0`), not error (`throw`). Verbose logging should indicate approval state clearly.

**Independent Test**: Run installation flow with various edge cases, verify all error messages are actionable and exit codes are correct. See quickstart.md verification checklist.

### Implementation for User Story 3

- [X] T020 [US3] Update installation prompt to include exact command instruction (`/speckit-update -Proceed`) in scripts/helpers/Invoke-PreUpdateValidation.ps1
- [X] T021 [US3] Add cyan-colored `[PROMPT_FOR_INSTALL]` marker to installation prompt in scripts/helpers/Invoke-PreUpdateValidation.ps1
- [X] T022 [US3] Add yellow warning text "SpecKit is not currently installed in this project." in scripts/helpers/Invoke-PreUpdateValidation.ps1
- [X] T023 [US3] Add gray description text describing what installation will do in scripts/helpers/Invoke-PreUpdateValidation.ps1
- [X] T024 [US3] Add white command text showing exact proceed command in scripts/helpers/Invoke-PreUpdateValidation.ps1
- [X] T025 [US3] Add verbose logging message "Awaiting user approval for SpecKit installation" when awaiting approval in scripts/helpers/Invoke-PreUpdateValidation.ps1
- [X] T026 [US3] Add verbose logging message "User approved SpecKit installation, proceeding..." when proceeding in scripts/helpers/Invoke-PreUpdateValidation.ps1
- [X] T027 [US3] Add progress indicator "📦 Installing SpecKit..." in cyan when installation proceeds in scripts/helpers/Invoke-PreUpdateValidation.ps1

### Tests for User Story 3

- [X] T028 [P] [US3] Add unit test: installation prompt contains all required elements with exact colors (Cyan marker, Yellow warning, Gray description, White command) in tests/unit/Invoke-PreUpdateValidation.Tests.ps1
- [X] T029 [P] [US3] Add unit test: verbose logging shows correct approval state transitions in tests/unit/Invoke-PreUpdateValidation.Tests.ps1
- [X] T030 [US3] Add integration test: no error thrown when awaiting approval (graceful exit) in tests/integration/UpdateOrchestrator.Tests.ps1

**Checkpoint**: All user stories complete - installation flow fully functional with clear UX

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation updates, final validation, edge case testing, and release preparation

- [X] T031 [P] Add installation flow documentation section to CLAUDE.md (Key Workflows section)
- [X] T032 [P] Update installation example in SKILL.md with two-command workflow
- [X] T033 [P] Add bug fix entry to CHANGELOG.md under "Fixed" section for next release
- [X] T034 Run manual test scenarios from specs/011-fix-install-proceed-flag/quickstart.md (scenarios 1-5)
- [X] T035 Run full test suite with ./tests/test-runner.ps1 and verify all tests pass
- [X] T036 Run unit tests only with ./tests/test-runner.ps1 -Unit and verify all pass
- [X] T037 Run integration tests only with ./tests/test-runner.ps1 -Integration and verify all pass
- [X] T038 Verify exit code is 0 for installation prompt (not error code)
- [X] T039 Verify no double prompts occur in any scenario
- [X] T040 Verify installation completes successfully with `-Proceed` flag
- [X] T041 [P] Add integration test: network failure during template download shows clear error (edge case 2) in tests/integration/UpdateOrchestrator.Tests.ps1
- [X] T042 [P] Add integration test: empty or corrupt .specify/ directory detected and handled correctly (edge case 3) in tests/integration/UpdateOrchestrator.Tests.ps1

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: SKIPPED - No setup needed
- **Foundational (Phase 2)**: SKIPPED - No foundational changes
- **User Story 1 (Phase 3)**: Can start immediately - This is the core bug fix
- **User Story 2 (Phase 4)**: Depends on User Story 1 implementation (verification/consistency tasks)
- **User Story 3 (Phase 5)**: Can run in parallel with User Story 2 after User Story 1 complete
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: No dependencies - Core bug fix
- **User Story 2 (P2)**: Depends on User Story 1 (verifies consistency with US1 implementation)
- **User Story 3 (P3)**: Depends on User Story 1 (enhances output from US1 implementation)

### Within Each User Story

**User Story 1**:
- T001-T005: Implementation tasks in Invoke-PreUpdateValidation.ps1 (sequential - same file edits)
- T006: Pass parameter from orchestrator (different file, runs after T001-T005)
- T007-T013: Test tasks (can run after implementation, tests marked [P] can run in parallel)

**User Story 2**:
- T014-T016: Review/verification tasks (sequential)
- T017-T019: Test tasks (can run in parallel, marked [P])

**User Story 3**:
- T020-T027: Output enhancement tasks in Invoke-PreUpdateValidation.ps1 (sequential - same file, adjacent lines, or assign to single developer)
- T028-T030: Test tasks (can run in parallel, marked [P])

### Parallel Opportunities

- **Within User Story 1**: T008, T009, T010 (unit tests for different scenarios)
- **Within User Story 2**: T017, T018 (integration tests for different scenarios)
- **Within User Story 3**: T028, T029 (unit tests only - T020-T027 are sequential, same file)
- **Phase 6**: T031, T032, T033 (documentation updates to different files)
- **User Stories 2 and 3**: Can run in parallel after User Story 1 complete (but US3 implementation tasks T020-T027 must be sequential)

---

## Parallel Example: User Story 1 Implementation

```powershell
# After completing T001-T006 (implementation), launch these tests in parallel:
# Terminal 1:
Task: "Add unit test: validation helper accepts -Proceed parameter in tests/unit/Invoke-PreUpdateValidation.Tests.ps1"

# Terminal 2:
Task: "Add unit test: without -Proceed, installation detection exits with code 0 in tests/unit/Invoke-PreUpdateValidation.Tests.ps1"

# Terminal 3:
Task: "Add unit test: with -Proceed, installation detection continues in tests/unit/Invoke-PreUpdateValidation.Tests.ps1"
```

---

## Parallel Example: User Story 3 Output Formatting

```powershell
# IMPORTANT: T020-T027 modify adjacent lines in Invoke-PreUpdateValidation.ps1
# RECOMMENDED: Assign all to single developer to avoid merge conflicts
# ALTERNATIVE: If parallelizing, use feature branches and coordinate merging carefully

# Example sequential execution (single developer):
Task T020: "Update installation prompt to include exact command instruction"
Task T021: "Add cyan-colored [PROMPT_FOR_INSTALL] marker"
Task T022: "Add yellow warning text"
Task T023: "Add gray description text"
Task T024: "Add white command text"
Task T025: "Add verbose logging message for awaiting approval"
Task T026: "Add verbose logging message for proceeding"
Task T027: "Add progress indicator"

# Tests can run in parallel after implementation:
# Terminal 1: Task T028 (unit test for prompt elements)
# Terminal 2: Task T029 (unit test for verbose logging)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 3: User Story 1 (T001-T013)
2. **STOP and VALIDATE**: Run quickstart.md scenarios 1-3
3. Verify: Installation prompt shows once, `-Proceed` works, exit code is 0
4. This delivers the core bug fix - installations work!

### Incremental Delivery

1. Implement User Story 1 → Test independently → **Bug fix deployed** (MVP!)
2. Add User Story 2 → Test consistency → **Improved UX consistency**
3. Add User Story 3 → Test error handling → **Enhanced user guidance**
4. Each story adds value without breaking previous fixes

### Sequential Strategy (Single Developer)

1. Complete User Story 1 (T001-T013) - Core bug fix
2. Complete User Story 2 (T014-T019) - Consistency verification
3. Complete User Story 3 (T020-T030) - Output enhancement
4. Complete Polish (T031-T042) - Documentation, validation, and edge case testing
5. Total: 42 tasks, sequential execution

### Parallel Team Strategy

With multiple developers:

1. Developer A: User Story 1 (T001-T013) - **CRITICAL PATH**
2. Once T001-T006 complete:
   - Developer B: User Story 2 (T014-T019)
   - Developer C: User Story 3 (T020-T030)
3. All converge on Polish (T031-T042)

---

## Notes

- [P] tasks = different files or independent test scenarios, no dependencies
- [Story] label maps task to specific user story for traceability
- User Story 1 is MVP - delivers core bug fix
- User Story 2 validates consistency with existing update flow
- User Story 3 enhances user experience with better output
- All tests verify both success and error paths
- Exit code 0 (not throw) is critical for conversational workflow
- Reference implementation exists in update-orchestrator.ps1:381-409
- Bug report has complete proposed solution (docs/bugs/008-install-proceed-flag-ignored.md)
- Manual testing guide in specs/011-fix-install-proceed-flag/quickstart.md
