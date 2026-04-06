# Implementation Plan: Fix Version Parameter Handling in Update Orchestrator

**Branch**: `005-fix-version-parameter` | **Date**: 2025-10-20 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/005-fix-version-parameter/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Fix critical bug where the update orchestrator fails with "missing mandatory parameters: SpecKitVersion" error when attempting to update without specifying an explicit version. The primary issues are:
1. Null or invalid `$targetRelease` object when GitHub API call fails silently
2. Lack of validation before accessing `$targetRelease.tag_name` property
3. Missing error handling for GitHub API failures with actionable user messages

The fix will add robust validation, improved error handling, and ensure consistent function parameter usage across the codebase.

## Technical Context

**Language/Version**: PowerShell 7.0+
**Primary Dependencies**:
- PowerShell Core 7.0+ (cross-platform)
- Pester 5.x (unit testing framework)
- Invoke-RestMethod (built-in cmdlet for GitHub API calls)

**Storage**:
- File-based manifest (`.specify/manifest.json`)
- Backup storage (`.specify/backups/`)
- Template files in `.specify/` and `.claude/commands/`

**Testing**:
- Pester 5.x for unit tests (`tests/unit/`)
- Pester 5.x for integration tests (`tests/integration/`)
- Mock GitHub API responses for offline testing

**Target Platform**: Windows 11 (primary), cross-platform PowerShell support (secondary)
**Project Type**: PowerShell module-based skill for Claude Code CLI
**Performance Goals**:
- API calls complete within 5 seconds under normal network conditions
- Error messages display within 3 seconds of failure detection
- Update orchestration completes in under 30 seconds for typical projects

**Constraints**:
- GitHub API rate limiting: 60 requests/hour (unauthenticated)
- Must work offline for `-Rollback` mode
- No external dependencies beyond PowerShell built-ins
- Backward compatibility with existing manifests

**Scale/Scope**:
- Single-user CLI skill
- Typical project: 8-15 SpecKit template files
- Manifest size: <50KB
- Supports projects with any number of custom commands

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Modular Architecture (NON-NEGOTIABLE)

**Status**: ✅ PASS

**Analysis**: This bug fix maintains modular architecture:
- Business logic changes confined to `GitHubApiClient.psm1` module (error handling, validation)
- Orchestrator changes limited to validation checks before function calls
- No new modules required; enhancing existing modules only
- Helper functions unchanged (no UI changes for this fix)

**Actions**:
- Add validation logic to `Get-LatestSpecKitRelease` function
- Add error handling to `Invoke-GitHubApiRequest` (already has some, enhance it)
- Add null checks in orchestrator before accessing `$targetRelease` properties

### II. Fail-Fast with Rollback (NON-NEGOTIABLE)

**Status**: ✅ PASS

**Analysis**: Current failure occurs before backup creation (Step 4), so rollback is not applicable. However, improved error handling will:
- Fail early with clear error message
- Exit with appropriate error code (3 for network/API errors)
- No rollback needed as no destructive operations occur before API validation

**Actions**:
- Ensure errors use exit code 3 for GitHub API failures
- Validate `$targetRelease` immediately after API call, before any file operations

### III. Customization Detection via Normalized Hashing

**Status**: ✅ PASS (Not Affected)

**Analysis**: This bug fix does not impact hash calculation or customization detection. No changes to `HashUtils.psm1` or hashing logic required.

### IV. User Confirmation Required

**Status**: ✅ PASS (Not Affected)

**Analysis**: Errors occur before confirmation step. Improved error messages will help users understand failures before they reach confirmation. No changes to confirmation workflow.

### V. Testing Discipline

**Status**: ⚠️  REQUIRES ACTION

**Analysis**: This bug fix requires new tests:
- Unit tests for `Get-LatestSpecKitRelease` with null/invalid responses
- Unit tests for error scenarios (network failures, rate limiting, invalid JSON)
- Integration tests for orchestrator behavior when GitHub API fails
- Mock tests to simulate GitHub API edge cases

**Actions**:
- Add test cases to `tests/unit/GitHubApiClient.Tests.ps1`
- Add integration test scenarios to `tests/integration/UpdateOrchestrator.Tests.ps1`
- Create mock GitHub API responses in `tests/fixtures/mock-responses/`

### PowerShell Standards

**Status**: ✅ PASS

**Analysis**: All changes will follow existing PowerShell standards:
- Use `Write-Error` for error messages
- Use `Write-Verbose` for diagnostic logging
- Maintain comment-based help for all modified functions
- Follow try-catch-finally error handling patterns

### Module Import Rules

**Status**: ✅ PASS (Not Affected)

**Analysis**: No new module imports required. `GitHubApiClient.psm1` already has no nested imports. Orchestrator already imports all required modules in correct order.

**Verification**: This fix does not introduce any `Import-Module` statements in module files.

## Project Structure

### Documentation (this feature)

```
specs/005-fix-version-parameter/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (GitHub API patterns, error handling)
├── data-model.md        # Phase 1 output (API response structure, error types)
├── quickstart.md        # Phase 1 output (developer testing guide)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created yet)
```

### Source Code (repository root)

```
scripts/
├── update-orchestrator.ps1          # Add $targetRelease validation (lines 229-235)
├── modules/
│   └── GitHubApiClient.psm1         # Enhance error handling in Get-LatestSpecKitRelease
└── helpers/
    └── (no changes required)

tests/
├── unit/
│   └── GitHubApiClient.Tests.ps1    # Add error scenario tests
├── integration/
│   └── UpdateOrchestrator.Tests.ps1 # Add GitHub API failure tests
└── fixtures/
    └── mock-responses/              # Add mock API responses
        ├── valid-release.json       # Complete GitHub release structure
        ├── missing-tag-name.json    # Malformed response missing tag_name
        ├── empty-response.json      # Null/empty API response
        └── invalid-version-format.json  # Non-semantic version format
```

**Structure Decision**: This is a single PowerShell project with module-based architecture. No structural changes required - only enhancing existing modules with better validation and error handling. The fix touches two primary files:
1. `scripts/modules/GitHubApiClient.psm1` - Add validation and error handling
2. `scripts/update-orchestrator.ps1` - Add null checks before using `$targetRelease`

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

**Status**: No violations - this section is empty.

All constitution principles are satisfied. No complexity justification needed.