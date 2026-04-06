# Feature Specification: Smart Conflict Resolution for Large Files

**Feature Branch**: `008-smart-conflict-resolution`
**Created**: 2025-10-21
**Status**: Draft
**Input**: User description: "Implement smart conflict resolution that shows only changed sections for large files instead of full Git conflict markers"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Large Template File Conflict Review (Priority: P1)

A SpecKit user updates their templates and encounters a conflict in a large template file (500+ lines). Instead of seeing the entire file duplicated in Git conflict markers (which shows no indication of what changed), they receive a side-by-side diff file showing only the sections that actually differ between versions.

**Why this priority**: This is the core value proposition of the feature. Large file conflicts are the most painful scenario (mentioned in bug report as "critical usability issue") and directly undermine the "safe updates" promise. Without this, users cannot make informed decisions about template conflicts.

**Independent Test**: Can be fully tested by simulating a large file (>100 lines) with conflicts and verifying that a diff file is generated in `.specify/.tmp-conflicts/` showing only changed sections with line numbers and clear comparison format. Delivers immediate value by making large file conflicts reviewable.

**Acceptance Scenarios**:

1. **Given** a user is updating SpecKit templates AND a file over 100 lines has both local customizations and upstream changes, **When** the conflict resolution process runs, **Then** a side-by-side diff file is created at `.specify/.tmp-conflicts/[filename].diff.md` showing only changed sections with line numbers
2. **Given** a large file conflict diff was generated, **When** the user opens the diff file, **Then** they see clearly labeled sections: "Changed Section 1", "Changed Section 2", etc., each showing "Your Version" vs "Incoming Version" with line number context
3. **Given** a large file conflict diff is displayed, **When** the user reviews it, **Then** they can clearly identify which specific lines differ between versions without scrolling through hundreds of duplicate lines
4. **Given** a large file has conflicts, **When** the diff is generated, **Then** the system displays a message indicating the conflict and the path to the detailed diff file (e.g., "Review detailed diff: .specify/.tmp-conflicts/tasks-template.diff.md")

---

### User Story 2 - Small File Standard Conflict Handling (Priority: P2)

A SpecKit user updates templates and encounters a conflict in a small file (under 100 lines). The system continues to use the existing Git conflict marker approach, which works effectively for files of this size.

**Why this priority**: This ensures backward compatibility and avoids over-engineering. Git markers work fine for small files where users can easily scroll and compare. Changing this behavior would create unnecessary complexity without user benefit.

**Independent Test**: Can be fully tested by simulating a small file (<= 100 lines) with conflicts and verifying that Git conflict markers are written directly to the file (not a separate diff file). Delivers value by maintaining familiar workflow for small files.

**Acceptance Scenarios**:

1. **Given** a user is updating SpecKit templates AND a file with 100 or fewer lines has both local customizations and upstream changes, **When** the conflict resolution process runs, **Then** Git conflict markers are written directly to the file in standard 3-way format
2. **Given** a small file uses Git markers, **When** the user opens the file in VSCode, **Then** they see CodeLens actions (Accept Current, Accept Incoming, Accept Both, Compare) for resolving the conflict
3. **Given** the system is determining conflict resolution method, **When** a file has exactly 100 lines, **Then** Git markers are used (not "greater than 100")

---

### User Story 3 - Diff File Cleanup After Resolution (Priority: P3)

A SpecKit user completes conflict resolution and the update succeeds. The system automatically cleans up temporary diff files that were created during the conflict resolution process, preventing clutter in the `.specify/.tmp-conflicts/` directory.

**Why this priority**: This is important for user experience (preventing directory clutter) but is lower priority than the core conflict resolution functionality. Users can manually delete these files if cleanup fails, so it's not blocking.

**Independent Test**: Can be fully tested by creating conflict diff files, completing an update successfully, and verifying that `.specify/.tmp-conflicts/` directory is cleaned up. Delivers value by maintaining a clean working directory.

**Acceptance Scenarios**:

1. **Given** conflict diff files exist in `.specify/.tmp-conflicts/` AND the update completes successfully, **When** cleanup runs, **Then** the temporary diff files are removed
2. **Given** an update is rolled back, **When** cleanup would normally run, **Then** the diff files are preserved for debugging purposes
3. **Given** the `.specify/.tmp-conflicts/` directory doesn't exist, **When** cleanup runs, **Then** no error occurs (graceful handling)

---

### User Story 4 - Unchanged Sections Summary (Priority: P3)

When reviewing a large file conflict diff, users can see a summary of unchanged sections at the bottom of the diff file. This confirms which parts of the file are identical in both versions and don't require review.

**Why this priority**: This is a nice-to-have enhancement that provides additional context but isn't critical to the core workflow. Users can successfully resolve conflicts without this information.

**Independent Test**: Can be fully tested by generating a large file diff and verifying the "Unchanged Sections" list appears with accurate line ranges. Delivers value by reducing cognitive load during conflict review.

**Acceptance Scenarios**:

1. **Given** a large file conflict diff is generated, **When** the user scrolls to the bottom of the diff file, **Then** they see an "Unchanged Sections" list showing line ranges that are identical in both versions
2. **Given** the unchanged sections list is displayed, **When** the user reviews it, **Then** the line ranges are accurate and correspond to actual unchanged content

---

### Edge Cases

- What happens when a file is exactly 100 lines? (Use Git markers per requirement)
- What happens when a file is 101 lines but has only 1 line changed? (Generate diff - file size is primary criterion, not change percentage)
- What happens when `.specify/.tmp-conflicts/` directory doesn't exist? (Create it automatically)
- What happens when diff file generation fails (e.g., permissions error)? (Fall back to Git markers and warn user)
- What happens when comparing two identical files (no actual changes)? (Should not reach conflict resolution - system error upstream)
- What happens when base version is empty (v0.0.0 scenario)? (Compare current vs incoming only, mark base as "empty")
- What happens when cleanup fails? (Log warning but don't fail the update - cleanup is non-critical)
- What happens when file encoding causes comparison issues? (Use normalized content from HashUtils module - CRLF/LF normalization already implemented)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST detect file size before applying conflict resolution (count lines in current version)
- **FR-002**: System MUST use side-by-side diff format for files with more than 100 lines when conflicts exist
- **FR-003**: System MUST use standard Git conflict markers for files with 100 or fewer lines when conflicts exist
- **FR-004**: System MUST compare current version and incoming version line-by-line to identify changed sections
- **FR-005**: System MUST group consecutive changed lines into logical sections (e.g., "Changed Section 1", "Changed Section 2")
- **FR-006**: System MUST include line numbers for each changed section showing the range in both current and incoming versions
- **FR-007**: System MUST write diff output to `.specify/.tmp-conflicts/[filename].diff.md` for large file conflicts
- **FR-008**: System MUST display a message to the user indicating the conflict and the path to the diff file when generated
- **FR-009**: System MUST format diff files as valid Markdown with clear headings and code blocks
- **FR-010**: System MUST show both "Your Version" and "Incoming Version" for each changed section
- **FR-011**: System MUST include version information (e.g., "v0.0.71" vs "v0.0.72") in the diff file header
- **FR-012**: System MUST list unchanged sections at the end of the diff file with line ranges
- **FR-013**: System MUST create `.specify/.tmp-conflicts/` directory if it doesn't exist
- **FR-014**: System MUST clean up temporary diff files after successful update completion
- **FR-015**: System MUST preserve diff files when an update is rolled back (for debugging)
- **FR-016**: System MUST handle edge cases gracefully (empty base version, encoding issues, permission errors)
- **FR-017**: System MUST use normalized content comparison (leveraging existing HashUtils module for CRLF/LF normalization)
- **FR-018**: System MUST add 3 lines of context before and after each changed section for readability
- **FR-019**: System MUST export new functions (`Write-SmartConflictResolution`, `Compare-FileSections`, `Write-SideBySideDiff`) from ConflictDetector module
- **FR-020**: System MUST maintain backward compatibility with existing Git marker workflow for small files

### Key Entities *(include if feature involves data)*

- **Diff Section**: Represents a contiguous block of changed lines in a file comparison
  - Attributes: start line number (current), end line number (current), start line number (incoming), end line number (incoming), current content, incoming content, context lines (before/after)
  - Relationships: Multiple sections per file comparison

- **Conflict Resolution Metadata**: Information about the conflict being resolved
  - Attributes: file path, current version ID, incoming version ID, base version ID (may be empty), file size (line count), resolution method used (Git markers vs diff file)
  - Relationships: One per conflicting file

- **Unchanged Section Range**: A range of line numbers that are identical in both versions
  - Attributes: start line number, end line number, description (e.g., "Header and frontmatter", "Format and Path Conventions")
  - Relationships: Multiple ranges per file comparison

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can identify specific changed lines in large file conflicts (>100 lines) without scrolling through duplicate full file content
- **SC-002**: Diff files are generated in under 2 seconds for files up to 1000 lines
- **SC-003**: Diff file format is valid Markdown that renders correctly in VSCode preview and Claude Code chat
- **SC-004**: Users report improved confidence in conflict resolution decisions for large files (measured by reduced "accept blindly" behavior)
- **SC-005**: System correctly categorizes files as "large" (>100 lines) or "small" (<=100 lines) in 100% of cases
- **SC-006**: Side-by-side diff shows only changed sections, reducing content volume by at least 80% for typical template conflicts
- **SC-007**: Unchanged section summary is accurate in 100% of generated diff files (no false positives/negatives)
- **SC-008**: Cleanup process removes temporary diff files successfully after 95% of completed updates
- **SC-009**: System handles edge cases (empty base, encoding issues, permission errors) without crashing or corrupting data
- **SC-010**: All existing unit and integration tests continue to pass (backward compatibility maintained)

## Assumptions *(optional)*

- VSCode is the primary editor for reviewing diff files (Markdown rendering expected)
- Users have basic familiarity with diff/merge workflows (understand "Current" vs "Incoming" terminology)
- The existing HashUtils module provides reliable normalized content comparison (CRLF/LF handling)
- The 100-line threshold is reasonable for typical editor viewports (40-60 lines visible)
- PowerShell's `Compare-Object` cmdlet is suitable for line-by-line comparison (performance acceptable for files up to 1000 lines)
- The `.specify/.tmp-conflicts/` directory is safe to clean up after successful updates (users don't manually modify these files)
- Git conflict markers continue to work effectively for small files (<= 100 lines)
- The current Git marker implementation (`Write-ConflictMarkers` function) is reliable and tested

## Out of Scope *(optional)*

- Syntax highlighting for different file types in diff output (future enhancement)
- Interactive resolution wizard with checkboxes for accepting/rejecting changes (architectural constraint: text-only I/O)
- HTML diff viewer or browser integration (architectural constraint: subprocess limitations)
- Integration with external diff tools (e.g., Beyond Compare, WinMerge) - too unreliable per bug #005
- Automatic conflict resolution based on heuristics (requires AI/ML, too complex)
- Configurable threshold for "large file" definition (100 lines is hardcoded for MVP)
- Change percentage calculation as secondary filter (implementation complexity not justified for MVP)
- Diff file retention policy beyond "cleanup on success, preserve on rollback" (future enhancement)

## Dependencies *(optional)*

- **Existing Module**: `scripts/modules/HashUtils.psm1` - Provides normalized content hashing for reliable comparison
- **Existing Module**: `scripts/modules/ConflictDetector.psm1` - Contains existing `Write-ConflictMarkers` function to be enhanced
- **Existing Orchestrator**: `scripts/update-orchestrator.ps1` - Calls conflict resolution functions, handles cleanup
- **Existing Helper**: `scripts/helpers/Invoke-ConflictResolutionWorkflow.ps1` - May need updates to guide users to review diff files
- **PowerShell Version**: 7.x (pwsh.exe) - Required for compatibility with existing codebase
- **Git**: Not a direct dependency (uses Git marker format but doesn't invoke Git commands)

## Open Questions *(optional)*

None - all implementation details are well-defined in the bug report and technical analysis.

## Technical Constraints *(optional)*

- **Text-Only I/O**: PowerShell subprocess runs under Claude Code with stdout/stderr streams only (no GUI dialogs or VSCode API access)
- **No External Tools**: Cannot reliably invoke external diff viewers (e.g., `code --diff`) per architectural limitations documented in bug #005
- **Performance**: Diff generation must complete quickly to avoid blocking the update workflow (target: <2 seconds for 1000-line files)
- **Memory**: Large file content must be loaded into memory for comparison (PowerShell string manipulation constraints)
- **Cross-Platform**: Output must render correctly in Windows terminal, VSCode preview, and Claude Code chat (Markdown format requirement)
- **Module Scope**: New functions must follow the Module vs Helper pattern (use `Export-ModuleMember` in ConflictDetector.psm1)
- **Import Pattern**: All module imports must be in the orchestrator only (no nested imports per constitution rules)

## Related Context *(optional)*

- **Bug Report**: `docs/bugs/006-large-file-conflict-markers-unhelpful.md` - Original bug report with detailed analysis
- **Related Issue**: #13 - First-time install scenario will encounter this with all templates
- **Related Issue**: #5 - VSCode Quick Pick limitation affects external diff tool integration
- **Historical Context**: v0.2.0 implemented Git conflict markers which work well for small files
- **Architecture Doc**: `CLAUDE.md` section "Git Conflict Markers" describes current implementation
- **Original Spec**: `specs/001-safe-update/spec.md` - Safe update workflow specification
- **Module Documentation**: PowerShell comment-based help in existing modules provides patterns to follow
