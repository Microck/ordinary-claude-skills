# Quick Start: PR Validation Workflow Enhancement

**Last Updated**: 2025-10-25
**For**: Developers implementing or extending the PR validation workflow

## Table of Contents

1. [5-Minute Overview](#5-minute-overview)
2. [Adding a New Validation Check](#adding-a-new-validation-check)
3. [Testing Your Changes](#testing-your-changes)
4. [Troubleshooting](#troubleshooting)
5. [Common Tasks](#common-tasks)

---

## 5-Minute Overview

### What This Feature Does

Enhances GitHub Actions PR validation to:
- **Detect security issues** (secrets, vulnerabilities, path traversal)
- **Validate SpecKit compliance** (spec files, CHANGELOG, constitution)
- **Post PR comments** that update in place (no spam)
- **Provide non-blocking feedback** (informational, not blocking)

### Architecture at a Glance

```
PR Commit Pushed
    ↓
GitHub Actions Workflow (.github/workflows/pr-validation.yml)
    ↓
Validation Scripts (.github/scripts/*.ps1)
    ↓
JSON Results → Format as Markdown → Post as PR Comment
```

### Key Files

| File | Purpose |
|------|---------|
| `.github/workflows/pr-validation.yml` | Main workflow definition (Steps 1-6) |
| `.github/scripts/check-dependencies.ps1` | Scan PowerShell dependencies for CVEs |
| `.github/scripts/check-path-security.ps1` | Detect path traversal vulnerabilities |
| `.github/scripts/check-spec-compliance.ps1` | Validate SpecKit artifacts |
| `.github/scripts/format-pr-comment.ps1` | Format validation results as Markdown |
| `tests/unit/Check*.Tests.ps1` | Unit tests for validation scripts |

---

## Adding a New Validation Check

### Step 1: Create Validation Script

**Template**: `.github/scripts/check-your-new-check.ps1`

```powershell
#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Brief description of what this check validates

.DESCRIPTION
    Detailed explanation of the validation logic

.PARAMETER RepoRoot
    Path to repository root directory

.EXAMPLE
    .\check-your-new-check.ps1 -RepoRoot "C:\repo"
#>

param(
    [Parameter(Mandatory)]
    [string]$RepoRoot
)

$ErrorActionPreference = 'Stop'

# 1. Perform validation
$findings = @()

# Your validation logic here...
# Example: Check for specific pattern
$files = Get-ChildItem -Path $RepoRoot -Recurse -Include *.ps1
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    if ($content -match 'PATTERN_TO_DETECT') {
        $findings += @{
            severity = 'warning'
            category = 'your-category'
            file = $file.FullName.Replace("$RepoRoot\", '')
            line = $null  # Or extract line number
            column = $null
            rule = 'your-rule-name'
            message = 'Description of the issue'
            remediation = 'How to fix it'
            snippet = $null
        }
    }
}

# 2. Determine overall status
$status = 'pass'
if ($findings.Count -gt 0) {
    $hasErrors = $findings | Where-Object { $_.severity -eq 'error' }
    $status = if ($hasErrors) { 'failed' } else { 'warning' }
}

# 3. Build result object
$result = @{
    step = 'your-check'
    status = $status
    timestamp = (Get-Date).ToUniversalTime().ToString('o')
    findings = $findings
    summary = @{
        total = $findings.Count
        errors = ($findings | Where-Object { $_.severity -eq 'error' }).Count
        warnings = ($findings | Where-Object { $_.severity -eq 'warning' }).Count
        info = ($findings | Where-Object { $_.severity -eq 'info' }).Count
    }
}

# 4. Output JSON
$result | ConvertTo-Json -Depth 10
```

### Step 2: Add to Workflow

**File**: `.github/workflows/pr-validation.yml`

Add new sub-check in appropriate step:

```yaml
    # Add to Step 5 (Security) or Step 6 (Compliance)
    - name: Run Your New Check
      shell: pwsh
      run: |
        $result = & .github/scripts/check-your-new-check.ps1 -RepoRoot $PWD
        $result | Out-File -FilePath "your-check-result.json"

    # Then include in comment formatting
    - name: Format Results
      run: |
        # Read all result files
        $results = @()
        $results += Get-Content "your-check-result.json" | ConvertFrom-Json
        # ... format and post comment
```

### Step 3: Create Unit Test

**File**: `tests/unit/CheckYourNewCheck.Tests.ps1`

```powershell
Describe "check-your-new-check" {
    BeforeAll {
        # Setup test environment
        $testRoot = Join-Path $TestDrive "test-repo"
        New-Item -ItemType Directory -Path $testRoot -Force
    }

    Context "When validating files" {
        It "Should detect issue pattern" {
            # Arrange
            $testFile = Join-Path $testRoot "test.ps1"
            Set-Content -Path $testFile -Value 'PATTERN_TO_DETECT'

            # Act
            $result = & "$PSScriptRoot\..\..\github\scripts\check-your-new-check.ps1" `
                        -RepoRoot $testRoot | ConvertFrom-Json

            # Assert
            $result.findings.Count | Should -BeGreaterThan 0
            $result.status | Should -Be 'warning'
        }

        It "Should pass when no issues found" {
            # Arrange: Clean repo

            # Act
            $result = & "$PSScriptRoot\..\..\github\scripts\check-your-new-check.ps1" `
                        -RepoRoot $testRoot | ConvertFrom-Json

            # Assert
            $result.findings.Count | Should -Be 0
            $result.status | Should -Be 'pass'
        }
    }
}
```

### Step 4: Add Test Fixtures

**Directory**: `tests/fixtures/your-check/`

Create sample files for testing:
- `valid-example.ps1` - Should pass validation
- `invalid-example.ps1` - Should trigger finding

---

## Testing Your Changes

### Unit Tests

```powershell
# Run all unit tests
./tests/test-runner.ps1 -Unit

# Run specific test file
Invoke-Pester tests/unit/CheckYourNewCheck.Tests.ps1 -Output Detailed
```

### Integration Testing

```powershell
# Test entire workflow locally (requires Act or GitHub CLI)
gh workflow run pr-validation.yml

# Or test validation script directly
.github/scripts/check-your-new-check.ps1 -RepoRoot $PWD | ConvertFrom-Json
```

### Manual PR Testing

1. Create test PR with intentional issue
2. Push commit to trigger workflow
3. Verify:
   - Workflow completes successfully
   - PR comment appears with findings
   - Comment updates on subsequent push (not duplicate)
   - Findings are accurate

---

## Troubleshooting

### Problem: Validation script fails with JSON parsing error

**Cause**: Invalid JSON output (missing comma, unescaped string)

**Fix**:
```powershell
# Validate JSON output locally
$result | ConvertTo-Json -Depth 10 | ConvertFrom-Json
# Should not throw error
```

### Problem: PR comment not updating, creating duplicates

**Cause**: HTML marker not matching or marker changed

**Fix**:
- Ensure marker format: `<!-- pr-validation:step-{N} -->`
- Check marker is at very start of comment body
- Verify `actions/github-script` has `issues: write` permission

### Problem: Workflow fails with "permission denied"

**Cause**: Missing GitHub token permissions

**Fix**:
```yaml
# Add to job in workflow
permissions:
  contents: read
  pull-requests: write
  issues: write
```

### Problem: Test fixtures not found

**Cause**: Relative path issues in test setup

**Fix**:
```powershell
# Use absolute paths
$fixturesPath = Join-Path (Split-Path $PSScriptRoot) "fixtures"
```

---

## Common Tasks

### Update Validation Logic

**File**: `.github/scripts/check-*.ps1`

1. Modify validation criteria
2. Update test expectations
3. Run `./tests/test-runner.ps1 -Unit` to verify
4. Create test PR to validate end-to-end

### Add New Security Rule

**File**: `.github/workflows/pr-validation.yml` (Step 5)

```yaml
# Add to PSScriptAnalyzer IncludeRule list
-IncludeRule @(
  'PSAvoidUsingPlainTextForPassword',
  'PSAvoidUsingInvokeExpression',
  'YourNewRuleName'  # Add here
)
```

### Change Comment Format

**File**: `.github/scripts/format-pr-comment.ps1`

1. Update Markdown template
2. Test with `format-pr-comment.Tests.ps1`
3. Verify rendering in GitHub Markdown preview

### Adjust Status Thresholds

**Logic**: Change when validation returns "pass" vs "warning" vs "failed"

```powershell
# In validation script
$status = 'pass'
if ($findings.Count -gt 0) {
    $hasErrors = $findings | Where-Object { $_.severity -eq 'error' }
    $hasCritical = $findings | Where-Object { $_.severity -eq 'critical' }  # New
    $status = if ($hasCritical) {
        'failed'
    } elseif ($hasErrors) {
        'warning'
    } else {
        'pass'
    }
}
```

---

## Quick Reference

### JSON Schema Validation

```powershell
# Validate result against schema
$schema = Get-Content specs/014-pr-validation-enhancement/contracts/validation-result.schema.json | ConvertFrom-Json
# Use Test-Json cmdlet (PowerShell 6+)
$result | ConvertTo-Json -Depth 10 | Test-Json -SchemaFile $schema
```

### Markdown Comment Template

```markdown
<!-- pr-validation:step-{N} -->
## {Emoji} Step {N}/6: {Name}

**Status**: {Status}

### {Sub-Check Name}
{Status Indicator} {Description}

---
*Last updated: {Timestamp}*
```

### Status Indicators

| Status | Emoji | Description |
|--------|-------|-------------|
| Pass | ✅ | No issues found |
| Warning | ⚠️ | Issues found but non-blocking |
| Failed | ❌ | Critical issues found |
| Info | ℹ️ | Informational only |

### Severity Levels

| Severity | Use When |
|----------|----------|
| `error` | Critical issue, should block merge (but doesn't in this workflow) |
| `warning` | Issue should be addressed but not critical |
| `info` | Informational, no action required |

---

## Need More Help?

- **Full specification**: [spec.md](spec.md)
- **Data model**: [data-model.md](data-model.md)
- **Research**: [research.md](research.md)
- **Constitution**: [../../.specify/memory/constitution.md](../../.specify/memory/constitution.md)
- **GitHub Issues**: [Issues tagged `pr-validation`](https://github.com/NotMyself/claude-win11-speckit-safe-update-skill/labels/pr-validation)

---

**Last Updated**: 2025-10-25 | **Version**: 1.0
