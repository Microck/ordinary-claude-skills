# Data Model: Conflict Markers & Summary Output

**Feature**: 007-remove-quickpick-integration
**Date**: 2025-10-21
**Phase**: 1 (Design & Contracts)

## Overview

This document defines the structure of:
1. Git-style conflict markers written to files
2. Summary output Markdown structure
3. Internal data structures for conflict representation

## Git Conflict Marker Format

### Standard Format

Git conflict markers follow this structure:

```
<<<<<<< Current (Your Version)
[content from current/local file]
||||||| Base (v0.0.71)
[content from base/original version]
=======
[content from incoming/upstream version]
>>>>>>> Incoming (v0.0.72)
```

### Components

| Marker | Purpose | Label Format |
|--------|---------|--------------|
| `<<<<<<<` | Start of conflict; introduces current version | `<<<<<<< Current (Your Version)` |
| `\|\|\|\|\|\|\|` | Separator for base version (optional, 3-way merge) | `\|\|\|\|\|\|\| Base ({originalVersion})` |
| `=======` | Separator between versions | `=======` (no label) |
| `>>>>>>>` | End of conflict; introduces incoming version | `>>>>>>> Incoming ({newVersion})` |

### Example: Template Conflict

**Scenario**: User customized `.claude/commands/speckit.plan.md` to add a custom section. Upstream v0.0.72 adds a new architecture validation step.

**File**: `.claude/commands/speckit.plan.md`

```markdown
# Implementation Plan Template

## Summary
[standard content]

## Technical Context
[standard content]

<<<<<<< Current (Your Version)
## Custom Tech Stack Review
- Database choice: PostgreSQL vs MongoDB
- Frontend framework: React vs Vue
||||||| Base (v0.0.71)
[this section did not exist in base]
=======
## Architecture Validation
- Review against SOLID principles
- Identify coupling points
- Document design decisions
>>>>>>> Incoming (v0.0.72)

## Constitution Check
[standard content continues...]
```

### Writing Algorithm

```powershell
function Write-ConflictMarkers {
    param(
        [string]$FilePath,           # Target file to write markers to
        [string]$CurrentContent,     # User's local version
        [string]$BaseContent,        # Original version from manifest
        [string]$IncomingContent,    # New upstream version
        [string]$OriginalVersion,    # e.g., "v0.0.71"
        [string]$NewVersion          # e.g., "v0.0.72"
    )

    # Construct conflict marker block
    $conflictBlock = @"
<<<<<<< Current (Your Version)
$CurrentContent
||||||| Base ($OriginalVersion)
$BaseContent
=======
$IncomingContent
>>>>>>> Incoming ($NewVersion)
"@

    # Write to file
    Set-Content -Path $FilePath -Value $conflictBlock -Encoding UTF8
}
```

### Validation Rules

- **Marker alignment**: All markers must start at column 1 (no leading whitespace)
- **Label format**: Use exact format shown above for VSCode recognition
- **Content preservation**: Content sections MUST NOT contain conflict markers themselves (escape if present)
- **UTF-8 encoding**: Always write with UTF-8 encoding (BOM optional but consistent)
- **Line ending normalization**: Use CRLF on Windows, LF on Unix (match file's original line ending style)

---

## Summary Output Structure

### Markdown Schema

```markdown
## SpecKit Update Summary

**Current Version**: {currentVersion}
**Available Version**: {availableVersion}

### Files to Update ({count})
- {relativePath1}
- {relativePath2}
[...]

### Files to Add ({count})
- {newFilePath1}
[...]

### Files to Remove ({count})
- {removedFilePath1}
[...]

### Conflicts Detected ({count})
- {conflictedFilePath1}
  * Local: {userChangeSummary}
  * Upstream: {upstreamChangeSummary}
[...]

### Files Preserved (Customized) ({count})
- {preservedFilePath1}
[...]

### Backup Location
{backupPath}

### Custom Commands ({count})
- {customCommandPath1}
[...]

---
[PROMPT_FOR_APPROVAL]
```

### Field Definitions

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `currentVersion` | string | Installed SpecKit version from manifest | `v0.0.71` |
| `availableVersion` | string | Target version to update to | `v0.0.72` |
| `count` | integer | Number of items in category | `5` |
| `relativePath` | string | Path relative to project root | `.claude/commands/speckit.tasks.md` |
| `userChangeSummary` | string | Brief description of local modifications | `Added custom deployment steps` |
| `upstreamChangeSummary` | string | Brief description of upstream changes | `New dependency tracking section` |
| `backupPath` | string | Relative path to backup directory | `.specify/backups/2025-10-21_14-22-10/` |

### Example Output

```markdown
## SpecKit Update Summary

**Current Version**: v0.0.71
**Available Version**: v0.0.72

### Files to Update (3)
- .claude/commands/speckit.tasks.md
- .specify/templates/spec-template.md
- .specify/scripts/powershell/create-new-feature.ps1

### Conflicts Detected (1)
- .claude/commands/speckit.plan.md
  * Local: Added custom tech stack review section
  * Upstream: New architecture validation step added

### Files Preserved (Customized) (2)
- .specify/memory/constitution.md
- .claude/commands/custom-deploy.md

### Backup Location
.specify/backups/2025-10-21_14-22-10/

### Custom Commands (1)
- .claude/commands/custom-deploy.md

---
[PROMPT_FOR_APPROVAL]
```

---

## Internal Data Structures

### FileConflict Object

Represents a file with merge conflict:

```powershell
@{
    Path = ".claude/commands/speckit.plan.md"
    FileName = "speckit.plan.md"
    CurrentContent = "[user's local version content]"
    BaseContent = "[original manifest version content]"
    IncomingContent = "[new upstream version content]"
    CurrentHash = "sha256:abc123..."
    BaseHash = "sha256:def456..."
    IncomingHash = "sha256:ghi789..."
    OriginalVersion = "v0.0.71"
    NewVersion = "v0.0.72"
    UserChangeSummary = "Added custom tech stack review section"
    UpstreamChangeSummary = "New architecture validation step added"
}
```

### UpdateSummary Object

Represents complete update analysis:

```powershell
@{
    CurrentVersion = "v0.0.71"
    AvailableVersion = "v0.0.72"
    FilesToUpdate = @(
        ".claude/commands/speckit.tasks.md",
        ".specify/templates/spec-template.md"
    )
    FilesToAdd = @()
    FilesToRemove = @()
    Conflicts = @(
        [FileConflict object],
        [...]
    )
    FilesPreserved = @(
        ".specify/memory/constitution.md"
    )
    BackupPath = ".specify/backups/2025-10-21_14-22-10/"
    CustomCommands = @(
        ".claude/commands/custom-deploy.md"
    )
}
```

### Generation Function Signature

```powershell
function New-UpdateSummary {
    <#
    .SYNOPSIS
        Generates structured summary output for user approval.

    .PARAMETER UpdateSummary
        UpdateSummary object from conflict analysis.

    .OUTPUTS
        String. Markdown-formatted summary with [PROMPT_FOR_APPROVAL] marker.
    #>
    param(
        [Parameter(Mandatory)]
        [hashtable]$UpdateSummary
    )

    # Build Markdown sections
    $markdown = @"
## SpecKit Update Summary

**Current Version**: $($UpdateSummary.CurrentVersion)
**Available Version**: $($UpdateSummary.AvailableVersion)

"@

    # Add sections conditionally
    if ($UpdateSummary.FilesToUpdate.Count -gt 0) {
        $markdown += "### Files to Update ($($UpdateSummary.FilesToUpdate.Count))`n"
        foreach ($file in $UpdateSummary.FilesToUpdate) {
            $markdown += "- $file`n"
        }
        $markdown += "`n"
    }

    # [Additional sections...]

    $markdown += "---`n[PROMPT_FOR_APPROVAL]`n"

    return $markdown
}
```

---

## Constraints

### VSCode Conflict Detection

For VSCode to recognize conflict markers automatically:

1. **Marker format must be exact**: `<<<<<<<`, `|||||||`, `=======`, `>>>>>>>`
2. **Label format**: `<<<<<<< Current (descriptive text)` and `>>>>>>> Incoming (descriptive text)`
3. **Position**: Markers must start at column 1 (no indentation)
4. **File extension**: Must be text-based (`.md`, `.txt`, `.json`, `.ps1`, etc.)

### Performance Targets

- **Conflict marker write**: < 50ms per file (up to 100KB file size)
- **Summary generation**: < 500ms for up to 50 files analyzed
- **Memory usage**: < 10MB for conflict marker data structures

---

## Validation & Testing

### Test Cases

1. **Basic conflict marker write**:
   - Input: Current, Base, Incoming content
   - Expected: Valid Git marker format with all 4 sections

2. **VSCode recognition**:
   - Input: File with conflict markers
   - Expected: VSCode shows CodeLens conflict resolution UI

3. **Summary output formatting**:
   - Input: UpdateSummary with multiple file categories
   - Expected: Valid Markdown with all sections, [PROMPT_FOR_APPROVAL] marker

4. **Empty categories**:
   - Input: UpdateSummary with no conflicts
   - Expected: Summary omits "Conflicts Detected" section entirely

5. **Unicode content**:
   - Input: File content with emoji, non-ASCII characters
   - Expected: Conflict markers preserve Unicode correctly

### Edge Cases

- **Nested conflict markers**: If incoming content contains conflict marker syntax, escape it
- **Very large files**: Files > 1MB may cause VSCode performance issues; warn user
- **Binary files**: Never write conflict markers to binary files; error with clear message
- **Empty content sections**: Handle gracefully (empty string between markers is valid)
