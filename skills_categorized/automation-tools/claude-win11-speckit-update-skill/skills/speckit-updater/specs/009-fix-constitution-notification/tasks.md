# Tasks: Fix False Constitution Update Notification

**Input**: Design documents from `/specs/009-fix-constitution-notification/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Feature Type**: Bug fix to existing code (Step 12 of update orchestrator)

**Tests**: Integration tests are included to validate the bug fix per Testing Discipline (Constitution Principle V).

**Organization**: Since all three user stories modify the same code location (Step 12, lines 677-707 of update-orchestrator.ps1), tasks are organized sequentially rather than by independent user story phases. The implementation integrates all three user stories into a single cohesive modification.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions
- PowerShell skill structure: `scripts/`, `tests/` at repository root
- Documentation: `docs/`, `CHANGELOG.md`, `CLAUDE.md`

---

## Phase 1: Setup (No New Infrastructure Required)

**Purpose**: This is a bug fix to existing code. No new project structure or infrastructure needed.

**Status**: ✅ Existing project structure is adequate

---

## Phase 2: Foundational (No Blocking Prerequisites)

**Purpose**: Verify that existing modules and infrastructure are functional

**⚠️ CRITICAL**: These validation tasks ensure the existing codebase is ready for modification

- [X] T001 [P] Verify Get-NormalizedHash function exists and works in scripts/modules/HashUtils.psm1
- [X] T002 [P] Verify backup creation works in Step 8 of scripts/update-orchestrator.ps1 (around line 544)
- [X] T003 [P] Verify current Step 12 notification logic in scripts/update-orchestrator.ps1 (lines 677-707)
- [X] T004 Run existing integration tests to establish baseline in tests/integration/UpdateOrchestrator.Tests.ps1

**Checkpoint**: Existing code validated - ready for modification

---

## Phase 3: Core Implementation - All User Stories

**Note**: All three user stories (US1, US2, US3) are implemented together in Step 12 modification because they:
- Modify the same code location (lines 677-707)
- Share hash verification logic (US1 core)
- Differentiate notification styling (US2, US3 build on US1)
- Cannot be independently deployed (single Step 12 block)

**Goal**: Implement hash verification to eliminate false positives (US1), add informational notifications for real updates (US2), and urgent notifications for conflicts (US3).

**Independent Test**: Run integration tests with mocked file systems and hash functions to verify notification logic without requiring actual SpecKit projects.

### Implementation Tasks

- [X] T005 [US1] Read and understand current Step 12 implementation in scripts/update-orchestrator.ps1 (lines 677-707)
- [X] T006 [US1] Add hash verification logic: construct file paths for current and backup constitution files in scripts/update-orchestrator.ps1 Step 12
- [X] T007 [US1] Add hash verification logic: implement Test-Path checks for file existence in scripts/update-orchestrator.ps1 Step 12
- [X] T008 [US1] Add hash verification logic: call Get-NormalizedHash for both files with try-catch error handling in scripts/update-orchestrator.ps1 Step 12
- [X] T009 [US1] Add hash verification logic: compare hashes and set $actualChangeDetected flag in scripts/update-orchestrator.ps1 Step 12
- [X] T010 [US1] Add hash verification logic: implement fail-safe behavior (missing backup or error → show notification) in scripts/update-orchestrator.ps1 Step 12
- [X] T011 [US1] Update notification conditional: wrap existing notification code in `if ($actualChangeDetected)` block in scripts/update-orchestrator.ps1 Step 12
- [X] T012 [US1] [US2] [US3] Add structured verbose logging: log file paths, hashes, and changed status in key-value format in scripts/update-orchestrator.ps1 Step 12
- [X] T013 [US2] Differentiate notification types: detect clean update vs conflict based on ConflictsResolved array in scripts/update-orchestrator.ps1 Step 12
- [X] T014 [US2] Implement informational notification: add ℹ️ emoji, cyan/gray colors, and "OPTIONAL" label for clean updates in scripts/update-orchestrator.ps1 Step 12
- [X] T015 [US3] Implement urgent notification: add ⚠️ emoji, red/yellow colors, and "REQUIRED" label for conflicts in scripts/update-orchestrator.ps1 Step 12
- [X] T016 [US1] [US2] [US3] Update notification messages: include backup path parameter for /speckit.constitution command in scripts/update-orchestrator.ps1 Step 12
- [X] T017 [US1] [US2] [US3] Add error logging: log exception type, message, file path, and suggested action when Get-NormalizedHash fails in scripts/update-orchestrator.ps1 Step 12

**Checkpoint**: Step 12 modification complete - hash verification, notification differentiation, and structured logging implemented

---

## Phase 4: Integration Testing

**Purpose**: Validate all three user stories through integration tests

**Goal**: Ensure false positives eliminated (US1), informational notifications shown correctly (US2), and urgent notifications styled appropriately (US3).

### Test Implementation Tasks

- [X] T018 [P] [US1] Add integration test: Constitution marked updated but hashes identical → no notification in tests/integration/UpdateOrchestrator.Tests.ps1
- [X] T019 [P] [US1] Add integration test: Constitution marked updated but backup missing → notification shown (fail-safe) in tests/integration/UpdateOrchestrator.Tests.ps1
- [X] T020 [P] [US1] Add integration test: Fresh install scenario (v0.0.0 to v0.0.78) with identical content → no notification in tests/integration/UpdateOrchestrator.Tests.ps1
- [X] T021 [P] [US2] Add integration test: Constitution cleanly updated with differing hashes → ℹ️ informational notification with "OPTIONAL" label in tests/integration/UpdateOrchestrator.Tests.ps1
- [X] T022 [P] [US2] Add integration test: Clean update notification includes backup path parameter in tests/integration/UpdateOrchestrator.Tests.ps1
- [X] T023 [P] [US2] Add integration test: Verbose logging shows structured key-value format with hashes, paths, timestamp in tests/integration/UpdateOrchestrator.Tests.ps1
- [X] T024 [P] [US3] Add integration test: Constitution conflict with differing hashes → ⚠️ urgent notification with "REQUIRED" label in tests/integration/UpdateOrchestrator.Tests.ps1
- [X] T025 [P] [US3] Add integration test: Constitution conflict but hashes match → no notification (prevents false positive) in tests/integration/UpdateOrchestrator.Tests.ps1
- [X] T026 [P] [US1] [US2] [US3] Add integration test: Get-NormalizedHash throws exception → verbose error logged and notification shown (fail-safe) in tests/integration/UpdateOrchestrator.Tests.ps1

**Checkpoint**: All integration tests passing - bug fix validated across all scenarios

---

## Phase 5: Documentation & Validation

**Purpose**: Update documentation and perform manual validation

### Documentation Tasks

- [X] T027 [P] [US1] [US2] [US3] Update CLAUDE.md: document new constitution notification behavior in "Constitution Update Notification" section
- [X] T028 [P] [US1] [US2] [US3] Update CLAUDE.md: add examples of informational vs urgent notifications with emoji/color schemes
- [X] T029 [P] [US1] [US2] [US3] Update CHANGELOG.md: add "Fixed" entry for Issue #18 describing false positive elimination and notification enhancements
- [X] T030 [P] [US1] [US2] [US3] Verify CONTRIBUTING.md mentions running tests before committing (no changes expected)

### Manual Validation Tasks

- [ ] T031 [US1] Manual test: Create scenario with identical constitution in backup, verify no notification shown using quickstart.md test procedure
- [ ] T032 [US2] Manual test: Create scenario with modified constitution in backup, verify ℹ️ informational notification shown using quickstart.md test procedure
- [ ] T033 [US3] Manual test: Simulate conflict scenario, verify ⚠️ urgent notification shown using quickstart.md test procedure
- [X] T034 [US1] [US2] [US3] Verify emoji rendering in Windows Terminal and VSCode integrated terminal
- [ ] T035 [US1] [US2] [US3] Test verbose logging: enable $VerbosePreference and verify structured key-value output format
- [ ] T036 [US1] [US2] [US3] Test fail-safe behavior: delete backup constitution, verify notification still shown
- [ ] T037 [US1] Performance validation: measure Step 12 processing time with Measure-Command, verify <200ms total
- [ ] T038 [US1] Performance validation: measure hash verification time, verify <100ms for typical constitution file
- [X] T039 [US1] [US2] [US3] Code quality check: run PSScriptAnalyzer on scripts/update-orchestrator.ps1, verify no warnings
- [X] T040 [US1] [US2] [US3] Run full test suite: execute tests/test-runner.ps1, verify all tests pass including new integration tests

**Checkpoint**: All documentation updated, manual tests passed, performance validated

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: ✅ Not applicable (existing project structure)
- **Foundational (Phase 2)**: Validation tasks T001-T004 can run in parallel - BLOCKS implementation
- **Core Implementation (Phase 3)**: Depends on Foundational validation - Tasks T005-T017 are sequential (same file modification)
- **Integration Testing (Phase 4)**: Depends on Core Implementation completion - Tasks T018-T026 can run in parallel
- **Documentation & Validation (Phase 5)**: Depends on Integration Testing passing - Documentation tasks (T027-T030) can run in parallel, validation tasks (T031-T040) are sequential

### Task Dependencies Within Phases

**Phase 2 (Foundational):**
- All tasks (T001-T004) marked [P] can run in parallel

**Phase 3 (Core Implementation):**
- T005-T017 are sequential because they all modify the same code block (Step 12, lines 677-707)
- Must be implemented in order: hash verification → notification conditional → logging → notification differentiation

**Phase 4 (Integration Testing):**
- All tasks (T018-T026) marked [P] can run in parallel (different test cases, no dependencies)

**Phase 5 (Documentation & Validation):**
- Documentation tasks (T027-T030) marked [P] can run in parallel (different files)
- Validation tasks (T031-T040) are sequential (depend on previous validation steps)

### User Story Dependencies

- **User Story 1 (P1)**: Core hash verification - Must be implemented first (T006-T011)
- **User Story 2 (P2)**: Informational notifications - Builds on US1 hash verification (T013-T014)
- **User Story 3 (P3)**: Urgent notifications - Builds on US1 hash verification (T013, T015)

**Note**: All three user stories share the hash verification logic from US1 and cannot be independently deployed. They are implemented together in Phase 3.

### Parallel Opportunities

**Phase 2: All validation tasks can run in parallel**
```bash
Task: "Verify Get-NormalizedHash function exists"
Task: "Verify backup creation works in Step 8"
Task: "Verify current Step 12 notification logic"
Task: "Run existing integration tests to establish baseline"
```

**Phase 4: All integration test tasks can run in parallel**
```bash
Task: "Add integration test: Constitution marked updated but hashes identical"
Task: "Add integration test: Constitution marked updated but backup missing"
Task: "Add integration test: Fresh install scenario with identical content"
Task: "Add integration test: Constitution cleanly updated with differing hashes"
Task: "Add integration test: Clean update notification includes backup path"
Task: "Add integration test: Verbose logging shows structured format"
Task: "Add integration test: Constitution conflict with differing hashes"
Task: "Add integration test: Constitution conflict but hashes match"
Task: "Add integration test: Get-NormalizedHash throws exception"
```

**Phase 5: Documentation tasks can run in parallel**
```bash
Task: "Update CLAUDE.md: document new constitution notification behavior"
Task: "Update CLAUDE.md: add examples of notifications with emoji/colors"
Task: "Update CHANGELOG.md: add Fixed entry for Issue #18"
Task: "Verify CONTRIBUTING.md mentions running tests"
```

---

## Parallel Example: Integration Testing (Phase 4)

```bash
# Launch all 9 integration test tasks together:
Task T018: "Add integration test: Constitution marked updated but hashes identical → no notification"
Task T019: "Add integration test: Constitution marked updated but backup missing → notification shown"
Task T020: "Add integration test: Fresh install scenario (v0.0.0 to v0.0.78) with identical content → no notification"
Task T021: "Add integration test: Constitution cleanly updated with differing hashes → ℹ️ informational notification"
Task T022: "Add integration test: Clean update notification includes backup path parameter"
Task T023: "Add integration test: Verbose logging shows structured key-value format"
Task T024: "Add integration test: Constitution conflict with differing hashes → ⚠️ urgent notification"
Task T025: "Add integration test: Constitution conflict but hashes match → no notification"
Task T026: "Add integration test: Get-NormalizedHash throws exception → error logged and notification shown"

# All tests can be written simultaneously since they test different scenarios
# Expected outcome: All 9 test cases fail initially, then pass after implementation
```

---

## Implementation Strategy

### Sequential Delivery (Single Bug Fix)

This bug fix cannot be delivered incrementally since all three user stories modify the same code block (Step 12). The implementation strategy is:

1. **Complete Phase 2: Foundational Validation** (T001-T004)
   - Verify existing code works correctly
   - Establish test baseline

2. **Complete Phase 3: Core Implementation** (T005-T017)
   - Implement hash verification (US1 core)
   - Add notification differentiation (US2, US3)
   - Add structured logging (all user stories)
   - **Cannot stop mid-phase** - Step 12 must be fully functional

3. **Complete Phase 4: Integration Testing** (T018-T026)
   - Write all test cases in parallel
   - Verify all scenarios work correctly
   - **STOP and VALIDATE**: All tests must pass before proceeding

4. **Complete Phase 5: Documentation & Validation** (T027-T040)
   - Update documentation
   - Perform manual validation
   - Verify performance targets met

5. **Deploy/Merge**: Submit PR with all changes (code + tests + docs)

### Why No MVP Approach?

Unlike feature development, bug fixes typically:
- Cannot be partially deployed (incomplete fix may introduce new bugs)
- Must address all related scenarios (US1, US2, US3) together
- Require comprehensive testing before release

**Delivery**: Single PR with all three user stories implemented and validated together.

---

## Success Criteria Validation

Each success criterion from spec.md will be validated:

- **SC-001** (100% false positive elimination): Tasks T018, T020, T025 verify no notification when hashes match
- **SC-002** (100% real change detection): Tasks T021, T024 verify notification when hashes differ
- **SC-003** (3-second user comprehension): Tasks T032, T033 manual UX testing with emoji/icon labels
- **SC-004** (<100ms performance): Tasks T037, T038 measure hash verification and Step 12 timing
- **SC-005** (95% user understanding): Post-release user feedback survey (deferred to production)
- **SC-006** (80% support reduction): Post-release metrics tracking (deferred to production)

---

## Notes

- **[P] tasks** = different files, no dependencies - can run in parallel
- **[Story] label** = maps task to user story (US1, US2, US3) for traceability
- **Sequential implementation** required for Phase 3 (all tasks modify same file)
- **Parallel testing** possible for Phase 4 (different test cases)
- **Fail-fast**: Any test failure in Phase 4 blocks Phase 5 progression
- **Code review** after T040 (all tests passing) before merging to main
- **Performance validation** mandatory (T037-T038) per constitution requirements
- **Emoji rendering** must be verified manually (T034) - cannot be automated

---

## Quick Reference: Task Count Summary

- **Phase 2 (Foundational)**: 4 tasks (all parallelizable)
- **Phase 3 (Core Implementation)**: 13 tasks (sequential, same file)
- **Phase 4 (Integration Testing)**: 9 tasks (all parallelizable)
- **Phase 5 (Documentation & Validation)**: 14 tasks (4 parallelizable docs, 10 sequential validation)

**Total Tasks**: 40
**Parallelizable Tasks**: 17 (42.5%)
**Sequential Tasks**: 23 (57.5%)
**Estimated Effort**: 4-6 hours (per plan.md)

---

## Risk Mitigation

| Risk | Mitigation Task |
|------|----------------|
| Emoji not rendering | T034 (manual test in Windows Terminal and VSCode) |
| Performance regression | T037, T038 (measure and verify <200ms target) |
| Breaking existing tests | T004 (baseline), T040 (full test suite validation) |
| False negatives | T021, T024 (verify real changes still detected) |
| Fail-safe not working | T019, T026, T036 (test error scenarios) |

---

## Appendix: File Paths Reference

**Modified Files:**
- `scripts/update-orchestrator.ps1` (lines 677-707) - Step 12 modification
- `tests/integration/UpdateOrchestrator.Tests.ps1` - 9 new test cases
- `CLAUDE.md` - Constitution Update Notification section
- `CHANGELOG.md` - Fixed entry for Issue #18

**Referenced Files (No Changes):**
- `scripts/modules/HashUtils.psm1` - Provides Get-NormalizedHash (existing)
- `scripts/modules/ManifestManager.psm1` - Provides manifest operations (existing)
- `CONTRIBUTING.md` - Development guidelines (verify only)
- `docs/bugs/007-false-constitution-update-notification.md` - Bug report (reference)

**Supporting Documents:**
- `specs/009-fix-constitution-notification/spec.md` - Feature specification
- `specs/009-fix-constitution-notification/plan.md` - Implementation plan
- `specs/009-fix-constitution-notification/research.md` - Research findings
- `specs/009-fix-constitution-notification/data-model.md` - Data structures
- `specs/009-fix-constitution-notification/quickstart.md` - Testing guide
