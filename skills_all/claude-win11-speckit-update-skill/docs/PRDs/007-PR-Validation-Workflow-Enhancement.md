# PRD: PR Validation Workflow Enhancement

**GitHub Issue:** [#32](https://github.com/NotMyself/claude-win11-speckit-update-skill/issues/32)

## Executive Summary

Enhance the GitHub Actions PR validation workflow to provide comprehensive, non-blocking validation with intelligent reporting. Transform the current placeholder security and spec review steps into actionable checks that post findings as PR comments, updating them on subsequent runs to keep the conversation clean.

**Problem:** Steps 5 (Security Review) and 6 (Spec Review) are placeholders with TODOs. Several existing steps fail PRs even when failures are informational, and there's no persistent visibility into validation results within the PR conversation.

**Solution:** Implement all 6 validation steps as non-blocking checks (except authorization) that post findings as updateable PR comments. Add comprehensive security scanning and intelligent SpecKit compliance validation.

**Impact:** Contributors get immediate, actionable feedback on every commit. Maintainers have full visibility into all validation aspects without noise from duplicate comments. PR process becomes educational rather than punitive.

## Problem Statement

The current PR validation workflow (`.github/workflows/pr-validation.yml`) has several gaps:

**Current Pain Points:**
- **Step 5 (Security Review):** Placeholder with "TODO: Add security scanning"
- **Step 6 (Spec Review):** Placeholder with "TODO: Add SpecKit compliance validation"
- **Blocking failures:** Some steps fail PRs when they should be informational (e.g., unit tests with known Pester issues)
- **No PR comments:** Validation results only visible in GitHub Actions logs, not in PR conversation
- **Comment spam:** If we add comments naively, each new commit creates duplicate comments
- **Lost context:** Maintainers must dig through CI logs to understand what failed

**Real-World Scenario:**
1. Contributor submits PR with new feature
2. Forgets to update CHANGELOG.md
3. Accidentally commits `.env` file with test token
4. PR passes all checks (security placeholder does nothing)
5. Maintainer must manually review for these issues
6. Back-and-forth in comments requesting changes
7. Time wasted on preventable issues

## Goals

### Primary Goals
1. **Implement Step 5 (Claude Security Scan)** with 4 security checks
2. **Implement Step 6 (SpecKit Compliance)** with intelligent spec validation
3. **Add PR comment reporting** for all steps (2-6) with update-in-place behavior
4. **Convert to non-blocking** for all steps except authorization
5. **Improve maintainer experience** with comprehensive, persistent validation feedback

### Secondary Goals
- Educate contributors through helpful validation messages
- Reduce back-and-forth review cycles by catching common issues early
- Maintain clean PR conversations (no comment spam)
- Provide actionable guidance when checks fail

### Non-Goals (v1)
- **Auto-fixing issues:** Don't automatically commit fixes (stay read-only)
- **Interactive prompts:** All validation must be fully automated
- **Cross-repo validation:** Only validate current repository
- **Historical analysis:** Only validate current PR state, not commit history (except secret scanning)

## User Stories

### Story 1: Contributor Gets Immediate Feedback
**As a** contributor submitting a PR
**I want to** see validation results as comments on my PR
**So that** I can fix issues before the maintainer reviews

**Acceptance Criteria:**
- Each validation step posts a comment with findings
- Comments use clear emoji indicators (✅ ⚠️ ❌)
- Failed checks provide actionable guidance on how to fix
- Comments appear within 2-3 minutes of pushing commits

### Story 2: Maintainer Reviews Comprehensive Validation
**As a** maintainer reviewing a PR
**I want to** see all validation results in one place
**So that** I can make informed merge decisions without digging through CI logs

**Acceptance Criteria:**
- All 6 steps have visible results in PR conversation
- Non-blocking failures don't prevent merge, just inform decision
- Comments persist across commits (update in place, don't duplicate)
- Summary shows overall validation status

### Story 3: Security Issues Are Caught Early
**As a** contributor working on a feature
**I want to** be warned if I accidentally commit secrets or create security vulnerabilities
**So that** I can fix them before they're merged

**Acceptance Criteria:**
- Secret scanning detects common patterns (API keys, tokens, passwords)
- PowerShell security rules catch risky patterns (Invoke-Expression, plain text passwords)
- Path traversal checks validate file path handling
- Findings posted as PR comment with severity indicators

### Story 4: Spec-Driven Development Is Enforced
**As a** contributor working on a feature branch
**I want to** be reminded if my spec/plan/tasks are incomplete
**So that** I follow the SpecKit workflow and maintain project standards

**Acceptance Criteria:**
- Branch name `010-feature-name` triggers check for `specs/010-feature-name/`
- Validates presence of spec.md, plan.md, tasks.md
- Checks CHANGELOG.md has entry under [Unreleased]
- Reports constitution compliance issues (module architecture, testing, etc.)

### Story 5: Updated PR Doesn't Spam Comments
**As a** contributor updating my PR with fixes
**I want to** see validation comments update in place
**So that** the PR conversation stays clean and readable

**Acceptance Criteria:**
- First commit: Creates 5 comments (one per step 2-6)
- Subsequent commits: Updates existing comments (no duplicates)
- Comments have identifiable markers (e.g., "<!-- pr-validation:step-2 -->")
- Timestamps show when each comment was last updated

## Technical Design

### Step Architecture

**Step 1: Authorization (BLOCKING ✋)**
- Current behavior: Checks user authorization via config file
- Status: Already implemented, no changes needed
- Failure mode: Exits workflow immediately if unauthorized

**Step 2: Size and Description (NON-BLOCKING ⚠️)**
- Current behavior: Checks PR size and description quality
- Enhancement: Add PR comment with findings
- Failure mode: Warns but continues

**Step 3: Linting and Testing (NON-BLOCKING ⚠️)**
- Current behavior: Runs PSScriptAnalyzer, module lint check, unit tests
- Enhancement: Add PR comment with test results summary
- Failure mode: Warns but continues (known Pester issues)

**Step 4: Claude Code Review (NON-BLOCKING ⚠️)**
- Current behavior: Optional Claude Code AI review
- Enhancement: Already posts comments, ensure consistent format
- Failure mode: Skips if no token, warns but continues

**Step 5: Claude Security Scan (NON-BLOCKING ⚠️) - NEW IMPLEMENTATION**

Four sub-checks:

1. **Secret Scanning (GitLeaks)**
   - Tool: `gitleaks/gitleaks-action@v2`
   - Scans: Commit history, file contents
   - Detects: API keys, tokens, passwords, credentials
   - Output: JSON report → formatted PR comment

2. **PowerShell Security (PSScriptAnalyzer)**
   - Tool: PSScriptAnalyzer with security rule subset
   - Rules:
     - `PSAvoidUsingPlainTextForPassword`
     - `PSAvoidUsingConvertToSecureStringWithPlainText`
     - `PSUsePSCredentialType`
     - `PSAvoidUsingInvokeExpression`
   - Output: Severity-based report (Error/Warning)

3. **Dependency Vulnerability Scanning**
   - Tool: Custom PowerShell script
   - Checks: Pester version for known CVEs (minimal deps in this project)
   - Future: Integrate with PowerShell Gallery security advisories when available
   - Output: List of vulnerable dependencies (if any)

4. **Path Traversal & Injection Checks**
   - Tool: Custom validation script
   - Checks:
     - File path construction uses `Join-Path` (not string concatenation)
     - No user input directly in `Invoke-Expression` or `Invoke-Command`
     - Manifest file paths validated before use
     - No `..` path components in user-controllable paths
   - Output: List of potential vulnerabilities with file:line references

**Step 6: SpecKit Compliance (NON-BLOCKING ⚠️) - NEW IMPLEMENTATION**

Four sub-checks:

1. **Smart Spec Validation**
   - Logic: Extract spec number from branch name (e.g., `010-feature` → `010`)
   - Check: `specs/{number}-{name}/` directory exists
   - Validate:
     - `spec.md` exists and has required sections (User Stories, Technical Design, etc.)
     - `plan.md` exists and is non-empty
     - `tasks.md` exists and is non-empty
   - Output: Missing files/sections, completeness percentage

2. **Documentation Completeness**
   - Check:
     - `CHANGELOG.md` has entry under `[Unreleased]` section
     - If user-facing change: `README.md` modified in PR
     - If new module: Corresponding test file exists in `tests/unit/`
   - Output: List of missing documentation

3. **Constitution Compliance**
   - Validate against `.specify/memory/constitution.md` principles:
     - **Module architecture:** New business logic in `.psm1` files (not helpers)
     - **Export rules:** Modules use `Export-ModuleMember`, helpers don't
     - **Module imports:** No `Import-Module` in `.psm1` files (orchestrator only)
     - **Error handling:** Try-catch-finally in critical operations
     - **Comment help:** New exported functions have `.SYNOPSIS`, `.PARAMETER`, etc.
   - Tool: Custom PowerShell script (static analysis)
   - Output: List of violations with file:line references

4. **Test Coverage (Informational)**
   - Check: Modified modules have corresponding test updates
   - Tool: Git diff + test file presence check
   - Output: List of modified modules without test changes (informational only)

### PR Comment Management

**Comment Identification Strategy:**

Each step posts a comment with a unique HTML marker:

```markdown
<!-- pr-validation:step-2 -->
## 📏 Step 2/6: Size and Description

**Status:** ⚠️ Warning

- **PR Size:** 350 lines (within 2000 limit)
- **Description:** Too short (12 chars, minimum 20)

### Recommendation
Add a more detailed description explaining what this PR does.

---
*Last updated: 2025-01-20 14:32 UTC*
```

**Update Logic:**

```yaml
- name: Post or update PR comment
  uses: actions/github-script@v7
  with:
    script: |
      const marker = '<!-- pr-validation:step-2 -->';
      const body = `${marker}\n## 📏 Step 2/6: Size and Description\n...`;

      // Find existing comment
      const comments = await github.rest.issues.listComments({
        owner: context.repo.owner,
        repo: context.repo.repo,
        issue_number: context.issue.number,
      });

      const existing = comments.data.find(c => c.body.includes(marker));

      if (existing) {
        // Update existing comment
        await github.rest.issues.updateComment({
          owner: context.repo.owner,
          repo: context.repo.repo,
          comment_id: existing.id,
          body: body,
        });
      } else {
        // Create new comment
        await github.rest.issues.createComment({
          owner: context.repo.owner,
          repo: context.repo.repo,
          issue_number: context.issue.number,
          body: body,
        });
      }
```

**Permissions Required:**

```yaml
permissions:
  contents: read
  pull-requests: write  # Required for posting/updating comments
  issues: write         # Required for issue comments (PRs are issues)
```

### Workflow Changes

**Before (Current State):**

```yaml
# Step 5: Placeholder
security-review:
  name: "5️⃣ Security Check"
  steps:
    - run: echo "TODO: Add security scanning"
```

**After (Proposed):**

```yaml
# Step 5: Claude Security Scan
security-review:
  name: "5️⃣ Claude Security Scan"
  runs-on: ubuntu-latest
  continue-on-error: true  # Non-blocking
  permissions:
    contents: read
    pull-requests: write
    issues: write
  steps:
    - name: Checkout code
      uses: actions/checkout@v4
      with:
        fetch-depth: 0  # Full history for secret scanning

    # Sub-check 1: Secret Scanning
    - name: Run GitLeaks
      uses: gitleaks/gitleaks-action@v2
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

    # Sub-check 2: PowerShell Security
    - name: Run PSScriptAnalyzer Security Rules
      shell: pwsh
      run: |
        Install-Module PSScriptAnalyzer -Force -Scope CurrentUser
        $results = Invoke-ScriptAnalyzer -Path . -Recurse -IncludeRule PSAvoidUsingPlainTextForPassword,PSAvoidUsingInvokeExpression,...
        # Format results as JSON
        $results | ConvertTo-Json > security-lint.json

    # Sub-check 3: Dependency Scanning
    - name: Check Dependencies
      shell: pwsh
      run: |
        # Custom script to check for vulnerable dependencies
        ./.github/scripts/check-dependencies.ps1

    # Sub-check 4: Path Traversal Checks
    - name: Validate Path Handling
      shell: pwsh
      run: |
        # Custom script to detect path traversal risks
        ./.github/scripts/check-path-security.ps1

    # Post combined results as PR comment
    - name: Post Security Scan Results
      uses: actions/github-script@v7
      if: always()
      with:
        script: |
          // Read results from all sub-checks
          // Format as unified comment
          // Post or update comment with marker
```

### New Scripts to Create

**`.github/scripts/check-dependencies.ps1`**
- Checks Pester, PSScriptAnalyzer versions for known CVEs
- Returns JSON with vulnerable dependencies

**`.github/scripts/check-path-security.ps1`**
- Static analysis for path traversal patterns
- Regex checks for dangerous patterns
- Returns JSON with findings

**`.github/scripts/check-spec-compliance.ps1`**
- Extracts branch name to detect spec association
- Validates spec directory structure
- Checks constitution compliance
- Returns JSON with findings

**`.github/scripts/format-pr-comment.ps1`**
- Utility to format findings as Markdown
- Reusable across all steps
- Generates consistent comment structure

## Implementation Phases

### Phase 1: Infrastructure Setup (Week 1)
**Goal:** Set up PR comment posting/updating infrastructure

**Tasks:**
1. Create reusable GitHub Actions workflow for posting comments
2. Implement comment identification with HTML markers
3. Test update-in-place logic with dummy comments
4. Update existing steps 2-3 to post comments
5. Verify no duplicate comments on subsequent commits

**Success Criteria:**
- Steps 2-3 post updateable comments
- No duplicate comments after 3 test commits
- Comments have timestamps and status indicators

### Phase 2: Step 5 - Security Scanning (Week 2)
**Goal:** Implement all 4 security checks

**Tasks:**
1. Integrate GitLeaks for secret scanning
2. Configure PSScriptAnalyzer security rule subset
3. Create dependency vulnerability check script
4. Create path traversal validation script
5. Combine results into unified PR comment
6. Test with PRs containing intentional security issues

**Success Criteria:**
- GitLeaks detects test API key in commit
- PSScriptAnalyzer flags `Invoke-Expression` usage
- Path check detects `..` in file paths
- All findings posted as single comment with sections

### Phase 3: Step 6 - Spec Compliance (Week 2)
**Goal:** Implement smart spec validation

**Tasks:**
1. Create branch name → spec directory mapping logic
2. Implement spec.md/plan.md/tasks.md completeness checks
3. Create CHANGELOG.md validation
4. Implement constitution compliance static analysis
5. Create test coverage informational check
6. Combine results into unified PR comment

**Success Criteria:**
- Branch `010-feature` triggers `specs/010-feature/` validation
- Missing spec.md flagged in comment
- Missing CHANGELOG entry detected
- Module without `Export-ModuleMember` flagged

### Phase 4: Step 4 Enhancement (Week 3)
**Goal:** Ensure Claude Code Review uses same comment format

**Tasks:**
1. Verify Claude Code action posts comments (already does)
2. Add HTML marker for update-in-place behavior
3. Ensure consistent formatting with other steps

**Success Criteria:**
- Claude review comment updates in place
- Format matches other validation steps

### Phase 5: Convert to Non-Blocking (Week 3)
**Goal:** Make all steps except authorization non-blocking

**Tasks:**
1. Add `continue-on-error: true` to steps 2-6
2. Update final validation-complete job to report, not fail
3. Update README/docs to explain non-blocking approach
4. Test that failed checks don't prevent merge

**Success Criteria:**
- PR with failed checks can still merge
- Validation-complete job summarizes all results
- No workflow failures from informational checks

### Phase 6: Documentation & Testing (Week 4)
**Goal:** Document new workflow and validate with real PRs

**Tasks:**
1. Update CONTRIBUTING.md with validation step descriptions
2. Create docs/workflows/pr-validation.md explaining each step
3. Add troubleshooting guide for common failures
4. Test workflow with 5 different PR scenarios
5. Gather feedback from maintainers

**Success Criteria:**
- Contributors understand what each check does
- Maintainers can interpret validation results
- Workflow handles edge cases gracefully

## Testing Strategy

### Unit Testing
**What to test:**
- Individual validation scripts (`check-dependencies.ps1`, etc.)
- Comment formatting logic
- Branch name parsing for spec detection

**How:**
- Pester tests for PowerShell scripts
- Mock GitHub API responses
- Test with known vulnerable dependencies

### Integration Testing
**What to test:**
- End-to-end workflow execution
- Comment posting and updating
- Multi-commit PR scenarios

**How:**
- Create test PRs with intentional issues
- Verify comments appear and update correctly
- Test with different branch naming patterns

### Validation Scenarios

**Scenario 1: Clean PR**
- All checks pass
- 5 comments with ✅ status
- No action items

**Scenario 2: Security Issues**
- GitLeaks finds API key
- PSScriptAnalyzer flags Invoke-Expression
- Comment shows 2 findings with file:line
- Non-blocking (PR can merge)

**Scenario 3: Incomplete Spec**
- Branch: `015-new-feature`
- Missing `specs/015-new-feature/tasks.md`
- CHANGELOG.md not updated
- Comment lists missing items

**Scenario 4: Updated PR**
- First commit: 3 failures
- Fix issues, push new commit
- Comments update (don't duplicate)
- Timestamps reflect update time

**Scenario 5: Non-Spec Branch**
- Branch: `bugfix/typo-in-readme`
- No spec directory expected
- Spec validation skipped
- Only CHANGELOG check runs

## Success Metrics

### Quantitative Metrics
1. **Comment update rate:** 100% (no duplicate comments)
2. **False positive rate:** <5% (checks don't flag correct code)
3. **Time to feedback:** <3 minutes from push to comment
4. **Detection rate:** >90% for common issues (secrets, missing docs)

### Qualitative Metrics
1. **Contributor satisfaction:** Feedback is actionable and helpful
2. **Maintainer efficiency:** Less time spent on preventable issues
3. **Code quality:** Fewer security issues and incomplete specs merged
4. **Onboarding:** New contributors understand standards from validation feedback

### Key Performance Indicators (KPIs)
- **Before:** 40% of PRs require maintainer comments for missing docs/specs
- **After (Target):** <10% require manual requests for docs/specs
- **Before:** Average 2-3 review cycles per PR
- **After (Target):** Average 1-2 review cycles per PR

## Rollout Plan

### Stage 1: Canary Deployment (Week 1)
- Deploy to test branch `test/pr-validation`
- Create 3 test PRs with various scenarios
- Monitor GitHub Actions usage (ensure no quota issues)
- Gather initial feedback from maintainers

### Stage 2: Limited Rollout (Week 2-3)
- Deploy to `develop` branch PRs only
- Monitor for false positives
- Refine validation rules based on feedback
- Update documentation

### Stage 3: Full Rollout (Week 4)
- Deploy to `main` branch PRs
- Announce in repository README
- Monitor for issues over 1 week
- Create rollback plan if needed

### Rollback Plan
If critical issues arise:
1. Revert workflow file to previous version
2. Disable problematic steps with `if: false`
3. Post issue to track root cause
4. Fix in test branch before re-deploying

## Open Questions

1. **Rate Limits:** Will GitHub Actions API rate limits be an issue with 5 comments per PR?
   - *Mitigation:* Combine into single comment if needed

2. **Performance:** Will full history checkout for GitLeaks slow down workflow?
   - *Mitigation:* Run in parallel with other steps

3. **Token Requirements:** Does GitLeaks action require special permissions?
   - *Investigation needed:* Review gitleaks-action documentation

4. **False Positives:** Will path traversal check flag legitimate `Join-Path` usage?
   - *Mitigation:* Tune regex patterns, allow suppressions

5. **Spec Naming:** What if branch name doesn't match spec directory exactly?
   - *Decision:* Fuzzy matching (e.g., `010-feature-name` → `010-*`) or exact match only?

## Future Enhancements (Out of Scope for v1)

1. **Configurable Severity Thresholds**
   - Allow per-repo configuration of which checks are blocking
   - Support `.pr-validation.yml` config file

2. **Auto-Fix Suggestions**
   - Generate diffs for simple fixes (e.g., add CHANGELOG entry)
   - Post as code suggestions in PR comments

3. **Historical Trending**
   - Track validation metrics over time
   - Dashboard showing repository health trends

4. **Custom Validation Rules**
   - Plugin system for project-specific checks
   - Community-contributed validation scripts

5. **Cross-Repository Validation**
   - Check for breaking changes in dependent repositories
   - Validate API compatibility with consumers

## References

- [GitHub Actions: Creating and using encrypted secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [GitLeaks Action Documentation](https://github.com/gitleaks/gitleaks-action)
- [PSScriptAnalyzer Rules](https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/README.md)
- [GitHub Actions: Permissions for the GITHUB_TOKEN](https://docs.github.com/en/actions/security-guides/automatic-token-authentication#permissions-for-the-github_token)
- [Constitution: .specify/memory/constitution.md](../../.specify/memory/constitution.md)
- [Current Workflow: .github/workflows/pr-validation.yml](../../.github/workflows/pr-validation.yml)

## Appendix A: Comment Template Examples

### Step 2: Size and Description
```markdown
<!-- pr-validation:step-2 -->
## 📏 Step 2/6: Size and Description

**Status:** ✅ Pass

- **PR Size:** 142 lines (within 2000 limit)
- **Files Changed:** 3
- **Description:** Present and descriptive

---
*Last updated: 2025-01-20 14:32 UTC*
```

### Step 5: Claude Security Scan
```markdown
<!-- pr-validation:step-5 -->
## 🔒 Step 5/6: Claude Security Scan

**Status:** ⚠️ 2 Findings

### Secret Scanning
✅ No secrets detected

### PowerShell Security
❌ **1 issue found:**
- `scripts/helpers/Example.ps1:45` - Avoid using `Invoke-Expression` (security risk)
  ```powershell
  Invoke-Expression $userInput  # ❌ Dangerous
  ```
  **Recommendation:** Use `& $command` or validate input rigorously

### Dependency Vulnerabilities
✅ No known vulnerabilities in dependencies

### Path Traversal & Injection
⚠️ **1 potential issue:**
- `scripts/modules/FileHandler.psm1:23` - Path construction may allow traversal
  ```powershell
  $path = $baseDir + "\" + $userPath  # ⚠️ Use Join-Path
  ```
  **Recommendation:** Use `Join-Path $baseDir $userPath` for safe path construction

---
*Last updated: 2025-01-20 14:35 UTC*
```

### Step 6: SpecKit Compliance
```markdown
<!-- pr-validation:step-6 -->
## 📋 Step 6/6: SpecKit Compliance

**Status:** ⚠️ 3 Items Need Attention

### Spec Validation (Branch: `015-new-feature`)
✅ Spec directory found: `specs/015-new-feature/`
✅ `spec.md` present and complete
⚠️ `tasks.md` missing - generate with `/speckit.tasks`

### Documentation Completeness
❌ `CHANGELOG.md` not updated - add entry under `[Unreleased]`
✅ `README.md` updated (user-facing change detected)

### Constitution Compliance
⚠️ **1 violation found:**
- `scripts/modules/NewModule.psm1` - Missing `Export-ModuleMember` statement
  - See: [Constitution - Module Export Rules](../../.specify/memory/constitution.md#module-export-rules)

### Test Coverage (Informational)
⚠️ Modified modules without test updates:
- `scripts/modules/NewModule.psm1` → No test file found at `tests/unit/NewModule.Tests.ps1`

---
*Last updated: 2025-01-20 14:36 UTC*
```

## Appendix B: Validation Script Pseudocode

### check-spec-compliance.ps1
```powershell
param(
    [string]$BranchName,
    [string]$RepoRoot
)

# Extract spec number from branch (e.g., "015-new-feature" -> "015")
if ($BranchName -match '^(\d{3})-') {
    $specNumber = $Matches[1]
    $specDirs = Get-ChildItem "$RepoRoot/specs" -Directory | Where-Object { $_.Name -like "$specNumber-*" }

    if ($specDirs) {
        $specDir = $specDirs[0]

        # Check required files
        $specMd = Test-Path (Join-Path $specDir "spec.md")
        $planMd = Test-Path (Join-Path $specDir "plan.md")
        $tasksMd = Test-Path (Join-Path $specDir "tasks.md")

        # Validate spec.md content
        if ($specMd) {
            $content = Get-Content (Join-Path $specDir "spec.md") -Raw
            $hasUserStories = $content -match '## User Stories'
            $hasTechnicalDesign = $content -match '## Technical Design'
        }

        # Return findings
        [PSCustomObject]@{
            SpecFound = $true
            SpecDirectory = $specDir.Name
            SpecMdPresent = $specMd
            PlanMdPresent = $planMd
            TasksMdPresent = $tasksMd
            SpecComplete = $hasUserStories -and $hasTechnicalDesign
        }
    }
}

# Check CHANGELOG
$changelog = Get-Content "$RepoRoot/CHANGELOG.md" -Raw
$hasUnreleasedEntry = $changelog -match '\[Unreleased\][\s\S]+?-'

# Check constitution compliance
$violations = @()
Get-ChildItem "$RepoRoot/scripts/modules" -Filter "*.psm1" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -notmatch 'Export-ModuleMember') {
        $violations += [PSCustomObject]@{
            File = $_.Name
            Rule = "Missing Export-ModuleMember"
        }
    }
}

# Return JSON
@{
    SpecValidation = $specValidation
    ChangelogUpdated = $hasUnreleasedEntry
    ConstitutionViolations = $violations
} | ConvertTo-Json
```

---

**Document Version:** 1.0
**Created:** 2025-01-20
**Author:** Bobby Johnson
**Status:** Draft
**GitHub Issue:** [#32](https://github.com/NotMyself/claude-win11-speckit-update-skill/issues/32)
