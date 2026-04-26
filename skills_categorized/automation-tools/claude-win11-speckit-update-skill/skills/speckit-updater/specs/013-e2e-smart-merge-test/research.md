# Research & Design Decisions: E2E Smart Merge Test

**Feature**: End-to-End Smart Merge Test with Parallel Execution
**Date**: 2025-10-24
**Purpose**: Document design decisions for test infrastructure implementation

---

## 1. Parallel Test Execution in Pester 5.x

### Decision: Use ForEach-Object -Parallel with ThrottleLimit Parameter

**Selected Approach**:

```powershell
$results = $mergePairs | ForEach-Object -Parallel {
    # Import required modules in parallel context
    Import-Module "$using:helperModulePath" -Force

    # Execute test logic
    $testResult = # ... test execution ...

    # Return result object (collected automatically)
    $testResult
} -ThrottleLimit 4
```

**Rationale**:

- **ForEach-Object -Parallel** is native PowerShell 7.0+ feature (no external dependencies)
- **ThrottleLimit** parameter controls parallelism (default 5, we use 4 for resource management)
- Results are automatically collected into array, no manual synchronization needed
- Each parallel iteration runs in isolated runspace (prevents variable contamination)
- Simpler than Start-Job/Start-ThreadJob approaches (no manual job management)

**Alternatives Considered**:

1. **Start-Job with Wait-Job**: Rejected - more complex job management, slower runspace initialization
2. **Start-ThreadJob**: Rejected - requires ThreadJob module installation, limited PowerShell 7.0 support
3. **PoshRSJob module**: Rejected - external dependency, not shipped with PowerShell

**Thread-Safe Result Collection**:

- ForEach-Object -Parallel automatically aggregates returned objects into array
- No need for manual ConcurrentBag or synchronized collections
- Each iteration returns PSCustomObject with test results
- Final $results array contains all test outcomes

**Progress Tracking**:

```powershell
# Use $using: scope to access outer variables
$totalTests = $mergePairs.Count
$completed = 0

$results = $mergePairs | ForEach-Object -Parallel {
    # Increment progress (note: not thread-safe for display, but results are collected)
    $using:completed++

    # Write progress to verbose stream (visible in Pester output)
    Write-Verbose "[$($using:completed)/$($using:totalTests)] Testing $($_.From) → $($_.To)"

    # ... test execution ...
} -ThrottleLimit 4
```

**Limitations**:

- Progress tracking is approximate (race conditions on $completed variable)
- Cannot use Write-Progress inside parallel blocks (only outer scope)
- Verbose output may be interleaved across threads

**References**:

- [about_ForEach-Parallel (Microsoft Docs)](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_foreach-parallel)
- [PowerShell 7.0 Parallel Foreach (DevBlogs)](https://devblogs.microsoft.com/powershell/powershell-foreach-object-parallel-feature/)

---

## 2. GitHub API Rate Limiting

### Decision: Mutex-Based Serialization with 500ms Delay

**Selected Approach**:

```powershell
function Install-SpecKitVersion {
    param([string]$Version)

    # Create named mutex for cross-process coordination
    $mutex = New-Object System.Threading.Mutex($false, "Global\SpecKitE2EGitHubAPI")

    try {
        # Wait for exclusive access (no timeout = wait indefinitely)
        $null = $mutex.WaitOne()

        # Add delay to respect rate limits
        Start-Sleep -Milliseconds 500

        # Make GitHub API call
        $release = Get-LatestSpecKitRelease -Version $Version

        # Download and extract templates
        # ...
    }
    finally {
        # Always release mutex, even on error
        $mutex.ReleaseMutex()
        $mutex.Dispose()
    }
}
```

**Rationale**:

- **Mutex** ensures only one thread accesses GitHub API at a time (prevents simultaneous requests)
- **500ms delay** stays well under 60 req/hr limit (7200 requests would require 3600 seconds = 1 hour)
- **Named mutex** ("Global\SpecKitE2EGitHubAPI") works across processes and threads
- **finally block** guarantees mutex release even on exceptions

**Math**:

- 60 requests/hour = 1 request per 60 seconds
- With 500ms delay: 120 potential requests/hour (double the limit)
- Actual usage: ~18 tests × 1 API call = 18 requests (well under limit)
- Safety margin: 18/60 = 30% of limit used

**Rate Limit Detection**:

```powershell
# Check response headers for rate limit info
if ($response.Headers.'X-RateLimit-Remaining') {
    $remaining = [int]$response.Headers.'X-RateLimit-Remaining'
    if ($remaining -lt 5) {
        Write-Warning "GitHub API rate limit low: $remaining requests remaining"
    }
}
```

**Fail-Fast on API Error** (per FR-016):

```powershell
try {
    $release = Get-LatestSpecKitRelease -Version $Version -ErrorAction Stop
}
catch {
    # No retries - fail immediately
    throw "GitHub API error for version $Version: $($_.Exception.Message)"
}
```

**Alternatives Considered**:

1. **Retry with exponential backoff**: Rejected per clarification (fail-fast approach chosen)
2. **Template caching**: Rejected for MVP (future enhancement to reduce API calls)
3. **Semaphore (limit N concurrent)**: Rejected (mutex simpler, serialization sufficient)

**References**:

- [GitHub REST API Rate Limits](https://docs.github.com/en/rest/overview/resources-in-the-rest-api#rate-limiting)
- [System.Threading.Mutex (Microsoft Docs)](https://learn.microsoft.com/en-us/dotnet/api/system.threading.mutex)

---

## 3. Dad Joke Injection Strategy

### Decision: Regex-Based Safe Insertion with Line-Level Parsing

**Selected Approach**:

```powershell
function Add-DadJokesToFile {
    param(
        [string]$FilePath,
        [int]$MinJokes = 5,
        [int]$MaxJokes = 10,
        [string[]]$JokeDatabase
    )

    $content = Get-Content -Path $FilePath -Raw
    $lines = Get-Content -Path $FilePath

    # Identify safe insertion points (body paragraphs, list items)
    $safeLines = @()
    $inCodeBlock = $false
    $inFrontMatter = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Track code blocks
        if ($line -match '^```') { $inCodeBlock = !$inCodeBlock; continue }

        # Track front matter
        if ($line -match '^---$' -and $i -lt 10) { $inFrontMatter = !$inFrontMatter; continue }

        # Skip headers, code, front matter, empty lines
        if ($inCodeBlock -or $inFrontMatter) { continue }
        if ($line -match '^#+\s') { continue }  # Headers
        if ($line.Trim() -eq '') { continue }   # Empty lines

        # This is a safe insertion point
        $safeLines += $i
    }

    # Randomly select joke count and insertion points
    $random = New-Object System.Random(42)
    $jokeCount = $random.Next($MinJokes, $MaxJokes + 1)
    $selectedLines = $safeLines | Get-Random -Count ([Math]::Min($jokeCount, $safeLines.Count)) -SetSeed 42
    $selectedJokes = $JokeDatabase | Get-Random -Count $jokeCount -SetSeed 42

    # Insert jokes (working backwards to preserve line numbers)
    $selectedLines = $selectedLines | Sort-Object -Descending
    $modifiedLines = $lines.Clone()

    for ($i = 0; $i -lt $selectedLines.Count; $i++) {
        $lineNum = $selectedLines[$i]
        $joke = $selectedJokes[$i]

        # Insert joke after the safe line
        $modifiedLines = @($modifiedLines[0..$lineNum]) + @($joke) + @($modifiedLines[($lineNum + 1)..($modifiedLines.Count - 1)])
    }

    # Write back to file
    $modifiedLines | Set-Content -Path $FilePath -Force

    return @{
        Jokes = $selectedJokes
        Locations = $selectedLines
        Count = $jokeCount
    }
}
```

**Rationale**:

- **Regex patterns** are sufficient for markdown structure detection (no AST parser needed)
- **Line-level parsing** is simple and fast
- **Safe insertion rules**:
  - ✅ Body paragraphs (text lines)
  - ✅ List items
  - ❌ Headers (start with #)
  - ❌ Code blocks (between ```)
  - ❌ Front matter (between --- delimiters)
  - ❌ Empty lines
- **Random selection** ensures variety across runs (with fixed seed for reproducibility)
- **Backward insertion** preserves line numbers when adding content

**Joke Distribution Algorithm**:

- Minimum 5 jokes, maximum 10 per file
- Random selection within range using seed 42
- If file has fewer safe lines than minimum jokes, use all available safe lines

**Alternatives Considered**:

1. **Markdown AST parser (markdig, CommonMark.NET)**: Rejected - requires .NET dependencies, overkill for simple task
2. **Fixed insertion points (every 10 lines)**: Rejected - not random enough, may hit unsafe locations
3. **Append all jokes to end of file**: Rejected - doesn't test merge logic across file (only end-of-file conflicts)

**Dad Joke Database**:

Embedded in test file (no external file dependency):

```powershell
$script:DadJokes = @(
    "Why don't scientists trust atoms? Because they make up everything!",
    "I'm reading a book about anti-gravity. It's impossible to put down!",
    "Why did the scarecrow win an award? He was outstanding in his field!",
    # ... 47 more jokes (total 50)
)
```

**References**:

- [about_Regular_Expressions (Microsoft Docs)](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_regular_expressions)
- [Markdown Specification (CommonMark)](https://spec.commonmark.org/)

---

## 4. Version Stratification Algorithm

### Decision: Date-Based Equal Time Periods with Minimum 3 per Group

**Selected Approach**:

```powershell
function Get-StratifiedVersions {
    param(
        [PSCustomObject]$FingerprintsData,
        [int]$Seed = 42,
        [int]$TotalVersions = 10
    )

    # Parse versions with release dates
    $allVersions = $FingerprintsData.versions.PSObject.Properties | ForEach-Object {
        [PSCustomObject]@{
            Version = $_.Name
            ReleaseDate = [datetime]$_.Value.release_date
        }
    } | Sort-Object ReleaseDate

    # Calculate date range boundaries
    $oldestDate = $allVersions[0].ReleaseDate
    $newestDate = $allVersions[-1].ReleaseDate
    $totalDays = ($newestDate - $oldestDate).TotalDays
    $daysPerGroup = $totalDays / 3

    # Group versions by timeframe
    $oldGroup = $allVersions | Where-Object {
        ($_.ReleaseDate - $oldestDate).TotalDays -lt $daysPerGroup
    }

    $middleGroup = $allVersions | Where-Object {
        $days = ($_.ReleaseDate - $oldestDate).TotalDays
        $days -ge $daysPerGroup -and $days -lt ($daysPerGroup * 2)
    }

    $recentGroup = $allVersions | Where-Object {
        ($_.ReleaseDate - $oldestDate).TotalDays -ge ($daysPerGroup * 2)
    }

    # Select random versions from each group
    $random = New-Object System.Random($Seed)
    $selectedVersions = @()

    $selectedVersions += ($oldGroup | Get-Random -Count 3 -SetSeed $Seed).Version
    $selectedVersions += ($middleGroup | Get-Random -Count 3 -SetSeed $Seed).Version
    $selectedVersions += ($recentGroup | Get-Random -Count 4 -SetSeed $Seed).Version

    return $selectedVersions
}
```

**Rationale**:

- **Equal time periods** (not equal version counts) ensures temporal diversity
  - If SpecKit had 50 releases in 2023 and 10 in 2024, equal counts would over-sample 2024
  - Date-based grouping gives proportional representation
- **3-3-4 distribution** (total 10) ensures minimum coverage per timeframe
  - Recent group gets +1 (most important for upgrade paths)
- **Deterministic seed (42)** guarantees reproducible selection across test runs

**Handling Edge Cases**:

```powershell
# If a group has fewer than required versions, take all available
$oldCount = [Math]::Min(3, $oldGroup.Count)
$middleCount = [Math]::Min(3, $middleGroup.Count)
$recentCount = [Math]::Min(4, $recentGroup.Count)

# If total < 10, reduce expectations (e.g., database has only 8 versions)
if (($oldCount + $middleCount + $recentCount) -lt $TotalVersions) {
    Write-Warning "Fingerprints database has fewer than $TotalVersions versions ($($oldCount + $middleCount + $recentCount) available)"
}
```

**Merge Pair Generation**:

```powershell
function Get-RandomMergePairs {
    param([string[]]$Versions, [int]$Count = 18, [int]$Seed = 42)

    # Generate all possible upgrade pairs (older → newer)
    $allPairs = @()
    for ($i = 0; $i -lt $Versions.Count; $i++) {
        for ($j = $i + 1; $j -lt $Versions.Count; $j++) {
            $v1 = [version]($Versions[$i] -replace '^v', '')
            $v2 = [version]($Versions[$j] -replace '^v', '')

            if ($v1 -lt $v2) {
                $allPairs += [PSCustomObject]@{ From = $Versions[$i]; To = $Versions[$j] }
            }
        }
    }

    # Randomly select pairs (with seed for reproducibility)
    return $allPairs | Get-Random -Count ([Math]::Min($Count, $allPairs.Count)) -SetSeed $Seed
}
```

**Why This Works**:

- 10 versions produce C(10,2) = 45 possible pairs
- We select 18 pairs (40% of all possible)
- Ensures coverage of old→middle, middle→recent, old→recent transitions

**Alternatives Considered**:

1. **Equal version counts per group**: Rejected - oversamples recent period if release cadence increased
2. **Manual version selection**: Rejected - not reproducible, requires maintenance as new versions release
3. **Test ALL possible pairs**: Rejected - 45 pairs × 60s each = 45 minutes (exceeds 15-minute goal)

**References**:

- [Get-Random with -SetSeed (Microsoft Docs)](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/get-random)
- [System.Random Class](https://learn.microsoft.com/en-us/dotnet/api/system.random)

---

## 5. Test Validation Strategies

### Decision: 9-Point Semantic Validation Checklist

**Selected Approach**:

```powershell
function Test-MergedFileValidity {
    param(
        [string]$FilePath,
        [hashtable]$OriginalJokes
    )

    $errors = @()
    $warnings = @()
    $content = Get-Content -Path $FilePath -Raw

    # 1. File integrity (exists, non-empty, reasonable size)
    if (-not (Test-Path $FilePath)) {
        $errors += "File does not exist: $FilePath"
        return @{ Valid = $false; Errors = $errors; Warnings = $warnings }
    }

    if ((Get-Item $FilePath).Length -eq 0) {
        $errors += "File is empty: $FilePath"
    }

    if ((Get-Item $FilePath).Length -gt 10MB) {
        $warnings += "File unusually large: $((Get-Item $FilePath).Length / 1MB) MB"
    }

    # 2. Markdown syntax validation (basic checks)
    $lines = Get-Content -Path $FilePath
    $inCodeBlock = $false

    foreach ($line in $lines) {
        # Check for orphaned code block markers
        if ($line -match '^```') { $inCodeBlock = !$inCodeBlock }
    }

    if ($inCodeBlock) {
        $errors += "Unclosed code block (odd number of ``` markers)"
    }

    # 3. Front matter validation (YAML structure)
    if ($content -match '^---\r?\n(.+?)\r?\n---') {
        # Front matter exists - basic YAML syntax check
        $frontMatter = $matches[1]
        if ($frontMatter -match ':\s*$') {
            $warnings += "Possible malformed YAML (empty values)"
        }
    }

    # 4. Required SpecKit sections present
    $requiredSections = @('User Scenarios', 'Requirements', 'Success Criteria')
    foreach ($section in $requiredSections) {
        if ($content -notmatch "##\s+$section") {
            $warnings += "Missing expected section: $section"
        }
    }

    # 5. Orphaned conflict markers check
    $conflictStarts = ($content | Select-String -Pattern '^<<<<<<<' -AllMatches).Matches.Count
    $conflictEnds = ($content | Select-String -Pattern '^>>>>>>>' -AllMatches).Matches.Count

    if ($conflictStarts -ne $conflictEnds) {
        $errors += "Orphaned conflict markers (start: $conflictStarts, end: $conflictEnds)"
    }

    # 6. Duplicate sections detection
    $headers = $lines | Where-Object { $_ -match '^##\s+(.+)$' }
    $headerTexts = $headers | ForEach-Object { $matches[1] }
    $duplicates = $headerTexts | Group-Object | Where-Object { $_.Count -gt 1 }

    if ($duplicates) {
        $warnings += "Duplicate sections: $($duplicates.Name -join ', ')"
    }

    # 7. Section order logical (subjective - basic check only)
    # (Skip for now - too subjective without domain knowledge)

    # 8. Dad jokes preservation (100% requirement)
    $jokesFound = 0
    $jokesMissing = @()

    foreach ($joke in $OriginalJokes.Jokes) {
        if ($content -match [regex]::Escape($joke)) {
            $jokesFound++
        }
        else {
            $jokesMissing += $joke
        }
    }

    if ($jokesMissing.Count -gt 0) {
        $errors += "Missing $($jokesMissing.Count) dad jokes: $($jokesMissing -join '; ')"
    }

    # 9. No file corruption (read succeeded, valid encoding)
    try {
        $null = [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($FilePath))
    }
    catch {
        $errors += "File encoding corruption: $($_.Exception.Message)"
    }

    return @{
        Valid = ($errors.Count -eq 0)
        Errors = $errors
        Warnings = $warnings
        JokesFound = $jokesFound
        JokesExpected = $OriginalJokes.Jokes.Count
    }
}
```

**Command Execution Testing with Fallback**:

```powershell
function Test-MergedCommandExecution {
    param([string]$CommandPath, [string]$ProjectRoot)

    try {
        # Option C: Attempt actual command invocation (if Claude Code available)
        if (Test-ClaudeCodeAvailable) {
            # Would require invoking Claude Code CLI (complex, deferred)
            # Fall through to structural validation
        }

        # Option A: Fallback - structural validation
        return Test-CommandStructure -CommandPath $CommandPath
    }
    catch {
        return @{
            Executable = $false
            StructureValid = $false
            ErrorMessage = $_.Exception.Message
        }
    }
}

function Test-CommandStructure {
    param([string]$CommandPath)

    $content = Get-Content -Path $CommandPath -Raw
    $errors = @()

    # Check front matter exists
    if ($content -notmatch '^---\r?\n(.+?)\r?\n---') {
        $errors += "Missing front matter"
    }

    # Check required markdown structure
    if ($content -notmatch '##\s+') {
        $errors += "No markdown sections found"
    }

    # Basic syntax validation
    $lines = Get-Content -Path $CommandPath
    $inCodeBlock = $false

    foreach ($line in $lines) {
        if ($line -match '^```') { $inCodeBlock = !$inCodeBlock }
    }

    if ($inCodeBlock) {
        $errors += "Unclosed code block"
    }

    return @{
        Executable = $false  # Not actually executed
        StructureValid = ($errors.Count -eq 0)
        ErrorMessage = if ($errors) { $errors -join '; ' } else { $null }
    }
}
```

**Rationale**:

- **9-point checklist** provides comprehensive validation without being overly complex
- **Fail-fast on critical errors** (missing file, orphaned markers, missing jokes)
- **Warnings for non-critical issues** (duplicate sections, large files)
- **Command execution fallback** (structural validation when actual execution unavailable)

**Alternatives Considered**:

1. **Full CommonMark validation**: Rejected - requires external .NET parser, overkill
2. **Actual command execution in test**: Rejected - requires Claude Code CLI integration (complex)
3. **Minimal validation (just file exists)**: Rejected - insufficient quality assurance

**References**:

- [CommonMark Spec](https://spec.commonmark.org/)
- [PowerShell regex](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_regular_expressions)

---

## 6. Test Cleanup and Resource Management

### Decision: Per-Test Cleanup with Disk Space Validation

**Selected Approach**:

```powershell
# In parallel execution block
$results = $mergePairs | ForEach-Object -Parallel {
    $testResult = $null

    try {
        # Pre-test disk space check (per FR-017)
        $availableSpace = (Get-PSDrive -Name C).Free / 1MB
        if ($availableSpace -lt 100) {
            throw "Insufficient disk space: ${availableSpace}MB available (minimum 100MB required)"
        }

        # Create test directory
        $testDir = New-E2ETestProject -Version $_.From -Root $using:testRoot

        # Execute test logic
        # ...

        $testResult = [PSCustomObject]@{
            Status = 'Passed'
            # ... other fields
        }
    }
    catch {
        $testResult = [PSCustomObject]@{
            Status = 'Failed'
            Error = $_.Exception.Message
        }
    }
    finally {
        # Cleanup test directory (always run, even on error)
        if ($testDir -and (Test-Path $testDir)) {
            try {
                Remove-Item -Path $testDir -Recurse -Force -ErrorAction Stop
            }
            catch {
                Write-Warning "Failed to cleanup test directory: $testDir"
            }
        }
    }

    # Return result
    $testResult
} -ThrottleLimit 4
```

**Disk Space Monitoring**:

- Check available space before each test (per FR-017)
- Fail gracefully if < 100MB available
- Calculate: 4 threads × 10MB each = 40MB active, +60MB buffer = 100MB threshold

**Cleanup Timing**:

- **Per-test cleanup** (chosen) - reduces peak disk usage, prevents accumulation
- Alternative: End-of-suite cleanup - rejected (higher peak usage, orphaned files if suite crashes)

**Error State Cleanup**:

```powershell
# In AfterAll block
AfterAll {
    # Final cleanup sweep (catch any orphaned directories)
    if (Test-Path $testRoot) {
        Get-ChildItem -Path $testRoot -Directory | Where-Object {
            $_.Name -match '^test-v\d+\.\d+\.\d+-'
        } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }

    # No orphaned processes expected (tests run in-process via PowerShell)
}
```

**Resource Leak Prevention**:

- **Mutex disposal**: Always dispose in finally blocks
- **File handles**: Use -Force flag with Remove-Item to close handles
- **Runspace cleanup**: ForEach-Object -Parallel handles automatically

**Alternatives Considered**:

1. **End-of-suite cleanup only**: Rejected - high peak disk usage, orphaned files on crash
2. **Aggressive mid-test cleanup**: Rejected - adds complexity, limited benefit
3. **No cleanup (manual)**: Rejected - poor developer experience, disk accumulation

**References**:

- [Get-PSDrive (Microsoft Docs)](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-psdrive)
- [about_Try_Catch_Finally](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_try_catch_finally)

---

## Summary of Decisions

| Topic | Decision | Rationale |
|-------|----------|-----------|
| **Parallel Execution** | ForEach-Object -Parallel | Native PowerShell 7.0+, automatic result collection |
| **GitHub API** | Mutex + 500ms delay, fail-fast | Prevents rate limiting, simple coordination |
| **Dad Joke Injection** | Regex-based line parsing | Simple, fast, sufficient for markdown |
| **Version Stratification** | Date-based equal periods (3-3-4) | Temporal diversity, reproducible |
| **Validation** | 9-point semantic checklist | Comprehensive without being complex |
| **Cleanup** | Per-test cleanup with disk validation | Reduces peak usage, prevents leaks |

**Next Phase**: Generate data model, API contracts, and quickstart guide (Phase 1).
