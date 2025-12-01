# Research: Smart Conflict Resolution for Large Files

**Phase**: 0 (Outline & Research)
**Date**: 2025-10-21
**Feature**: [spec.md](spec.md) | [plan.md](plan.md)

## Overview

This document consolidates research findings for implementing intelligent conflict resolution that generates side-by-side diff files for large template files instead of full Git conflict markers.

## Research Areas

### 1. PowerShell File Comparison Approaches

**Decision**: Use `Compare-Object` with manual grouping for consecutive changed lines

**Rationale**:
- `Compare-Object` is a built-in PowerShell cmdlet (no external dependencies)
- Supports line-by-line comparison with `-SyncWindow` parameter for context
- Returns objects with `SideIndicator` property (`<=` for left-only, `=>` for right-only, `==` for equal)
- Performance is acceptable for files up to 1000 lines (PowerShell 7.x optimizations)
- Can be enhanced with custom grouping logic to create diff sections

**Alternatives Considered**:
- **Git diff command via CLI**: Rejected - adds Git dependency, parsing CLI output is fragile, and may not be available in all environments
- **Manual line-by-line comparison with loops**: Rejected - reinvents the wheel, slower than optimized `Compare-Object`, harder to maintain
- **External diff libraries (Python difflib, GNU diff)**: Rejected - violates single-language constraint, adds installation complexity

**Implementation Pattern**:
```powershell
$currentLines = $CurrentContent -split "`n"
$incomingLines = $IncomingContent -split "`n"

$comparison = Compare-Object -ReferenceObject $currentLines `
                             -DifferenceObject $incomingLines `
                             -IncludeEqual `
                             -SyncWindow 5

# Group consecutive changed lines into sections
# Process comparison results to identify start/end line numbers
```

### 2. Diff Section Grouping Algorithm

**Decision**: Implement custom grouping logic to merge consecutive changed lines into logical sections

**Rationale**:
- `Compare-Object` returns individual line differences, not grouped sections
- Users need to see contextual blocks (e.g., "lines 54-62 changed") not individual line changes
- Grouping consecutive changes improves readability and reduces section count
- Adding 3 lines of context before/after each section provides readability without bloat

**Algorithm**:
1. Iterate through `Compare-Object` results
2. Track current section start/end line numbers
3. If current line difference is within threshold (e.g., 3 lines) of previous difference, extend current section
4. If gap exceeds threshold, finalize current section and start new section
5. Add context lines (3 before/after) to each section
6. Handle edge cases (start of file, end of file, overlapping sections)

**Example Output**:
```
Section 1: Lines 11-18 (Current) vs Lines 11-14 (Incoming)
Section 2: Lines 54-62 (Current) vs Lines 48-58 (Incoming)
Section 3: Lines 203-207 (Current) vs Lines 197-203 (Incoming)
```

### 3. Markdown Diff Format Design

**Decision**: Use fenced code blocks with language hints for syntax highlighting, clear section headers, and horizontal rules for separation

**Rationale**:
- VSCode Markdown preview supports fenced code blocks with syntax highlighting
- Triple backticks (` ``` `) with language hint (` ```markdown `) enable syntax coloring
- Horizontal rules (`---`) provide clear visual separation between sections
- Consistent heading hierarchy (h2 for sections, h3 for subsections) improves navigation
- Markdown tables are readable in plain text and render beautifully in preview

**Format Structure**:
```markdown
# Conflict Resolution: [filename]

**Your Version**: v0.0.71
**Incoming Version**: v0.0.72
**File Path**: `.specify/templates/tasks-template.md`

## Changed Section 1 (Lines 11-14)

### Your Version (Lines 11-14)

```markdown
[current version content with context]
```

### Incoming Version (Lines 11-14)

```markdown
[incoming version content with context]
```

---

## Changed Section 2 (Lines 54-56)

[repeat pattern]

---

## Unchanged Sections

The following sections are identical in both versions:
- Lines 1-10: Header and frontmatter
- Lines 15-53: Format conventions
- Lines 57-200: Task examples
```

**Benefits**:
- Renders correctly in VSCode preview, GitHub Markdown, and Claude Code chat
- Plain text readable (no HTML/CSS required)
- Syntax highlighting for code sections (if language hint provided)
- Easy to search (Ctrl+F for section numbers)

### 4. Performance Optimization for Large Files

**Decision**: Use streaming comparison with lazy evaluation, avoid loading entire file into single string

**Rationale**:
- PowerShell arrays are efficient for line-by-line operations
- `-split "`n"` creates array once, `Compare-Object` streams through it
- Avoid string concatenation in loops (use `StringBuilder` or array join)
- Limit diff output to changed sections only (don't write unchanged content)

**Performance Targets** (from Success Criteria SC-002):
- Files up to 1000 lines: < 2 seconds
- Typical template file (200-500 lines): < 500ms

**Optimization Techniques**:
- Pre-allocate arrays with known sizes where possible
- Use `[System.Collections.ArrayList]` for dynamic section collection
- Avoid nested loops where possible (linear passes over comparison results)
- Write diff file incrementally (use `StreamWriter` instead of concatenating entire content)

**Benchmark Approach** (for validation):
```powershell
Measure-Command {
    Write-SmartConflictResolution -FilePath "test-1000-lines.md" `
                                   -CurrentContent $current `
                                   -IncomingContent $incoming `
                                   -BaseContent $base `
                                   -OriginalVersion "v1" `
                                   -NewVersion "v2"
}
```

### 5. Error Handling and Fallback Strategy

**Decision**: Implement graceful fallback to Git conflict markers on any diff generation error

**Rationale**:
- User must not lose conflict information due to diff generation failure
- Git conflict markers are the proven fallback (already working in production)
- Failures should be logged with detailed error context but not block the update
- Constitution Principle II (Fail-Fast with Rollback) applies to critical failures only; diff generation is not critical

**Error Scenarios and Handling**:

| Error Scenario | Handling Strategy | User Impact |
|----------------|-------------------|-------------|
| `Compare-Object` throws exception | Catch, log warning, fall back to Git markers | See standard markers, process continues |
| Permission error writing diff file | Catch, log warning, fall back to Git markers | See standard markers, process continues |
| `.specify/.tmp-conflicts/` creation fails | Catch, log warning, fall back to Git markers | See standard markers, process continues |
| Out of memory (huge file) | Catch, log warning, fall back to Git markers | See standard markers, process continues |
| Diff file corruption during write | Partial file written; cleanup on next update | Minor - temp file, cleaned on next run |
| Cleanup failure | Log warning, continue update | Temp files remain (manual cleanup) |

**Implementation Pattern**:
```powershell
function Write-SmartConflictResolution {
    try {
        # Attempt smart diff generation
        if ($currentLines.Count -gt 100) {
            # Generate diff
        }
    }
    catch {
        Write-Warning "Diff generation failed: $($_.Exception.Message)"
        Write-Verbose "Falling back to Git conflict markers"
        Write-ConflictMarkers @PSBoundParameters
    }
}
```

### 6. Unchanged Section Detection

**Decision**: Use inverse of `Compare-Object` results to identify unchanged line ranges

**Rationale**:
- `Compare-Object -IncludeEqual` returns all lines with `SideIndicator` of `==` for equal lines
- Group consecutive equal lines into ranges
- No need for separate comparison pass (reuse existing comparison results)

**Algorithm**:
1. Filter `Compare-Object` results for `SideIndicator -eq "=="`
2. Group consecutive equal lines into ranges
3. Format as "Lines X-Y: [description]"
4. Description can be inferred from content (e.g., "Header and frontmatter" for lines 1-10)

**Output Format**:
```markdown
## Unchanged Sections

The following sections are identical in both versions:
- Lines 1-10 (10 lines)
- Lines 15-53 (39 lines)
- Lines 64-200 (137 lines)
```

## Technology Stack Summary

| Component | Technology | Version | Justification |
|-----------|------------|---------|---------------|
| Core Language | PowerShell | 7.x | Existing codebase standard, cross-platform |
| File Comparison | Compare-Object cmdlet | Built-in | No dependencies, sufficient performance |
| String Manipulation | PowerShell operators | Built-in | -split, -join, -replace for text processing |
| File I/O | Get-Content, Set-Content, StreamWriter | Built-in | Standard PowerShell file operations |
| Testing | Pester | 5.x | Existing test framework |
| Output Format | Markdown | CommonMark | VSCode native support, readable plain text |

## Open Questions Resolved

**Q1**: Should we use PowerShell `Compare-Object` or invoke Git diff?
**A1**: Use `Compare-Object` - no Git dependency, easier to parse results, sufficient performance.

**Q2**: What threshold should trigger smart diff vs. Git markers?
**A2**: 100 lines (per spec FR-002) - balances usability (typical viewport is 40-60 lines) with performance.

**Q3**: Should we implement change percentage filter in addition to line count?
**A3**: No (deferred to future) - adds complexity without clear benefit per spec Out of Scope section. File size is primary criterion.

**Q4**: How to handle empty base version (v0.0.0 scenario)?
**A4**: Skip base comparison, only compare current vs incoming. Mark base as "empty" in diff header.

**Q5**: Should diff files include action checkboxes or resolution options?
**A5**: No - text-only I/O constraint means no interactive elements. Diff is informational; user resolves in editor.

## Best Practices Identified

### PowerShell Module Development

1. **Parameter Validation**: Use `[Parameter(Mandatory)]` and type annotations for all function parameters
2. **Comment-Based Help**: All exported functions MUST have `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`
3. **Verbose Logging**: Use `Write-Verbose` for debugging (user can enable with `-Verbose`)
4. **Error Context**: Include file path and operation in error messages
5. **Export Functions**: Explicitly export functions with `Export-ModuleMember -Function`

### Diff Generation

1. **Normalize Input**: Use normalized content from `HashUtils` module (CRLF/LF handling)
2. **Context Lines**: Include 3 lines before/after each changed section for readability
3. **Line Number Accuracy**: Track original line numbers (don't renumber after context addition)
4. **UTF-8 Encoding**: Use UTF-8 without BOM for cross-platform compatibility
5. **Markdown Escaping**: Escape special characters in content (backticks, brackets) to avoid rendering issues

### Testing Strategy

1. **Boundary Testing**: Test exactly 100 lines, 101 lines, 99 lines
2. **Edge Cases**: Empty files, single-line files, identical files, completely different files
3. **Error Injection**: Mock file system failures, permission errors, out-of-memory
4. **Performance Validation**: Benchmark with 1000-line files, verify < 2 second target
5. **Markdown Validation**: Ensure output renders correctly in VSCode preview

## Implementation Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Performance degradation for large files | High | Low | Benchmark with 1000-line files; optimize if needed |
| Markdown rendering issues in different viewers | Medium | Low | Use standard CommonMark syntax; test in VSCode |
| False positive change detection | High | Very Low | Reuse existing normalized hashing from HashUtils |
| Diff file encoding issues | Medium | Low | Force UTF-8 without BOM; test on Windows/Mac/Linux |
| Cleanup failures leave temp files | Low | Medium | Log warning, document manual cleanup; non-critical |

## Next Steps

- [x] Phase 0 complete: Research findings documented
- [ ] Phase 1: Generate data-model.md (define diff section data structure)
- [ ] Phase 1: Generate function contracts (signatures, parameters, return types)
- [ ] Phase 1: Generate quickstart.md (developer onboarding guide)
- [ ] Phase 1: Update agent context (Claude Code integration)
- [ ] Phase 2: Generate tasks.md (implementation task breakdown)
