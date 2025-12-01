# Implementation Plan: GitHub Personal Access Token Support

**Branch**: `012-github-token-support` | **Date**: 2025-10-23 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/012-github-token-support/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Enable the SpecKit updater to use GitHub Personal Access Tokens (PATs) for authenticated API requests, increasing rate limit from 60 requests/hour to 5,000 requests/hour. This is achieved by detecting the GITHUB_TOKEN environment variable and adding an Authorization header to all GitHub API requests. The implementation maintains full backward compatibility (works without token), follows security best practices (never logs token values), and provides helpful guidance when rate limits are hit.

**Technical Approach**: Modify the existing `Invoke-GitHubApiRequest` function in `GitHubApiClient.psm1` to detect `$env:GITHUB_TOKEN`, add OAuth Bearer authorization header when present, enhance error messages with token setup guidance, and update verbose logging to show authentication status without exposing secrets.

## Technical Context

**Language/Version**: PowerShell 7+
**Primary Dependencies**: None (uses built-in `Invoke-RestMethod` cmdlet)
**Storage**: N/A (environment variable only, no persistence)
**Testing**: Pester 5.x (unit tests) with manual integration verification
**Target Platform**: Windows 10/11 with PowerShell 7+, cross-compatible with macOS/Linux PowerShell
**Project Type**: Single project (PowerShell modules)
**Performance Goals**: No performance impact (header addition is negligible overhead)
**Constraints**:
- Must maintain backward compatibility (zero breaking changes)
- Must never log or persist token values (security requirement)
- Must work identically in terminal, Claude Code, and CI/CD contexts
- Must use standard GITHUB_TOKEN environment variable (ecosystem compatibility)

**Scale/Scope**: Single module modification (`scripts/modules/GitHubApiClient.psm1`), approximately 50 LOC changes, 6 new unit tests, 2 integration tests, documentation updates across 3 files

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### ✅ I. Modular Architecture (NON-NEGOTIABLE)
**Status**: PASS
**Rationale**: All changes are contained within the existing `GitHubApiClient.psm1` module. Token detection logic, header injection, and error message enhancement are implemented as modifications to the `Invoke-GitHubApiRequest` function. No helper functions or orchestrator modifications needed. Module remains independently testable with Pester mocks.

### ✅ II. Fail-Fast with Rollback (NON-NEGOTIABLE)
**Status**: PASS (N/A)
**Rationale**: This feature does not involve destructive file operations or state changes that require rollback. Token detection and header injection occur at API request time. Invalid tokens fail gracefully via GitHub API error responses (401 Unauthorized). No backup/rollback mechanism needed.

### ✅ III. Customization Detection via Normalized Hashing
**Status**: PASS (N/A)
**Rationale**: This feature does not involve file customization detection or manifest hashing. Token authentication is runtime behavior only.

### ✅ IV. User Confirmation Required
**Status**: PASS (N/A)
**Rationale**: No destructive operations require confirmation. Token usage is opt-in via environment variable. Users maintain full control by setting/unsetting `GITHUB_TOKEN`. Rate limit errors provide actionable guidance but do not modify system state.

### ✅ V. Testing Discipline
**Status**: PASS
**Rationale**: Feature includes comprehensive unit test suite in `tests/unit/GitHubApiClient.Tests.ps1`:
- Token detection when `$env:GITHUB_TOKEN` is set
- Authorization header construction (`Bearer {token}`)
- Verbose logging without token exposure
- Rate limit error message enhancement (with/without token)
- Invalid token handling (401 errors)

Integration tests verify:
- Real authenticated requests to GitHub API (with test token)
- Rate limit comparison (authenticated vs unauthenticated)

### ✅ VI. Architectural Verification Before Suggestions
**Status**: PASS
**Rationale**: Feature respects text-only I/O constraint:
- ✅ Input via environment variable (`$env:GITHUB_TOKEN`)
- ✅ Output via text streams (Write-Verbose, Write-Error)
- ✅ No GUI, VSCode APIs, or IPC required
- ✅ Works identically in terminal, Claude Code, and CI/CD contexts
- ✅ Conversational workflow supported (check-only mode shows status, user sets token, re-run succeeds)

**Module Import Compliance**: No new module dependencies introduced. `GitHubApiClient.psm1` remains a Tier 0 foundation module with no dependencies. Orchestrator import order unchanged.

**Conclusion**: All constitution principles satisfied. No violations to justify. Feature aligns with architectural constraints and testing requirements.

## Project Structure

### Documentation (this feature)

```
specs/012-github-token-support/
├── spec.md              # Feature specification (complete)
├── plan.md              # This file (implementation plan)
├── research.md          # Phase 0 output (research findings)
├── data-model.md        # Phase 1 output (data structures)
├── quickstart.md        # Phase 1 output (setup guide)
├── contracts/           # Phase 1 output (API contracts)
│   └── github-api-contract.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created yet)
```

### Source Code (repository root)

```
scripts/
├── modules/
│   ├── GitHubApiClient.psm1          # PRIMARY MODIFICATION TARGET
│   │                                 # - Add token detection (line ~45)
│   │                                 # - Add Authorization header (line ~46-48)
│   │                                 # - Update verbose logging (line ~49-53)
│   │                                 # - Enhance rate limit errors (line ~62-77)
│   │                                 # - Update comment-based help (line ~7-31)
│   │
│   ├── HashUtils.psm1                # No changes
│   ├── VSCodeIntegration.psm1        # No changes
│   ├── ManifestManager.psm1          # No changes
│   ├── BackupManager.psm1            # No changes
│   └── ConflictDetector.psm1         # No changes
│
├── helpers/                          # No changes to helpers
└── update-orchestrator.ps1           # No changes to orchestrator

tests/
├── unit/
│   ├── GitHubApiClient.Tests.ps1     # SIGNIFICANT ADDITIONS
│   │                                 # - New context: "Token Support"
│   │                                 # - 6 new test cases
│   │
│   └── [other test files]            # No changes
│
└── integration/
    ├── GitHubToken.Tests.ps1         # NEW FILE
    │                                 # - Authenticated request verification
    │                                 # - Rate limit comparison tests
    │
    └── UpdateOrchestrator.Tests.ps1  # No changes

docs/
├── PRDs/
│   └── 003-GitHub-Token-Support.md   # Existing PRD (reference document)
│
└── [other docs]                      # No changes to existing docs
```

**Additional Documentation Updates** (outside feature directory):

```
README.md                             # Add "Using GitHub Tokens" section
CLAUDE.md                             # Update "Troubleshooting - GitHub API Issues"
CHANGELOG.md                          # Add entry under [Unreleased]
CONTRIBUTING.md                       # No changes (no new workflow)
```

**Structure Decision**: Single project structure is appropriate. This is a focused enhancement to one existing module (`GitHubApiClient.psm1`). No new modules, no architectural changes, no cross-module dependencies. The PowerShell skill maintains its flat module structure with clear separation between modules (business logic) and helpers (orchestration).

## Complexity Tracking

*No violations to justify - all constitution gates passed.*

---

## Phase 0: Research & Technical Decisions

*See [research.md](research.md) for detailed findings.*

**Research Questions**:
1. What is the correct Authorization header format for GitHub API?
2. How does GitHub indicate rate limiting in API responses?
3. What are security best practices for handling tokens in PowerShell?
4. What error message patterns provide the best user experience?
5. How do CI/CD platforms provide GITHUB_TOKEN to workflows?

**Key Decisions**:
- Use `Authorization: Bearer {token}` header format (OAuth 2.0 standard)
- Detect rate limiting via HTTP 403 + `X-RateLimit-Remaining: 0` header
- Never log token values; use `Write-Verbose` for status only
- Include documentation link in rate limit errors
- Support standard `GITHUB_TOKEN` environment variable (ecosystem compatibility)

---

## Phase 1: Design Artifacts

*See [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)*

**Data Structures**:
- GitHub Personal Access Token (environment variable, 40-character string with `ghp_` prefix)
- Authentication Status (runtime boolean: authenticated vs unauthenticated)
- Rate Limit Response Headers (`X-RateLimit-Remaining`, `X-RateLimit-Reset`)

**API Contracts**:
- GitHub Releases API request headers (with/without Authorization)
- GitHub Releases API error responses (403 rate limit, 401 unauthorized)

**User Guide**:
- Step-by-step token creation on GitHub
- Setting GITHUB_TOKEN in PowerShell (session, profile, system)
- Verification steps (`-Verbose` output)
- CI/CD integration examples (GitHub Actions, Azure Pipelines, Jenkins)

---

## Phase 2: Task Generation

*Run `/speckit.tasks` after plan approval to generate dependency-ordered implementation tasks.*

**Anticipated Task Breakdown**:
1. Modify `Invoke-GitHubApiRequest` function (token detection, header injection)
2. Update comment-based help in `GitHubApiClient.psm1`
3. Enhance rate limit error messages with conditional token suggestion
4. Add unit tests for token detection and header construction
5. Add unit tests for verbose logging security (no token exposure)
6. Add unit tests for error message enhancement
7. Create integration test file for authenticated requests
8. Update README.md with token setup section
9. Update CLAUDE.md troubleshooting section
10. Update CHANGELOG.md under [Unreleased]
11. Manual testing: unauthenticated, authenticated, invalid token, rate limits
12. Security audit: verify no token exposure in logs, verbose output, files

**Critical Path**: Steps 1-3 must complete first (core functionality), then tests (4-7), then documentation (8-10), then verification (11-12).

---

## Implementation Notes

### Security Considerations
- **Token Exposure Prevention**: Use `Write-Verbose` for status messages only. Never include `$env:GITHUB_TOKEN` value in any output stream or exception message.
- **File Persistence**: Do NOT store tokens in manifest.json, configuration files, or any tracked files. Environment variable only.
- **Error Messages**: Ensure `catch` blocks do not serialize Authorization header values.
- **Testing**: Unit tests must verify token values never appear in captured verbose output.

### Backward Compatibility Verification
- All existing tests must pass without modification
- Command-line interface unchanged (no new parameters)
- Exit codes unchanged
- Works identically when `GITHUB_TOKEN` is not set

### CI/CD Integration
- Document standard `GITHUB_TOKEN` usage (recognized by GitHub Actions, gh CLI, Octokit)
- Provide copy-paste examples for GitHub Actions, Azure Pipelines, Jenkins
- Explain automatic provisioning in GitHub Actions (`secrets.GITHUB_TOKEN`)

### Testing Strategy
- **Unit Tests**: Mock `Invoke-RestMethod` to capture headers and verify Authorization presence
- **Integration Tests**: Use `$env:GITHUB_TEST_TOKEN` (optional, skipped if not set)
- **Security Tests**: Verify token never appears in `4>&1` stream capture (verbose output)
- **Manual Testing**: Document 6 manual test scenarios in research.md

---

## Success Criteria Validation

From [spec.md](spec.md#success-criteria-mandatory), this implementation satisfies:

- **SC-001**: ✅ Backward compatibility (no changes to unauthenticated flow)
- **SC-002**: ✅ 20+ consecutive runs (5,000/hour rate limit with token)
- **SC-003**: ✅ Token security (verbose logging tests verify no exposure)
- **SC-004**: ✅ Helpful error messages (rate limit errors include setup guidance)
- **SC-005**: ✅ Profile persistence (standard environment variable mechanism)
- **SC-006**: ✅ CI/CD integration (documented with examples)
- **SC-007**: ✅ Invalid token handling (401 errors surfaced clearly)
- **SC-008**: ✅ Environment variable flexibility (session/profile/system all work)
- **SC-009**: ✅ Verbose status visibility (authentication status in first 3 lines)
- **SC-010**: ✅ Developer verification (verbose output shows "Using authenticated request")
- **SC-011**: ✅ CI/CD examples (GitHub Actions, Azure Pipelines, Jenkins documented)
- **SC-012**: ✅ Quick setup (5-minute resolution via documentation link)

All success criteria addressable by this implementation approach.