# Feature Specification: Helpful Error Messages for Non-SpecKit Projects

**Feature Branch**: `010-helpful-error-messages`
**Created**: 2025-10-22
**Status**: Draft
**Input**: User description: "docs\PRDs\002-Helpful-Error-Messages.md"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - First-Time User Discovery (Priority: P1)

A developer discovers the SpecKit updater skill and installs it before learning about SpecKit itself. When they run the update command in their project, they receive a cryptic error that doesn't explain what SpecKit is or why it's required. They feel frustrated and confused about what to do next.

**Why this priority**: This is the most critical user journey because it addresses the primary pain point - users who find the updater first need immediate context about what SpecKit is and how to get started. Without this, users will abandon the tool entirely.

**Independent Test**: Can be fully tested by running the update command in a non-SpecKit project and verifying the error message explains what SpecKit is, why it's needed, and provides clear next steps. This delivers immediate value by eliminating confusion for first-time users.

**Acceptance Scenarios**:

1. **Given** a project without a `.specify/` directory and SpecKit commands are installed in `.claude/commands/`, **When** the user runs the update command, **Then** the error message explains what SpecKit is in one sentence and instructs the user to run `/speckit.constitution` to initialize
2. **Given** a project without a `.specify/` directory and SpecKit commands are not installed, **When** the user runs the update command, **Then** the error message explains what SpecKit is in one sentence and provides a link to the official SpecKit documentation
3. **Given** a first-time user reading the error message, **When** they finish reading, **Then** they understand that this is expected behavior (not a bug) and know what SpecKit is used for

---

### User Story 2 - Experienced Developer with Uninitialized Project (Priority: P2)

A developer who already uses SpecKit in other projects creates a new project and forgets to initialize SpecKit. When they try to run the updater, they need a quick reminder of the initialization command without having to search documentation.

**Why this priority**: Experienced users value efficiency. While they already know about SpecKit, they need a quick path to fix the issue. This is less critical than P1 because experienced users could figure this out, but it significantly improves their experience.

**Independent Test**: Can be tested by simulating an experienced user scenario - run the update command in an uninitialized project with SpecKit already installed, and verify the error provides the exact initialization command. Delivers value by saving time for experienced users.

**Acceptance Scenarios**:

1. **Given** a developer with SpecKit installed who runs the update command in an uninitialized project, **When** they read the error message, **Then** they see the exact command to run (`/speckit.constitution`) without needing to check documentation
2. **Given** an experienced developer scanning the error message quickly, **When** they look for the initialization command, **Then** they can find it within 3 seconds due to clear formatting
3. **Given** a developer who just initialized SpecKit, **When** they run the update command again, **Then** the command succeeds and they can proceed with their workflow

---

### User Story 3 - Developer Evaluating SpecKit (Priority: P3)

A developer is evaluating whether to adopt SpecKit for their team's workflow. They installed the updater skill to explore its functionality but haven't committed to SpecKit yet. They need easy access to documentation to make an informed decision about adoption.

**Why this priority**: This supports the evaluation phase of tool adoption. While important for conversion, it's less critical than helping users who are already trying to use the tool. Evaluators are more patient and will seek out information.

**Independent Test**: Can be tested by verifying the error message includes a stable documentation link and distinguishes between "SpecKit not installed" vs "project not initialized" states. Delivers value by supporting informed decision-making.

**Acceptance Scenarios**:

1. **Given** a developer evaluating SpecKit who runs the update command, **When** SpecKit is not installed, **Then** the error message includes a link to official SpecKit documentation
2. **Given** an evaluator reading the error message, **When** they click the documentation link, **Then** they reach the official SpecKit repository with comprehensive information about features and setup
3. **Given** an evaluator seeing both error variants (commands available vs not available), **When** comparing them, **Then** they can clearly distinguish whether SpecKit is partially or fully absent from their environment

---

### Edge Cases

- What happens with partial or missing SpecKit installations (directory missing, empty, or containing only some commands)?
- What happens when SpecKit commands exist but with non-standard names?
- What happens when the system cannot determine SpecKit command availability due to permissions issues?
- How does the error message render in terminal vs Claude Code extension contexts?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST detect when a `.specify/` directory is missing from the project root
- **FR-002**: System MUST detect whether SpecKit commands are available by checking for command files in `.claude/commands/`
- **FR-003**: Error message MUST include a one-sentence explanation of what SpecKit is ("SpecKit is a Claude Code workflow framework that helps build features with specs, plans, and tasks")
- **FR-004**: Error message MUST provide context-aware next steps based on whether SpecKit commands are detected
- **FR-005**: Error message MUST suggest running `/speckit.constitution` when SpecKit commands are detected
- **FR-006**: Error message MUST provide a documentation link (https://github.com/github/spec-kit) when SpecKit commands are not detected
- **FR-007**: Error message tone MUST be helpful and educational, not accusatory or technical (see quickstart.md for approved message variants that demonstrate educational tone with one-sentence SpecKit explanation and actionable next steps)
- **FR-008**: System MUST check for at least one of these official SpecKit commands: `speckit.constitution.md`, `speckit.specify.md`, or `speckit.plan.md`
- **FR-009**: Error message MUST remain scannable (under 10 lines of text content, excluding blank lines used for visual spacing) to support quick comprehension
- **FR-010**: System MUST fall back to a generic helpful message if command detection fails or encounters errors
- **FR-011**: Error message formatting MUST use clear visual hierarchy (whitespace, indentation, bullet points)
- **FR-012**: System MUST not attempt automatic SpecKit installation without user consent

### Key Entities *(include if feature involves data)*

- **Error Message Variant**: Represents one of two possible error messages displayed based on detection results
  - Attributes: message text, context (commands available or not), target audience (first-time vs experienced)
  - Variants: "Commands Available" variant, "Commands Not Available" variant
  - Relationship: Each variant corresponds to a specific SpecKit installation state

- **Detection Result**: Represents the outcome of checking for SpecKit command availability
  - Attributes: commands found (boolean), checked paths (list), detection timestamp
  - States: commands available, commands not available, detection error
  - Relationship: Determines which Error Message Variant is displayed

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 90% of users report understanding what SpecKit is after reading the error message (measured via user surveys)
- **SC-002**: Support questions about "what is SpecKit?" reduce by 80% compared to baseline (measured via GitHub issue analysis)
- **SC-003**: 50% of users who encounter the error proceed to install or initialize SpecKit within the same session (measured via analytics if available)
- **SC-004**: Error message clarity scores 8 out of 10 or higher in user testing (measured via user feedback sessions)
- **SC-005**: Average time from encountering error to successful SpecKit initialization is under 5 minutes (measured via user observation studies)
- **SC-006**: Zero regression in behavior for existing SpecKit projects (verified via automated tests)
- **SC-007**: Error message renders correctly in both terminal and VSCode extension contexts (verified via manual testing)

## Assumptions *(optional)*

- Users have read access to the `.claude/commands/` directory
- SpecKit official commands maintain consistent naming convention (`speckit.*.md`)
- GitHub repository URL (https://github.com/github/spec-kit) remains stable
- Users running the updater have basic familiarity with command-line interfaces
- The `/speckit.constitution` command name will not change in future SpecKit versions
- Error messages are displayed in environments that support basic text formatting (line breaks, whitespace)

## Dependencies *(optional)*

### Technical Dependencies

- PowerShell 7+ (already required by the updater skill)
- Access to file system for checking `.specify/` and `.claude/commands/` directories
- No new external dependencies required (pure enhancement to existing code)

### External Dependencies

- SpecKit documentation availability at https://github.com/github/spec-kit
- SpecKit command naming convention remains consistent
- Claude Code slash command system for `/speckit.constitution` recommendation

### Documentation Dependencies

- README.md should be updated to mention improved error handling
- CHANGELOG.md must document this enhancement
- SKILL.md may need updates if error message examples are included

## Out of Scope *(optional)*

The following items are explicitly excluded from this feature:

- **Automatic SpecKit installation**: The system will not automatically run `/speckit.constitution` or install SpecKit without explicit user action
- **Interactive setup wizard**: Error message remains text-based; no interactive prompts or multi-step wizards
- **Version detection**: System will not detect or recommend specific SpecKit versions
- **Multi-agent detection**: Focus is solely on Claude Code context; other AI agent environments are not considered
- **Custom error message configuration**: Users cannot customize the error message content or format
- **Telemetry or analytics**: No automatic tracking of user actions after error is displayed
- **Alternative SpecKit installation methods**: Only the standard `/speckit.constitution` path is recommended

## Open Questions *(optional)*

No open questions remain. All critical decisions have been made based on the PRD analysis:

- Context detection approach: Decided to use file-based detection (Decision 1)
- Explanation detail level: Decided on one-sentence explanation (Decision 2)
- Command recommendation: Decided to detect and customize (Decision 3)
- Documentation link: Decided to use GitHub repository URL (Decision 4)
- Error message tone: Decided on helpful/educational tone (Decision 5)
