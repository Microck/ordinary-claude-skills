# Contributing to SpecKit Safe Update Skill

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## Development Setup

### Prerequisites

- PowerShell 7+
- Git
- VSCode (recommended)
- Pester 5.x testing framework

### Getting Started

1. Fork the repository
2. Clone your fork:
   ```powershell
   git clone https://github.com/YOUR_USERNAME/claude-win11-speckit-update-skill
   cd claude-win11-speckit-update-skill
   ```

3. Install Pester (if not already installed):
   ```powershell
   Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
   ```

## Current State (v0.4.0)

The project is **feature-complete** and released. Recent additions include:

- ✅ **Automatic SpecKit Installation** (v0.4.0): Offers to install SpecKit in non-SpecKit projects
- ✅ **Smart Conflict Resolution**: Two-tier system (Git markers for small files, side-by-side diffs for large files)
- ✅ **False Positive Detection**: Auto-resolves conflicts where files are identical to upstream
- ✅ **Customization Preservation**: Detects and preserves user customizations
- ✅ **Automatic Backups**: Timestamped backups with retention management
- ✅ **Conversational Approval**: Two-step workflow designed for Claude Code
- ✅ **Constitution Integration**: Seamless integration with `/speckit.constitution` command

See [CHANGELOG.md](CHANGELOG.md) for complete version history.

## Project Structure

```
claude-Win11-SpecKit-Safe-Update-Skill/
├── scripts/
│   ├── update-orchestrator.ps1       # Main entry point (16-step workflow)
│   ├── modules/                       # PowerShell modules (6 files)
│   │   ├── HashUtils.psm1            # Normalized hashing
│   │   ├── VSCodeIntegration.psm1    # Context detection
│   │   ├── GitHubApiClient.psm1      # GitHub Releases API
│   │   ├── ManifestManager.psm1      # Manifest CRUD
│   │   ├── BackupManager.psm1        # Backup/restore
│   │   └── ConflictDetector.psm1     # File state analysis
│   └── helpers/                       # Helper functions (7 files)
│       ├── Invoke-PreUpdateValidation.ps1  # Prerequisites & installation offer
│       ├── Show-UpdateSummary.ps1          # Results display
│       ├── Show-UpdateReport.ps1           # Check-only mode
│       ├── Get-UpdateConfirmation.ps1      # Conversational approval
│       ├── Invoke-ConflictResolutionWorkflow.ps1
│       ├── Invoke-RollbackWorkflow.ps1
│       └── Invoke-ThreeWayMerge.ps1
├── tests/
│   ├── unit/                          # Unit tests (245+ tests)
│   ├── integration/                   # Integration tests (12 scenarios)
│   └── fixtures/                      # Test data
├── specs/                             # Feature specifications
│   ├── 001-safe-update/              # Core update spec
│   └── 010-helpful-error-messages/   # Installation feature spec
└── templates/                         # Template files
```

## Development Workflow

This project uses **SpecKit** for feature development. Follow the SpecKit workflow for all new features:

### 1. Create a Feature Specification

```
/speckit.specify
```

This will guide you through creating a complete specification in `specs/NNN-feature-name/spec.md` with:
- User stories and acceptance criteria
- Data model and entities
- API contracts (if applicable)
- Test scenarios

### 2. Generate Implementation Plan

```
/speckit.plan
```

This creates a detailed implementation plan in `specs/NNN-feature-name/plan.md` covering:
- Tech stack decisions
- File structure
- Component architecture
- Integration points

### 3. Generate Task Breakdown

```
/speckit.tasks
```

This generates an actionable task list in `specs/NNN-feature-name/tasks.md` with:
- Dependency-ordered tasks
- Parallel execution markers
- Test-first approach
- Validation checkpoints

### 4. Create a Branch

```powershell
git checkout -b NNN-feature-name
```

Use the spec number prefix (e.g., `010-helpful-error-messages`) for consistency.

### 5. Implement the Feature

```
/speckit.implement
```

This executes the task plan, or you can implement manually following the tasks.

### 6. Make Changes

Follow these guidelines:

**PowerShell Code Style:**
- Use PascalCase for function names (`Get-FileState`)
- Use camelCase for variables (`$fileName`)
- Use proper cmdlet binding with `[CmdletBinding()]`
- Include comment-based help for all exported functions
- Use try-catch-finally for error handling
- Add verbose logging with `Write-Verbose`

**Example:**
```powershell
function Get-Example {
    <#
    .SYNOPSIS
        Short description
    .DESCRIPTION
        Longer description
    .PARAMETER Name
        Parameter description
    .EXAMPLE
        Get-Example -Name "test"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    try {
        Write-Verbose "Processing: $Name"
        # Implementation
    }
    catch {
        Write-Error "Error: $($_.Exception.Message)"
        throw
    }
}
```

### 7. Write Tests

All new functionality must include tests (often generated as part of Step 5):

**Unit Tests:**
- Create in `tests/unit/`
- Name pattern: `ModuleName.Tests.ps1`
- Use Pester 5.x syntax (`Describe`, `Context`, `It`)
- Mock external dependencies
- Test both success and error cases

**Example:**
```powershell
Describe "Get-Example" {
    Context "When called with valid input" {
        It "Returns expected result" {
            $result = Get-Example -Name "test"
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context "When called with invalid input" {
        It "Throws an error" {
            { Get-Example -Name "" } | Should -Throw
        }
    }
}
```

### 8. Run Tests

```powershell
# Run all tests
./tests/test-runner.ps1

# Run unit tests only
./tests/test-runner.ps1 -Unit

# Run integration tests only
./tests/test-runner.ps1 -Integration

# Run with code coverage
./tests/test-runner.ps1 -Coverage
```

### 9. Update Documentation

- Update README.md if adding user-facing features (focus on end-user benefits)
- Update CHANGELOG.md under [Unreleased] section (detailed technical changes)
- Update SKILL.md if changing command behavior
- Update CLAUDE.md if changing architecture or development patterns
- Add inline comments for complex logic
- Update spec files (spec.md, plan.md, tasks.md) to reflect actual implementation

### 10. Commit Changes

```powershell
git add .
git commit -m "feat: add new feature"
# or
git commit -m "fix: resolve issue with X"
```

**Commit Message Format:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `test:` Test additions/changes
- `refactor:` Code refactoring
- `style:` Formatting changes
- `chore:` Maintenance tasks

### 11. Push and Create Pull Request

```powershell
git push origin NNN-feature-name
```

Then create a pull request on GitHub, referencing the spec number in the title and description.

### Why Use SpecKit?

This project dogfoods SpecKit to demonstrate its value:
- **Complete specifications** ensure all requirements are captured upfront
- **Implementation plans** reduce architectural surprises mid-development
- **Task breakdowns** make complex features manageable
- **Living documentation** in `specs/` directory serves as project memory

See `specs/010-helpful-error-messages/` for a complete example of the SpecKit workflow in action.

## Pull Request Guidelines

### Before Submitting

- [ ] All tests pass locally
- [ ] Code follows PowerShell style guidelines
- [ ] New functionality includes tests
- [ ] Documentation is updated
- [ ] No merge conflicts with main branch
- [ ] Commit messages are clear and descriptive

#### PowerShell-Specific Checks

- [ ] **Module vs. Helper Pattern**:
  - [ ] New helper scripts (`.ps1` in `scripts/helpers/`) do NOT use `Export-ModuleMember`
  - [ ] New modules (`.psm1` in `scripts/modules/`) DO use `Export-ModuleMember`
  - [ ] Use `templates/helper-template.ps1` as starting point for helpers
  - [ ] Use `templates/module-template.psm1` as starting point for modules
- [ ] **Error Handling**:
  - [ ] Module import logic in orchestrator uses proper error handling (no blanket suppression)
  - [ ] No `-ErrorAction SilentlyContinue` on `Import-Module` calls (masks real errors)
  - [ ] No `2>$null` redirection on helper dot-sourcing (masks real errors)
  - [ ] Try-catch blocks with stack trace logging for real errors
- [ ] **Code Standards**:
  - [ ] All new PowerShell functions have comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`)
  - [ ] Verbose logging added with `Write-Verbose` for debugging
  - [ ] Error messages are clear and actionable

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
Describe how you tested your changes

## Checklist
- [ ] Tests added/updated
- [ ] All tests passing (`./tests/test-runner.ps1`)
- [ ] Lint check passes (no `Import-Module` in `.psm1` files - see constitution)
- [ ] Code review: Verified no nested module imports
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
```

## Automated PR Validation

When you submit a pull request, it automatically goes through a comprehensive 6-step validation workflow:

### Step 1: Authorization (Blocking)
- Verifies PR author is authorized to contribute
- Checks: repository owner, collaborator, organization member, or explicit allowlist
- **Blocking**: PRs from unauthorized users fail here

### Step 2: PR Guardrails (Non-blocking)
- **PR Size Check**: Warns if PR exceeds 2000 lines (owner bypass allowed)
- **Description Check**: Warns if PR description is too short or missing
- **Feedback**: Posted as PR comment (updates in place on new commits)

### Step 3: Quality Checks (Non-blocking)
- **PSScriptAnalyzer Linting**: Validates code against style rules
- **Pester Unit Tests**: Runs `./tests/test-runner.ps1 -Unit`
- **Feedback**: Aggregates lint and test results in PR comment
- **Non-blocking**: Known Pester 5.x scoping issues won't fail PR

### Step 4: Code Review (Optional)
- **Claude Code Review**: Automated review if `CLAUDE_CODE_OAUTH_TOKEN` secret is configured
- Checks: code quality, best practices, potential bugs, documentation

### Step 5: Security Scan (Non-blocking)
- **GitLeaks Secret Scanning**: Detects hardcoded API keys, tokens, passwords (100+ patterns)
- **PSScriptAnalyzer Security Rules**: Checks for insecure PowerShell patterns
- **Dependency Vulnerabilities**: Scans PowerShell modules for known vulnerabilities
- **Path Traversal Detection**: Identifies unsafe path operations
- **Feedback**: Posted as detailed PR comment with file:line references

### Step 6: SpecKit Compliance (Non-blocking)
- **Feature Branch Validation**: Parses branch name (format: `NNN-feature-name`)
- **Spec Artifacts**: Validates `specs/NNN-feature-name/` directory structure
  - Checks for `spec.md` with required sections (User Scenarios, Requirements, Success Criteria)
  - Checks for `plan.md` and `tasks.md`
- **CHANGELOG Validation**: Ensures `CHANGELOG.md` has `[Unreleased]` section
- **Constitution Compliance**: Validates PowerShell module patterns
  - All `.psm1` files must have `Export-ModuleMember`
  - No nested `Import-Module` in modules
- **Feedback**: Posted as PR comment with specific remediation guidance

### Comment System
- Each validation step posts a PR comment with unique marker (e.g., `<!-- pr-validation:step-5 -->`)
- Comments **update in place** on new commits (no duplicate comments)
- Status indicators: `[PASS]`, `[WARN]`, `[FAIL]`
- Includes file locations, code snippets, and remediation guidance

### What to Expect
- **Non-blocking validation**: You can still merge PRs with warnings (except authorization)
- **Actionable feedback**: Comments include specific fixes and file locations
- **Progressive enhancement**: Fix issues incrementally, comments update automatically
- **Performance**: Typical workflow completes in 4-6 minutes

See [docs/workflows/pr-validation.md](docs/workflows/pr-validation.md) for detailed documentation, troubleshooting, and configuration options.

## Code Review Process

1. Automated PR validation runs (6 steps above)
2. Review automated feedback in PR comments
3. Fix any security issues or critical errors
4. Maintainer reviews code
5. Address any feedback
6. Once approved, maintainer merges PR

## Reporting Issues

### Bug Reports

Include:
- PowerShell version (`$PSVersionTable.PSVersion`)
- Operating system
- Steps to reproduce
- Expected behavior
- Actual behavior
- Error messages (if any)
- Relevant logs

### Feature Requests

Include:
- Clear description of the feature
- Use case(s)
- Why it would be useful
- Potential implementation approach (optional)

## Areas to Contribute

### High Priority
- Additional test coverage
- Bug fixes
- Documentation improvements
- Performance optimizations

### Medium Priority
- New helper functions
- Enhanced error messages
- Better user prompts
- Additional validation checks

### Future Enhancements
- GitHub token authentication support
- Partial updates (specific files/directories)
- Team version locking
- Migration from older manifest formats

## Questions?

- Open an issue for discussion
- Check existing issues for related topics
- Review the specification in `specs/001-safe-update/`

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
