# Feature Specification: Fix Module Function Availability

**Feature Branch**: `004-fix-nested-imports`
**Created**: 2025-10-20
**Status**: Draft
**Input**: User description: "Fix PowerShell module functions not available after import"

## Clarifications

### Session 2025-10-20

- Q: Codebase scope - should we scan only ManifestManager (known issue) or audit all 6 modules comprehensively? → A: Scan all 6 modules (HashUtils, VSCodeIntegration, GitHubApiClient, ManifestManager, BackupManager, ConflictDetector) and remove nested imports from any that have them
- Q: Automated prevention mechanism - how should we prevent future reintroduction of nested imports? → A: Add automated lint check to CI/CD pipeline that fails builds if any `.psm1` file contains `Import-Module`
- Q: Test strategy for module audit - how should we verify modules still work after removing nested imports? → A: Add module-specific integration tests verifying cross-module function calls work after nested import removal
- Q: CI/CD integration specifics - where should the lint check be implemented? → A: Add to existing tests/test-runner.ps1 script as pre-test validation step (works locally and in any CI)
- Q: Audit scope boundary - should we fix only nested imports or address other antipatterns discovered during audit? → A: Fix nested imports only (focused scope) - document any other issues found as separate bugs/tasks for future work

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Skill Executes Successfully with All Module Functions Available (Priority: P1)

Developers using the SpecKit Update skill need all PowerShell module functions to be accessible when the skill executes, so the update workflow can complete without errors.

**Why this priority**: Critical blocker - skill cannot execute at all without this fix. Blocks all user value.

**Independent Test**: Can be fully tested by running `/speckit-update -CheckOnly` in a SpecKit project and verifying no "command not recognized" errors occur, delivering immediate value of a working skill.

**Acceptance Scenarios**:

1. **Given** all 6 module files have been audited and any nested imports removed, **When** user runs `/speckit-update -CheckOnly`, **Then** the orchestrator loads all modules successfully and all module functions execute without errors
2. **Given** all required modules (HashUtils, GitHubApiClient, ManifestManager, BackupManager, ConflictDetector, VSCodeIntegration), **When** orchestrator imports them, **Then** all exported functions from each module are available in the calling scope
3. **Given** the skill is running in Claude Code environment, **When** any orchestrator step calls a module function, **Then** PowerShell resolves the function without throwing "command not recognized" errors

---

### User Story 2 - Module Dependencies Resolve Without Nested Imports (Priority: P2)

Developers maintaining the skill codebase need clear, non-nested module dependency management so future changes don't introduce scope isolation bugs.

**Why this priority**: Prevents future regressions and establishes architectural correctness. Enables sustainable development but skill must work first (P1).

**Independent Test**: Can be tested by searching all `.psm1` files for `Import-Module` statements and verifying none exist within module files, delivering cleaner architecture.

**Acceptance Scenarios**:

1. **Given** any module file (`.psm1`), **When** code review checks for dependency imports, **Then** no `Import-Module` statements exist within the module
2. **Given** ManifestManager module requires HashUtils and GitHubApiClient, **When** orchestrator imports modules, **Then** dependency order is documented and enforced in orchestrator only
3. **Given** a developer adds a new module with dependencies, **When** following the constitution, **Then** they add import statements to orchestrator, not within the new module

---

### User Story 3 - Constitution Prevents Future Nested Import Antipattern (Priority: P3)

Project contributors need clear architectural guidelines prohibiting nested module imports so the codebase maintains consistency and avoids repeating this bug.

**Why this priority**: Long-term code quality and contributor guidance. Important for sustainability but doesn't block immediate functionality.

**Independent Test**: Can be tested by reviewing constitution document for explicit prohibition of nested module imports and verification in code review checklists.

**Acceptance Scenarios**:

1. **Given** a new contributor reading the project constitution, **When** they implement a new module with dependencies, **Then** they know to declare imports in orchestrator only, not within module files
2. **Given** a code reviewer evaluating a PR with module changes, **When** they check constitution compliance, **Then** they verify no `Import-Module` statements exist in `.psm1` files
3. **Given** a PR contains a `.psm1` file with `Import-Module` statement, **When** CI/CD pipeline runs automated lint check, **Then** the build fails with clear error message indicating nested import violation

---

### Edge Cases

- What happens when a module tries to use a function from a dependency that hasn't been imported yet? (Dependency order enforcement)
- How does the system handle circular dependencies between modules? (Should be prevented by architecture)
- What happens if orchestrator imports modules in the wrong order? (Should fail fast with clear error)
- How does the fix maintain backward compatibility with existing `.specify/manifest.json` files? (No manifest format changes required)
- What happens if the comprehensive audit discovers nested imports in modules beyond ManifestManager? (Remove them all following the same pattern)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: All PowerShell module functions MUST be available in the orchestrator's calling scope after `Import-Module` completes
- **FR-002**: No `.psm1` module files MUST contain `Import-Module` statements (nested imports prohibited across all 6 modules)
- **FR-003**: The orchestrator script MUST import all modules in correct dependency order (dependencies before dependents)
- **FR-004**: All modules MUST access functions from dependency modules without importing them internally (orchestrator handles all imports)

> **Note**: FR-004 describes the positive behavior outcome enabled by FR-002's constraint. Removing nested imports (FR-002) enables cross-module function calls without imports (FR-004).

- **FR-005**: All existing exported functions from modules MUST remain accessible after architectural changes
- **FR-006**: The project constitution MUST explicitly prohibit nested module imports and document the correct pattern
- **FR-007**: Code review guidelines MUST include verification that `.psm1` files contain no `Import-Module` statements
- **FR-008**: An automated lint check MUST be added to `tests/test-runner.ps1` as a pre-test validation step that fails test runs if any `.psm1` file contains `Import-Module` statements
- **FR-009**: Module-specific integration tests MUST be added to verify cross-module function calls work correctly after nested import removal
- **FR-010**: Error messages MUST clearly indicate when module dependency order is incorrect
- **FR-011**: All existing unit and integration tests MUST pass after the fix is applied
- **FR-012**: The fix MUST NOT introduce any new `Export-ModuleMember` statements in helper scripts (`.ps1` files)

### Key Entities *(include if feature involves data)*

- **Module Dependency Graph**: Represents the correct import order where HashUtils and GitHubApiClient have no dependencies, ManifestManager depends on both, BackupManager depends on ManifestManager, ConflictDetector depends on HashUtils and ManifestManager, VSCodeIntegration has no dependencies
- **Module Import Configuration**: Orchestrator section defining the sequence of `Import-Module` calls with `-Force` and `-WarningAction` flags
- **Constitution Rule**: New architectural guideline prohibiting nested module imports with rationale and examples
- **Lint Check Integration**: Pre-test validation added to `tests/test-runner.ps1` that scans all `.psm1` files for `Import-Module` statements, exits with error code if violations found, outputs clear error messages with file paths and line numbers, runs automatically with every test execution
- **Integration Test Suite**: Module-specific tests verifying cross-module function calls (e.g., ManifestManager calling Get-NormalizedHash from HashUtils) work correctly when imports are managed by orchestrator

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Skill executes successfully (zero errors) when invoked via `/speckit-update -CheckOnly` in 3 different SpecKit projects from Claude Code
- **SC-002**: All module functions are verifiable in orchestrator scope using `Get-Command -Module [ModuleName]` immediately after import
- **SC-003**: Zero `.psm1` files contain `Import-Module` statements (measured by codebase scan)
- **SC-004**: All 132 passing unit tests continue to pass after architectural changes
- **SC-005**: All new module-specific integration tests pass, verifying 100% of cross-module function calls work correctly
- **SC-006**: Manual testing workflow completes without "command not recognized" errors in all 15 orchestrator steps
- **SC-007**: Code review checklist includes module import verification, reducing risk of future regressions to near-zero
- **SC-008**: Automated lint check integrated into test-runner.ps1 correctly detects and blocks 100% of nested import violations before tests run
- **SC-009**: Module dependency order is documented in orchestrator comments, enabling future maintainers to add modules correctly on first attempt

## Assumptions

- PowerShell module scope isolation is the root cause (nested imports create scope barriers)
- Removing nested imports and centralizing dependency management in orchestrator will resolve availability issues
- Existing `-Force` flag on imports is correct and necessary for reload scenarios
- No module manifests (`.psd1` files) are currently used, and adding them is out of scope for this fix
- The fix will not require changes to helper scripts (`.ps1` files in `scripts/helpers/`)
- All modules are designed to be stateless and don't rely on load-time initialization from nested imports

## Dependencies

- PowerShell 7.x runtime environment (already established)
- Existing module architecture with `Export-ModuleMember` in `.psm1` files
- Git repository structure with `.specify/` directories
- Pester testing framework for validation

## Out of Scope

- Creating PowerShell module manifests (`.psd1` files) - may be future enhancement
- Refactoring module internal implementation details beyond removing nested imports
- Fixing other PowerShell antipatterns or issues discovered during audit (document separately as future work)
- Changing the orchestrator workflow steps (still 15 steps)
- Modifying the manifest schema in `.specify/manifest.json`
- Adding new module dependencies or external libraries
- Changing helper script architecture (already correct)
- Performance optimization of module loading (current speed acceptable)

## Related Context

- **Issue #1**: Original fatal Export-ModuleMember error in helper scripts
- **PR #1**: Error suppression workaround (worked but masked antipattern)
- **PR #3**: Architectural fix removing Export-ModuleMember from helpers (correctly fixed helpers but introduced this regression)
- **Spec 003**: fix-module-import-error specification with constitution compliance requirements
- **Bug Report**: docs/bugs/002-module-functions-not-available.md (detailed root cause analysis)
