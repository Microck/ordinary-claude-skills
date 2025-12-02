# Feature Specification: Remove VSCode QuickPick Integration

**Feature Branch**: `007-remove-quickpick-integration`
**Created**: 2025-10-21
**Status**: Draft
**Input**: User description: "docs\bugs\005-vscode-quickpick-architectural-limitation.md"

## Clarifications

### Session 2025-10-21

- Q: Can `code --merge` (VSCode 3-way merge editor) work when Claude Code VSCode Extension spawns PowerShell subprocess? → A: Test first during implementation; if fails, remove feature and use Git conflict markers only
- Q: Should terminal invocation be a supported user-facing workflow? → A: Skill works from Claude Code CLI and VSCode Extension; direct PowerShell execution is dev/testing only, not user-facing
- Q: What should default behavior be in Claude Code without `-Auto` flag? → A: Remove `-Auto` flag entirely; skill outputs summary text, Claude handles approval workflow, skill proceeds after confirmation
- Q: How should conflict resolution work given interactive prompt limitations? → A: Test `code --merge` availability; if unavailable, write Git-style conflict markers to files (VSCode detects and provides native resolution UI)
- Q: Is current Get-VSCodeContext detection (VSCODE_PID + TERM_PROGRAM) sufficient? → A: Yes, current detection logic is sufficient for distinguishing Claude Code contexts

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Claude Code Execution with Summary Approval (Priority: P1)

When a developer invokes the SpecKit update skill through Claude Code, the skill analyzes changes, outputs a text summary of proposed updates, and waits for Claude to handle user approval through conversational workflow before proceeding.

**Why this priority**: This is the primary supported workflow for Claude Code users (CLI and Extension) and must work reliably without requiring command-line flags or interactive prompts.

**Independent Test**: Can be fully tested by running `/speckit-update` in Claude Code, verifying summary text is output, approving via chat, and confirming the update completes successfully. Delivers value by enabling conversational update workflow.

**Acceptance Scenarios**:

1. **Given** the skill is invoked via Claude Code, **When** the analysis completes, **Then** a text summary of changes is output (files to update, conflicts, etc.)
2. **Given** the summary is displayed to user, **When** user approves via Claude chat, **Then** the workflow proceeds without attempting Show-QuickPick or Read-Host prompts
3. **Given** the skill is executing updates, **When** processing files, **Then** no interactive PowerShell prompts are displayed

---

### User Story 2 - Conflict Resolution with Git Markers (Priority: P2)

When the skill detects file conflicts (local customizations plus upstream changes), it writes Git-style conflict markers to the conflicted files, allowing VSCode's native conflict resolution UI to handle merging without requiring external process invocation.

**Why this priority**: Conflicts are common when users customize templates, and the resolution mechanism must work reliably in Claude Code contexts where interactive prompts fail.

**Independent Test**: Can be tested by customizing a tracked file, running `/speckit-update` when upstream has changes, and verifying Git conflict markers are written and VSCode shows merge UI.

**Acceptance Scenarios**:

1. **Given** a file has both local modifications and upstream changes, **When** the skill processes conflicts, **Then** Git-style markers (`<<<<<<<`, `=======`, `>>>>>>>`) are written to the file
2. **Given** conflict markers are written, **When** user opens the file in VSCode, **Then** VSCode's CodeLens conflict resolution UI appears automatically
3. **Given** the skill attempted `code --merge` and it failed, **When** falling back to conflict markers, **Then** no error is shown to user (seamless fallback)

---

### User Story 3 - Works from Both Claude Code CLI and VSCode Extension (Priority: P2)

When a developer uses the skill from either Claude Code CLI (terminal-based) or Claude Code VSCode Extension, the skill executes successfully using the same conversational approval workflow without requiring different flags or commands.

**Why this priority**: Users should have a consistent experience regardless of which Claude Code interface they prefer, with automatic context detection handling the differences.

**Independent Test**: Can be tested by running `/speckit-update` from both Claude Code CLI and VSCode Extension, verifying identical output format and workflow in both contexts.

**Acceptance Scenarios**:

1. **Given** the skill is invoked via Claude Code CLI, **When** execution begins, **Then** Get-VSCodeContext correctly identifies the context and outputs text summary
2. **Given** the skill is invoked via Claude Code VSCode Extension, **When** execution begins, **Then** the same text summary format is output without attempting VSCode UI integration
3. **Given** the skill runs in either context, **When** user approves via chat, **Then** the update proceeds identically without context-specific code paths

---

### User Story 4 - Clean Codebase Without Broken Functionality (Priority: P3)

When developers and maintainers work with the skill codebase, they encounter only functional code without broken VSCode UI integration attempts, making the architectural limitations and supported workflows clear.

**Why this priority**: Reduces maintenance burden, eliminates confusion, and makes the codebase easier to understand. While important for long-term maintainability, it doesn't directly impact end users.

**Independent Test**: Can be tested by searching the codebase for `Show-QuickPick` and verifying it no longer exists, and by reviewing VSCodeIntegration.psm1 to confirm it only contains working functions.

**Acceptance Scenarios**:

1. **Given** a developer searches for `Show-QuickPick` in the codebase, **When** the search completes, **Then** no function definition or calls are found
2. **Given** a developer reads VSCodeIntegration.psm1, **When** reviewing exported functions, **Then** only Get-VSCodeContext is exported (Show-QuickPick is removed)
3. **Given** a maintainer reads the constitution, **When** reviewing architectural principles, **Then** principles explicitly prohibit VSCode UI integration attempts
4. **Given** a developer reads CLAUDE.md, **When** looking for architectural limitations, **Then** the documentation clearly explains that skills can only use text-based I/O

---

### Edge Cases

- What happens when the skill is run directly via PowerShell (not through Claude Code)? This is dev/testing-only usage; skill outputs summary text and proceeds without approval (or fails gracefully if approval mechanism is unavailable).
- What happens if Get-VSCodeContext fails to detect the execution context correctly? The system defaults to outputting text summary without attempting interactive prompts.
- What happens if `code --merge` test fails during conflict resolution? The system seamlessly falls back to writing Git conflict markers without showing error to user.
- What happens if a file has conflict markers but user doesn't resolve them before next update? The skill detects existing conflict markers and warns user to resolve before proceeding.
- What happens if user rejects the update during Claude approval workflow? Claude does not re-invoke the skill; no files are modified; exit code 5 (user cancelled) is returned.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST remove the Show-QuickPick function from VSCodeIntegration.psm1 (lines 55-143)
- **FR-002**: System MUST remove Show-QuickPick from the Export-ModuleMember statement in VSCodeIntegration.psm1
- **FR-003**: System MUST remove all calls to Show-QuickPick from Get-UpdateConfirmation.ps1 (lines 113-126)
- **FR-004**: System MUST retain the Get-VSCodeContext function in VSCodeIntegration.psm1 (lines 8-53) for context detection
- **FR-005**: System MUST remove the `-Auto` flag from update-orchestrator.ps1 parameter definitions
- **FR-006**: System MUST output structured text summary of proposed changes (files to update, conflicts, backup path) to stdout for Claude to parse
- **FR-007**: System MUST support approval confirmation via command-line parameter (e.g., `-Confirm:$false` or internal flag) for Claude to pass after user approval
- **FR-008**: System MUST remove all Read-Host prompts from Get-UpdateConfirmation.ps1 (replaced by summary output + approval parameter)
- **FR-009**: System MUST test `code --merge` availability at runtime by attempting invocation with timeout
- **FR-010**: System MUST write Git-style conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`) to files when conflicts are detected
- **FR-011**: System MUST include base version, current version, and incoming version in conflict marker sections
- **FR-012**: System MUST update SKILL.md to document conversational approval workflow (no flags required)
- **FR-013**: System MUST add "Architectural Limitations" section to CLAUDE.md explaining VSCode UI integration impossibility and Git conflict marker solution
- **FR-014**: System MUST add principles to constitution prohibiting VSCode UI integration attempts and requiring text-only I/O
- **FR-015**: System MUST remove all tests for Show-QuickPick from tests/unit/VSCodeIntegration.Tests.ps1
- **FR-016**: System MUST add integration test verifying conflict markers are written correctly when conflicts detected
- **FR-017**: System MUST add integration test verifying skill works identically from Claude Code CLI and VSCode Extension contexts

### Key Entities

- **Show-QuickPick Function**: Non-functional code attempting to display VSCode Quick Pick UI by returning sentinel hashtables; to be removed entirely
- **Get-VSCodeContext Function**: Working function that detects execution context (Claude Code CLI, VSCode Extension, standalone); to be retained for context detection
- **Summary Output**: Structured text output containing proposed changes, conflicts, and backup information; replaces interactive prompts; consumed by Claude for user presentation
- **Approval Parameter**: Command-line parameter (e.g., `-Confirm:$false`) that Claude passes after user approves; replaces `-Auto` flag and interactive prompts
- **Git Conflict Markers**: Standard merge conflict syntax (`<<<<<<<`, `=======`, `>>>>>>>`) written to files; enables VSCode native conflict resolution UI
- **Get-UpdateConfirmation Helper**: Script that outputs summary text and checks approval parameter; to be modified to remove Show-QuickPick and Read-Host calls

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Skill completes successfully when invoked via Claude Code (CLI and Extension) without requiring flags (100% success rate in testing)
- **SC-002**: Summary output is displayed within 2 seconds of analysis completion, containing all required information (files to update, conflicts, backup path)
- **SC-003**: Conversational approval workflow completes in under 5 seconds from user approval to skill proceeding with updates
- **SC-004**: Git conflict markers are written correctly with base/current/incoming versions (validated by VSCode recognizing and showing merge UI)
- **SC-005**: Codebase search for "Show-QuickPick" returns zero results after cleanup
- **SC-006**: Codebase search for "-Auto" flag references returns zero results in user-facing documentation (may remain in dev/testing docs)
- **SC-007**: All existing tests continue to pass except those testing Show-QuickPick functionality (which are removed)
- **SC-008**: Documentation clearly explains architectural limitations and Git conflict marker solution in at least 2 locations (SKILL.md and CLAUDE.md)
- **SC-009**: Constitution includes at least 1 principle prohibiting VSCode UI integration attempts and requiring text-only I/O
