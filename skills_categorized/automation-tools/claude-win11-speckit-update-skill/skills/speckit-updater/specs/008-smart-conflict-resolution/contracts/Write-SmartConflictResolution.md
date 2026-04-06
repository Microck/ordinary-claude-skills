# Function Contract: Write-SmartConflictResolution

**Module**: ConflictDetector.psm1
**Type**: Public (Exported)
**Phase**: 1 (Design & Contracts)
**Date**: 2025-10-21

## Purpose

Writes conflict resolution based on file size. For large files (>100 lines), generates a side-by-side diff file showing only changed sections. For small files (≤100 lines), uses standard Git conflict markers.

This is the entry point function that replaces `Write-ConflictMarkers` calls in the orchestrator when smart resolution is needed.

## Signature

```powershell
function Write-SmartConflictResolution {
    <#
    .SYNOPSIS
        Writes conflict resolution based on file size (smart diff vs. standard markers).

    .DESCRIPTION
        For large files (>100 lines), generates a side-by-side diff file showing only
        changed sections in Markdown format. For small files (≤100 lines), uses standard
        Git conflict markers. Falls back to Git markers on any error.

    .PARAMETER FilePath
        The path to the conflicting file (relative to project root).

    .PARAMETER CurrentContent
        The current file content (user's version). Must be normalized.

    .PARAMETER BaseContent
        The base file content from manifest (original version). May be empty.

    .PARAMETER IncomingContent
        The incoming file content from upstream (new version). Must be normalized.

    .PARAMETER OriginalVersion
        Version identifier for the base/current version (e.g., "v0.0.71").

    .PARAMETER NewVersion
        Version identifier for the incoming version (e.g., "v0.0.72").

    .EXAMPLE
        Write-SmartConflictResolution -FilePath ".specify/templates/tasks-template.md" `
                                       -CurrentContent $currentVersion `
                                       -BaseContent $baseVersion `
                                       -IncomingContent $incomingVersion `
                                       -OriginalVersion "v0.0.71" `
                                       -NewVersion "v0.0.72"

        Generates a smart diff file for a large template file.

    .EXAMPLE
        Write-SmartConflictResolution -FilePath ".claude/commands/small-command.md" `
                                       -CurrentContent $current `
                                       -BaseContent $base `
                                       -IncomingContent $incoming `
                                       -OriginalVersion "v1" `
                                       -NewVersion "v2"

        Uses Git conflict markers for a small file (≤100 lines).

    .NOTES
        This function has the same signature as Write-ConflictMarkers for drop-in
        replacement. It calls Write-ConflictMarkers internally for small files.

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$CurrentContent,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$BaseContent,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$IncomingContent,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OriginalVersion,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NewVersion
    )

    # Implementation goes here
}
```

## Parameters

| Parameter | Type | Required | Validation | Description |
|-----------|------|----------|------------|-------------|
| `FilePath` | `[string]` | Yes | NotNullOrEmpty | Relative path to the conflicting file |
| `CurrentContent` | `[string]` | Yes | AllowEmptyString | User's current version (normalized) |
| `BaseContent` | `[string]` | Yes | AllowEmptyString | Original version from manifest (may be empty for v0.0.0) |
| `IncomingContent` | `[string]` | Yes | AllowEmptyString | New upstream version (normalized) |
| `OriginalVersion` | `[string]` | Yes | NotNullOrEmpty | Version identifier for base/current (e.g., "v0.0.71") |
| `NewVersion` | `[string]` | Yes | NotNullOrEmpty | Version identifier for incoming (e.g., "v0.0.72") |

## Return Value

**Type**: None (void)

**Side Effects**:
- For large files: Creates diff file in `.specify/.tmp-conflicts/[filename].diff.md`
- For small files: Writes Git conflict markers to `FilePath`
- Displays message to user via `Write-Host` indicating conflict and resolution method

## Behavior

### Decision Logic

```
Count lines in CurrentContent
    ↓
If line count ≤ 100:
    Call Write-ConflictMarkers (existing function)
    Display: "Conflict detected in: [FilePath] (using Git markers)"
    Return
    ↓
If line count > 100:
    Call Compare-FileSections to analyze differences
    Call Write-SideBySideDiff to generate diff file
    Display: "Large file conflict detected in: [FilePath]"
    Display: "Review detailed diff: .specify/.tmp-conflicts/[filename].diff.md"
    Return
```

### Error Handling

```
Try:
    Detect file size
    If large file:
        Generate diff
Catch any exception:
    Log warning: "Diff generation failed: [error message]"
    Fall back to Write-ConflictMarkers
    Display: "Using standard Git conflict markers"
```

**Rationale**: User must not lose conflict information due to diff generation failure. Git markers are proven fallback.

## Dependencies

- `Write-ConflictMarkers` (existing function in ConflictDetector.psm1)
- `Compare-FileSections` (new function, defined in this spec)
- `Write-SideBySideDiff` (new function, defined in this spec)
- PowerShell built-in: `-split` operator for counting lines

## Testing Requirements

### Unit Tests

1. **Test: Small file uses Git markers**
   - Input: 50-line file
   - Expected: `Write-ConflictMarkers` called, Git markers written to file

2. **Test: Large file generates diff**
   - Input: 200-line file
   - Expected: Diff file created in `.specify/.tmp-conflicts/`

3. **Test: Boundary condition (exactly 100 lines)**
   - Input: 100-line file
   - Expected: Git markers used (not "greater than 100")

4. **Test: Boundary condition (101 lines)**
   - Input: 101-line file
   - Expected: Diff file generated

5. **Test: Error fallback**
   - Input: Mock `Compare-FileSections` to throw exception
   - Expected: Warning logged, `Write-ConflictMarkers` called

6. **Test: Empty base version**
   - Input: `BaseContent = ""`
   - Expected: No error, base marked as empty in diff

### Integration Tests

1. **Test: End-to-end large file conflict**
   - Simulate update with 300-line template conflict
   - Verify diff file created with correct format

2. **Test: End-to-end small file conflict**
   - Simulate update with 50-line file conflict
   - Verify Git markers written to file

## Performance Criteria

- **Small files (≤100 lines)**: Same performance as existing `Write-ConflictMarkers` (<50ms)
- **Large files (>100 lines)**: Complete in <2 seconds for 1000-line files (per SC-002)

## Example Output

### Small File (Git Markers)

```
Conflict detected in: .claude/commands/custom-deploy.md (using Git markers)
```

File content:
```markdown
<<<<<<< Current (Your Version)
[current content]
||||||| Base (v0.0.71)
[base content]
=======
[incoming content]
>>>>>>> Incoming (v0.0.72)
```

### Large File (Smart Diff)

```
Large file conflict detected in: .specify/templates/tasks-template.md
Review detailed diff: .specify/.tmp-conflicts/tasks-template.diff.md
```

Diff file: `.specify/.tmp-conflicts/tasks-template.diff.md` (see `Write-SideBySideDiff.md` for format)

## Notes

- This function has the same signature as `Write-ConflictMarkers` for easy drop-in replacement
- The 100-line threshold is hardcoded (no configuration in MVP)
- Function is stateless (no module-level state)
- All parameters must be passed explicitly
- Verbose logging (`Write-Verbose`) should be used for debugging
