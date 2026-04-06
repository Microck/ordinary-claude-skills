# PR Validation Workflow

**File**: `.github/workflows/pr-validation.yml`
**Purpose**: Automated validation of pull requests with intelligent comment-based feedback
**Status**: ✅ Active

## Overview

This workflow provides comprehensive, non-blocking validation for all pull requests. It runs 6 validation steps and posts detailed feedback as PR comments that update in place.

## Workflow Steps

### Step 1: Authorization Check (Blocking)

**Purpose**: Verify the PR author is authorized to contribute

**What it checks:**
- Repository owner status
- Collaborator status
- Organization membership
- Explicit allowlist in `.github/claude-authorized-users.yml`
- Emergency circuit breaker status

**Blocking**: ✅ Yes - unauthorized PRs fail here

**Configuration**: `.github/claude-authorized-users.yml`

---

### Step 2: PR Guardrails (Non-blocking)

**Purpose**: Validate PR size and description quality

**What it checks:**
- PR size (lines changed)
  - Limit: 2000 lines
  - Owner bypass: Allowed
- Description length
  - Minimum: 20 characters
  - Warning only

**Blocking**: ❌ No - informational feedback

**PR Comment**: ✅ Posted as Step 2/6 comment

---

### Step 3: Quality Checks (Non-blocking)

**Purpose**: Linting and unit test validation

**What it checks:**
- PSScriptAnalyzer linting
  - All rules from `PSScriptAnalyzerSettings.psd1`
  - Errors and warnings reported
- Pester unit tests
  - Runs `./tests/test-runner.ps1 -Unit`
  - Known Pester 5.x issues = non-blocking

**Blocking**: ❌ No - failures reported as warnings

**PR Comment**: ✅ Posted as Step 3/6 comment

---

### Step 4: Code Review (Optional)

**Purpose**: Claude Code automated review

**What it checks:**
- Code quality and best practices
- PowerShell conventions
- Potential bugs
- Documentation completeness

**Blocking**: ❌ No - requires `CLAUDE_CODE_OAUTH_TOKEN` secret

**PR Comment**: ❌ No - Claude posts its own review

---

### Step 5: Security Scan (Non-blocking)

**Purpose**: Detect security vulnerabilities and exposed secrets

**What it checks:**

1. **GitLeaks Secret Scanning**
   - Hardcoded API keys, tokens, passwords
   - 100+ secret patterns
   - GitHub, AWS, Azure, etc.

2. **PSScriptAnalyzer Security Rules**
   - `PSAvoidUsingPlainTextForPassword`
   - `PSAvoidUsingConvertToSecureStringWithPlainText`
   - `PSUsePSCredentialType`
   - `PSAvoidUsingInvokeExpression`

3. **Dependency Vulnerability Scan**
   - Checks installed PowerShell modules
   - Validates manifest files (`.psd1`)
   - Known vulnerable versions database
   - Example: Pester < 5.0.0

4. **Path Traversal Detection**
   - Unsafe string concatenation: `$path + "\"`
   - Unsafe interpolation: `"$path\$input"`
   - Direct `..` traversal checks
   - Flags missing `Join-Path` usage

**Blocking**: ❌ No - critical findings are warnings

**PR Comment**: ✅ Posted as Step 5/6 comment with file:line references

---

### Step 6: SpecKit Compliance (Non-blocking)

**Purpose**: Validate SpecKit artifacts and constitution compliance

**What it checks:**

1. **Branch Name Parsing**
   - Feature branches: `NNN-feature-name`
   - Extracts spec number
   - Skips validation for non-feature branches

2. **Spec Directory Structure**
   - `specs/NNN-feature-name/` exists
   - `spec.md` present with required sections:
     - User Scenarios & Testing
     - Requirements
     - Success Criteria
   - `plan.md` present
   - `tasks.md` present

3. **CHANGELOG Validation**
   - `CHANGELOG.md` exists
   - Contains `[Unreleased]` section

4. **Constitution Compliance**
   - All `.psm1` files have `Export-ModuleMember`
   - No nested `Import-Module` in modules
   - Validates Module vs Helper pattern

**Blocking**: ❌ No - helps enforce best practices

**PR Comment**: ✅ Posted as Step 6/6 comment

---

## PR Comment System

### Update-in-Place Behavior

Each validation step posts a PR comment with an HTML marker:

```markdown
<!-- pr-validation:step-N -->
```

On subsequent pushes to the same PR:
- Workflow searches for existing comment by marker
- Updates existing comment if found
- Creates new comment only if marker not found

**Result**: Clean PR conversation with no duplicate comments

### Comment Format

```markdown
<!-- pr-validation:step-N -->
## [EMOJI] Step N/6: [Name]

**Status**: [PASS|WARN|FAIL] **STATUS**

### Summary

- **Total findings**: N
- **Errors**: N
- **Warnings**: N

### [Category] (N finding(s))

[ERROR|WARN] **rule-name**
  - **Location**: `file.ps1:line:col`
  - **Issue**: Description
  - **Code**:
    ```powershell
    code snippet
    ```
  - **Fix**: Remediation guidance

---
_Last updated: timestamp_
```

---

## Troubleshooting

### Issue: Comment not updating (duplicates created)

**Cause**: HTML marker mismatch or permissions issue

**Fix**:
1. Verify marker format: `<!-- pr-validation:step-N -->`
2. Check workflow permissions include `issues: write`
3. Ensure `actions/github-script@v7` is used

### Issue: Security scan finds false positives

**Cause**: Test fixtures or example code flagged

**Fix**:
1. Move sensitive examples to `tests/fixtures/`
2. Add `.gitleaksignore` for known safe patterns
3. Document why patterns are safe

### Issue: Spec compliance fails on valid branch

**Cause**: Branch name doesn't match `NNN-feature-name` pattern

**Fix**:
- Feature branches must use 3-digit spec numbers: `014-my-feature`
- Bugfix branches can use any name (validation skipped)

### Issue: PSScriptAnalyzer errors block PR

**Cause**: Linting errors found

**Fix**:
1. Run locally: `Invoke-ScriptAnalyzer -Path . -Recurse`
2. Fix reported issues
3. Push updated code

### Issue: Path traversal false positive on safe code

**Cause**: Script detects pattern but doesn't recognize safe usage

**Fix**:
- Ensure using `Join-Path` or `[System.IO.Path]::Combine()`
- Safe patterns are automatically excluded

---

## Configuration

### Modify Validation Rules

**Security Rules** (Step 5):
Edit `.github/workflows/pr-validation.yml`, Step 5, PSScriptAnalyzer section:

```yaml
-IncludeRule @(
  'PSAvoidUsingPlainTextForPassword',
  'PSAvoidUsingInvokeExpression',
  'YourNewRule'  # Add here
)
```

**Linting Rules** (Step 3):
Edit `PSScriptAnalyzerSettings.psd1` in repository root

**PR Size Limit** (Step 2):
Edit `.github/workflows/pr-validation.yml`, Step 2:

```yaml
MAX_SIZE=2000  # Change this value
```

### Add Custom Validation Check

See [quickstart.md](../../specs/014-pr-validation-enhancement/quickstart.md) for step-by-step guide

---

## Validation Scripts

All validation logic lives in standalone scripts:

| Script | Purpose | Output |
|--------|---------|--------|
| `format-pr-comment.ps1` | Formats validation results as Markdown | PR comment body |
| `check-dependencies.ps1` | Scans PowerShell module dependencies | JSON ValidationResult |
| `check-path-security.ps1` | Detects path traversal vulnerabilities | JSON ValidationResult |
| `check-spec-compliance.ps1` | Validates SpecKit artifacts | JSON ValidationResult |

### Running Scripts Locally

```powershell
# Test path security check
.github/scripts/check-path-security.ps1 -RepoRoot .

# Test dependency check
.github/scripts/check-dependencies.ps1 -RepoRoot .

# Test spec compliance
.github/scripts/check-spec-compliance.ps1 -RepoRoot . -BranchName "014-my-feature"

# Format sample result
$json = Get-Content result.json -Raw
.github/scripts/format-pr-comment.ps1 -InputJson $json -StepNumber 5 -StepName "Test" -Emoji "LOCK"
```

---

## Workflow Permissions

Required permissions for PR comment posting:

```yaml
permissions:
  contents: read          # Read repository code
  pull-requests: write    # Update PR metadata
  issues: write           # Create/update comments (PRs are issues)
```

---

## Performance

**Typical Runtime**: 4-6 minutes per PR

| Step | Duration |
|------|----------|
| Step 1: Authorization | ~10 seconds |
| Step 2: Guardrails | ~15 seconds |
| Step 3: Quality Checks | ~2-3 minutes (Windows runner) |
| Step 4: Code Review | Optional |
| Step 5: Security Scan | ~1-2 minutes |
| Step 6: Spec Compliance | ~10 seconds |

**Optimization Tips**:
- PSScriptAnalyzer and Pester are cached between runs
- Steps 5 and 6 run in parallel (both need Step 4)
- Comment posting is fast (~1-2 seconds)

---

## Related Documentation

- [Quickstart Guide](../../specs/014-pr-validation-enhancement/quickstart.md) - Add new validation checks
- [Data Model](../../specs/014-pr-validation-enhancement/data-model.md) - JSON schemas
- [Research](../../specs/014-pr-validation-enhancement/research.md) - Technology decisions
- [Constitution](../../.specify/memory/constitution.md) - Project principles

---

**Last Updated**: 2025-10-25
**Version**: 1.0
**Feature Branch**: `014-pr-validation-enhancement`
