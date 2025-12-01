# Tasks: Fix Fatal Module Import Error

**Input**: Design documents from `specs/003-fix-module-import-error/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: This feature includes test tasks to validate the fix and prevent regression.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions
- PowerShell skill structure: `scripts/modules/`, `scripts/helpers/`, `tests/`
- Paths are relative to repository root

---

## Phase 1: Setup (Prerequisites Verification)

**Purpose**: Verify environment and prerequisites before making changes

- [ ] T001 Verify PowerShell 7.0+ installed and accessible
- [ ] T002 Verify Git working directory is clean (or commit/stash changes)
- [ ] T003 [P] Create backup of all 7 helper scripts before modification
- [ ] T004 [P] Create backup of scripts/update-orchestrator.ps1 before modification
- [ ] T005 Verify test framework (Pester 5.x) is available

---

## Phase 2: Foundational (Core Fix - Blocking Prerequisites)

**Purpose**: Fix the root architectural issue that blocks all user stories

**⚠️ CRITICAL**: These tasks MUST be complete before ANY user story can be validated

### Remove Export-ModuleMember from Helper Scripts (Root Cause Fix)

- [X] T006 [P] Remove Export-ModuleMember line from scripts/helpers/Invoke-PreUpdateValidation.ps1 (line 180)
- [X] T007 [P] Remove Export-ModuleMember line from scripts/helpers/Show-UpdateSummary.ps1 (line 159)
- [X] T008 [P] Remove Export-ModuleMember line from scripts/helpers/Show-UpdateReport.ps1 (line 170)
- [X] T009 [P] Remove Export-ModuleMember line from scripts/helpers/Get-UpdateConfirmation.ps1 (line 136)
- [X] T010 [P] Remove Export-ModuleMember line from scripts/helpers/Invoke-ConflictResolutionWorkflow.ps1 (line 216)
- [X] T011 [P] Remove Export-ModuleMember line from scripts/helpers/Invoke-ThreeWayMerge.ps1 (line 182)
- [X] T012 [P] Remove Export-ModuleMember line from scripts/helpers/Invoke-RollbackWorkflow.ps1 (line 196)

### Simplify Orchestrator Import Logic

- [X] T013 Simplify module import logic in scripts/update-orchestrator.ps1 (lines 90-136) to remove error suppression workarounds
- [X] T014 Ensure orchestrator retains -WarningAction SilentlyContinue for unapproved verb warnings in scripts/update-orchestrator.ps1
- [X] T015 Add proper try-catch blocks with stack trace logging to scripts/update-orchestrator.ps1 import sections
- [X] T016 Add verbose logging messages for module and helper loading progress in scripts/update-orchestrator.ps1

**Checkpoint**: Foundation ready - helper scripts no longer have Export-ModuleMember, orchestrator uses clean import pattern

---

## Phase 3: User Story 1 - Skill Executes Without Fatal Errors (Priority: P1) 🎯 MVP

**Goal**: Skill executes successfully when invoked through Claude Code without fatal module import errors

**Independent Test**: Run `/speckit-update -CheckOnly` in Claude Code and verify it completes without "Export-ModuleMember cmdlet can only be called from inside a module" errors

### Validation for User Story 1

- [X] T017 [US1] Manual test: Run update-orchestrator.ps1 -CheckOnly and verify no fatal errors
- [X] T018 [US1] Manual test: Verify all 6 modules load successfully without errors
- [X] T019 [US1] Manual test: Verify all 7 helpers load successfully without errors
- [X] T020 [US1] Manual test: Verify orchestrator proceeds to main workflow (prerequisite validation)

### Unit Tests for User Story 1

- [ ] T021 [P] [US1] Extend tests/unit/UpdateOrchestrator.ModuleImport.Tests.ps1 to verify modules load without errors
- [ ] T022 [P] [US1] Add test to tests/unit/UpdateOrchestrator.ModuleImport.Tests.ps1 to verify helpers load without errors
- [ ] T023 [P] [US1] Add test to tests/unit/UpdateOrchestrator.ModuleImport.Tests.ps1 to verify all required functions are available

### Integration Tests for User Story 1

- [ ] T024 [US1] Extend tests/integration/UpdateOrchestrator.Tests.ps1 to test full orchestrator execution with -CheckOnly parameter
- [ ] T025 [US1] Add integration test to tests/integration/UpdateOrchestrator.Tests.ps1 for -Version parameter
- [ ] T026 [US1] Add integration test to tests/integration/UpdateOrchestrator.Tests.ps1 for -Force parameter

**Checkpoint**: At this point, User Story 1 (basic execution without errors) should be fully functional and testable independently

---

## Phase 4: User Story 2 - Clean Module Loading with Helpful Diagnostics (Priority: P2)

**Goal**: Clean module loading without spurious errors in normal output, with verbose diagnostic information when requested

**Independent Test**: Run skill with and without `-Verbose` flag and verify normal output is clean while verbose mode provides diagnostic information

### Implementation for User Story 2

- [ ] T027 [US2] Verify verbose logging messages are clear and helpful in scripts/update-orchestrator.ps1
- [ ] T028 [US2] Ensure no false-positive errors appear in normal output (non-verbose mode)
- [ ] T029 [US2] Verify unapproved verb warnings are suppressed in normal output

### Testing for User Story 2

- [ ] T030 [P] [US2] Manual test: Run update-orchestrator.ps1 -CheckOnly (without -Verbose) and verify zero error messages in output
- [ ] T031 [P] [US2] Manual test: Run update-orchestrator.ps1 -CheckOnly -Verbose and verify helpful diagnostic messages appear
- [ ] T032 [US2] Add unit test to tests/unit/UpdateOrchestrator.ModuleImport.Tests.ps1 to verify verbose output contains expected messages
- [ ] T033 [US2] Add integration test to tests/integration/UpdateOrchestrator.Tests.ps1 to verify clean output in normal mode

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently - basic execution works AND output is clean/helpful

---

## Phase 5: User Story 3 - Robust Error Handling with Clear Diagnostics (Priority: P3)

**Goal**: Maintain strict error handling for real errors while tolerating benign import issues

**Independent Test**: Introduce intentional errors in various parts of the workflow and verify that real errors are caught with stack traces while benign import issues are tolerated

### Implementation for User Story 3

- [ ] T034 [US3] Verify error handling in scripts/update-orchestrator.ps1 catches real errors with proper stack traces
- [ ] T035 [US3] Ensure $ErrorActionPreference is properly restored after imports in scripts/update-orchestrator.ps1
- [ ] T036 [US3] Verify strict error handling applies to main workflow (post-import) in scripts/update-orchestrator.ps1

### Negative Testing for User Story 3

- [ ] T037 [US3] Create negative test: Introduce syntax error in a module file and verify orchestrator fails fatally (not suppressed)
- [ ] T038 [US3] Create negative test: Introduce syntax error in a helper file and verify orchestrator fails fatally (not suppressed)
- [ ] T039 [US3] Create negative test: Simulate missing module file and verify proper error message with stack trace
- [ ] T040 [US3] Add unit test to tests/unit/UpdateOrchestrator.ModuleImport.Tests.ps1 to verify real errors cause fatal exit
- [ ] T041 [US3] Verify error messages include actionable information (file path, operation attempted)

### Performance Validation for User Story 3

- [ ] T042 [US3] Measure module import duration with Measure-Command and verify < 2 seconds (SC-002)
- [ ] T043 [US3] Add performance test to tests/unit/UpdateOrchestrator.ModuleImport.Tests.ps1 if not already present

**Checkpoint**: All user stories should now be independently functional - execution works, output is clean, error handling is robust

**Edge Case Coverage** (from spec.md):
- ✅ PowerShell modules fail due to actual syntax errors → Validated by T037
- ✅ Different PowerShell hosts (pwsh.exe vs VSCode terminal) → Validated by T058
- ✅ Modules already loaded from previous run → Implicitly covered by T017-T020 (orchestrator handles reloads)
- ✅ Different execution policies → Validated by T001 (prerequisites check)
- ✅ Helper scripts contain actual errors → Validated by T038

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, prevention mechanisms, and final validation

### Documentation Updates

- [X] T044 [P] Add "Module vs. Helper Pattern" section to CLAUDE.md under "Architecture" heading
- [X] T045 [P] Update CHANGELOG.md with fix details under [Unreleased] → Fixed section
- [X] T046 [P] Document the fix rationale (architectural correction, not just error suppression) in CHANGELOG.md

### Regression Prevention

- [X] T047 [P] Create new file tests/unit/CodeStandards.Tests.ps1 with Pester test to enforce no Export-ModuleMember in helper scripts
- [X] T048 [P] Add test to tests/unit/CodeStandards.Tests.ps1 to verify modules still have Export-ModuleMember
- [X] T049 Update CONTRIBUTING.md with PowerShell-specific PR checklist items (module vs. helper pattern)

### Template Creation (Future Prevention)

- [X] T050 [P] Create templates/helper-template.ps1 with correct pattern (no Export-ModuleMember)
- [X] T051 [P] Create templates/module-template.psm1 with correct pattern (with Export-ModuleMember)

### Final Validation

- [X] T052 Run full test suite: ./tests/test-runner.ps1 and verify all tests pass
- [X] T053 Run quickstart.md Test 1-3 (basic execution with all parameters)
- [X] T054 Run quickstart.md Test 4-5 (verify no Export-ModuleMember in helpers, still in modules)
- [X] T055 Run quickstart.md Test 6 (function availability check)
- [X] T056 Run quickstart.md Test 7 (performance measurement < 2 seconds)
- [X] T057 Run quickstart.md Test 8 (negative test - real errors still fatal)
- [ ] T058 Test in actual Claude Code environment with /speckit-update command

### Code Cleanup

- [X] T059 Remove backup files created in Phase 1 (if tests pass)
- [X] T060 Review all modified files for code quality and consistency
- [X] T061 Verify no debugging code or comments left in final version

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - User stories can proceed sequentially in priority order (P1 → P2 → P3)
  - Or if staffed, US1 tasks can run while US2/US3 validation is prepared
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start validation after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Builds on US1 success (basic execution must work first)
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Validates error handling that US1/US2 rely on

### Within Each Phase

**Foundational (Phase 2)**:
- T006-T012 (helper modifications) can run in parallel
- T013-T016 (orchestrator modifications) must run sequentially after helpers
- Orchestrator changes depend on helpers being fixed first

**User Story 1 (Phase 3)**:
- T021-T023 (unit tests) can run in parallel
- T024-T026 (integration tests) run sequentially (each depends on orchestrator working)

**User Story 2 (Phase 4)**:
- T030-T031 (manual tests) can run in parallel
- T032-T033 (automated tests) run after manual validation

**User Story 3 (Phase 5)**:
- T037-T039 (negative tests) can run in parallel
- T040-T041 (test automation) run after negative tests validated

**Polish (Phase 6)**:
- T044-T046 (documentation) can run in parallel
- T047-T049 (prevention) can run in parallel
- T050-T051 (templates) can run in parallel
- T052-T058 (final validation) run sequentially
- T059-T061 (cleanup) run last

### Parallel Opportunities

**Phase 2 (Foundational)**:
- All 7 helper modifications (T006-T012) in parallel - different files

**Phase 3 (US1)**:
- Unit tests T021-T023 in parallel - different test cases in same file but can write concurrently
- Integration tests run sequentially (each tests full workflow)

**Phase 4 (US2)**:
- Manual tests T030-T031 in parallel - different command invocations

**Phase 5 (US3)**:
- Negative tests T037-T039 in parallel - different error scenarios

**Phase 6 (Polish)**:
- Documentation tasks T044-T046 in parallel - different files
- Prevention tasks T047-T049 in parallel - different files
- Template tasks T050-T051 in parallel - different files

---

## Parallel Example: Foundational Phase (Core Fix)

```bash
# Launch all helper modifications in parallel (7 tasks):
Task: "Remove Export-ModuleMember from scripts/helpers/Invoke-PreUpdateValidation.ps1"
Task: "Remove Export-ModuleMember from scripts/helpers/Show-UpdateSummary.ps1"
Task: "Remove Export-ModuleMember from scripts/helpers/Show-UpdateReport.ps1"
Task: "Remove Export-ModuleMember from scripts/helpers/Get-UpdateConfirmation.ps1"
Task: "Remove Export-ModuleMember from scripts/helpers/Invoke-ConflictResolutionWorkflow.ps1"
Task: "Remove Export-ModuleMember from scripts/helpers/Invoke-ThreeWayMerge.ps1"
Task: "Remove Export-ModuleMember from scripts/helpers/Invoke-RollbackWorkflow.ps1"

# Then sequentially modify orchestrator:
Task: "Simplify module import logic in scripts/update-orchestrator.ps1"
# (depends on all helpers being fixed)
```

---

## Parallel Example: User Story 1 (Basic Execution)

```bash
# Launch all unit tests in parallel (3 tasks):
Task: "Add test to verify modules load without errors"
Task: "Add test to verify helpers load without errors"
Task: "Add test to verify all required functions available"
```

---

## Parallel Example: Polish Phase (Documentation)

```bash
# Launch all documentation tasks in parallel (3 tasks):
Task: "Add Module vs. Helper Pattern section to CLAUDE.md"
Task: "Update CHANGELOG.md with fix details"
Task: "Document fix rationale in CHANGELOG.md"

# Launch all prevention tasks in parallel (3 tasks):
Task: "Create CodeStandards.Tests.ps1 with pattern enforcement"
Task: "Add test to verify modules have Export-ModuleMember"
Task: "Update CONTRIBUTING.md with PR checklist"

# Launch all template tasks in parallel (2 tasks):
Task: "Create templates/helper-template.ps1"
Task: "Create templates/module-template.psm1"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (verify environment) - ~5 minutes
2. Complete Phase 2: Foundational (remove Export-ModuleMember, simplify orchestrator) - ~15 minutes
3. Complete Phase 3: User Story 1 (validation and basic tests) - ~20 minutes
4. **STOP and VALIDATE**: Run quickstart.md tests 1-3, verify skill executes without errors
5. **MVP COMPLETE**: Skill is now functional - can be deployed/demoed

**Total MVP Time**: ~40 minutes for core functionality

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready (~20 min)
2. Add User Story 1 → Test independently → **MVP Deliverable** (~20 min)
3. Add User Story 2 → Test independently → **Enhanced Output Quality** (~15 min)
4. Add User Story 3 → Test independently → **Robust Error Handling** (~20 min)
5. Add Polish → Documentation + Prevention → **Production Ready** (~30 min)

**Total Time**: ~105 minutes (1.75 hours) for complete feature with all stories and polish

### Sequential Implementation Strategy

Recommended approach for single developer:

1. **Phase 1** (Setup): T001-T005 - Verify environment
2. **Phase 2** (Foundational): T006-T016 - Core fix
   - T006-T012 can be done in parallel if using multiple editor windows
   - T013-T016 must be sequential (orchestrator changes)
3. **Phase 3** (US1): T017-T026 - MVP validation
   - Manual tests first (T017-T020)
   - Then automated tests (T021-T026)
4. **Phase 4** (US2): T027-T033 - Clean output
5. **Phase 5** (US3): T034-T043 - Error handling
6. **Phase 6** (Polish): T044-T061 - Documentation and prevention

### Parallel Team Strategy

With 2-3 developers:

1. **All together**: Complete Phase 1 + Phase 2 (foundation is critical)
2. **Once foundation is done**:
   - **Developer A**: Phase 3 (US1 validation + tests)
   - **Developer B**: Phase 4 (US2 validation + tests)
   - **Developer C**: Phase 6 documentation tasks (T044-T051)
3. **Converge**: Phase 5 (US3 - one person), then final validation together (T052-T061)

---

## Success Criteria Validation

Each user story maps to success criteria from spec.md:

**User Story 1 (P1 - Basic Execution)**:
- SC-001: Skill executes successfully 100% of the time → Validated by T017-T020
- SC-002: Module import < 2 seconds → Validated by T042
- SC-004: All parameters function correctly → Validated by T024-T026

**User Story 2 (P2 - Clean Output)**:
- SC-003: Zero false-positive errors in normal output → Validated by T030
- SC-007: Verbose mode provides diagnostic information → Validated by T031

**User Story 3 (P3 - Error Handling)**:
- SC-006: Real errors produce clear messages with stack traces → Validated by T037-T041
- SC-005: Works across different PowerShell hosts → Validated by T058

---

## Notes

- [P] tasks = different files, no dependencies - can run in parallel
- [Story] label maps task to specific user story (US1, US2, US3) for traceability
- Each user story should be independently completable and testable
- Verify tests pass after each user story phase before proceeding
- Commit after each phase or logical group of tasks
- Stop at any checkpoint to validate story independently
- The core fix (Phase 2) is small (remove 7 lines, simplify orchestrator) but impact is large (eliminates recurring issue)
- Prevention tasks (Phase 6) are critical to ensure this pattern doesn't recur

**Key Insight**: This is an **architectural correction**, not just a bug fix. The tasks reflect this by including documentation and prevention mechanisms to establish clear module vs. helper boundaries.
