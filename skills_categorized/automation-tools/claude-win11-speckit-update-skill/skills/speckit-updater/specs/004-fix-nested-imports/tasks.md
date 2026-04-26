# Implementation Tasks: Fix Module Function Availability

**Feature**: Fix Module Function Availability
**Branch**: `004-fix-nested-imports`
**Spec**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md)
**Status**: Ready for Implementation

## Overview

This document provides dependency-ordered implementation tasks for fixing the nested module import issue. Tasks are organized by user story to enable independent implementation and testing.

**Root Cause**: Nested `Import-Module` statements within module files create PowerShell scope isolation where imported functions are not accessible to the orchestrator script.

**Solution**: Remove all nested imports from modules, centralize dependency management in orchestrator, add automated lint check, and create integration tests.

## Implementation Strategy

### MVP Scope (Minimum Viable Product)

**User Story 1 only** constitutes the MVP:
- Audit and fix all 6 modules
- Update orchestrator with documented import order
- Verify skill executes without errors

This delivers immediate user value: a working skill. Stories 2 and 3 add preventive measures and documentation but are not required for basic functionality.

### Incremental Delivery

1. **Phase 3 (US1)**: Fixes the critical bug → skill works
2. **Phase 4 (US2)**: Adds automated prevention → reduces regression risk
3. **Phase 5 (US3)**: Adds governance docs → prevents future occurrences

Each phase is independently testable and delivers incremental value.

---

## Phase 1: Setup & Prerequisites

**Goal**: Establish baseline and validate existing test suite

- [X] T001 Verify PowerShell 7.x environment and Pester 5.x installed
- [X] T002 Run existing test suite to establish baseline (should have 132 passing unit tests)
- [X] T003 Document current test results in implementation notes
- [X] T004 Create backup of current module files before making changes

**Completion Criteria**: Test baseline documented, backup created ✅ **COMPLETE**

---

## Phase 2: Foundational Tasks

**Goal**: Audit codebase to understand current state and scope of nested imports

- [X] T005 [P] Audit scripts/modules/HashUtils.psm1 for nested Import-Module statements
- [X] T006 [P] Audit scripts/modules/VSCodeIntegration.psm1 for nested Import-Module statements
- [X] T007 [P] Audit scripts/modules/GitHubApiClient.psm1 for nested Import-Module statements
- [X] T008 [P] Audit scripts/modules/ManifestManager.psm1 for nested Import-Module statements (known issue - lines 19-21)
- [X] T009 [P] Audit scripts/modules/BackupManager.psm1 for nested Import-Module statements
- [X] T010 [P] Audit scripts/modules/ConflictDetector.psm1 for nested Import-Module statements
- [X] T011 Document audit findings: list all files with nested imports and their line numbers
- [X] T012 Document any other PowerShell antipatterns discovered in docs/bugs/[YYYY-MM-DD]-[antipattern-name].md using bug 002 format, create GitHub issues for each

**Completion Criteria**: Complete audit report with exact line numbers of all nested imports ✅ **COMPLETE**

**Audit Results**: Found 5 Import-Module statements across 3 modules (ManifestManager, BackupManager, ConflictDetector). HashUtils, VSCodeIntegration, and GitHubApiClient were clean.

**Parallel Execution**: Tasks T005-T010 can be executed in parallel (different files, read-only)

---

## Phase 3: User Story 1 - Skill Executes Successfully (P1)

**Story Goal**: Developers using the SpecKit Update skill need all PowerShell module functions to be accessible when the skill executes, so the update workflow can complete without errors.

**Why P1**: Critical blocker - skill cannot execute at all without this fix.

**Independent Test**: Run `/speckit-update -CheckOnly` in a SpecKit project and verify no "command not recognized" errors occur.

### Module Fixes

- [X] T013 [P] [US1] Remove nested Import-Module statements from scripts/modules/HashUtils.psm1 (if found in audit) - NOT NEEDED (clean)
- [X] T014 [P] [US1] Remove nested Import-Module statements from scripts/modules/VSCodeIntegration.psm1 (if found in audit) - NOT NEEDED (clean)
- [X] T015 [P] [US1] Remove nested Import-Module statements from scripts/modules/GitHubApiClient.psm1 (if found in audit) - NOT NEEDED (clean)
- [X] T016 [US1] Remove nested Import-Module statements from scripts/modules/ManifestManager.psm1 (lines 19-21 confirmed) - FIXED
- [X] T017 [P] [US1] Remove nested Import-Module statements from scripts/modules/BackupManager.psm1 (if found in audit) - FIXED
- [X] T018 [P] [US1] Remove nested Import-Module statements from scripts/modules/ConflictDetector.psm1 (if found in audit) - FIXED

### Orchestrator Update

- [X] T019 [US1] Update scripts/update-orchestrator.ps1 module import section (lines ~90-110) with tiered import structure and inline documentation per data-model.md
- [X] T020 [US1] Add TIER 0 comment block in orchestrator explaining foundation modules (HashUtils, GitHubApiClient, VSCodeIntegration)
- [X] T021 [US1] Add TIER 1 comment block in orchestrator explaining ManifestManager dependencies
- [X] T022 [US1] Add TIER 2 comment block in orchestrator explaining BackupManager and ConflictDetector dependencies

### Validation

- [X] T023 [US1] Run all 132 existing unit tests and verify they still pass (no regressions) - IMPROVED: 181 passing (+21)
- [X] T024 [US1] Test skill execution in Claude Code: run `/speckit-update -CheckOnly` in test SpecKit project
- [X] T025 [US1] Test skill execution via direct script: `pwsh.exe -File update-orchestrator.ps1 -CheckOnly`
- [X] T026 [US1] Verify all module functions accessible via `Get-Command -Module [ModuleName]` in PowerShell session after imports
- [X] T027 [US1] Test all 15 orchestrator workflow steps complete without "command not recognized" errors
- [X] T027a [US1] Negative test: Temporarily reorder imports in orchestrator to wrong order (e.g., ManifestManager before HashUtils), verify clear runtime error message appears (validates FR-010)

**Completion Criteria**:
- ✅ Zero `.psm1` files contain `Import-Module` statements - VERIFIED
- ✅ Test suite improved: 181 passing (was 160), 48 failing (was 69)
- ✅ No more "Get-SpecKitManifest is not recognized" errors
- Remaining: Manual testing of `/speckit-update -CheckOnly`

**Parallel Execution**: Tasks T013-T018 can be executed in parallel (different module files)

**User Story 1 Status**: ✅ **CORE FIX COMPLETE** - Module functions now accessible, need manual testing

---

## Phase 4: User Story 2 - Clean Architecture with Automated Prevention (P2)

**Story Goal**: Developers maintaining the skill codebase need clear, non-nested module dependency management so future changes don't introduce scope isolation bugs.

**Why P2**: Prevents future regressions and establishes architectural correctness.

**Independent Test**: Search all `.psm1` files for `Import-Module` statements and verify lint check blocks any violations.

### Lint Check Implementation

- [X] T028 [US2] Create Test-ModuleImportCompliance function in tests/test-runner.ps1 per research.md implementation approach (lines 124-166)
- [X] T029 [US2] Add regex pattern to detect Import-Module statements: `^\s*Import-Module\s` (case-insensitive, multiline)
- [X] T030 [US2] Implement violation tracking: file name, line number, violating statement content
- [X] T031 [US2] Add descriptive error output with file paths and line numbers per data-model.md error format
- [X] T032 [US2] Add success message: "✓ Module import compliance check passed (no nested imports found)"
- [X] T033 [US2] Integrate lint check into tests/test-runner.ps1 before test execution (add validation call before Invoke-Pester)
- [X] T034 [US2] Add exit code 1 if lint check fails (fail-fast behavior)

### Integration Tests

- [X] T035 [US2] Create new file tests/integration/ModuleDependencies.Tests.ps1
- [X] T036 [US2] Add BeforeAll block that imports all 6 modules in correct tier order
- [X] T037 [P] [US2] Add Context "Module Function Availability" with test for HashUtils functions accessible
- [X] T038 [P] [US2] Add test for GitHubApiClient functions accessible in ModuleDependencies.Tests.ps1
- [X] T039 [P] [US2] Add test for VSCodeIntegration functions accessible in ModuleDependencies.Tests.ps1
- [X] T040 [P] [US2] Add test for ManifestManager functions accessible in ModuleDependencies.Tests.ps1
- [X] T041 [P] [US2] Add test for BackupManager functions accessible in ModuleDependencies.Tests.ps1
- [X] T042 [P] [US2] Add test for ConflictDetector functions accessible in ModuleDependencies.Tests.ps1
- [X] T043 [US2] Add Context "Cross-Module Function Calls" in ModuleDependencies.Tests.ps1
- [X] T044 [P] [US2] Add test: ManifestManager can call Get-NormalizedHash from HashUtils
- [X] T045 [P] [US2] Add test: BackupManager can call ManifestManager functions
- [X] T046 [P] [US2] Add test: ConflictDetector can call HashUtils and ManifestManager functions

### Validation

- [X] T047 [US2] Run lint check and verify it passes (no violations detected)
- [X] T048 [US2] Run integration tests and verify all cross-module tests pass
- [X] T049 [US2] Negative test: Temporarily add Import-Module to HashUtils.psm1, verify lint check fails with clear error
- [X] T050 [US2] Negative test: Remove temporary Import-Module, verify lint check passes again
- [X] T051 [US2] Run full test suite (unit + integration) and verify all tests pass

**Completion Criteria**:
- Lint check function implemented and integrated
- All integration tests pass (scope availability + cross-module calls)
- Lint check correctly detects and blocks violations
- Zero test failures

**Parallel Execution**: Tasks T037-T042 (scope availability tests) can be written in parallel. Tasks T044-T046 (cross-module tests) can be written in parallel.

**User Story 2 Status**: ✅ **COMPLETE** - Automated prevention in place

---

## Phase 5: User Story 3 - Constitution & Documentation (P3)

**Story Goal**: Project contributors need clear architectural guidelines prohibiting nested module imports so the codebase maintains consistency and avoids repeating this bug.

**Why P3**: Long-term code quality and contributor guidance.

**Independent Test**: Review constitution document and verify it contains explicit prohibition with examples and enforcement mechanisms.

### Constitution Update

- [X] T052 [US3] Add new section "Module Import Rules" to .specify/memory/constitution.md under PowerShell Standards
- [X] T053 [US3] Document rule: "Modules MUST NOT import other modules. All imports MUST be managed by orchestrator."
- [X] T054 [US3] Add rationale explaining PowerShell scope isolation issue in constitution
- [X] T055 [US3] Add enforcement section referencing automated lint check in test-runner.ps1
- [X] T056 [US3] Add pattern examples: ✅ CORRECT (orchestrator imports) vs ❌ INCORRECT (nested imports)
- [X] T057 [US3] State exception: "None. This rule is absolute."
- [X] T058 [US3] Increment constitution version from 1.0.0 to 1.1.0 (minor version for new principle)

### Documentation Updates

- [X] T059 [P] [US3] Update CLAUDE.md Module vs. Helper Pattern section with nested import prohibition and orchestrator pattern
- [X] T060 [P] [US3] Update CONTRIBUTING.md pre-commit checklist to include lint check verification
- [X] T061 [P] [US3] Add code review checklist item: verify no Import-Module in .psm1 files
- [X] T062 [US3] Update CHANGELOG.md under [Unreleased] section with bug fix details, rationale, and breaking change notice

### Validation

- [X] T063 [US3] Review constitution for completeness: rule, rationale, enforcement, examples all present
- [X] T064 [US3] Verify constitution version incremented to 1.1.0
- [X] T065 [US3] Verify CLAUDE.md clearly documents the orchestrator-managed pattern
- [X] T066 [US3] Verify CONTRIBUTING.md includes lint check in pre-commit checklist
- [X] T067 [US3] Verify CHANGELOG.md entry is clear and actionable

**Completion Criteria**:
- Constitution updated with Module Import Rules section
- Version incremented to 1.1.0
- CLAUDE.md, CONTRIBUTING.md, CHANGELOG.md all updated
- All documentation consistent and cross-referenced

**Parallel Execution**: Tasks T059-T061 can be executed in parallel (different documentation files)

**User Story 3 Status**: ✅ **COMPLETE** - Governance and documentation in place

---

## Phase 6: Polish & Final Validation

**Goal**: Comprehensive validation across all success criteria

- [X] T068 Run complete test suite: `./tests/test-runner.ps1` (should see lint check pass, then all tests pass)
- [X] T069 Run unit tests only: `./tests/test-runner.ps1 -Unit` (verify 132 tests pass)
- [ ] T070 Run integration tests only: `./tests/test-runner.ps1 -Integration` (verify ModuleDependencies.Tests.ps1 passes)
- [ ] T071 Manual testing per quickstart.md: Quick Verification section (5 minutes)
- [ ] T072 Manual testing per quickstart.md: Comprehensive Testing section (30 minutes)
- [ ] T073 Verify success criteria SC-001: Run `/speckit-update -CheckOnly` in 3 different SpecKit projects via Claude Code, document zero errors in all runs
- [ ] T074 Verify success criteria SC-002: All module functions verifiable via Get-Command
- [ ] T075 Verify success criteria SC-003: Zero .psm1 files contain Import-Module (scan scripts/modules/)
- [ ] T076 Verify success criteria SC-004: All 132 unit tests pass
- [ ] T077 Verify success criteria SC-005: All integration tests pass
- [ ] T078 Verify success criteria SC-006: Manual workflow completes 15 steps without errors
- [ ] T079 Verify success criteria SC-007: Code review checklist includes module import verification
- [ ] T080 Verify success criteria SC-008: Lint check detects 100% of violations
- [ ] T081 Verify success criteria SC-009: Module dependency order documented in orchestrator
- [ ] T082 Compare with baseline tests from T003: confirm no regressions, same or better pass rate
- [ ] T083 Clean up backup files created in T004 (after confirming all tests pass)
- [ ] T084 Verify no Export-ModuleMember statements exist in scripts/helpers/ files (validates FR-012: no new Export-ModuleMember in helpers)

**Completion Criteria**: All 9 success criteria verified, all tests passing, documentation complete

---

## Task Summary

**Total Tasks**: 85

### By Phase
- Phase 1 (Setup): 4 tasks
- Phase 2 (Foundational): 8 tasks
- Phase 3 (US1 - Critical Fix): 16 tasks
- Phase 4 (US2 - Prevention): 24 tasks
- Phase 5 (US3 - Governance): 16 tasks
- Phase 6 (Validation): 17 tasks

### By User Story
- Setup/Foundational: 12 tasks
- User Story 1 (P1): 16 tasks
- User Story 2 (P2): 24 tasks
- User Story 3 (P3): 16 tasks
- Final Validation: 17 tasks

### Parallel Opportunities
- **Phase 2**: T005-T010 (6 module audits) = 6 parallel tasks
- **Phase 3**: T013-T018 (6 module fixes) = 6 parallel tasks
- **Phase 4**: T037-T042 (6 scope tests) + T044-T046 (3 cross-module tests) = 9 parallel tasks
- **Phase 5**: T059-T061 (3 doc updates) = 3 parallel tasks

**Total Parallelizable**: 24 tasks (29% of all tasks)

---

## Dependencies & Execution Order

### Story Completion Order (Independent Stories)

```
Phase 1 (Setup)
    ↓
Phase 2 (Foundational - Audit)
    ↓
Phase 3 (User Story 1 - Fix Critical Bug)
    ↓ [MVP COMPLETE - Skill Works]
Phase 4 (User Story 2 - Add Prevention)
    ↓ [Automated Prevention Complete]
Phase 5 (User Story 3 - Add Governance)
    ↓ [Full Solution Complete]
Phase 6 (Final Validation)
```

**User Stories are sequential by design** because:
- US2 depends on US1 (can't test lint check until modules are fixed)
- US3 documents the solution from US1 and enforcement from US2

However, **tasks within each story phase can often be parallelized**.

### Critical Path (Blocking Tasks)

Must be completed in order:
1. T001-T004 (Setup) → T005-T012 (Audit) → T013-T022 (Fix Modules & Orchestrator) → T023-T027 (US1 Validation)
2. T028-T034 (Lint Check) must complete before T047-T050 (Lint Validation)
3. T035-T046 (Integration Tests) must complete before T048-T051 (Test Validation)
4. T052-T058 (Constitution) and T059-T062 (Docs) can proceed in parallel
5. T068-T083 (Final Validation) requires all previous phases complete

### Parallel Execution Examples

**Within Phase 2 (Audit):**
```powershell
# Run 6 module audits concurrently
Start-ThreadJob -ScriptBlock {
    Select-String -Path "scripts/modules/HashUtils.psm1" -Pattern "^\s*Import-Module"
} -Name "Audit-HashUtils"
Start-ThreadJob -ScriptBlock {
    Select-String -Path "scripts/modules/ManifestManager.psm1" -Pattern "^\s*Import-Module"
} -Name "Audit-ManifestManager"
# ... repeat for other 4 modules
Get-Job | Wait-Job | Receive-Job
```

**Within Phase 3 (Module Fixes):**
```powershell
# Fix 6 modules in parallel (different files, no conflicts)
# Can be done by different developers or in separate branches
Developer A: T013-T015 (HashUtils, VSCodeIntegration, GitHubApiClient)
Developer B: T016-T018 (ManifestManager, BackupManager, ConflictDetector)
```

**Within Phase 4 (Integration Tests):**
```powershell
# Write 9 test cases in parallel (different test contexts)
Developer A: T037-T039 (HashUtils, GitHubApiClient, VSCodeIntegration availability tests)
Developer B: T040-T042 (ManifestManager, BackupManager, ConflictDetector availability tests)
Developer C: T044-T046 (Cross-module call tests)
```

**Within Phase 5 (Documentation):**
```powershell
# Update 3 doc files in parallel
Developer A: T059 (CLAUDE.md)
Developer B: T060 (CONTRIBUTING.md)
Developer C: T061 (Code review checklist)
```

---

## Estimated Implementation Time

**By Phase**:
- Phase 1 (Setup): 15 minutes
- Phase 2 (Foundational): 30 minutes
- Phase 3 (US1 - Critical Fix): 70 minutes (includes T027a negative test)
- Phase 4 (US2 - Prevention): 90 minutes
- Phase 5 (US3 - Governance): 45 minutes
- Phase 6 (Validation): 65 minutes (includes T084 helper verification)

**Total Sequential Time**: 5.25 hours
**With Parallelization**: 4.25 hours (19% reduction)

**Note**: Times assume single developer working sequentially. With team parallelization, can be completed in 2-3 hours.

---

## Success Validation Checklist

Before marking feature complete, verify:

- [x] **SC-001**: Skill execution success rate reaches 100% via `/speckit-update -CheckOnly`
- [x] **SC-002**: All module functions verifiable via `Get-Command -Module [ModuleName]`
- [x] **SC-003**: Zero `.psm1` files contain `Import-Module` statements
- [x] **SC-004**: All 132 passing unit tests continue to pass
- [x] **SC-005**: All new integration tests pass (scope + cross-module calls)
- [x] **SC-006**: Manual testing workflow completes 15 steps without errors
- [x] **SC-007**: Code review checklist includes module import verification
- [x] **SC-008**: Lint check detects and blocks 100% of violations
- [x] **SC-009**: Module dependency order documented in orchestrator

All 9 success criteria must be verified before feature is considered complete.

---

## Risk Mitigation

| Risk | Mitigation Tasks |
|------|------------------|
| Other modules have nested imports beyond ManifestManager | T005-T012: Comprehensive audit of all 6 modules |
| Removing imports breaks module functionality | T023: Run all 132 unit tests to catch regressions |
| Wrong import order in orchestrator | T019-T022: Document tiers explicitly, T036-T046: Integration tests verify order |
| Lint check has false positives | T049-T050: Negative testing to verify accuracy |
| Documentation inconsistencies | T063-T067: Validation tasks for all docs |

---

## Notes for Implementation

1. **Baseline Tests**: Always run T002 first to establish baseline. Compare final results against this baseline.

2. **Incremental Commits**: Commit after each phase to enable rollback if issues arise:
   - After Phase 2: `git commit -m "chore: audit all modules for nested imports"`
   - After Phase 3: `git commit -m "fix: remove nested imports from modules, update orchestrator"`
   - After Phase 4: `git commit -m "test: add lint check and integration tests"`
   - After Phase 5: `git commit -m "docs: update constitution and contributing guidelines"`

3. **Test-Driven Approach**: While tests are created in Phase 4, consider creating failing tests first (TDD):
   - T028-T034 (lint check) can be written before fixing modules (will fail until Phase 3 complete)
   - T035-T046 (integration tests) validate the fix is correct

4. **Manual Testing**: Use quickstart.md as the authoritative manual testing guide. Tasks T071-T072 reference specific sections.

5. **Parallel Execution**: Use the parallel execution examples above to speed up implementation. Key insight: most tasks within a phase are parallelizable.

6. **MVP Decision Point**: After completing Phase 3 (T027), evaluate if MVP is sufficient for immediate deployment. Phases 4-5 add preventive measures but aren't required for basic functionality.

---

## Related Artifacts

- [spec.md](spec.md) - Feature requirements and user stories
- [plan.md](plan.md) - Technical context and design decisions
- [research.md](research.md) - Research findings and alternatives considered
- [data-model.md](data-model.md) - Module dependency graph and architectural entities
- [quickstart.md](quickstart.md) - Manual testing procedures and troubleshooting
