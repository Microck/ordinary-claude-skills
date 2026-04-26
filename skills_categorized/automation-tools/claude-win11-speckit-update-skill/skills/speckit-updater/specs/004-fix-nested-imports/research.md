# Phase 0: Research Findings

**Feature**: Fix Module Function Availability
**Date**: 2025-10-20
**Status**: Complete

## Overview

This document consolidates research findings for resolving the nested module import issue in PowerShell. Research focused on four key areas: PowerShell module scope mechanics, centralized dependency management patterns, automated lint check implementation, and cross-module integration testing strategies.

## Research Areas

### 1. PowerShell Module Scope Resolution Mechanics

**Research Question**: Why do nested `Import-Module` calls within modules create function availability issues?

**Findings**:

PowerShell modules operate in isolated scopes. When a module (e.g., `ManifestManager.psm1`) contains an `Import-Module` statement, the imported functions are loaded into the **module's internal scope**, not the calling script's scope. This creates a scope hierarchy:

```
Global Scope
└── Orchestrator Script Scope
    └── ManifestManager Module Scope
        └── HashUtils Module Scope (nested import)
            └── Get-NormalizedHash function
```

When the orchestrator calls `Get-NormalizedHash`, PowerShell searches:
1. Orchestrator script scope
2. Parent scopes (global)

It **does not** search child module scopes, so the function is "not recognized" even though it was imported successfully within ManifestManager's scope.

**Decision**: Remove all nested imports. Establish flat import structure where orchestrator imports all modules directly into its scope.

**Rationale**:
- Flat structure makes all module functions available to orchestrator
- Follows PowerShell best practice of explicit dependency declaration
- Prevents scope isolation issues
- Improves debuggability (clear dependency graph in one location)

**Alternatives Considered**:
- **Module manifests (.psd1) with RequiredModules**: Would work but adds complexity (need manifest for each module, PowerShell handles loading automatically). Out of scope for this fix.
- **Global scope imports (-Scope Global)**: Pollutes global namespace, considered anti-pattern. Rejected.
- **Dot-sourcing modules**: Would work but contradicts PowerShell module best practices. Modules should be imported, not dot-sourced. Rejected.

**Reference**: PowerShell Documentation - [about_Scopes](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_scopes), [about_Modules](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_modules)

---

### 2. Centralized Dependency Management Patterns

**Research Question**: What is the best practice for managing module dependencies in PowerShell projects?

**Findings**:

**Pattern: Orchestrator-Managed Dependencies**

In PowerShell projects without module manifests, the standard pattern is:
1. Main entry point (orchestrator) explicitly imports all modules
2. Modules never import other modules
3. Import order established based on dependency graph (dependencies first, dependents after)
4. Use `-Force` flag to handle reload scenarios
5. Document dependency order with inline comments

**Example**:
```powershell
# Dependency order (explicit):
# - HashUtils: no dependencies
# - GitHubApiClient: no dependencies
# - VSCodeIntegration: no dependencies
# - ManifestManager: depends on HashUtils, GitHubApiClient
# - BackupManager: depends on ManifestManager
# - ConflictDetector: depends on HashUtils, ManifestManager

$modulesPath = Join-Path $PSScriptRoot "modules"

# Import foundation modules (no dependencies)
Import-Module (Join-Path $modulesPath "HashUtils.psm1") -Force
Import-Module (Join-Path $modulesPath "GitHubApiClient.psm1") -Force
Import-Module (Join-Path $modulesPath "VSCodeIntegration.psm1") -Force

# Import modules with dependencies
Import-Module (Join-Path $modulesPath "ManifestManager.psm1") -Force
Import-Module (Join-Path $modulesPath "BackupManager.psm1") -Force
Import-Module (Join-Path $modulesPath "ConflictDetector.psm1") -Force
```

**Decision**: Implement orchestrator-managed dependencies pattern with documented import order.

**Rationale**:
- Single source of truth for dependency graph
- Easy to understand and modify
- Works with existing codebase structure
- No additional infrastructure required
- Aligns with PowerShell community practices for script-based projects

**Alternatives Considered**:
- **PSDepend**: External dependency management tool. Overkill for 6 internal modules. Rejected.
- **Module manifests with RequiredModules**: Already noted as out of scope. May be future enhancement.
- **Implicit dependency resolution**: No standard PowerShell mechanism exists. Would require custom loader. Rejected as too complex.

**Reference**: [The PowerShell Best Practices and Style Guide](https://poshcode.gitbook.io/powershell-practice-and-style)

---

### 3. Automated Lint Check Implementation

**Research Question**: How should we implement the lint check in `test-runner.ps1` to detect nested imports automatically?

**Findings**:

**Pattern: Pre-Test Validation Function**

Add a validation function at the start of `test-runner.ps1` that:
1. Scans all `.psm1` files in `scripts/modules/`
2. Searches each file for `Import-Module` statements (case-insensitive)
3. Reports violations with file path and line number
4. Exits with non-zero code if violations found

**Implementation Approach**:
```powershell
function Test-ModuleImportCompliance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModulesPath
    )

    $violations = @()
    $moduleFiles = Get-ChildItem -Path $ModulesPath -Filter "*.psm1"

    foreach ($file in $moduleFiles) {
        $content = Get-Content -Path $file.FullName -Raw
        # Use regex to find Import-Module statements
        $matches = [regex]::Matches($content, '^\s*Import-Module\s', [System.Text.RegularExpressions.RegexOptions]::Multiline -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

        if ($matches.Count -gt 0) {
            # Find line numbers for each match
            $lines = $content -split "`n"
            for ($i = 0; $i < $lines.Count; $i++) {
                if ($lines[$i] -match '^\s*Import-Module\s') {
                    $violations += [PSCustomObject]@{
                        File = $file.Name
                        Line = $i + 1
                        Content = $lines[$i].Trim()
                    }
                }
            }
        }
    }

    if ($violations.Count -gt 0) {
        Write-Error "Module import compliance check FAILED. Found $($violations.Count) violation(s):"
        foreach ($violation in $violations) {
            Write-Error "  $($violation.File):$($violation.Line) - $($violation.Content)"
        }
        Write-Error "`nModules must NOT import other modules. All imports should be managed by the orchestrator."
        Write-Error "See .specify/memory/constitution.md - PowerShell Standards - Module Export Rules"
        return $false
    }

    Write-Host "✓ Module import compliance check passed (no nested imports found)" -ForegroundColor Green
    return $true
}
```

**Integration Point**:
Add to `test-runner.ps1` before test execution:
```powershell
# Validate module import compliance before running tests
Write-Host "`nValidating module import compliance..." -ForegroundColor Cyan
$modulesPath = Join-Path $PSScriptRoot "../scripts/modules"
if (-not (Test-ModuleImportCompliance -ModulesPath $modulesPath)) {
    exit 1
}
```

**Decision**: Implement pre-test validation function with regex-based detection and descriptive error messages.

**Rationale**:
- Runs automatically with every test execution (local and CI)
- Fast (< 1 second for 6 modules)
- Clear error messages guide developers to fix violations
- No external dependencies (pure PowerShell)
- Fail-fast behavior (tests don't run if lint fails)

**Alternatives Considered**:
- **PSScriptAnalyzer custom rule**: Overkill for single check, requires PSScriptAnalyzer configuration. Rejected.
- **Git pre-commit hook**: Local only, doesn't enforce in CI. Insufficient on its own. Rejected as sole solution.
- **Separate lint script**: Would work but adds complexity (another script to remember to run). Integrated approach better.

**Reference**: PowerShell regex documentation, [Write-Error](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/write-error)

---

### 4. Cross-Module Integration Test Strategy

**Research Question**: How should we test that cross-module function calls work after removing nested imports?

**Findings**:

**Pattern: Module Dependency Integration Tests**

Create a new test file `tests/integration/ModuleDependencies.Tests.ps1` that:
1. Imports modules in correct order (simulates orchestrator)
2. Tests each module's ability to call functions from its dependencies
3. Verifies all exported functions are accessible
4. Uses Pester `BeforeAll` block to set up module imports once

**Test Categories**:
- **Scope Availability Tests**: Verify functions are available via `Get-Command -Module`
- **Cross-Module Call Tests**: Verify module A can call module B's functions
- **Dependency Order Tests**: Verify import order matters (wrong order should fail gracefully)

**Implementation Approach**:
```powershell
Describe "Module Dependency Integration Tests" {
    BeforeAll {
        # Import modules in correct order (orchestrator pattern)
        $modulesPath = Join-Path $PSScriptRoot "../../scripts/modules"

        Import-Module (Join-Path $modulesPath "HashUtils.psm1") -Force
        Import-Module (Join-Path $modulesPath "GitHubApiClient.psm1") -Force
        Import-Module (Join-Path $modulesPath "VSCodeIntegration.psm1") -Force
        Import-Module (Join-Path $modulesPath "ManifestManager.psm1") -Force
        Import-Module (Join-Path $modulesPath "BackupManager.psm1") -Force
        Import-Module (Join-Path $modulesPath "ConflictDetector.psm1") -Force
    }

    Context "Module Function Availability" {
        It "All HashUtils functions should be accessible" {
            $commands = Get-Command -Module HashUtils
            $commands.Count | Should -BeGreaterThan 0
            $commands.Name | Should -Contain "Get-NormalizedHash"
        }

        # Repeat for each module...
    }

    Context "Cross-Module Function Calls" {
        It "ManifestManager should be able to call Get-NormalizedHash from HashUtils" {
            # Create a test manifest that triggers hash calculation
            $testFile = New-TemporaryFile
            "test content" | Out-File -FilePath $testFile.FullName

            # This internally calls Get-NormalizedHash
            { Get-NormalizedHash -FilePath $testFile.FullName } | Should -Not -Throw

            Remove-Item $testFile.FullName
        }

        # Add similar tests for other dependency relationships...
    }
}
```

**Decision**: Create dedicated integration test file with scope availability tests and cross-module call tests.

**Rationale**:
- Directly tests the fix objective (module functions accessible after import)
- Catches scope isolation regressions before they reach users
- Documents correct import order in test code
- Fast execution (< 5 seconds for all tests)
- Integrates with existing Pester test suite

**Alternatives Considered**:
- **Manual testing only**: Insufficient, doesn't prevent regressions. Rejected.
- **Unit tests with mocking**: Wouldn't catch real scope issues. Integration tests required.
- **End-to-end orchestrator tests only**: Already exist, but don't specifically target module dependencies. Both needed.

**Reference**: [Pester Documentation](https://pester.dev/docs/quick-start), [Integration Testing Best Practices](https://pester.dev/docs/usage/test-file-structure)

---

## Summary of Decisions

| Decision Point | Chosen Approach | Rationale |
|----------------|----------------|-----------|
| **Module Scope Issue** | Remove nested imports, flat orchestrator-managed structure | Resolves scope isolation, follows PowerShell best practices |
| **Dependency Management** | Document import order in orchestrator with inline comments | Single source of truth, easy to maintain |
| **Lint Check** | Pre-test validation function in test-runner.ps1 with regex detection | Automatic enforcement, fast, clear error messages |
| **Integration Testing** | New ModuleDependencies.Tests.ps1 with scope + cross-call tests | Prevents regressions, documents correct pattern |

## Implementation Readiness

All research complete. No blocking unknowns remain. Ready to proceed to Phase 1 (Design).

**Next Steps**:
1. Create data-model.md documenting module dependency graph
2. Create quickstart.md for manual testing workflow
3. Update agent context with PowerShell module patterns
