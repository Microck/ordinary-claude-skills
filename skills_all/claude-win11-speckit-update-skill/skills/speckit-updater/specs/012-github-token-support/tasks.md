# Tasks: GitHub Personal Access Token Support

**Input**: Design documents from `/specs/012-github-token-support/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Organization**: Tasks are grouped to reflect that the core implementation satisfies multiple user stories simultaneously. The PowerShell module modification is not decomposable by user story, but testing and documentation are organized by story to demonstrate independent validation.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task validates (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions
- **Single project**: `scripts/modules/`, `tests/unit/`, `tests/integration/`
- **Documentation**: Root-level files (README.md, CLAUDE.md, CHANGELOG.md)

---

## Phase 1: Core Token Authentication Implementation

**Purpose**: Implement token detection, authorization header injection, and verbose logging in GitHubApiClient module. This single implementation simultaneously enables US1 (backward compatibility), US2 (authenticated requests), and US5 (enhanced error messages).

**⚠️ Implementation Note**: These tasks modify the same function (`Invoke-GitHubApiRequest`) and must be completed sequentially as a cohesive unit. They cannot be parallelized despite serving multiple user stories.

- [X] T001 Add token detection logic to Invoke-GitHubApiRequest in scripts/modules/GitHubApiClient.psm1
- [X] T002 Add Authorization Bearer header construction when token present in scripts/modules/GitHubApiClient.psm1
- [X] T003 Add conditional verbose logging for authentication status in scripts/modules/GitHubApiClient.psm1
- [X] T004 Parse rate limit response headers (X-RateLimit-Remaining, X-RateLimit-Reset) in scripts/modules/GitHubApiClient.psm1
- [X] T005 Implement Unix timestamp to local DateTime conversion for reset time display in scripts/modules/GitHubApiClient.psm1
- [X] T006 Add conditional error message enhancement (show token tip only without token) in scripts/modules/GitHubApiClient.psm1
- [X] T007 Add documentation link to rate limit error messages in scripts/modules/GitHubApiClient.psm1
- [X] T008 Update comment-based help documentation for Invoke-GitHubApiRequest in scripts/modules/GitHubApiClient.psm1

**Checkpoint**: Core functionality complete - token authentication works end-to-end

---

## Phase 2: Unit Tests (Organized by User Story Validation)

**Purpose**: Validate each user story requirement through focused unit tests using Pester mocking

### User Story 1 Tests (Backward Compatibility - P1)

**Story Goal**: Verify system works without token (maintains current behavior)

- [X] T009 [P] [US1] Add unit test: unauthenticated request has no Authorization header in tests/unit/GitHubApiClient.Tests.ps1
- [X] T010 [P] [US1] Add unit test: verbose output shows unauthenticated status in tests/unit/GitHubApiClient.Tests.ps1
- [X] T011 [P] [US1] Add unit test: existing tests still pass without token set in tests/unit/GitHubApiClient.Tests.ps1

**Checkpoint US1**: Can verify backward compatibility independently

### User Story 2 Tests (Authenticated Requests - P1)

**Story Goal**: Verify authenticated requests work with 5,000/hour rate limit

- [X] T012 [P] [US2] Add unit test: token detection when GITHUB_TOKEN environment variable set in tests/unit/GitHubApiClient.Tests.ps1
- [X] T013 [P] [US2] Add unit test: Authorization header constructed as "Bearer {token}" in tests/unit/GitHubApiClient.Tests.ps1
- [X] T014 [P] [US2] Add unit test: verbose output shows authenticated status with 5,000 req/hour in tests/unit/GitHubApiClient.Tests.ps1
- [X] T015 [P] [US2] Add unit test: token value never appears in verbose output (security check) in tests/unit/GitHubApiClient.Tests.ps1

**Checkpoint US2**: Can verify authenticated requests independently

### User Story 5 Tests (Error Message Guidance - P3)

**Story Goal**: Verify rate limit errors provide helpful guidance

- [X] T016 [P] [US5] Add unit test: rate limit error without token includes setup tip in tests/unit/GitHubApiClient.Tests.ps1
- [X] T017 [P] [US5] Add unit test: rate limit error without token includes documentation link in tests/unit/GitHubApiClient.Tests.ps1
- [X] T018 [P] [US5] Add unit test: rate limit error WITH token does NOT show setup tip in tests/unit/GitHubApiClient.Tests.ps1
- [X] T019 [P] [US5] Add unit test: rate limit error shows reset time in local timezone in tests/unit/GitHubApiClient.Tests.ps1
- [X] T020 [P] [US5] Add unit test: invalid token (401) produces clear error message in tests/unit/GitHubApiClient.Tests.ps1

**Checkpoint US5**: Can verify error guidance independently

---

## Phase 3: Integration Tests

**Purpose**: Validate real GitHub API integration with actual authentication

**⚠️ Note**: Integration tests use `$env:GITHUB_TEST_TOKEN` and are skipped if not set (optional for CI/CD)

- [X] T021 [P] [US2] Create integration test file tests/integration/GitHubToken.Tests.ps1
- [X] T022 [US2] Add integration test: authenticated request to real GitHub API succeeds in tests/integration/GitHubToken.Tests.ps1
- [X] T023 [US2] Add integration test: rate limit comparison (authenticated limit > unauthenticated) in tests/integration/GitHubToken.Tests.ps1
- [X] T024 [US2] Add integration test: token value never exposed in any output stream in tests/integration/GitHubToken.Tests.ps1

**Checkpoint US2/US3/US4**: Real API authentication validated (US3 and US4 use same mechanism as US2)

---

## Phase 4: Documentation & CI/CD Examples

**Purpose**: Document token setup for different user personas and environments

### User Story 2 Documentation (Developer Workflow)

- [X] T025 [P] [US2] Add "Using GitHub Tokens" section to README.md with token creation steps
- [X] T026 [P] [US2] Add PowerShell session token setup example to README.md
- [X] T027 [P] [US2] Add PowerShell profile persistence example to README.md
- [X] T028 [P] [US2] Add Windows system environment variable setup to README.md

### User Story 3 Documentation (Team Collaboration)

- [X] T029 [P] [US3] Add team collaboration scenario to README.md (each member uses own token)
- [X] T030 [P] [US3] Add shared office network explanation to README.md

### User Story 4 Documentation (CI/CD Integration)

- [X] T031 [P] [US4] Add GitHub Actions integration example to README.md
- [X] T032 [P] [US4] Add Azure Pipelines integration example to README.md
- [X] T033 [P] [US4] Add Jenkins integration example to README.md
- [X] T034 [P] [US4] Add CircleCI integration example to README.md

### User Story 5 Documentation (Troubleshooting)

- [X] T035 [P] [US5] Update "Troubleshooting - GitHub API Issues" section in CLAUDE.md
- [X] T036 [P] [US5] Add rate limit error troubleshooting to CLAUDE.md
- [X] T037 [P] [US5] Add invalid token troubleshooting to CLAUDE.md
- [X] T038 [P] [US5] Add security best practices section to README.md

**Checkpoint**: All user personas have clear documentation

---

## Phase 5: Manual Testing & Validation

**Purpose**: Comprehensive manual validation of all user scenarios

### Backward Compatibility Verification (US1)

- [X] T039 [US1] Manual test: Run update without GITHUB_PAT set, verify no errors or warnings
- [X] T040 [US1] Manual test: Verify all existing functionality works identically without token
- [X] T041 [US1] Manual test: Run existing test suite without GITHUB_PAT, verify all pass
- [X] T041.1 [US1] Manual test: Verify all exit codes unchanged (0=success, 1=error, 2=prerequisites, 3=API error, 4=Git error, 5=user cancelled, 6=rollback)

### Developer Workflow Verification (US2)

- [X] T042 [US2] Manual test: Set GITHUB_PAT in session, run update with -Verbose, verify authenticated status shown
- [X] T043 [US2] Manual test: Make 20 consecutive update runs in one hour, verify no rate limiting
- [X] T044 [US2] Manual test: Verify token value never appears in verbose output (capture with 4>&1)
- [X] T044.1 [US2] Manual test: Set token, run update, change GITHUB_PAT value, run update again, verify new token used

### Team Collaboration Verification (US3)

- [X] T045 [US3] Manual test: Document team testing scenario (conceptual - same as US2 validation)
- [X] T046 [US3] Manual test: Verify token-per-user isolates rate limits (conceptual validation)

### CI/CD Integration Verification (US4)

- [X] T047 [US4] Manual test: Test GitHub Actions example workflow (if available)
- [X] T048 [US4] Manual test: Verify GITHUB_PAT from secrets works in automation context

### Error Guidance Verification (US5)

- [X] T049 [US5] Manual test: Trigger rate limit error without token, verify setup tip shown
- [X] T050 [US5] Manual test: Trigger rate limit error with token set, verify no setup tip
- [X] T051 [US5] Manual test: Use invalid token, verify clear 401 error message
- [X] T052 [US5] Manual test: Verify documentation link in error message is accessible

---

## Phase 6: Security Audit & Polish

**Purpose**: Final security verification and code cleanup

### Security Validation

- [X] T053 Audit: Verify token never logged in Write-Verbose statements across entire module
- [X] T054 Audit: Verify token never included in Write-Error or exception messages
- [X] T055 Audit: Verify token never written to any file (manifest, logs, backups)
- [X] T056 Audit: Verify all error paths handle token securely (catch blocks don't expose Authorization header)
- [X] T057 Audit: Review unit tests confirm token absence in all output streams

### Code Quality & Documentation

- [X] T058 [P] Update CHANGELOG.md with feature description under [Unreleased]
- [X] T059 [P] Review comment-based help in GitHubApiClient.psm1 for completeness
- [X] T060 [P] Add inline comments explaining token security decisions in GitHubApiClient.psm1
- [X] T061 Verify all existing tests still pass (regression check)
- [X] T062 Run PowerShell linter (PSScriptAnalyzer) on modified module

### Final Validation

- [X] T063 Run full test suite (unit + integration) and verify all pass
- [X] T064 Test all documented setup methods (session, profile, system env var)
- [X] T065 Verify cross-platform compatibility (Windows, macOS, Linux PowerShell)
- [X] T065.1 [P] Optional: Benchmark API request overhead with/without token (verify header addition <1ms)

**Checkpoint**: Feature complete, secure, and ready for merge

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Core Implementation)**: No dependencies - can start immediately
  - ⚠️ **BLOCKING**: Must complete T001-T008 sequentially before any testing
- **Phase 2 (Unit Tests)**: Depends on Phase 1 completion
  - Within Phase 2: All tests marked [P] can run in parallel
  - US1 tests, US2 tests, and US5 tests are independent (different contexts)
- **Phase 3 (Integration Tests)**: Depends on Phase 1 completion
  - Integration tests can run in parallel with Phase 2
  - Requires `$env:GITHUB_TEST_TOKEN` (optional)
- **Phase 4 (Documentation)**: Can start after Phase 1 (core implementation known)
  - All documentation tasks marked [P] can run in parallel
- **Phase 5 (Manual Testing)**: Depends on Phase 1 + Phase 4 (need docs for testing)
  - US1, US2, US5 manual tests are independent
  - US3, US4 are conceptual validations (same mechanism as US2)
- **Phase 6 (Polish)**: Depends on all previous phases

### Critical Path

```
Phase 1 (Sequential: T001-T008)
    ↓
    ├─→ Phase 2 (Parallel: T009-T020) ──┐
    ├─→ Phase 3 (Parallel: T021-T024) ──┤
    └─→ Phase 4 (Parallel: T025-T038) ──┤
                                         ↓
                                    Phase 5 (Sequential: T039-T052)
                                         ↓
                                    Phase 6 (Mixed: T053-T065)
```

### Within Each Phase

**Phase 1 (Core Implementation)**:
- **Sequential**: T001 → T002 → T003 → T004 → T005 → T006 → T007 → T008
- **Rationale**: All modify same function in dependency order

**Phase 2 (Unit Tests)**:
- **Parallel US1**: T009, T010, T011 (different test contexts)
- **Parallel US2**: T012, T013, T014, T015 (different test cases)
- **Parallel US5**: T016, T017, T018, T019, T020 (different error scenarios)
- **Cross-Story Parallel**: US1 tests || US2 tests || US5 tests (independent stories)

**Phase 3 (Integration Tests)**:
- **Sequential within**: T021 (create file) → T022, T023, T024 (add tests)
- **Parallel**: T022, T023, T024 can run together (different test cases)

**Phase 4 (Documentation)**:
- **Fully Parallel**: All T025-T038 (different files/sections)

**Phase 5 (Manual Testing)**:
- **Sequential per story**: Test each story's scenarios in order
- **Parallel across stories**: US1 tests || US2 tests || US5 tests (if multiple testers)

**Phase 6 (Polish)**:
- **Parallel audits**: T053-T057 (different security checks)
- **Parallel docs**: T058, T059, T060 (different files)
- **Sequential final**: T061 → T062 → T063 → T064 → T065 (verification order)

---

## Parallel Execution Examples

### Example 1: Phase 2 Unit Tests (Maximum Parallelization)

```bash
# Launch all US1 tests together:
Task: "[US1] unauthenticated request has no Authorization header" (T009)
Task: "[US1] verbose output shows unauthenticated status" (T010)
Task: "[US1] existing tests still pass without token" (T011)

# Simultaneously launch all US2 tests:
Task: "[US2] token detection when GITHUB_TOKEN set" (T012)
Task: "[US2] Authorization header constructed as Bearer" (T013)
Task: "[US2] verbose output shows authenticated status" (T014)
Task: "[US2] token value never in verbose output" (T015)

# Simultaneously launch all US5 tests:
Task: "[US5] rate limit error without token includes tip" (T016)
Task: "[US5] rate limit error without token includes link" (T017)
Task: "[US5] rate limit error with token no tip" (T018)
Task: "[US5] rate limit error shows reset time" (T019)
Task: "[US5] invalid token produces clear error" (T020)
```

### Example 2: Phase 4 Documentation (All Parallel)

```bash
# Launch all documentation tasks together (different files/sections):
Task: "Add Using GitHub Tokens section to README.md" (T025)
Task: "Add PowerShell session example to README.md" (T026)
Task: "Add PowerShell profile example to README.md" (T027)
Task: "Add Windows env var setup to README.md" (T028)
Task: "Add team collaboration to README.md" (T029)
Task: "Add GitHub Actions example to README.md" (T031)
Task: "Add Azure Pipelines example to README.md" (T032)
Task: "Add Jenkins example to README.md" (T033)
Task: "Update CLAUDE.md troubleshooting" (T035)
Task: "Add rate limit troubleshooting to CLAUDE.md" (T036)
# ... and so on for all [P] tasks in Phase 4
```

---

## Implementation Strategy

### MVP First (User Story 1 + 2 Combined)

**Goal**: Minimal viable implementation - token authentication works, backward compatible

1. Complete Phase 1: Core Implementation (T001-T008) → **Core done**
2. Complete Phase 2: US1 + US2 tests only (T009-T015) → **Basic validation**
3. Complete Phase 5: US1 + US2 manual tests (T039-T044, T041.1, T044.1) → **MVP verified**
4. **STOP and VALIDATE**: Demonstrate token auth works, backward compatible, exit codes maintained
5. Deploy/demo if ready

**At this point**: Feature works for developers, no documentation yet

### Incremental Delivery

1. **MVP** (Phase 1 + US1/US2 tests) → Token authentication functional
2. **+ Error Guidance** (US5 tests + docs T016-T020, T035-T038) → Enhanced UX
3. **+ Team/CI Documentation** (US3/US4 docs T029-T034) → Enterprise ready
4. **+ Full Polish** (Phase 6) → Production ready

### Parallel Team Strategy

With multiple developers after Phase 1 completes:

- **Developer A**: Phase 2 (Unit Tests) - T009-T020
- **Developer B**: Phase 3 (Integration Tests) - T021-T024
- **Developer C**: Phase 4 (Documentation) - T025-T038

Once Phase 2/3/4 complete:

- **Developer A**: Phase 5 (Manual Testing US1/US2) - T039-T044
- **Developer B**: Phase 5 (Manual Testing US3/US4) - T045-T048
- **Developer C**: Phase 5 (Manual Testing US5) - T049-T052

Finally:

- **All together**: Phase 6 (Security Audit + Polish) - T053-T065

---

## User Story Independence Validation

### How Each Story is Independently Testable

**User Story 1 (Backward Compatibility - P1)**:
- **Tests**: T009-T011, T039-T041, T041.1
- **Validation**: Run updater WITHOUT setting GITHUB_TOKEN, verify works exactly as before, verify exit codes unchanged
- **Success**: No behavior changes, no errors, existing tests pass, exit codes maintained

**User Story 2 (Developer Workflow - P1)**:
- **Tests**: T012-T015, T021-T024, T042-T044, T044.1
- **Validation**: Set GITHUB_TOKEN, run updater with -Verbose, make 20+ runs, test mid-session token change
- **Success**: Authenticated status shown, 5,000/hour limit, token never exposed, token changes respected

**User Story 3 (Team Collaboration - P2)**:
- **Tests**: T045-T046 (conceptual validation using US2 tests)
- **Validation**: Document that each team member sets their own token
- **Success**: Rate limits are per-user (same mechanism as US2)

**User Story 4 (CI/CD Integration - P2)**:
- **Tests**: T047-T048, Documentation T031-T034
- **Validation**: Test GitHub Actions workflow, verify secrets work
- **Success**: Automation works with token from CI secrets (same mechanism as US2)

**User Story 5 (Error Guidance - P3)**:
- **Tests**: T016-T020, T049-T052
- **Validation**: Trigger rate limit errors with/without token, test invalid token
- **Success**: Helpful messages, conditional guidance, documentation link

---

## Notes

- **[P] tasks**: Can run in parallel (different files, test contexts, or documentation sections)
- **[Story] labels**: Map tasks to user stories for traceability
- **Core Implementation** (Phase 1): Not decomposable by story - all US1/US2/US5 requirements implemented together in same function
- **Testing & Documentation**: Organized by story to demonstrate independent validation
- **US3 and US4**: No additional code beyond US2 - same token mechanism, just different usage contexts (team vs CI/CD)
- **Security Priority**: Token exposure prevention is critical - Phase 6 audit must pass before merge
- **Backward Compatibility**: US1 tests must pass WITHOUT any token set to verify no breaking changes

---

## Task Count Summary

- **Total Tasks**: 68 (increased from 65 after analysis remediation)
- **Phase 1 (Core)**: 8 tasks (sequential)
- **Phase 2 (Unit Tests)**: 12 tasks (11 parallel within stories)
- **Phase 3 (Integration)**: 4 tasks (3 parallel after file creation)
- **Phase 4 (Documentation)**: 14 tasks (all parallel)
- **Phase 5 (Manual Testing)**: 16 tasks (sequential per story, parallel across stories) - *+2 tasks: exit code verification (T041.1), mid-session token change (T044.1)*
- **Phase 6 (Polish)**: 14 tasks (mixed parallel/sequential) - *+1 task: optional performance benchmark (T065.1)*

**Parallel Opportunities**: 39 tasks marked [P] (57% parallelizable)

**User Story Coverage**:
- **US1 (P1)**: 7 tasks (T009-T011, T039-T041, T041.1)
- **US2 (P1)**: 17 tasks (T012-T015, T021-T028, T042-T044, T044.1)
- **US3 (P2)**: 4 tasks (T029-T030, T045-T046)
- **US4 (P2)**: 6 tasks (T031-T034, T047-T048)
- **US5 (P3)**: 13 tasks (T016-T020, T035-T038, T049-T052)
- **Core + Polish**: 21 tasks (T001-T008, T053-T065, T065.1)

**MVP Scope (US1+US2 only)**: 32 tasks (T001-T015, T021-T028, T039-T044, T041.1, T044.1) - 47% of total
