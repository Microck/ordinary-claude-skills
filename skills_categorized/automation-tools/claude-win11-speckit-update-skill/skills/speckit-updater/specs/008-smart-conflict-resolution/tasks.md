---
description: "Task list for smart conflict resolution implementation"
---

# Tasks: Smart Conflict Resolution for Large Files

**Input**: Design documents from `/specs/008-smart-conflict-resolution/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included per Constitution Principle V (Testing Discipline) - all modules MUST have corresponding Pester unit tests.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions
- PowerShell skill project - single repository structure
- Modules: `scripts/modules/`
- Tests: `tests/unit/`, `tests/integration/`
- Fixtures: `tests/fixtures/`

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and test fixture preparation

- [X] T001 Create test fixtures directory at tests/fixtures/large-file-samples/
- [X] T002 [P] Create small-file.md test fixture (50 lines) in tests/fixtures/large-file-samples/
- [X] T003 [P] Create boundary-100-lines.md test fixture (exactly 100 lines) in tests/fixtures/large-file-samples/
- [X] T004 [P] Create boundary-101-lines.md test fixture (101 lines) in tests/fixtures/large-file-samples/
- [X] T005 [P] Create large-file-200-lines.md test fixture (200 lines with 3 changed sections) in tests/fixtures/large-file-samples/
- [X] T006 [P] Create large-file-1000-lines.md test fixture (1000 lines for performance testing) in tests/fixtures/large-file-samples/

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: This phase contains no blocking foundational tasks. All implementations are story-specific and can proceed directly to user story phases.

**Checkpoint**: Foundation ready - user story implementation can now begin immediately

---

## Phase 3: User Story 1 - Large Template File Conflict Review (Priority: P1) 🎯 MVP

**Goal**: Generate side-by-side diff files showing only changed sections for large template conflicts (>100 lines)

**Independent Test**: Create a test scenario with a 200-line file that has conflicts. Run the update workflow and verify that a diff file is generated at `.specify/.tmp-conflicts/[filename].diff.md` with proper Markdown formatting showing only changed sections with line numbers.

### Implementation for User Story 1

- [X] T007 [US1] Implement Compare-FileSections function in scripts/modules/ConflictDetector.psm1
- [X] T008 [US1] Implement Write-SideBySideDiff function (including unchanged sections summary) in scripts/modules/ConflictDetector.psm1
- [X] T009 [US1] Implement Write-SmartConflictResolution function (size detection and large file path) in scripts/modules/ConflictDetector.psm1

### Tests for User Story 1

- [X] T010 [P] [US1] Unit test: Compare-FileSections with identical files returns empty DiffSections in tests/unit/ConflictDetector.Tests.ps1
- [X] T011 [P] [US1] Unit test: Compare-FileSections with single section change groups consecutive lines in tests/unit/ConflictDetector.Tests.ps1
- [X] T012 [P] [US1] Unit test: Compare-FileSections with multiple sections returns correct section count in tests/unit/ConflictDetector.Tests.ps1
- [X] T013 [P] [US1] Unit test: Compare-FileSections adds 3 context lines before/after changes in tests/unit/ConflictDetector.Tests.ps1
- [X] T014 [P] [US1] Unit test: Compare-FileSections handles change at start of file (boundary) in tests/unit/ConflictDetector.Tests.ps1
- [X] T015 [P] [US1] Unit test: Compare-FileSections handles change at end of file (boundary) in tests/unit/ConflictDetector.Tests.ps1
- [X] T016 [P] [US1] Unit test: Compare-FileSections handles empty file comparison in tests/unit/ConflictDetector.Tests.ps1
- [X] T017 [P] [US1] Unit test: Compare-FileSections identifies unchanged ranges correctly in tests/unit/ConflictDetector.Tests.ps1
- [X] T018 [P] [US1] Unit test: Write-SideBySideDiff creates diff file at correct path in tests/unit/ConflictDetector.Tests.ps1
- [X] T019 [P] [US1] Unit test: Write-SideBySideDiff generates valid Markdown format in tests/unit/ConflictDetector.Tests.ps1
- [X] T020 [P] [US1] Unit test: Write-SideBySideDiff detects language hint from file extension in tests/unit/ConflictDetector.Tests.ps1
- [X] T021 [P] [US1] Unit test: Write-SideBySideDiff creates .specify/.tmp-conflicts/ directory if not exists in tests/unit/ConflictDetector.Tests.ps1
- [X] T022 [P] [US1] Unit test: Write-SideBySideDiff uses UTF-8 encoding without BOM in tests/unit/ConflictDetector.Tests.ps1
- [X] T023 [P] [US1] Unit test: Write-SideBySideDiff includes unchanged sections summary in tests/unit/ConflictDetector.Tests.ps1
- [X] T024 [P] [US1] Unit test: Write-SmartConflictResolution generates diff for 101-line file in tests/unit/ConflictDetector.Tests.ps1
- [X] T025 [P] [US1] Unit test: Write-SmartConflictResolution generates diff for 200-line file in tests/unit/ConflictDetector.Tests.ps1
- [X] T026 [P] [US1] Unit test: Write-SmartConflictResolution falls back to Git markers on error in tests/unit/ConflictDetector.Tests.ps1
- [X] T027 [P] [US1] Unit test: Write-SmartConflictResolution handles empty base version in tests/unit/ConflictDetector.Tests.ps1
- [X] T028 [US1] Integration test: End-to-end large file conflict generates diff file with correct format in tests/integration/UpdateOrchestrator.Tests.ps1
- [X] T029 [US1] Validation test: Open generated diff file in VSCode preview and verify Markdown renders correctly with syntax highlighting

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently. Large file conflicts (>100 lines) generate side-by-side diff files.

**Note on User Story 4**: The "Unchanged Sections Summary" user story from spec.md is implemented within User Story 1 (tasks T008 and T023) as it's a natural part of the diff file generation. Separating it into a different phase would create unnecessary complexity. All User Story 4 acceptance criteria are met by User Story 1 implementation.

---

## Phase 4: User Story 2 - Small File Standard Conflict Handling (Priority: P2)

**Goal**: Ensure small files (≤100 lines) continue to use standard Git conflict markers, maintaining backward compatibility

**Independent Test**: Create a test scenario with a 50-line file that has conflicts. Run the update workflow and verify that Git conflict markers are written directly to the file (not a separate diff file), and that VSCode shows CodeLens actions for resolution.

### Implementation for User Story 2

- [X] T030 [US2] Update Write-SmartConflictResolution to call Write-ConflictMarkers for files ≤100 lines in scripts/modules/ConflictDetector.psm1
- [X] T031 [US2] Update Export-ModuleMember to export Write-SmartConflictResolution, Compare-FileSections, Write-SideBySideDiff in scripts/modules/ConflictDetector.psm1
- [X] T032 [US2] Update orchestrator to replace Write-ConflictMarkers calls with Write-SmartConflictResolution in scripts/update-orchestrator.ps1

### Tests for User Story 2

- [X] T033 [P] [US2] Unit test: Write-SmartConflictResolution uses Git markers for 50-line file in tests/unit/ConflictDetector.Tests.ps1
- [X] T034 [P] [US2] Unit test: Write-SmartConflictResolution uses Git markers for exactly 100-line file (boundary) in tests/unit/ConflictDetector.Tests.ps1
- [X] T035 [P] [US2] Unit test: Write-SmartConflictResolution calls Write-ConflictMarkers with correct parameters in tests/unit/ConflictDetector.Tests.ps1
- [X] T036 [US2] Integration test: End-to-end small file conflict uses Git markers in tests/integration/UpdateOrchestrator.Tests.ps1
- [ ] T037 [US2] Validation test: Verify Git conflict markers work in VSCode (CodeLens actions appear)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently. Small files use Git markers, large files use diff files.

---

## Phase 5: User Story 3 - Diff File Cleanup After Resolution (Priority: P3)

**Goal**: Automatically clean up temporary diff files after successful update completion, preventing clutter

**Independent Test**: Create a test scenario that generates diff files, complete the update successfully, and verify that `.specify/.tmp-conflicts/` directory is removed. Then test rollback scenario and verify diff files are preserved.

### Implementation for User Story 3

- [X] T038 [US3] Implement cleanup logic for .specify/.tmp-conflicts/ in orchestrator after successful update in scripts/update-orchestrator.ps1
- [X] T039 [US3] Ensure cleanup does NOT run on rollback (preserve diff files for debugging) in scripts/update-orchestrator.ps1

### Tests for User Story 3

- [X] T040 [P] [US3] Unit test: Cleanup function removes .specify/.tmp-conflicts/ directory in tests/unit/ConflictDetector.Tests.ps1
- [X] T041 [P] [US3] Unit test: Cleanup handles non-existent directory gracefully in tests/unit/ConflictDetector.Tests.ps1
- [X] T042 [P] [US3] Unit test: Cleanup failure logs warning but doesn't fail update in tests/unit/ConflictDetector.Tests.ps1
- [X] T043 [US3] Integration test: Successful update cleans up diff files in tests/integration/UpdateOrchestrator.Tests.ps1
- [X] T044 [US3] Integration test: Rollback preserves diff files in .specify/.tmp-conflicts/ in tests/integration/UpdateOrchestrator.Tests.ps1

**Checkpoint**: All user stories should now be independently functional. Cleanup works for successful updates, diff files preserved on rollback.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, performance validation, and final quality checks

- [X] T045 [P] Update "Git Conflict Markers" section in CLAUDE.md with smart conflict resolution description
- [X] T046 [P] Add example diff file output to CLAUDE.md documentation
- [X] T047 [P] Update README.md with feature mention (smart diff generation for large files)
- [X] T048 [P] Update CHANGELOG.md under [Unreleased] with feature description and breaking changes
- [X] T049 Performance benchmark: Measure Compare-FileSections with 100-line file (target <50ms) in tests/unit/ConflictDetector.Tests.ps1
- [X] T050 Performance benchmark: Measure Write-SmartConflictResolution with 1000-line file (target <2000ms) in tests/unit/ConflictDetector.Tests.ps1
- [X] T051 Code cleanup: Review all new functions for PowerShell style compliance (PascalCase, comment-based help, verbose logging)
- [X] T052 Code cleanup: Ensure all functions have .SYNOPSIS, .DESCRIPTION, .PARAMETER, .EXAMPLE documentation
- [X] T053 Final validation: Run all unit tests (.\tests\test-runner.ps1 -Unit) and verify pass
- [X] T054 Final validation: Run all integration tests (.\tests\test-runner.ps1 -Integration) and verify pass
- [X] T055 Final validation: Run full test suite with coverage (.\tests\test-runner.ps1 -Coverage) and verify 80%+ coverage

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: No blocking tasks - skip directly to user stories
- **User Stories (Phase 3+)**: Can proceed directly after Setup
  - User Story 1 (P1): Can start immediately after Setup
  - User Story 2 (P2): Depends on User Story 1 completion (needs Write-SmartConflictResolution implemented)
  - User Story 3 (P3): Can start after Setup (independent of US1/US2 implementation)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Setup (Phase 1) - No dependencies on other stories
- **User Story 2 (P2)**: Depends on User Story 1 (needs Write-SmartConflictResolution function) - Extends US1 with small file handling
- **User Story 3 (P3)**: Can start after Setup (Phase 1) - No dependencies on US1/US2 (cleanup is independent)

### Within Each User Story

- Implementation tasks before test tasks (need code to test)
- Unit tests can run in parallel (marked [P])
- Integration tests run after unit tests pass
- Validation tests run after integration tests pass
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks (T002-T006) can run in parallel - different fixture files
- User Story 1: All unit tests (T010-T027) can run in parallel after implementation (T007-T009) completes
- User Story 2: All unit tests (T033-T035) can run in parallel after implementation completes
- User Story 3: All unit tests (T040-T042) can run in parallel after implementation completes
- Polish phase: Documentation updates (T045-T048) can run in parallel

---

## Parallel Example: User Story 1

```bash
# After implementing T007-T009, launch all unit tests together:
Task: "Unit test: Compare-FileSections with identical files returns empty DiffSections in tests/unit/ConflictDetector.Tests.ps1"
Task: "Unit test: Compare-FileSections with single section change groups consecutive lines in tests/unit/ConflictDetector.Tests.ps1"
Task: "Unit test: Compare-FileSections with multiple sections returns correct section count in tests/unit/ConflictDetector.Tests.ps1"
Task: "Unit test: Compare-FileSections adds 3 context lines before/after changes in tests/unit/ConflictDetector.Tests.ps1"
Task: "Unit test: Compare-FileSections handles change at start of file (boundary) in tests/unit/ConflictDetector.Tests.ps1"
Task: "Unit test: Compare-FileSections handles change at end of file (boundary) in tests/unit/ConflictDetector.Tests.ps1"
Task: "Unit test: Compare-FileSections handles empty file comparison in tests/unit/ConflictDetector.Tests.ps1"
Task: "Unit test: Compare-FileSections identifies unchanged ranges correctly in tests/unit/ConflictDetector.Tests.ps1"
Task: "Unit test: Write-SideBySideDiff creates diff file at correct path in tests/unit/ConflictDetector.Tests.ps1"
Task: "Unit test: Write-SideBySideDiff generates valid Markdown format in tests/unit/ConflictDetector.Tests.ps1"
Task: "Unit test: Write-SideBySideDiff detects language hint from file extension in tests/unit/ConflictDetector.Tests.ps1"
Task: "Unit test: Write-SideBySideDiff creates .specify/.tmp-conflicts/ directory if not exists in tests/unit/ConflictDetector.Tests.ps1"
Task: "Unit test: Write-SideBySideDiff uses UTF-8 encoding without BOM in tests/unit/ConflictDetector.Tests.ps1"
Task: "Unit test: Write-SideBySideDiff includes unchanged sections summary in tests/unit/ConflictDetector.Tests.ps1"
Task: "Unit test: Write-SmartConflictResolution generates diff for 101-line file in tests/unit/ConflictDetector.Tests.ps1"
Task: "Unit test: Write-SmartConflictResolution generates diff for 200-line file in tests/unit/ConflictDetector.Tests.ps1"
Task: "Unit test: Write-SmartConflictResolution falls back to Git markers on error in tests/unit/ConflictDetector.Tests.ps1"
Task: "Unit test: Write-SmartConflictResolution handles empty base version in tests/unit/ConflictDetector.Tests.ps1"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T006)
2. Complete Phase 3: User Story 1 (T007-T029)
3. **STOP and VALIDATE**: Test User Story 1 independently
   - Create 200-line file with conflicts
   - Run update workflow
   - Verify diff file generated at `.specify/.tmp-conflicts/[filename].diff.md`
   - Open diff file in VSCode and verify Markdown rendering
   - Verify diff shows only changed sections with line numbers
4. If validated successfully, User Story 1 is MVP-ready!

### Incremental Delivery

1. Complete Setup (Phase 1) → Test fixtures ready
2. Add User Story 1 (Phase 3) → Test independently → **Deploy/Demo (MVP!)**
   - Users can now review large file conflicts with side-by-side diffs
3. Add User Story 2 (Phase 4) → Test independently → **Deploy/Demo**
   - Small files continue to work with Git markers (backward compatibility)
4. Add User Story 3 (Phase 5) → Test independently → **Deploy/Demo**
   - Automatic cleanup prevents clutter
5. Complete Polish (Phase 6) → Documentation and final validation

### Parallel Team Strategy

With multiple developers:

1. Developer A: Complete Setup (T001-T006)
2. Once Setup done, work can split:
   - Developer A: User Story 1 implementation (T007-T009)
   - Developer B: User Story 3 implementation (T038-T039) - independent
3. Developer A completes US1 implementation, then:
   - Developer A: US1 tests (T010-T029)
   - Developer B: US3 tests (T040-T044)
4. Developer A: User Story 2 (T030-T037) - depends on US1
5. Both: Polish phase (T045-T055) - documentation in parallel

---

## Notes

- [P] tasks = different files, no dependencies (can run in parallel)
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Constitution Principle V requires comprehensive Pester unit tests for all modules
- Performance targets: <50ms for 100-line files, <2000ms for 1000-line files (SC-002)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- All functions must have comment-based help (.SYNOPSIS, .DESCRIPTION, .PARAMETER, .EXAMPLE)
- Follow PowerShell style: PascalCase functions, camelCase variables, Write-Verbose for logging
- Module exports must include all three new functions
- Error handling: Fall back to Git markers on any diff generation error (graceful degradation)
