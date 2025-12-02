# Feature Specification: Fix Fatal Module Import Error

**Feature Branch**: `003-fix-module-import-error`
**Created**: 2025-10-20
**Status**: Draft
**Input**: User description: "Fix fatal Export-ModuleMember error blocking skill execution"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Skill Executes Without Fatal Errors (Priority: P1)

As a user of the SpecKit Update Skill, I need the skill to execute successfully when invoked through Claude Code, so that I can check for and apply SpecKit updates without encountering blocking errors.

**Why this priority**: This is the core functionality - if the skill cannot execute at all, no other features matter. This represents the minimum viable fix.

**Independent Test**: Can be fully tested by invoking `/speckit-update -CheckOnly` in Claude Code and verifying it completes without fatal errors, delivering the ability to check for updates.

**Acceptance Scenarios**:

1. **Given** the user has the skill installed in their Claude Code environment, **When** they invoke `/speckit-update -CheckOnly`, **Then** the skill executes without fatal errors and displays update information
2. **Given** the skill is invoked with default parameters, **When** PowerShell modules are loaded, **Then** no "Export-ModuleMember cmdlet can only be called from inside a module" errors appear
3. **Given** the skill is running on Windows 11 with PowerShell 7.x, **When** module imports occur, **Then** the import process completes in under 2 seconds
4. **Given** the user is running the skill for the first time, **When** modules are loaded, **Then** the skill proceeds to the main workflow without terminating

---

### User Story 2 - Clean Module Loading with Helpful Diagnostics (Priority: P2)

As a user troubleshooting skill issues, I need clean module loading without spurious errors in normal output, while still being able to access verbose diagnostic information when needed, so that I can distinguish between real problems and false positives.

**Why this priority**: While execution must work (P1), users also need confidence that the skill is working correctly. Clean output prevents confusion and support requests, while verbose logging enables self-service troubleshooting.

**Independent Test**: Can be tested independently by running the skill with and without `-Verbose` flag and verifying normal output is clean while verbose mode provides diagnostic information.

**Acceptance Scenarios**:

1. **Given** the skill is invoked without verbose flags, **When** modules are imported, **Then** no false-positive errors or warnings appear in the output
2. **Given** the skill is invoked with `-Verbose` flag, **When** modules are imported, **Then** diagnostic information about module loading is displayed
3. **Given** unapproved PowerShell verb warnings exist in helper scripts, **When** modules load, **Then** these warnings are suppressed in normal output¹
4. **Given** module import completes successfully, **When** reviewing output, **Then** users see only actionable information relevant to their update check

¹ *Unapproved PowerShell verb warnings refer to the `Download-SpecKitTemplates` function in `GitHubApiClient.psm1`, which uses 'Download' instead of an approved verb like 'Get' or 'Save'. This is a separate issue from the Export-ModuleMember error and will be addressed in a future refactoring.*

---

### User Story 3 - Robust Error Handling with Clear Diagnostics (Priority: P3)

As a developer maintaining the skill, I need the skill to maintain strict error handling for real errors while tolerating benign import issues, so that actual problems are caught and reported with useful stack traces while false positives don't block execution.

**Why this priority**: This ensures long-term maintainability and helps catch real bugs. It's lower priority than basic execution (P1) and user experience (P2), but essential for quality.

**Independent Test**: Can be tested by introducing intentional errors in various parts of the workflow and verifying that real errors are caught with stack traces while benign import issues are tolerated.

**Acceptance Scenarios**:

1. **Given** a real error occurs during prerequisite validation, **When** the error is caught, **Then** a detailed error message with stack trace is displayed
2. **Given** benign Export-ModuleMember warnings occur during import, **When** modules load, **Then** execution continues without treating these as fatal errors
3. **Given** strict error handling is restored after imports, **When** the main workflow runs, **Then** real errors are caught and reported immediately
4. **Given** the skill encounters an error after imports complete, **When** the error occurs, **Then** execution stops with clear diagnostic information

---

### Edge Cases

- What happens when PowerShell modules fail to load due to actual syntax errors (not benign Export-ModuleMember issues)?
- How does the system behave when running in different PowerShell hosts (pwsh.exe vs. VSCode integrated terminal)?
- What happens when modules are already loaded in the PowerShell session from a previous run?
- How does the skill handle module import when running with different execution policies (Restricted, RemoteSigned, Unrestricted)?
- What happens if helper scripts contain actual errors beyond benign Export-ModuleMember calls?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST successfully import all required PowerShell modules without fatal errors when invoked through Claude Code
- **FR-002**: System MUST eliminate false-positive errors related to Export-ModuleMember by removing Export-ModuleMember calls from helper scripts (which are dot-sourced and do not require explicit exports)
- **FR-003**: System MUST suppress unapproved PowerShell verb warnings during helper script imports in normal output
- **FR-004**: System MUST restore strict error handling after module and helper imports complete, ensuring real errors are caught
- **FR-005**: System MUST complete module import phase in under 2 seconds on Windows 11 with PowerShell 7.x
- **FR-006**: System MUST provide verbose diagnostic logging for module import process when requested via command-line flag
- **FR-007**: System MUST proceed to main workflow execution after successful module imports
- **FR-008**: System MUST differentiate between benign import warnings and actual errors that should halt execution
- **FR-009**: System MUST maintain compatibility with different PowerShell hosts (pwsh.exe, VSCode terminal, PowerShell ISE)
- **FR-010**: System MUST display clean output with no false-positive errors in normal execution mode (without verbose flag)

### Key Entities

- **Module Import Phase**: The initialization stage where PowerShell modules (.psm1 files) and helper scripts (.ps1 files) are loaded into the current session, occurring before main workflow execution
- **Error Handling Context**: The state of error behavior control (`$ErrorActionPreference`) that determines whether non-terminating errors become terminating errors, temporarily relaxed during imports and restored afterward
- **Verbose Diagnostic Output**: Optional detailed logging information about module loading progress and status, controlled by the `-Verbose` command-line flag

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Skill executes successfully 100% of the time on Windows 11 with PowerShell 7.x when invoked via `/speckit-update` command
- **SC-002**: Module import phase completes in under 2 seconds from invocation to main workflow start
- **SC-003**: Zero false-positive errors appear in normal output (without verbose flag) during successful execution
- **SC-004**: All command-line parameters (`-CheckOnly`, `-Version`, `-Force`, `-Rollback`, `-NoBackup`) function correctly after import fix
- **SC-005**: Skill works identically across different PowerShell hosts (pwsh.exe, VSCode terminal)
- **SC-006**: Real errors occurring after import phase still produce clear error messages with stack traces
- **SC-007**: Verbose mode provides diagnostic information for troubleshooting without requiring code changes

## Assumptions

- Users are running Windows 11 with PowerShell 7.x (as documented in skill prerequisites)
- Claude Code invokes the skill's main orchestrator script through standard PowerShell execution
- Module files (.psm1) and helper scripts (.ps1) are present in expected locations relative to orchestrator script
- No changes to module export behavior are required - only import error handling needs adjustment
- Export-ModuleMember calls in helper scripts are benign and can be safely ignored during import
- Standard PowerShell execution policies (RemoteSigned or Unrestricted) are in place
- Users have read access to skill directory structure

## Dependencies

- PowerShell 7.x runtime environment
- Claude Code skill loading mechanism
- Existing module structure in `scripts/modules/` directory
- Existing helper scripts in `scripts/helpers/` directory
- `scripts/update-orchestrator.ps1` as main entry point

## Scope Boundaries

**In Scope**:

- Fixing module import error handling in update-orchestrator.ps1
- Eliminating benign Export-ModuleMember errors by removing Export-ModuleMember from helper scripts
- Maintaining strict error handling for real errors after imports
- Adding verbose diagnostic logging for import process
- Ensuring all existing command-line parameters work correctly

**Out of Scope**:

- Refactoring module structure or architecture
- Changing Export-ModuleMember usage patterns in **modules** (.psm1 files - these correctly use Export-ModuleMember)
- Adding new skill features or parameters beyond fixing execution
- Modifying test infrastructure beyond validating the fix
- Updating documentation beyond CHANGELOG entry
- Changes to other scripts or modules not directly related to import error

**Note**: Removing Export-ModuleMember from **helper scripts** (.ps1 files) IS in scope - this is the core architectural fix that eliminates the recurring error at its source.
