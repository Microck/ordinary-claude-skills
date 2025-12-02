# Phase 1: Data Model

**Feature**: PR Validation Workflow Enhancement
**Date**: 2025-10-25
**Status**: Complete

## Overview

This document defines the data structures used throughout the PR validation workflow, including validation results, findings, PR comments, and check summaries. All structures use JSON format for interoperability between PowerShell validation scripts and JavaScript GitHub Actions workflows.

---

## Entity 1: ValidationResult

**Purpose**: Top-level output from any validation script

**Attributes**:
- `step` (string): Step identifier (e.g., "step-5", "security-scan")
- `status` (enum): Overall validation status
  - Values: `"pass"`, `"warning"`, `"failed"`
- `timestamp` (string): ISO 8601 timestamp in UTC (e.g., "2025-10-25T14:32:00Z")
- `findings` (array): List of ValidationFinding objects
- `summary` (object): Summary statistics
- `metadata` (object): Additional context (branch name, PR number, commit SHA)

**JSON Schema**:
```json
{
  "step": "security-scan",
  "status": "warning",
  "timestamp": "2025-10-25T14:32:00Z",
  "findings": [
    {/* ValidationFinding */}
  ],
  "summary": {
    "total": 5,
    "errors": 2,
    "warnings": 3,
    "info": 0
  },
  "metadata": {
    "branch": "014-pr-validation-enhancement",
    "pr_number": 42,
    "commit_sha": "abc123def456"
  }
}
```

**Validation Rules**:
- `step` must be non-empty string
- `status` must be one of: "pass", "warning", "failed"
- `timestamp` must be valid ISO 8601 format
- `findings` must be array (can be empty)
- `summary.total` must equal length of `findings` array
- `summary.errors + warnings + info` must equal `total`

**Relationships**:
- Contains 0 to N ValidationFinding objects
- Consumed by FormatPRComment to generate comment body
- Stored temporarily during workflow execution

---

## Entity 2: ValidationFinding

**Purpose**: Individual issue discovered during validation

**Attributes**:
- `severity` (enum): Issue severity level
  - Values: `"error"`, `"warning"`, `"info"`
- `category` (string): Type of finding (e.g., "secret", "security-rule", "path-traversal")
- `file` (string): Relative file path from repository root
- `line` (integer, nullable): Line number where issue found (null if file-level)
- `column` (integer, nullable): Column number (null if not applicable)
- `rule` (string): Rule or pattern that triggered finding
- `message` (string): Human-readable description of the issue
- `remediation` (string): How to fix the issue
- `snippet` (string, nullable): Code snippet showing the issue (max 200 chars)

**JSON Schema**:
```json
{
  "severity": "error",
  "category": "secret",
  "file": "scripts/helpers/Example.ps1",
  "line": 45,
  "column": 12,
  "rule": "aws-access-key",
  "message": "AWS Access Key detected in plain text",
  "remediation": "Store credentials in environment variables or use AWS credential chain",
  "snippet": "$accessKey = \"AKIAIOSFODNN7EXAMPLE\""
}
```

**Validation Rules**:
- `severity` must be one of: "error", "warning", "info"
- `category` must be non-empty string
- `file` must be valid relative path
- `line` and `column` must be positive integers or null
- `message` must be non-empty string
- `remediation` must provide actionable guidance
- `snippet` should be truncated to 200 characters max

**Relationships**:
- Belongs to one ValidationResult
- Multiple findings can reference the same file
- Rendered in PR comment as bulleted list or table

---

## Entity 3: PRComment

**Purpose**: Structured PR comment content with metadata

**Attributes**:
- `marker` (string): HTML comment marker for identification (e.g., `"<!-- pr-validation:step-5 -->"`)
- `step_number` (integer): Step number (2-6)
- `step_name` (string): Human-readable step name (e.g., "Claude Security Scan")
- `emoji` (string): Status emoji for visual clarity (e.g., "🔒", "📋")
- `status` (enum): Overall status
  - Values: `"pass"`, `"warning"`, `"failed"`
- `sections` (array): Array of CommentSection objects
- `timestamp` (string): Last updated timestamp (ISO 8601)
- `footer` (string): Footer text (e.g., "Last updated: ...")

**JSON Schema**:
```json
{
  "marker": "<!-- pr-validation:step-5 -->",
  "step_number": 5,
  "step_name": "Claude Security Scan",
  "emoji": "🔒",
  "status": "warning",
  "sections": [
    {
      "title": "Secret Scanning",
      "status": "pass",
      "content": "No secrets detected"
    },
    {
      "title": "PowerShell Security",
      "status": "error",
      "content": "1 issue found:\n- file.ps1:45 - Avoid Invoke-Expression"
    }
  ],
  "timestamp": "2025-10-25T14:32:00Z",
  "footer": "Last updated: 2025-10-25 14:32 UTC"
}
```

**Validation Rules**:
- `marker` must include step identifier for uniqueness
- `step_number` must be 2-6
- `status` must be one of: "pass", "warning", "failed"
- `sections` must contain at least 1 section
- `timestamp` must be valid ISO 8601

**Relationships**:
- Generated from ValidationResult
- Posted to GitHub PR via actions/github-script
- Updated in place using marker for identification

---

## Entity 4: CommentSection

**Purpose**: Individual section within a PR comment

**Attributes**:
- `title` (string): Section heading (e.g., "Secret Scanning", "PowerShell Security")
- `status` (enum): Section-specific status
  - Values: `"pass"`, `"warning"`, `"error"`, `"info"`
- `content` (string): Markdown-formatted content
- `findings_count` (integer, nullable): Number of findings in this section

**JSON Schema**:
```json
{
  "title": "PowerShell Security",
  "status": "error",
  "content": "**1 issue found:**\n- `scripts/helpers/Example.ps1:45` - Avoid using `Invoke-Expression` (security risk)\n  ```powershell\n  Invoke-Expression $userInput  # ❌ Dangerous\n  ```\n  **Recommendation:** Use `& $command` or validate input rigorously",
  "findings_count": 1
}
```

**Validation Rules**:
- `title` must be non-empty
- `status` must be one of: "pass", "warning", "error", "info"
- `content` must be valid Markdown
- `findings_count` should match number of findings in content (if applicable)

**Relationships**:
- Belongs to one PRComment
- Rendered as collapsible section or paragraph in final comment

---

## Entity 5: SpecArtifact

**Purpose**: Represents a SpecKit documentation file (spec.md, plan.md, tasks.md)

**Attributes**:
- `path` (string): Relative path from repository root
- `type` (enum): Artifact type
  - Values: `"spec"`, `"plan"`, `"tasks"`, `"other"`
- `exists` (boolean): Whether file exists in PR
- `complete` (boolean): Whether file contains all required sections
- `required_sections` (array): List of expected section headers
- `found_sections` (array): List of section headers found in file
- `missing_sections` (array): Sections required but not found

**JSON Schema**:
```json
{
  "path": "specs/014-pr-validation-enhancement/spec.md",
  "type": "spec",
  "exists": true,
  "complete": false,
  "required_sections": [
    "User Scenarios & Testing",
    "Requirements",
    "Success Criteria"
  ],
  "found_sections": [
    "User Scenarios & Testing",
    "Requirements"
  ],
  "missing_sections": [
    "Success Criteria"
  ]
}
```

**Validation Rules**:
- `path` must be valid relative path
- `type` must be one of: "spec", "plan", "tasks", "other"
- `exists` must be boolean
- `complete` is true only if all required_sections found
- `missing_sections` = required_sections - found_sections

**Relationships**:
- Associated with one feature branch (via spec number)
- Multiple SpecArtifacts form a complete spec directory
- Validated by check-spec-compliance.ps1 script

---

## Entity 6: ConstitutionViolation

**Purpose**: Represents a violation of project constitution rules

**Attributes**:
- `file` (string): File path where violation found
- `line` (integer, nullable): Line number of violation
- `rule` (string): Constitution principle violated
- `description` (string): What was violated
- `recommendation` (string): How to fix
- `severity` (enum): How serious the violation is
  - Values: `"error"`, `"warning"`
- `documentation_link` (string): URL to constitution section

**JSON Schema**:
```json
{
  "file": "scripts/modules/NewModule.psm1",
  "line": null,
  "rule": "Module Export Rules",
  "description": "Missing Export-ModuleMember statement",
  "recommendation": "Add 'Export-ModuleMember -Function FunctionName' at end of module",
  "severity": "error",
  "documentation_link": "../../.specify/memory/constitution.md#module-export-rules"
}
```

**Validation Rules**:
- `file` must be valid path
- `rule` must reference actual constitution principle
- `description` and `recommendation` must be non-empty
- `severity` must be "error" or "warning"
- `documentation_link` must be valid relative or absolute URL

**Relationships**:
- Multiple violations can exist per file
- Aggregated in SpecKit Compliance check results
- Rendered with link to constitution documentation

---

## Entity 7: SecurityIssue

**Purpose**: Security vulnerability or exposed secret

**Attributes**:
- `type` (enum): Type of security issue
  - Values: `"secret"`, `"security-rule"`, `"path-traversal"`, `"dependency-vuln"`
- `file` (string): File path where issue found
- `line` (integer, nullable): Line number
- `pattern` (string): Pattern or rule that matched (e.g., "aws-access-key", "PSAvoidUsingInvokeExpression")
- `description` (string): What was detected
- `risk` (enum): Risk level
  - Values: `"critical"`, `"high"`, `"medium"`, `"low"`
- `remediation` (string): How to fix
- `cve` (string, nullable): CVE identifier if applicable (for dependency vulnerabilities)

**JSON Schema**:
```json
{
  "type": "secret",
  "file": ".env.example",
  "line": 3,
  "pattern": "github-pat",
  "description": "GitHub Personal Access Token detected",
  "risk": "critical",
  "remediation": "Remove token from repository. Revoke token at https://github.com/settings/tokens. Use environment variables instead.",
  "cve": null
}
```

**Validation Rules**:
- `type` must be one of allowed values
- `file` must be valid path
- `pattern` must identify the detection rule
- `risk` must be one of: "critical", "high", "medium", "low"
- `remediation` must be actionable
- `cve` should follow CVE-YYYY-NNNNN format if present

**Relationships**:
- Belongs to security scan validation result
- Grouped by type in PR comment sections
- Critical/High risks highlighted prominently

---

## Data Flow

```
┌─────────────────────────────────────────────────────────┐
│ 1. Validation Scripts (PowerShell)                      │
│    - check-dependencies.ps1                             │
│    - check-path-security.ps1                            │
│    - check-spec-compliance.ps1                          │
│    - PSScriptAnalyzer                                   │
│    - GitLeaks                                           │
└────────────────┬────────────────────────────────────────┘
                 │
                 ↓ Outputs JSON
┌─────────────────────────────────────────────────────────┐
│ 2. ValidationResult (JSON)                              │
│    {                                                    │
│      step, status, timestamp,                           │
│      findings: [ValidationFinding, ...],                │
│      summary: {...}                                     │
│    }                                                    │
└────────────────┬────────────────────────────────────────┘
                 │
                 ↓ Consumed by
┌─────────────────────────────────────────────────────────┐
│ 3. format-pr-comment.ps1                                │
│    - Formats ValidationResult as Markdown               │
│    - Groups findings by category                        │
│    - Adds status indicators and remediation             │
└────────────────┬────────────────────────────────────────┘
                 │
                 ↓ Generates
┌─────────────────────────────────────────────────────────┐
│ 4. PRComment (JSON)                                     │
│    {                                                    │
│      marker, step_number, status,                       │
│      sections: [CommentSection, ...],                   │
│      timestamp                                          │
│    }                                                    │
└────────────────┬────────────────────────────────────────┘
                 │
                 ↓ Posted by
┌─────────────────────────────────────────────────────────┐
│ 5. GitHub Actions (actions/github-script)               │
│    - Searches for existing comment by marker            │
│    - Updates or creates comment                         │
│    - Displays in PR conversation                        │
└─────────────────────────────────────────────────────────┘
```

---

## State Transitions

### ValidationResult Status

```
[Initial State]
      ↓
  ┌─────────┐
  │ Unknown │
  └────┬────┘
       │ (After validation runs)
       ↓
   ┌────────────┐
   │  All checks│
   │   passed?  │
   └─┬────────┬─┘
     │        │
    Yes       No
     │        │
     ↓        ↓
  ┌──────┐  ┌────────┐
  │ Pass │  │Warning │
  └──────┘  │   or   │
            │ Failed │
            └────────┘
```

**Transition Rules**:
- Start: "unknown" (before validation)
- Pass: All findings have severity "info" or no findings
- Warning: At least one "warning" severity finding, no "error" findings
- Failed: At least one "error" severity finding

### PR Comment Update Flow

```
[PR Commit Pushed]
      ↓
  ┌─────────────────┐
  │ GitHub Actions  │
  │ Workflow Starts │
  └────────┬────────┘
           │
           ↓
  ┌─────────────────┐
  │ Run Validation  │
  │     Scripts     │
  └────────┬────────┘
           │
           ↓
  ┌─────────────────┐
  │ Generate JSON   │
  │    Results      │
  └────────┬────────┘
           │
           ↓
  ┌─────────────────┐
  │ Format Comment  │
  └────────┬────────┘
           │
           ↓
  ┌─────────────────┐
  │ Search for      │
  │ Existing Comment│
  │ (by marker)     │
  └────────┬────────┘
           │
     ┌─────┴─────┐
     │           │
   Found      Not Found
     │           │
     ↓           ↓
┌─────────┐  ┌─────────┐
│ Update  │  │ Create  │
│ Comment │  │ Comment │
└─────────┘  └─────────┘
     │           │
     └─────┬─────┘
           ↓
  ┌─────────────────┐
  │ Comment Visible │
  │   in PR UI      │
  └─────────────────┘
```

---

## File Structure Mapping

### Validation Script Outputs

| Script | Output File | Entity Type |
|--------|-------------|-------------|
| `check-dependencies.ps1` | `dependency-scan-result.json` | ValidationResult |
| `check-path-security.ps1` | `path-security-result.json` | ValidationResult |
| `check-spec-compliance.ps1` | `spec-compliance-result.json` | ValidationResult |
| PSScriptAnalyzer | `security-lint-result.json` | ValidationResult |
| GitLeaks | `gitleaks-report.json` | Custom format (converted to ValidationResult) |

### Comment Generation

| Input | Script | Output |
|-------|--------|--------|
| Multiple ValidationResult JSON files | `format-pr-comment.ps1` | Single PRComment Markdown |

### Test Fixtures

| Fixture Type | Path | Purpose |
|--------------|------|---------|
| Valid spec directory | `tests/fixtures/spec-structures/valid-spec/` | Test spec validation pass case |
| Invalid spec (missing files) | `tests/fixtures/spec-structures/missing-tasks/` | Test spec validation failure |
| Vulnerable code samples | `tests/fixtures/vulnerable-code-samples/invoke-expression.ps1` | Test security scanning |
| Expected comments | `tests/fixtures/pr-comment-examples/step-5-pass.md` | Test comment formatting |

---

## JSON Schema Definitions

All JSON schemas are defined in `specs/014-pr-validation-enhancement/contracts/` directory:

- `validation-result.schema.json` - ValidationResult structure
- `validation-finding.schema.json` - ValidationFinding structure
- `pr-comment.schema.json` - PRComment structure
- `security-issue.schema.json` - SecurityIssue structure
- `spec-artifact.schema.json` - SpecArtifact structure
- `constitution-violation.schema.json` - ConstitutionViolation structure

These schemas are used for:
1. Validation of JSON outputs from PowerShell scripts
2. TypeScript/JavaScript type definitions in GitHub Actions
3. Documentation of expected data structures
4. Contract testing between validation scripts and comment formatter

---

**Phase 1 (Data Model) Status**: ✅ **COMPLETE**

All entity definitions documented with attributes, relationships, validation rules, and state transitions. Ready to create JSON schema contracts and quickstart guide.
