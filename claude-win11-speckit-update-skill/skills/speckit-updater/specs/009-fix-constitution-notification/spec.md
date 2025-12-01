# Feature Specification: Fix False Constitution Update Notification

**Feature Branch**: `009-fix-constitution-notification`
**Created**: 2025-10-22
**Status**: Draft
**Input**: User description: "docs\bugs\007-false-constitution-update-notification.md"

## Clarifications

### Session 2025-10-22

- Q: How should notifications differentiate required vs. optional actions for colorblind users or terminals with limited color support? → A: Icons plus colors - add emoji/symbols (⚠️ for required, ℹ️ for optional) with colors
- Q: What format and detail level should verbose hash comparison logging use for effective debugging? → A: Structured key-value format with file paths and timestamps
- Q: What information should be logged when Get-NormalizedHash throws an error for troubleshooting? → A: Exception type, message, file path, and suggested action

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Suppress False Positive Notifications (Priority: P1)

When a user runs `/speckit-update` and the constitution file hasn't actually changed (even though it's marked as "updated"), the system should not display a notification asking them to run `/speckit.constitution`. This eliminates confusion and unnecessary work.

**Why this priority**: This is the core bug fix that directly addresses user frustration and trust issues. Without this, users receive confusing notifications that waste their time and undermine confidence in the tool.

**Independent Test**: Can be fully tested by running an update where the constitution file is marked as updated but the content is identical (hash match). Delivers immediate value by eliminating false positives.

**Acceptance Scenarios**:

1. **Given** constitution file marked as "updated" in FilesUpdated array, **When** system compares backup hash to current hash and finds them identical, **Then** no notification is displayed to user
2. **Given** constitution file marked as "updated" but no backup exists, **When** system cannot compare hashes, **Then** notification is shown (fail-safe behavior)
3. **Given** fresh install scenario (v0.0.0 to v0.0.78) with identical constitution content, **When** update completes, **Then** no notification shown because hashes match

---

### User Story 2 - Clear Notification for Real Updates (Priority: P2)

When a user runs `/speckit-update` and the constitution file has been cleanly updated (no conflicts, but real content changes), the system should display an informational notification indicating the update is optional to review.

**Why this priority**: Keeps users informed about important constitution changes while making clear that reviewing is optional (no manual resolution required). This provides value but is less critical than fixing the false positive bug.

**Independent Test**: Can be fully tested by running an update where constitution differs from backup with no conflicts. Delivers value by keeping users informed without creating false urgency.

**Acceptance Scenarios**:

1. **Given** constitution cleanly updated with real content changes, **When** system compares hashes and finds they differ, **Then** displays ℹ️ information icon with cyan/gray informational message showing "OPTIONAL: Review changes"
2. **Given** constitution cleanly updated, **When** notification is shown, **Then** message includes backup path for comparison: `/speckit.constitution [backup-path]`
3. **Given** constitution cleanly updated, **When** verbose logging enabled, **Then** hash comparison details are logged in structured key-value format with current hash, backup hash, file paths, timestamp, and changed status

---

### User Story 3 - Urgent Notification for Conflicts (Priority: P3)

When a user runs `/speckit-update` and the constitution file has conflicts (user customized it AND upstream has changes), the system should display an urgent notification indicating that running `/speckit.constitution` is required to resolve conflicts.

**Why this priority**: While important for clarity, the existing system already notifies on conflicts. This story enhances the messaging to differentiate required vs. optional actions, but the core functionality already works.

**Independent Test**: Can be fully tested by running an update where constitution is customized locally and has upstream changes. Delivers value by making the severity clear to users.

**Acceptance Scenarios**:

1. **Given** constitution has conflicts (customized + upstream changes), **When** system detects real content changes via hash comparison, **Then** displays ⚠️ warning icon with red/yellow urgent message showing "REQUIRED: Run the following command"
2. **Given** constitution conflict detected, **When** notification is shown, **Then** message clearly distinguishes this from optional update notifications
3. **Given** constitution conflict with no actual hash changes (edge case), **When** hashes match, **Then** no notification shown (prevents false positive even in conflict scenario)

---

### Edge Cases

- What happens when backup directory doesn't exist at Step 12 (should never occur, but need fail-safe)?
  - **Expected**: System assumes file changed and shows notification (fail-safe behavior)

- How does system handle hash normalization differences (CRLF vs LF, BOM, trailing whitespace)?
  - **Expected**: Uses existing `Get-NormalizedHash` function which handles normalization automatically

- What if constitution file doesn't exist in current project but exists in backup?
  - **Expected**: Hash comparison will fail, system treats as changed (notification shown)

- What if `Get-NormalizedHash` throws an error (file locked, permissions issue)?
  - **Expected**: Catch exception, log verbose error (exception type, message, file path, suggested action), assume file changed (fail-safe notification)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST verify actual content changes before displaying constitution update notification
- **FR-002**: System MUST compare normalized file hashes (backup vs. current) to detect real changes
- **FR-003**: System MUST suppress notification when backup hash equals current hash (identical content)
- **FR-004**: System MUST display notification when backup hash differs from current hash (real changes)
- **FR-005**: System MUST differentiate conflict notifications (REQUIRED action) from clean update notifications (OPTIONAL review)
- **FR-006**: System MUST use existing `Get-NormalizedHash` function from HashUtils module for hash computation
- **FR-007**: System MUST log verbose hash comparison details in structured key-value format including current hash, backup hash, changed status, file paths, and timestamp for debugging
- **FR-008**: System MUST fail-safe to showing notification if backup doesn't exist or hash comparison fails, logging exception type, message, file path, and suggested action when errors occur
- **FR-009**: Conflict notifications MUST use ⚠️ warning emoji/icon with red/yellow color scheme and "REQUIRED" label for accessibility
- **FR-010**: Clean update notifications MUST use ℹ️ information emoji/icon with cyan/gray color scheme and "OPTIONAL" label for accessibility
- **FR-011**: All notifications MUST include backup path parameter for `/speckit.constitution` command
- **FR-012**: System MUST check for notification conditions after both FilesUpdated and ConflictsResolved arrays are populated

### Key Entities *(include if feature involves data)*

- **Update Result Object**: Contains arrays tracking which files were updated, preserved, or had conflicts during update process
  - `FilesUpdated`: Array of file paths marked as updated
  - `ConflictsResolved`: Array of file paths with resolved conflicts
  - `ConstitutionUpdateNeeded`: Boolean flag indicating whether user should run `/speckit.constitution`

- **Hash Comparison State**: Represents the verification check performed before notification
  - Current file hash (normalized SHA-256 from current `.specify/memory/constitution.md`)
  - Backup file hash (normalized SHA-256 from backup directory constitution.md)
  - Change detection flag (true if hashes differ, false if identical)

- **Notification Context**: Information needed to display appropriate message to user
  - Notification type (conflict vs. clean update)
  - Severity level (required vs. optional)
  - Emoji/icon indicator (⚠️ for conflicts, ℹ️ for updates)
  - Backup path for user command reference
  - Color scheme for terminal output

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Zero false positive notifications when constitution file content is unchanged (100% elimination of false positives)
- **SC-002**: Users receive accurate notifications for all real constitution changes (100% detection rate for actual changes)
- **SC-003**: Users can distinguish required actions (conflicts) from optional reviews (clean updates) within 3 seconds of reading notification
- **SC-004**: Hash verification adds less than 100ms to Step 12 processing time (negligible performance impact)
- **SC-005**: 95% of users correctly understand whether action is required based on notification wording and color
- **SC-006**: Support requests related to constitution update confusion reduced by 80% compared to pre-fix baseline
