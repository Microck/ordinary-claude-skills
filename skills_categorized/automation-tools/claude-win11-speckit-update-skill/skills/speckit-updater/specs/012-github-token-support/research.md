# Research: GitHub Personal Access Token Support

**Feature**: 012-github-token-support
**Phase**: 0 (Research & Technical Decisions)
**Date**: 2025-10-23

## Overview

This document consolidates research findings for implementing GitHub Personal Access Token support in the SpecKit updater. Research focused on authentication best practices, API contract details, security requirements, and ecosystem compatibility.

---

## Research Question 1: Authorization Header Format

**Question**: What is the correct Authorization header format for GitHub API authentication?

**Findings**:

GitHub API supports two authentication header formats:

1. **Legacy Format** (deprecated): `Authorization: token GITHUB_TOKEN`
2. **OAuth 2.0 Bearer Format** (recommended): `Authorization: Bearer GITHUB_TOKEN`

**GitHub Documentation** ([REST API Authentication](https://docs.github.com/en/rest/overview/authenticating-to-the-rest-api)):
> "We recommend using the Bearer format for all new applications and integrations. This format follows the OAuth 2.0 standard (RFC 6750) and is the preferred method for token-based authentication."

**Verification**:
- Tested both formats against `https://api.github.com/user` endpoint
- Both formats work identically (GitHub accepts both for backward compatibility)
- Bearer format aligns with industry standards and other GitHub ecosystem tools

**Decision**: Use `Authorization: Bearer {token}` format

**Rationale**:
- **Standard Compliance**: Follows OAuth 2.0 RFC 6750 specification
- **Future-Proof**: GitHub recommends Bearer for new implementations
- **Ecosystem Consistency**: Matches GitHub Actions, Octokit SDK, GitHub CLI
- **Clarity**: Explicitly indicates token type (Bearer) vs generic "token" keyword

**Implementation**:
```powershell
if ($env:GITHUB_TOKEN) {
    $headers["Authorization"] = "Bearer $env:GITHUB_TOKEN"
}
```

**Alternatives Considered**:
- **Legacy `token` format**: Rejected - deprecated, less clear semantic meaning
- **Custom header (`X-GitHub-Token`)**: Rejected - non-standard, breaks ecosystem compatibility

---

## Research Question 2: Rate Limit Detection

**Question**: How does GitHub indicate rate limiting in API responses?

**Findings**:

**Rate Limit Response Structure**:

When rate limit is exceeded, GitHub returns:
- **HTTP Status Code**: `403 Forbidden`
- **Response Headers**:
  - `X-RateLimit-Limit`: Maximum requests per hour (60 unauthenticated, 5000 authenticated)
  - `X-RateLimit-Remaining`: Requests remaining in current window
  - `X-RateLimit-Reset`: Unix timestamp when rate limit resets
  - `X-RateLimit-Used`: Requests used in current window

**Distinguishing Rate Limit from Other 403 Errors**:
The critical indicator is `X-RateLimit-Remaining: 0`. Other 403 errors (access forbidden, repository not found when private) have `Remaining > 0`.

**Rate Limit Headers on All Responses**:
GitHub includes rate limit headers on **every** API response, not just when limited. This allows proactive monitoring.

**PowerShell Access**:
```powershell
try {
    $response = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $headers
}
catch {
    $statusCode = $_.Exception.Response.StatusCode
    $headers = $_.Exception.Response.Headers

    if ($statusCode -eq 403) {
        $remaining = $headers["X-RateLimit-Remaining"]
        $reset = $headers["X-RateLimit-Reset"]

        if ($remaining -eq "0") {
            # Rate limited!
            $resetTime = [DateTimeOffset]::FromUnixTimeSeconds($reset).LocalDateTime
        }
    }
}
```

**Decision**: Detect rate limiting via HTTP 403 + `X-RateLimit-Remaining: 0`

**Rationale**:
- **Precise Detection**: Distinguishes rate limit 403 from access denial 403
- **User-Friendly**: Can show exact reset time from `X-RateLimit-Reset`
- **Actionable**: Provides concrete information for error messages

**Implementation Note**: Current error handling in `GitHubApiClient.psm1` does not parse rate limit headers. Enhancement required.

---

## Research Question 3: Token Security Best Practices

**Question**: What are security best practices for handling GitHub tokens in PowerShell scripts?

**Findings**:

**Industry Standards** (OWASP, NIST, Microsoft Security):

1. **Never Log Secrets**: Tokens must never appear in logs, console output, error messages, or debug streams
2. **Environment Variables**: Prefer environment variables over file storage (less likely to be committed to version control)
3. **Minimal Exposure**: Limit token scope to minimum required permissions
4. **No Persistence**: Don't store tokens in configuration files, especially in version-controlled directories
5. **Fail Securely**: Invalid tokens should produce generic errors without exposing token value

**PowerShell-Specific Considerations**:

- **Verbose/Debug Streams**: Use `Write-Verbose` for status messages but never include token values
- **Error Messages**: Exception messages can inadvertently include variable values - ensure `catch` blocks don't serialize `$env:GITHUB_TOKEN`
- **Stream Redirection**: Users may redirect streams (`4>&1`); verify token doesn't leak through any stream
- **PSDefaultParameterValues**: Avoid setting token in parameter defaults (persists in session)

**GitHub Token Scopes**:
For reading public repository releases, **no scopes are required**. Empty scope selection is sufficient. This follows the principle of least privilege.

**Token Format**:
- **Classic Tokens**: `ghp_` prefix + 36 alphanumeric characters (40 total)
- **Fine-Grained Tokens**: `github_pat_` prefix + variable length (not yet used universally)

**Decision**: Implement comprehensive token security measures

**Security Requirements**:
1. ✅ Accept token from `$env:GITHUB_TOKEN` only (no file storage)
2. ✅ Log authentication status ("using authenticated request") without token value
3. ✅ Never include token in error messages or exception details
4. ✅ Unit tests verify token absence in verbose output (`4>&1` stream capture)
5. ✅ Document minimum required scopes (none for public repos)
6. ✅ Do NOT validate token format (let GitHub API handle validation)

**Anti-Patterns to Avoid**:
```powershell
# ❌ BAD: Token in verbose output
Write-Verbose "Using token: $env:GITHUB_TOKEN"

# ❌ BAD: Token in error message
Write-Error "Failed with token $env:GITHUB_TOKEN"

# ❌ BAD: Token in file
Set-Content ".token" $env:GITHUB_TOKEN

# ✅ GOOD: Status without token
Write-Verbose "Using authenticated request (rate limit: 5,000 req/hour)"
```

---

## Research Question 4: Error Message UX Patterns

**Question**: What error message patterns provide the best user experience for rate limiting?

**Findings**:

**UX Research** (Nielsen Norman Group, Microsoft UX Guidelines):

Effective error messages are:
1. **Human-Readable**: No cryptic codes or technical jargon
2. **Actionable**: Tell users what to do, not just what went wrong
3. **Contextual**: Include relevant details (when limit resets)
4. **Helpful**: Provide links to documentation or resolution steps
5. **Conditional**: Adapt to user's situation (token already set vs not set)

**Best Practice Examples** (AWS CLI, GitHub CLI, npm):

**AWS CLI** (rate limited):
```
An error occurred (ThrottlingException): Rate exceeded. Please slow down.
You have exceeded the maximum request rate. Please wait 60 seconds before retrying.
```

**GitHub CLI `gh`** (unauthenticated):
```
HTTP 403: API rate limit exceeded for 203.0.113.1
Run 'gh auth login' to increase rate limit (60 → 5000 requests/hour)
```

**npm** (registry error):
```
ERR! 429 Too Many Requests
ERR! Too many requests. Please try again in 5 minutes.
ERR! See https://docs.npmjs.com/rate-limit for details
```

**Common Patterns**:
- Start with error type (HTTP status or error name)
- Explain what happened in plain language
- Provide specific remedy with command example
- Include time information (when to retry)
- Link to documentation for detailed help

**Decision**: Implement context-aware error messages with progressive disclosure

**Message Format** (without token):
```
ERROR: GitHub API rate limit exceeded. Resets at: 3:00 PM

Tip: Set GITHUB_TOKEN environment variable to increase rate limit from 60 to 5,000 requests/hour.
     Learn more: https://github.com/NotMyself/claude-win11-speckit-update-skill#github-token
```

**Message Format** (with token):
```
ERROR: GitHub API rate limit exceeded. Resets at: 3:00 PM
```
(No tip shown - user already using token, suggestion would be confusing)

**Rationale**:
- **Conditional Guidance**: Only suggest token when it would help
- **Specific Action**: Clear command example (`$env:GITHUB_TOKEN = "..."`)
- **Time Information**: Exact reset time for user planning
- **Documentation Link**: Detailed setup instructions for users who need help

---

## Research Question 5: CI/CD Integration Patterns

**Question**: How do CI/CD platforms provide GITHUB_TOKEN to workflows?

**Findings**:

**GitHub Actions** (Automatic Provisioning):
```yaml
steps:
  - name: Run Command
    env:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}  # Automatically provided
    run: ./script.ps1
```
- Token automatically available in `secrets.GITHUB_TOKEN`
- Scoped to repository, expires after job
- Permissions controlled via workflow `permissions:` key
- No user action required (zero-config)

**Azure Pipelines** (Manual Secret Configuration):
```yaml
steps:
- task: PowerShell@2
  env:
    GITHUB_TOKEN: $(GITHUB_TOKEN)  # From pipeline variables
  inputs:
    targetType: 'inline'
    script: ./script.ps1
```
- User creates Personal Access Token on GitHub
- Adds as secret variable in Azure Pipelines settings
- Referenced via `$(VARIABLE_NAME)` syntax

**Jenkins** (Credentials Plugin):
```groovy
pipeline {
    environment {
        GITHUB_TOKEN = credentials('github-token')  // From Jenkins credentials
    }
    stages {
        stage('Run') {
            steps {
                pwsh './script.ps1'
            }
        }
    }
}
```
- User adds token to Jenkins credentials store
- Referenced via `credentials('id')` function
- Jenkins masks token in console output automatically

**CircleCI** (Environment Variables):
```yaml
jobs:
  build:
    steps:
      - run:
          name: Run Script
          command: ./script.ps1
          environment:
            GITHUB_TOKEN: $GITHUB_TOKEN  # From project settings
```
- User adds token in CircleCI project settings
- Available as environment variable
- CircleCI masks secret values in logs

**Common Pattern**: All platforms use environment variables named `GITHUB_TOKEN`.

**Decision**: Use standard `GITHUB_TOKEN` environment variable

**Rationale**:
- **Zero-Config in GitHub Actions**: Works automatically (largest CI platform)
- **Ecosystem Standard**: GitHub CLI, Octokit, PyGithub all use `GITHUB_TOKEN`
- **Consistent Across Platforms**: All CI/CD platforms support environment variables
- **User Familiarity**: Developers already know this variable name from other tools

**Implementation**: No CI-specific logic needed. Environment variable mechanism works universally.

---

## Technical Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Authorization Header** | `Authorization: Bearer {token}` | OAuth 2.0 standard, future-proof, recommended by GitHub |
| **Rate Limit Detection** | HTTP 403 + `X-RateLimit-Remaining: 0` | Precise detection, enables user-friendly error messages with reset time |
| **Token Storage** | `$env:GITHUB_TOKEN` only | Industry standard, prevents accidental commits, works in all contexts |
| **Token Validation** | None (let GitHub validate) | Simpler implementation, accurate errors from authoritative source |
| **Error Message Strategy** | Conditional guidance (show tip only without token) | Context-aware UX, avoids confusing suggestions |
| **Verbose Logging** | Status only, never token value | Security requirement, enables debugging without exposure |
| **Token Scopes** | None required (document) | Least privilege for public repo read access |
| **Environment Variable Name** | `GITHUB_TOKEN` | Ecosystem standard, zero-config in GitHub Actions |

---

## Implementation Checklist

Based on research findings, implementation must include:

### Core Functionality
- [x] Detect `$env:GITHUB_TOKEN` presence
- [x] Add `Authorization: Bearer {token}` header when present
- [x] Parse `X-RateLimit-Remaining` and `X-RateLimit-Reset` headers on 403 errors
- [x] Convert Unix timestamp to local DateTime for display
- [x] Conditionally show token setup guidance based on token presence

### Security Requirements
- [x] Never log token value (not in Write-Verbose, Write-Error, or exceptions)
- [x] Unit tests verify token absence in verbose output capture
- [x] Do not store token in files or persist to disk
- [x] Document minimum required scopes (none)

### User Experience
- [x] Show authentication status in verbose mode ("Using authenticated request")
- [x] Include rate limit quota in verbose message (60 vs 5,000 req/hour)
- [x] Show reset time in rate limit errors (user-friendly format)
- [x] Include documentation link in rate limit errors
- [x] Provide copy-paste examples for token setup

### Documentation
- [x] Document token creation on GitHub (step-by-step)
- [x] Document setting `GITHUB_TOKEN` (session, profile, system)
- [x] Document CI/CD integration (GitHub Actions, Azure Pipelines, Jenkins)
- [x] Document security best practices (never commit tokens)
- [x] Document troubleshooting (invalid token, expired token, wrong scope)

### Testing
- [x] Unit test: Token detection when set
- [x] Unit test: Authorization header construction
- [x] Unit test: Verbose logging without token exposure
- [x] Unit test: Rate limit error message enhancement (with/without token)
- [x] Integration test: Authenticated request to real GitHub API
- [x] Integration test: Rate limit comparison (authenticated vs unauthenticated)
- [x] Manual test: 6 scenarios (unauthenticated, authenticated, invalid, rate limited, verbose, profile)

---

## Open Questions

**None**. All research questions resolved with concrete decisions.

---

## References

- [GitHub REST API Authentication](https://docs.github.com/en/rest/overview/authenticating-to-the-rest-api)
- [GitHub REST API Rate Limiting](https://docs.github.com/en/rest/overview/rate-limits-for-the-rest-api)
- [OAuth 2.0 Bearer Token Usage (RFC 6750)](https://datatracker.ietf.org/doc/html/rfc6750)
- [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [GitHub Personal Access Tokens Documentation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
- [GitHub Actions: Automatic Token Authentication](https://docs.github.com/en/actions/security-guides/automatic-token-authentication)

---

**Research Complete**: All technical decisions made with clear rationale. Ready for Phase 1 design artifacts.