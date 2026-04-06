# API Contract: E2ETestHelpers.psm1

**Module**: E2ETestHelpers
**Location**: `tests/helpers/E2ETestHelpers.psm1`
**Purpose**: Reusable helper functions for end-to-end smart merge testing
**Date**: 2025-10-24

---

## Module Overview

The E2ETestHelpers module provides business logic for end-to-end testing of the smart merge system. It handles version stratification, test project management, content injection, validation, and reporting.

**Design Principles**:

- Stateless functions (all state passed via parameters)
- No dependencies on other modules (test file manages imports)
- Deterministic behavior (fixed seed 42 for reproducibility)
- Fail-fast error handling (throw on unrecoverable errors)

---

## Exported Functions

### 1. Get-StratifiedVersions

**Purpose**: Select 10 representative SpecKit versions stratified across old/middle/recent timeframes.

**Signature**:

```powershell
function Get-StratifiedVersions {
    <#
    .SYNOPSIS
        Selects stratified SpecKit versions for comprehensive merge testing.

    .DESCRIPTION
        Analyzes the fingerprints database and selects 10 versions distributed across
        three timeframes (old, middle, recent) using date-based boundaries. Ensures
        temporal diversity in test coverage.

    .PARAMETER FingerprintsData
        Parsed JSON object from data/speckit-fingerprints.json containing version metadata.

    .PARAMETER Seed
        Random number generator seed for reproducible selection (default: 42).

    .PARAMETER TotalVersions
        Total number of versions to select (default: 10, distributed as 3-3-4).

    .OUTPUTS
        string[] Array of version strings (e.g., "v0.0.50", "v0.0.79")

    .EXAMPLE
        $fingerprintsData = Get-Content "data/speckit-fingerprints.json" | ConvertFrom-Json
        $versions = Get-StratifiedVersions -FingerprintsData $fingerprintsData
        # Returns: @("v0.0.5", "v0.0.12", ..., "v0.0.79")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$FingerprintsData,

        [int]$Seed = 42,

        [int]$TotalVersions = 10
    )

    # Implementation details in research.md
}
```

**Behavior**:

- Parses version metadata from fingerprints database
- Calculates date boundaries (total range / 3)
- Groups versions into old (2023-early 2024), middle (mid-2024), recent (late-2024)
- Selects 3 from old, 3 from middle, 4 from recent (deterministic with seed 42)
- Returns array of version strings

**Error Handling**:

- Throws if FingerprintsData is null or missing 'versions' property
- Warns if any group has fewer than desired count
- Returns fewer than TotalVersions if database insufficient

---

### 2. Get-RandomMergePairs

**Purpose**: Generate random upgrade pairs from selected versions for test execution.

**Signature**:

```powershell
function Get-RandomMergePairs {
    <#
    .SYNOPSIS
        Generates random upgrade pairs from provided SpecKit versions.

    .DESCRIPTION
        Creates all possible upgrade pairs (older → newer) from input versions, then
        randomly selects a subset for testing. Ensures only valid upgrade paths.

    .PARAMETER Versions
        Array of SpecKit version strings (e.g., @("v0.0.50", "v0.0.79")).

    .PARAMETER Count
        Number of merge pairs to select (default: 18).

    .PARAMETER Seed
        Random number generator seed for reproducible selection (default: 42).

    .OUTPUTS
        PSCustomObject[] Array of {From, To} objects representing upgrade paths.

    .EXAMPLE
        $versions = @("v0.0.50", "v0.0.60", "v0.0.70", "v0.0.79")
        $pairs = Get-RandomMergePairs -Versions $versions -Count 3
        # Returns: @({From='v0.0.50'; To='v0.0.79'}, {From='v0.0.60'; To='v0.0.70'}, ...)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Versions,

        [int]$Count = 18,

        [int]$Seed = 42
    )
}
```

**Behavior**:

- Generates all possible pairs where From < To (semantic versioning)
- 10 versions produce C(10,2) = 45 possible pairs
- Randomly selects Count pairs (default 18, ~40% coverage)
- Returns PSCustomObject array with From and To properties

**Error Handling**:

- Throws if Versions array is null or empty
- Returns all pairs if Count > available pairs (no error)

---

### 3. New-E2ETestProject

**Purpose**: Create isolated test directory with unique GUID-based name.

**Signature**:

```powershell
function New-E2ETestProject {
    <#
    .SYNOPSIS
        Creates isolated test directory for merge testing.

    .DESCRIPTION
        Generates a unique directory name using GUID to prevent conflicts between
        parallel test executions. Creates directory in specified root path.

    .PARAMETER Version
        SpecKit version being tested (used in directory name for debugging).

    .PARAMETER Root
        Root directory for test environments (e.g., C:\Temp\e2e-tests).

    .OUTPUTS
        string Absolute path to created test directory.

    .EXAMPLE
        $testDir = New-E2ETestProject -Version "v0.0.79" -Root "C:\Temp\tests"
        # Returns: "C:\Temp\tests\test-v0.0.79-a1b2c3d4-e5f6-7890-abcd-ef1234567890"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Version,

        [Parameter(Mandatory)]
        [string]$Root
    )
}
```

**Behavior**:

- Generates directory name: `test-{version}-{guid}`
- Creates directory using New-Item -Force
- Returns absolute path to created directory

**Error Handling**:

- Throws if Root directory doesn't exist
- Throws if directory creation fails (permissions, disk space)

---

### 4. Install-SpecKitVersion

**Purpose**: Download and install specific SpecKit version from GitHub to test project.

**Signature**:

```powershell
function Install-SpecKitVersion {
    <#
    .SYNOPSIS
        Downloads and installs SpecKit templates from GitHub release.

    .DESCRIPTION
        Fetches specified SpecKit version from GitHub Releases API, downloads template
        archive, extracts to test project directory. Uses mutex for API coordination.

    .PARAMETER ProjectRoot
        Absolute path to test project directory.

    .PARAMETER Version
        SpecKit version to install (e.g., "v0.0.79").

    .OUTPUTS
        hashtable {Success, TemplatePath, ErrorMessage}

    .EXAMPLE
        $result = Install-SpecKitVersion -ProjectRoot "C:\Temp\test-123" -Version "v0.0.79"
        if ($result.Success) {
            Write-Host "Installed to: $($result.TemplatePath)"
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot,

        [Parameter(Mandatory)]
        [string]$Version
    )
}
```

**Behavior**:

- Acquires mutex ("Global\SpecKitE2EGitHubAPI") for exclusive API access
- Adds 500ms delay to respect rate limits
- Calls GitHub Releases API to fetch version metadata
- Downloads template ZIP archive
- Extracts to ProjectRoot/.specify/
- Releases mutex in finally block

**Return Values**:

```powershell
# Success
@{
    Success = $true
    TemplatePath = "C:\Temp\test-123\.specify"
    ErrorMessage = $null
}

# Failure (per FR-016: fail-fast, no retries)
@{
    Success = $false
    TemplatePath = $null
    ErrorMessage = "GitHub API error: 404 Not Found"
}
```

**Error Handling**:

- Throws if ProjectRoot doesn't exist
- Fails fast on GitHub API errors (no retries per FR-016)
- Returns error hashtable instead of throwing (allows test to continue)
- Always releases mutex (finally block)

---

### 5. Add-DadJokesToFile

**Purpose**: Inject 5-10 dad jokes into markdown file at safe locations.

**Signature**:

```powershell
function Add-DadJokesToFile {
    <#
    .SYNOPSIS
        Injects dad jokes into markdown file for preservation testing.

    .DESCRIPTION
        Parses markdown file to identify safe insertion points (body paragraphs), avoiding
        headers, code blocks, and front matter. Randomly selects and inserts jokes.

    .PARAMETER FilePath
        Absolute path to markdown file.

    .PARAMETER MinJokes
        Minimum number of jokes to inject (default: 5).

    .PARAMETER MaxJokes
        Maximum number of jokes to inject (default: 10).

    .PARAMETER JokeDatabase
        Array of available dad jokes to select from.

    .OUTPUTS
        hashtable {Jokes, Locations, Count}

    .EXAMPLE
        $jokes = Get-DadJokeDatabase
        $result = Add-DadJokesToFile -FilePath "file.md" -JokeDatabase $jokes
        # Returns: @{Jokes=@("Why don't..."); Locations=@(42, 87); Count=7}
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [int]$MinJokes = 5,

        [int]$MaxJokes = 10,

        [Parameter(Mandatory)]
        [string[]]$JokeDatabase
    )
}
```

**Behavior**:

- Reads file content as lines
- Identifies safe insertion points (body paragraphs, list items)
- Avoids unsafe locations (headers, code blocks, front matter, empty lines)
- Randomly selects joke count between MinJokes and MaxJokes
- Randomly selects jokes from database (seed 42)
- Inserts jokes (working backwards to preserve line numbers)
- Writes modified content back to file
- Returns hashtable with injected jokes and locations

**Return Value**:

```powershell
@{
    Jokes = @(
        "Why don't scientists trust atoms? Because they make up everything!",
        "I'm reading a book about anti-gravity. It's impossible to put down!"
    )
    Locations = @(42, 87, 134)
    Count = 7
}
```

**Error Handling**:

- Throws if FilePath doesn't exist
- Throws if JokeDatabase is empty
- Adjusts joke count if file has fewer safe lines than MinJokes

---

### 6. Get-DadJokeDatabase

**Purpose**: Return array of 50 dad jokes for test content injection.

**Signature**:

```powershell
function Get-DadJokeDatabase {
    <#
    .SYNOPSIS
        Returns array of dad jokes for test content injection.

    .DESCRIPTION
        Provides embedded database of 50 dad jokes used as distinguishable test content.

    .OUTPUTS
        string[] Array of 50 dad jokes.

    .EXAMPLE
        $jokes = Get-DadJokeDatabase
        # Returns: @("Why don't scientists...", "I'm reading a book...", ...)
    #>
    [CmdletBinding()]
    param()
}
```

**Behavior**:

- Returns static array of 50 dad jokes
- No parameters required
- No external dependencies

**Example Output**:

```powershell
@(
    "Why don't scientists trust atoms? Because they make up everything!",
    "I'm reading a book about anti-gravity. It's impossible to put down!",
    # ... 48 more jokes
)
```

---

### 7. Assert-AllJokesPreserved

**Purpose**: Validate 100% preservation of injected dad jokes after merge (zero tolerance).

**Signature**:

```powershell
function Assert-AllJokesPreserved {
    <#
    .SYNOPSIS
        Validates all dad jokes preserved after merge (zero tolerance).

    .DESCRIPTION
        Checks that every injected dad joke appears in merged file content. Throws
        if any jokes missing (100% preservation required per FR-005).

    .PARAMETER FilePath
        Absolute path to merged file.

    .PARAMETER ExpectedJokes
        Array of dad jokes that were injected before merge.

    .PARAMETER MergedContent
        Content of merged file (read as -Raw string).

    .OUTPUTS
        None (throws on failure, returns nothing on success).

    .EXAMPLE
        $content = Get-Content -Path "merged.md" -Raw
        Assert-AllJokesPreserved -FilePath "merged.md" `
                                  -ExpectedJokes @("Why don't...") `
                                  -MergedContent $content
        # Throws if any jokes missing
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string[]]$ExpectedJokes,

        [Parameter(Mandatory)]
        [string]$MergedContent
    )
}
```

**Behavior**:

- Iterates through ExpectedJokes array
- For each joke, searches MergedContent using regex escape
- Accepts joke in any location (clean merge, conflict markers, moved sections)
- Accumulates missing jokes
- Throws if any jokes missing (zero tolerance per FR-005)

**Error Message Format**:

```powershell
"MERGE FAILURE: 3 dad jokes lost in file.md: Why don't scientists...; I'm reading a book...; Why did the scarecrow..."
```

---

### 8. Test-MergedFileValidity

**Purpose**: Perform 9-point semantic validation on merged file.

**Signature**:

```powershell
function Test-MergedFileValidity {
    <#
    .SYNOPSIS
        Performs 9-point semantic validation on merged file.

    .DESCRIPTION
        Validates merged file for integrity, markdown syntax, required sections,
        conflict markers, and dad joke preservation. Returns detailed results.

    .PARAMETER FilePath
        Absolute path to merged file.

    .PARAMETER OriginalJokes
        Hashtable from Add-DadJokesToFile with Jokes, Locations, Count.

    .OUTPUTS
        hashtable {Valid, Errors, Warnings, JokesFound, JokesExpected}

    .EXAMPLE
        $result = Test-MergedFileValidity -FilePath "merged.md" -OriginalJokes $jokes
        if (-not $result.Valid) {
            Write-Host "Errors: $($result.Errors -join '; ')"
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [hashtable]$OriginalJokes
    )
}
```

**9-Point Validation Checklist**:

1. File integrity (exists, non-empty, reasonable size <10MB)
2. Markdown syntax valid (matched code blocks, no orphaned markers)
3. Front matter validation (YAML structure if present)
4. Required SpecKit sections present
5. Orphaned conflict markers check (start count == end count)
6. Duplicate sections detection
7. Section order logical (basic check only)
8. Dad jokes preservation (100% requirement)
9. No file corruption (valid UTF-8 encoding)

**Return Value**:

```powershell
@{
    Valid = $true  # false if any errors
    Errors = @()   # Critical issues
    Warnings = @('File unusually large: 1.2 MB')
    JokesFound = 67
    JokesExpected = 67
}
```

---

### 9. Test-MergedCommandExecution

**Purpose**: Test command execution readiness with structural validation fallback.

**Signature**:

```powershell
function Test-MergedCommandExecution {
    <#
    .SYNOPSIS
        Tests merged command file for execution readiness.

    .DESCRIPTION
        Validates command structure (front matter, markdown sections, syntax).
        Fallback to structural validation (actual execution not feasible in tests).

    .PARAMETER CommandPath
        Absolute path to merged command file.

    .PARAMETER ProjectRoot
        Test project root directory (for context).

    .OUTPUTS
        hashtable {Executable, StructureValid, ErrorMessage}

    .EXAMPLE
        $result = Test-MergedCommandExecution -CommandPath "speckit.specify.md" -ProjectRoot $testDir
        if ($result.StructureValid) {
            Write-Host "Command structure valid"
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CommandPath,

        [Parameter(Mandatory)]
        [string]$ProjectRoot
    )
}
```

**Behavior**:

- Attempts Option C (actual execution) if Claude Code available (deferred for MVP)
- Falls back to Option A (structural validation):
  - Front matter exists and valid YAML
  - Markdown sections present
  - No unclosed code blocks
- Returns validation results

**Return Value**:

```powershell
@{
    Executable = $false         # Not actually executed
    StructureValid = $true      # Structure validation passed
    ErrorMessage = $null
}
```

---

### 10. Write-E2ETestReport

**Purpose**: Generate comprehensive test report to stdout.

**Signature**:

```powershell
function Write-E2ETestReport {
    <#
    .SYNOPSIS
        Generates comprehensive test report with statistics.

    .DESCRIPTION
        Creates formatted report with summary statistics, per-merge details, and
        aggregate metrics. Writes to stdout for Pester output capture.

    .PARAMETER TestResults
        Array of Test Scenario objects from parallel execution.

    .OUTPUTS
        None (writes formatted report to stdout).

    .EXAMPLE
        Write-E2ETestReport -TestResults $results
        # Outputs formatted report to console
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject[]]$TestResults
    )
}
```

**Report Format**:

```
============================================================
End-to-End Smart Merge Test Report
============================================================

Summary:
  Total Tests: 18
  Passed: 18 (100.0%)
  Failed: 0
  Skipped: 0
  Timeout: 0
  Total Duration: 14m 23s

Dad Joke Preservation:
  Total Injected: 1,234
  Total Preserved: 1,234 (100.0%)
  Data Loss: 0 jokes

Performance:
  Average Merge Time: 42.3s
  Fastest: v0.0.78 → v0.0.79 (28.1s)
  Slowest: v0.0.50 → v0.0.79 (61.2s)

Per-Merge Details:
  [01/18] v0.0.50 → v0.0.79: PASSED (42.3s) - Files: 12, Jokes: 67/67
  [02/18] v0.0.60 → v0.0.75: PASSED (38.7s) - Files: 12, Jokes: 68/68
  ...

============================================================
Result: ALL TESTS PASSED ✓
============================================================
```

---

### 11. Get-MergePairStatistics

**Purpose**: Extract statistics from Test Scenario for reporting.

**Signature**:

```powershell
function Get-MergePairStatistics {
    <#
    .SYNOPSIS
        Extracts statistics from Test Scenario object.

    .DESCRIPTION
        Parses Test Scenario and returns formatted statistics hashtable.

    .PARAMETER TestResult
        Test Scenario object from merge test execution.

    .OUTPUTS
        hashtable {Duration, FilesProcessed, JokesPreserved, ValidationsPassed}

    .EXAMPLE
        $stats = Get-MergePairStatistics -TestResult $scenario
        # Returns: @{Duration=42.3s; FilesProcessed=12; ...}
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$TestResult
    )
}
```

**Return Value**:

```powershell
@{
    Duration = [TimeSpan]::FromSeconds(42.3)
    FilesProcessed = 12
    JokesPreserved = 67
    JokesExpected = 67
    ValidationsPassed = 9
    ValidationsFailed = 0
}
```

---

## Module Exports

```powershell
Export-ModuleMember -Function @(
    'Get-StratifiedVersions',
    'Get-RandomMergePairs',
    'New-E2ETestProject',
    'Install-SpecKitVersion',
    'Add-DadJokesToFile',
    'Get-DadJokeDatabase',
    'Assert-AllJokesPreserved',
    'Test-MergedFileValidity',
    'Test-MergedCommandExecution',
    'Write-E2ETestReport',
    'Get-MergePairStatistics'
)
```

---

## Usage Example

```powershell
# Import module (in test file BeforeAll block)
Import-Module "$PSScriptRoot/../helpers/E2ETestHelpers.psm1" -Force

# Load fingerprints database
$fingerprintsData = Get-Content "data/speckit-fingerprints.json" | ConvertFrom-Json

# Stratify versions
$versions = Get-StratifiedVersions -FingerprintsData $fingerprintsData

# Generate merge pairs
$mergePairs = Get-RandomMergePairs -Versions $versions -Count 18

# Get dad jokes
$dadJokes = Get-DadJokeDatabase

# Execute tests (parallel)
$results = $mergePairs | ForEach-Object -Parallel {
    $helperModulePath = $using:helperModulePath
    Import-Module $helperModulePath -Force

    # Create test project
    $testDir = New-E2ETestProject -Version $_.From -Root $using:testRoot

    # Install SpecKit version
    $installResult = Install-SpecKitVersion -ProjectRoot $testDir -Version $_.From

    # Inject dad jokes
    $jokeResults = @{}
    Get-ChildItem "$testDir/.claude/commands/*.md" | ForEach-Object {
        $jokeResults[$_.FullName] = Add-DadJokesToFile -FilePath $_.FullName -JokeDatabase $using:dadJokes
    }

    # Execute merge (invoke orchestrator)
    # ...

    # Validate results
    $validationResults = Test-MergedFileValidity -FilePath $mergedFile -OriginalJokes $jokeResults

    # Return test scenario
    [PSCustomObject]@{
        SourceVersion = $_.From
        TargetVersion = $_.To
        Status = if ($validationResults.Valid) { 'Completed' } else { 'Failed' }
        ValidationResults = $validationResults
    }
} -ThrottleLimit 4

# Generate report
Write-E2ETestReport -TestResults $results
```

---

## Error Handling Contract

| Function | Error Behavior | Return Type |
|----------|----------------|-------------|
| Get-StratifiedVersions | Throws on invalid input; warns on insufficient versions | string[] |
| Get-RandomMergePairs | Throws on null input; returns fewer if Count > available | PSCustomObject[] |
| New-E2ETestProject | Throws on directory creation failure | string |
| Install-SpecKitVersion | Returns error hashtable (no throw) | hashtable |
| Add-DadJokesToFile | Throws on invalid file path | hashtable |
| Get-DadJokeDatabase | Never throws (static data) | string[] |
| Assert-AllJokesPreserved | Throws if any jokes missing (zero tolerance) | void |
| Test-MergedFileValidity | Never throws (returns validation result) | hashtable |
| Test-MergedCommandExecution | Never throws (returns validation result) | hashtable |
| Write-E2ETestReport | Never throws (writes to stdout) | void |
| Get-MergePairStatistics | Throws on null input | hashtable |

---

## Testing Strategy

**Unit Tests** (`tests/unit/E2ETestHelpers.Tests.ps1`):

- Test each function in isolation with mocked dependencies
- Mock file system operations (New-Item, Get-Content, Set-Content)
- Mock GitHub API calls (mutex, delays)
- Verify deterministic behavior with seed 42
- Test error handling paths

**Integration Tests** (part of `tests/integration/SmartMerge.E2E.Tests.ps1`):

- Validate module functions work together end-to-end
- Use real file system (temporary directories)
- Use real GitHub API (with rate limiting)
- Verify parallel execution behavior

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-10-24 | Initial contract definition |
