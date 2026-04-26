# Feature Specification: Fix Installation Flow to Respect -Proceed Flag

**Feature Branch**: `011-fix-install-proceed-flag`
**Created**: 2025-10-23
**Status**: Draft
**Input**: User description: "Fix installation flow to respect -Proceed flag for conversational approval workflow"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fresh SpecKit Installation via Conversational Workflow (Priority: P1)

A developer working on a project without SpecKit installed wants to initialize SpecKit using the `/speckit-update` command. They expect a two-phase conversational approval workflow: first viewing what will be installed, then approving to proceed.

**Why this priority**: This is the primary installation workflow documented in README and SKILL.md. Without this working, new users are completely blocked from installing SpecKit via the skill. This bug has High severity because it blocks 100% of fresh installations.

**Independent Test**: Can be fully tested by running `/speckit-update` in a project directory without `.specify/` folder, then running `/speckit-update -Proceed` after viewing the installation offer. Delivers immediate value by enabling fresh SpecKit installations without manual workarounds.

**Acceptance Scenarios**:

1. **Given** a project directory without `.specify/` folder, **When** developer runs `/speckit-update` (without -Proceed flag), **Then** system shows `[PROMPT_FOR_INSTALL]` marker, describes what installation will do, displays instruction to run `/speckit-update -Proceed`, and exits gracefully with code 0
2. **Given** the first invocation completed showing installation offer, **When** developer runs `/speckit-update -Proceed`, **Then** system skips installation prompt, creates `.specify/` directory structure, downloads latest SpecKit templates from GitHub, creates manifest file, and completes installation successfully with exit code 0
3. **Given** developer has approved installation, **When** templates are downloaded and files are created, **Then** system shows progress messages ("Installing SpecKit...") and verbose logging indicates "User approved SpecKit installation, proceeding..."

---

### User Story 2 - Consistent Behavior Between Installation and Update Flows (Priority: P2)

A developer familiar with the update workflow expects the installation workflow to follow the same `-Proceed` flag pattern. They should see consistent behavior: first invocation shows summary and awaits approval, second invocation with `-Proceed` executes the operation.

**Why this priority**: Consistency in user experience reduces confusion and learning curve. The update flow already implements this pattern correctly (lines 381-409 in update-orchestrator.ps1), and installation should mirror it for predictability.

**Independent Test**: Can be tested independently by comparing installation flow behavior against update flow behavior with/without `-Proceed` flag. Both should follow identical approval patterns.

**Acceptance Scenarios**:

1. **Given** update flow correctly handles `-Proceed` flag (reference: lines 381-409 in update-orchestrator.ps1), **When** installation flow is invoked without `-Proceed`, **Then** it exits gracefully (code 0) with prompt marker, matching update flow's behavior
2. **Given** both flows support `-Proceed` flag, **When** user runs either command with `-Proceed` after initial check, **Then** both proceed immediately without re-prompting
3. **Given** developer reads documentation or help output, **When** comparing installation and update workflows, **Then** both describe identical two-phase approval patterns

---

### User Story 3 - Clear Error Prevention and User Guidance (Priority: P3)

A developer attempting to install SpecKit should never see confusing error messages or be left uncertain about what to do next. When approval is required, the system provides clear guidance on the exact command to run.

**Why this priority**: Good error handling and user guidance improve overall user experience but are lower priority than core functionality working correctly. This builds trust and reduces support burden.

**Independent Test**: Can be tested by running various invalid command sequences and verifying appropriate, actionable error messages are shown. No user should see "Awaiting user approval" as a thrown error.

**Acceptance Scenarios**:

1. **Given** SpecKit is not installed and `-Proceed` flag not provided, **When** validation runs, **Then** system uses `exit 0` (not `throw`) to pause workflow gracefully
2. **Given** installation prompt is shown, **When** user sees the output, **Then** exact command to proceed is displayed (`/speckit-update -Proceed`) with clear formatting
3. **Given** verbose logging is enabled (`-Verbose` flag), **When** installation flow runs, **Then** debug messages indicate approval state ("Awaiting user approval for SpecKit installation" or "User approved SpecKit installation, proceeding...")

---

### Edge Cases

- What happens when user runs `/speckit-update -Proceed` multiple times after installation completes? (Should behave as normal update check on subsequent runs)
- How does system handle network failures during template download after user approves installation? (Should fail gracefully with clear error, potentially offering rollback or retry)
- What if `.specify/` directory exists but is empty/corrupt? (Should detect and offer repair/reinstall, not treat as successful installation)
- What if user provides `-Proceed` on first invocation without seeing the installation offer? (Should still work - proceed immediately with installation since approval is explicit)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Validation helper (`Invoke-PreUpdateValidation.ps1`) MUST accept `-Proceed` parameter as an optional switch parameter
- **FR-002**: Installation detection logic (lines 206-221 in Invoke-PreUpdateValidation.ps1) MUST check `-Proceed` flag before prompting user or throwing errors
- **FR-003**: Orchestrator (`update-orchestrator.ps1` line 189) MUST pass `-Proceed` parameter value to validation helper using `-Proceed:$Proceed` syntax
- **FR-004**: When SpecKit is not installed and `-Proceed` flag is NOT provided, system MUST show `[PROMPT_FOR_INSTALL]` marker, describe installation actions, display exact command to proceed, and exit with code 0 (not throw error)
- **FR-005**: When SpecKit is not installed and `-Proceed` flag IS provided, system MUST skip installation prompt, log verbose message "User approved SpecKit installation, proceeding...", and continue with validation (not exit or throw)
- **FR-006**: Installation prompt output MUST include: cyan-colored `[PROMPT_FOR_INSTALL]` marker, yellow warning that SpecKit not installed, gray description of what installation does, and white command text showing `/speckit-update -Proceed`
- **FR-007**: Exit behavior when awaiting approval MUST use `exit 0` (graceful exit) instead of `throw` (error condition) to maintain conversational workflow pattern
- **FR-008**: Verbose logging MUST clearly indicate approval state transitions: "Awaiting user approval for SpecKit installation" (first invocation) and "User approved SpecKit installation, proceeding..." (second invocation)
- **FR-009**: Installation flow pattern MUST match update flow pattern (lines 381-409 in update-orchestrator.ps1) for consistency: check flag → show prompt if not set → exit gracefully OR proceed if set
- **FR-010**: When installation proceeds, system MUST show progress indicator ("📦 Installing SpecKit...") in cyan color before continuing validation steps

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developer can successfully complete fresh SpecKit installation using two-command workflow (`/speckit-update` followed by `/speckit-update -Proceed`) without errors
- **SC-002**: Installation prompt appears exactly once per installation attempt (no double prompts)
- **SC-003**: Exit code is 0 when awaiting installation approval on first invocation (not exit code 1 or thrown exception)
- **SC-004**: Time from running first command to completing installation is under 2 minutes (assuming normal network conditions for GitHub API)
- **SC-005**: 100% of fresh installation attempts using `-Proceed` flag succeed when network and permissions are available (no false failures due to flag being ignored)
- **SC-006**: Verbose logging output allows developers to trace approval flow state at each step (measurable by presence of expected log messages)
- **SC-007**: Installation workflow behavior is identical to update workflow behavior for `-Proceed` flag handling (measurable by comparing code paths)
- **SC-008**: Zero support tickets or bug reports from users about installation prompts appearing twice or `-Proceed` flag being ignored after fix is deployed