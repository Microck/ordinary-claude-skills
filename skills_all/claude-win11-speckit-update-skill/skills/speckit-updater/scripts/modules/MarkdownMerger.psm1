<#
.SYNOPSIS
    Performs intelligent 3-way merge of markdown files with semantic understanding.

.DESCRIPTION
    The MarkdownMerger module provides smart merge capabilities for markdown files,
    parsing them into semantic sections and performing granular conflict detection.
    Uses fuzzy matching to identify renamed/reorganized sections and generates
    git conflict markers only for truly conflicting changes.

    Key Features:
    - Section-based parsing using markdown headers
    - Fuzzy section matching (80% similarity threshold)
    - Granular git conflict markers (section-level, not file-level)
    - Incoming structure as canonical (layer customizations)
    - Auto-merge compatible changes

.NOTES
    Module: MarkdownMerger
    Author: SpecKit Safe Update Skill
    Version: 1.0.0
    Related Issue: #25
#>

<#
.SYNOPSIS
    Calculates Levenshtein distance between two strings.

.DESCRIPTION
    Computes the minimum number of single-character edits (insertions, deletions,
    substitutions) required to change one string into another. Used for fuzzy
    matching of markdown sections.

.PARAMETER Source
    The source string.

.PARAMETER Target
    The target string to compare against.

.OUTPUTS
    Int32
    The Levenshtein distance (edit distance) between the two strings.

.EXAMPLE
    Get-LevenshteinDistance -Source "kitten" -Target "sitting"
    # Returns: 3
#>
function Get-LevenshteinDistance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Source,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Target
    )

    # Handle empty strings
    if ([string]::IsNullOrEmpty($Source)) { return $Target.Length }
    if ([string]::IsNullOrEmpty($Target)) { return $Source.Length }

    $sourceLength = $Source.Length
    $targetLength = $Target.Length

    # Convert strings to char arrays for proper indexing
    $sourceChars = $Source.ToCharArray()
    $targetChars = $Target.ToCharArray()

    # Initialize distance matrix
    $matrix = New-Object 'int[,]' ($sourceLength + 1), ($targetLength + 1)

    # Initialize first column and row
    for ($i = 0; $i -le $sourceLength; $i++) {
        $matrix[$i, 0] = $i
    }
    for ($j = 0; $j -le $targetLength; $j++) {
        $matrix[0, $j] = $j
    }

    # Calculate distances
    for ($i = 1; $i -le $sourceLength; $i++) {
        for ($j = 1; $j -le $targetLength; $j++) {
            # Use case-sensitive comparison for characters
            $cost = if ($sourceChars[$i - 1] -ceq $targetChars[$j - 1]) { 0 } else { 1 }

            $deletion = $matrix[($i - 1), $j] + 1
            $insertion = $matrix[$i, ($j - 1)] + 1
            $substitution = $matrix[($i - 1), ($j - 1)] + $cost

            $matrix[$i, $j] = [Math]::Min([Math]::Min($deletion, $insertion), $substitution)
        }
    }

    return $matrix[$sourceLength, $targetLength]
}

<#
.SYNOPSIS
    Calculates similarity percentage between two strings.

.DESCRIPTION
    Uses Levenshtein distance to calculate a similarity percentage (0-100%)
    between two strings. Higher percentage means more similar.

.PARAMETER Source
    The source string.

.PARAMETER Target
    The target string to compare against.

.OUTPUTS
    Double
    Similarity percentage (0.0 to 100.0).

.EXAMPLE
    Get-StringSimilarity -Source "Hello World" -Target "Hello World!"
    # Returns: ~95.8
#>
function Get-StringSimilarity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Source,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Target
    )

    if ($Source -eq $Target) { return 100.0 }
    if ([string]::IsNullOrEmpty($Source) -and [string]::IsNullOrEmpty($Target)) { return 100.0 }
    if ([string]::IsNullOrEmpty($Source) -or [string]::IsNullOrEmpty($Target)) { return 0.0 }

    $distance = Get-LevenshteinDistance -Source $Source -Target $Target
    $maxLength = [Math]::Max($Source.Length, $Target.Length)

    return [Math]::Round((1 - ($distance / $maxLength)) * 100, 2)
}

<#
.SYNOPSIS
    Parses markdown content into sections based on headers.

.DESCRIPTION
    Splits markdown content into logical sections using headers (# ## ###).
    Each section includes the header and all content until the next header
    of equal or higher level.

.PARAMETER Content
    The markdown content to parse.

.OUTPUTS
    Array of PSCustomObject
    Each object has: Header, Level, Content, LineStart, LineEnd

.EXAMPLE
    $sections = Get-MarkdownSections -Content $markdownText
    foreach ($section in $sections) {
        Write-Host "$($section.Header): $($section.Content.Length) chars"
    }
#>
function Get-MarkdownSections {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    $lines = $Content -split "`r?`n"
    $sections = @()
    $currentSection = $null
    $lineNumber = 0

    foreach ($line in $lines) {
        $lineNumber++

        # Check if line is a header
        if ($line -match '^(#{1,6})\s+(.+)$') {
            $level = $Matches[1].Length
            $header = $Matches[2].Trim()

            # Save previous section
            if ($currentSection) {
                $currentSection.LineEnd = $lineNumber - 1
                $currentSection.Content = $currentSection.ContentLines -join "`n"
                $sections += $currentSection
            }

            # Start new section
            $currentSection = [PSCustomObject]@{
                Header = $header
                Level = $level
                HeaderLine = $line
                ContentLines = @()
                Content = ""
                LineStart = $lineNumber
                LineEnd = 0
            }
        }
        elseif ($currentSection) {
            # Add line to current section
            $currentSection.ContentLines += $line
        }
        else {
            # Content before first header (frontmatter, etc.)
            if (-not $currentSection) {
                $currentSection = [PSCustomObject]@{
                    Header = "[Document Start]"
                    Level = 0
                    HeaderLine = ""
                    ContentLines = @($line)
                    Content = ""
                    LineStart = 1
                    LineEnd = 0
                }
            }
        }
    }

    # Save last section
    if ($currentSection) {
        $currentSection.LineEnd = $lineNumber
        $currentSection.Content = $currentSection.ContentLines -join "`n"
        $sections += $currentSection
    }

    return $sections
}

<#
.SYNOPSIS
    Finds the best matching section using fuzzy matching.

.DESCRIPTION
    Searches for a section in a list that best matches the target section
    using header similarity and content similarity. Returns the best match
    if similarity exceeds the threshold.

.PARAMETER TargetSection
    The section to find a match for.

.PARAMETER SectionList
    The list of sections to search.

.PARAMETER Threshold
    Minimum similarity percentage required for a match (default: 80.0).

.OUTPUTS
    PSCustomObject
    The best matching section, or $null if no match exceeds threshold.

.EXAMPLE
    $match = Find-MatchingSection -TargetSection $section -SectionList $baseSections
    if ($match) {
        Write-Host "Found match: $($match.Header)"
    }
#>
function Find-MatchingSection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$TargetSection,

        [Parameter(Mandatory)]
        [array]$SectionList,

        [Parameter()]
        [double]$Threshold = 80.0
    )

    if ($SectionList.Count -eq 0) { return $null }

    $bestMatch = $null
    $bestScore = 0.0

    foreach ($section in $SectionList) {
        # Skip if already matched
        if ($section.Matched) { continue }

        # Calculate header similarity (weighted 70%)
        $headerSimilarity = Get-StringSimilarity -Source $TargetSection.Header -Target $section.Header

        # Calculate content similarity (weighted 30%)
        $contentSimilarity = if ($TargetSection.Content -and $section.Content) {
            Get-StringSimilarity -Source $TargetSection.Content -Target $section.Content
        } else { 0.0 }

        # Combined score
        $score = ($headerSimilarity * 0.7) + ($contentSimilarity * 0.3)

        Write-Verbose "Section '$($section.Header)': header=$headerSimilarity%, content=$contentSimilarity%, combined=$score%"

        if ($score -gt $bestScore) {
            $bestScore = $score
            $bestMatch = $section
        }
    }

    if ($bestScore -ge $Threshold) {
        Write-Verbose "Best match for '$($TargetSection.Header)': '$($bestMatch.Header)' (score: $bestScore%)"
        $bestMatch | Add-Member -MemberType NoteProperty -Name Matched -Value $true -Force
        return $bestMatch
    }

    Write-Verbose "No match found for '$($TargetSection.Header)' (best score: $bestScore% < threshold: $Threshold%)"
    return $null
}

<#
.SYNOPSIS
    Generates git conflict markers for a section.

.DESCRIPTION
    Creates git-style conflict markers (<<<<<<< ======= >>>>>>>) for a section
    that has conflicting changes in the current and incoming versions.

.PARAMETER Header
    The section header.

.PARAMETER CurrentContent
    Content from the current (local) version.

.PARAMETER BaseContent
    Content from the base (original) version.

.PARAMETER IncomingContent
    Content from the incoming (new) version.

.PARAMETER CurrentVersion
    Version label for current content (e.g., "Your Version").

.PARAMETER IncomingVersion
    Version label for incoming content (e.g., "v0.0.79").

.OUTPUTS
    String
    The section with git conflict markers.

.EXAMPLE
    $conflictSection = New-ConflictMarker -Header "## Installation" `
                                          -CurrentContent $current `
                                          -BaseContent $base `
                                          -IncomingContent $incoming `
                                          -CurrentVersion "Your Changes" `
                                          -IncomingVersion "v0.0.79"
#>
function New-ConflictMarker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Header,

        [Parameter(Mandatory)]
        [string]$CurrentContent,

        [Parameter()]
        [string]$BaseContent = "",

        [Parameter(Mandatory)]
        [string]$IncomingContent,

        [Parameter()]
        [string]$CurrentVersion = "Current",

        [Parameter()]
        [string]$IncomingVersion = "Incoming"
    )

    $marker = @"
$Header
<<<<<<< $CurrentVersion
$CurrentContent
||||||| Base
$BaseContent
=======
$IncomingContent
>>>>>>> $IncomingVersion
"@

    return $marker
}

<#
.SYNOPSIS
    Performs intelligent 3-way merge of markdown files.

.DESCRIPTION
    Merges three versions of a markdown file (base, current, incoming) using
    semantic understanding of markdown structure. Automatically merges compatible
    changes and generates granular git conflict markers for truly conflicting sections.

    Merge Strategy:
    1. Parse all three versions into sections
    2. Use incoming structure as canonical
    3. For each incoming section:
       - Find matching sections in base and current
       - If current unchanged from base: use incoming (update)
       - If current changed but compatible: auto-merge
       - If current changed and conflicts: generate conflict markers

.PARAMETER BasePath
    Path to the base (original) version file.

.PARAMETER CurrentPath
    Path to the current (local) version file.

.PARAMETER IncomingPath
    Path to the incoming (new) version file.

.PARAMETER OutputPath
    Path where merged result should be written.

.PARAMETER BaseVersion
    Version label for base content (e.g., "v0.0.71").

.PARAMETER IncomingVersion
    Version label for incoming content (e.g., "v0.0.79").

.OUTPUTS
    PSCustomObject
    Merge result with: Success, ConflictCount, MergedSections, AutoMergedSections, NewSections, RemovedSections

.EXAMPLE
    $result = Merge-MarkdownFiles -BasePath "old.md" `
                                   -CurrentPath "current.md" `
                                   -IncomingPath "new.md" `
                                   -OutputPath "merged.md" `
                                   -BaseVersion "v0.0.71" `
                                   -IncomingVersion "v0.0.79"

    if ($result.ConflictCount -eq 0) {
        Write-Host "Clean merge! No conflicts."
    }
#>
function Merge-MarkdownFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BasePath,

        [Parameter(Mandatory)]
        [string]$CurrentPath,

        [Parameter(Mandatory)]
        [string]$IncomingPath,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [Parameter()]
        [string]$BaseVersion = "Base",

        [Parameter()]
        [string]$IncomingVersion = "Incoming"
    )

    try {
        Write-Verbose "Starting 3-way merge: Base=$BasePath, Current=$CurrentPath, Incoming=$IncomingPath"

        # Read all three versions
        $baseContent = Get-Content -Path $BasePath -Raw -ErrorAction Stop
        $currentContent = Get-Content -Path $CurrentPath -Raw -ErrorAction Stop
        $incomingContent = Get-Content -Path $IncomingPath -Raw -ErrorAction Stop

        # Parse into sections
        $baseSections = Get-MarkdownSections -Content $baseContent
        $currentSections = Get-MarkdownSections -Content $currentContent
        $incomingSections = Get-MarkdownSections -Content $incomingContent

        Write-Verbose "Parsed sections: Base=$($baseSections.Count), Current=$($currentSections.Count), Incoming=$($incomingSections.Count)"

        # Merge result
        $mergedSections = @()
        $conflictCount = 0
        $autoMergedCount = 0
        $newSectionCount = 0
        $removedSections = @()

        # Process each incoming section (incoming structure is canonical)
        foreach ($incomingSection in $incomingSections) {
            Write-Verbose "Processing incoming section: $($incomingSection.Header)"

            # Find matching section in base
            $baseMatch = Find-MatchingSection -TargetSection $incomingSection -SectionList $baseSections

            # Find matching section in current
            $currentMatch = Find-MatchingSection -TargetSection $incomingSection -SectionList $currentSections

            if (-not $baseMatch -and -not $currentMatch) {
                # New section in incoming - add it
                Write-Verbose "  → New section (not in base or current)"
                $mergedSections += $incomingSection
                $newSectionCount++
            }
            elseif ($baseMatch -and -not $currentMatch) {
                # Section existed in base but was removed in current - respect removal
                Write-Verbose "  → Section removed in current, keeping removed"
                $removedSections += $baseMatch.Header
            }
            elseif (-not $baseMatch -and $currentMatch) {
                # New section added in current - keep current version
                Write-Verbose "  → Custom section in current, preserving"
                $mergedSections += $currentMatch
            }
            else {
                # Section exists in all three versions - check for conflicts
                $baseContentNorm = $baseMatch.Content.Trim()
                $currentContentNorm = $currentMatch.Content.Trim()
                $incomingContentNorm = $incomingSection.Content.Trim()

                if ($currentContentNorm -eq $baseContentNorm) {
                    # Current unchanged from base - use incoming (update)
                    Write-Verbose "  → Current unchanged, using incoming"
                    $mergedSections += $incomingSection
                }
                elseif ($currentContentNorm -eq $incomingContentNorm) {
                    # Current and incoming are the same - already up to date
                    Write-Verbose "  → Current matches incoming, no change needed"
                    $mergedSections += $incomingSection
                }
                elseif ($baseContentNorm -eq $incomingContentNorm) {
                    # Incoming unchanged from base - keep current customization
                    Write-Verbose "  → Incoming unchanged, keeping current customization"
                    $mergedSections += $currentMatch
                }
                else {
                    # Both current and incoming changed - conflict!
                    Write-Verbose "  → CONFLICT: Both current and incoming changed"
                    $conflictMarker = New-ConflictMarker -Header $incomingSection.HeaderLine `
                                                          -CurrentContent $currentMatch.Content `
                                                          -BaseContent $baseMatch.Content `
                                                          -IncomingContent $incomingSection.Content `
                                                          -CurrentVersion "Current (Your Changes)" `
                                                          -IncomingVersion "Incoming ($IncomingVersion)"

                    $conflictSection = [PSCustomObject]@{
                        Header = $incomingSection.Header
                        Level = $incomingSection.Level
                        HeaderLine = $incomingSection.HeaderLine
                        Content = $conflictMarker
                        LineStart = $incomingSection.LineStart
                        LineEnd = $incomingSection.LineEnd
                        IsConflict = $true
                    }

                    $mergedSections += $conflictSection
                    $conflictCount++
                }
            }
        }

        # Check for sections in current that don't exist in incoming (custom sections)
        foreach ($currentSection in $currentSections) {
            if ($currentSection.Matched) { continue }

            # Check if this was in base (removed in incoming) or is truly custom
            $baseMatch = Find-MatchingSection -TargetSection $currentSection -SectionList $baseSections -Threshold 80.0

            if ($baseMatch) {
                # Section was in base but removed in incoming - user decision needed
                Write-Verbose "Custom section '$($currentSection.Header)' was removed in incoming, preserving"
            }
            else {
                # Truly custom section - preserve it
                Write-Verbose "Preserving custom section: $($currentSection.Header)"
            }

            $mergedSections += $currentSection
        }

        # Build final merged content
        $mergedContent = ($mergedSections | ForEach-Object {
            if ($_.HeaderLine) {
                "$($_.HeaderLine)`n$($_.Content)"
            } else {
                $_.Content
            }
        }) -join "`n`n"

        # Write output
        Set-Content -Path $OutputPath -Value $mergedContent -Encoding UTF8 -NoNewline

        Write-Verbose "Merge complete: $conflictCount conflicts, $autoMergedCount auto-merged, $newSectionCount new sections"

        return [PSCustomObject]@{
            Success = $true
            ConflictCount = $conflictCount
            AutoMergedSections = $autoMergedCount
            NewSections = $newSectionCount
            RemovedSections = $removedSections
            TotalSections = $mergedSections.Count
            OutputPath = $OutputPath
        }
    }
    catch {
        Write-Error "Markdown merge failed: $($_.Exception.Message)"
        throw
    }
}

# Export public functions
Export-ModuleMember -Function @(
    'Get-LevenshteinDistance'
    'Get-StringSimilarity'
    'Get-MarkdownSections'
    'Find-MatchingSection'
    'New-ConflictMarker'
    'Merge-MarkdownFiles'
)
