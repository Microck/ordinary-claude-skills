# Phase 1: Data Model & Architecture

**Feature**: Fix Module Function Availability
**Date**: 2025-10-20
**Status**: Complete

## Overview

This document defines the architectural entities and relationships for the nested import fix. While this feature is not data-driven in the traditional sense (no database entities), it involves critical architectural structures that govern module dependencies, lint validation, and testing.

## Architectural Entities

### 1. Module Dependency Graph

**Definition**: Directed acyclic graph (DAG) representing the dependency relationships between PowerShell modules.

**Structure**:
```
┌─────────────────────┐
│   HashUtils.psm1    │  (No dependencies)
│   - Get-NormalizedHash
│   - Compare-FileHashes
└─────────────────────┘
          ▲
          │
┌─────────────────────┐
│ GitHubApiClient.psm1│  (No dependencies)
│ - Get-GitHubRelease
│ - Download-Template
└─────────────────────┘
          ▲
          │
┌─────────────────────┐
│VSCodeIntegration.psm1│ (No dependencies)
│ - Test-VSCodeContext
│ - Invoke-VSCodeMerge
└─────────────────────┘
          │
          ├──────────────┬─────────────────┐
          ▼              ▼                 ▼
┌─────────────────────────────────────────┐
│     ManifestManager.psm1                │
│     Dependencies: HashUtils,            │
│                   GitHubApiClient       │
│     - Get-SpecKitManifest               │
│     - Update-ManifestHashes             │
└─────────────────────────────────────────┘
          ▲
          │
┌─────────────────────────────────────────┐
│      BackupManager.psm1                 │
│      Dependencies: ManifestManager      │
│      - New-Backup                       │
│      - Restore-FromBackup               │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│    ConflictDetector.psm1                │
│    Dependencies: HashUtils,             │
│                  ManifestManager        │
│    - Get-FileState                      │
│    - Test-FileCustomized                │
└─────────────────────────────────────────┘
```

**Import Order** (orchestrator must follow this sequence):
1. **Tier 0** (no dependencies): HashUtils, GitHubApiClient, VSCodeIntegration
2. **Tier 1** (depends on Tier 0): ManifestManager
3. **Tier 2** (depends on Tier 1): BackupManager, ConflictDetector

**Properties**:
- **Acyclic**: No circular dependencies allowed
- **Explicit**: All dependencies documented in orchestrator comments
- **Minimal**: Each module depends only on what it needs
- **Validated**: Lint check ensures no nested imports violate this structure

**Validation Rules**:
- Module in Tier N may only depend on modules in Tier < N
- Modules within same tier have no inter-dependencies
- Orchestrator must import in tier order (0 → 1 → 2)

---

### 2. Module Import Configuration

**Definition**: The canonical import sequence in `scripts/update-orchestrator.ps1` that establishes module availability in orchestrator scope.

**Schema**:
```powershell
# Located at: scripts/update-orchestrator.ps1, lines ~90-110

$modulesPath = Join-Path $PSScriptRoot "modules"

# TIER 0: Foundation modules (no dependencies)
# These must be imported first as other modules depend on them
Import-Module (Join-Path $modulesPath "HashUtils.psm1") -Force -WarningAction SilentlyContinue
Import-Module (Join-Path $modulesPath "GitHubApiClient.psm1") -Force -WarningAction SilentlyContinue
Import-Module (Join-Path $modulesPath "VSCodeIntegration.psm1") -Force -WarningAction SilentlyContinue

# TIER 1: Modules depending on Tier 0
# ManifestManager uses HashUtils.Get-NormalizedHash and GitHubApiClient functions
Import-Module (Join-Path $modulesPath "ManifestManager.psm1") -Force -WarningAction SilentlyContinue

# TIER 2: Modules depending on Tier 1
# BackupManager uses ManifestManager functions
# ConflictDetector uses HashUtils and ManifestManager functions
Import-Module (Join-Path $modulesPath "BackupManager.psm1") -Force -WarningAction SilentlyContinue
Import-Module (Join-Path $modulesPath "ConflictDetector.psm1") -Force -WarningAction SilentlyContinue
```

**Properties**:
- **Flags**:
  - `-Force`: Enables reload if module already imported (development workflow support)
  - `-WarningAction SilentlyContinue`: Suppresses unapproved verb warnings (cosmetic only)
- **Path Resolution**: Uses `Join-Path` for cross-platform compatibility
- **Inline Documentation**: Comments explain tier structure and reasoning

**Maintenance Contract**:
- When adding new module: Determine tier, insert at appropriate location
- When adding dependency: May require tier promotion (document in comments)
- Never add `Import-Module` within module files (enforced by lint check)

---

### 3. Lint Check Integration

**Definition**: Pre-test validation logic in `tests/test-runner.ps1` that enforces the no-nested-imports rule automatically.

**Components**:

#### Test-ModuleImportCompliance Function

**Signature**:
```powershell
function Test-ModuleImportCompliance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModulesPath
    )
    # Returns: $true if compliant, $false if violations found
}
```

**Algorithm**:
1. Enumerate all `.psm1` files in `$ModulesPath`
2. For each file:
   - Read content
   - Search for regex pattern: `^\s*Import-Module\s` (case-insensitive, multiline)
   - If found, record file name, line number, and violating statement
3. If violations found:
   - Output detailed error message with file paths and line numbers
   - Reference constitution document
   - Return `$false`
4. If no violations:
   - Output success message
   - Return `$true`

**Error Output Format**:
```
Module import compliance check FAILED. Found 2 violation(s):
  ManifestManager.psm1:19 - Import-Module (Join-Path $PSScriptRoot "HashUtils.psm1") -Force
  BackupManager.psm1:23 - Import-Module (Join-Path $PSScriptRoot "ManifestManager.psm1") -Force

Modules must NOT import other modules. All imports should be managed by the orchestrator.
See .specify/memory/constitution.md - PowerShell Standards - Module Export Rules
```

**Integration Point**:
```powershell
# In tests/test-runner.ps1, before test execution

Write-Host "`nValidating module import compliance..." -ForegroundColor Cyan
$modulesPath = Join-Path $PSScriptRoot "../scripts/modules"
if (-not (Test-ModuleImportCompliance -ModulesPath $modulesPath)) {
    Write-Error "Lint check failed. Fix violations before running tests."
    exit 1
}
```

**Properties**:
- **Fail-Fast**: Test execution blocked if lint fails
- **Zero False Positives**: Regex pattern matches only actual `Import-Module` statements
- **Actionable Errors**: Developers see exactly which files/lines to fix
- **Performance**: Negligible overhead (< 1 second for 6 modules)

---

### 4. Integration Test Suite

**Definition**: Pester test suite in `tests/integration/ModuleDependencies.Tests.ps1` that validates cross-module function calls work correctly.

**Test Structure**:

```
ModuleDependencies.Tests.ps1
├── BeforeAll: Import all modules in correct order
├── Context: "Module Function Availability"
│   ├── Test: HashUtils functions accessible
│   ├── Test: GitHubApiClient functions accessible
│   ├── Test: VSCodeIntegration functions accessible
│   ├── Test: ManifestManager functions accessible
│   ├── Test: BackupManager functions accessible
│   └── Test: ConflictDetector functions accessible
├── Context: "Cross-Module Function Calls"
│   ├── Test: ManifestManager → HashUtils.Get-NormalizedHash
│   ├── Test: ManifestManager → GitHubApiClient functions
│   ├── Test: BackupManager → ManifestManager functions
│   └── Test: ConflictDetector → HashUtils + ManifestManager functions
└── Context: "Dependency Order Enforcement"
    └── Test: Wrong import order causes clear error (negative test)
```

**Test Categories**:

1. **Scope Availability Tests**: Verify `Get-Command -Module [ModuleName]` returns expected functions
2. **Cross-Module Call Tests**: Invoke functions that internally call other modules' functions
3. **Negative Tests**: Verify meaningful errors when dependencies missing

**Properties**:
- **Isolation**: Each test runs in clean state (BeforeAll handles imports once)
- **Fast Execution**: < 5 seconds for full suite
- **Regression Detection**: Catches scope issues before they reach users
- **Documentation**: Test names serve as living documentation of dependency relationships

---

### 5. Constitution Rule Entity

**Definition**: Formal architectural guideline added to `.specify/memory/constitution.md` that prohibits nested module imports.

**Schema**:
```markdown
### Module Import Rules (Added: 2025-10-20)

**Rule**: Modules MUST NOT import other modules. All module imports MUST be managed by
the orchestrator script.

**Rationale**: Nested `Import-Module` statements create PowerShell scope isolation where
imported functions exist in the module's internal scope but are not accessible to the
calling script. This causes "command not recognized" errors despite successful imports.

**Enforcement**: Automated lint check in `tests/test-runner.ps1` scans all `.psm1` files
and fails test execution if `Import-Module` statements are detected.

**Pattern**:
- ✅ Correct: Orchestrator imports all modules in dependency order
- ❌ Incorrect: Module A imports Module B internally

**Example**:
# ✅ CORRECT: scripts/update-orchestrator.ps1
Import-Module (Join-Path $modulesPath "HashUtils.psm1") -Force
Import-Module (Join-Path $modulesPath "ManifestManager.psm1") -Force

# ❌ INCORRECT: scripts/modules/ManifestManager.psm1
Import-Module (Join-Path $PSScriptRoot "HashUtils.psm1") -Force  # This will cause issues!

**Exception**: None. This rule is absolute.
```

**Properties**:
- **Version**: Part of Constitution v1.1.0 (minor version increment for new principle)
- **Precedence**: Takes precedence over conflicting documentation (per constitution governance)
- **Enforcement Level**: Automated (lint check) + Manual (code review checklist)

---

## Relationships

### Module Dependency Graph → Module Import Configuration
The dependency graph **defines** the required import order. The import configuration **implements** this order in code.

### Lint Check Integration → Module Dependency Graph
The lint check **enforces** that no module violates the dependency graph by creating nested imports.

### Integration Test Suite → Module Dependency Graph
The test suite **validates** that the dependency graph is correctly implemented and functions work across module boundaries.

### Constitution Rule → All Entities
The constitution rule **governs** all entities, providing the architectural rationale and enforcement mechanisms.

## Validation Rules Summary

| Entity | Validation Rule | Enforcement |
|--------|----------------|-------------|
| **Module Dependency Graph** | Must be acyclic (no circular dependencies) | Manual code review |
| **Module Import Configuration** | Must match dependency tier order | Integration tests |
| **Lint Check** | Must detect all `Import-Module` in `.psm1` files | Automated on every test run |
| **Integration Tests** | Must cover all cross-module call paths | Test coverage report |
| **Constitution Rule** | Must be referenced in all relevant docs | PR review checklist |

## Migration from Current State

**Current State** (broken):
- ManifestManager.psm1 contains nested imports (lines 19-21)
- Functions not available in orchestrator scope
- Skill fails with "command not recognized" errors

**Target State** (fixed):
- Zero `.psm1` files contain `Import-Module` statements
- Orchestrator imports all modules with documented tier structure
- Lint check blocks future violations
- Integration tests verify cross-module calls work
- Constitution documents the pattern

**Migration Steps** (to be executed in Phase 2 - Implementation):
1. Audit all 6 modules, remove any `Import-Module` statements
2. Update orchestrator with tiered import structure and inline documentation
3. Add lint check function to test-runner.ps1
4. Create ModuleDependencies.Tests.ps1 integration tests
5. Update constitution with Module Import Rules section
6. Update CLAUDE.md and CONTRIBUTING.md with the pattern
7. Run full test suite to verify all 132 unit tests still pass
8. Run new integration tests to verify cross-module calls work

## Implementation Notes

- **No Database Changes**: This is purely architectural, no data persistence changes
- **No API Contracts**: Internal module architecture only
- **Backward Compatible**: No changes to module function signatures or behavior
- **Zero Downtime**: Fix does not affect deployed skill (users pull updates via Git)
