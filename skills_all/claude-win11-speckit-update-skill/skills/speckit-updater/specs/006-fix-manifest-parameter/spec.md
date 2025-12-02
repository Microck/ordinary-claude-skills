# Feature Specification: Complete Parameter Standardization for Manifest Creation

**Feature Branch**: `006-fix-manifest-parameter`
**Created**: 2025-10-20
**Status**: Draft
**Input**: User description: "docs\bugs\004-new-manifest-speckit-version-parameter.md"

## Clarifications

### Session 2025-10-20

- Q: Should this feature expand beyond fixing just the `New-SpecKitManifest` parameter to include a comprehensive audit and fix of ALL similar parameter naming inconsistencies across the entire codebase? → A: Create a systematic parameter naming standard and refactor ALL function parameters across the codebase for consistency (very broad scope, major refactoring)
- Q: What level of sophistication should the automated parameter naming audit tool have? → A: PowerShell script with JSON/markdown report output that can be run manually or in CI/CD pipeline (moderate automation, reusable)
- Q: Should the parameter refactoring be rolled out all at once or incrementally? → A: All at once - Fix immediate bug and refactor entire codebase in single release (fastest, highest risk)
- Q: What scope should the parameter naming standard cover? → A: All parameters with focus on frequently-used
- Q: What level of test coverage is required before releasing the all-at-once parameter refactoring? → A: 90%+ code coverage + all existing/new tests pass + manual testing of critical workflows (comprehensive, safest)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - First-Time Update in New Project (Priority: P1)

A developer working on a new SpecKit project (without an existing manifest) runs the update command to check for and apply template updates. The update process should create a new manifest automatically and proceed with the update check without errors.

**Why this priority**: This is the primary bug fix - the current implementation completely blocks first-time users and new projects. Without this fix, users cannot use the update skill at all in new projects.

**Independent Test**: Can be fully tested by removing any existing manifest.json file, running the update orchestrator, and verifying a new manifest is created successfully with the correct SpecKit version.

**Acceptance Scenarios**:

1. **Given** a SpecKit project directory with `.specify/` folder but no `manifest.json`, **When** the user runs the update command with check-only mode, **Then** the system creates a new manifest with the current SpecKit version and displays available updates
2. **Given** a SpecKit project directory without any manifest, **When** the user runs a full update (not check-only), **Then** the system creates a new manifest, applies updates safely, and completes successfully
3. **Given** a new SpecKit project with custom slash commands, **When** the update runs and creates a manifest, **Then** all existing files are marked as customized to prevent accidental overwrites

---

### User Story 2 - Systematic Parameter Naming Standard Across Entire Codebase (Priority: P2)

Developers and maintainers working with the update skill codebase expect consistent parameter naming across ALL functions following a documented standard. All function parameters should follow PowerShell best practices and maintain consistency throughout the codebase, preventing the class of bugs exemplified by the `New-SpecKitManifest` issue.

**Why this priority**: This ensures codebase consistency and prevents future bugs through systematic refactoring. It addresses not just the immediate issue but establishes a foundation for long-term maintainability by creating and enforcing parameter naming standards across all modules, scripts, and helpers.

**Independent Test**: Can be tested by running a comprehensive parameter audit tool across all `.ps1` and `.psm1` files, verifying all functions adhere to the established naming standard, and confirming no inconsistencies exist between function signatures and call sites.

**Acceptance Scenarios**:

1. **Given** all PowerShell modules and scripts in the codebase, **When** examining function parameter declarations, **Then** all parameters follow the documented naming standard (e.g., `-Version`, `-Path`, `-ProjectRoot` consistently used)
2. **Given** the complete codebase, **When** searching for parameter naming variations (e.g., `SpecKitVersion` vs `Version`), **Then** only the standardized form exists
3. **Given** all function call sites, **When** comparing parameter names passed to function signatures, **Then** 100% match the declared parameter names with no legacy variations
4. **Given** the parameter naming standard document, **When** developers add new functions, **Then** they have clear guidelines for choosing parameter names consistently

---

### User Story 3 - Clear Documentation and Help Text (Priority: P3)

Users running PowerShell help commands expect accurate, up-to-date documentation. When viewing help for manifest-related functions, the parameter documentation should reflect the current `-Version` parameter name.

**Why this priority**: This is important for user experience and developer onboarding but doesn't block functionality. Users can still use the function even if the help text is slightly outdated.

**Independent Test**: Can be tested by running `Get-Help New-SpecKitManifest -Parameter Version` and verifying the parameter is documented correctly.

**Acceptance Scenarios**:

1. **Given** the ManifestManager module, **When** a user runs `Get-Help New-SpecKitManifest -Full`, **Then** the parameter documentation shows `.PARAMETER Version` not `.PARAMETER SpecKitVersion`
2. **Given** the updated function, **When** viewing verbose output during manifest creation, **Then** messages reference "Version" not "SpecKitVersion"

---

### Edge Cases

- What happens when the orchestrator tries to create a manifest but the GitHub API call fails (returns null target version)?
- What happens if `Get-OfficialSpecKitCommands` is called with the old parameter name (backward compatibility)?
- What happens if the manifest creation process is interrupted midway (file system permissions, disk full)?
- What happens when updating from an older version of the skill that might still pass the old parameter name?
- What happens if the automated audit tool finds parameter inconsistencies that cannot be automatically refactored (complex parameter splatting, dynamic parameter names)?
- What happens if refactoring breaks parameter binding in edge cases not covered by tests?
- What happens if the all-at-once refactoring creates merge conflicts with other development work?

## Requirements *(mandatory)*

### Functional Requirements

**Immediate Bug Fix (New-SpecKitManifest):**

- **FR-001**: The `New-SpecKitManifest` function MUST accept a parameter named `Version` (not `SpecKitVersion`) for specifying the SpecKit version to initialize
- **FR-002**: The update orchestrator MUST pass the `-Version` parameter when calling `New-SpecKitManifest` with the target release version
- **FR-003**: The `New-SpecKitManifest` function MUST use the `Version` parameter when calling `Get-OfficialSpecKitCommands`
- **FR-004**: All verbose logging messages within `New-SpecKitManifest` MUST reference the correct `Version` variable name
- **FR-005**: The comment-based help documentation for `New-SpecKitManifest` MUST document the `.PARAMETER Version` (not `.PARAMETER SpecKitVersion`)

**Comprehensive Codebase Refactoring:**

- **FR-006**: A parameter naming standard document MUST be created at `.specify/memory/parameter-naming-standard.md` defining canonical parameter names for ALL parameters used in the codebase, with priority focus on frequently-used parameters (Version, Path, ProjectRoot, Force, Verbose, WhatIf, Confirm, etc.)
- **FR-007**: ALL PowerShell modules (.psm1 files) in scripts/modules/ MUST be audited for parameter naming consistency
- **FR-008**: ALL PowerShell scripts (.ps1 files) in scripts/ and scripts/helpers/ MUST be audited for parameter naming consistency
- **FR-009**: ALL function signatures MUST be updated to use standardized parameter names as defined in the naming standard
- **FR-010**: ALL function call sites MUST be updated to pass parameters using the standardized names
- **FR-011**: ALL comment-based help documentation MUST be updated to reflect standardized parameter names
- **FR-012**: ALL verbose logging and error messages MUST reference the standardized parameter variable names

**Validation & Testing:**

- **FR-013**: The system MUST maintain backward compatibility such that existing projects with manifests continue to update successfully
- **FR-014**: An automated parameter naming audit PowerShell script MUST be created that outputs structured reports (JSON and markdown formats) and can be executed both manually and within CI/CD pipelines
- **FR-015**: The audit tool MUST detect parameter naming inconsistencies including mismatched parameter names between function signatures and call sites, non-standard parameter names, and outdated documentation
- **FR-016**: Code coverage MUST reach at least 90% across all modules and scripts after refactoring
- **FR-017**: Unit tests MUST verify all refactored functions work correctly with the new parameter names
- **FR-018**: Regression tests MUST verify both new manifest creation and existing manifest updates work correctly
- **FR-019**: Integration tests MUST verify all end-to-end workflows continue to function after parameter refactoring
- **FR-020**: Manual testing MUST be performed on all critical user workflows including first-time updates, existing manifest updates, conflict resolution, and rollback scenarios

### Key Entities *(include if feature involves data)*

- **Manifest**: JSON file (`.specify/manifest.json`) tracking SpecKit version, file hashes, customization flags, and backup history. Key attributes: `speckit_version`, `tracked_files`, `custom_files`, `backup_history`
- **Version Parameter**: String value representing the SpecKit semantic version (e.g., "v0.0.72") passed between orchestrator and manifest functions
- **Parameter Naming Standard**: Documentation defining canonical parameter names for common concepts across the codebase. Key attributes: parameter name (e.g., `-Version`), usage context, approved verbs, capitalization rules, examples
- **Parameter Audit Report**: Output from automated audit tool listing all function parameters, their current names, and any inconsistencies found. Key attributes: file path, function name, parameter name, compliance status, suggested corrections

## Success Criteria *(mandatory)*

### Measurable Outcomes

**Immediate Bug Resolution:**

- **SC-001**: First-time users can successfully run update commands in projects without existing manifests without errors
- **SC-002**: All five identified code locations (4 in ManifestManager.psm1, 1 in update-orchestrator.ps1) are updated to use the standardized parameter name
- **SC-003**: 100% of the four test cases defined in the bug report pass (new project update, existing project update, AssumeAllCustomized flag, explicit version parameter)

**Comprehensive Codebase Standardization:**

- **SC-004**: A parameter naming standard document exists and defines canonical names for all common parameter types used across the codebase
- **SC-005**: Zero parameter naming inconsistencies exist across all PowerShell modules and scripts (verified by automated audit tool)
- **SC-006**: 100% of function signatures use standardized parameter names as defined in the naming standard
- **SC-007**: 100% of function call sites pass parameters using the standardized names with zero mismatches
- **SC-008**: All comment-based help documentation reflects the standardized parameter names
- **SC-009**: An automated parameter naming audit tool successfully validates the entire codebase with zero violations

**Quality & Compatibility:**

- **SC-010**: Code coverage reaches at least 90% across all modules and scripts
- **SC-011**: All existing unit tests continue to pass after refactoring (no regression)
- **SC-012**: All new unit tests for refactored functions pass successfully
- **SC-013**: All regression tests pass, confirming both new and existing manifest workflows work correctly
- **SC-014**: All integration tests pass, confirming end-to-end workflows function correctly
- **SC-015**: All critical user workflows pass manual testing including first-time updates, existing updates, conflict resolution, and rollback
- **SC-016**: Update commands complete in the same time as before the refactoring within ±10% tolerance (no significant performance degradation)
- **SC-017**: PowerShell `Get-Help` commands show correct parameter documentation for all refactored functions

## Assumptions *(include when applicable)*

- The issue #6 fix provides a starting point for parameter standardization (some functions already use `-Version`)
- No external scripts or tools depend on any old parameter names (this is an internal-only codebase)
- The current test suite provides sufficient foundation to build toward 90% coverage
- Users are running the latest version of the skill (v0.1.3+) that includes the issue #6 fixes
- The GitHub API validation added in issue #6 will catch null version values before they reach manifest functions
- PowerShell best practices for parameter naming are well-established and can be codified in a standard
- The automated audit tool can accurately detect parameter inconsistencies through AST parsing or regex patterns
- All-at-once refactoring is feasible within a single development cycle given comprehensive testing requirements
- Manual testing resources are available to validate critical workflows before release

## Dependencies *(include when applicable)*

- **Internal Dependency**: Requires the issue #6 fixes (commit d7392bb) to be present, which standardized other functions to use `-Version`
- **Testing Dependency**: Requires Pester 5.x test framework for unit test execution
- **Validation Dependency**: Requires the GitHub API client to provide valid version data when creating manifests

## Out of Scope *(include when applicable)*

- Adding parameter aliases for backward compatibility - this is an internal API with no external consumers
- Refactoring the manifest schema or data structure (only parameter names are being standardized)
- Creating new manifest validation or migration logic beyond parameter standardization
- Performance optimization of core functionality (only verifying no performance regression)
- Adding new features to the manifest management system or other modules
- Refactoring code logic, algorithms, or implementation details (only parameter names and their documentation)
- Changing function names or restructuring module organization
- Modifying test framework or testing infrastructure (only updating test parameter usage)

## Risks *(include when applicable)*

- **Risk**: Tests may not have covered the first-time manifest creation scenario, which is why this bug was missed initially
  - **Mitigation**: Add specific regression tests for manifest creation in projects without existing manifests

- **Risk**: All-at-once refactoring of entire codebase increases likelihood of breaking changes and introduces high integration risk
  - **Mitigation**: Comprehensive test suite execution (unit, integration, end-to-end) before release; extensive manual testing of all workflows; create detailed rollback plan

- **Risk**: Other functions might still be using old parameter names that weren't caught in the issue #6 audit
  - **Mitigation**: Run automated audit tool before and after refactoring to verify 100% parameter naming consistency

- **Risk**: Refactoring may introduce subtle bugs in parameter passing that tests don't catch
  - **Mitigation**: Manual code review of all parameter changes; validate each module independently before integration testing

- **Risk**: Verbose logging or error messages might still reference old parameter names after refactoring
  - **Mitigation**: Audit tool must validate error messages and verbose output in addition to function signatures

- **Risk**: Large-scale refactoring may conflict with other active development branches
  - **Mitigation**: Coordinate refactoring timing; perform refactoring on dedicated branch; communicate widely before merge

## Alternative Approaches Considered *(optional)*

### Approach 1: Parameter Alias for Backward Compatibility

Add `[Alias('SpecKitVersion')]` to the `$Version` parameter, allowing both names to work during a transition period.

**Pros**: Provides safety if external scripts exist that use the old name
**Cons**: Adds unnecessary complexity for an internal-only API with no known external consumers
**Decision**: Rejected - complete renaming (Solution 1) is simpler and sufficient

### Approach 2: Create New Function with New Name

Create a `New-SpecKitManifestV2` function with the correct parameter name, deprecate the old one.

**Pros**: Zero breaking changes, clear migration path
**Cons**: Increases code maintenance burden, confuses users about which function to use
**Decision**: Rejected - not needed for internal API changes

### Approach 3: Fix Only Orchestrator Call (Partial Fix)

Update only the orchestrator to pass the old parameter name that the function expects.

**Pros**: Minimal code changes, quick fix
**Cons**: Doesn't complete the standardization from issue #6, perpetuates inconsistency
**Decision**: Rejected - completes the partial work rather than reversing it
