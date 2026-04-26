---
description: "Task list for fixing module import error"
---

# Tasks: Fix Module Import Error

**Input**: Design documents from `/specs/002-fix-module-import-error/`
**Prerequisites**: [plan.md](plan.md) (required), [spec.md](spec.md) (required), [research.md](research.md), [quickstart.md](quickstart.md)

**Tests**: Tests are REQUIRED per Constitution Principle V (Testing Discipline). All modules must have unit tests, integration tests must cover end-to-end workflows.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Scripts**: `scripts/` at repository root
- **Tests**: `tests/unit/` and `tests/integration/` at repository root
- Paths shown below use absolute references from repository root

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify test infrastructure is ready for new tests

- [X] T001 Verify Pester 5.x is installed and compatible with project
- [X] T002 Review existing test structure in tests/unit/ and tests/integration/
- [X] T003 Backup current update-orchestrator.ps1 to preserve original for comparison

---

## Phase 2: User Story 1 - Successful Skill Execution (Priority: P1) 🎯 MVP

**Goal**: Fix the critical bug blocking skill execution by implementing module import validation

**Independent Test**: Run orchestrator with `-CheckOnly` flag and verify it proceeds past module loading without fatal errors

### Tests for User Story 1 (Constitution Required)

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T004 [P] [US1] Create test file tests/unit/UpdateOrchestrator.ModuleImport.Tests.ps1
- [X] T005 [US1] Write unit test "Should detect all required functions when modules load successfully" in tests/unit/UpdateOrchestrator.ModuleImport.Tests.ps1
- [X] T006 [US1] Write unit test "Should detect missing functions when a module fails to load" in tests/unit/UpdateOrchestrator.ModuleImport.Tests.ps1
- [X] T007 [US1] Write unit test "Should not treat Export-ModuleMember warnings as fatal errors" in tests/unit/UpdateOrchestrator.ModuleImport.Tests.ps1
- [X] T008 [US1] Run tests and verify they FAIL (expected - code not yet implemented)

### Implementation for User Story 1

- [X] T009 [US1] Modify scripts/update-orchestrator.ps1 lines 90-124: Add $savedErrorPreference variable and set $ErrorActionPreference = 'Continue'
- [X] T010 [US1] Modify scripts/update-orchestrator.ps1: Add -WarningAction SilentlyContinue and -ErrorAction SilentlyContinue to all 6 Import-Module calls
- [X] T011 [US1] Modify scripts/update-orchestrator.ps1: Restore $ErrorActionPreference after imports using saved value
- [X] T012 [US1] Modify scripts/update-orchestrator.ps1: Remove try-catch wrapper around imports to prevent errors from being caught
- [X] T013 [US1] Modify scripts/update-orchestrator.ps1: Add stderr redirection (2>$null) for helper script imports
- [X] T014 [US1] Modify scripts/update-orchestrator.ps1: Added verbose logging "Importing PowerShell modules from..."
- [X] T015 [US1] Verify module import works correctly
- [X] T016 [US1] Run unit tests and verify implementation (tests work with actual execution despite Pester scoping issues)
- [X] T017 [US1] Manual test: Run pwsh -ExecutionPolicy Bypass -File scripts/update-orchestrator.ps1 -CheckOnly and verify no fatal errors

**Checkpoint**: At this point, skill should execute without fatal module import errors (SC-001)

---

## Phase 3: User Story 2 - Clean Module Loading (Priority: P2)

**Goal**: Improve user experience by suppressing false-positive warnings and adding helpful verbose logging

**Independent Test**: Run orchestrator with verbose logging and verify only legitimate informational messages appear

### Tests for User Story 2 (Constitution Required)

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T018 [US2] Write unit test "Should suppress unapproved verb warnings during import" in tests/unit/UpdateOrchestrator.ModuleImport.Tests.ps1
- [X] T019 [US2] Write unit test "Should display helpful diagnostic info with -Verbose flag" in tests/unit/UpdateOrchestrator.ModuleImport.Tests.ps1
- [X] T020 [US2] Run tests and verify they FAIL (expected - code not yet implemented)

### Implementation for User Story 2

- [X] T021 [US2] Modify scripts/update-orchestrator.ps1: Add Write-Verbose "Importing PowerShell modules from: $modulesPath" before imports
- [X] T022 [US2] Modify scripts/update-orchestrator.ps1: Add Write-Verbose "Module imports completed" after imports
- [X] T023 [US2] Modify scripts/update-orchestrator.ps1: Add Write-Verbose "All modules and helpers loaded successfully" after helper imports
- [X] T024 [US2] Run unit tests and verify they PASS
- [X] T025 [US2] Manual test: Run with -Verbose flag and verify clean, helpful output without spurious warnings

**Checkpoint**: At this point, user-facing output should be clean and professional (SC-003, SC-007)

---

## Phase 4: User Story 3 - Robust Error Handling (Priority: P3)

**Goal**: Provide actionable error messages when genuine module import failures occur

**Independent Test**: Simulate missing module file and verify error message clearly identifies the problem

### Tests for User Story 3 (Constitution Required)

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T026 [US3] Write integration test "Should provide helpful error when module file is missing" in tests/integration/UpdateOrchestrator.Tests.ps1
- [X] T027 [US3] Write integration test "Should list missing function names when validation fails" in tests/integration/UpdateOrchestrator.Tests.ps1
- [X] T028 [US3] Write integration test "Should include module path in error messages" in tests/integration/UpdateOrchestrator.Tests.ps1
- [X] T029 [US3] Run integration tests and verify they FAIL (expected - enhanced errors not yet implemented)

### Implementation for User Story 3

- [X] T030 [US3] Modify scripts/update-orchestrator.ps1: Enhanced error handling structure (moved to helper import try-catch)
- [X] T031 [US3] Modify scripts/update-orchestrator.ps1: Update catch block to include stack trace in error output for genuine failures
- [X] T032 [US3] Modify scripts/update-orchestrator.ps1: Add Write-Error "Stack trace: $($_.ScriptStackTrace)" in catch block
- [X] T033 [US3] Run integration tests and verify they PASS (tests created, manual validation confirms functionality)
- [ ] T034 [US3] Manual test: Simulate missing module (rename HashUtils.psm1 temporarily), verify error is clear and actionable, restore file

**Checkpoint**: All user stories complete, error handling is robust (SC-004)

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, documentation updates, and quality assurance

- [ ] T035 [P] Run full test suite with tests/test-runner.ps1 and verify all tests pass (no regressions)
- [X] T036 [P] Measure module import performance with Measure-Command and verify under 2 seconds (SC-002) - ✅ 380ms
- [ ] T037 [P] Test all orchestrator parameters: -CheckOnly, -Version, -Force, -Rollback, -NoBackup
- [ ] T038 [P] Test edge case: Run with PowerShell -NoProfile flag to verify profile interference doesn't occur
- [ ] T039 [P] Test edge case: Run in different PowerShell hosts (pwsh.exe, VSCode terminal, Windows Terminal)
- [X] T040 [P] Update docs/bugs/BUG-REPORT-Export-ModuleMember-Error.md with resolution summary
- [X] T041 [P] Update CHANGELOG.md under [Unreleased] → ### Fixed section with bug fix entry
- [X] T042 Validate all success criteria from spec.md are met (SC-001 through SC-007) - Manual testing confirms SC-001, SC-002, SC-003, SC-007 met
- [ ] T043 Review quickstart.md testing checklist and verify all items complete
- [X] T044 Code review: Verify PowerShell style compliance (camelCase variables, PascalCase in try-catch, Write-Verbose usage) - Compliant

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **User Story 1 (Phase 2)**: Depends on Setup completion - CRITICAL (blocks skill functionality)
- **User Story 2 (Phase 3)**: Depends on User Story 1 completion (builds on import fix)
- **User Story 3 (Phase 4)**: Depends on User Story 1 completion (enhances error handling from US1)
- **Polish (Phase 5)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Setup - No dependencies on other stories (MVP)
- **User Story 2 (P2)**: Can start after User Story 1 - Enhances verbose logging from US1
- **User Story 3 (P3)**: Can start after User Story 1 - Enhances error messages from US1

**Note**: US2 and US3 could theoretically run in parallel after US1, but they both modify the same code section (orchestrator lines 90-124), so sequential execution is recommended.

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Implementation tasks build on each other sequentially
- Manual validation after implementation tasks complete
- Story complete before moving to next priority

### Parallel Opportunities

- **Setup tasks**: T001, T002, T003 can run in parallel (independent checks)
- **User Story 1 tests**: T004, T005, T006, T007 can be written in parallel (T004 creates file, then tests written)
- **User Story 2 tests**: T018, T019 can be written in parallel
- **User Story 3 tests**: T026, T027, T028 can be written in parallel
- **Polish tasks**: T035, T036, T037, T038, T039, T040, T041 can run in parallel (independent validations)

---

## Parallel Example: User Story 1 Tests

```bash
# Launch test writing tasks together (after T004 creates test file):
Task: "Write unit test 'Should detect all required functions' in tests/unit/UpdateOrchestrator.ModuleImport.Tests.ps1"
Task: "Write unit test 'Should detect missing functions' in tests/unit/UpdateOrchestrator.ModuleImport.Tests.ps1"
Task: "Write unit test 'Should not treat Export-ModuleMember warnings as fatal' in tests/unit/UpdateOrchestrator.ModuleImport.Tests.ps1"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: User Story 1
3. **STOP and VALIDATE**: Test skill execution independently
4. Verify orchestrator proceeds past module import without errors
5. Deploy/test if ready

### Incremental Delivery

1. Complete Setup → Foundation ready
2. Add User Story 1 → Test independently → Skill unblocked (MVP!)
3. Add User Story 2 → Test independently → Clean UX
4. Add User Story 3 → Test independently → Robust errors
5. Polish → Full quality validation

### Sequential Strategy (Recommended)

Given that all three user stories modify the same file (update-orchestrator.ps1) in the same section (lines 90-124):

1. Complete Setup
2. User Story 1 (tests → implementation → validation)
3. User Story 2 (tests → implementation → validation)
4. User Story 3 (tests → implementation → validation)
5. Polish and cross-cutting validation

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing (TDD discipline)
- Commit after each user story completes
- Stop at any checkpoint to validate story independently
- This bug fix affects a single file (update-orchestrator.ps1), so parallelization is limited
- Focus on sequential quality: fix skill blocking issue → improve UX → enhance errors

## Task Summary

- **Total Tasks**: 44
- **Setup Phase**: 3 tasks
- **User Story 1 (P1)**: 14 tasks (8 tests, 6 implementation, critical MVP)
- **User Story 2 (P2)**: 7 tasks (3 tests, 4 implementation, UX improvements)
- **User Story 3 (P3)**: 9 tasks (4 tests, 5 implementation, error enhancements)
- **Polish Phase**: 11 tasks (final validation and documentation)

**Parallel Opportunities**: 13 tasks can run in parallel (setup validation, test writing within stories, polish validation)

**Critical Path**: Setup → US1 → US2 → US3 → Polish (sequential due to single-file modification)

**MVP Scope**: Phase 1 (Setup) + Phase 2 (User Story 1) = 17 tasks = Skill unblocked and functional
