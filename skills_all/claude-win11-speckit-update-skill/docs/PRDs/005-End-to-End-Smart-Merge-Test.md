# PRD: End-to-End Smart Merge Test with Parallel Execution

**Status**: Draft
**Created**: 2025-10-24
**GitHub Issue**: [#27](https://github.com/NotMyself/claude-win11-speckit-update-skill/issues/27)
**Target Release**: v0.6.0

---

## Executive Summary

Implement a comprehensive end-to-end test suite that validates the smart merge system across multiple SpecKit versions with strict data preservation guarantees. The test suite will install 10 random SpecKit versions, inject customizations (dad jokes), perform 15-20 cross-version merges, and validate 100% data preservation using parallel execution to complete in under 15 minutes.

**Key Innovation**: Zero-tolerance data loss validation - test fails if ANY user customization is lost during merge, proving the system's reliability.

---

## Problem Statement

### Current Testing Gaps

The existing test suite (`tests/integration/UpdateOrchestrator.Tests.ps1`) has significant gaps:

1. **No cross-version testing**: Tests use mocked templates, not real SpecKit releases
2. **No multi-version scenarios**: Can't validate v0.0.50 → v0.0.79 upgrade paths
3. **No customization preservation validation**: No automated verification that user customizations survive merges
4. **No merge quality metrics**: Can't measure merge success rate, conflict reduction, or data loss
5. **Limited real-world simulation**: Mocked GitHub API doesn't test actual download/extraction logic
6. **Manual testing burden**: Cross-version scenarios require time-consuming manual testing before releases

### Pain Points

- **Regression risk**: Changes to merge logic could break upgrade paths without detection
- **Data loss fear**: No proof that customizations survive complex multi-version merges
- **Time-consuming manual QA**: 30-60 minutes per release to manually test upgrade scenarios
- **Low confidence**: Can't make claims about merge success rates without data

---

## Goals

### Primary Goal
**Automated validation** that the smart merge system preserves **100% of user customizations** across **10 different SpecKit versions** in **under 15 minutes**.

### Secondary Goals
1. **Cross-version coverage**: Test 15-20 random upgrade paths (old → middle, middle → recent, old → recent)
2. **Real-world simulation**: Use actual GitHub releases, not mocked templates
3. **Parallel execution**: Run 4 concurrent tests to complete in 12-15 minutes (vs. 45-60 minutes sequential)
4. **Comprehensive validation**:
   - Exit code success
   - Manifest correctness
   - Data preservation (100% of injected customizations)
   - Markdown syntax validity
   - SpecKit command structure
   - Execution readiness
5. **Detailed reporting**: Per-merge statistics, aggregate metrics, failure diagnostics

---

## Proposed Solution

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. VERSION STRATIFICATION (Deterministic)                       │
│    Load 79 versions from fingerprints.json                      │
│    Group: Old (2023-2024), Middle (mid-2024), Recent (late-2024)│
│    Select 3-4 from each group using seed 42 → 10 versions       │
└─────────────────────────────────────────────────────────────────┘
                               ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. MERGE PAIR GENERATION (Random Upgrades Only)                 │
│    Generate all possible pairs from 10 versions                 │
│    Filter: Keep only upgrade pairs (vOlder → vNewer)            │
│    Randomly select 15-20 pairs using seed 42                    │
└─────────────────────────────────────────────────────────────────┘
                               ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. PARALLEL TEST EXECUTION (4 Threads)                          │
│    For each merge pair:                                         │
│      a. Install source version from GitHub                      │
│      b. Inject 5-10 dad jokes per file (smart placement)        │
│      c. Execute merge via update-orchestrator.ps1               │
│      d. Validate 100% data preservation                         │
│      e. Validate semantic correctness                           │
│      f. Test command execution (with fallback)                  │
│      g. Cleanup test directory                                  │
└─────────────────────────────────────────────────────────────────┘
                               ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. AGGREGATE REPORTING                                          │
│    Summary: 18/18 tests passed                                  │
│    Dad jokes: 1,234 inserted, 1,234 preserved (100%)           │
│    Avg merge time: 42.3 seconds                                 │
│    Total execution: 14 minutes 23 seconds                       │
└─────────────────────────────────────────────────────────────────┘
```

---

## Technical Design

### Component 1: Test Orchestration

**File**: `tests/integration/SmartMerge.E2E.Tests.ps1` (~1000-1200 lines)

**Key Features**:
- Pester 5.x test framework
- ForEach-Object -Parallel for concurrent execution
- ThrottleLimit: 4 (configurable via parameter)
- Deterministic randomness (seed 42) for reproducibility
- ConcurrentBag for thread-safe result collection

**Test Structure**:
```powershell
Describe "End-to-End Smart Merge Test" {
    BeforeAll {
        # Load fingerprints database (79 versions)
        # Stratify into groups (old/middle/recent)
        # Select 10 versions with seed 42
        # Generate 15-20 merge pairs
        # Initialize dad jokes database (~50 jokes)
        # Create temp test root directory
        # Setup progress tracking
    }

    It "Should successfully execute all merge tests in parallel" {
        $results = $mergePairs | ForEach-Object -Parallel {
            # Import modules in parallel context
            # Install source version
            # Inject dad jokes (5-10 per file)
            # Execute merge
            # Validate results (9-point checklist)
            # Cleanup
            # Return result object
        } -ThrottleLimit 4

        # Assert aggregate results
        $failedTests.Count | Should -Be 0
        $totalJokesLost | Should -Be 0  # CRITICAL: Zero tolerance
    }

    AfterAll {
        # Generate detailed report
        # Cleanup temp directories
    }
}
```

### Component 2: Test Helpers Module

**File**: `tests/helpers/E2ETestHelpers.psm1` (~400-500 lines)

**Exported Functions**:

#### New-E2ETestProject
Creates isolated test directory with unique GUID name.

```powershell
function New-E2ETestProject {
    param(
        [string]$Version,
        [string]$Root
    )

    $testDir = Join-Path $Root "test-$Version-$(New-Guid)"
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    return $testDir
}
```

#### Install-SpecKitVersion
Downloads and installs specific SpecKit version from GitHub.

```powershell
function Install-SpecKitVersion {
    param(
        [string]$ProjectRoot,
        [string]$Version
    )

    # Use mutex to prevent API hammering
    $mutex = New-Object System.Threading.Mutex($false, "SpecKitE2EGitHubAPI")

    try {
        $mutex.WaitOne() | Out-Null
        Start-Sleep -Milliseconds 500  # Rate limiting

        # Fetch release from GitHub
        # Download templates
        # Extract to project root
        # Create basic manifest
    }
    finally {
        $mutex.ReleaseMutex()
    }
}
```

#### Add-DadJokesToFile
Injects 5-10 dad jokes into markdown files using smart placement.

```powershell
function Add-DadJokesToFile {
    param(
        [string]$FilePath,
        [int]$MinJokes = 5,
        [int]$MaxJokes = 10,
        [string[]]$JokeDatabase
    )

    # Parse markdown into AST
    # Identify safe insertion points:
    #   - Body paragraphs (YES)
    #   - Headers (NO)
    #   - Code blocks (NO)
    #   - Front matter (NO)
    # Randomly insert jokes at safe points
    # Track insertion locations

    return @{
        Jokes = @("Why don't scientists...", "I'm reading a book...")
        Locations = @(42, 87, 134)
        Count = 7
    }
}
```

#### Assert-AllJokesPreserved
**CRITICAL FUNCTION**: Validates 100% dad joke preservation.

```powershell
function Assert-AllJokesPreserved {
    param(
        [string]$FilePath,
        [string[]]$ExpectedJokes,
        [string]$MergedContent
    )

    $missingJokes = @()
    foreach ($joke in $ExpectedJokes) {
        # Check joke exists in merged content
        # Accept in any location:
        #   - Clean merge location
        #   - Inside conflict markers (<<<<<<< Current)
        #   - Moved with renamed section

        if ($MergedContent -notmatch [regex]::Escape($joke)) {
            $missingJokes += $joke
        }
    }

    if ($missingJokes.Count -gt 0) {
        throw "MERGE FAILURE: $($missingJokes.Count) dad jokes lost in $FilePath"
    }
}
```

#### Test-MergedFileValidity
Performs 9-point semantic validation on merged files.

```powershell
function Test-MergedFileValidity {
    param(
        [string]$FilePath,
        [hashtable]$OriginalJokes
    )

    $errors = @()
    $warnings = @()

    # 1. Markdown syntax validation (CommonMark)
    # 2. File integrity (not empty, reasonable size)
    # 3. Front matter validation (YAML structure)
    # 4. Required SpecKit sections present
    # 5. No orphaned conflict markers (<<<<<< without >>>>>>)
    # 6. No duplicate sections
    # 7. Section order logical
    # 8. Dad jokes preservation (100%)
    # 9. No corruption (malformed markdown)

    return @{
        Valid = ($errors.Count -eq 0)
        Errors = $errors
        Warnings = $warnings
        JokesFound = 8
        JokesExpected = 8
    }
}
```

#### Test-MergedCommandExecution
Tests command execution readiness (Option C with Option A fallback).

```powershell
function Test-MergedCommandExecution {
    param(
        [string]$CommandPath,
        [string]$ProjectRoot
    )

    try {
        # Option C: Try actual command invocation
        if (Test-ClaudeCodeAvailable) {
            return Test-ActualCommandExecution -CommandPath $CommandPath
        }
    }
    catch {
        # Option A: Fallback to structural validation
        return Test-CommandStructure -CommandPath $CommandPath
    }
}

function Test-CommandStructure {
    # Parse command file
    # Validate front matter (YAML)
    # Check required sections exist
    # Validate markdown syntax
    # Return validation results
}
```

#### Write-E2ETestReport
Generates comprehensive test report with statistics.

```powershell
function Write-E2ETestReport {
    param([PSCustomObject[]]$TestResults)

    # Summary section:
    #   - Total tests: 18
    #   - Passed: 18 (100%)
    #   - Total duration: 14m 23s

    # Per-merge details:
    #   - v0.0.50 → v0.0.79: PASSED (42.3s)
    #     Files: 12, Jokes: 67/67 (100%)
    #     Validation: ✓ All checks passed

    # Aggregate statistics:
    #   - Total dad jokes: 1,234
    #   - Preserved: 1,234 (100%)
    #   - Avg merge time: 42.3s
    #   - Fastest: 28.1s (v0.0.78 → v0.0.79)
    #   - Slowest: 61.2s (v0.0.50 → v0.0.79)

    # Failed tests (if any):
    #   - v0.0.55 → v0.0.70: FAILED
    #     Error: 3 dad jokes lost
    #     Files: custom.md (2 jokes), plan.md (1 joke)
}
```

### Component 3: Dad Jokes Database

**Embedded in test file**: ~50 dad jokes for variety

```powershell
$script:DadJokes = @(
    "Why don't scientists trust atoms? Because they make up everything!",
    "I'm reading a book about anti-gravity. It's impossible to put down!",
    "Why did the scarecrow win an award? He was outstanding in his field!",
    "I used to be a baker, but I couldn't make enough dough.",
    "What do you call a fake noodle? An impasta!",
    # ... 45 more jokes
)
```

### Component 4: Version Stratification Logic

```powershell
function Get-StratifiedVersions {
    param(
        [PSCustomObject]$FingerprintsData,
        [int]$Seed = 42,
        [int]$TotalVersions = 10
    )

    # Parse versions with release dates
    $allVersions = $FingerprintsData.versions.PSObject.Properties |
        ForEach-Object {
            [PSCustomObject]@{
                Version = $_.Name
                ReleaseDate = [datetime]$_.Value.release_date
            }
        } | Sort-Object ReleaseDate

    # Determine date ranges
    $oldestDate = $allVersions[0].ReleaseDate
    $newestDate = $allVersions[-1].ReleaseDate
    $rangePerGroup = ($newestDate - $oldestDate).TotalDays / 3

    # Group versions
    $oldGroup = $allVersions | Where-Object {
        ($_.ReleaseDate - $oldestDate).TotalDays -lt $rangePerGroup
    }
    $middleGroup = $allVersions | Where-Object {
        $days = ($_.ReleaseDate - $oldestDate).TotalDays
        $days -ge $rangePerGroup -and $days -lt ($rangePerGroup * 2)
    }
    $recentGroup = $allVersions | Where-Object {
        ($_.ReleaseDate - $oldestDate).TotalDays -ge ($rangePerGroup * 2)
    }

    # Select random versions from each group
    $random = New-Object System.Random($Seed)
    $selectedVersions = @()
    $selectedVersions += $oldGroup | Get-Random -Count 3 -SetSeed $Seed
    $selectedVersions += $middleGroup | Get-Random -Count 3 -SetSeed $Seed
    $selectedVersions += $recentGroup | Get-Random -Count 4 -SetSeed $Seed

    return $selectedVersions | Select-Object -ExpandProperty Version
}
```

### Component 5: Merge Pair Generator

```powershell
function Get-RandomMergePairs {
    param(
        [string[]]$Versions,
        [int]$Count = 18,
        [int]$Seed = 42
    )

    # Generate all possible upgrade pairs
    $allPairs = @()
    for ($i = 0; $i -lt $Versions.Count; $i++) {
        for ($j = $i + 1; $j -lt $Versions.Count; $j++) {
            $v1 = [version]($Versions[$i] -replace '^v', '')
            $v2 = [version]($Versions[$j] -replace '^v', '')

            if ($v1 -lt $v2) {
                $allPairs += [PSCustomObject]@{
                    From = $Versions[$i]
                    To = $Versions[$j]
                }
            }
        }
    }

    # Randomly select pairs
    $random = New-Object System.Random($Seed)
    return $allPairs | Get-Random -Count $Count -SetSeed $Seed
}
```

---

## Implementation Plan

### Phase 1: Core Test Infrastructure (Week 1)
1. Create `tests/helpers/E2ETestHelpers.psm1`
2. Implement version stratification logic
3. Implement merge pair generator
4. Implement dad joke injection
5. Unit test helper functions

### Phase 2: Test Orchestration (Week 2)
1. Create `tests/integration/SmartMerge.E2E.Tests.ps1`
2. Implement parallel execution with ForEach-Object -Parallel
3. Implement result aggregation
4. Add progress tracking
5. Add resource protection (mutex for GitHub API)

### Phase 3: Validation Framework (Week 3)
1. Implement semantic validation (9-point checklist)
2. Implement dad joke preservation validation (100% requirement)
3. Implement execution testing (Option C with Option A fallback)
4. Add detailed error reporting

### Phase 4: Reporting & Integration (Week 4)
1. Implement comprehensive test report generation
2. Update `tests/test-runner.ps1` with `-MaxParallelTests` parameter
3. Update `CONTRIBUTING.md` with E2E test documentation
4. Run full test suite and tune performance
5. CI/CD integration (optional)

---

## Success Metrics

### Critical Requirements (Must Pass)
- ✅ **100% dad joke preservation**: Zero jokes lost across all tests
- ✅ **All tests pass**: Exit code 0 for all 15-20 merge tests
- ✅ **Execution time**: Complete in <15 minutes (parallel mode)
- ✅ **No resource exhaustion**: No API rate limits, memory issues, or disk space problems

### Quality Metrics (Target)
- ✅ **Semantic validation**: 100% of merged files pass 9-point validation
- ✅ **Execution tests**: 100% of commands pass structure/execution tests
- ✅ **Manifest correctness**: 100% of manifests correctly updated
- ✅ **No orphaned conflicts**: 0% files with unresolvable conflict markers

### Performance Metrics
- **Sequential baseline**: 45-60 minutes (1 test at a time)
- **Parallel (4 threads)**: 12-15 minutes (4 tests at a time)
- **Average merge time**: <60 seconds per test
- **GitHub API calls**: <50 total (well under rate limit)

---

## Risks & Mitigations

### Risk 1: GitHub API Rate Limits
**Impact**: High (tests fail if rate limited)
**Probability**: Medium (40+ API calls in 15 minutes)

**Mitigation**:
- Implement mutex for serialized API access
- Add 500ms delay between API calls
- Recommend setting `$env:GITHUB_PAT` for 5000 req/hr limit
- Cache downloaded templates (future enhancement)

### Risk 2: Parallel Execution Race Conditions
**Impact**: High (incorrect test results)
**Probability**: Low (isolated test directories)

**Mitigation**:
- Each test gets unique GUID-based directory
- Use ConcurrentBag for thread-safe result collection
- Use mutex for shared resources (GitHub API)
- Thorough testing of parallel execution logic

### Risk 3: Memory/Disk Exhaustion
**Impact**: Medium (tests fail or slow down)
**Probability**: Low (4 threads × 10 MB each = 40 MB)

**Mitigation**:
- Limit parallel threads to 4 (configurable)
- Cleanup test directories after each test
- Monitor disk space in test root
- Document hardware requirements

### Risk 4: Flaky Tests (Non-Deterministic Failures)
**Impact**: High (CI/CD unreliable)
**Probability**: Medium (network issues, GitHub downtime)

**Mitigation**:
- Use deterministic random seed (42)
- Implement retry logic for GitHub API failures
- Add timeout handling for long-running tests
- Sequential mode for debugging (`-Sequential` flag)

---

## Future Enhancements

### Post-MVP Features (Not in v0.6.0)
1. **Template caching**: Cache downloaded templates to reduce API calls
2. **HTML report generation**: Rich HTML report with charts and graphs
3. **Conflict injection testing**: Deliberately create conflicts to test resolution
4. **Performance benchmarking**: Track merge performance across versions
5. **CI/CD integration**: Run on every PR via GitHub Actions
6. **Configurable joke count**: Allow users to specify joke insertion density
7. **Custom validation rules**: Plugin system for custom validation checks

---

## Dependencies

### External Dependencies
- Pester 5.x (test framework)
- PowerShell 7.0+ (ForEach-Object -Parallel support)
- GitHub API (public, no auth required for 60 req/hr)
- Internet connection (to download SpecKit releases)

### Internal Dependencies
- `data/speckit-fingerprints.json` (version database)
- `scripts/update-orchestrator.ps1` (system under test)
- All modules in `scripts/modules/` (HashUtils, ManifestManager, etc.)

---

## Acceptance Criteria

### Test Implementation
- [ ] `tests/integration/SmartMerge.E2E.Tests.ps1` created and passing
- [ ] `tests/helpers/E2ETestHelpers.psm1` created with all helper functions
- [ ] Test executes 15-20 merge scenarios in parallel
- [ ] Deterministic version selection (seed 42)
- [ ] Dad joke injection working (5-10 per file)

### Validation
- [ ] 100% dad joke preservation validated
- [ ] 9-point semantic validation implemented
- [ ] Execution testing with fallback working
- [ ] All tests pass with exit code 0

### Reporting
- [ ] Comprehensive report generated after test run
- [ ] Per-merge statistics displayed
- [ ] Aggregate metrics calculated
- [ ] Failed tests clearly identified

### Performance
- [ ] Test completes in <15 minutes (4 parallel threads)
- [ ] No GitHub API rate limit issues
- [ ] No memory or disk exhaustion
- [ ] Progress tracking visible during execution

### Documentation
- [ ] `CONTRIBUTING.md` updated with E2E test instructions
- [ ] Test execution examples provided
- [ ] Troubleshooting guide added
- [ ] Hardware requirements documented

---

## Open Questions

1. **Should we cache SpecKit templates locally?** (reduces API calls but increases disk usage)
2. **What's the retry strategy for GitHub API failures?** (3 retries with exponential backoff?)
3. **Should we publish test reports to GitHub Pages?** (for historical tracking)
4. **Do we need Windows/Linux/macOS test coverage?** (currently Windows-only)
5. **Should we test downgrade scenarios?** (currently only upgrades)

---

## Timeline

**Target Release**: v0.6.0
**Estimated Duration**: 4 weeks (1 week per phase)

**Milestones**:
- Week 1: Core infrastructure complete
- Week 2: Test orchestration complete
- Week 3: Validation framework complete
- Week 4: Reporting and documentation complete

**Review Points**:
- Week 2: Architecture review and parallel execution validation
- Week 4: Full test suite review and performance tuning
