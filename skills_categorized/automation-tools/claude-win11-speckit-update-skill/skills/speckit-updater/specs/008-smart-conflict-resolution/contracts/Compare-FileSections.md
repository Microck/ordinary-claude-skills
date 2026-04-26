# Function Contract: Compare-FileSections

**Module**: ConflictDetector.psm1
**Type**: Public (Exported)
**Phase**: 1 (Design & Contracts)
**Date**: 2025-10-21

## Purpose

Compares two file contents line-by-line and returns structured information about changed and unchanged sections. Groups consecutive changed lines into logical sections with line numbers and context.

This is the core comparison logic function that powers the smart diff generation.

## Signature

```powershell
function Compare-FileSections {
    <#
    .SYNOPSIS
        Compares two file contents and returns changed sections with line numbers.

    .DESCRIPTION
        Uses PowerShell's Compare-Object to find differences between two file versions.
        Groups consecutive changed lines into logical sections (DiffSection entities).
        Identifies unchanged line ranges (UnchangedRange entities).
        Returns a ComparisonResult hashtable with all comparison data.

    .PARAMETER CurrentContent
        The current file content (user's version). Must be normalized.

    .PARAMETER IncomingContent
        The incoming file content from upstream (new version). Must be normalized.

    .PARAMETER ContextLines
        Number of context lines to include before/after each changed section.
        Default: 3 (matches Git diff standard).

    .EXAMPLE
        $result = Compare-FileSections -CurrentContent $current -IncomingContent $incoming

        Returns a ComparisonResult with DiffSections and UnchangedRanges.

    .EXAMPLE
        $result = Compare-FileSections -CurrentContent $current `
                                        -IncomingContent $incoming `
                                        -ContextLines 5

        Uses 5 context lines instead of default 3.

    .OUTPUTS
        [hashtable] ComparisonResult with these keys:
        - Metadata: ConflictMetadata (partial - only basic info)
        - DiffSections: [DiffSection[]] Array of changed sections
        - UnchangedRanges: [UnchangedRange[]] Array of unchanged line ranges
        - TotalChangedLines: [int] Count of changed lines
        - TotalUnchangedLines: [int] Count of unchanged lines

    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$CurrentContent,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$IncomingContent,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 10)]
        [int]$ContextLines = 3
    )

    # Implementation goes here
}
```

## Parameters

| Parameter | Type | Required | Default | Validation | Description |
|-----------|------|----------|---------|------------|-------------|
| `CurrentContent` | `[string]` | Yes | N/A | AllowEmptyString | User's current version (normalized) |
| `IncomingContent` | `[string]` | Yes | N/A | AllowEmptyString | New upstream version (normalized) |
| `ContextLines` | `[int]` | No | 3 | Range(0, 10) | Number of context lines before/after changes |

## Return Value

**Type**: `[hashtable]` (ComparisonResult entity from data-model.md)

**Structure**:
```powershell
@{
    Metadata = @{
        FileSize = [int]  # Line count from CurrentContent
        # Other metadata fields populated by caller
    }
    DiffSections = @(
        @{
            SectionNumber = [int]
            CurrentStartLine = [int]
            CurrentEndLine = [int]
            IncomingStartLine = [int]
            IncomingEndLine = [int]
            CurrentContent = [string]
            IncomingContent = [string]
            ChangeType = [string]  # "Added", "Removed", "Modified"
        },
        # ... more sections
    )
    UnchangedRanges = @(
        @{
            StartLine = [int]
            EndLine = [int]
            LineCount = [int]
            Description = [string]  # Optional, may be $null
        },
        # ... more ranges
    )
    TotalChangedLines = [int]
    TotalUnchangedLines = [int]
}
```

## Algorithm

### High-Level Flow

```
1. Split content into line arrays
2. Run Compare-Object with -IncludeEqual
3. Group consecutive changed lines into sections
4. Add context lines to each section
5. Identify unchanged ranges
6. Return ComparisonResult hashtable
```

### Detailed Algorithm

```powershell
# Step 1: Split into lines
$currentLines = $CurrentContent -split "`n"
$incomingLines = $IncomingContent -split "`n"

# Step 2: Compare line by line
$comparison = Compare-Object -ReferenceObject $currentLines `
                             -DifferenceObject $incomingLines `
                             -IncludeEqual `
                             -SyncWindow 5

# Step 3: Group consecutive changes
$diffSections = @()
$sectionNumber = 1
$currentSection = $null

foreach ($line in $comparison) {
    if ($line.SideIndicator -ne "==") {
        # This is a changed line
        if ($null -eq $currentSection) {
            # Start new section
            $currentSection = @{
                SectionNumber = $sectionNumber++
                StartLine = $line.InputObject.LineNumber
                Changes = @($line)
            }
        }
        elseif ($line.InputObject.LineNumber - $currentSection.EndLine -le $ContextLines + 1) {
            # Extend current section (within context threshold)
            $currentSection.Changes += $line
        }
        else {
            # Gap too large, finalize current section and start new one
            $diffSections += Finalize-Section $currentSection
            $currentSection = @{
                SectionNumber = $sectionNumber++
                StartLine = $line.InputObject.LineNumber
                Changes = @($line)
            }
        }
    }
}

# Finalize last section
if ($null -ne $currentSection) {
    $diffSections += Finalize-Section $currentSection
}

# Step 4: Identify unchanged ranges
$unchangedRanges = Get-UnchangedRanges -Comparison $comparison -DiffSections $diffSections

# Step 5: Build result
return @{
    Metadata = @{ FileSize = $currentLines.Count }
    DiffSections = $diffSections
    UnchangedRanges = $unchangedRanges
    TotalChangedLines = ($diffSections | Measure-Object -Sum { $_.CurrentEndLine - $_.CurrentStartLine + 1 }).Sum
    TotalUnchangedLines = ($unchangedRanges | Measure-Object -Sum LineCount).Sum
}
```

## Dependencies

- PowerShell built-in: `Compare-Object` cmdlet
- PowerShell built-in: `-split` operator
- PowerShell built-in: `Measure-Object` cmdlet

## Error Handling

```
Try:
    Split content into lines
    Run Compare-Object
    Group changes
Catch [System.OutOfMemoryException]:
    Throw "File too large for comparison"
Catch [System.ArgumentException]:
    Throw "Invalid content format"
Catch:
    Throw "Comparison failed: $($_.Exception.Message)"
```

## Testing Requirements

### Unit Tests

1. **Test: Identical files**
   - Input: Same content for both parameters
   - Expected: Empty `DiffSections`, all lines in `UnchangedRanges`

2. **Test: Single section change**
   - Input: Files differ in lines 10-15
   - Expected: One `DiffSection` with correct line numbers

3. **Test: Multiple sections**
   - Input: Files differ in lines 10-15, 50-55, 100-105
   - Expected: Three `DiffSection` entities

4. **Test: Context lines**
   - Input: Single line changed (line 50), ContextLines=3
   - Expected: Section includes lines 47-53 (3 before + 1 changed + 3 after)

5. **Test: Change at start of file**
   - Input: Lines 1-5 differ
   - Expected: No context before line 1 (boundary handling)

6. **Test: Change at end of file**
   - Input: Last 5 lines differ
   - Expected: No context after last line (boundary handling)

7. **Test: Empty file comparison**
   - Input: Both files empty
   - Expected: Empty `DiffSections`, empty `UnchangedRanges`

8. **Test: One empty file**
   - Input: Current empty, Incoming has 100 lines
   - Expected: One `DiffSection` with ChangeType="Added"

### Performance Tests

1. **Benchmark: 100-line file**
   - Expected: Complete in <50ms

2. **Benchmark: 1000-line file**
   - Expected: Complete in <500ms (supports 2-second total target)

## Example Output

### Example 1: Three Changed Sections

Input:
- Current: 200 lines
- Incoming: 200 lines
- Changes at lines 11-14, 54-58, 120-125

Output:
```powershell
@{
    Metadata = @{ FileSize = 200 }
    DiffSections = @(
        @{
            SectionNumber = 1
            CurrentStartLine = 8     # 3 context lines before
            CurrentEndLine = 17      # 3 context lines after
            IncomingStartLine = 8
            IncomingEndLine = 17
            CurrentContent = "Line 8\nLine 9\n..."
            IncomingContent = "Line 8\nLine 9\n..."
            ChangeType = "Modified"
        },
        @{
            SectionNumber = 2
            CurrentStartLine = 51
            CurrentEndLine = 61
            # ...
        },
        @{
            SectionNumber = 3
            CurrentStartLine = 117
            CurrentEndLine = 128
            # ...
        }
    )
    UnchangedRanges = @(
        @{ StartLine = 1; EndLine = 7; LineCount = 7; Description = $null },
        @{ StartLine = 18; EndLine = 50; LineCount = 33; Description = $null },
        @{ StartLine = 62; EndLine = 116; LineCount = 55; Description = $null },
        @{ StartLine = 129; EndLine = 200; LineCount = 72; Description = $null }
    )
    TotalChangedLines = 30
    TotalUnchangedLines = 170
}
```

## Notes

- Function is stateless and pure (same inputs always produce same output)
- Content MUST be normalized before calling (CRLF/LF, trailing whitespace)
- Context lines are added symmetrically (same number before and after)
- Line numbers are 1-indexed (not 0-indexed)
- ChangeType determination: "Added" if only in Incoming, "Removed" if only in Current, "Modified" if in both
