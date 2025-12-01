# Phase 0: Research & Technology Decisions

**Feature**: PR Validation Workflow Enhancement
**Date**: 2025-10-25
**Status**: Complete

## Overview

This document captures research findings and technology decisions for implementing comprehensive PR validation with intelligent comment management. All decisions are based on GitHub Actions best practices, PowerShell scripting standards, and the project's existing architecture.

---

## Decision 1: Secret Scanning Tool Selection

**Decision**: Use GitLeaks (gitleaks/gitleaks-action@v2)

**Rationale**:
- Industry-standard secret scanning tool with 10k+ GitHub stars
- Native GitHub Action available (gitleaks/gitleaks-action@v2)
- Detects 100+ secret patterns (API keys, tokens, passwords, private keys)
- Zero configuration required for common patterns
- SARIF output format supported for GitHub Security tab integration
- Active maintenance and regular pattern updates

**Alternatives Considered**:
1. **TruffleHog** - Good tool but slower, requires more configuration
2. **detect-secrets** (Yelp) - Python-based, requires setup, fewer pattern matches
3. **Custom regex** - Incomplete coverage, high maintenance burden

**Integration Approach**:
```yaml
- name: Run GitLeaks
  uses: gitleaks/gitleaks-action@v2
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Output**: JSON file with findings including file path, line number, matched pattern, and severity.

---

## Decision 2: PowerShell Security Rule Selection

**Decision**: Use PSScriptAnalyzer with security-focused rule subset

**Rationale**:
- PSScriptAnalyzer is the official PowerShell linting tool from Microsoft
- Already used in project for general linting (see `.github/workflows/pr-validation.yml` Step 3)
- Security rules specifically target PowerShell anti-patterns
- Can be configured to run only security checks via `-IncludeRule` parameter
- Outputs structured results (JSON/CSV/console)

**Security Rules to Include**:
1. `PSAvoidUsingPlainTextForPassword` - Detects passwords in plain text
2. `PSAvoidUsingConvertToSecureStringWithPlainText` - Flags unsafe credential conversion
3. `PSUsePSCredentialType` - Enforces proper credential typing
4. `PSAvoidUsingInvokeExpression` - Prevents code injection vulnerabilities
5. `PSAvoidUsingPositionalParameters` - Improves code clarity and security
6. `PSAvoidGlobalVars` - Prevents state pollution

**Usage**:
```powershell
Invoke-ScriptAnalyzer -Path . -Recurse `
  -IncludeRule @(
    'PSAvoidUsingPlainTextForPassword',
    'PSAvoidUsingConvertToSecureStringWithPlainText',
    'PSUsePSCredentialType',
    'PSAvoidUsingInvokeExpression'
  ) `
  -Severity Error,Warning
```

**Output**: Array of findings with file, line, column, rule name, severity, and message.

---

## Decision 3: PR Comment Management Strategy

**Decision**: Use actions/github-script@v7 with HTML comment markers for update-in-place behavior

**Rationale**:
- `actions/github-script` provides direct access to GitHub API (Octokit) within workflows
- HTML comments are invisible in rendered Markdown but searchable
- Unique markers (e.g., `<!-- pr-validation:step-2 -->`) identify each validation step's comment
- Update logic: Search for existing comment by marker, update if found, create if not found
- Standard pattern used by many GitHub Actions (dependabot, renovate, etc.)

**Comment Marker Format**:
```markdown
<!-- pr-validation:step-{N} -->
## {Emoji} Step {N}/6: {Name}

**Status**: {✅ Pass | ⚠️ Warning | ❌ Failed}

[Validation results]

---
*Last updated: {timestamp}*
```

**Update-in-Place Logic**:
```javascript
const marker = '<!-- pr-validation:step-5 -->';
const comments = await github.rest.issues.listComments({
  owner: context.repo.owner,
  repo: context.repo.repo,
  issue_number: context.issue.number,
});

const existing = comments.data.find(c => c.body.includes(marker));

if (existing) {
  await github.rest.issues.updateComment({
    owner: context.repo.owner,
    repo: context.repo.repo,
    comment_id: existing.id,
    body: newBody,
  });
} else {
  await github.rest.issues.createComment({
    owner: context.repo.owner,
    repo: context.repo.repo,
    issue_number: context.issue.number,
    body: newBody,
  });
}
```

**Permissions Required**:
```yaml
permissions:
  contents: read
  pull-requests: write
  issues: write  # PRs are GitHub issues
```

---

## Decision 4: Validation Result Output Format

**Decision**: Use structured JSON output from validation scripts

**Rationale**:
- JSON is easily parsable in both PowerShell and JavaScript (GitHub Actions script)
- Enables structured error handling and formatting
- Supports nested data structures (findings with metadata)
- Can be validated against JSON schemas
- Standard format across all validation scripts

**Schema Pattern**:
```json
{
  "status": "pass|warning|failed",
  "findings": [
    {
      "severity": "error|warning|info",
      "file": "path/to/file.ps1",
      "line": 42,
      "column": 10,
      "rule": "PSAvoidUsingInvokeExpression",
      "message": "Avoid using Invoke-Expression",
      "remediation": "Use & operator or dot-sourcing instead"
    }
  ],
  "summary": {
    "total": 5,
    "errors": 2,
    "warnings": 3,
    "info": 0
  }
}
```

**PowerShell Output**:
```powershell
$result = @{
    status = "warning"
    findings = @(/* array */)
    summary = @{/* object */}
}

$result | ConvertTo-Json -Depth 10
```

**JavaScript Consumption**:
```javascript
const fs = require('fs');
const result = JSON.parse(fs.readFileSync('result.json', 'utf8'));
```

---

## Decision 5: Branch Name Parsing for Spec Detection

**Decision**: Use regex pattern matching with fuzzy fallback

**Rationale**:
- SpecKit branch naming convention: `NNN-feature-name` (3 digits + description)
- Regex: `^(\d{3})-(.+)$` extracts spec number and feature name
- Fuzzy matching: If directory `specs/NNN-*` exists, use first match
- Graceful degradation: If no match, skip spec validation (e.g., bugfix branches)

**Implementation**:
```powershell
param([string]$BranchName)

# Extract spec number
if ($BranchName -match '^(\d{3})-') {
    $specNumber = $Matches[1]

    # Find matching spec directory
    $specDirs = Get-ChildItem "$RepoRoot/specs" -Directory |
                Where-Object { $_.Name -like "$specNumber-*" }

    if ($specDirs) {
        $specDir = $specDirs[0]
        # Validate spec artifacts...
    } else {
        Write-Output "Spec directory not found for branch: $BranchName"
    }
} else {
    Write-Output "Branch doesn't follow spec naming convention, skipping spec validation"
}
```

**Edge Cases Handled**:
- Branch name: `015-pr-validation-enhancement` → Spec: `specs/015-pr-validation-enhancement/`
- Branch name: `bugfix/typo-in-readme` → Skips spec validation
- Branch name: `015-feature` → Finds `specs/015-feature-full-name/` (fuzzy match)

---

## Decision 6: Path Traversal Detection Approach

**Decision**: Static analysis with pattern matching

**Rationale**:
- Path traversal vulnerabilities occur when user input constructs file paths
- PowerShell best practice: Use `Join-Path` instead of string concatenation
- Detection: Search for string concatenation patterns in path construction
- Focus on functions that accept user/external input

**Detection Patterns**:
1. **Unsafe string concatenation**: `$basePath + "\" + $userInput`
2. **Unsafe interpolation**: `"$basePath\$userInput"`
3. **Direct `..\` usage**: `$path.Contains("..")`
4. **User input in path without validation**: Parameters used in paths without whitelist

**Safe Patterns to Ignore**:
1. `Join-Path $basePath $safePath` - Using approved cmdlet
2. `[System.IO.Path]::Combine($a, $b)` - Using .NET method
3. Static paths: `"C:\Program Files\App\config.json"` (no variables)

**Implementation**:
```powershell
# Check for unsafe path construction
$unsafePatterns = @(
    '\$\w+\s*\+\s*["\']\\',  # $path + "\"
    '"\$\w+\\[^"]+"',        # "$path\file"
    'Contains\(["\']\.\.["\']\)'  # .Contains("..")
)

$findings = @()
foreach ($file in $psFiles) {
    $content = Get-Content $file.FullName -Raw
    foreach ($pattern in $unsafePatterns) {
        if ($content -match $pattern) {
            $findings += @{
                file = $file.FullName
                pattern = $pattern
                message = "Potential path traversal vulnerability"
            }
        }
    }
}
```

---

## Decision 7: Dependency Vulnerability Scanning Approach

**Decision**: Manual CVE checking with known-vulnerable list

**Rationale**:
- This project has minimal dependencies (Pester, PSScriptAnalyzer)
- PowerShell Gallery doesn't have CVE database API (unlike npm, PyPI)
- Maintain curated list of known-vulnerable versions
- Check installed module versions against list
- Future: Integrate with GitHub Dependabot when PowerShell support added

**Known Vulnerabilities to Check**:
- Pester < 5.0.0 (various security issues in v4.x)
- PSScriptAnalyzer (no known CVEs as of 2025-01)

**Implementation**:
```powershell
$vulnerableVersions = @{
    'Pester' = @{
        'VulnerableVersions' = @('4.0.0', '4.10.1')
        'MinSafeVersion' = '5.0.0'
        'CVE' = 'N/A'
    }
}

$installedModules = Get-InstalledModule
foreach ($module in $installedModules) {
    if ($vulnerableVersions.ContainsKey($module.Name)) {
        $vulnInfo = $vulnerableVersions[$module.Name]
        if ($module.Version -in $vulnInfo.VulnerableVersions) {
            Write-Output "Vulnerable: $($module.Name) $($module.Version)"
        }
    }
}
```

**Future Enhancement**: Integrate with [GitHub Advisory Database API](https://docs.github.com/en/rest/security-advisories/global-advisories) when PowerShell ecosystem coverage improves.

---

## Decision 8: Constitution Compliance Validation Strategy

**Decision**: Static analysis using AST parsing and regex patterns

**Rationale**:
- PowerShell Abstract Syntax Tree (AST) provides structured code analysis
- Can detect missing `Export-ModuleMember` statements programmatically
- Regex patterns can detect `Import-Module` in .psm1 files
- Can verify comment-based help presence
- Lightweight and fast (no external tools needed)

**Checks to Implement**:

1. **Module Export Check**:
```powershell
$moduleFiles = Get-ChildItem scripts/modules -Filter *.psm1
foreach ($file in $moduleFiles) {
    $content = Get-Content $file.FullName -Raw
    if ($content -notmatch 'Export-ModuleMember') {
        # Flag violation
    }
}
```

2. **Nested Import Check**:
```powershell
foreach ($file in $moduleFiles) {
    $content = Get-Content $file.FullName -Raw
    if ($content -match 'Import-Module') {
        # Flag violation
    }
}
```

3. **Comment Help Check** (for new exported functions):
```powershell
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $file.FullName, [ref]$null, [ref]$null
)

$functions = $ast.FindAll({$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]}, $true)
foreach ($func in $functions) {
    $help = $func.GetHelpContent()
    if (-not $help.Synopsis) {
        # Flag violation
    }
}
```

---

## Decision 9: GitHub API Rate Limit Handling

**Decision**: Rely on GitHub Actions built-in token with 5000 req/hour limit

**Rationale**:
- GitHub Actions automatically provides `GITHUB_TOKEN` with 5000 req/hour
- PR validation uses ~5-10 API calls per PR (list comments, create/update comments)
- Even with 100 PRs per hour, well within rate limit
- If rate limited, GitHub Actions will retry automatically
- No need for custom retry logic or token rotation

**API Calls Per PR**:
- List existing comments: 1 call
- Update/create comment (Steps 2-6): 5 calls
- Total: ~6 calls per PR validation run

**Rate Limit Buffer**: 5000 / 6 = 833 PR validations per hour (highly unlikely to hit)

**Error Handling**:
```javascript
try {
  const comments = await github.rest.issues.listComments({...});
} catch (error) {
  if (error.status === 403 && error.message.includes('rate limit')) {
    core.warning('GitHub API rate limit exceeded. Retrying later...');
    // GitHub Actions will auto-retry
  } else {
    throw error;
  }
}
```

---

## Decision 10: Non-Blocking Workflow Strategy

**Decision**: Use `continue-on-error: true` with summary job

**Rationale**:
- Validation should inform, not block (except authorization)
- `continue-on-error: true` allows step to fail without failing entire workflow
- Final summary job aggregates all step results
- Maintainers see all validation results, can still merge if needed

**Implementation**:
```yaml
security-review:
  runs-on: ubuntu-latest
  continue-on-error: true  # Non-blocking
  steps:
    - name: Run validation
      # ...

validation-summary:
  needs: [step-2, step-3, step-4, step-5, step-6]
  runs-on: ubuntu-latest
  if: always()  # Run even if previous steps failed
  steps:
    - name: Summarize Results
      run: |
        echo "Validation complete. Check PR comments for details."
        echo "Note: Validation failures are informational, not blocking."
```

---

## Summary of Technology Decisions

| Area | Technology | Rationale |
|------|------------|-----------|
| Secret Scanning | GitLeaks v2 | Industry standard, native GitHub Action |
| PowerShell Security | PSScriptAnalyzer | Official MS tool, already in use |
| PR Commenting | actions/github-script@v7 | Direct GitHub API access, standard pattern |
| Comment Identification | HTML markers | Invisible, searchable, update-in-place support |
| Output Format | Structured JSON | Parseable, validatable, standard |
| Branch Parsing | Regex + fuzzy match | Robust, handles edge cases |
| Path Security | Static analysis + patterns | Fast, no runtime overhead |
| Dependency Scanning | Manual CVE list | Pragmatic for limited dependencies |
| Constitution Check | AST + regex | Programmatic, accurate |
| Rate Limiting | GitHub Actions token | Built-in, sufficient capacity |
| Non-Blocking | continue-on-error | Informational validation |

---

## Best Practices Identified

1. **Workflow Permissions**: Always specify minimum required permissions explicitly
2. **Comment Size Limits**: GitHub comment max size is 65536 characters - truncate large outputs
3. **Timestamp Format**: Use ISO 8601 in UTC for comment timestamps
4. **Error Context**: Include file path, line number, and remediation guidance in all findings
5. **Markdown Formatting**: Use consistent emoji status indicators (✅⚠️❌)
6. **JSON Depth**: Use `-Depth 10` in `ConvertTo-Json` to avoid truncation
7. **Workflow Caching**: Cache PSScriptAnalyzer module installation across runs
8. **Test Fixtures**: Include intentionally vulnerable code samples in test fixtures
9. **Documentation**: Document each validation check's purpose and how to fix violations
10. **Graceful Degradation**: Skip optional checks if tools unavailable, never fail hard

---

## Open Questions Resolved

1. **Q**: Should we use separate comments for each sub-check or combined?
   **A**: Combined per step (Steps 2-6) for cleaner PR conversation

2. **Q**: How to handle very large validation outputs?
   **A**: Truncate with summary (e.g., "Showing first 10 of 50 findings") + link to logs

3. **Q**: Should spec validation be strict or fuzzy?
   **A**: Fuzzy with clear error messages - detect `NNN-*` pattern, skip non-feature branches

4. **Q**: How to prevent comment spam if workflow runs multiple times quickly?
   **A**: GitHub Actions has built-in concurrency control - use `concurrency` key to cancel in-progress runs

5. **Q**: Should we block on failed security checks?
   **A**: No - informational only. Maintainers decide if issues warrant blocking merge

---

**Phase 0 Status**: ✅ **COMPLETE**

All technology decisions documented. No unresolved clarifications remain. Ready to proceed to Phase 1 (Design & Contracts).
