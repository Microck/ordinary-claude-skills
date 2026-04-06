# Tasks: Helpful Error Messages for Non-SpecKit Projects

**Input**: Design documents from `/specs/010-helpful-error-messages/`
**Prerequisites**: plan.md, spec.md, research.md, quickstart.md

**Tests**: Included per plan.md requirement (unit tests + integration tests)

**Organization**: Tasks are grouped by user story. Note: All three user stories are satisfied by the same core implementation but have different testing scenarios.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions
- PowerShell skill project structure: `scripts/`, `tests/` at repository root
- Helpers: `scripts/helpers/`
- Tests: `tests/unit/`, `tests/integration/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and understanding existing codebase

- [X] T001 Review existing error handling in scripts/helpers/Invoke-PreUpdateValidation.ps1 lines 44-48
- [X] T002 Review research.md decisions for implementation approach
- [X] T003 Review quickstart.md for detailed implementation guide and test scenarios
- [X] T004 Update CHANGELOG.md under [Unreleased] section with feature description

---

## Phase 2: Foundational (Core Implementation)

**Purpose**: Core helper functions that serve ALL user stories

**⚠️ CRITICAL**: This implementation satisfies all 3 user stories - the stories differ only in testing scenarios

**Conceptual Model Note**: The spec.md defines "Error Message Variant" and "Detection Result" entities to describe the two possible error messages (Commands Available vs Not Available variants). Tasks T005-T007 implement these as conditional logic within the Get-HelpfulSpecKitError function.

- [X] T005 [P] Add Test-SpecKitCommandsAvailable function to scripts/helpers/Invoke-PreUpdateValidation.ps1 after line 21
- [X] T006 [P] Add Get-HelpfulSpecKitError function (generates Error Message Variants) to scripts/helpers/Invoke-PreUpdateValidation.ps1 after Test-SpecKitCommandsAvailable
- [X] T007 Modify line 47 in scripts/helpers/Invoke-PreUpdateValidation.ps1 to call Get-HelpfulSpecKitError

**Checkpoint**: Core implementation complete - helper functions can generate context-aware error messages

---

## Phase 3: User Story 1 - First-Time User Discovery (Priority: P1) 🎯 MVP

**Goal**: First-time users who discover the updater before SpecKit get helpful, educational error messages

**Independent Test**: Run `/speckit-update` in non-SpecKit project with SpecKit commands installed, verify error explains what SpecKit is and suggests `/speckit.constitution`

### Tests for User Story 1

**NOTE: Write these tests FIRST, ensure they FAIL before implementation (Tasks T005-T007)**

- [X] T008 [P] [US1] Add unit test context for Test-SpecKitCommandsAvailable in tests/unit/Invoke-PreUpdateValidation.Tests.ps1
- [X] T009 [P] [US1] Add test case for commands available scenario in tests/unit/Invoke-PreUpdateValidation.Tests.ps1
- [X] T010 [P] [US1] Add test case for commands not available scenario in tests/unit/Invoke-PreUpdateValidation.Tests.ps1
- [X] T011 [P] [US1] Add test case for empty commands directory in tests/unit/Invoke-PreUpdateValidation.Tests.ps1

### Implementation Validation for User Story 1

- [X] T012 [US1] Add unit test context for Get-HelpfulSpecKitError in tests/unit/Invoke-PreUpdateValidation.Tests.ps1
- [X] T013 [US1] Add test case for error message with /speckit.constitution suggestion in tests/unit/Invoke-PreUpdateValidation.Tests.ps1
- [X] T014 [US1] Add test case for error message with documentation link in tests/unit/Invoke-PreUpdateValidation.Tests.ps1
- [X] T015 [US1] Add test case for fallback message when detection fails in tests/unit/Invoke-PreUpdateValidation.Tests.ps1
- [X] T016 [US1] Add integration test for non-SpecKit project scenario in tests/integration/UpdateOrchestrator.Tests.ps1
- [X] T017 [US1] Run unit tests and verify all pass using tests/test-runner.ps1 -Unit
- [X] T018 [US1] Verify error message includes SpecKit explanation per acceptance scenario 1
- [X] T019 [US1] Verify error message provides /speckit.constitution command per acceptance scenario 2

**Checkpoint**: User Story 1 is fully functional - first-time users get helpful error messages with educational context

---

## Phase 4: User Story 2 - Experienced Developer with Uninitialized Project (Priority: P2)

**Goal**: Experienced developers get quick reminder of initialization command

**Independent Test**: Run `/speckit-update` in uninitialized project with SpecKit installed, verify error provides exact `/speckit.constitution` command

### Tests for User Story 2

- [ ] T020 [P] [US2] Manual test: Verify error message is scannable (findable within 3 seconds) per acceptance scenario 1
- [ ] T021 [P] [US2] Manual test: Verify /speckit.constitution command is prominently displayed per acceptance scenario 2
- [ ] T022 [US2] Manual test: Initialize SpecKit and re-run updater to confirm success per acceptance scenario 3

**Checkpoint**: User Story 2 validated - experienced developers can quickly find initialization command

---

## Phase 5: User Story 3 - Developer Evaluating SpecKit (Priority: P3)

**Goal**: Developers evaluating SpecKit can easily find documentation

**Independent Test**: Run `/speckit-update` without SpecKit installed, verify error includes stable documentation link

### Tests for User Story 3

- [ ] T023 [P] [US3] Manual test: Verify documentation link is present when SpecKit not installed per acceptance scenario 1
- [ ] T024 [P] [US3] Manual test: Navigate to documentation link and verify it reaches SpecKit repository per acceptance scenario 2
- [ ] T025 [US3] Manual test: Compare both error variants to verify clear distinction between states per acceptance scenario 3

**Checkpoint**: All user stories validated - error messages serve first-time users, experienced developers, and evaluators

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, edge case testing, and documentation

- [ ] T026 [P] Edge case test: Verify behavior when .claude/commands directory doesn't exist
- [ ] T027 [P] Edge case test: Verify behavior when partial SpecKit installation exists (only 1 command file)
- [ ] T028 [P] Edge case test: Verify behavior when permissions deny access to .claude/commands
- [ ] T029 [P] Edge case test: Verify error message renders correctly in terminal context
- [ ] T030 [P] Edge case test: Verify error message renders correctly in Claude Code extension context
- [ ] T031 Regression test: Verify normal SpecKit project behavior unchanged (no error when .specify/ exists)
- [ ] T032 Run integration tests and verify all pass using tests/test-runner.ps1 -Integration
- [ ] T033 Run all tests together using tests/test-runner.ps1
- [ ] T034 Review error message wording against Success Criteria SC-004 (clarity score 8+/10)
- [ ] T035 [P] Review CHANGELOG.md entry for completeness and accuracy
- [ ] T036 Final validation: Run quickstart.md testing checklist

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup (T001-T004) - BLOCKS all user story testing
- **User Stories (Phase 3-5)**: All depend on Foundational phase (T005-T007) completion
  - US1 (P1) testing can start after Foundational implementation
  - US2 (P2) manual testing can start after US1 completes
  - US3 (P3) manual testing can start after US2 completes
  - Or: US2 and US3 manual tests can run in parallel after US1
- **Polish (Phase 6)**: Depends on all user stories being validated

### User Story Dependencies

**CRITICAL NOTE**: All three user stories share the SAME implementation (Tasks T005-T007). They differ only in testing scenarios:

- **User Story 1 (P1)**: Commands available scenario (first-time user) + unit/integration tests
- **User Story 2 (P2)**: Commands available scenario (experienced user) + manual UX validation
- **User Story 3 (P3)**: Commands not available scenario (evaluator) + documentation link validation

### Within Each Phase

**Phase 2 (Foundational)**:
- T005 and T006 can run in parallel (different functions)
- T007 depends on T005 and T006 (modifies line to call new functions)

**Phase 3 (US1 Tests)**:
- T008-T011 can all run in parallel (different test contexts, write tests first)
- T012-T016 must wait for implementation (T005-T007)
- T017-T019 are validation steps after tests pass

**Phase 4 (US2 Manual Tests)**:
- T020-T021 can run in parallel (independent manual checks)
- T022 is sequential (requires action then re-test)

**Phase 5 (US3 Manual Tests)**:
- T023-T024 can run in parallel (independent checks)
- T025 requires both variants tested

**Phase 6 (Polish)**:
- T026-T030 can all run in parallel (independent edge case tests)
- T031-T033 are sequential test runs
- T034-T036 can run in parallel (documentation review)

### Parallel Opportunities

**Maximum parallelization example**:

1. **Phase 1**: T001-T004 can all be reviewed/updated in parallel
2. **Phase 2**: T005 and T006 in parallel, then T007
3. **Phase 3**: T008-T011 all in parallel (write failing tests), then T012-T016 after implementation
4. **Phase 4-5**: T020-T025 can all run in parallel (all manual tests)
5. **Phase 6**: T026-T030 in parallel, then T034-T036 in parallel

---

## Parallel Example: Phase 3 (User Story 1)

```bash
# Launch all test setup tasks together:
Task: "Add unit test context for Test-SpecKitCommandsAvailable in tests/unit/Invoke-PreUpdateValidation.Tests.ps1"
Task: "Add test case for commands available scenario in tests/unit/Invoke-PreUpdateValidation.Tests.ps1"
Task: "Add test case for commands not available scenario in tests/unit/Invoke-PreUpdateValidation.Tests.ps1"
Task: "Add test case for empty commands directory in tests/unit/Invoke-PreUpdateValidation.Tests.ps1"

# After implementation (T005-T007), launch validation tests:
Task: "Add unit test context for Get-HelpfulSpecKitError in tests/unit/Invoke-PreUpdateValidation.Tests.ps1"
Task: "Add test case for error message with /speckit.constitution suggestion in tests/unit/Invoke-PreUpdateValidation.Tests.ps1"
Task: "Add test case for error message with documentation link in tests/unit/Invoke-PreUpdateValidation.Tests.ps1"
Task: "Add test case for fallback message when detection fails in tests/unit/Invoke-PreUpdateValidation.Tests.ps1"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T004) - ~15 minutes
2. Complete Phase 2: Foundational (T005-T007) - ~30 minutes
3. Complete Phase 3: User Story 1 (T008-T019) - ~45 minutes
4. **STOP and VALIDATE**: Verify error messages work for first-time users
5. **MVP COMPLETE**: Core functionality working with test coverage

**Total MVP Time**: ~1.5 hours

### Incremental Delivery

1. **MVP (US1)**: First-time users get helpful errors → Test independently → Commit
2. **US2 Addition**: Validate experienced user scenario → Manual test → Commit
3. **US3 Addition**: Validate evaluator scenario → Manual test → Commit
4. **Polish**: Edge cases + final validation → Full test suite → Final commit

### Single Developer Strategy

**Day 1**:
- Morning: T001-T007 (Setup + Foundational) → MVP implementation complete
- Afternoon: T008-T019 (US1 testing) → MVP validated
- End of Day: Working feature with test coverage

**Day 2** (optional):
- Morning: T020-T025 (US2 + US3 manual tests) → All stories validated
- Afternoon: T026-T036 (Polish + edge cases) → Production-ready

**Total Estimated Time**: 1-2 hours for MVP, 3-4 hours for complete feature

---

## Notes

- **[P] tasks** = different files, no dependencies - can run in parallel
- **[Story] label** maps task to specific user story for traceability
- **All user stories share same implementation** - testing validates different scenarios
- PowerShell functions use comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`)
- Follow PowerShell naming: `Get-`, `Test-` verbs; camelCase variables
- Error messages use here-strings for multi-line formatting
- Try-catch blocks for graceful fallback on detection errors
- See quickstart.md for detailed implementation code and test examples
- Commit after completing each phase
- Avoid: modifying orchestrator (not needed), adding new modules (helpers only), GUI assumptions

## Task Summary

**Total Tasks**: 36
- Phase 1 (Setup): 4 tasks
- Phase 2 (Foundational): 3 tasks
- Phase 3 (US1): 12 tasks
- Phase 4 (US2): 3 tasks
- Phase 5 (US3): 3 tasks
- Phase 6 (Polish): 11 tasks

**Parallelizable Tasks**: 23 tasks marked [P]

**Test Coverage**:
- Unit tests: 8 test cases across 2 function contexts
- Integration tests: 1 end-to-end scenario
- Manual tests: 6 scenarios (UX, documentation, edge cases)
- Edge case tests: 6 scenarios

**Files Modified**: 3
- scripts/helpers/Invoke-PreUpdateValidation.ps1
- tests/unit/Invoke-PreUpdateValidation.Tests.ps1
- tests/integration/UpdateOrchestrator.Tests.ps1
- CHANGELOG.md

**Files Created**: 0 (pure enhancement)

**MVP Scope**: Phase 1-3 (Tasks T001-T019) delivers core functionality with automated test coverage
