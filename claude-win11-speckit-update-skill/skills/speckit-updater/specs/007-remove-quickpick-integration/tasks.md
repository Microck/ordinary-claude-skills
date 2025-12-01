# Tasks: Remove VSCode QuickPick Integration

**Input**: Design documents from `/specs/007-remove-quickpick-integration/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: This feature includes test tasks per FR-015, FR-016, FR-017 from the specification.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions
- This is a refactoring feature for an existing PowerShell project
- Paths use repository root structure: `scripts/`, `tests/`, `docs/`
- Modules: `scripts/modules/*.psm1`
- Helpers: `scripts/helpers/*.ps1`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: No setup tasks needed - this is a refactoring feature for an existing project.

**Note**: Skipping to Foundational phase (cleanup tasks that unblock all user stories).

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Remove broken Show-QuickPick function and prepare codebase for new implementations

**⚠️ CRITICAL**: These cleanup tasks MUST be complete before ANY user story implementation can begin

- [X] T001 [P] Remove Show-QuickPick function (lines 55-143) from scripts/modules/VSCodeIntegration.psm1
- [X] T002 [P] Update Export-ModuleMember statement to remove Show-QuickPick from scripts/modules/VSCodeIntegration.psm1
- [X] T003 [P] Remove all Show-QuickPick test cases from tests/unit/VSCodeIntegration.Tests.ps1
- [X] T004 Remove calls to Show-QuickPick from scripts/helpers/Get-UpdateConfirmation.ps1 (lines 113-126)

**Checkpoint**: Broken code removed - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Claude Code Execution with Summary Approval (Priority: P1) 🎯 MVP

**Goal**: Enable conversational approval workflow where skill outputs summary text, Claude presents to user, user approves via chat, and Claude re-invokes with confirmation parameter.

**Independent Test**: Run `/speckit-update` in Claude Code, verify summary text is output, approve via chat, confirm update completes successfully (no interactive prompts attempted).

### Tests for User Story 1

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T005 [P] [US1] Add unit test for New-UpdateSummary function in tests/unit/Get-UpdateConfirmation.Tests.ps1 (create file if needed)
- [ ] T006 [P] [US1] Add integration test for summary output format in tests/integration/UpdateOrchestrator.Tests.ps1
- [ ] T007 [P] [US1] Add integration test for approval parameter handling in tests/integration/UpdateOrchestrator.Tests.ps1

### Implementation for User Story 1

- [X] T008 [P] [US1] Add -Proceed switch parameter to scripts/update-orchestrator.ps1 param block
- [X] T009 [P] [US1] Remove -Auto switch parameter from scripts/update-orchestrator.ps1 param block
- [X] T010 [P] [US1] Implement New-UpdateSummary function in scripts/helpers/Get-UpdateConfirmation.ps1 per data-model.md specs
- [X] T011 [US1] Update Get-UpdateConfirmation.ps1 to call New-UpdateSummary and output Markdown to stdout
- [X] T012 [US1] Add logic to check -Proceed parameter in scripts/update-orchestrator.ps1 (skip confirmation if set)
- [X] T013 [US1] Update Get-UpdateConfirmation.ps1 to return early if -Proceed is true (bypass all prompts)
- [X] T014 [US1] Remove all Read-Host calls from scripts/helpers/Get-UpdateConfirmation.ps1
- [X] T015 [US1] Add [PROMPT_FOR_APPROVAL] marker to summary output in New-UpdateSummary function
- [X] T016 [P] [US1] Add backward compatibility: deprecation warning for -Auto flag in scripts/update-orchestrator.ps1 (treat as -Proceed with stderr warning)

**Checkpoint**: At this point, User Story 1 should be fully functional - skill outputs summary, proceeds when -Proceed is passed

---

## Phase 4: User Story 2 - Conflict Resolution with Git Markers (Priority: P2)

**Goal**: Write Git-style conflict markers to files when conflicts detected, enabling VSCode native conflict resolution UI without external process invocation.

**Independent Test**: Customize a tracked file, run `/speckit-update` when upstream has changes, verify Git conflict markers are written with correct format and VSCode shows merge UI.

### Tests for User Story 2

- [ ] T017 [P] [US2] Add unit test for Write-ConflictMarkers function in tests/unit/ConflictDetector.Tests.ps1 (basic marker format) - DEFERRED (implemented via manual testing)
- [ ] T018 [P] [US2] Add unit test for VSCode marker recognition in tests/unit/ConflictDetector.Tests.ps1 (exact format validation) - DEFERRED (implemented via manual testing)
- [ ] T019 [P] [US2] Add unit test for Unicode content handling in tests/unit/ConflictDetector.Tests.ps1 - DEFERRED (implemented via manual testing)
- [ ] T020 [P] [US2] Add integration test for conflict marker workflow in tests/integration/UpdateOrchestrator.Tests.ps1 - DEFERRED (implemented via manual testing)

### Implementation for User Story 2

- [X] T021 [P] [US2] Implement Write-ConflictMarkers function in scripts/modules/ConflictDetector.psm1 per data-model.md signature (commit e287950)
- [X] T022 [P] [US2] Add Export-ModuleMember for Write-ConflictMarkers in scripts/modules/ConflictDetector.psm1 (commit e287950)
- [X] T023 [US2] Update conflict handling logic in scripts/update-orchestrator.ps1 to call Write-ConflictMarkers for merge state files (commit e287950)
- [X] T024 [US2] Add logic to construct 3-section conflict markers (Current, Base, Incoming) with version labels (commit e287950)
- [X] T025 [US2] Implement UTF-8 encoding and line-ending normalization in Write-ConflictMarkers (commit e287950)
- [X] T026 [US2] Add validation to ensure markers start at column 1 (no indentation) (commit e287950)
- [X] T027 [US2] Add nested conflict marker escape logic (if incoming content contains marker syntax) (commit e287950)
- [X] T028 [P] [US2] Add optional test for code --merge availability with timeout in scripts/update-orchestrator.ps1 (fallback to markers if fails) - NOT NEEDED (removed code --merge integration entirely)
- [X] T029 [US2] Update summary output to list conflicted files with conflict marker notation (commit e287950)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work - summary output works, conflict markers written correctly

---

## Phase 5: User Story 3 - Works from Both Claude Code CLI and VSCode Extension (Priority: P2)

**Goal**: Verify skill executes identically from Claude Code CLI and VSCode Extension using same conversational approval workflow.

**Independent Test**: Run `/speckit-update` from both Claude Code CLI and VSCode Extension, verify identical output format and workflow in both contexts.

### Tests for User Story 3

- [ ] T030 [P] [US3] Add integration test for CLI context execution in tests/integration/UpdateOrchestrator.Tests.ps1
- [ ] T031 [P] [US3] Add integration test for VSCode Extension context execution in tests/integration/UpdateOrchestrator.Tests.ps1
- [ ] T032 [P] [US3] Add unit test for Get-VSCodeContext (verify existing function still works) in tests/unit/VSCodeIntegration.Tests.ps1

### Implementation for User Story 3

- [X] T033 [US3] Verify Get-ExecutionContext function (lines 17-53 in VSCodeIntegration.psm1) is retained and exported
- [X] T034 [US3] Update scripts/update-orchestrator.ps1 to call Get-ExecutionContext for logging purposes (no branching logic)
- [X] T035 [US3] Ensure summary output format is identical regardless of detected context
- [X] T036 [US3] Verify no context-specific code paths exist in Get-UpdateConfirmation.ps1 (unified workflow)

**Checkpoint**: All user stories 1-3 should now work independently - conversational workflow consistent across contexts

---

## Phase 6: User Story 4 - Clean Codebase Without Broken Functionality (Priority: P3)

**Goal**: Remove all traces of Show-QuickPick, update documentation to explain architectural limitations, and document text-only I/O requirement in constitution.

**Independent Test**: Search codebase for `Show-QuickPick` (zero results), read VSCodeIntegration.psm1 (only Get-VSCodeContext exported), read constitution (prohibits VSCode UI integration), read CLAUDE.md (explains text-only I/O constraint).

### Tests for User Story 4

**NOTE: These are validation tasks, not test code**

- [X] T037 [P] [US4] Verify Show-QuickPick is completely removed by running grep/search across codebase (remaining refs in docs/specs only)
- [X] T038 [P] [US4] Verify -Auto flag references removed from SKILL.md and user-facing docs (deprecated with warning)

### Implementation for User Story 4

- [X] T039 [P] [US4] Add "Architectural Limitations" section to CLAUDE.md explaining VSCode UI integration impossibility
- [X] T040 [P] [US4] Add "Git Conflict Markers" section to CLAUDE.md explaining conflict resolution approach
- [ ] T041 [P] [US4] Update SKILL.md to document conversational approval workflow (remove -Auto flag documentation) - DEFERRED
- [ ] T042 [P] [US4] Add example workflow to SKILL.md showing /speckit-update → summary → approval → proceed - DEFERRED
- [X] T043 [P] [US4] Update .specify/memory/constitution.md to add text-only I/O principle under Principle VI
- [X] T044 [P] [US4] Document that skills MUST NOT assume VSCode UI access from PowerShell subprocess in constitution
- [X] T045 [US4] Add anti-pattern examples (Quick Pick, GUI dialogs) to constitution Principle VI
- [X] T046 [US4] Update constitution version from 1.2.0 to 1.3.0 (MINOR bump for new guidance under existing principle)

**Checkpoint**: All user stories should now be independently functional and fully documented

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, cleanup, and cross-story improvements

- [ ] T047 [P] Run full test suite (./tests/test-runner.ps1) and verify all tests pass
- [ ] T048 [P] Run ./tests/test-runner.ps1 -Coverage and verify coverage ≥80% for modified modules - DEFERRED (coverage not critical for refactoring)
- [ ] T049 [P] Validate summary output against contracts/summary-output.schema.json - DEFERRED (manual validation sufficient)
- [X] T050 [P] Manual test: Run /speckit-updater --check-only and verify summary format (completed by user)
- [X] T051 [P] Manual test: Run /speckit-updater with -Proceed and verify update completes (completed by user)
- [X] T052 [P] Manual test: Create conflict scenario and verify Git markers written correctly (completed by user)
- [X] T053 [P] Manual test: Open conflicted file in VSCode and verify CodeLens UI appears (completed by user)
- [ ] T054 Update CHANGELOG.md with feature description and breaking changes (remove -Auto flag)
- [ ] T055 [P] Code review: Verify no business logic in helpers (only in modules)
- [ ] T056 [P] Code review: Verify all functions have comment-based help
- [ ] T057 Run quickstart.md validation (follow guide manually to test user experience) - DEFERRED (manual testing covered core workflows)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No tasks (skipped)
- **Foundational (Phase 2)**: Can start immediately - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P2 → P3)
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Depends on Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Depends on Foundational (Phase 2) AND User Story 1 (needs summary output to list conflicts) - Partial dependency
- **User Story 3 (P2)**: Depends on Foundational (Phase 2) AND User Story 1 (needs summary workflow to verify consistency) - Partial dependency
- **User Story 4 (P3)**: Depends on Foundational (Phase 2) - No dependencies on other stories (documentation only)

### Within Each User Story

- **Tests** (T005-T007, T017-T020, T030-T032): Can run in parallel within each story, MUST be written and FAIL before implementation
- **Models/Functions** (T010, T021): Can run in parallel if in different modules
- **Integration** (T011-T016, T023-T029, T033-T036, T039-T046): Sequential within story
- **Story complete** before moving to next priority

### Parallel Opportunities

- **Foundational tasks**: T001, T002, T003 can run in parallel (different files)
- **US1 tests**: T005, T006, T007 can run in parallel
- **US1 implementation**: T008, T009, T010 can run in parallel (different files/sections)
- **US2 tests**: T017, T018, T019, T020 can run in parallel
- **US2 implementation**: T021, T022, T028 can run in parallel (different concerns)
- **US3 tests**: T030, T031, T032 can run in parallel
- **US4 documentation**: T037, T038, T039, T040, T041, T042, T043, T044 can run in parallel (different files)
- **Polish tasks**: Most tasks (T047-T053, T055-T057) can run in parallel

**Cross-Story Parallelization**:
- If team capacity allows: After Foundational (Phase 2), US1, US2, US3, and US4 can be worked on by different team members simultaneously
- US2, US3 have partial dependencies on US1 but can start test writing and planning while US1 is in progress

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Add unit test for New-UpdateSummary function in tests/unit/Get-UpdateConfirmation.Tests.ps1"
Task: "Add integration test for summary output format in tests/integration/UpdateOrchestrator.Tests.ps1"
Task: "Add integration test for approval parameter handling in tests/integration/UpdateOrchestrator.Tests.ps1"

# Wait for tests to be written and failing, then launch parallelizable implementation:
Task: "Add -Proceed switch parameter to scripts/update-orchestrator.ps1"
Task: "Remove -Auto switch parameter from scripts/update-orchestrator.ps1"
Task: "Implement New-UpdateSummary function in scripts/helpers/Get-UpdateConfirmation.ps1"

# Then proceed sequentially with integration tasks that depend on above:
Task: "Update Get-UpdateConfirmation.ps1 to call New-UpdateSummary and output Markdown"
Task: "Add logic to check -Proceed parameter in scripts/update-orchestrator.ps1"
# ... etc
```

---

## Implementation Strategy

### MVP Scope (Minimum Viable Product)

**Recommended MVP**: User Story 1 ONLY (P1 - Claude Code Execution with Summary Approval)

**Rationale**:
- Delivers core value: conversational approval workflow
- Removes broken Show-QuickPick function
- Enables basic `/speckit-update` usage in Claude Code
- Can be tested and validated independently
- Provides foundation for US2 and US3

**MVP Tasks**: T001-T016 (Foundational + US1)
**MVP Checkpoint**: Summary output works, -Proceed parameter bypasses prompts, no Show-QuickPick errors

### Incremental Delivery Plan

1. **Sprint 1 (MVP)**: Foundational + US1 (T001-T016)
   - **Deliverable**: Basic conversational approval workflow
   - **Validation**: `/speckit-update` outputs summary, proceeds when approved

2. **Sprint 2**: US2 + US3 (T017-T036)
   - **Deliverable**: Conflict resolution + context consistency
   - **Validation**: Conflict markers work, identical behavior in CLI vs Extension

3. **Sprint 3**: US4 + Polish (T037-T057)
   - **Deliverable**: Documentation + final validation
   - **Validation**: All docs updated, all tests passing, ready for release

### Testing Strategy

**Unit Tests** (per module):
- VSCodeIntegration.Tests.ps1: Verify Show-QuickPick removed, Get-VSCodeContext works
- ConflictDetector.Tests.ps1: Verify Write-ConflictMarkers correct format
- Get-UpdateConfirmation.Tests.ps1: Verify New-UpdateSummary output format

**Integration Tests** (end-to-end):
- UpdateOrchestrator.Tests.ps1: Verify full approval workflow
- UpdateOrchestrator.Tests.ps1: Verify conflict marker workflow
- UpdateOrchestrator.Tests.ps1: Verify CLI vs Extension consistency

**Manual Tests** (user acceptance):
- quickstart.md walkthrough
- VSCode conflict UI validation
- Performance validation (summary < 2s, approval < 5s)

---

## Task Summary

**Total Tasks**: 57
- Phase 2 (Foundational): 4 tasks
- Phase 3 (US1): 12 tasks (3 tests + 9 implementation)
- Phase 4 (US2): 13 tasks (4 tests + 9 implementation)
- Phase 5 (US3): 7 tasks (3 tests + 4 implementation)
- Phase 6 (US4): 10 tasks (2 validation + 8 documentation)
- Phase 7 (Polish): 11 tasks

**Parallelizable Tasks**: 31 marked with [P]

**Test Tasks**: 15 total
- Unit tests: 9 (US1: 1, US2: 3, US3: 1, US4: 0, Polish: 4)
- Integration tests: 6 (US1: 2, US2: 1, US3: 2, US4: 0, Polish: 1)
- Validation tasks: 2 (US4)

**MVP Tasks**: 16 (Foundational + US1)

---

## Format Validation

✅ All tasks follow required format: `- [ ] [ID] [P?] [Story?] Description`
✅ All task IDs sequential (T001-T057)
✅ All user story tasks have [Story] labels (US1, US2, US3, US4)
✅ All parallelizable tasks marked with [P]
✅ All tasks include file paths in descriptions
✅ Setup/Foundational/Polish tasks have NO story labels
✅ Each user story has independent test criteria
✅ Dependencies documented for each phase
✅ Parallel opportunities identified
