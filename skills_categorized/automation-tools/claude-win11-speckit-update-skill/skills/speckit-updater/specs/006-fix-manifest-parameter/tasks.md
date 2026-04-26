# Tasks: Complete Parameter Standardization for Manifest Creation

**Input**: Design documents from `/specs/006-fix-manifest-parameter/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/parameter-naming-standard.md, quickstart.md

**Tests**: Tests are REQUIRED for this feature (90%+ code coverage mandated in spec)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions
- PowerShell skill architecture: `scripts/modules/`, `scripts/helpers/`, `tests/unit/`, `tests/integration/`
- All paths relative to repository root

---

## Phase 1: Setup (Baseline & Infrastructure)

**Purpose**: Establish baseline metrics and create audit tooling infrastructure

- [ ] T001 Measure baseline code coverage using tests/test-runner.ps1 -Coverage and document metrics
- [ ] T002 Document baseline test results (passing/failing tests count)
- [ ] T003 [P] Create parameter audit tool script in scripts/tools/audit-parameters.ps1
- [ ] T004 [P] Implement AST-based parameter detection in audit tool using System.Management.Automation.Language.Parser
- [ ] T005 [P] Implement violation detection logic in audit tool (compare against naming standard)
- [ ] T006 [P] Implement JSON report generation in audit tool per data-model.md structure
- [ ] T007 [P] Implement markdown report generation in audit tool
- [ ] T008 [P] Add exit code logic to audit tool (0 = pass, 1 = fail)
- [ ] T009 Create baseline audit report by running audit tool and saving output as audit-baseline-before-refactoring.json

---

## Phase 2: Foundational (Parameter Naming Standard)

**Purpose**: Create the parameter naming standard document that all refactoring will follow

**⚠️ CRITICAL**: No user story refactoring can begin until this standard is finalized

- [ ] T010 Copy parameter naming standard contract from specs/006-fix-manifest-parameter/contracts/parameter-naming-standard.md to .specify/memory/parameter-naming-standard.md
- [ ] T011 Verify parameter naming standard document contains all canonical names for this codebase (Version, Path, ProjectRoot, ManifestPath, BackupPath, etc.)
- [ ] T012 Create unit tests for audit tool in tests/unit/ParameterAuditTool.Tests.ps1
- [ ] T013 Test audit tool detects non-standard parameter names (test case with SpecKitVersion)
- [ ] T014 Test audit tool detects missing required parameters (test case with missing -Version)
- [ ] T015 Test audit tool detects mismatched call sites (test case with wrong parameter name)
- [ ] T016 Test audit tool generates valid JSON output (validate against data-model.md schema)
- [ ] T017 Test audit tool generates valid markdown output
- [ ] T018 Test audit tool exit codes (0 when compliant, 1 when violations found)

**Checkpoint**: Parameter naming standard finalized and audit tool functional - refactoring can now begin

---

## Phase 3: User Story 1 - First-Time Update in New Project (Priority: P1) 🎯 MVP

**Goal**: Fix the immediate bug blocking first-time users from creating manifests

**Independent Test**: Remove manifest.json, run update-orchestrator.ps1 -CheckOnly, verify manifest created successfully with correct Version parameter

### Tests for User Story 1

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T019 [P] [US1] Add unit test for New-SpecKitManifest with -Version parameter in tests/unit/ManifestManager.Tests.ps1
- [ ] T020 [P] [US1] Add unit test for New-SpecKitManifest parameter validation (Version required, not null)
- [ ] T021 [P] [US1] Add integration test for first-time manifest creation in tests/integration/UpdateOrchestrator.Tests.ps1
- [ ] T022 [P] [US1] Add integration test for manifest creation with AssumeAllCustomized flag

### Implementation for User Story 1

- [ ] T023 [US1] Refactor New-SpecKitManifest function signature in scripts/modules/ManifestManager.psm1 line 126 (change $SpecKitVersion to $Version)
- [ ] T024 [US1] Update verbose message in ManifestManager.psm1 line 135 (change $SpecKitVersion to $Version)
- [ ] T025 [US1] Update Get-OfficialSpecKitCommands call in ManifestManager.psm1 line 138 (use -Version parameter)
- [ ] T026 [US1] Update comment-based help in ManifestManager.psm1 (change .PARAMETER SpecKitVersion to .PARAMETER Version)
- [ ] T027 [US1] Add -Version parameter to New-SpecKitManifest call in scripts/update-orchestrator.ps1 line 200
- [ ] T028 [US1] Run unit tests for ManifestManager module to verify fix (Invoke-Pester tests/unit/ManifestManager.Tests.ps1)
- [ ] T029 [US1] Run integration test for first-time manifest creation to verify end-to-end workflow

**Checkpoint**: User Story 1 complete - first-time users can now create manifests without errors

---

## Phase 4: User Story 2 - Systematic Parameter Naming Standard Across Entire Codebase (Priority: P2)

**Goal**: Refactor ALL function parameters across the codebase to use standardized naming

**Independent Test**: Run audit tool (audit-parameters.ps1) and verify 100% compliance (zero violations)

### Comprehensive Audit (Identification Phase)

- [ ] T030 [US2] Run full parameter audit tool to identify all violations across codebase
- [ ] T031 [US2] Categorize violations by module, severity, and type (create refactoring task list)
- [ ] T032 [US2] Identify all functions with parameter violations using audit report

### Tier 0 Module Refactoring (No Dependencies)

**HashUtils Module:**

- [ ] T033 [P] [US2] Review HashUtils.psm1 parameters against naming standard
- [ ] T034 [P] [US2] Refactor HashUtils.psm1 function signatures if needed (Path parameter)
- [ ] T035 [P] [US2] Update HashUtils.psm1 comment-based help for any refactored parameters
- [ ] T036 [P] [US2] Update verbose/error messages in HashUtils.psm1 using refactored variables
- [ ] T037 [P] [US2] Update all call sites for HashUtils functions in orchestrator and other modules
- [ ] T038 [P] [US2] Run unit tests for HashUtils module (tests/unit/HashUtils.Tests.ps1)

**GitHubApiClient Module:**

- [ ] T039 [P] [US2] Review GitHubApiClient.psm1 parameters against naming standard
- [ ] T040 [P] [US2] Refactor GitHubApiClient.psm1 function signatures (ensure -Version parameter consistency)
- [ ] T041 [P] [US2] Update GitHubApiClient.psm1 comment-based help for any refactored parameters
- [ ] T042 [P] [US2] Update verbose/error messages in GitHubApiClient.psm1
- [ ] T043 [P] [US2] Update all call sites for GitHubApiClient functions in orchestrator
- [ ] T044 [P] [US2] Run unit tests for GitHubApiClient module (tests/unit/GitHubApiClient.Tests.ps1)

**VSCodeIntegration Module:**

- [ ] T045 [P] [US2] Review VSCodeIntegration.psm1 parameters against naming standard
- [ ] T046 [P] [US2] Refactor VSCodeIntegration.psm1 function signatures (BasePath, CurrentPath, IncomingPath, MergedPath)
- [ ] T047 [P] [US2] Update VSCodeIntegration.psm1 comment-based help
- [ ] T048 [P] [US2] Update verbose/error messages in VSCodeIntegration.psm1
- [ ] T049 [P] [US2] Update all call sites for VSCodeIntegration functions in helpers
- [ ] T050 [P] [US2] Run unit tests for VSCodeIntegration module (tests/unit/VSCodeIntegration.Tests.ps1) - note: some tests may be skipped due to mocking limitations

### Tier 1 Module Refactoring (Depends on Tier 0)

**ManifestManager Module (additional refactoring beyond US1):**

- [ ] T051 [US2] Review all ManifestManager.psm1 functions for additional parameter standardization beyond New-SpecKitManifest
- [ ] T052 [US2] Refactor remaining ManifestManager.psm1 functions (Get-Manifest, Save-Manifest, Update-Manifest) for Path/ProjectRoot consistency
- [ ] T053 [US2] Update ManifestManager.psm1 comment-based help for all refactored functions
- [ ] T054 [US2] Update verbose/error messages across ManifestManager.psm1
- [ ] T055 [US2] Update all ManifestManager call sites in orchestrator and helpers
- [ ] T056 [US2] Run unit tests for ManifestManager module (tests/unit/ManifestManager.Tests.ps1)

### Tier 2 Module Refactoring (Depends on Tier 1)

**BackupManager Module:**

- [ ] T057 [P] [US2] Review BackupManager.psm1 parameters against naming standard
- [ ] T058 [P] [US2] Refactor BackupManager.psm1 function signatures (ProjectRoot, BackupPath, FromVersion, ToVersion)
- [ ] T059 [P] [US2] Update BackupManager.psm1 comment-based help
- [ ] T060 [P] [US2] Update verbose/error messages in BackupManager.psm1
- [ ] T061 [P] [US2] Update all call sites for BackupManager functions in orchestrator and helpers
- [ ] T062 [P] [US2] Run unit tests for BackupManager module (tests/unit/BackupManager.Tests.ps1)

**ConflictDetector Module:**

- [ ] T063 [P] [US2] Review ConflictDetector.psm1 parameters against naming standard
- [ ] T064 [P] [US2] Refactor ConflictDetector.psm1 function signatures (ProjectRoot, Manifest parameters)
- [ ] T065 [P] [US2] Update ConflictDetector.psm1 comment-based help
- [ ] T066 [P] [US2] Update verbose/error messages in ConflictDetector.psm1
- [ ] T067 [P] [US2] Update all call sites for ConflictDetector functions in orchestrator
- [ ] T068 [P] [US2] Run unit tests for ConflictDetector module (tests/unit/ConflictDetector.Tests.ps1)

### Scripts & Helpers Refactoring

**Update Orchestrator:**

- [ ] T069 [US2] Review update-orchestrator.ps1 for any additional parameter standardization beyond US1 fix
- [ ] T070 [US2] Refactor update-orchestrator.ps1 internal parameters and variables
- [ ] T071 [US2] Update verbose/error messages in update-orchestrator.ps1

**Helper Scripts:**

- [ ] T072 [P] [US2] Review and refactor Show-UpdateSummary.ps1 parameters in scripts/helpers/
- [ ] T073 [P] [US2] Review and refactor Get-UpdateConfirmation.ps1 parameters in scripts/helpers/
- [ ] T074 [P] [US2] Review and refactor Invoke-PreUpdateValidation.ps1 parameters in scripts/helpers/
- [ ] T075 [P] [US2] Review and refactor Show-UpdateReport.ps1 parameters in scripts/helpers/
- [ ] T076 [P] [US2] Review and refactor Invoke-ConflictResolutionWorkflow.ps1 parameters in scripts/helpers/
- [ ] T077 [P] [US2] Review and refactor Invoke-ThreeWayMerge.ps1 parameters in scripts/helpers/
- [ ] T078 [P] [US2] Review and refactor Invoke-RollbackWorkflow.ps1 parameters in scripts/helpers/
- [ ] T079 [US2] Update all helper script call sites in update-orchestrator.ps1

### Test Coverage Expansion for User Story 2

- [ ] T080 [P] [US2] Add parameter binding tests for all refactored module functions in tests/unit/
- [ ] T081 [P] [US2] Add splatting scenario tests if splatting used in codebase
- [ ] T082 [P] [US2] Add error path tests for null/invalid parameters across all modules
- [ ] T083 [P] [US2] Add integration tests for cross-module function calls in tests/integration/ModuleDependencies.Tests.ps1
- [ ] T084 [US2] Run full test suite and measure code coverage (target: 90%+)
- [ ] T085 [US2] Identify and add tests for uncovered lines/functions based on coverage report
- [ ] T086 [US2] Re-run coverage analysis to verify 90%+ threshold achieved

### Final Validation for User Story 2

- [ ] T087 [US2] Run parameter audit tool to verify 100% compliance (zero violations)
- [ ] T088 [US2] Compare audit report with baseline to confirm all violations resolved
- [ ] T089 [US2] Run full test suite to verify no regressions (all tests passing)

**Checkpoint**: User Story 2 complete - All parameters standardized, 100% audit compliance, 90%+ test coverage

---

## Phase 5: User Story 3 - Clear Documentation and Help Text (Priority: P3)

**Goal**: Ensure all comment-based help and verbose output reflects standardized parameter names

**Independent Test**: Run Get-Help for all refactored functions and verify parameter documentation is correct

### Documentation Verification

- [ ] T090 [P] [US3] Verify Get-Help New-SpecKitManifest shows .PARAMETER Version (not SpecKitVersion)
- [ ] T091 [P] [US3] Verify Get-Help for all HashUtils functions shows correct parameter names
- [ ] T092 [P] [US3] Verify Get-Help for all GitHubApiClient functions shows correct parameter names
- [ ] T093 [P] [US3] Verify Get-Help for all ManifestManager functions shows correct parameter names
- [ ] T094 [P] [US3] Verify Get-Help for all BackupManager functions shows correct parameter names
- [ ] T095 [P] [US3] Verify Get-Help for all ConflictDetector functions shows correct parameter names
- [ ] T096 [P] [US3] Verify Get-Help for all VSCodeIntegration functions shows correct parameter names

### Verbose Output Verification

- [ ] T097 [US3] Run update-orchestrator.ps1 -CheckOnly -Verbose and verify all messages use standardized variable names
- [ ] T098 [US3] Verify verbose output from manifest creation references "Version" not "SpecKitVersion"
- [ ] T099 [US3] Verify error messages across all modules use standardized parameter variable names

**Checkpoint**: User Story 3 complete - All documentation and verbose output accurate

---

## Phase 6: Manual Testing & Validation

**Purpose**: Execute comprehensive manual testing checklist from quickstart.md

- [ ] T100 Manual Test Case 1: First-time update with no manifest (remove manifest, run -CheckOnly, verify manifest created)
- [ ] T101 Manual Test Case 2: Existing update with manifest (run -CheckOnly with existing manifest, verify file analysis works)
- [ ] T102 Manual Test Case 3: AssumeAllCustomized flag (remove manifest, run with flag, verify all files marked customized)
- [ ] T103 Manual Test Case 4: Explicit version parameter (run with -Version v0.0.72, verify specific version used)
- [ ] T104 Manual Test Case 5: Conflict resolution workflow (modify tracked file, run update, verify conflict detection works)
- [ ] T105 Manual Test Case 6: Rollback workflow (run -Rollback, verify restoration from backup)
- [ ] T106 Manual Test Case 7: Force mode (run with -Force, verify no confirmation prompts)
- [ ] T107 Manual Test Case 8: Get-Help verification (verify help text for refactored functions)
- [ ] T108 Performance baseline check (measure update command execution time, verify no significant degradation ±10%)

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, documentation, and release preparation

### Final Validation

- [ ] T109 Run final parameter audit tool with -FailOnViolations flag (expected: 0 violations, 100% compliance)
- [ ] T110 Run full test suite one final time (expected: all tests passing, 90%+ coverage)
- [ ] T111 Run final end-to-end smoke test (update-orchestrator.ps1 -CheckOnly -Verbose)

### Documentation Updates

- [ ] T112 [P] Update CHANGELOG.md under [Unreleased] section with comprehensive change list
- [ ] T113 [P] Update CONTRIBUTING.md with parameter naming standards section and audit tool usage
- [ ] T114 [P] Update docs/bugs/004-new-manifest-speckit-version-parameter.md status to RESOLVED
- [ ] T115 [P] Add resolution date and commit reference to bug report

### Release Preparation

- [ ] T116 Create comprehensive commit message following conventional commits format (refactor: complete parameter standardization)
- [ ] T117 Stage all changes (git add .) and commit with detailed multi-paragraph message
- [ ] T118 Verify commit includes all refactored files (modules, scripts, helpers, tests, documentation)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion (T009 baseline audit needed before standard finalization)
- **User Story 1 (Phase 3)**: Depends on Foundational completion (T010-T018 parameter standard and audit tool ready)
- **User Story 2 (Phase 4)**: Can start after Foundational, but logically follows US1 to validate audit tool works
- **User Story 3 (Phase 5)**: Depends on User Story 2 completion (verify documentation after refactoring)
- **Manual Testing (Phase 6)**: Depends on all user stories complete
- **Polish (Phase 7)**: Depends on manual testing validation

### User Story Dependencies

- **User Story 1 (P1)**: Fully independent - can complete standalone (fixes immediate bug)
- **User Story 2 (P2)**: Technically independent (no hard task dependencies on US1), but sequentially recommended after US1 to validate audit tool works correctly on the P1 fix before proceeding with full refactoring
- **User Story 3 (P3)**: Depends on US2 (verify documentation after refactoring)

### Within User Story 2 Module Refactoring

- **Tier 0 modules** (T033-T050): Can run in parallel - no dependencies on each other
- **Tier 1 modules** (T051-T056): Depends on Tier 0 completion (ManifestManager depends on HashUtils)
- **Tier 2 modules** (T057-T068): Depends on Tier 1 completion (BackupManager/ConflictDetector depend on ManifestManager)
- **Scripts & Helpers** (T069-T079): Depends on all module refactoring completion

### Parallel Opportunities

- **Phase 1 Setup**: T003-T008 (audit tool implementation tasks) can run in parallel
- **Phase 2 Foundational**: T012-T018 (audit tool tests) can run in parallel
- **Phase 3 US1 Tests**: T019-T022 can run in parallel
- **Phase 4 US2 Tier 0**: T033-T050 (all 3 Tier 0 modules) can run in parallel
- **Phase 4 US2 Tier 2**: T057-T068 (BackupManager and ConflictDetector) can run in parallel
- **Phase 4 US2 Helpers**: T072-T078 (all helper scripts) can run in parallel
- **Phase 4 US2 Test Expansion**: T080-T083 can run in parallel
- **Phase 5 US3 Documentation**: T090-T096 can run in parallel
- **Phase 7 Polish**: T112-T115 (documentation updates) can run in parallel

---

## Parallel Example: User Story 2 Tier 0 Modules

```bash
# Launch all Tier 0 module refactoring tasks together:
Task: "Review HashUtils.psm1 parameters against naming standard"
Task: "Review GitHubApiClient.psm1 parameters against naming standard"
Task: "Review VSCodeIntegration.psm1 parameters against naming standard"

# After reviews complete, launch all refactoring implementations in parallel:
Task: "Refactor HashUtils.psm1 function signatures if needed"
Task: "Refactor GitHubApiClient.psm1 function signatures"
Task: "Refactor VSCodeIntegration.psm1 function signatures"

# Then update all documentation in parallel:
Task: "Update HashUtils.psm1 comment-based help"
Task: "Update GitHubApiClient.psm1 comment-based help"
Task: "Update VSCodeIntegration.psm1 comment-based help"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T009) - establish baseline and create audit tool
2. Complete Phase 2: Foundational (T010-T018) - finalize parameter standard
3. Complete Phase 3: User Story 1 (T019-T029) - fix immediate bug
4. **STOP and VALIDATE**: Test US1 independently (first-time manifest creation works)
5. Optionally release hotfix with just US1 if urgency demands

### Incremental Delivery (Recommended)

1. Complete Setup + Foundational (T001-T018) → Audit tool and standard ready
2. Add User Story 1 (T019-T029) → Test independently → P1 bug fixed ✅
3. Add User Story 2 (T030-T089) → Test independently → Full refactoring complete ✅
4. Add User Story 3 (T090-T099) → Test independently → Documentation perfect ✅
5. Complete Manual Testing (T100-T108) and Polish (T109-T118) → Ready for release

### All-at-Once Strategy (Per User Clarification)

Per the user's clarification in spec.md (Q3: "All at once - Fix immediate bug and refactor entire codebase in single release"):

1. Complete ALL phases (T001-T118) before releasing
2. Achieve 90%+ code coverage (T084-T086)
3. Pass 100% audit compliance (T087-T089, T109)
4. Complete all manual testing (T100-T108)
5. Single comprehensive release with all refactoring

**Risk Mitigation**:
- 90%+ test coverage (T084-T086)
- Manual testing checklist (T100-T108)
- Parameter audit tool validation (T087, T109)
- Performance baseline check (T108)

---

## Parallel Team Strategy

With multiple developers working in parallel (after Foundational phase complete):

**Week 1**:
- Developer A: Setup + Foundational (T001-T018)

**Week 2** (after T018 complete):
- Developer A: User Story 1 (T019-T029)
- Developer B: Tier 0 modules for US2 - HashUtils (T033-T038)
- Developer C: Tier 0 modules for US2 - GitHubApiClient (T039-T044)

**Week 3**:
- Developer A: Tier 0 modules for US2 - VSCodeIntegration (T045-T050)
- Developer B: Tier 1 modules for US2 - ManifestManager (T051-T056)
- Developer C: Test coverage expansion (T080-T086)

**Week 4**:
- Developer A: Tier 2 modules for US2 - BackupManager (T057-T062)
- Developer B: Tier 2 modules for US2 - ConflictDetector (T063-T068)
- Developer C: Scripts & Helpers (T069-T079)

**Week 5**:
- Developer A: User Story 3 documentation (T090-T099)
- Developer B: Manual testing (T100-T108)
- Developer C: Final validation & polish (T109-T118)

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label (US1, US2, US3) maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Tests MUST fail before implementing (TDD approach for new functionality)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
- **Critical**: 90%+ code coverage required before release (spec requirement)
- **Critical**: 100% parameter audit compliance required (zero violations)
- **Critical**: All manual test cases must pass (T100-T108)

---

## Summary

**Total Tasks**: 118
**Task Breakdown by User Story**:
- Setup: 9 tasks
- Foundational: 9 tasks
- User Story 1 (P1): 11 tasks (T019-T029)
- User Story 2 (P2): 60 tasks (T030-T089)
- User Story 3 (P3): 10 tasks (T090-T099)
- Manual Testing: 9 tasks (T100-T108)
- Polish: 10 tasks (T109-T118)

**Parallel Opportunities**: 45 tasks marked [P] can run in parallel
**Independent Test Criteria**:
- US1: Remove manifest, run update, verify manifest created with -Version parameter
- US2: Run audit tool, verify 100% compliance (zero violations)
- US3: Run Get-Help commands, verify all documentation accurate

**Suggested MVP Scope**: User Story 1 only (T001-T029) - fixes immediate P1 bug blocking first-time users

**All-at-Once Release Scope** (per user clarification): All 118 tasks (T001-T118) before release
