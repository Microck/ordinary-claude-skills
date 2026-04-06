# Feature Specification: Fix Module Import Error

**Feature Branch**: `002-fix-module-import-error`
**Created**: 2025-10-20
**Status**: Draft
**Input**: User description: "docs\bugs\BUG-REPORT-Export-ModuleMember-Error.md"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Successful Skill Execution (Priority: P1)

Users can successfully execute the `/speckit-update` skill without encountering module import errors that block execution.

**Why this priority**: This is a critical bug that completely prevents the skill from functioning. Users cannot perform any update operations (check updates, apply updates, rollback) until this is resolved. This is blocking all skill functionality.

**Independent Test**: Can be fully tested by running the orchestrator script with `-CheckOnly` flag and verifying it proceeds past module loading to prerequisite validation, delivering immediate value by unblocking the skill.

**Acceptance Scenarios**:

1. **Given** a user has installed the skill in their Claude Code environment, **When** they run `/speckit-update --check-only` from a SpecKit project, **Then** the script imports all 6 modules without fatal errors and proceeds to check for updates
2. **Given** a user runs the orchestrator script directly with PowerShell 7.x, **When** modules are imported, **Then** no fatal errors occur and all module functions are available
3. **Given** modules generate non-fatal warnings during import, **When** the script continues execution, **Then** the warnings are logged but do not block the workflow
4. **Given** a module fails to load critical functions, **When** import validation runs, **Then** the script exits with a clear error message identifying which functions are missing

---

### User Story 2 - Clean Module Loading (Priority: P2)

Users see clean, professional output when the skill loads without spurious error messages or confusing warnings.

**Why this priority**: While the skill may function with warnings visible, clean output improves user confidence and reduces confusion. This enhances user experience but is not blocking core functionality.

**Independent Test**: Can be tested by running the skill with verbose logging and verifying only legitimate informational messages appear, no false-positive errors or irrelevant warnings.

**Acceptance Scenarios**:

1. **Given** a user runs `/speckit-update` with normal verbosity, **When** modules load, **Then** no error messages about Export-ModuleMember appear
2. **Given** modules use unapproved PowerShell verbs, **When** the script imports them, **Then** verb warnings are suppressed during normal operation
3. **Given** a user runs the script with `-Verbose` flag, **When** modules load, **Then** only helpful diagnostic information is displayed (module paths, function names, load times)

---

### User Story 3 - Robust Error Handling (Priority: P3)

When genuine module import failures occur, users receive actionable error messages that help them resolve the issue.

**Why this priority**: This improves the troubleshooting experience for real failures but is less critical than fixing the false-positive errors that currently block all usage.

**Independent Test**: Can be tested by simulating module corruption or missing files and verifying error messages clearly identify the problem and suggest remediation steps.

**Acceptance Scenarios**:

1. **Given** a module file is missing or corrupted, **When** the script attempts to import it, **Then** an error message identifies the specific module and file path that failed
2. **Given** a module lacks required functions, **When** import validation runs, **Then** the error message lists the missing function names
3. **Given** PowerShell execution policy blocks module loading, **When** import fails, **Then** the error message suggests running with `-ExecutionPolicy Bypass`

---

### Edge Cases

- What happens when modules load successfully but Export-ModuleMember generates non-terminating errors?
- How does the system handle modules that partially load (some functions available, others missing)?
- What happens if PowerShell version is incompatible (e.g., PowerShell 5.1 vs 7.x)?
- How are warnings from unapproved verb names handled without cluttering output?
- What happens when a user's PowerShell profile interferes with module loading?
- How does the script behave when running in different PowerShell hosts (pwsh.exe, powershell.exe, VSCode integrated terminal)?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Script MUST successfully import all 6 PowerShell modules (HashUtils, VSCodeIntegration, GitHubApiClient, ManifestManager, BackupManager, ConflictDetector) without fatal errors
- **FR-002**: Script MUST validate that critical module functions are available after import before proceeding with workflow
- **FR-003**: Script MUST distinguish between fatal import errors (missing files, syntax errors) and non-fatal errors (Export-ModuleMember quirks, verb warnings)
- **FR-004**: Script MUST suppress or handle non-fatal module import warnings to avoid confusing users
- **FR-005**: Script MUST provide clear, actionable error messages when genuine module import failures occur
- **FR-006**: Script MUST continue execution when modules load successfully despite generating non-terminating errors
- **FR-007**: Script MUST log module import progress at appropriate verbosity levels (normal, verbose, debug)
- **FR-008**: Module files MUST remain compatible with PowerShell 7.x without requiring restructuring into manifest-based modules
- **FR-009**: Import error handling MUST not mask genuine failures (corrupted files, missing dependencies, syntax errors)
- **FR-010**: Script MUST work correctly when invoked from Claude Code, direct PowerShell execution, and automated testing

### Key Entities

- **Module Import Validation**: A verification step that confirms all required module functions are loaded and available, distinguishing between "modules imported" vs "modules working correctly"
- **Non-Fatal Error**: PowerShell error or warning that appears during module import but does not prevent the module from functioning (e.g., Export-ModuleMember context errors, unapproved verb warnings)
- **Fatal Error**: Genuine module import failure that prevents functions from loading (missing file, syntax error, corrupted module)
- **Required Functions List**: Collection of critical function names from all modules that must be available for the skill to operate (Get-NormalizedHash, Get-ExecutionContext, Get-LatestSpecKitRelease, etc.)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can execute `/speckit-update --check-only` successfully without fatal errors in 100% of attempts on Windows 11 with PowerShell 7.x
- **SC-002**: Module import phase completes in under 2 seconds under normal conditions
- **SC-003**: Zero false-positive module import errors appear in normal user-facing output (errors that claim failure when modules actually work)
- **SC-004**: Genuine module import failures produce error messages that include file paths and specific problem descriptions within 1 second of detection
- **SC-005**: All 6 modules and their exported functions remain available throughout script execution after successful import
- **SC-006**: Skill functions correctly when invoked via Claude Code `/speckit-update` command without requiring users to run PowerShell directly
- **SC-007**: Verbose logging provides complete diagnostic information for troubleshooting without cluttering normal output

## Assumptions

- Users are running PowerShell 7.x (pwsh.exe) as specified in skill prerequisites
- Module `.psm1` files are structurally sound and follow PowerShell best practices
- The Export-ModuleMember error is a PowerShell quirk related to how modules are imported via direct file paths, not a genuine failure
- Modules currently function correctly despite the error messages (as confirmed by verbose output showing all functions imported)
- The try-catch block in update-orchestrator.ps1 is overly strict and treats non-fatal errors as fatal
- Standard PowerShell error suppression techniques (ErrorActionPreference, WarningAction, SilentlyContinue) are acceptable for non-fatal import warnings
