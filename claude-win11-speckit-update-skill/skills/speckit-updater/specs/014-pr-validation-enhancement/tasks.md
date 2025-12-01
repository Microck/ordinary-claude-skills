# Tasks: PR Validation Workflow Enhancement

**Input**: Design documents from `/specs/014-pr-validation-enhancement/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Tests are REQUIRED per project constitution (Principle V: Testing Discipline). All validation scripts MUST have corresponding Pester unit tests.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions
- Validation scripts: `.github/scripts/`
- Unit tests: `tests/unit/`
- Integration tests: `tests/integration/`
- Test fixtures: `tests/fixtures/`
- Workflow: `.github/workflows/pr-validation.yml`
- Documentation: `docs/workflows/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and directory structure

- [X] T001 Create `.github/scripts/` directory for validation scripts
- [X] T002 Create `tests/fixtures/vulnerable-code-samples/` directory for security test data
- [X] T003 [P] Create `tests/fixtures/spec-structures/` directory for spec validation test data
- [X] T004 [P] Create `tests/fixtures/pr-comment-examples/` directory for expected comment outputs
- [X] T005 [P] Create `docs/workflows/` directory for workflow documentation

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core PR comment infrastructure that ALL user stories depend on. This implements User Story 4 (Comment Update-in-Place) behavior as foundational requirement.

**⚠️ CRITICAL**: No user story validation work can begin until this phase is complete

### Comment Formatter

- [X] T006 [P] Create `format-pr-comment.ps1` script in `.github/scripts/` with JSON input parsing
- [X] T007 [P] Implement Markdown formatting logic in `format-pr-comment.ps1` (status indicators, sections, timestamps)
- [X] T008 Implement HTML marker generation in `format-pr-comment.ps1` (format: `<!-- pr-validation:step-N -->`)
- [X] T009 [P] Create `FormatPRComment.Tests.ps1` in `tests/unit/` to test comment formatting
- [X] T010 [P] Add test fixtures for comment formatter in `tests/fixtures/pr-comment-examples/` (pass, warning, failed scenarios)

### Comment Posting Infrastructure (User Story 4 Implementation)

- [X] T011 [US4] Create reusable GitHub Actions workflow step for posting/updating PR comments in `.github/workflows/pr-validation.yml`
- [X] T012 [US4] Implement comment search logic using HTML markers (find existing comment by marker)
- [X] T013 [US4] Implement update-in-place logic (update existing comment if found, create if not)
- [X] T014 [US4] Add permissions block to workflow (`pull-requests: write`, `issues: write`)
- [ ] T015 [P] [US4] Create test fixture PR comment examples showing update behavior in `tests/fixtures/pr-comment-examples/update-scenarios/`

### Test Infrastructure

- [X] T016 [P] Create sample vulnerable code in `tests/fixtures/vulnerable-code-samples/` (API key, Invoke-Expression, path concatenation)
- [X] T017 [P] Create valid spec structure in `tests/fixtures/spec-structures/valid-spec/` (spec.md, plan.md, tasks.md)
- [X] T018 [P] Create invalid spec structures in `tests/fixtures/spec-structures/` (missing-tasks, missing-changelog, etc.)

---

## Phase 3: User Story 1 - Contributor Receives Immediate Security Feedback (Priority: P1)

**Goal**: Detect and report security vulnerabilities (secrets, security anti-patterns, path traversal, dependency CVEs) in PR comments within 3 minutes

**Independent Test**: Submit PR with hardcoded API key, verify comment appears within 3 minutes with file:line reference and remediation guidance

### Tests for User Story 1

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T019 [P] [US1] Create `CheckDependencies.Tests.ps1` in `tests/unit/` with test cases for vulnerable versions
- [X] T020 [P] [US1] Create `CheckPathSecurity.Tests.ps1` in `tests/unit/` with test cases for unsafe path patterns
- [X] T021 [P] [US1] Create test case in `CheckPathSecurity.Tests.ps1` for safe Join-Path usage (should pass)
- [X] T022 [P] [US1] Create test case in `CheckDependencies.Tests.ps1` for current safe versions (should pass)

### Implementation for User Story 1

#### Dependency Scanning

- [X] T023 [P] [US1] Create `check-dependencies.ps1` in `.github/scripts/` with parameter definition
- [X] T024 [US1] Implement Pester version check logic in `check-dependencies.ps1` (check against known vulnerable versions)
- [X] T025 [US1] Implement PSScriptAnalyzer version check logic in `check-dependencies.ps1`
- [X] T026 [US1] Add JSON output generation in `check-dependencies.ps1` (ValidationResult schema)
- [X] T027 [US1] Verify `CheckDependencies.Tests.ps1` tests now pass

#### Path Traversal Detection

- [X] T028 [P] [US1] Create `check-path-security.ps1` in `.github/scripts/` with parameter definition
- [X] T029 [US1] Implement unsafe concatenation pattern detection in `check-path-security.ps1` (`$path + "\"`regex)
- [X] T030 [US1] Implement unsafe interpolation pattern detection in `check-path-security.ps1` (`"$path\file"` regex)
- [X] T031 [US1] Implement `..` traversal detection in `check-path-security.ps1`
- [X] T032 [US1] Add safe pattern exceptions in `check-path-security.ps1` (Join-Path, Path::Combine)
- [X] T033 [US1] Add JSON output generation in `check-path-security.ps1` (ValidationResult schema)
- [X] T034 [US1] Verify `CheckPathSecurity.Tests.ps1` tests now pass

#### Workflow Step 5 Integration

- [X] T035 [US1] Add Step 5 job `claude-security-scan` to `.github/workflows/pr-validation.yml`
- [X] T036 [US1] Add `continue-on-error: true` to Step 5 (non-blocking behavior)
- [X] T037 [US1] Add GitLeaks action step in Step 5 (`gitleaks/gitleaks-action@v2`)
- [X] T038 [US1] Add PSScriptAnalyzer security rules step in Step 5 (IncludeRule: PSAvoidUsingPlainTextForPassword, PSAvoidUsingInvokeExpression, etc.)
- [X] T039 [US1] Add `check-dependencies.ps1` invocation in Step 5
- [X] T040 [US1] Add `check-path-security.ps1` invocation in Step 5
- [X] T041 [US1] Add result aggregation step in Step 5 (combine all security check outputs)
- [X] T042 [US1] Add `format-pr-comment.ps1` invocation in Step 5 for security results
- [X] T043 [US1] Add PR comment posting step in Step 5 using foundational infrastructure

#### Integration Testing

- [X] T044 [US1] Create `PRValidationWorkflow.Tests.ps1` in `tests/integration/` with Step 5 security tests
- [X] T045 [US1] Add test case for GitLeaks secret detection in integration test
- [X] T046 [US1] Add test case for PSScriptAnalyzer security rule violation in integration test
- [X] T047 [US1] Add test case for dependency vulnerability in integration test
- [X] T048 [US1] Add test case for path traversal detection in integration test

---

## Phase 4: User Story 2 - Contributor Ensures Spec Compliance (Priority: P2)

**Goal**: Validate SpecKit artifacts (spec.md, plan.md, tasks.md), CHANGELOG updates, and constitution compliance, reporting findings in PR comments

**Independent Test**: Create feature branch `015-test-feature` without spec directory, submit PR, verify comment identifies missing spec artifacts

### Tests for User Story 2

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T049 [P] [US2] Create `CheckSpecCompliance.Tests.ps1` in `tests/unit/` with test case for missing spec directory
- [X] T050 [P] [US2] Add test case in `CheckSpecCompliance.Tests.ps1` for missing tasks.md
- [X] T051 [P] [US2] Add test case in `CheckSpecCompliance.Tests.ps1` for missing CHANGELOG entry
- [X] T052 [P] [US2] Add test case in `CheckSpecCompliance.Tests.ps1` for missing Export-ModuleMember
- [X] T053 [P] [US2] Add test case in `CheckSpecCompliance.Tests.ps1` for valid spec structure (should pass)

### Implementation for User Story 2

#### Spec Compliance Script

- [X] T054 [P] [US2] Create `check-spec-compliance.ps1` in `.github/scripts/` with parameters (RepoRoot, BranchName)
- [X] T055 [US2] Implement branch name parsing logic in `check-spec-compliance.ps1` (regex: `^(\d{3})-`)
- [X] T056 [US2] Implement spec directory detection in `check-spec-compliance.ps1` (fuzzy match: `specs/NNN-*`)
- [X] T057 [US2] Implement spec artifact validation in `check-spec-compliance.ps1` (spec.md, plan.md, tasks.md existence)
- [X] T058 [US2] Implement spec.md section validation in `check-spec-compliance.ps1` (check for User Stories, Requirements, Success Criteria)
- [X] T059 [US2] Implement CHANGELOG.md validation in `check-spec-compliance.ps1` (check for [Unreleased] entry)
- [X] T060 [US2] Implement constitution compliance check in `check-spec-compliance.ps1` (Export-ModuleMember in .psm1 files)
- [X] T061 [US2] Implement nested Import-Module detection in `check-spec-compliance.ps1` (flag .psm1 files with Import-Module)
- [ ] T062 [US2] Implement test coverage check in `check-spec-compliance.ps1` (modified modules have test updates)
- [X] T063 [US2] Add JSON output generation in `check-spec-compliance.ps1` (ValidationResult schema)
- [X] T064 [US2] Verify `CheckSpecCompliance.Tests.ps1` tests now pass

#### Workflow Step 6 Integration

- [X] T065 [US2] Add Step 6 job `speckit-compliance` to `.github/workflows/pr-validation.yml`
- [X] T066 [US2] Add `continue-on-error: true` to Step 6 (non-blocking behavior)
- [X] T067 [US2] Add `check-spec-compliance.ps1` invocation in Step 6 with branch name parameter
- [X] T068 [US2] Add `format-pr-comment.ps1` invocation in Step 6 for spec compliance results
- [X] T069 [US2] Add PR comment posting step in Step 6 using foundational infrastructure

#### Integration Testing

- [X] T070 [US2] Add Step 6 tests to `PRValidationWorkflow.Tests.ps1`
- [X] T071 [US2] Add test case for missing spec directory detection in integration test
- [X] T072 [US2] Add test case for missing CHANGELOG entry detection in integration test
- [X] T073 [US2] Add test case for constitution violation detection in integration test

---

## Phase 5: User Story 5 - Contributor Receives Size and Description Feedback (Priority: P3)

**Goal**: Validate PR size and description quality, posting comments for Steps 2-3

**Independent Test**: Submit PR with 10-character description, verify comment suggests adding more detail

### Implementation for User Story 5

- [X] T074 [US5] Modify Step 2 in `.github/workflows/pr-validation.yml` to add PR size calculation
- [X] T075 [US5] Modify Step 2 to add description length validation (minimum 20 characters)
- [X] T076 [US5] Add JSON result generation in Step 2 (ValidationResult schema)
- [X] T077 [US5] Add `format-pr-comment.ps1` invocation in Step 2
- [X] T078 [US5] Add PR comment posting step in Step 2 using foundational infrastructure
- [ ] T079 [P] [US5] Modify Step 3 in `.github/workflows/pr-validation.yml` to add test results summarization
- [ ] T080 [US5] Add `format-pr-comment.ps1` invocation in Step 3 for lint/test results
- [ ] T081 [US5] Add PR comment posting step in Step 3 using foundational infrastructure

#### Integration Testing

- [X] T082 [US5] Add Step 2 and Step 3 comment tests to `PRValidationWorkflow.Tests.ps1`
- [X] T083 [US5] Add test case for small PR size (should pass) in integration test
- [X] T084 [US5] Add test case for large PR size (should warn) in integration test
- [X] T085 [US5] Add test case for short description (should warn) in integration test

---

## Phase 6: User Story 3 - Maintainer Reviews Consolidated Validation Results (Priority: P2)

**Goal**: Ensure all validation results are visible in PR conversation with clear status indicators

**Independent Test**: Submit PR that triggers multiple validation warnings, verify 5 separate comments appear (Steps 2-6)

**NOTE**: This user story is achieved by completing User Stories 1, 2, and 5. The following tasks verify integration.

### Integration Validation

- [ ] T086 [US3] Add integration test in `PRValidationWorkflow.Tests.ps1` for full workflow (all steps)
- [ ] T087 [US3] Add test case verifying 5 PR comments created (one per step 2-6)
- [ ] T088 [US3] Add test case verifying each comment has correct HTML marker
- [ ] T089 [US3] Add test case verifying non-blocking behavior (workflow succeeds despite validation failures)
- [ ] T090 [US3] Verify manual test with real PR showing all 5 comments with status indicators

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, optimization, and final validation

### Documentation

- [X] T091 [P] Create `pr-validation.md` in `docs/workflows/` explaining all 6 validation steps
- [X] T092 [P] Add troubleshooting section to `docs/workflows/pr-validation.md` (common errors, fixes)
- [ ] T093 [P] Add examples to `docs/workflows/pr-validation.md` (comment screenshots, workflow logs)
- [X] T094 [P] Update `CONTRIBUTING.md` with PR validation step descriptions
- [X] T095 [P] Update `CHANGELOG.md` under `[Unreleased]` section with new validation features

### Workflow Optimization

- [X] T096 [P] Add workflow concurrency control to `.github/workflows/pr-validation.yml` (cancel in-progress runs)
- [X] T097 [P] Add caching for PSScriptAnalyzer module installation in workflow
- [X] T098 [P] Add timeout limits to each validation step (prevent runaway jobs)
- [ ] T099 Add validation summary job at end of `.github/workflows/pr-validation.yml` (aggregates all step results)

### Edge Case Handling

- [X] T100 [P] Add error handling for validation step failures in workflow (post error comment on network timeout)
- [X] T101 [P] Implement output truncation in `format-pr-comment.ps1` (max 100 findings, link to full logs)
- [ ] T102 [P] Configure workflow to checkout validation scripts from base branch (prevent bypass by PR modifications)
- [ ] T103 [P] Add permission pre-check in workflow (detect missing PR comment permissions, log clear error)
- [X] T104 Add workflow concurrency control to `.github/workflows/pr-validation.yml` (cancel in-progress runs on new commit)

### Final Validation

- [X] T105 Run full test suite `./tests/test-runner.ps1` and verify all tests pass
- [ ] T106 Manually test workflow with multiple test PRs (clean, security issues, spec issues, combined issues)
- [ ] T107 Verify comment update-in-place behavior with multiple commits to same PR
- [ ] T108 Verify non-blocking behavior (can merge PR despite validation warnings)
- [ ] T109 Validate quickstart.md instructions by following guide to add a new validation check

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phases 3-6)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 3 (P2)**: Integration verification only - depends on US1, US2, US5 completion
- **User Story 4 (P3)**: Implemented in Foundational phase (T011-T015) - BLOCKS all other stories (comment infrastructure must exist first)
- **User Story 5 (P3)**: Can start after Foundational (Phase 2) - No dependencies on other stories

### Within Each User Story

- Tests MUST be written and FAIL before implementation (TDD approach per constitution)
- Validation scripts before workflow integration
- Unit tests before integration tests
- Story complete and verified before moving to next priority

### Parallel Opportunities

- **Phase 1 (Setup)**: All tasks T001-T005 can run in parallel (different directories)
- **Phase 2 (Foundational)**:
  - T006-T008 (format-pr-comment.ps1) can run in parallel with T016-T018 (test fixtures)
  - T009-T010 (formatter tests) depend on T006-T008 completion
- **Phase 3 (US1)**:
  - Tests T019-T022 can all run in parallel (different test files)
  - Implementation: T023-T026 (dependency script) parallel with T028-T033 (path security script)
  - Integration tests T044-T048 can run in parallel after implementation complete
- **Phase 4 (US2)**:
  - Tests T049-T053 can all run in parallel
  - Workflow T065-T069 can start once T054-T064 (script) complete
- **Phase 5 (US5)**:
  - Steps 2 and 3 modifications can run in parallel (T074-T078 and T079-T081)
- **Phase 7 (Polish)**:
  - All documentation tasks T091-T095 can run in parallel
  - All optimization tasks T096-T098 can run in parallel
  - All edge case tasks T100-T103 can run in parallel
- **Cross-Story Parallelization**: Once Foundational completes, US1, US2, US5 can all start in parallel (different scripts/steps)

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Create CheckDependencies.Tests.ps1 in tests/unit/"
Task: "Create CheckPathSecurity.Tests.ps1 in tests/unit/"
Task: "Create test case in CheckPathSecurity.Tests.ps1 for safe Join-Path usage"
Task: "Create test case in CheckDependencies.Tests.ps1 for current safe versions"

# Launch validation script implementations in parallel:
Task: "Create check-dependencies.ps1 in .github/scripts/"
Task: "Create check-path-security.ps1 in .github/scripts/"

# Launch integration tests in parallel after implementation:
Task: "Add test case for GitLeaks secret detection in integration test"
Task: "Add test case for PSScriptAnalyzer security rule violation"
Task: "Add test case for dependency vulnerability in integration test"
Task: "Add test case for path traversal detection in integration test"
```

---

## Implementation Strategy

### User Story 1 First

1. Complete Phase 1: Setup (T001-T005) → Directory structure ready
2. Complete Phase 2: Foundational (T006-T018, CRITICAL) → Comment infrastructure ready
3. Complete Phase 3: User Story 1 (T019-T048) → Security scanning ready
4. Test and validate:
   - Run `./tests/test-runner.ps1 -Unit` → All US1 tests pass
   - Submit test PR with security issue → Comment appears with findings
   - Push fix → Comment updates (not duplicates)
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready for all stories
2. Add User Story 1 (Security) → Test independently → Deploy/Demo
3. Add User Story 2 (Spec Compliance) → Test independently → Deploy/Demo
4. Add User Story 5 (Size/Description) → Test independently → Deploy/Demo
5. Validate User Story 3 (Integration) → All comments working together
6. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (Security scanning)
   - Developer B: User Story 2 (Spec compliance)
   - Developer C: User Story 5 (Size/description comments)
3. Stories complete independently, validate US3 integration together
4. Team completes Polish phase together

---

## Task Statistics

**Total Tasks**: 109
**Setup Tasks**: 5 (T001-T005)
**Foundational Tasks**: 13 (T006-T018, includes 5 US4 tasks)
**User Story 1 Tasks**: 30 (T019-T048) - Security Feedback
**User Story 2 Tasks**: 25 (T049-T073) - Spec Compliance
**User Story 3 Tasks**: 5 (T086-T090) - Consolidated Results (integration validation)
**User Story 4 Tasks**: 5 (T011-T015) - Update-in-Place (in Foundational phase)
**User Story 5 Tasks**: 12 (T074-T085) - Size/Description Feedback
**Polish Tasks**: 19 (T091-T109, includes 5 edge case tasks T100-T104)

**Parallel Opportunities**: 39 tasks marked [P] can run in parallel within their phase
**Independent Stories**: US1, US2, US5 can all run in parallel after Foundational phase

---

## Notes

- [P] tasks = different files, no dependencies within phase
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing (TDD per constitution)
- Commit after each task or logical group
- Constitution requires tests for all modules - test tasks are mandatory, not optional
- JSON schemas in contracts/ provide validation for all script outputs
- Use quickstart.md as reference when implementing validation scripts
