# GitHub Actions Workflows

This directory contains automated workflows for the SpecKit Safe Update Skill, including quality checks, access control, and automated maintenance.

## Workflow Overview

| Workflow | Purpose | Trigger | Status Required |
|----------|---------|---------|-----------------|
| **claude.yml** | @claude mention handling | Issue/PR comments | ✅ Blocking |
| **claude-code-review.yml** | Automated PR reviews | PR open/sync | ℹ️ Informational |
| **quality-checks.yml** | Code quality validation | Push/PR | ✅ Blocking |
| **pr-guardrails.yml** | PR validation | PR open/sync | ⚠️ Warning |
| **test.yml** | Basic unit tests | Push/PR | ✅ Blocking |
| **update-fingerprints.yml** | Database maintenance | Daily schedule | ℹ️ Automated |

---

## Security & Access Control

### claude.yml - @claude Mention Handler (Access Controlled)

**Purpose**: Processes @claude mentions in issues, PRs, and comments with authorization checks.

**Triggers**:
- Issue comments containing `@claude`
- Pull request review comments containing `@claude`
- Pull request reviews containing `@claude`
- New issues with `@claude` in title or body

**Authorization**:
- **Repository Owner**: Always authorized
- **Collaborators**: Authorized if `allow_collaborators: true` in config
- **Org Members**: Authorized if `allow_org_members: true` in config
- **Allowlist Users**: Listed in `.github/claude-authorized-users.yml`
- **All Others**: ❌ Silently rejected (no workflow execution)

**Security Features**:
- ✅ Early authorization check - unauthorized users trigger no execution
- ✅ Emergency circuit breaker (`emergency.disable_all: true`)
- ✅ Audit logging of all authorization attempts
- ✅ Configurable via `.github/claude-authorized-users.yml`

**Configuration File**: `.github/claude-authorized-users.yml`
```yaml
authorized_users:
  - NotMyself  # Repository owner
  - trusted-contributor

settings:
  allow_collaborators: true
  allow_org_members: true
  block_first_time_contributors: true

emergency:
  disable_all: false  # Set to true to disable ALL @claude triggers
```

**How It Works**:
1. **Detect @claude mention** - Check if @claude appears in content
2. **Authorize user** - Check user against owner/collaborators/allowlist
3. **Execute if authorized** - Run Claude Code action
4. **Log result** - Audit log shows actor, association, reason

**Permissions Required**:
- `contents: read`
- `pull-requests: read`
- `issues: read`
- `id-token: write`
- `actions: read` (for CI results)

---

### claude-code-review.yml - Automated PR Reviews (Access Controlled)

**Purpose**: Automatically runs Claude Code review on PRs from authorized users.

**Triggers**:
- Pull request opened
- Pull request synchronized (new commits pushed)

**Authorization**: Same as claude.yml (uses `.github/claude-authorized-users.yml`)

**Review Criteria**:
- Code quality and best practices
- Potential bugs or issues
- Performance considerations
- Security concerns
- Test coverage

**Permissions Required**:
- `contents: read`
- `pull-requests: read`
- `issues: read`
- `id-token: write`

**Review Posting**: Uses `gh pr comment` to post review feedback

**Note**: This is different from claude.yml:
- **claude.yml**: Manual @claude mentions (user-triggered)
- **claude-code-review.yml**: Automatic reviews (event-triggered)

---

## Quality Checks

### quality-checks.yml - Code Quality Validation

**Purpose**: Comprehensive code quality validation using PSScriptAnalyzer, module compliance, and test coverage.

**Triggers**:
- Push to main/develop branches
- Pull requests to main/develop
- Changes to PowerShell files (`scripts/**/*.ps1`, `scripts/**/*.psm1`, `tests/**/*.ps1`)

**Checks**:

#### 1. **PSScriptAnalyzer Linting**
- Runs PSScriptAnalyzer with project-specific rules
- Configuration: `PSScriptAnalyzerSettings.psd1`
- ✅ **Blocks merge** on errors
- ⚠️ **Warns** on style violations

**Rules Enforced**:
- Security (no plain text passwords, proper credential handling)
- Performance (no Invoke-Expression, variable usage)
- Best practices (comment-based help, approved verbs)
- Style (consistent whitespace, indentation, alignment)
- Compatibility (PowerShell 7.0+ cross-platform)

#### 2. **Module Import Compliance**
- Prevents nested module imports (modules importing other modules)
- Enforces orchestrator-managed imports pattern
- ✅ **Blocks merge** if violations found

**Why This Matters**: Nested imports create scope isolation bugs where functions imported within a module are not accessible to the calling script.

#### 3. **Unit Tests with Coverage**
- Runs all unit tests with Pester 5.x
- Generates code coverage report (JaCoCo format)
- ✅ **Blocks merge** if tests fail
- ℹ️ **Reports** coverage percentage (70% threshold target)

**Coverage Threshold**: Currently informational (not blocking), will enforce in future.

**Artifacts**:
- Test results: `tests/TestResults/` (30 day retention)
- Coverage report: `tests/coverage/` (30 day retention)

**Example Output**:
```
✅ PSScriptAnalyzer: No issues found
✅ Module Import Compliance: Passed (0 violations)
✅ Unit Tests: 245 passed, 0 failed
ℹ️  Code Coverage: 72.3% (meets 70% threshold)
```

**Status**: ✅ **Required** - must pass to merge

---

### pr-guardrails.yml - Pull Request Validation

**Purpose**: Validates PR completeness, size, and documentation updates.

**Triggers**:
- Pull request opened, synchronized, reopened, or edited
- PRs to main or develop branches

**Checks**:

#### 1. **PR Size Check**
Analyzes lines changed and categorizes PRs:

| Size | Lines | Status | Recommendation |
|------|-------|--------|----------------|
| **XS** | <200 | ✅ Excellent | Ideal for review |
| **S** | 200-499 | ✅ Good | Easy to review |
| **M** | 500-999 | ⚠️ Large | Consider splitting |
| **L** | 1000-1999 | ⚠️ Very Large | Strongly recommend splitting |
| **XL** | 2000+ | 🚫 **Blocks** | Must split or justify |

**Rationale**: Large PRs are harder to review, more likely to introduce bugs, and take longer to merge.

#### 2. **PR Description Check**
- ✅ **Requires** non-empty description (min 50 chars)
- ⚠️ **Warns** if testing information missing
- ℹ️ **Reports** checklist completion status

#### 3. **CHANGELOG.md Check**
- ⚠️ **Warns** if CHANGELOG.md not updated
- Automatically skips for:
  - Docs-only PRs (only `*.md` files)
  - Test-only PRs (only `tests/` files)
  - PRs with `WIP:`, `chore:`, `test:`, `docs:` prefix

**When Required**: Feature and fix PRs affecting code behavior

#### 4. **Related Issue Check**
- ℹ️ **Recommends** linking to related issue
- Detects patterns: `Fixes #123`, `Closes #123`, `Relates to #123`

**Status**: ⚠️ **Warning** - provides feedback but doesn't block merge (except XL PRs)

---

## Existing Workflows

### test.yml - Basic Unit Tests

**Purpose**: Runs unit tests on Windows with Pester.

**Triggers**:
- Push to main/develop
- Pull requests to main

**Note**: This workflow is **superseded by quality-checks.yml** which includes tests plus linting and coverage. Consider deprecating test.yml in favor of the more comprehensive quality-checks.yml.

**Steps**:
1. Checkout code
2. Install Pester 5.x
3. Run unit tests
4. Upload test results

**Status**: ✅ **Required** - must pass to merge

---

### update-fingerprints.yml - Automated Database Maintenance

**Purpose**: Automatically maintains the SpecKit fingerprint database by detecting new releases and updating the database.

**Triggers**:
- **Schedule**: Runs daily at 2 AM UTC
- **Manual**: Can be triggered via workflow_dispatch with optional force update

**What it does**:
1. Checks current fingerprint database version
2. Queries GitHub API for latest SpecKit release
3. If new release found:
   - Regenerates fingerprint database using `scripts/generate-fingerprints.ps1`
   - Verifies changes
   - Creates a pull request with updated database
4. If no new release: Exits gracefully

**Outputs**:
- Pull request with updated `data/speckit-fingerprints.json`
- PR includes version stats and size information
- Auto-labeled with `automated`, `database-update`, `relates-to-#25`

**Permissions Required**:
- `contents: write` - To commit database changes
- `pull-requests: write` - To create PRs

**Environment Variables**:
- `GITHUB_TOKEN` - Provided automatically by GitHub Actions
  - Used to query SpecKit releases API
  - Used to create pull requests

**Manual Trigger**:
```bash
# Via GitHub CLI
gh workflow run update-fingerprints.yml

# Force update even if no new releases
gh workflow run update-fingerprints.yml -f force_update=true
```

**Related Files**:
- Generator script: `scripts/generate-fingerprints.ps1`
- Database: `data/speckit-fingerprints.json`
- Feature PRD: `docs/PRDs/004-Smart-Merge-Frictionless-Onboarding.md`
- GitHub Issue: #25

---

## Managing Access Control

### Adding Authorized Users

Edit `.github/claude-authorized-users.yml`:

```yaml
authorized_users:
  - NotMyself
  - new-trusted-contributor  # Add here
```

### Removing Access

Remove username from `authorized_users` list or set individual settings to `false`.

### Emergency Shutdown

If you detect abuse or need to quickly disable Claude Code:

```yaml
emergency:
  disable_all: true  # Disables ALL @claude triggers immediately
  disable_reason: "Maintenance in progress"
```

### Viewing Authorization Logs

Check Actions logs for authorization decisions:
1. Go to repository Actions tab
2. Select "Claude Code" or "Claude Code Review" workflow
3. View "Check Authorization" job logs

Example log output:
```
🔐 Checking authorization for @username...
Author Association: CONTRIBUTOR
🚫 User @username is NOT authorized to trigger @claude
   Reason: Not in authorized users list and not a collaborator/owner
```

---

## Quality Standards Summary

### Required for Merge (Blocking)
- ✅ All unit tests passing
- ✅ PSScriptAnalyzer with no errors
- ✅ Module import compliance
- ✅ PR description present
- ✅ PR size <2000 lines (or justified)

### Recommended (Warning)
- ⚠️ PSScriptAnalyzer warnings fixed
- ⚠️ Code coverage ≥70%
- ⚠️ CHANGELOG.md updated (for code changes)
- ⚠️ PR size <1000 lines
- ⚠️ Testing information in PR description

### Informational
- ℹ️ Related issue linked
- ℹ️ Checklist items completed
- ℹ️ Claude Code automated review feedback

---

## Troubleshooting

### "Unauthorized to trigger @claude"

**Cause**: User is not in authorized users list and not a collaborator/owner.

**Solution**:
1. Check if user is in `.github/claude-authorized-users.yml`
2. Check if `allow_collaborators` is enabled (for collaborators)
3. Add user to `authorized_users` list if trusted

### "PSScriptAnalyzer failed"

**Cause**: PowerShell code violates linting rules.

**Solution**:
1. Run locally: `Invoke-ScriptAnalyzer -Path . -Recurse -Settings PSScriptAnalyzerSettings.psd1`
2. Fix errors shown in output
3. Re-run tests: `./tests/test-runner.ps1`

### "Module import compliance failed"

**Cause**: A `.psm1` file contains `Import-Module` statement.

**Solution**:
1. Remove `Import-Module` from the module file
2. Move import to orchestrator (`scripts/update-orchestrator.ps1`)
3. See `.specify/memory/constitution.md` - Module Import Rules

### "PR size too large"

**Cause**: PR changes >2000 lines.

**Solution**:
- **Option 1**: Split PR into multiple smaller PRs (recommended)
- **Option 2**: Add justification in PR description (e.g., "Generated code", "Data files", "Refactoring")

---

## Workflow Dependencies

```
Pull Request Opened/Updated
    ↓
    ├── quality-checks.yml (Blocking)
    │   ├── PSScriptAnalyzer
    │   ├── Module Import Compliance
    │   └── Unit Tests + Coverage
    │
    ├── pr-guardrails.yml (Warning)
    │   ├── PR Size
    │   ├── PR Description
    │   ├── CHANGELOG.md
    │   └── Related Issue
    │
    ├── claude-code-review.yml (Informational)
    │   └── Automated Code Review (if authorized)
    │
    └── test.yml (Blocking - legacy)
        └── Unit Tests Only

@claude Mention
    ↓
    └── claude.yml
        ├── Authorization Check
        └── Claude Code Execution (if authorized)

Daily 2 AM UTC
    ↓
    └── update-fingerprints.yml
        └── Database Update PR
```

---

## Future Enhancements

Potential workflow improvements:

- **Security Scanning**: CodeQL, secret scanning, dependency vulnerabilities
- **Performance Testing**: Benchmark critical functions, detect regressions
- **Documentation Validation**: Broken link checker, spelling, grammar
- **Automated Releases**: Version tagging, release notes generation
- **Dependency Updates**: Dependabot for PowerShell modules
- **Commit Message Validation**: Enforce conventional commits format

---

## Configuration Files

| File | Purpose |
|------|---------|
| `.github/claude-authorized-users.yml` | Access control for Claude Code |
| `PSScriptAnalyzerSettings.psd1` | Linting rules configuration |
| `.github/pull_request_template.md` | PR checklist template |

---

## Getting Help

- **Workflow Failures**: Check Actions tab for detailed logs
- **Authorization Issues**: Review `.github/claude-authorized-users.yml`
- **Quality Check Failures**: Run checks locally before pushing
- **Questions**: Open an issue or check CONTRIBUTING.md

---

**Last Updated**: 2025-10-24
**Maintained By**: Repository Owner (NotMyself)
