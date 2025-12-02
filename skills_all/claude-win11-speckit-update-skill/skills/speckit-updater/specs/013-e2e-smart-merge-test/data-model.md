# Data Model: E2E Smart Merge Test

**Feature**: End-to-End Smart Merge Test with Parallel Execution
**Date**: 2025-10-24
**Purpose**: Define data structures and entities for test infrastructure

---

## Entity Definitions

### 1. Test Scenario

**Purpose**: Represents a single merge test execution from source version to target version.

**Fields**:

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| SourceVersion | string | Starting SpecKit version (e.g., "v0.0.50") | Semantic version with 'v' prefix |
| TargetVersion | string | Target SpecKit version (e.g., "v0.0.79") | Must be > SourceVersion |
| TestDirectory | string | Absolute path to isolated test environment | Unique GUID-based name |
| InjectedJokes | hashtable | Joke content and locations per file | Keys: file paths, Values: joke arrays |
| ValidationResults | hashtable | Output from Test-MergedFileValidity | See Validation Result entity |
| Duration | TimeSpan | Total test execution time | From test start to completion |
| Status | enum | Test outcome | Pending, Running, Validating, Completed, Failed, Timeout, Skipped |
| ErrorMessage | string | Failure reason (if Status = Failed/Timeout) | Null if successful |
| FilesProcessed | int | Count of files that received dad jokes | Typically 8-12 (SpecKit commands) |
| JokesPreserved | int | Count of dad jokes found after merge | Must equal total injected for pass |
| TotalJokes | int | Total dad jokes injected across all files | Sum of all joke arrays |

**State Transitions**:

```
Pending → Running → Validating → {Completed, Failed, Timeout, Skipped}

- Pending: Test created, not yet started
- Running: Test project created, merge executing
- Validating: Merge complete, running validation checks
- Completed: All validations passed
- Failed: Validation failed or error occurred
- Timeout: Test exceeded 5-minute limit
- Skipped: Prerequisite failed (corrupted template, disk space)
```

**Example**:

```powershell
[PSCustomObject]@{
    SourceVersion = 'v0.0.50'
    TargetVersion = 'v0.0.79'
    TestDirectory = 'C:\Temp\test-v0.0.50-a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    InjectedJokes = @{
        '.claude/commands/speckit.specify.md' = @('Why don't scientists...', 'I'm reading a book...')
        '.claude/commands/speckit.plan.md' = @('Why did the scarecrow...')
    }
    ValidationResults = @{
        Valid = $true
        Errors = @()
        Warnings = @('Duplicate sections: Requirements')
        JokesFound = 67
        JokesExpected = 67
    }
    Duration = [TimeSpan]::FromSeconds(42.3)
    Status = 'Completed'
    ErrorMessage = $null
    FilesProcessed = 12
    JokesPreserved = 67
    TotalJokes = 67
}
```

---

### 2. Version Stratification

**Purpose**: Groups SpecKit versions by release timeframe for representative sampling.

**Fields**:

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| VersionList | array | All available versions from fingerprints database | Sorted by release date ascending |
| GroupBoundaries | hashtable | Date cutoffs for old/middle/recent groups | Keys: OldMax, MiddleMax (DateTime) |
| OldGroup | array | Versions in old timeframe (2023-2024 early) | Minimum 3 versions preferred |
| MiddleGroup | array | Versions in middle timeframe (mid-2024) | Minimum 3 versions preferred |
| RecentGroup | array | Versions in recent timeframe (late-2024) | Minimum 4 versions preferred |
| SelectedVersions | array | Final 10 versions selected (3-3-4 distribution) | Deterministic with seed 42 |

**Lifecycle**:

```
1. Load fingerprints database
2. Calculate date boundaries (total range / 3)
3. Group versions by date
4. Randomly select 3-3-4 from groups (seed 42)
5. Return selected versions for merge pair generation
```

**Example**:

```powershell
[PSCustomObject]@{
    VersionList = @('v0.0.1', 'v0.0.2', ..., 'v0.0.79')  # 79 total
    GroupBoundaries = @{
        OldMax = [datetime]'2024-03-15'
        MiddleMax = [datetime]'2024-08-30'
    }
    OldGroup = @('v0.0.1', 'v0.0.5', 'v0.0.12', ...)     # 25 versions
    MiddleGroup = @('v0.0.30', 'v0.0.42', ...)           # 28 versions
    RecentGroup = @('v0.0.60', 'v0.0.79', ...)           # 26 versions
    SelectedVersions = @('v0.0.5', 'v0.0.12', 'v0.0.18',  # Old: 3
                         'v0.0.35', 'v0.0.42', 'v0.0.48', # Middle: 3
                         'v0.0.60', 'v0.0.71', 'v0.0.75', 'v0.0.79')  # Recent: 4
}
```

---

### 3. Dad Joke

**Purpose**: Represents a single piece of test content injected for preservation validation.

**Fields**:

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| Text | string | The joke content | Unique within database (no duplicates) |
| Category | string | Optional grouping (unused in MVP) | Null or empty |
| InsertionPoints | array | File paths and line numbers where joke inserted | Each point: {FilePath, LineNumber} |

**Lifecycle**:

```
1. Selected from database (Get-Random with seed 42)
2. Inserted into file at safe location (Add-DadJokesToFile)
3. Tracked in Test Scenario's InjectedJokes field
4. Validated after merge (Assert-AllJokesPreserved)
```

**Example**:

```powershell
[PSCustomObject]@{
    Text = "Why don't scientists trust atoms? Because they make up everything!"
    Category = $null
    InsertionPoints = @(
        @{ FilePath = '.claude/commands/speckit.specify.md'; LineNumber = 42 }
    )
}
```

**Database Structure**:

```powershell
$script:DadJokes = @(
    "Why don't scientists trust atoms? Because they make up everything!",
    "I'm reading a book about anti-gravity. It's impossible to put down!",
    "Why did the scarecrow win an award? He was outstanding in his field!",
    "I used to be a baker, but I couldn't make enough dough.",
    "What do you call a fake noodle? An impasta!",
    "Why did the bicycle fall over? It was two-tired!",
    # ... 44 more jokes (total 50)
)
```

---

### 4. Merge Pair

**Purpose**: Combination of source and target versions representing a valid upgrade path.

**Fields**:

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| From | string | Source SpecKit version | Semantic version with 'v' prefix |
| To | string | Target SpecKit version | Must be > From |
| IsDiversePath | boolean | True if spans multiple timeframes (old→recent) | Calculated from stratification groups |

**Validation Rules**:

- From must be semantically less than To (e.g., v0.0.50 < v0.0.79)
- Both versions must exist in fingerprints database
- No downgrade pairs (e.g., v0.0.79 → v0.0.50 invalid)

**Generation Algorithm**:

```powershell
# Generate all valid upgrade pairs from 10 selected versions
$allPairs = @()
for ($i = 0; $i -lt $versions.Count; $i++) {
    for ($j = $i + 1; $j -lt $versions.Count; $j++) {
        $v1 = [version]($versions[$i] -replace '^v', '')
        $v2 = [version]($versions[$j] -replace '^v', '')

        if ($v1 -lt $v2) {
            $allPairs += [PSCustomObject]@{ From = $versions[$i]; To = $versions[$j] }
        }
    }
}

# Randomly select 18 pairs (40% of 45 total from C(10,2))
$selectedPairs = $allPairs | Get-Random -Count 18 -SetSeed 42
```

**Example**:

```powershell
[PSCustomObject]@{
    From = 'v0.0.50'
    To = 'v0.0.79'
    IsDiversePath = $true  # Old → Recent
}

[PSCustomObject]@{
    From = 'v0.0.71'
    To = 'v0.0.75'
    IsDiversePath = $false  # Recent → Recent
}
```

---

### 5. Validation Result

**Purpose**: Outcome of post-merge validation including data preservation, semantic correctness, and execution readiness.

**Fields**:

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| Valid | boolean | Overall validation status (true if no errors) | False if any errors present |
| DataPreservationStatus | boolean | True if 100% of dad jokes preserved | Critical failure if false |
| SemanticCorrectnessStatus | boolean | True if markdown syntax valid | Based on 9-point checklist |
| ExecutionReadiness | boolean | True if command structure valid | Fallback structural validation |
| Errors | array | Critical issues that fail test | Empty if Valid = true |
| Warnings | array | Non-critical issues | Informational only |
| JokesFound | int | Count of dad jokes detected after merge | Must equal JokesExpected |
| JokesExpected | int | Count of dad jokes injected before merge | From Test Scenario |

**Aggregate Rules**:

- Valid = (Errors.Count == 0)
- DataPreservationStatus = (JokesFound == JokesExpected)
- Test fails if DataPreservationStatus = false (zero tolerance for data loss)

**Example (Success)**:

```powershell
@{
    Valid = $true
    DataPreservationStatus = $true
    SemanticCorrectnessStatus = $true
    ExecutionReadiness = $true
    Errors = @()
    Warnings = @('File unusually large: 1.2 MB')
    JokesFound = 67
    JokesExpected = 67
}
```

**Example (Failure)**:

```powershell
@{
    Valid = $false
    DataPreservationStatus = $false
    SemanticCorrectnessStatus = $true
    ExecutionReadiness = $true
    Errors = @(
        'Missing 3 dad jokes: Why don't scientists...; I'm reading a book...; Why did the scarecrow...'
    )
    Warnings = @()
    JokesFound = 64
    JokesExpected = 67
}
```

---

### 6. Test Report

**Purpose**: Aggregate data structure containing per-merge statistics and overall metrics.

**Fields**:

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| TotalTests | int | Total merge tests executed | Always 15-20 |
| Passed | int | Tests with Status = Completed | Success count |
| Failed | int | Tests with Status = Failed | Failure count |
| Skipped | int | Tests with Status = Skipped | Skipped count |
| Timeout | int | Tests with Status = Timeout | Timeout count |
| TotalJokes | int | Sum of all dad jokes injected | Across all tests |
| PreservedJokes | int | Sum of all dad jokes preserved | Should equal TotalJokes for 100% success |
| AvgDuration | TimeSpan | Average test execution time | Mean of all durations |
| TotalDuration | TimeSpan | End-to-end suite execution time | From first test start to last completion |
| FastestTest | hashtable | Merge pair with shortest duration | {From, To, Duration} |
| SlowestTest | hashtable | Merge pair with longest duration | {From, To, Duration} |
| PerMergeResults | array | Individual Test Scenario objects | Full detail for each test |

**Relationships**:

- Aggregates data from multiple Test Scenario entities
- Provides summary statistics for reporting
- Includes both aggregate and per-test detail

**Example**:

```powershell
[PSCustomObject]@{
    TotalTests = 18
    Passed = 18
    Failed = 0
    Skipped = 0
    Timeout = 0
    TotalJokes = 1234
    PreservedJokes = 1234
    AvgDuration = [TimeSpan]::FromSeconds(42.3)
    TotalDuration = [TimeSpan]::FromMinutes(14).Add([TimeSpan]::FromSeconds(23))
    FastestTest = @{ From = 'v0.0.78'; To = 'v0.0.79'; Duration = [TimeSpan]::FromSeconds(28.1) }
    SlowestTest = @{ From = 'v0.0.50'; To = 'v0.0.79'; Duration = [TimeSpan]::FromSeconds(61.2) }
    PerMergeResults = @(
        # ... 18 Test Scenario objects
    )
}
```

---

## Entity Relationships

```
Fingerprints Database
        ↓
Version Stratification (selects 10 versions)
        ↓
Merge Pair Generation (creates 18 pairs)
        ↓
Test Scenario (1 per merge pair)
        ├── Dad Jokes (injected into files)
        └── Validation Result (post-merge checks)
        ↓
Test Report (aggregates all scenarios)
```

**Data Flow**:

1. Load fingerprints database → Version Stratification
2. Stratify versions → Generate merge pairs
3. For each merge pair → Create Test Scenario
4. Inject dad jokes → Track in Test Scenario
5. Execute merge → Update Test Scenario status
6. Validate results → Create Validation Result
7. Aggregate all Test Scenarios → Generate Test Report

---

## Storage Considerations

**In-Memory Data**:

- Version Stratification (ephemeral, recalculated each run)
- Merge Pairs (ephemeral, generated from selected versions)
- Test Scenarios (collected in array during parallel execution)
- Test Report (generated at end from collected scenarios)

**File System Data**:

- Fingerprints database: `data/speckit-fingerprints.json` (read-only)
- Test directories: `C:\Temp\test-v{version}-{guid}` (temporary, cleaned up)
- Merged files: Within test directories (validated then deleted)

**No Persistent Storage Required**:

- All test data is ephemeral (regenerated each run)
- Deterministic randomization (seed 42) ensures reproducibility
- No need for test result database (console output sufficient)

---

## Validation Rules Summary

| Entity | Validation | Enforcement |
|--------|------------|-------------|
| Test Scenario | Status transitions valid | State machine in test orchestration |
| Version Stratification | Groups have minimum versions | Warning if < 3 per group |
| Merge Pair | From < To (semantic versioning) | Enforced in pair generation |
| Validation Result | JokesFound == JokesExpected | Critical failure if mismatch |
| Test Report | TotalTests == Passed + Failed + Skipped + Timeout | Validated in report generation |

---

## Next Steps

1. ✅ **Completed**: Data model defined
2. ⏳ **Next**: Generate API contracts (contracts/E2ETestHelpers-contract.md)
3. ⏳ **Next**: Generate quickstart guide (quickstart.md)
