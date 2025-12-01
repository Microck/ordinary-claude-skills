# Implementation Plan: Complete Parameter Standardization for Manifest Creation

**Branch**: `006-fix-manifest-parameter` | **Date**: 2025-10-20 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/006-fix-manifest-parameter/spec.md`

## Summary

This feature addresses a critical bug where `New-SpecKitManifest` still uses the old `-SpecKitVersion` parameter name, blocking first-time users from creating manifests. Beyond fixing the immediate issue, this feature expands to a comprehensive codebase-wide parameter standardization effort. The implementation will:

1. Fix the 5 known code locations preventing manifest creation (P1 - immediate bug fix)
2. Create a parameter naming standard document defining canonical names for all parameters
3. Audit ALL PowerShell modules and scripts for parameter naming consistency
4. Refactor ALL function signatures and call sites to use standardized parameter names
5. Create an automated audit tool (PowerShell script with JSON/markdown output) to prevent future inconsistencies
6. Achieve 90%+ code coverage with comprehensive testing (unit, integration, manual)
7. Deploy all changes in a single release (all-at-once approach)

**Technical Approach**: PowerShell module refactoring with AST-based static analysis for parameter detection, systematic renaming following PowerShell approved verbs and naming conventions, comprehensive test suite expansion to meet 90% coverage threshold.

## Technical Context

**Language/Version**: PowerShell 7.4+
**Primary Dependencies**: Pester 5.x (testing framework), PowerShell Abstract Syntax Tree (AST) API for code analysis
**Storage**: File-based (`.specify/manifest.json`, parameter naming standard document, audit reports)
**Testing**: Pester 5.x with code coverage analysis, manual testing checklist for critical workflows
**Target Platform**: Windows 11 (primary), cross-platform PowerShell 7+ compatible
**Project Type**: PowerShell skill (single project with module architecture)
**Performance Goals**: No performance regression - update commands must complete in same time as baseline
**Constraints**:
- All-at-once refactoring in single release (high integration risk)
- 90%+ code coverage required before release
- Zero breaking changes to user-facing workflows
- Must maintain backward compatibility for existing projects
**Scale/Scope**:
- ~15 PowerShell modules and scripts across scripts/modules/, scripts/helpers/, scripts/
- ~50-100 function definitions estimated
- ~200-300 parameter usages estimated (signatures + call sites)
- Single repository, distributed via Git

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Modular Architecture ✅ PASS

**Requirement**: All business logic MUST be implemented in PowerShell modules (`.psm1` files), not in helper functions or the orchestrator.

**Compliance**:
- ✅ Parameter standardization will maintain existing module architecture
- ✅ Automated audit tool will be implemented as a standalone script (scripts/tools/audit-parameters.ps1) - acceptable per Constitution Principle I as it's a validation utility tool, not core business logic
- ✅ No business logic will be added to helpers - they remain thin orchestration wrappers
- ✅ All refactoring preserves module boundaries and responsibilities

**Action Required**: None - audit tool approach finalized as standalone validation utility.

### Principle II: Fail-Fast with Rollback ✅ PASS

**Requirement**: The update process MUST be transactional with automatic rollback on error.

**Compliance**:
- ✅ Parameter refactoring does not modify the rollback mechanism
- ✅ Existing backup/restore functionality preserved
- ✅ All refactored code will maintain try-catch-finally error handling
- ✅ No changes to exit code 6 rollback behavior

**Action Required**: Test that refactored parameter names don't break rollback workflow.

### Principle III: Customization Detection via Normalized Hashing ✅ PASS

**Requirement**: File customization detection MUST use normalized hashing.

**Compliance**:
- ✅ HashUtils module parameter standardization will not alter normalization logic
- ✅ Only parameter names change, not hashing algorithms or normalization rules
- ✅ Manifest hash comparisons remain unchanged

**Action Required**: Verify HashUtils module tests still pass after parameter renaming.

### Principle IV: User Confirmation Required ✅ PASS

**Requirement**: Update process MUST obtain explicit user confirmation before applying changes.

**Compliance**:
- ✅ Parameter refactoring does not modify user confirmation workflows
- ✅ Confirmation dialogs and prompts preserved
- ✅ No changes to exit code 5 (user cancelled) behavior

**Action Required**: Test user confirmation flows with refactored parameters.

### Principle V: Testing Discipline ✅ PASS

**Requirement**: All modules MUST have corresponding Pester unit tests. Integration tests MUST cover end-to-end orchestration.

**Compliance**:
- ✅ Feature explicitly requires 90%+ code coverage (exceeds 80% minimum)
- ✅ Unit tests will be updated for all refactored modules
- ✅ Integration tests will validate end-to-end workflows
- ✅ Manual testing required for critical workflows
- ✅ New automated audit tool will have corresponding tests

**Action Required**: Expand test coverage to meet 90% threshold; add tests for audit tool.

### PowerShell Standards ✅ PASS

**Requirement**: Follow PowerShell naming conventions, error handling, and module export rules.

**Compliance**:
- ✅ Parameter naming standard will codify PascalCase for parameters
- ✅ All refactored code will maintain approved verb usage (Get-, Set-, New-, Invoke-, etc.)
- ✅ Comment-based help will be updated for all refactored functions
- ✅ Module export rules (`Export-ModuleMember`) preserved
- ✅ Error handling patterns maintained

**Action Required**: Parameter naming standard document must reference PowerShell approved verbs and naming conventions.

### Module Import Rules ✅ PASS

**Requirement**: Modules MUST NOT import other modules. All imports managed by orchestrator.

**Compliance**:
- ✅ Parameter refactoring does not add new module imports
- ✅ Existing orchestrator import pattern (Tier 0 → Tier 1 → Tier 2) preserved
- ✅ Automated lint check will continue to enforce no nested imports

**Action Required**: Audit tool must not introduce nested module imports; document audit tool dependencies if any.

### Git & Version Control ✅ PASS

**Requirement**: Use conventional commits, run tests before committing, update CHANGELOG.md.

**Compliance**:
- ✅ This feature follows conventional commit format (`refactor: complete parameter standardization`)
- ✅ All tests will pass before merge (90% coverage requirement enforces this)
- ✅ CHANGELOG.md will be updated under [Unreleased]

**Action Required**: Comprehensive commit message documenting all-at-once refactoring scope.

### Distribution & Installation ✅ PASS

**Requirement**: Skill distributed as Git repository, not npm/PowerShell Gallery.

**Compliance**:
- ✅ No changes to distribution model
- ✅ Users still install via `git clone`
- ✅ Parameter refactoring transparent to installation process

**Action Required**: None.

### SpecKit Integration ✅ PASS

**Requirement**: Integrate with GitHub SpecKit projects, preserve custom commands, handle constitution updates.

**Compliance**:
- ✅ Parameter refactoring does not modify SpecKit command detection logic
- ✅ Custom command preservation logic unchanged
- ✅ Constitution update notification mechanism preserved

**Action Required**: Test that SpecKit integration still works with refactored parameters.

### Summary

**Overall Assessment**: ✅ **ALL GATES PASS**

This feature is a pure refactoring effort focused on parameter naming consistency. It preserves all architectural principles, testing requirements, and integration behaviors. The primary risk is scope (all-at-once refactoring), which is mitigated by 90%+ code coverage and comprehensive manual testing requirements.

**No complexity violations to justify.**

## Project Structure

### Documentation (this feature)

```
specs/006-fix-manifest-parameter/
├── spec.md                         # Feature specification (completed)
├── plan.md                         # This file
├── research.md                     # Phase 0: Research findings
├── data-model.md                   # Phase 1: Data structures
├── quickstart.md                   # Phase 1: Implementation guide
├── contracts/
│   └── parameter-naming-standard.md  # Canonical parameter names document
├── checklists/
│   └── requirements.md             # Spec quality checklist
└── tasks.md                        # Phase 2: Implementation tasks (created by /speckit.tasks)
```

### Source Code (repository root)

```
# PowerShell Skill Architecture (existing structure preserved)

scripts/
├── update-orchestrator.ps1         # Main entry point (imports all modules)
├── modules/                        # Business logic modules
│   ├── HashUtils.psm1             # File hashing (refactor parameters)
│   ├── VSCodeIntegration.psm1     # VSCode integration (refactor parameters)
│   ├── GitHubApiClient.psm1       # GitHub API (refactor parameters)
│   ├── ManifestManager.psm1       # Manifest CRUD (PRIMARY FIX: New-SpecKitManifest)
│   ├── BackupManager.psm1         # Backup/restore (refactor parameters)
│   ├── ConflictDetector.psm1      # File state analysis (refactor parameters)
│   └── ParameterAuditTool.psm1    # NEW: Automated parameter audit (if module)
└── helpers/                        # Thin orchestration wrappers
    ├── Show-UpdateSummary.ps1      # Refactor parameter usages
    ├── Get-UpdateConfirmation.ps1  # Refactor parameter usages
    ├── Invoke-PreUpdateValidation.ps1  # Refactor parameter usages
    ├── Show-UpdateReport.ps1       # Refactor parameter usages
    ├── Invoke-ConflictResolutionWorkflow.ps1  # Refactor parameter usages
    ├── Invoke-ThreeWayMerge.ps1    # Refactor parameter usages
    └── Invoke-RollbackWorkflow.ps1 # Refactor parameter usages

tests/
├── unit/                           # Unit tests for each module
│   ├── HashUtils.Tests.ps1        # Update for parameter changes
│   ├── ManifestManager.Tests.ps1  # Update for New-SpecKitManifest fix
│   ├── GitHubApiClient.Tests.ps1  # Update for parameter changes
│   ├── VSCodeIntegration.Tests.ps1 # Update for parameter changes
│   ├── BackupManager.Tests.ps1    # Update for parameter changes
│   ├── ConflictDetector.Tests.ps1 # Update for parameter changes
│   └── ParameterAuditTool.Tests.ps1  # NEW: Tests for audit tool
├── integration/                    # End-to-end workflow tests
│   ├── UpdateOrchestrator.Tests.ps1  # Update for refactored parameters
│   └── ModuleDependencies.Tests.ps1  # Verify cross-module calls still work
├── fixtures/                       # Test data
│   └── mock-responses/            # GitHub API mock responses
└── test-runner.ps1                # Test harness (runs lint + tests)

.specify/
└── memory/
    └── parameter-naming-standard.md  # NEW: Canonical parameter names

docs/
└── bugs/
    └── 004-new-manifest-speckit-version-parameter.md  # Bug report for this feature
```

**Structure Decision**:

This is a **single project PowerShell skill** using the existing modular architecture. The structure above represents the current layout with annotations for what will be refactored:

- **Immediate fix**: `ManifestManager.psm1` (5 specific locations)
- **Comprehensive refactoring**: ALL modules in `scripts/modules/`, all helpers in `scripts/helpers/`, and the orchestrator
- **New artifact**: Parameter naming standard document (location TBD during research - either `.specify/memory/` or `docs/`)
- **New tool**: Parameter audit tool (could be module in `scripts/modules/` or standalone script in `scripts/tools/`)

The module architecture aligns with Constitution Principle I (Modular Architecture). All business logic remains in modules, helpers remain thin wrappers.

## Complexity Tracking

**No violations** - this feature fully complies with all constitutional principles.

This table is empty because there are no constitutional violations that require justification. The all-at-once refactoring approach increases risk but does not violate any architectural principles. Risk is mitigated through comprehensive testing (90% coverage) and manual validation.
