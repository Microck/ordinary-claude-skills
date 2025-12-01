# Implementation Plan: Fix Module Function Availability

**Branch**: `004-fix-nested-imports` | **Date**: 2025-10-20 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/004-fix-nested-imports/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

This feature fixes a critical bug where PowerShell module functions become unavailable after import due to nested `Import-Module` statements within module files creating scope isolation issues. The fix involves auditing all 6 modules (HashUtils, VSCodeIntegration, GitHubApiClient, ManifestManager, BackupManager, ConflictDetector) to remove nested imports, centralizing dependency management in the orchestrator, adding automated lint checks to prevent future violations, and creating integration tests to verify cross-module function calls work correctly.

**Root Cause**: Nested module imports create PowerShell scope barriers where functions imported within a module's scope are not propagated to the calling (orchestrator) scope, causing "command not recognized" errors.

**Technical Approach**:
1. Remove all `Import-Module` statements from `.psm1` module files
2. Establish correct dependency order in orchestrator with documented comments
3. Add pre-test lint validation to `tests/test-runner.ps1`
4. Create integration tests for cross-module function calls
5. Update constitution with explicit prohibition and rationale

## Technical Context

**Language/Version**: PowerShell 7.x
**Primary Dependencies**: Pester 5.x (testing framework)
**Storage**: File system (no database, operates on `.specify/` directories and module files)
**Testing**: Pester 5.x for unit and integration tests
**Target Platform**: Windows 11 (PowerShell Core cross-platform compatible, but primary target is Windows)
**Project Type**: Single project (PowerShell skill distributed as Git repository)
**Performance Goals**: Local script execution speed adequate (< 5 seconds for lint check, < 30 seconds for test suite)
**Constraints**:
- Must work within Claude Code VSCode extension environment
- Cannot introduce breaking changes to existing skill functionality
- Must preserve all 132 passing unit tests
- Module functions must remain accessible to orchestrator scope
- Lint check must integrate cleanly with existing test-runner.ps1 without breaking CI workflows

**Scale/Scope**:
- 6 modules to audit (approximately 1500-2000 lines of PowerShell code total)
- 15 orchestrator workflow steps to validate
- 132 existing unit tests to preserve
- New integration tests for cross-module calls (estimated 20-30 test cases)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle Alignment

| Constitution Principle | Compliance Status | Notes |
|------------------------|-------------------|-------|
| **I. Modular Architecture** | ✅ **STRENGTHENS** | This fix directly reinforces modular architecture by removing nested import antipattern. Modules become truly self-contained with orchestrator managing all dependencies. |
| **II. Fail-Fast with Rollback** | ✅ No Impact | No changes to rollback mechanism. Fix operates on module architecture only. |
| **III. Customization Detection** | ✅ No Impact | No changes to normalized hashing. |
| **IV. User Confirmation** | ✅ No Impact | No changes to confirmation workflow. |
| **V. Testing Discipline** | ✅ **STRENGTHENS** | Adds new integration tests for cross-module function calls. Existing unit tests preserved. |
| **PowerShell Standards** | ✅ **ENFORCES** | Explicitly enforces Module Export Rules through constitution update and automated lint check. |
| **Testing Requirements** | ✅ **ENHANCES** | Adds pre-test validation step to test-runner.ps1. |
| **Git & Version Control** | ✅ Compliant | Follows conventional commit format, pre-commit checklist enforced via lint check. |

### Gate Status: **PASS**

**Rationale**: This feature has zero constitution violations. In fact, it strengthens two core principles (I. Modular Architecture, V. Testing Discipline) by removing an architectural antipattern and adding defensive checks. The fix is fully aligned with constitution intent.

**No Complexity Tracking Required**: Feature reduces complexity by simplifying dependency management (orchestrator-only imports instead of nested imports).

## Project Structure

### Documentation (this feature)

```
specs/004-fix-nested-imports/
├── spec.md              # Feature specification (/speckit.specify output)
├── plan.md              # This file (/speckit.plan output)
├── research.md          # Phase 0 output (generated below)
├── data-model.md        # Phase 1 output (generated below)
├── quickstart.md        # Phase 1 output (generated below)
├── checklists/
│   └── requirements.md  # Spec validation checklist
└── tasks.md             # Phase 2 output (/speckit.tasks - NOT created yet)
```

### Source Code (repository root)

```
claude-Win11-SpecKit-Safe-Update-Skill/
├── scripts/
│   ├── update-orchestrator.ps1     # Main entry point - imports all modules
│   ├── modules/                     # Business logic modules (FIX TARGET)
│   │   ├── HashUtils.psm1           # File hashing with normalization
│   │   ├── VSCodeIntegration.psm1   # VSCode context detection
│   │   ├── GitHubApiClient.psm1     # GitHub Releases API
│   │   ├── ManifestManager.psm1     # Manifest CRUD (known issue)
│   │   ├── BackupManager.psm1       # Backup/restore operations
│   │   └── ConflictDetector.psm1    # File state analysis
│   └── helpers/                     # UI/orchestration wrappers
│       ├── Invoke-PreUpdateValidation.ps1
│       ├── Show-UpdateReport.ps1
│       └── [others - not modified in this fix]
├── tests/
│   ├── test-runner.ps1              # Test orchestrator (LINT CHECK TARGET)
│   ├── unit/                        # Module-specific unit tests
│   │   ├── HashUtils.Tests.ps1
│   │   ├── ManifestManager.Tests.ps1
│   │   └── [others - preserved]
│   └── integration/                 # End-to-end workflow tests
│       ├── UpdateOrchestrator.Tests.ps1
│       └── ModuleDependencies.Tests.ps1  # NEW: cross-module call tests
├── .specify/
│   └── memory/
│       └── constitution.md          # UPDATE: add nested import prohibition
├── CLAUDE.md                        # UPDATE: document module import pattern
├── CONTRIBUTING.md                  # UPDATE: add lint check to pre-commit
└── CHANGELOG.md                     # UPDATE: document bug fix and changes
```

**Structure Decision**: This is a single-project PowerShell skill with standard module/helper/test organization. The fix targets the `scripts/modules/` directory (audit and remove nested imports), `scripts/update-orchestrator.ps1` (document dependency order), `tests/test-runner.ps1` (add lint check), and `tests/integration/` (add cross-module tests). No new directories required; all changes fit within existing structure.

## Complexity Tracking

*Not applicable - no constitution violations to justify.*

This feature reduces system complexity by eliminating nested module imports and establishing a single, clear dependency management pattern in the orchestrator.

---

## Planning Complete

**Status**: ✅ All planning phases complete

### Phase 0: Research - COMPLETE

**Deliverable**: [research.md](research.md)

**Key Findings**:
- PowerShell module scope isolation is confirmed root cause
- Orchestrator-managed dependencies pattern is best practice
- Lint check implementation via pre-test validation function
- Integration test strategy: Module dependency tests in dedicated file

**Unknowns Resolved**: 4 of 4 research areas addressed

---

### Phase 1: Design - COMPLETE

**Deliverables**:
- [data-model.md](data-model.md) - Module dependency graph, architectural entities, validation rules
- [quickstart.md](quickstart.md) - Manual testing guide with comprehensive test procedures
- CLAUDE.md - Updated with PowerShell module patterns (via update-agent-context.ps1)

**Key Design Decisions**:
- Module Dependency Graph defined as 3-tier DAG (Tier 0: no deps, Tier 1: depends on Tier 0, Tier 2: depends on Tier 1)
- Lint Check Integration: Function-based validation in test-runner.ps1 with regex detection
- Integration Test Suite: ModuleDependencies.Tests.ps1 with scope availability + cross-call tests
- Constitution Rule: Formal prohibition of nested imports with automated enforcement

**No API Contracts Required**: Internal module architecture only (no REST/GraphQL endpoints)

---

### Constitution Check - RE-VALIDATED POST-DESIGN

**Status**: ✅ PASS (no changes from initial check)

**Rationale**: Design phase confirmed zero constitution violations. All design decisions align with and strengthen existing principles.

---

## Next Steps

**Immediate**:
1. Run `/speckit.tasks` to generate dependency-ordered implementation tasks from this plan
2. Review tasks.md for task breakdown and sequencing

**Implementation Sequence** (to be detailed in tasks.md):
1. Audit all 6 modules for nested imports (ManifestManager known, check others)
2. Remove nested imports from affected modules
3. Update orchestrator with tiered import structure and inline documentation
4. Add lint check function to test-runner.ps1
5. Create ModuleDependencies.Tests.ps1 integration tests
6. Update constitution with Module Import Rules section
7. Update CLAUDE.md, CONTRIBUTING.md with pattern examples
8. Run full test suite validation (132 unit tests + new integration tests)
9. Manual testing per quickstart.md procedures
10. Update CHANGELOG.md with bug fix details

**Estimated Implementation Time**: 4-6 hours (including testing)

**Risk Areas**:
- Risk: Other modules besides ManifestManager may have nested imports → Mitigation: Comprehensive audit (Clarification Q1 addressed this)
- Risk: Removing imports may break module functionality → Mitigation: Extensive test coverage (unit + integration)
- Risk: Wrong import order in orchestrator → Mitigation: Documented tier structure + integration tests

---

## Artifacts Summary

| Artifact | Status | Location | Purpose |
|----------|--------|----------|---------|
| **Specification** | ✅ Complete | [spec.md](spec.md) | Feature requirements, user stories, success criteria |
| **Implementation Plan** | ✅ Complete | [plan.md](plan.md) (this file) | Technical context, constitution check, structure |
| **Research Findings** | ✅ Complete | [research.md](research.md) | Resolved unknowns, design decisions, rationale |
| **Data Model** | ✅ Complete | [data-model.md](data-model.md) | Module dependency graph, architectural entities |
| **Quickstart Guide** | ✅ Complete | [quickstart.md](quickstart.md) | Manual testing procedures, troubleshooting |
| **Tasks (TODO)** | ⏳ Pending | tasks.md | Dependency-ordered implementation tasks |

**Planning Phase Duration**: ~90 minutes

**Ready for Implementation**: ✅ Yes - all design artifacts complete, no blocking unknowns