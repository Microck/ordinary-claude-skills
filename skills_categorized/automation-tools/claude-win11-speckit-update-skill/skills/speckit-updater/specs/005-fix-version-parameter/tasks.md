# Tasks: Fix Version Parameter Handling in Update Orchestrator

**Input**: Design documents from `/specs/005-fix-version-parameter/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, quickstart.md

**Tests**: Test tasks are included because the constitution requires testing discipline for all modules.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions
- PowerShell module-based project
- Modules: `scripts/modules/`
- Orchestrator: `scripts/update-orchestrator.ps1`
- Tests: `tests/unit/` and `tests/integration/`
- Fixtures: `tests/fixtures/mock-responses/`

---

## Phase 1: Setup (Test Infrastructure)

**Purpose**: Create test fixtures and directory structure for mock GitHub API responses

- [X] T001 Create mock-responses directory at tests/fixtures/mock-responses/
- [X] T002 [P] Create valid-release.json fixture with complete GitHub release structure in tests/fixtures/mock-responses/valid-release.json
- [X] T003 [P] Create missing-tag-name.json fixture with malformed release response in tests/fixtures/mock-responses/missing-tag-name.json
- [X] T004 [P] Create empty-response.json fixture with null response in tests/fixtures/mock-responses/empty-response.json
- [X] T005 [P] Create invalid-version-format.json fixture with non-semantic version in tests/fixtures/mock-responses/invalid-version-format.json

---

## Phase 2: Foundational (Core Error Handling Infrastructure)

**Purpose**: Core refactoring that ALL user stories depend on - validation framework, error handling, and parameter standardization

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T006 Enhance Invoke-GitHubApiRequest function with structured error handling for HTTP status codes in scripts/modules/GitHubApiClient.psm1
- [X] T007 Add error classification helper function Get-ErrorClassification in scripts/modules/GitHubApiClient.psm1
- [X] T008 [P] Standardize parameter naming in Get-OfficialSpecKitCommands from -SpecKitVersion to -Version in scripts/modules/ManifestManager.psm1
- [X] T009 [P] Add Write-Verbose logging to all validation checkpoints in scripts/modules/GitHubApiClient.psm1
- [X] T010 Update function comment-based help to document new error handling behavior in scripts/modules/ManifestManager.psm1
- [X] T011 [P] Add timeout parameter (30 seconds) to Invoke-RestMethod calls in Invoke-GitHubApiRequest in scripts/modules/GitHubApiClient.psm1

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Automatic Latest Version Update (Priority: P1) 🎯 MVP

**Goal**: Enable users to run updates without specifying a version, automatically fetching the latest from GitHub Releases

**Independent Test**: Run `update-orchestrator.ps1 -CheckOnly` without `-Version` parameter and verify it fetches and displays the latest version

### Tests for User Story 1

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T012 [P] [US1] Add unit test for Get-LatestSpecKitRelease with successful response in tests/unit/GitHubApiClient.Tests.ps1
- [X] T013 [P] [US1] Add unit test for Get-LatestSpecKitRelease with null response in tests/unit/GitHubApiClient.Tests.ps1
- [X] T014 [P] [US1] Add unit test for Get-LatestSpecKitRelease with missing tag_name property in tests/unit/GitHubApiClient.Tests.ps1

### Implementation for User Story 1

- [X] T015 [US1] Add response validation to Get-LatestSpecKitRelease to check for null response in scripts/modules/GitHubApiClient.psm1
- [X] T016 [US1] Add property validation to Get-LatestSpecKitRelease to check for tag_name existence in scripts/modules/GitHubApiClient.psm1
- [X] T017 [US1] Add property validation to Get-LatestSpecKitRelease to check for assets array existence in scripts/modules/GitHubApiClient.psm1
- [X] T018 [US1] Add tag_name format validation using regex pattern in Get-LatestSpecKitRelease in scripts/modules/GitHubApiClient.psm1
- [X] T019 [US1] Add defensive null check for $targetRelease after Get-LatestSpecKitRelease call in scripts/update-orchestrator.ps1 (after line 229)
- [X] T020 [US1] Add defensive property check for $targetRelease.tag_name in scripts/update-orchestrator.ps1 (after line 229)
- [X] T021 [US1] Add Write-Verbose logging after successful validation in scripts/update-orchestrator.ps1
- [X] T022 [US1] Update error exit code to 3 for GitHub API failures in scripts/update-orchestrator.ps1

**Checkpoint**: At this point, automatic latest version fetching should work reliably with validation

---

## Phase 4: User Story 2 - Clear Error Messages for API Failures (Priority: P2)

**Goal**: Provide actionable error messages when GitHub API fails, including network errors, rate limiting, and invalid responses

**Independent Test**: Simulate network failure or rate limiting and verify error messages are clear and actionable

### Tests for User Story 2

- [X] T023 [P] [US2] Add unit test for network failure scenario in tests/unit/GitHubApiClient.Tests.ps1
- [X] T024 [P] [US2] Add unit test for rate limit exceeded (HTTP 403) scenario in tests/unit/GitHubApiClient.Tests.ps1
- [X] T025 [P] [US2] Add unit test for not found (HTTP 404) scenario in tests/unit/GitHubApiClient.Tests.ps1
- [X] T026 [P] [US2] Add unit test for server error (HTTP 500-599) scenario in tests/unit/GitHubApiClient.Tests.ps1
- [X] T027 [P] [US2] Add unit test for invalid JSON response scenario in tests/unit/GitHubApiClient.Tests.ps1

### Implementation for User Story 2

- [X] T028 [US2] Add rate limit reset time extraction from X-RateLimit-Reset header in Invoke-GitHubApiRequest in scripts/modules/GitHubApiClient.psm1
- [X] T029 [US2] Add specific error message for HTTP 403 rate limit with reset time in Invoke-GitHubApiRequest in scripts/modules/GitHubApiClient.psm1
- [X] T030 [US2] Add specific error message for HTTP 404 not found with URI in Invoke-GitHubApiRequest in scripts/modules/GitHubApiClient.psm1
- [X] T031 [US2] Add specific error message for HTTP 500-599 server errors in Invoke-GitHubApiRequest in scripts/modules/GitHubApiClient.psm1
- [X] T032 [US2] Add specific error message for network failures (no Response object) in Invoke-GitHubApiRequest in scripts/modules/GitHubApiClient.psm1
- [X] T033 [US2] Add specific error message for empty response validation failure in Get-LatestSpecKitRelease in scripts/modules/GitHubApiClient.psm1
- [X] T034 [US2] Add specific error message for missing tag_name validation failure in Get-LatestSpecKitRelease in scripts/modules/GitHubApiClient.psm1
- [X] T035 [US2] Add specific error message for invalid tag_name format validation failure in Get-LatestSpecKitRelease in scripts/modules/GitHubApiClient.psm1

**Checkpoint**: At this point, all error scenarios should provide clear, actionable messages

---

## Phase 5: User Story 3 - Explicit Version Override (Priority: P3)

**Goal**: Ensure explicit version specification continues to work correctly after implementing automatic version detection

**Independent Test**: Run `update-orchestrator.ps1 -CheckOnly -Version v0.0.72` and verify it uses the specified version instead of fetching latest

### Tests for User Story 3

- [X] T036 [P] [US3] Add unit test for Get-SpecKitRelease with valid version in tests/unit/GitHubApiClient.Tests.ps1
- [X] T037 [P] [US3] Add unit test for Get-SpecKitRelease with invalid version (404) in tests/unit/GitHubApiClient.Tests.ps1
- [ ] T038 [P] [US3] Add integration test for explicit version workflow in tests/integration/UpdateOrchestrator.Tests.ps1

### Implementation for User Story 3

- [X] T039 [US3] Add same validation logic to Get-SpecKitRelease for consistency with Get-LatestSpecKitRelease in scripts/modules/GitHubApiClient.psm1
- [X] T040 [US3] Verify explicit version path in orchestrator has same defensive null checks in scripts/update-orchestrator.ps1 (after line 226)
- [X] T041 [US3] Add Write-Verbose logging for explicit version specification in scripts/update-orchestrator.ps1
- [X] T042 [US3] Update Get-OfficialSpecKitCommands call site to use -Version parameter name in scripts/update-orchestrator.ps1 (line 291)

**Checkpoint**: All user stories should now be independently functional - automatic detection, clear errors, and explicit override all work

---

## Phase 6: Integration Testing & Validation

**Purpose**: End-to-end testing and cross-story validation

- [ ] T043 [P] Add integration test for orchestrator with successful GitHub API call in tests/integration/UpdateOrchestrator.Tests.ps1
- [ ] T044 [P] Add integration test for orchestrator with GitHub API failure in tests/integration/UpdateOrchestrator.Tests.ps1
- [ ] T045 [P] Add integration test for orchestrator with rate limiting in tests/integration/UpdateOrchestrator.Tests.ps1
- [ ] T046 Run all unit tests and verify they pass using ./tests/test-runner.ps1 -Unit
- [ ] T047 Run all integration tests and verify they pass using ./tests/test-runner.ps1 -Integration
- [ ] T048 Manually test all scenarios from quickstart.md in a real SpecKit project
- [ ] T049 [P] Add unit test for API timeout scenario with mock delayed response in tests/unit/GitHubApiClient.Tests.ps1
- [ ] T050 [P] Add integration test for "already up-to-date" scenario in tests/integration/UpdateOrchestrator.Tests.ps1
- [ ] T051 [P] Add integration test for corrupted manifest.json handling in tests/integration/UpdateOrchestrator.Tests.ps1

---

## Phase 7: Polish & Documentation

**Purpose**: Documentation, cleanup, and final validation

- [X] T052 [P] Update CHANGELOG.md with bug fix details under [Unreleased] section
- [X] T053 [P] Update docs/bugs/003-missing-speckit-version-parameter.md with resolution notes
- [ ] T054 [P] Add troubleshooting section to CLAUDE.md for GitHub API issues
- [X] T055 Review code for PowerShell style compliance (PascalCase functions, camelCase variables)
- [ ] T056 Run full test suite with coverage using ./tests/test-runner.ps1 -Coverage
- [ ] T057 Close GitHub issue #6 with verification notes and test results

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Integration (Phase 6)**: Depends on all user stories being complete
- **Polish (Phase 7)**: Depends on Integration phase completion

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Independent of US1 (different error handling code paths)
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Independent of US1/US2 (separate function path)

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Validation logic before orchestrator integration
- Error handling before error messages
- Core implementation before logging/polish

### Parallel Opportunities

- **Phase 1**: All fixture creation tasks (T002-T005) can run in parallel
- **Phase 2**: T008 (parameter rename), T009 (logging), and T011 (timeout) can run in parallel with T006-T007
- **User Story 1 Tests**: T012-T014 can run in parallel
- **User Story 2 Tests**: T023-T027 can run in parallel
- **User Story 2 Implementation**: T028-T035 can run in parallel (different error code paths)
- **User Story 3 Tests**: T036-T038 can run in parallel
- **Integration Tests**: T043-T045 can run in parallel
- **Edge Case Tests**: T049-T051 can run in parallel
- **Polish Tasks**: T052-T054 can run in parallel
- **User Stories 1, 2, 3**: Can be worked on in parallel by different developers after Phase 2

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Add unit test for Get-LatestSpecKitRelease with successful response in tests/unit/GitHubApiClient.Tests.ps1"
Task: "Add unit test for Get-LatestSpecKitRelease with null response in tests/unit/GitHubApiClient.Tests.ps1"
Task: "Add unit test for Get-LatestSpecKitRelease with missing tag_name property in tests/unit/GitHubApiClient.Tests.ps1"
```

## Parallel Example: User Story 2 Error Messages

```bash
# Launch all error message implementations together (independent code paths):
Task: "T029 - Add specific error message for HTTP 403 rate limit with reset time in Invoke-GitHubApiRequest"
Task: "T030 - Add specific error message for HTTP 404 not found with URI in Invoke-GitHubApiRequest"
Task: "T031 - Add specific error message for HTTP 500-599 server errors in Invoke-GitHubApiRequest"
Task: "T032 - Add specific error message for network failures in Invoke-GitHubApiRequest"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T005 - create test fixtures)
2. Complete Phase 2: Foundational (T006-T011 - CRITICAL - core error handling infrastructure)
3. Complete Phase 3: User Story 1 (T012-T022 - automatic latest version detection)
4. **STOP and VALIDATE**: Test User Story 1 independently using quickstart.md scenarios
5. Deploy/merge if ready

**Result**: Users can now run updates without specifying versions - primary bug is fixed!

**MVP Tasks**: T001-T022 (22 tasks total)

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → **Deploy/Merge (MVP!)**
3. Add User Story 2 → Test independently → **Deploy/Merge** (better error messages)
4. Add User Story 3 → Test independently → **Deploy/Merge** (explicit version validated)
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (small, quick)
2. Once Foundational is done:
   - Developer A: User Story 1 (automatic version detection)
   - Developer B: User Story 2 (error messages)
   - Developer C: User Story 3 (explicit version validation)
3. Stories complete and integrate independently
4. Integration testing after all stories complete

---

## Task Count Summary

- **Phase 1 (Setup)**: 5 tasks
- **Phase 2 (Foundational)**: 6 tasks (includes timeout configuration)
- **Phase 3 (User Story 1)**: 11 tasks (3 tests + 8 implementation)
- **Phase 4 (User Story 2)**: 13 tasks (5 tests + 8 implementation)
- **Phase 5 (User Story 3)**: 7 tasks (3 tests + 4 implementation)
- **Phase 6 (Integration)**: 9 tasks (includes 3 edge case tests)
- **Phase 7 (Polish)**: 6 tasks

**Total**: 57 tasks

**Parallel Opportunities**:
- 35 tasks marked [P] can run in parallel within their phase
- User Stories 1, 2, 3 can run completely in parallel after Phase 2

---

## Verification Checklist

### Functional Requirements Coverage

- [ ] **FR-001**: T015-T022 (User Story 1 - fetch latest version)
- [ ] **FR-002**: T015-T017 (User Story 1 - validate API response)
- [ ] **FR-003**: T028-T035 (User Story 2 - clear error messages)
- [ ] **FR-004**: T016, T018 (User Story 1 - extract version correctly)
- [ ] **FR-005**: T008, T042 (Foundational - parameter naming)
- [ ] **FR-006**: T028-T029 (User Story 2 - rate limiting)
- [ ] **FR-007**: T016-T017 (User Story 1 - validate required fields)
- [ ] **FR-008**: T039-T042 (User Story 3 - explicit version)
- [ ] **FR-009**: T009, T021, T041 (Foundational + all stories - verbose logging)
- [ ] **FR-010**: T006, T011, T049 (Foundational - timeout handling and test)

### Success Criteria Coverage

- [ ] **SC-001**: T015-T022 (automatic version detection works)
- [ ] **SC-002**: T028-T035 (error messages within 3 seconds)
- [ ] **SC-003**: T008, T042 (100% parameter name consistency)
- [ ] **SC-004**: T015-T020 (all API responses validated)
- [ ] **SC-005**: T039-T042 (explicit version works)
- [ ] **SC-006**: T028-T035 (users can identify error type)
- [ ] **SC-007**: T043-T051 (integration testing validates success rate including edge cases)

---

## Notes

- [P] tasks = different files or independent code paths, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable
- Tests must fail before implementing (TDD approach)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Constitution compliance: All modules have tests, no nested imports, modular architecture maintained
