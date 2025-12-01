# Implementation Plan: End-to-End Smart Merge Test with Parallel Execution

**Branch**: `013-e2e-smart-merge-test` | **Date**: 2025-10-24 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/013-e2e-smart-merge-test/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement a comprehensive end-to-end test suite that validates the smart merge system across multiple SpecKit versions with parallel execution. The system will select 10 stratified SpecKit versions, generate 15-20 upgrade pairs, inject distinguishable test content (dad jokes), execute merges in parallel (4 threads), and validate 100% data preservation with zero tolerance for loss. Critical requirements include <15 minute execution time, fail-fast error handling, and comprehensive reporting with per-merge and aggregate statistics.

**Technical Approach**: Build a Pester 5.x test suite using ForEach-Object -Parallel for concurrent execution, with a dedicated E2ETestHelpers.psm1 module containing business logic for version stratification, test project creation, content injection, validation, and reporting. Use deterministic randomization (seed 42) for reproducible results and automatic thread-safe result aggregation (ForEach-Object -Parallel automatically collects returned objects).

## Technical Context

**Language/Version**: PowerShell 7.0+ (required for ForEach-Object -Parallel support)
**Primary Dependencies**: Pester 5.x (test framework), existing modules (HashUtils, ManifestManager, GitHubApiClient, ConflictDetector, MarkdownMerger)
**Storage**: File system (temporary test directories, downloaded templates, fingerprints database at `data/speckit-fingerprints.json`)
**Testing**: Pester 5.x for test orchestration; meta-consideration: this IS the test infrastructure
**Target Platform**: Windows PowerShell 7.0+ (primary), cross-platform support nice-to-have
**Project Type**: Single project (test infrastructure extension)
**Performance Goals**: Complete 15-20 merge tests in <15 minutes (4 parallel threads), average <60 seconds per test, <50 total GitHub API calls
**Constraints**: GitHub API rate limit (60 req/hr unauthenticated, 5,000 with token), 5-minute individual test timeout, 100MB minimum disk space threshold, 4GB RAM minimum for parallel execution
**Scale/Scope**: 10 SpecKit versions stratified across timeframes, 15-20 upgrade pairs, ~1,234 test content insertions across all tests, ~40MB temporary storage (4 threads × 10MB each)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### ✅ Principle I: Modular Architecture

**Compliance**: Business logic will be implemented in `tests/helpers/E2ETestHelpers.psm1` module with clear separation:

- **Module functions** (E2ETestHelpers.psm1): Version stratification, test project creation, dad joke injection, validation logic, report generation
- **Test orchestration** (SmartMerge.E2E.Tests.ps1): Pester test structure, parallel execution coordination, result aggregation

**Rationale**: Separates reusable test infrastructure (helpers module) from test-specific orchestration (Pester file), enabling unit testing of helper functions.

### ✅ Principle II: Fail-Fast with Rollback

**Compliance**: Test suite implements fail-fast strategy with graceful degradation:

- GitHub API failures: Fail immediately, mark test as failed, continue with remaining tests (FR-016)
- Disk space exhaustion: Pre-test validation, fail gracefully with cleanup if <100MB (FR-017)
- Test timeouts: Terminate after 5 minutes, capture logs, continue (FR-018)
- Corrupted templates: Validate integrity, skip test, continue (FR-019)
- Missing fingerprints database: Halt entire suite with clear error (FR-020)

**Rationale**: Each test is isolated; individual test failures don't prevent validation of other version pairs. Cleanup ensures no resource leaks.

### ✅ Principle III: Customization Detection via Normalized Hashing

**Compliance**: Test suite validates the existing normalized hashing mechanism by:

- Injecting known test content (dad jokes) into files
- Executing merge operations via `update-orchestrator.ps1` (which uses HashUtils.psm1)
- Validating 100% preservation of injected content using string matching

**Rationale**: This principle is part of the system under test, not the test infrastructure itself. Tests validate the principle is correctly implemented.

### N/A Principle IV: User Confirmation Required

**Not Applicable**: Test suite is fully automated with no user interaction. Tests invoke `update-orchestrator.ps1` in automated mode (not requiring prompts).

### ✅ Principle V: Testing Discipline

**Compliance**: This feature IS test infrastructure. Meta-testing considerations:

- Helper module functions (E2ETestHelpers.psm1) will have unit tests in `tests/unit/E2ETestHelpers.Tests.ps1`
- Integration test (SmartMerge.E2E.Tests.ps1) validates end-to-end workflow
- Test data: Uses real SpecKit releases from GitHub (not mocked), fingerprints database as test fixture

**Rationale**: Even test infrastructure needs tests. Helper functions for version selection, content injection, and validation are complex enough to warrant unit testing.

### ✅ Principle VI: Architectural Verification Before Suggestions

**Compliance**: Implementation respects PowerShell subprocess constraints:

- No GUI dependencies (Pester runs headless)
- Text-only I/O (test output via Write-Host/Write-Output)
- No VSCode extension API calls from tests
- File-based communication (writes test reports to files, generates summary to stdout)

**Rationale**: Test suite runs in CI/CD contexts where GUI is unavailable. Must work in headless environments.

### ✅ PowerShell Standards: Code Style

**Compliance**: All code follows established conventions:

- Functions: PascalCase with approved verbs (New-E2ETestProject, Add-DadJokesToFile, Assert-AllJokesPreserved)
- Variables: camelCase ($testDir, $mergePairs, $dadJokes)
- Parameters: PascalCase with type annotations
- Comment-based help: All exported functions include .SYNOPSIS, .DESCRIPTION, .PARAMETER, .EXAMPLE

### ✅ PowerShell Standards: Module Export Rules

**Compliance**: E2ETestHelpers.psm1 will:

- Use [CmdletBinding()] on all exported functions
- Explicitly export functions via Export-ModuleMember -Function
- Include module-level documentation

### ✅ PowerShell Standards: Module Import Rules

**Compliance**: E2ETestHelpers.psm1 MUST NOT import other modules.

**Import Strategy**:

```powershell
# SmartMerge.E2E.Tests.ps1 (test file manages imports)

BeforeAll {
    # Import helper module in test context
    Import-Module "$PSScriptRoot/../helpers/E2ETestHelpers.psm1" -Force

    # Load fingerprints database (no module import needed)
    $fingerprintsData = Get-Content "$repoRoot/data/speckit-fingerprints.json" | ConvertFrom-Json
}
```

**Rationale**: Test file controls all module imports; helper module remains dependency-free.

### Constitution Compliance Summary

- ✅ All applicable principles satisfied
- ✅ No violations requiring complexity tracking
- ✅ Architecture aligns with existing codebase patterns

## Project Structure

### Documentation (this feature)

```
specs/013-e2e-smart-merge-test/
├── spec.md              # Feature specification (completed)
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output: parallel execution patterns, test strategies
├── data-model.md        # Phase 1 output: test entities and validation logic
├── quickstart.md        # Phase 1 output: running E2E tests, interpreting results
├── contracts/           # Phase 1 output: helper module API contracts
│   └── E2ETestHelpers-contract.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```
tests/
├── helpers/
│   └── E2ETestHelpers.psm1        # NEW: Helper module with business logic
│       ├── Version Stratification: Get-StratifiedVersions
│       ├── Project Management: New-E2ETestProject, Install-SpecKitVersion
│       ├── Content Injection: Add-DadJokesToFile, Get-DadJokeDatabase
│       ├── Validation: Assert-AllJokesPreserved, Test-MergedFileValidity
│       ├── Execution Testing: Test-MergedCommandExecution, Test-CommandStructure
│       └── Reporting: Write-E2ETestReport, Get-MergePairStatistics
│
├── integration/
│   └── SmartMerge.E2E.Tests.ps1   # NEW: Main test orchestration
│       ├── BeforeAll: Load database, select versions, generate pairs
│       ├── Test: Parallel execution with ForEach-Object -Parallel
│       └── AfterAll: Generate report, cleanup
│
└── unit/
    └── E2ETestHelpers.Tests.ps1   # NEW: Unit tests for helper functions

data/
└── speckit-fingerprints.json      # EXISTING: Version database (no changes)

scripts/
└── update-orchestrator.ps1        # EXISTING: System under test (no changes)
```

**Structure Decision**: Single project structure (Option 1) as this feature extends the existing test infrastructure. New test files and helper module integrate into established `tests/` hierarchy. No backend/frontend split or platform-specific code required.

**File Organization Rationale**:

- **tests/helpers/**: Modules with reusable test utilities (follows existing pattern)
- **tests/integration/**: End-to-end workflow tests (follows existing pattern)
- **tests/unit/**: Module-level unit tests (follows existing pattern)
- **data/**: Static data fixtures (fingerprints database already exists here)

## Complexity Tracking

*No violations detected - this section is empty.*

All constitution principles are satisfied without requiring exceptions or complexity justifications.

---

## Phase 0: Research & Design Decisions

### Research Topics

1. **Parallel Test Execution in Pester 5.x**
   - Decision needed: Best practices for ForEach-Object -Parallel in Pester context
   - Decision needed: Thread-safe result collection patterns (ConcurrentBag usage)
   - Decision needed: Progress tracking with parallel execution

2. **GitHub API Rate Limiting**
   - Decision needed: Mutex-based serialization pattern for parallel API calls
   - Decision needed: Rate limit detection and handling strategies
   - Decision needed: Optimal delay between API calls (currently: 500ms)

3. **Dad Joke Injection Strategy**
   - Decision needed: Safe insertion points in markdown files (avoid headers, code blocks, front matter)
   - Decision needed: Markdown AST parsing vs regex-based approach
   - Decision needed: Joke distribution algorithm (5-10 per file)

4. **Version Stratification Algorithm**
   - Decision needed: Date-based grouping logic (old/middle/recent boundaries)
   - Decision needed: Random selection with fixed seed (reproducibility)
   - Decision needed: Minimum versions per group to ensure diversity

5. **Test Validation Strategies**
   - Decision needed: 9-point semantic validation checklist definition
   - Decision needed: Command execution testing with fallback mechanism
   - Decision needed: Conflict marker detection patterns

6. **Test Cleanup and Resource Management**
   - Decision needed: Cleanup timing (after each test vs. end of suite)
   - Decision needed: Disk space monitoring approach
   - Decision needed: Error state cleanup (ensure no orphaned processes/files)

### Output Artifact

**File**: `specs/013-e2e-smart-merge-test/research.md`

**Contents**: Documented decisions for each research topic with:
- Selected approach
- Rationale
- Alternatives considered
- Code examples/pseudocode
- References to relevant PowerShell documentation or Stack Overflow discussions

---

## Phase 1: Data Model & Contracts

### Data Model

**File**: `specs/013-e2e-smart-merge-test/data-model.md`

**Entities to Define**:

1. **Test Scenario**
   - Fields: SourceVersion, TargetVersion, TestDirectory, InjectedJokes, ValidationResults, Duration, Status
   - State transitions: Pending → Running → Validating → Completed/Failed/Timeout/Skipped

2. **Version Stratification**
   - Fields: VersionList, GroupBoundaries (OldMax, MiddleMax), SelectedVersions
   - Relationships: Produces list of versions for merge pair generation

3. **Dad Joke**
   - Fields: Text, Category (optional), InsertionPoints (file path + line number)
   - Lifecycle: Selected from database → Inserted into file → Validated after merge

4. **Merge Pair**
   - Fields: FromVersion, ToVersion, IsDiversePath (old→recent indicator)
   - Validation rules: FromVersion < ToVersion (semantic versioning)

5. **Validation Result**
   - Fields: DataPreservationStatus, SemanticCorrectnessStatus, ExecutionReadiness, Errors, Warnings
   - Aggregate rules: Status = Failed if any component fails

6. **Test Report**
   - Fields: TotalTests, Passed, Failed, Skipped, Timeout, TotalJokes, PreservedJokes, AvgDuration, TotalDuration
   - Relationships: Aggregates multiple TestScenario results

### API Contracts

**File**: `specs/013-e2e-smart-merge-test/contracts/E2ETestHelpers-contract.md`

**Exported Functions** (with signatures):

```powershell
# Version Stratification
function Get-StratifiedVersions {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$FingerprintsData,

        [int]$Seed = 42,
        [int]$TotalVersions = 10
    )
    # Returns: [string[]] Array of version strings (e.g., "v0.0.50", "v0.0.79")
}

# Merge Pair Generation
function Get-RandomMergePairs {
    param(
        [Parameter(Mandatory)]
        [string[]]$Versions,

        [int]$Count = 18,
        [int]$Seed = 42
    )
    # Returns: [PSCustomObject[]] Array of {From, To} objects
}

# Test Project Management
function New-E2ETestProject {
    param(
        [Parameter(Mandatory)]
        [string]$Version,

        [Parameter(Mandatory)]
        [string]$Root
    )
    # Returns: [string] Path to created test directory
}

function Install-SpecKitVersion {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot,

        [Parameter(Mandatory)]
        [string]$Version
    )
    # Returns: [hashtable] {Success, TemplatePath, ErrorMessage}
}

# Content Injection
function Add-DadJokesToFile {
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [int]$MinJokes = 5,
        [int]$MaxJokes = 10,

        [Parameter(Mandatory)]
        [string[]]$JokeDatabase
    )
    # Returns: [hashtable] {Jokes, Locations, Count}
}

function Get-DadJokeDatabase {
    # Returns: [string[]] Array of 50 dad jokes
}

# Validation
function Assert-AllJokesPreserved {
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string[]]$ExpectedJokes,

        [Parameter(Mandatory)]
        [string]$MergedContent
    )
    # Throws if any jokes missing; returns nothing on success
}

function Test-MergedFileValidity {
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [hashtable]$OriginalJokes
    )
    # Returns: [hashtable] {Valid, Errors, Warnings, JokesFound, JokesExpected}
}

function Test-MergedCommandExecution {
    param(
        [Parameter(Mandatory)]
        [string]$CommandPath,

        [Parameter(Mandatory)]
        [string]$ProjectRoot
    )
    # Returns: [hashtable] {Executable, StructureValid, ErrorMessage}
}

# Reporting
function Write-E2ETestReport {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject[]]$TestResults
    )
    # Writes formatted report to stdout; returns nothing
}

function Get-MergePairStatistics {
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$TestResult
    )
    # Returns: [hashtable] {Duration, FilesProcessed, JokesPreserved, ValidationsPassed}
}
```

### Quickstart Guide

**File**: `specs/013-e2e-smart-merge-test/quickstart.md`

**Contents**:

1. **Running the E2E Test Suite**
   ```powershell
   # Run all E2E tests with default parallelism (4 threads)
   Invoke-Pester -Path tests/integration/SmartMerge.E2E.Tests.ps1

   # Run with custom parallelism
   Invoke-Pester -Path tests/integration/SmartMerge.E2E.Tests.ps1 -MaxParallelTests 2

   # Run with GitHub token to avoid rate limits
   $env:GITHUB_PAT = "ghp_YOUR_TOKEN_HERE"
   Invoke-Pester -Path tests/integration/SmartMerge.E2E.Tests.ps1
   ```

2. **Interpreting Test Results**
   - Understanding the test report format
   - Identifying failure types (timeout, API failure, data loss, corruption)
   - Debugging failed tests (log locations, artifact preservation)

3. **Common Issues and Troubleshooting**
   - GitHub API rate limiting
   - Disk space exhaustion
   - Test timeouts
   - Fingerprints database issues

4. **Performance Tuning**
   - Adjusting parallel thread count
   - Configuring test timeout
   - Reducing test count for faster feedback

---

## Phase 2: Task Generation (Deferred to /speckit.tasks)

Task breakdown and implementation sequencing will be generated by the `/speckit.tasks` command. This plan provides the necessary design artifacts (research, data model, contracts, quickstart) for task generation.

---

## Next Steps

1. ✅ **Completed**: Specification created and validated
2. ✅ **Completed**: Clarifications resolved (5 edge cases)
3. ✅ **In Progress**: Implementation plan created (this file)
4. ⏳ **Next**: Execute Phase 0 research (generate research.md)
5. ⏳ **Next**: Execute Phase 1 design (generate data-model.md, contracts, quickstart.md)
6. ⏳ **Next**: Run `/speckit.tasks` to generate task breakdown and implementation plan

---

## Validation Checklist

- [x] Constitution check passed (all principles satisfied)
- [x] Technical context complete (no NEEDS CLARIFICATION markers)
- [x] Project structure defined (single project, tests/ hierarchy)
- [x] Research topics identified (6 decision points)
- [x] Data model entities defined (6 entities)
- [x] API contracts outlined (8 exported functions)
- [ ] Phase 0 research completed (research.md generated)
- [ ] Phase 1 design completed (data-model.md, contracts/, quickstart.md generated)
- [ ] Agent context updated (after Phase 1)
