# Implementation Plan: PR Validation Workflow Enhancement

**Branch**: `014-pr-validation-enhancement` | **Date**: 2025-10-25 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/014-pr-validation-enhancement/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Enhance the GitHub Actions PR validation workflow to provide comprehensive, non-blocking validation with intelligent PR comment reporting. The feature transforms placeholder security and spec review steps into actionable checks that post findings as updateable PR comments, enabling contributors to receive immediate feedback on security issues, spec compliance, and code quality while maintaining a clean PR conversation through update-in-place comment behavior.

**Primary Requirement**: Implement Steps 5 (Security Scan) and 6 (SpecKit Compliance) with four security checks and four compliance checks respectively, while adding PR comment infrastructure that updates existing comments rather than creating duplicates.

**Technical Approach**: Extend existing GitHub Actions workflow with new validation steps using GitHub Actions script for comment management, GitLeaks for secret scanning, PSScriptAnalyzer for PowerShell security rules, and custom PowerShell scripts for path traversal checks, dependency scanning, and spec compliance validation.

## Technical Context

**Language/Version**: PowerShell 7.0+, YAML (GitHub Actions), Bash (GitHub Actions environment)
**Primary Dependencies**: GitLeaks (secret scanning), PSScriptAnalyzer (PowerShell linting), actions/github-script@v7 (PR commenting)
**Storage**: N/A (stateless validation, results posted as PR comments)
**Testing**: Pester 5.x (PowerShell validation scripts), GitHub Actions test PRs (workflow validation)
**Target Platform**: GitHub Actions runners (ubuntu-latest), Windows PowerShell 7+ (validation scripts)
**Project Type**: CI/CD workflow enhancement (GitHub Actions YAML + PowerShell validation scripts)
**Performance Goals**: Validation feedback within 3 minutes of commit push, comment updates complete within 30 seconds
**Constraints**: GitHub API rate limits (5000 req/hour with token), workflow execution time <10 minutes, comment size <65536 characters
**Scale/Scope**: 5 validation steps (Steps 2-6), 8 security/compliance sub-checks, supports PRs up to 2000 lines changed

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Modular Architecture
**Status**: ✅ COMPLIANT

**Assessment**: This feature creates validation scripts in `.github/scripts/` (not the main module directory). The validation scripts are stateless PowerShell scripts that analyze code and return JSON results. They follow modular design:
- `check-dependencies.ps1` - Dependency vulnerability scanning
- `check-path-security.ps1` - Path traversal detection
- `check-spec-compliance.ps1` - SpecKit compliance validation
- `format-pr-comment.ps1` - Reusable comment formatting

These scripts are NOT part of the core module architecture (scripts/modules/) and don't need to follow `.psm1` module conventions. They're standalone validation tools invoked by GitHub Actions.

### Principle II: Fail-Fast with Rollback
**Status**: ✅ NOT APPLICABLE

**Assessment**: This feature is read-only validation. No file modifications, no state changes, no need for rollback. Validation scripts analyze code and post comments but never modify the repository. If validation fails, the only action is posting a PR comment - there's no state to roll back.

### Principle III: Customization Detection via Normalized Hashing
**Status**: ✅ NOT APPLICABLE

**Assessment**: This feature doesn't deal with file customization detection. It validates code for security issues and compliance, not tracking customizations. Hashing is not used.

### Principle IV: User Confirmation Required
**Status**: ✅ NOT APPLICABLE

**Assessment**: This is automated CI/CD validation running on every PR commit. No user confirmation needed or possible - GitHub Actions runs automatically. The validation is non-blocking (doesn't prevent merge), providing information only.

### Principle V: Testing Discipline
**Status**: ✅ COMPLIANT (to be validated in Phase 1)

**Assessment**: All validation scripts MUST have corresponding Pester unit tests:
- `tests/unit/CheckDependencies.Tests.ps1` - Test dependency scanner
- `tests/unit/CheckPathSecurity.Tests.ps1` - Test path traversal detector
- `tests/unit/CheckSpecCompliance.Tests.ps1` - Test spec validator
- `tests/unit/FormatPRComment.Tests.ps1` - Test comment formatter

Integration tests should verify end-to-end GitHub Actions workflow execution (may use test PRs or workflow mocks).

**Phase 1 Re-check**: Ensure test file structure is defined in data-model.md and included in tasks.

### Principle VI: Architectural Verification Before Suggestions
**Status**: ✅ COMPLIANT

**Assessment**: This feature correctly identifies the execution context:
- GitHub Actions runs on ubuntu-latest runners (full OS environment)
- Validation scripts execute in GitHub Actions environment with full tool access
- PR commenting uses GitHub Actions `github-script` which has direct API access
- No cross-process communication issues (GitHub Actions → GitHub API is native)
- No GUI assumptions (all text-based output to workflow logs and PR comments)

The design avoids architectural anti-patterns:
- ✅ Uses GitHub API for comments (not trying to access VSCode UI)
- ✅ Uses text-based validation outputs (JSON to stdout)
- ✅ No assumptions about PowerShell subprocess isolation from Claude Code

### Module Import Rules
**Status**: ✅ NOT APPLICABLE

**Assessment**: This feature doesn't create new PowerShell modules in `scripts/modules/`. Validation scripts are standalone scripts in `.github/scripts/` and don't need module import orchestration. If they need shared utilities, they can dot-source helper functions but should not use `Import-Module`.

### Summary
**Overall Status**: ✅ **PASSED** - No constitution violations

All applicable principles are satisfied. This feature is approved to proceed to Phase 0 research.

## Project Structure

### Documentation (this feature)

```
specs/014-pr-validation-enhancement/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0: Technology decisions and best practices
├── data-model.md        # Phase 1: Validation result structures and comment schemas
├── quickstart.md        # Phase 1: Quick reference for adding new validation checks
├── contracts/           # Phase 1: JSON schemas for validation outputs and PR comments
│   ├── validation-finding.schema.json
│   ├── pr-comment.schema.json
│   └── check-result.schema.json
└── tasks.md             # Phase 2: Implementation tasks (/speckit.tasks command)
```

### Source Code (repository root)

```
.github/
├── workflows/
│   └── pr-validation.yml        # MODIFIED: Add Steps 5-6, PR comment infrastructure
└── scripts/                      # NEW: Validation scripts directory
    ├── check-dependencies.ps1    # NEW: Scan dependencies for CVEs
    ├── check-path-security.ps1   # NEW: Detect path traversal vulnerabilities
    ├── check-spec-compliance.ps1 # NEW: Validate SpecKit artifacts and constitution
    └── format-pr-comment.ps1     # NEW: Format validation results as Markdown

tests/
├── unit/
│   ├── CheckDependencies.Tests.ps1    # NEW: Test dependency scanner
│   ├── CheckPathSecurity.Tests.ps1    # NEW: Test path security validator
│   ├── CheckSpecCompliance.Tests.ps1  # NEW: Test spec compliance validator
│   └── FormatPRComment.Tests.ps1      # NEW: Test comment formatter
├── integration/
│   └── PRValidationWorkflow.Tests.ps1 # NEW: Test end-to-end workflow
└── fixtures/                          # NEW: Test data for validation scripts
    ├── vulnerable-code-samples/       # Sample files with security issues
    ├── spec-structures/               # Sample spec directories (valid/invalid)
    └── pr-comment-examples/           # Expected comment outputs

docs/
└── workflows/
    └── pr-validation.md               # NEW: Documentation for PR validation workflow
```

**Structure Decision**: CI/CD workflow enhancement with validation scripts

This feature extends the existing GitHub Actions infrastructure by:

1. **Modifying existing workflow**: `.github/workflows/pr-validation.yml` gets new Steps 5-6 and PR comment posting logic added to Steps 2-4
2. **Adding validation scripts**: New `.github/scripts/` directory contains PowerShell validation scripts invoked by workflow
3. **Adding tests**: New unit tests in `tests/unit/` for validation scripts, new integration test for workflow
4. **Adding fixtures**: New `tests/fixtures/` directory with sample code for validation testing
5. **Adding documentation**: New `docs/workflows/pr-validation.md` explaining validation steps and troubleshooting

The validation scripts are standalone (not part of `scripts/modules/` core architecture) because they're CI/CD tools, not part of the SpecKit update workflow.

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

**Status**: N/A - No constitution violations detected

All constitution principles are either satisfied or not applicable to this feature. No complexity justifications required.

---

## Phase 0: Research Summary

✅ **COMPLETE** - See [research.md](research.md)

All technology decisions documented:
- GitLeaks v2 for secret scanning
- PSScriptAnalyzer for PowerShell security rules
- actions/github-script@v7 for PR comment management
- HTML markers for update-in-place behavior
- Structured JSON output format
- Branch name parsing with regex + fuzzy matching
- Path traversal detection via static analysis
- Manual CVE checking for dependencies
- Constitution compliance via AST parsing
- GitHub API rate limit handling

---

## Phase 1: Design Summary

✅ **COMPLETE** - See [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Data Entities Defined**:
1. ValidationResult - Top-level validation output
2. ValidationFinding - Individual issue discovered
3. PRComment - Structured PR comment with metadata
4. CommentSection - Individual section within comment
5. SpecArtifact - SpecKit documentation file tracking
6. ConstitutionViolation - Constitution rule violation
7. SecurityIssue - Security vulnerability or exposed secret

**Contracts Created**:
- `validation-result.schema.json` - ValidationResult JSON schema
- `validation-finding.schema.json` - ValidationFinding JSON schema
- `pr-comment.schema.json` - PRComment JSON schema

**Quickstart Guide**: Complete developer reference for adding validation checks, testing, and troubleshooting

**Agent Context**: Updated CLAUDE.md with new technology stack

---

## Phase 2: Next Steps

This plan is now complete. The next command to run is:

```
/speckit.tasks
```

This will generate the implementation tasks (tasks.md) based on the design artifacts created in this planning phase.

**Planning Status**: ✅ **COMPLETE** - Ready for task generation

