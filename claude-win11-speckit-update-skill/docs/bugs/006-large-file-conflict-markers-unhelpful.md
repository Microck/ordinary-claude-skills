# Bug Report: Git Conflict Markers Unhelpful for Large Template Files

**Issue:** #16
**Status:** OPEN
**Reporter:** Bobby Johnson (@NotMyself)
**Created:** 2025-10-21T22:39:17Z
**Severity:** High (Critical usability issue affecting core value proposition)

## Summary

When large template files (500+ lines) have conflicts, the Git conflict markers are completely unhelpful for manual merging because they show two full copies of the file with no indication of what actually changed. Users cannot identify the specific lines that differ between versions, making it impossible to make informed decisions about which version to keep.

## Environment

- **OS:** Windows 11
- **PowerShell Version:** 7.x (pwsh.exe)
- **Skill Version:** v0.2.0
- **Execution Context:** SpecKit template updates via `/speckit-update` skill
- **Affected Component:** `scripts/modules/ConflictDetector.psm1` (`Write-ConflictMarkers` function)
- **Affected Files:** Large template files like `tasks-template.md` (543 lines)

## Example Problem

User upgraded SpecKit and found `tasks-template.md` (543 lines) with conflict markers:

```markdown
<<<<<<< Current (Your Version)
[287 lines of template]
||||||| Base (v0.0.0)

=======
[253 lines of template]
>>>>>>> Incoming (v0.0.74)
```

**Problem:** No way to see **what specific lines changed** between versions! The entire file is duplicated in the conflict markers with no indication of the actual differences.

## Root Cause

The conflict resolution system writes Git conflict markers in 3-way format:
- Current version (full file)
- Base version (from manifest - may be empty!)
- Incoming version (full file)

**File:** [ConflictDetector.psm1](../../scripts/modules/ConflictDetector.psm1)

This approach works fine for small files (10-50 lines) but becomes useless for large template files because:
1. Users see hundreds of lines repeated twice
2. No visual indication of which specific lines actually differ
3. Base version may be empty (v0.0.0) providing no context
4. Cannot scroll and compare effectively in the editor

## Impact

### User Experience: Frustrating and Error-Prone

- **Cannot identify actual differences** without external tools
- **Must manually diff externally** (defeats purpose of automated tool)
- **Easy to accept wrong version** due to inability to review changes
- **Defeats purpose of "safe" updates** - the core value proposition

### Severity Justification

**High** - This directly undermines the skill's primary value proposition of preserving user customizations while applying template updates. Users cannot make informed decisions about conflicts if they cannot see what changed.

### Affected Scenarios

1. **First-time install** (Issue #13) - All templates will trigger conflicts
2. **Template updates** - Most common conflict scenario
3. **Constitution updates** - Large files with significant changes
4. **Any file > 100 lines** with both local and upstream changes

## Better Solution Options

### Option 1: Show Side-by-Side Diff (Recommended)

Instead of conflict markers, create a **side-by-side diff file** showing only changed sections:

```markdown
# Conflict Resolution: tasks-template.md

## Changed Section 1 (Lines 11-14)

**Your Version**:
```
**Tests**: Tests are MANDATORY following Test-Driven Development (TDD)
methodology per Constitution Principle VIII. All tasks must follow
the Red-Green-Refactor cycle.
```

**Incoming Version**:
```
**Tests**: The examples below include test tasks. Tests are OPTIONAL -
only include them if explicitly requested in the feature specification.
```

**Action**: Which version do you want to keep?
- [ ] Keep your version (MANDATORY TDD)
- [ ] Use incoming version (OPTIONAL tests)
- [ ] Edit manually

---

## Changed Section 2 (Lines 54-56)

[Similar format]

---

## Unchanged Sections

The following sections are identical in both versions:
- Lines 1-10: Header and frontmatter
- Lines 15-53: Format and Path Conventions
- [etc.]
```

**Benefits**:
- ✅ Shows only what changed
- ✅ Clear side-by-side comparison
- ✅ Actionable choices
- ✅ Highlights unchanged sections (don't need review)
- ✅ Line numbers for context
- ✅ Valid markdown format

### Option 2: Smart Merge with Annotations

Write the incoming version with **inline comments** showing what changed:

```markdown
---
description: "Task list template for feature implementation"
---

# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`

<!-- CHANGED: Your version said "Tests are MANDATORY", incoming says "OPTIONAL" -->
<!-- YOUR VERSION: **Tests**: Tests are MANDATORY following TDD... -->
**Tests**: The examples below include test tasks. Tests are OPTIONAL - only include them if explicitly requested.
<!-- END CHANGE -->

[rest of file continues normally]
```

**Benefits**:
- ✅ Valid markdown (comments hidden when rendered)
- ✅ Shows changes inline
- ✅ Easy to search and find changes
- ✅ Can edit directly

**Drawbacks**:
- ❌ More verbose than Option 1
- ❌ Harder to see full context of changes
- ❌ Comments may clutter the file

### Option 3: External Diff Tool Integration

Open an external diff tool automatically:
- Windows: `code --diff` (VSCode), `Beyond Compare`, `WinMerge`
- Auto-detect installed diff tools
- Fall back to Option 1 if no tool found

**Benefits**:
- ✅ Professional diff UI
- ✅ Familiar to developers
- ✅ Visual line-by-line comparison
- ✅ Syntax highlighting

**Drawbacks**:
- ❌ Requires external tool
- ❌ Breaks Claude Code workflow (subprocess invocation issues)
- ❌ Not text-only (conflicts with architectural constraints)
- ❌ May not work reliably (see bug #005)

## Recommended Approach

**Hybrid Solution - Smart Conflict Detection:**

1. **Detect conflict size**: If file > 100 lines AND changes > 20% of file:
   - Use **Option 1** (side-by-side diff showing only changed sections)
   - Write to `.specify/.tmp-conflicts/[filename].diff.md`
   - Show message: "Large file conflict - review: `.specify/.tmp-conflicts/tasks-template.diff.md`"

2. **For small conflicts** (< 100 lines or < 20% changed):
   - Keep current Git markers approach (works fine for small files)

3. **Optional**: If VSCode detected, also offer:
   - `code --diff .specify/.tmp-conflicts/tasks-template.current.md .specify/.tmp-conflicts/tasks-template.incoming.md`
   - But don't rely on it (architectural limitation - see bug #005)

### Rationale

- Provides appropriate resolution strategy based on file size
- Maintains backward compatibility for small files
- Addresses the specific pain point without over-engineering
- Text-based output respects architectural constraints
- Actionable and informative for users

## Implementation Plan

### New Function: `Write-SmartConflictResolution`

**Location:** `scripts/modules/ConflictDetector.psm1`

```powershell
function Write-SmartConflictResolution {
    <#
    .SYNOPSIS
        Writes conflict resolution based on file size (smart vs. standard markers)

    .DESCRIPTION
        For large files (>100 lines), generates side-by-side diff showing only
        changed sections. For small files, uses standard Git conflict markers.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string]$CurrentContent,

        [Parameter(Mandatory)]
        [string]$BaseContent,

        [Parameter(Mandatory)]
        [string]$IncomingContent,

        [Parameter(Mandatory)]
        [string]$OriginalVersion,

        [Parameter(Mandatory)]
        [string]$NewVersion
    )

    # Calculate file size and change percentage
    $currentLines = $CurrentContent -split "`n"
    $incomingLines = $IncomingContent -split "`n"

    if ($currentLines.Count -gt 100) {
        # Large file - use diff-based resolution
        Write-Verbose "Large file detected ($($currentLines.Count) lines) - generating smart diff"

        $diffSections = Compare-FileSections -Current $CurrentContent -Incoming $IncomingContent

        Write-SideBySideDiff -FilePath $FilePath `
                              -Sections $diffSections `
                              -OriginalVersion $OriginalVersion `
                              -NewVersion $NewVersion

        Write-Host "⚠️  Large file conflict detected in: $FilePath"
        Write-Host "📋 Review detailed diff: .specify/.tmp-conflicts/$(Split-Path $FilePath -Leaf).diff.md"
    }
    else {
        # Small file - use Git markers
        Write-Verbose "Small file detected ($($currentLines.Count) lines) - using Git conflict markers"
        Write-ConflictMarkers @PSBoundParameters
    }
}
```

### Helper Function: `Compare-FileSections`

Finds actual differences between files:

```powershell
function Compare-FileSections {
    <#
    .SYNOPSIS
        Compares two file contents and returns changed sections with line numbers
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Current,

        [Parameter(Mandatory)]
        [string]$Incoming
    )

    # Use PowerShell's Compare-Object to find differences
    $currentLines = $Current -split "`n"
    $incomingLines = $Incoming -split "`n"

    # Compare and group into sections
    # Return array of changed sections with line numbers and context

    # Implementation details:
    # 1. Use Compare-Object with -SyncWindow to find differences
    # 2. Group consecutive changed lines into sections
    # 3. Add context lines (3 before/after) for readability
    # 4. Return structured object with start/end line numbers
}
```

### Helper Function: `Write-SideBySideDiff`

Generates readable diff file:

```powershell
function Write-SideBySideDiff {
    <#
    .SYNOPSIS
        Generates markdown diff file showing only changed sections
    #>
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [array]$Sections,

        [Parameter(Mandatory)]
        [string]$OriginalVersion,

        [Parameter(Mandatory)]
        [string]$NewVersion
    )

    # Generate markdown diff showing only changed sections
    # Include action checkboxes for user decisions
    # Write to .specify/.tmp-conflicts/[filename].diff.md

    # Format:
    # 1. Header with file info and instructions
    # 2. Each changed section with line numbers
    # 3. Side-by-side comparison
    # 4. Action options (checkboxes if feasible)
    # 5. List of unchanged sections
}
```

## Files Requiring Changes

### Code Modifications

1. **scripts/modules/ConflictDetector.psm1**
   - Add `Write-SmartConflictResolution` function
   - Add `Compare-FileSections` helper function
   - Add `Write-SideBySideDiff` helper function
   - Update `Export-ModuleMember` to export new functions
   - Modify existing conflict detection logic to call smart resolution

2. **scripts/update-orchestrator.ps1**
   - Update conflict handling to call `Write-SmartConflictResolution` instead of `Write-ConflictMarkers`
   - Add cleanup for `.specify/.tmp-conflicts/` directory after resolution

3. **scripts/helpers/Invoke-ConflictResolutionWorkflow.ps1**
   - Update to handle both conflict marker files and diff files
   - Provide guidance for reviewing diff files

### Documentation Updates

1. **CLAUDE.md**
   - Update "Git Conflict Markers" section to describe smart conflict resolution
   - Add examples of side-by-side diff output
   - Document when each resolution method is used

2. **README.md**
   - Update conflict resolution section
   - Add screenshots/examples if applicable

3. **CHANGELOG.md**
   - Add entry for enhanced conflict resolution feature

### Testing

1. **tests/unit/ConflictDetector.Tests.ps1**
   - Add tests for `Write-SmartConflictResolution`
   - Add tests for `Compare-FileSections`
   - Add tests for `Write-SideBySideDiff`
   - Test threshold logic (100-line boundary)
   - Test change percentage calculation

2. **tests/integration/UpdateOrchestrator.Tests.ps1**
   - Add test: Small file uses Git markers
   - Add test: Large file generates diff file
   - Add test: Diff file format is valid markdown
   - Add test: Cleanup of tmp-conflicts directory

## Testing Plan

### Test Cases

```powershell
# Test 1: Small file uses Git markers
Write-SmartConflictResolution -FilePath "small-file.md" `
                               -CurrentContent (10 lines) `
                               -IncomingContent (12 lines) `
                               -BaseContent (10 lines) `
                               -OriginalVersion "v0.0.71" `
                               -NewVersion "v0.0.72"
# Expected: Git conflict markers in small-file.md

# Test 2: Large file generates diff
Write-SmartConflictResolution -FilePath "tasks-template.md" `
                               -CurrentContent (287 lines) `
                               -IncomingContent (253 lines) `
                               -BaseContent (243 lines) `
                               -OriginalVersion "v0.0.71" `
                               -NewVersion "v0.0.72"
# Expected: .specify/.tmp-conflicts/tasks-template.diff.md created
# Expected: Message displayed with path to diff file

# Test 3: Diff file shows only changed sections
$diffContent = Get-Content ".specify/.tmp-conflicts/tasks-template.diff.md" -Raw
# Verify: Contains "Changed Section 1", "Changed Section 2", etc.
# Verify: Contains "Unchanged Sections" list
# Verify: Contains line numbers
# Verify: Valid markdown format

# Test 4: Boundary condition (exactly 100 lines)
Write-SmartConflictResolution -FilePath "boundary-file.md" `
                               -CurrentContent (100 lines) `
                               -IncomingContent (100 lines)
# Expected: Uses Git markers (not "greater than 100")

# Test 5: Boundary condition (101 lines)
Write-SmartConflictResolution -FilePath "boundary-file.md" `
                               -CurrentContent (101 lines) `
                               -IncomingContent (101 lines)
# Expected: Generates diff file
```

### Success Criteria

- ✅ Detect file size and trigger appropriate resolution method
- ✅ For large files: Generate side-by-side diff showing only changes
- ✅ For small files: Keep current Git markers approach
- ✅ Diff file is valid markdown with clear formatting
- ✅ Shows line numbers for context
- ✅ Lists unchanged sections without full detail
- ✅ Provides clear instructions to user
- ✅ Cleans up temp diff files after resolution
- ✅ Updates documentation
- ✅ All tests pass

## Related Issues

- **Issue #13** - First-time install (will encounter this with all templates)
- **Issue #5** - VSCode Quick Pick limitation (Option 3 external diff tool affected)
- **v0.2.0** - Implemented Git conflict markers (works for small files)

## Related Documentation

- [ConflictDetector Module](../../scripts/modules/ConflictDetector.psm1)
- [Update Orchestrator](../../scripts/update-orchestrator.ps1)
- [Conflict Resolution Workflow](../../scripts/helpers/Invoke-ConflictResolutionWorkflow.ps1)
- [Project Instructions - Git Conflict Markers](../../CLAUDE.md#git-conflict-markers)
- [Specification](../../specs/001-safe-update/spec.md)

## Timeline

- **2025-10-21:** Issue created and documented as bug #007
- **Status:** Awaiting implementation

## Priority

**High** - This is a critical usability issue that makes conflict resolution painful for template files, which is the most common conflict scenario in SpecKit updates. It directly undermines the "safe updates" value proposition.

## User Impact

### Before Fix

User gets 543 lines of conflict markers showing full file duplicated:
- Cannot see what changed
- Must use external diff tool manually
- Frustrated and confused
- May accept wrong version blindly
- Bad experience

### After Fix

User gets clean diff showing 5-10 actual changed sections:
- Can see exactly what changed
- Can make informed decisions
- Clear side-by-side comparison
- Line numbers for context
- Professional experience

**This directly supports the "safe updates" value proposition!**

## Notes

### Design Considerations

1. **100-line threshold** is a reasonable heuristic based on:
   - Typical editor viewport (40-60 lines visible)
   - Ability to scroll and compare manually
   - Not too aggressive (avoids unnecessary diff generation for medium files)

2. **20% change threshold** could be added as secondary filter:
   - Only generate diff if both file is large AND significant changes
   - Avoids diff generation for large files with trivial changes
   - Implementation complexity may not justify benefit

3. **Diff format** should be optimized for:
   - Readability in markdown viewers
   - VSCode preview rendering
   - Claude Code chat display
   - Terminal text output

4. **Cleanup timing** considerations:
   - Keep diff files until all conflicts resolved
   - Clean up at end of successful update
   - Keep on rollback (for debugging)
   - Add to `.gitignore` if not already

### Future Enhancements

- [ ] Add configurable threshold (environment variable or config file)
- [ ] Syntax highlighting for different file types in diff
- [ ] Interactive resolution wizard (if architectural limitations resolved)
- [ ] HTML diff viewer (if browser integration feasible)
- [ ] Integration with `code --diff` when safe (requires testing)
