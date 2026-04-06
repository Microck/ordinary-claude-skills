# Research: Complete Parameter Standardization

**Feature**: 006-fix-manifest-parameter
**Date**: 2025-10-20
**Purpose**: Resolve technical unknowns and establish patterns for parameter standardization

## Overview

This document consolidates research findings for implementing comprehensive parameter standardization across the PowerShell codebase. The research covers parameter naming conventions, automated analysis techniques, refactoring patterns, and testing strategies.

## Research Topics

### 1. PowerShell Parameter Naming Best Practices

**Question**: What are the official PowerShell parameter naming standards and conventions?

**Decision**: Follow PowerShell approved parameter naming conventions

**Rationale**:
- PowerShell has well-established naming conventions documented in official style guides
- Consistency with PowerShell ecosystem improves readability and reduces cognitive load
- Standard parameter names enable IntelliSense and auto-completion

**Key Findings**:

**Parameter Naming Rules**:
1. **PascalCase** for all parameters (e.g., `-Path`, `-FilePath`, `-Version`, `-Force`)
2. **Singular nouns** preferred unless collection is semantically important (e.g., `-File` not `-Files`, but `-Paths` acceptable for arrays)
3. **Descriptive** - parameter name should clearly indicate purpose
4. **No abbreviations** unless extremely common (e.g., `-Id` acceptable, `-Usr` not acceptable)
5. **Consistent suffixes**:
   - `-Path` for file paths
   - `-Name` for identifiers/labels
   - `-Object` for object instances
   - `-Type` for type specifications

**Common Standard Parameters** (from PowerShell Common Parameters):
- `-Verbose` - detailed output
- `-Debug` - debugging information
- `-ErrorAction` - error handling behavior
- `-WarningAction` - warning handling behavior
- `-InformationAction` - information message handling
- `-ErrorVariable` - error variable name
- `-WarningVariable` - warning variable name
- `-OutVariable` - output variable name
- `-OutBuffer` - output buffering
- `-WhatIf` - simulation mode
- `-Confirm` - confirmation prompt

**Approved Verbs**:
PowerShell cmdlets follow approved verb-noun naming (e.g., `Get-Process`, `Set-Variable`). Common approved verbs:
- `Get-` - retrieve data
- `Set-` - establish data
- `New-` - create something
- `Remove-` - delete something
- `Invoke-` - perform an action
- `Test-` - verify a condition
- `Update-` - refresh or modify
- `Add-` - append to collection
- `Clear-` - remove all items

**Domain-Specific Parameters for This Codebase**:
- `-Version` - SpecKit version (not `-SpecKitVersion`)
- `-Path` - generic file path
- `-FilePath` - specific file path when ambiguity exists
- `-ProjectRoot` - root directory of project
- `-ManifestPath` - path to manifest.json
- `-BackupPath` - path to backup directory
- `-Force` - bypass confirmations/overwrite
- `-CheckOnly` - dry-run mode (custom to this skill)
- `-AssumeAllCustomized` - treat all files as customized (custom to this skill)
- `-Rollback` - trigger rollback operation (custom to this skill)

**Sources**:
- [PowerShell Practice and Style Guide](https://poshcode.gitbook.io/powershell-practice-and-style/)
- [PowerShell Approved Verbs](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands)
- [PowerShell Style Guide - Parameter Naming](https://github.com/PoshCode/PowerShellPracticeAndStyle/blob/master/Style-Guide/Code-Layout-and-Formatting.md#parameter-names)

**Alternatives Considered**:
- **camelCase** - Rejected: Not PowerShell convention
- **snake_case** - Rejected: Not PowerShell convention
- **Custom abbreviation scheme** - Rejected: Reduces readability, inconsistent with ecosystem

---

### 2. PowerShell AST (Abstract Syntax Tree) for Code Analysis

**Question**: How can we programmatically analyze PowerShell code to detect all parameters and their usages?

**Decision**: Use PowerShell AST API for static code analysis

**Rationale**:
- AST parsing is built into PowerShell 3.0+ (no external dependencies)
- Provides accurate syntax tree representation of code structure
- Can detect function definitions, parameter declarations, and function calls
- More reliable than regex-based parsing for complex code

**Key Findings**:

**AST Basics**:
```powershell
# Parse a PowerShell script file
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $filePath,
    [ref]$null,
    [ref]$null
)

# Find all function definitions
$functions = $ast.FindAll({
    $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
}, $true)

# Extract parameters from function
foreach ($func in $functions) {
    $params = $func.Body.ParamBlock.Parameters
    foreach ($param in $params) {
        $paramName = $param.Name.VariablePath.UserPath
        $paramType = $param.StaticType
        # Analyze parameter...
    }
}
```

**Finding Function Calls**:
```powershell
# Find all command/function calls
$commands = $ast.FindAll({
    $args[0] -is [System.Management.Automation.Language.CommandAst]
}, $true)

# Extract parameters passed to commands
foreach ($cmd in $commands) {
    $cmdName = $cmd.CommandElements[0].Value
    $cmdParams = $cmd.CommandElements | Where-Object {
        $_ -is [System.Management.Automation.Language.CommandParameterAst]
    }
    foreach ($param in $cmdParams) {
        $paramName = $param.ParameterName
        # Analyze parameter usage...
    }
}
```

**Audit Tool Implementation Strategy**:
1. **Scan Phase**: Parse all `.ps1` and `.psm1` files in scripts/
2. **Extract Phase**: Find all function definitions and extract parameter declarations
3. **Validate Phase**: Compare against parameter naming standard
4. **Report Phase**: Generate JSON and markdown reports with violations
5. **CI/CD Integration**: Exit code 0 if compliant, 1 if violations found

**Sources**:
- [PowerShell AST Documentation](https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.language)
- [Working with PowerShell AST](https://devblogs.microsoft.com/powershell/powershell-the-many-ways-to-use-the-ast/)
- [AST-based Script Analysis](https://powershellexplained.com/2017-05-18-Powershell-reading-and-saving-data-to-files/)

**Alternatives Considered**:
- **Regex parsing** - Rejected: Fragile for complex PowerShell syntax (here-strings, splatting, etc.)
- **PSScriptAnalyzer custom rules** - Rejected: Higher complexity for initial implementation, but viable for future enhancement
- **Manual code review** - Rejected: Not scalable, error-prone

---

### 3. Parameter Refactoring Patterns and Risks

**Question**: What are the best practices for refactoring parameters across a codebase without breaking functionality?

**Decision**: Systematic refactoring with comprehensive test coverage

**Rationale**:
- Parameters are deeply interconnected (signatures must match call sites)
- PowerShell is dynamically typed, so compile-time checks won't catch mismatches
- Test suite is critical safety net for detecting breakage

**Key Findings**:

**Refactoring Workflow**:
1. **Baseline**: Run all tests, document current coverage percentage
2. **Audit**: Run parameter audit tool to identify all inconsistencies
3. **Prioritize**: Fix P1 bug (New-SpecKitManifest) first to unblock users
4. **Module-by-Module Refactoring** (within all-at-once release):
   - Refactor function signature in module
   - Update comment-based help `.PARAMETER` documentation
   - Update verbose/error messages using the parameter
   - Update all call sites in orchestrator, helpers, and other modules
   - Run unit tests for that module
   - Run integration tests for affected workflows
5. **Final Validation**: Run full test suite, manual testing checklist
6. **Re-audit**: Run parameter audit tool to verify 100% compliance

**Common Refactoring Pitfalls**:
- **Parameter splatting**: `@params` hashtable keys must match new parameter names
- **Dynamic parameters**: Rare in this codebase, but be aware
- **Positional parameters**: Ensure order preserved if relying on positional binding
- **Pipeline parameters**: `ValueFromPipeline` and `ValueFromPipelineByPropertyName` attributes must match
- **Mandatory vs optional**: Changing parameter attributes can break backwards compatibility

**Recommended Test Expansion Strategy**:
```powershell
# Before refactoring: Baseline coverage
./tests/test-runner.ps1 -Coverage
# Target: 90%+

# Add tests for:
1. All refactored function signatures (parameter binding tests)
2. Cross-module function calls (integration tests)
3. Error path coverage (null/invalid parameters)
4. Splatting scenarios (if used in codebase)
5. Manual testing checklist:
   - First-time update (no manifest)
   - Existing update (with manifest)
   - Conflict resolution workflow
   - Rollback workflow
   - Check-only mode
   - Force mode
```

**Sources**:
- [Refactoring PowerShell Code](https://powershellexplained.com/2017-01-13-Refactoring-powershell/)
- [PowerShell Testing Best Practices](https://poshcode.gitbook.io/powershell-practice-and-style/testing)
- [Pester Code Coverage](https://pester.dev/docs/usage/code-coverage)

**Alternatives Considered**:
- **Parameter aliases** - Rejected: Adds complexity, doesn't eliminate inconsistency
- **Gradual deprecation** - Rejected: User input specified all-at-once approach
- **Automatic refactoring tool** - Considered for future: Could build AST-based automatic renamer

---

### 4. Pester Code Coverage Analysis

**Question**: How do we measure and achieve 90%+ code coverage with Pester?

**Decision**: Use Pester built-in code coverage with CodeCoverage parameter

**Rationale**:
- Pester 5.x has built-in code coverage analysis (no external tools needed)
- Generates detailed reports showing covered/uncovered lines
- Integrates with test-runner.ps1 infrastructure

**Key Findings**:

**Pester Code Coverage Usage**:
```powershell
# Basic coverage analysis
$config = New-PesterConfiguration
$config.Run.Path = "./tests"
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = "./scripts/**/*.ps1", "./scripts/**/*.psm1"
$config.CodeCoverage.OutputFormat = "JaCoCo" # or "CoverageGutters"
$config.CodeCoverage.OutputPath = "./coverage/coverage.xml"
$config.Output.Verbosity = "Detailed"

$result = Invoke-Pester -Configuration $config

# Check coverage percentage
$coverage = $result.CodeCoverage
$totalLines = $coverage.NumberOfCommandsExecuted + $coverage.NumberOfCommandsMissed
$coveragePercent = ($coverage.NumberOfCommandsExecuted / $totalLines) * 100

if ($coveragePercent -lt 90) {
    throw "Code coverage is $coveragePercent%, target is 90%+"
}
```

**Viewing Coverage Results**:
- **JaCoCo XML**: Can be imported into Azure DevOps, Jenkins, or other CI/CD tools
- **CoverageGutters**: VSCode extension shows covered/uncovered lines inline
- **Pester Console Output**: Shows summary in test run output

**Improving Coverage Strategy**:
1. **Identify uncovered lines**: Review coverage report to find gaps
2. **Add targeted tests**: Focus on uncovered error paths and edge cases
3. **Mock external dependencies**: Use `Mock` to test code that calls GitHub API, file system
4. **Test parameter validation**: Ensure all `[Parameter]` attributes tested (mandatory, validation, etc.)
5. **Test error handling**: Verify try-catch blocks execute

**Exclusions** (if coverage gaps unavoidable):
- VSCodeIntegration module: Known mocking limitations (document as exception)
- Certain error paths that require environment simulation (document as manual test cases)

**Sources**:
- [Pester Code Coverage Documentation](https://pester.dev/docs/usage/code-coverage)
- [Pester 5 Configuration](https://pester.dev/docs/usage/configuration)
- [Code Coverage Best Practices](https://github.com/pester/Pester/wiki/Code-Coverage)

**Alternatives Considered**:
- **External coverage tools** (OpenCover, dotCover) - Rejected: Unnecessary dependency for PowerShell
- **Manual coverage tracking** - Rejected: Not scalable, error-prone

---

### 5. CI/CD Integration for Parameter Audit Tool

**Question**: How should the parameter audit tool integrate into CI/CD pipelines?

**Decision**: PowerShell script with structured output (JSON/markdown) and exit codes

**Rationale**:
- JSON output parsable by CI/CD tools for reporting
- Markdown output human-readable for manual review
- Exit code 0 (pass) / 1 (fail) enables CI/CD gating
- No external dependencies required (pure PowerShell)

**Key Findings**:

**Audit Tool Interface Design**:
```powershell
# audit-parameters.ps1

param(
    [string]$RootPath = ".",
    [string]$OutputFormat = "json", # "json", "markdown", "both"
    [string]$OutputPath = "./parameter-audit-report",
    [switch]$FailOnViolations
)

# Exit codes:
# 0 - All checks passed
# 1 - Parameter violations found (if -FailOnViolations)
# 2 - Script error (parsing failures, etc.)
```

**Output Structure**:
```json
{
  "timestamp": "2025-10-20T15:30:00Z",
  "summary": {
    "total_files": 15,
    "total_functions": 87,
    "total_parameters": 234,
    "violations": 12,
    "compliance_rate": 94.9
  },
  "violations": [
    {
      "file": "scripts/modules/ManifestManager.psm1",
      "line": 126,
      "function": "New-SpecKitManifest",
      "parameter": "SpecKitVersion",
      "violation_type": "non_standard_name",
      "suggested_fix": "Version"
    }
  ]
}
```

**CI/CD Integration Example** (GitHub Actions):
```yaml
name: Parameter Audit

on: [push, pull_request]

jobs:
  audit:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Parameter Audit
        shell: pwsh
        run: |
          ./scripts/tools/audit-parameters.ps1 -FailOnViolations
      - name: Upload Report
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: parameter-audit-report
          path: ./parameter-audit-report.json
```

**Sources**:
- [PowerShell CI/CD Best Practices](https://learn.microsoft.com/en-us/powershell/scripting/dev-cross-plat/ci-cd/overview)
- [GitHub Actions for PowerShell](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)

**Alternatives Considered**:
- **PSScriptAnalyzer integration** - Deferred: Can be added later as enhancement
- **Custom pre-commit hooks** - Considered: Could add local git hook in addition to CI/CD

---

## Summary of Decisions

| Topic | Decision | Key Rationale |
|-------|----------|---------------|
| **Parameter Naming** | Follow PowerShell PascalCase conventions with standard parameter names | Consistency with PowerShell ecosystem |
| **Code Analysis** | Use PowerShell AST API for static analysis | Built-in, accurate, no external dependencies |
| **Refactoring Approach** | Systematic module-by-module with test validation | Ensures correctness, minimizes breakage risk |
| **Code Coverage** | Use Pester built-in coverage, target 90%+ | Comprehensive safety net for refactoring |
| **Audit Tool** | PowerShell script with JSON/markdown output | CI/CD compatible, human-readable |

## Open Questions

None - all research questions resolved.

## Next Steps

Proceed to **Phase 1: Design & Contracts**:
1. Create `data-model.md` - document parameter audit report structure
2. Create `contracts/parameter-naming-standard.md` - canonical parameter names
3. Create `quickstart.md` - implementation guide for refactoring
4. Update agent context with technology decisions
