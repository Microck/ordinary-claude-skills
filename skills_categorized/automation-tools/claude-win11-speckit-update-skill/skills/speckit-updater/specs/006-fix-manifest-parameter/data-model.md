# Data Model: Parameter Standardization

**Feature**: 006-fix-manifest-parameter
**Date**: 2025-10-20
**Purpose**: Define data structures for parameter audit tool and naming standard

## Overview

This document defines the data structures used in the parameter standardization feature. The primary entities are:
1. **Parameter Naming Standard** - canonical parameter names and rules
2. **Parameter Audit Report** - output from automated analysis tool
3. **Parameter Metadata** - information about each parameter in the codebase

## Entity Definitions

### 1. Parameter Naming Standard

**Purpose**: Define canonical parameter names for all common concepts used across the codebase.

**Structure**:
```json
{
  "version": "1.0.0",
  "last_updated": "2025-10-20T15:30:00Z",
  "conventions": {
    "case_style": "PascalCase",
    "singular_preferred": true,
    "no_abbreviations": true,
    "approved_verbs": ["Get", "Set", "New", "Remove", "Invoke", "Test", "Update", "Add", "Clear"]
  },
  "standard_parameters": [
    {
      "canonical_name": "Version",
      "description": "SpecKit semantic version (e.g., v0.0.72)",
      "type": "string",
      "usage_context": "SpecKit version references",
      "deprecated_names": ["SpecKitVersion"],
      "examples": [
        "-Version v0.0.72",
        "-Version $targetRelease.tag_name"
      ]
    },
    {
      "canonical_name": "Path",
      "description": "Generic file or directory path",
      "type": "string",
      "usage_context": "General path references",
      "deprecated_names": [],
      "examples": [
        "-Path C:\\Users\\bobby\\.specify",
        "-Path ./manifest.json"
      ]
    },
    {
      "canonical_name": "ProjectRoot",
      "description": "Root directory of the SpecKit project",
      "type": "string",
      "usage_context": "Project root directory references",
      "deprecated_names": ["RootPath", "Root"],
      "examples": [
        "-ProjectRoot C:\\Users\\bobby\\my-project"
      ]
    }
  ],
  "common_parameters": {
    "powershell_common": [
      "Verbose",
      "Debug",
      "ErrorAction",
      "WarningAction",
      "InformationAction",
      "ErrorVariable",
      "WarningVariable",
      "OutVariable",
      "OutBuffer",
      "WhatIf",
      "Confirm"
    ],
    "skill_specific": [
      "CheckOnly",
      "AssumeAllCustomized",
      "Rollback",
      "Force"
    ]
  }
}
```

**Fields**:
- `version` (string, required): Semantic version of the standard
- `last_updated` (ISO 8601 datetime, required): Last modification timestamp
- `conventions` (object, required): General naming rules
  - `case_style` (string): "PascalCase", "camelCase", etc.
  - `singular_preferred` (boolean): Prefer singular nouns
  - `no_abbreviations` (boolean): Avoid abbreviations
  - `approved_verbs` (array of strings): PowerShell approved verbs
- `standard_parameters` (array of objects, required): Canonical parameter definitions
  - `canonical_name` (string, required): The standardized parameter name
  - `description` (string, required): What the parameter represents
  - `type` (string, required): PowerShell type (string, int, switch, etc.)
  - `usage_context` (string, required): When to use this parameter
  - `deprecated_names` (array of strings): Old names to replace
  - `examples` (array of strings): Usage examples
- `common_parameters` (object): Categorized common parameters
  - `powershell_common` (array): Built-in PowerShell parameters
  - `skill_specific` (array): Custom parameters for this skill

**Relationships**:
- Referenced by Parameter Audit Report (comparison baseline)
- Used by Parameter Audit Tool (validation rules)

**Validation Rules**:
- `canonical_name` must be PascalCase
- `canonical_name` must not be in `deprecated_names`
- No duplicate `canonical_name` entries

---

### 2. Parameter Audit Report

**Purpose**: Output from the automated parameter audit tool showing compliance status and violations.

**Structure**:
```json
{
  "timestamp": "2025-10-20T16:00:00Z",
  "audit_version": "1.0.0",
  "summary": {
    "total_files_scanned": 15,
    "total_functions_found": 87,
    "total_parameters_declared": 234,
    "total_parameter_usages": 456,
    "total_violations": 12,
    "compliance_rate_percent": 94.87,
    "status": "FAIL"
  },
  "violations": [
    {
      "violation_id": "V001",
      "file_path": "scripts/modules/ManifestManager.psm1",
      "line_number": 126,
      "function_name": "New-SpecKitManifest",
      "parameter_name": "SpecKitVersion",
      "violation_type": "non_standard_name",
      "severity": "high",
      "suggested_fix": "Version",
      "rationale": "Parameter should use canonical name 'Version' per naming standard"
    },
    {
      "violation_id": "V002",
      "file_path": "scripts/update-orchestrator.ps1",
      "line_number": 200,
      "function_name": "N/A",
      "call_site_function": "New-SpecKitManifest",
      "parameter_name": "missing",
      "violation_type": "missing_parameter",
      "severity": "critical",
      "suggested_fix": "Add -Version $targetRelease.tag_name",
      "rationale": "Function call missing required -Version parameter"
    }
  ],
  "files_scanned": [
    {
      "file_path": "scripts/modules/HashUtils.psm1",
      "functions_found": 5,
      "parameters_declared": 12,
      "violations_count": 0,
      "status": "PASS"
    },
    {
      "file_path": "scripts/modules/ManifestManager.psm1",
      "functions_found": 8,
      "parameters_declared": 24,
      "violations_count": 5,
      "status": "FAIL"
    }
  ],
  "metadata": {
    "scan_duration_seconds": 2.45,
    "standard_version": "1.0.0",
    "naming_standard_path": ".specify/memory/parameter-naming-standard.json"
  }
}
```

**Fields**:

**Summary Section**:
- `timestamp` (ISO 8601 datetime): When audit ran
- `audit_version` (string): Version of audit tool
- `summary.total_files_scanned` (integer): Number of files analyzed
- `summary.total_functions_found` (integer): Number of function definitions
- `summary.total_parameters_declared` (integer): Number of parameter declarations
- `summary.total_parameter_usages` (integer): Number of parameter call sites
- `summary.total_violations` (integer): Number of violations found
- `summary.compliance_rate_percent` (float): Percentage of compliant parameters
- `summary.status` (enum): "PASS" (0 violations) | "FAIL" (>0 violations)

**Violations Section**:
- `violation_id` (string, unique): Identifier for violation
- `file_path` (string): Relative path to file with violation
- `line_number` (integer): Line number of violation
- `function_name` (string): Function containing violation
- `parameter_name` (string): Offending parameter name
- `violation_type` (enum): Type of violation
  - `non_standard_name` - parameter doesn't match canonical name
  - `missing_parameter` - required parameter not passed
  - `mismatched_parameter` - call site uses wrong parameter name
  - `outdated_documentation` - comment-based help uses old name
  - `inconsistent_variable` - verbose/error message uses old variable name
- `severity` (enum): "critical" | "high" | "medium" | "low"
- `suggested_fix` (string): Recommended correction
- `rationale` (string): Why this is a violation

**Files Scanned Section**:
- `file_path` (string): Relative path to scanned file
- `functions_found` (integer): Functions in this file
- `parameters_declared` (integer): Parameters in this file
- `violations_count` (integer): Violations in this file
- `status` (enum): "PASS" | "FAIL"

**Metadata Section**:
- `scan_duration_seconds` (float): How long audit took
- `standard_version` (string): Version of naming standard used
- `naming_standard_path` (string): Path to naming standard document

**Relationships**:
- References Parameter Naming Standard (validation baseline)
- Contains Parameter Metadata (individual parameter info)

**Validation Rules**:
- `summary.status` is "FAIL" if `total_violations` > 0, otherwise "PASS"
- `compliance_rate_percent` = ((total_parameters - total_violations) / total_parameters) * 100
- All `violation_id` values must be unique
- All `file_path` values must be valid relative paths

---

### 3. Parameter Metadata

**Purpose**: Information about a single parameter in the codebase (used internally by audit tool).

**Structure**:
```json
{
  "parameter_name": "Version",
  "file_path": "scripts/modules/ManifestManager.psm1",
  "line_number": 126,
  "function_name": "New-SpecKitManifest",
  "parameter_type": "string",
  "is_mandatory": true,
  "validation_attributes": [
    "ValidateNotNullOrEmpty()"
  ],
  "help_documented": true,
  "usage_count": 3,
  "call_sites": [
    {
      "file": "scripts/update-orchestrator.ps1",
      "line": 200,
      "parameter_passed": "Version"
    }
  ],
  "compliance_status": "compliant"
}
```

**Fields**:
- `parameter_name` (string): Name as declared in param block
- `file_path` (string): File containing parameter declaration
- `line_number` (integer): Line where parameter declared
- `function_name` (string): Function containing parameter
- `parameter_type` (string): PowerShell type (string, int, switch, etc.)
- `is_mandatory` (boolean): Whether parameter is mandatory
- `validation_attributes` (array of strings): Validation attributes applied
- `help_documented` (boolean): Whether `.PARAMETER` documentation exists
- `usage_count` (integer): Number of times parameter used in call sites
- `call_sites` (array of objects): Where this parameter is used
  - `file` (string): File containing call
  - `line` (integer): Line number of call
  - `parameter_passed` (string): Parameter name used in call
- `compliance_status` (enum): "compliant" | "non_compliant" | "needs_review"

**Relationships**:
- Aggregated into Parameter Audit Report
- Validated against Parameter Naming Standard

**Validation Rules**:
- `parameter_name` should match entry in Parameter Naming Standard
- `compliance_status` is "non_compliant" if `parameter_name` doesn't match canonical name
- `usage_count` should equal length of `call_sites` array

---

## State Transitions

### Parameter Audit Workflow States

```
[Unaudited] → [Scanning] → [Analyzed] → [Reported]
                    ↓
              [Scan Failed]
```

**State Definitions**:
- **Unaudited**: Codebase has not been analyzed
- **Scanning**: AST parsing in progress
- **Analyzed**: All parameters extracted and compared to standard
- **Reported**: JSON/markdown reports generated
- **Scan Failed**: Error during scanning (parsing failure, missing standard, etc.)

### Parameter Compliance States

```
[Compliant] ←→ [Non-Compliant]
     ↓
[Refactored] → [Re-Audited] → [Verified]
```

**State Definitions**:
- **Compliant**: Parameter matches naming standard
- **Non-Compliant**: Parameter violates naming standard
- **Refactored**: Parameter has been renamed to match standard
- **Re-Audited**: Parameter re-checked after refactoring
- **Verified**: Parameter confirmed compliant after refactoring

---

## Example Data Flows

### Audit Tool Execution Flow

```
1. Load Parameter Naming Standard (JSON)
   ↓
2. Scan scripts/ directory for .ps1 and .psm1 files
   ↓
3. For each file:
   - Parse with PowerShell AST
   - Extract function definitions
   - Extract parameter declarations
   - Extract function call sites
   - Compare parameters against standard
   - Record violations
   ↓
4. Aggregate results into Parameter Audit Report
   ↓
5. Generate JSON output (machine-readable)
   ↓
6. Generate Markdown output (human-readable)
   ↓
7. Exit with code 0 (compliant) or 1 (violations)
```

### Refactoring Workflow Data Dependencies

```
Parameter Audit Report
   ↓
Identify violations (sorted by severity)
   ↓
Refactor function signature
   ↓
Update comment-based help
   ↓
Update call sites
   ↓
Update verbose/error messages
   ↓
Run unit tests
   ↓
Re-run Parameter Audit Tool
   ↓
Verify violation resolved
```

---

## Constraints

1. **Parameter names must be unique within a function** - PowerShell requirement
2. **Parameter names are case-insensitive** - PowerShell convention (but PascalCase preferred)
3. **Deprecated names cannot be reused** - prevents confusion
4. **Audit report must be deterministic** - same codebase produces same report
5. **JSON output must be valid** - parsable by CI/CD tools

---

## Performance Considerations

- **AST parsing**: O(n) where n = number of lines in file (fast, typically <1s per file)
- **Violation detection**: O(m) where m = number of parameters (negligible overhead)
- **Report generation**: O(v) where v = number of violations (negligible overhead)
- **Expected audit duration**: ~2-5 seconds for entire codebase (15 files, 87 functions, 234 parameters)

---

## Future Enhancements

1. **Auto-fix mode**: Automatically refactor parameters to match standard
2. **Historical trend tracking**: Track compliance over time
3. **Custom rule definitions**: Allow project-specific naming rules
4. **IDE integration**: VSCode extension for real-time compliance checking
