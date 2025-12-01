# Quickstart: Smart Conflict Resolution Implementation

**Phase**: 1 (Design & Contracts)
**Date**: 2025-10-21
**Audience**: Developers implementing this feature
**Feature**: [spec.md](spec.md) | [plan.md](plan.md)

## Overview

This guide helps you implement the smart conflict resolution feature that generates side-by-side diff files for large template conflicts instead of full Git conflict markers.

**Goal**: Replace Git conflict markers for large files (>100 lines) with a structured Markdown diff showing only changed sections.

**Impact**: Improves user experience when resolving conflicts in 500+ line template files where full conflict markers are unhelpful.

## Prerequisites

- **Codebase**: Clone `claude-win11-speckit-update-skill` repository
- **Environment**: Windows 11 with PowerShell 7.x (pwsh.exe)
- **Branch**: Feature branch `008-smart-conflict-resolution` (already created)
- **Knowledge**: Familiarity with PowerShell modules, Pester testing, Git workflows

**Read These First**:
1. [CLAUDE.md](../../../CLAUDE.md) - Repository architecture and module patterns
2. [Constitution](../../../.specify/memory/constitution.md) - Core principles and constraints
3. [Feature Spec](spec.md) - User stories and requirements
4. [Implementation Plan](plan.md) - Technical approach and design decisions

## Architecture Quick Reference

### Module Organization

```
ConflictDetector.psm1 (MODIFY)
├── [Existing] Write-ConflictMarkers          # Git 3-way conflict markers
├── [Existing] Invoke-FileStateAnalysis       # Categorize files (add/update/merge)
├── [NEW] Write-SmartConflictResolution       # Entry point - size detection + routing
├── [NEW] Compare-FileSections                 # Line-by-line comparison + grouping
└── [NEW] Write-SideBySideDiff                 # Markdown diff file generation
```

### Data Flow

```
update-orchestrator.ps1
    ↓
ConflictDetector.Invoke-FileStateAnalysis
    ↓
File categorized as "merge" (conflict)
    ↓
Write-SmartConflictResolution (NEW - replaces Write-ConflictMarkers)
    ↓
Detect file size (count lines)
    ↓
    ├─ If ≤100 lines → Write-ConflictMarkers (existing)
    └─ If >100 lines → Compare-FileSections → Write-SideBySideDiff
                            ↓
                      .specify/.tmp-conflicts/[filename].diff.md
```

## Implementation Steps

### Step 1: Set Up Development Environment

```powershell
# Navigate to repository
cd $env:USERPROFILE\src\claude-Win11-SpecKit-Safe-Update-Skill

# Ensure you're on the feature branch
git branch  # Should show: * 008-smart-conflict-resolution

# Import modules for testing
Import-Module .\scripts\modules\ConflictDetector.psm1 -Force
Import-Module .\scripts\modules\HashUtils.psm1 -Force

# Run existing tests to establish baseline
.\tests\test-runner.ps1 -Unit
```

**Expected**: All existing tests should pass (132 passing, 45 known failures in Pester scoping).

### Step 2: Implement Compare-FileSections Function

**File**: `scripts/modules/ConflictDetector.psm1`

**Location**: Add after existing functions, before `Export-ModuleMember`

**Contract**: See [contracts/Compare-FileSections.md](contracts/Compare-FileSections.md)

**Implementation Checklist**:
- [  ] Add function signature with `[CmdletBinding()]` and parameters
- [  ] Add comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`)
- [ ] Split content into line arrays using `-split "`n"`
- [  ] Call `Compare-Object -IncludeEqual -SyncWindow 5`
- [  ] Implement grouping logic for consecutive changed lines
- [  ] Add context lines (3 before/after each section)
- [  ] Build `DiffSection` hashtables with line numbers
- [  ] Identify `UnchangedRange` sections
- [  ] Return `ComparisonResult` hashtable
- [  ] Add `Write-Verbose` logging for debugging

**Key Code Pattern**:
```powershell
$currentLines = $CurrentContent -split "`n"
$incomingLines = $IncomingContent -split "`n"

$comparison = Compare-Object -ReferenceObject $currentLines `
                             -DifferenceObject $incomingLines `
                             -IncludeEqual `
                             -SyncWindow 5

# Group consecutive changes into sections
# (See research.md for detailed algorithm)
```

### Step 3: Implement Write-SideBySideDiff Function

**File**: `scripts/modules/ConflictDetector.psm1`

**Contract**: See [contracts/Write-SideBySideDiff.md](contracts/Write-SideBySideDiff.md)

**Implementation Checklist**:
- [  ] Add function signature with parameters
- [  ] Add comment-based help
- [  ] Create `.specify/.tmp-conflicts/` directory if not exists
- [  ] Extract filename from FilePath
- [  ] Detect language hint from file extension
- [  ] Build Markdown content (header, sections, footer)
- [  ] Write file with UTF-8 encoding (no BOM)
- [  ] Display message to user with file path
- [  ] Add error handling with graceful fallback

**Key Code Pattern**:
```powershell
# Create directory if needed
if (-not (Test-Path $TmpConflictsDir)) {
    New-Item -ItemType Directory -Path $TmpConflictsDir -Force | Out-Null
}

# Build diff content
$diffContent = @"
# Conflict Resolution: $fileName

**Your Version**: $OriginalVersion
**Incoming Version**: $NewVersion
...
"@

# Write file (UTF-8, no BOM)
[System.IO.File]::WriteAllText($diffFilePath, $diffContent, [System.Text.UTF8Encoding]::new($false))

# Notify user
Write-Host "📋 Review detailed diff: $diffFilePath" -ForegroundColor Cyan
```

### Step 4: Implement Write-SmartConflictResolution Function

**File**: `scripts/modules/ConflictDetector.psm1`

**Contract**: See [contracts/Write-SmartConflictResolution.md](contracts/Write-SmartConflictResolution.md)

**Implementation Checklist**:
- [  ] Add function signature (same as Write-ConflictMarkers)
- [  ] Add comment-based help
- [  ] Count lines in CurrentContent
- [  ] If ≤100 lines, call Write-ConflictMarkers and return
- [  ] If >100 lines, call Compare-FileSections
- [  ] Pass result to Write-SideBySideDiff
- [  ] Wrap in try-catch with fallback to Write-ConflictMarkers
- [  ] Display appropriate messages to user

**Key Code Pattern**:
```powershell
try {
    $currentLines = $CurrentContent -split "`n"

    if ($currentLines.Count -le 100) {
        Write-Verbose "Small file ($($currentLines.Count) lines) - using Git markers"
        Write-ConflictMarkers @PSBoundParameters
        return
    }

    Write-Verbose "Large file ($($currentLines.Count) lines) - generating smart diff"
    $comparisonResult = Compare-FileSections -CurrentContent $CurrentContent `
                                              -IncomingContent $IncomingContent

    Write-SideBySideDiff -FilePath $FilePath `
                         -ComparisonResult $comparisonResult `
                         -OriginalVersion $OriginalVersion `
                         -NewVersion $NewVersion
}
catch {
    Write-Warning "Diff generation failed: $($_.Exception.Message)"
    Write-Verbose "Falling back to Git conflict markers"
    Write-ConflictMarkers @PSBoundParameters
}
```

### Step 5: Update Module Exports

**File**: `scripts/modules/ConflictDetector.psm1`

**Location**: At end of file

**Current Export**:
```powershell
Export-ModuleMember -Function Write-ConflictMarkers, Invoke-FileStateAnalysis
```

**Updated Export**:
```powershell
Export-ModuleMember -Function Write-ConflictMarkers, Invoke-FileStateAnalysis, `
                              Write-SmartConflictResolution, Compare-FileSections, `
                              Write-SideBySideDiff
```

### Step 6: Update Orchestrator to Use Smart Resolution

**File**: `scripts/update-orchestrator.ps1`

**Find**: Calls to `Write-ConflictMarkers`

**Replace**: With `Write-SmartConflictResolution`

**Example**:
```powershell
# Before
Write-ConflictMarkers -FilePath $file.Path `
                      -CurrentContent $currentContent `
                      -BaseContent $baseContent `
                      -IncomingContent $incomingContent `
                      -OriginalVersion $manifestVersion `
                      -NewVersion $targetVersion

# After
Write-SmartConflictResolution -FilePath $file.Path `
                               -CurrentContent $currentContent `
                               -BaseContent $baseContent `
                               -IncomingContent $incomingContent `
                               -OriginalVersion $manifestVersion `
                               -NewVersion $targetVersion
```

**Note**: Signature is identical, so this is a drop-in replacement.

### Step 7: Add Cleanup Logic

**File**: `scripts/update-orchestrator.ps1`

**Location**: In cleanup section (after successful update)

**Add**:
```powershell
# Cleanup temporary diff files
$tmpConflictsPath = ".specify/.tmp-conflicts"
if (Test-Path $tmpConflictsPath) {
    Write-Verbose "Cleaning up temporary diff files..."
    try {
        Remove-Item -Path $tmpConflictsPath -Recurse -Force
        Write-Verbose "Temporary diff files cleaned up successfully"
    }
    catch {
        Write-Warning "Failed to clean up diff files: $($_.Exception.Message)"
    }
}
```

**Location for Rollback**: Do NOT clean up on rollback (preserve for debugging per FR-015)

### Step 8: Write Unit Tests

**File**: `tests/unit/ConflictDetector.Tests.ps1`

**Add Test Blocks**:

```powershell
Describe "Compare-FileSections" {
    Context "Identical files" {
        It "Returns empty DiffSections for identical content" {
            # Test implementation
        }
    }

    Context "Single section change" {
        It "Groups consecutive changed lines into one section" {
            # Test implementation
        }
    }

    # Add more test cases per contracts/Compare-FileSections.md
}

Describe "Write-SideBySideDiff" {
    Context "Diff file creation" {
        It "Creates diff file in .specify/.tmp-conflicts/" {
            # Test implementation
        }
    }

    # Add more test cases per contracts/Write-SideBySideDiff.md
}

Describe "Write-SmartConflictResolution" {
    Context "File size detection" {
        It "Uses Git markers for files with 100 lines or less" {
            # Test implementation
        }

        It "Generates diff for files with more than 100 lines" {
            # Test implementation
        }
    }

    # Add more test cases per contracts/Write-SmartConflictResolution.md
}
```

**Run Tests**:
```powershell
.\tests\test-runner.ps1 -Unit
```

### Step 9: Create Test Fixtures

**Directory**: `tests/fixtures/large-file-samples/`

**Create**:
1. `small-file.md` (50 lines)
2. `boundary-100-lines.md` (exactly 100 lines)
3. `boundary-101-lines.md` (101 lines)
4. `large-file-200-lines.md` (200 lines with 3 changed sections)
5. `large-file-1000-lines.md` (1000 lines for performance testing)

**Usage**: Reference these in unit tests and integration tests.

### Step 10: Write Integration Tests

**File**: `tests/integration/UpdateOrchestrator.Tests.ps1`

**Add Test Cases**:
```powershell
Describe "Smart Conflict Resolution Integration" {
    It "Generates diff file for large template conflict" {
        # Simulate full update workflow with large file conflict
        # Verify diff file created
        # Verify format is valid Markdown
    }

    It "Uses Git markers for small file conflict" {
        # Simulate full update workflow with small file conflict
        # Verify Git markers written to file
    }

    It "Cleans up diff files after successful update" {
        # Simulate update with diff file generation
        # Verify cleanup removes .specify/.tmp-conflicts/
    }
}
```

### Step 11: Test End-to-End

**Manual Testing**:

```powershell
# 1. Create test SpecKit project
cd $env:TEMP
mkdir test-speckit-project
cd test-speckit-project
git init
mkdir .specify\templates

# 2. Create large template file (200 lines)
1..200 | ForEach-Object { "Line $_" } | Out-File ".specify\templates\tasks-template.md"

# 3. Initialize manifest with old version
# (Simulate customized file scenario)

# 4. Run update orchestrator with test data
& "path\to\scripts\update-orchestrator.ps1" -CheckOnly

# 5. Verify diff file generated
Get-Content ".specify\.tmp-conflicts\tasks-template.diff.md"

# 6. Open in VSCode to verify rendering
code ".specify\.tmp-conflicts\tasks-template.diff.md"
```

### Step 12: Update Documentation

**Files to Update**:

1. **CLAUDE.md** - Update "Git Conflict Markers" section:
   - Add description of smart conflict resolution
   - Add example diff file output
   - Update architecture diagram

2. **README.md** - Add feature mention:
   - "Smart diff generation for large file conflicts"

3. **CHANGELOG.md** - Add under `[Unreleased]`:
   ```markdown
   ### Added
   - Smart conflict resolution: Generate side-by-side diff files for large template conflicts (>100 lines) instead of full Git markers
   - Three new functions in ConflictDetector module: Write-SmartConflictResolution, Compare-FileSections, Write-SideBySideDiff
   - Automatic cleanup of temporary diff files in .specify/.tmp-conflicts/
   ```

### Step 13: Final Validation

**Pre-Commit Checklist**:

- [  ] All unit tests pass (`.\tests\test-runner.ps1 -Unit`)
- [  ] All integration tests pass (`.\tests\test-runner.ps1 -Integration`)
- [  ] No PowerShell script analyzer warnings (`Invoke-ScriptAnalyzer`)
- [  ] Diff file renders correctly in VSCode preview
- [  ] Performance target met (<2 seconds for 1000-line files)
- [  ] Documentation updated (CLAUDE.md, README.md, CHANGELOG.md)
- [  ] Constitution principles followed (check plan.md Constitution Check section)
- [  ] Git conflict markers still work for small files (backward compatibility)

## Common Pitfalls and Solutions

### Pitfall 1: Module Scope Errors

**Problem**: Functions not accessible after import

**Solution**: Ensure `Export-ModuleMember` includes all new functions

### Pitfall 2: Line Ending Inconsistencies

**Problem**: Comparison fails due to CRLF/LF differences

**Solution**: Use normalized content from HashUtils module before comparison

### Pitfall 3: Context Line Boundaries

**Problem**: Context lines extend beyond file boundaries (negative line numbers or beyond EOF)

**Solution**: Add boundary checks when adding context lines:
```powershell
$startWithContext = [Math]::Max(1, $sectionStart - $ContextLines)
$endWithContext = [Math]::Min($totalLines, $sectionEnd + $ContextLines)
```

### Pitfall 4: UTF-8 BOM Issues

**Problem**: BOM (Byte Order Mark) added to file causes rendering issues

**Solution**: Use `[System.Text.UTF8Encoding]::new($false)` for UTF-8 without BOM

### Pitfall 5: Performance Degradation

**Problem**: Large files (1000+ lines) exceed 2-second target

**Solution**: Use `[System.IO.StreamWriter]` for incremental file writing instead of string concatenation

## Testing Strategy

### Unit Test Coverage Targets

- `Compare-FileSections`: 12 tests (see contract)
- `Write-SideBySideDiff`: 6 tests (see contract)
- `Write-SmartConflictResolution`: 6 tests (see contract)
- **Total**: 24 new unit tests minimum

### Integration Test Scenarios

1. End-to-end large file conflict (200 lines, 3 sections)
2. End-to-end small file conflict (50 lines)
3. Cleanup verification
4. Rollback preservation (diff files kept)
5. Error fallback (diff generation fails → Git markers)

### Performance Benchmarks

```powershell
# Benchmark 1: 100-line file
Measure-Command { Write-SmartConflictResolution ... }  # Target: <100ms

# Benchmark 2: 1000-line file
Measure-Command { Write-SmartConflictResolution ... }  # Target: <2000ms
```

## Troubleshooting

### Issue: Tests fail with "command not recognized"

**Cause**: Module not imported or export missing

**Fix**:
```powershell
Import-Module .\scripts\modules\ConflictDetector.psm1 -Force
Get-Command -Module ConflictDetector  # Verify exports
```

### Issue: Diff file has incorrect line numbers

**Cause**: Off-by-one error in line indexing (0-based vs 1-based)

**Fix**: Ensure all line numbers are 1-indexed (first line is line 1, not line 0)

### Issue: Compare-Object is slow

**Cause**: Default SyncWindow too large or content not split correctly

**Fix**: Use `-SyncWindow 5` (tested value from research.md)

## Next Steps

After completing implementation:

1. **Run `/speckit.tasks`** to generate implementation task breakdown
2. **Create pull request** with comprehensive description
3. **Request code review** from maintainer
4. **Update version** in CHANGELOG.md when merged

## Resources

- [Feature Spec](spec.md) - User stories and requirements
- [Implementation Plan](plan.md) - Technical design
- [Research](research.md) - Technology choices and rationale
- [Data Model](data-model.md) - Entity definitions
- [Function Contracts](contracts/) - Detailed API specifications
- [Constitution](../../../.specify/memory/constitution.md) - Core principles
- [CLAUDE.md](../../../CLAUDE.md) - Repository architecture

## Questions?

If you encounter issues or have questions:

1. Check [CONTRIBUTING.md](../../../CONTRIBUTING.md) for development guidelines
2. Review existing module implementations for patterns
3. Consult the constitution for principle clarifications
4. Open GitHub issue with specific question and context
