# Data Model: Smart Conflict Resolution

**Phase**: 1 (Design & Contracts)
**Date**: 2025-10-21
**Feature**: [spec.md](spec.md) | [plan.md](plan.md) | [research.md](research.md)

## Overview

This document defines the data structures, entities, and relationships used in the smart conflict resolution feature. Since this is a PowerShell implementation, "entities" are represented as PowerShell hashtables or custom objects.

## Core Entities

### 1. DiffSection

Represents a contiguous block of changed lines in a file comparison.

**PowerShell Representation**: Custom hashtable

**Attributes**:

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `SectionNumber` | `[int]` | Sequential section identifier (1, 2, 3...) | `1` |
| `CurrentStartLine` | `[int]` | Starting line number in current version | `11` |
| `CurrentEndLine` | `[int]` | Ending line number in current version | `18` |
| `IncomingStartLine` | `[int]` | Starting line number in incoming version | `11` |
| `IncomingEndLine` | `[int]` | Ending line number in incoming version | `14` |
| `CurrentContent` | `[string]` | Lines from current version (with context) | `"line1\nline2\nline3"` |
| `IncomingContent` | `[string]` | Lines from incoming version (with context) | `"line1\nline2"` |
| `ChangeType` | `[string]` | Type of change: `Added`, `Removed`, `Modified` | `"Modified"` |

**Validation Rules**:
- `SectionNumber` MUST be positive integer
- `CurrentStartLine` MUST be ≤ `CurrentEndLine`
- `IncomingStartLine` MUST be ≤ `IncomingEndLine`
- `CurrentContent` and `IncomingContent` MUST NOT be null (empty string is valid)
- `ChangeType` MUST be one of: `Added`, `Removed`, `Modified`

**Relationships**:
- A file comparison produces multiple `DiffSection` entities (1-to-many)
- Sections are ordered by `SectionNumber`

**Example Instance**:
```powershell
$diffSection = @{
    SectionNumber = 1
    CurrentStartLine = 11
    CurrentEndLine = 18
    IncomingStartLine = 11
    IncomingEndLine = 14
    CurrentContent = @"
**Tests**: Tests are MANDATORY following Test-Driven Development (TDD)
methodology per Constitution Principle VIII. All tasks must follow
the Red-Green-Refactor cycle.
"@
    IncomingContent = @"
**Tests**: The examples below include test tasks. Tests are OPTIONAL -
only include them if explicitly requested in the feature specification.
"@
    ChangeType = "Modified"
}
```

### 2. UnchangedRange

Represents a range of line numbers that are identical in both versions.

**PowerShell Representation**: Custom hashtable

**Attributes**:

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `StartLine` | `[int]` | Starting line number (same in both versions) | `1` |
| `EndLine` | `[int]` | Ending line number (same in both versions) | `10` |
| `LineCount` | `[int]` | Number of lines in this range | `10` |
| `Description` | `[string]` | Optional human-readable description | `"Header and frontmatter"` |

**Validation Rules**:
- `StartLine` MUST be ≤ `EndLine`
- `LineCount` MUST equal `EndLine - StartLine + 1`
- `Description` is optional (can be null or empty)

**Relationships**:
- A file comparison produces multiple `UnchangedRange` entities (1-to-many)
- Ranges are ordered by `StartLine`
- Unchanged ranges are mutually exclusive with `DiffSection` ranges

**Example Instance**:
```powershell
$unchangedRange = @{
    StartLine = 1
    EndLine = 10
    LineCount = 10
    Description = "Header and frontmatter"
}
```

### 3. ConflictMetadata

Metadata about the conflict being resolved (used for diff file header).

**PowerShell Representation**: Custom hashtable

**Attributes**:

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `FilePath` | `[string]` | Relative path to the conflicting file | `.specify/templates/tasks-template.md` |
| `FileName` | `[string]` | File name only (for diff file naming) | `tasks-template.md` |
| `CurrentVersion` | `[string]` | Version identifier for current version | `v0.0.71` |
| `IncomingVersion` | `[string]` | Version identifier for incoming version | `v0.0.72` |
| `BaseVersion` | `[string]` | Version identifier for base version (may be null) | `v0.0.70` or `null` |
| `FileSize` | `[int]` | Line count in current version | `287` |
| `ResolutionMethod` | `[string]` | Method used: `SmartDiff` or `GitMarkers` | `"SmartDiff"` |
| `DiffFilePath` | `[string]` | Path to generated diff file (if applicable) | `.specify/.tmp-conflicts/tasks-template.diff.md` |

**Validation Rules**:
- `FilePath` MUST be non-empty string
- `FileName` MUST be non-empty string
- `CurrentVersion` and `IncomingVersion` MUST be non-empty strings
- `BaseVersion` MAY be null or empty (for first-time installs)
- `FileSize` MUST be positive integer
- `ResolutionMethod` MUST be `SmartDiff` or `GitMarkers`
- `DiffFilePath` is required only if `ResolutionMethod = SmartDiff`

**Example Instance**:
```powershell
$conflictMetadata = @{
    FilePath = ".specify/templates/tasks-template.md"
    FileName = "tasks-template.md"
    CurrentVersion = "v0.0.71"
    IncomingVersion = "v0.0.72"
    BaseVersion = $null  # First-time install scenario
    FileSize = 287
    ResolutionMethod = "SmartDiff"
    DiffFilePath = ".specify/.tmp-conflicts/tasks-template.diff.md"
}
```

### 4. ComparisonResult

Wrapper object containing all comparison data for a single file conflict.

**PowerShell Representation**: Custom hashtable

**Attributes**:

| Field | Type | Description |
|-------|------|-------------|
| `Metadata` | `ConflictMetadata` | File and version metadata |
| `DiffSections` | `[DiffSection[]]` | Array of changed sections |
| `UnchangedRanges` | `[UnchangedRange[]]` | Array of unchanged line ranges |
| `TotalChangedLines` | `[int]` | Count of changed lines across all sections |
| `TotalUnchangedLines` | `[int]` | Count of unchanged lines |

**Validation Rules**:
- `Metadata` MUST NOT be null
- `DiffSections` MUST be non-null array (empty array is valid)
- `UnchangedRanges` MUST be non-null array (empty array is valid)
- `TotalChangedLines + TotalUnchangedLines` SHOULD equal `Metadata.FileSize`

**Example Instance**:
```powershell
$comparisonResult = @{
    Metadata = $conflictMetadata
    DiffSections = @($diffSection1, $diffSection2, $diffSection3)
    UnchangedRanges = @($unchangedRange1, $unchangedRange2)
    TotalChangedLines = 45
    TotalUnchangedLines = 242
}
```

## Data Flow

### Input Flow

```
User initiates update
    ↓
Orchestrator detects conflict
    ↓
ConflictDetector.Invoke-FileStateAnalysis
    ↓
File categorized as "merge" (both local and upstream changes)
    ↓
Write-SmartConflictResolution invoked with:
    - FilePath
    - CurrentContent (normalized)
    - IncomingContent (normalized)
    - BaseContent (normalized, may be empty)
    - OriginalVersion (string)
    - NewVersion (string)
```

### Processing Flow

```
Write-SmartConflictResolution
    ↓
Detect file size (count lines in CurrentContent)
    ↓
If ≤ 100 lines → Call Write-ConflictMarkers (existing function)
If > 100 lines → Continue to smart diff generation
    ↓
Compare-FileSections
    ↓
    Calls Compare-Object on line arrays
    Groups consecutive changes into DiffSection entities
    Identifies unchanged ranges as UnchangedRange entities
    Returns ComparisonResult hashtable
    ↓
Write-SideBySideDiff
    ↓
    Accepts ComparisonResult
    Generates Markdown diff file
    Writes to .specify/.tmp-conflicts/[filename].diff.md
    Displays message to user with file path
```

### Output Flow

```
Diff file written to disk
    ↓
User sees message: "Review detailed diff: .specify/.tmp-conflicts/tasks-template.diff.md"
    ↓
User opens diff file in VSCode (or Claude presents in chat)
    ↓
User reviews changes
    ↓
User makes decision:
    - Keep current version (manual edit)
    - Accept incoming version (manual edit)
    - Hybrid (manual edit)
    ↓
Update completes successfully → Cleanup removes diff files
OR
Update rolls back → Diff files preserved for debugging
```

## State Transitions

### ConflictMetadata State

```
Initial State: Not exists
    ↓
Created during conflict detection
    ↓
ResolutionMethod determined (SmartDiff or GitMarkers)
    ↓
If SmartDiff: DiffFilePath assigned
    ↓
Passed to Write-SideBySideDiff
    ↓
Metadata written to diff file header
    ↓
Final State: Metadata persisted in diff file (temporary)
    ↓
Cleanup: Diff file deleted (metadata destroyed)
```

### DiffSection State

```
Initial State: Not exists
    ↓
Created by Compare-FileSections during comparison
    ↓
Assigned SectionNumber (sequential 1, 2, 3...)
    ↓
Content extracted with 3 lines of context
    ↓
Line numbers calculated
    ↓
ChangeType determined (Added/Removed/Modified)
    ↓
Added to DiffSections array
    ↓
Written to diff file as Markdown section
    ↓
Final State: Persisted in diff file (temporary)
```

## Constraints and Invariants

### Invariant 1: Non-Overlapping Ranges

**Rule**: `DiffSection` ranges and `UnchangedRange` ranges MUST NOT overlap.

**Validation**: For any line number `N`:
- If `N` is in a `DiffSection`, it MUST NOT be in any `UnchangedRange`
- If `N` is in an `UnchangedRange`, it MUST NOT be in any `DiffSection`

### Invariant 2: Complete Coverage

**Rule**: The union of all `DiffSection` ranges and `UnchangedRange` ranges SHOULD cover all lines in the file.

**Exception**: Context lines may extend ranges beyond the actual changed lines.

### Invariant 3: Sequential Section Numbers

**Rule**: `DiffSection.SectionNumber` values MUST be sequential integers starting from 1.

**Validation**: For sections `[S1, S2, S3, ..., Sn]`:
- `S1.SectionNumber = 1`
- `S2.SectionNumber = 2`
- `Sn.SectionNumber = n`

### Invariant 4: Line Number Monotonicity

**Rule**: Within a version, line ranges MUST be monotonically increasing.

**Validation**: For consecutive sections `Si` and `Si+1`:
- `Si.CurrentEndLine < Si+1.CurrentStartLine` (no overlap)
- `Si.IncomingEndLine < Si+1.IncomingStartLine` (no overlap)

## Performance Considerations

### Memory Usage

For a typical 500-line template file with 5 changed sections:

```
DiffSection entities: 5 sections × ~500 bytes = 2.5 KB
UnchangedRange entities: 6 ranges × ~100 bytes = 600 bytes
Content strings: 500 lines × ~80 chars/line × 2 versions = ~80 KB
Total: ~83 KB
```

**Acceptable**: Well within PowerShell memory limits.

### Time Complexity

| Operation | Time Complexity | Typical Time (500 lines) |
|-----------|-----------------|--------------------------|
| Compare-Object | O(n²) worst case, O(n) average | 50-100ms |
| Grouping changes | O(n) | 10-20ms |
| Writing diff file | O(n) | 20-50ms |
| **Total** | **O(n)** | **80-170ms** |

**Target**: < 2 seconds for 1000-line files (easily met).

## Testing Data Fixtures

### Fixture 1: Small File (50 lines, should use Git markers)

```powershell
$smallFileFixture = @{
    CurrentContent = (1..50 | ForEach-Object { "Line $_" }) -join "`n"
    IncomingContent = (1..50 | ForEach-Object {
        if ($_ -eq 25) { "Modified Line 25" } else { "Line $_" }
    }) -join "`n"
    ExpectedResolutionMethod = "GitMarkers"
}
```

### Fixture 2: Large File (200 lines, 3 changed sections)

```powershell
$largeFileFixture = @{
    CurrentContent = (1..200 | ForEach-Object { "Line $_" }) -join "`n"
    IncomingContent = (1..200 | ForEach-Object {
        if ($_ -in 11..14) { "Modified Line $_" }
        elseif ($_ -in 54..58) { "Modified Line $_" }
        elseif ($_ -in 120..125) { "Modified Line $_" }
        else { "Line $_" }
    }) -join "`n"
    ExpectedResolutionMethod = "SmartDiff"
    ExpectedDiffSections = 3
}
```

### Fixture 3: Empty Base (First-time install scenario)

```powershell
$emptyBaseFixture = @{
    CurrentContent = (1..100 | ForEach-Object { "Custom Line $_" }) -join "`n"
    IncomingContent = (1..100 | ForEach-Object { "Template Line $_" }) -join "`n"
    BaseContent = ""  # Empty base version
    ExpectedResolutionMethod = "GitMarkers"  # Small file
}
```

## Future Extensions

### Potential Enhancements (Out of Scope for MVP)

1. **ChangePercentage Filter**: Add secondary threshold based on percentage of file changed
   - Requires: Calculate `TotalChangedLines / FileSize`
   - Use case: Large file with only 1-2 line changes (may not need diff)

2. **Section Descriptions**: Auto-generate descriptions for unchanged ranges
   - Requires: Parse headings, detect structural patterns
   - Use case: "Lines 1-10: Header and metadata"

3. **Syntax Highlighting**: Detect file type and add language hints to code blocks
   - Requires: File extension mapping (`.md` → `markdown`, `.ps1` → `powershell`)
   - Use case: Better diff readability in VSCode preview

4. **Conflict Resolution Tracking**: Track which sections user accepted/rejected
   - Requires: Persistent state in manifest
   - Use case: Analytics on conflict resolution patterns
