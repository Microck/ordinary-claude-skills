# PRD: GitHub Personal Access Token Support for Rate Limit Avoidance

## Executive Summary

Enable the SpecKit updater to use GitHub Personal Access Tokens (PATs) for authenticated API requests, increasing the rate limit from 60 requests/hour to 5,000 requests/hour. This dramatically improves the user experience for developers who frequently update SpecKit templates or work in team environments.

**Problem:** Users frequently hit GitHub's unauthenticated API rate limit (60 req/hour), forcing them to wait up to an hour before continuing work.

**Solution:** Add optional support for the standard `GITHUB_TOKEN` environment variable to enable authenticated API requests with 5,000 req/hour rate limit.

**Impact:** Eliminates rate limiting as a pain point for 95%+ of users, especially those developing/testing the updater, working in teams, or using CI/CD environments.

## Problem Statement

The current implementation in `GitHubApiClient.psm1` uses unauthenticated GitHub API requests. GitHub enforces strict rate limits:

| Authentication | Rate Limit | Reset Window |
|---------------|-----------|--------------|
| Unauthenticated | 60 requests/hour | Per IP address |
| Authenticated (PAT) | 5,000 requests/hour | Per user |

**When Users Hit Rate Limits:**

- **Multiple updates:** Running `/speckit-update` 3-4 times in an hour (development/testing)
- **Team environments:** Multiple developers sharing the same IP address (office network)
- **CI/CD pipelines:** Shared runner IP addresses triggering rate limits
- **Network-level NAT:** All users behind corporate NAT appear as single IP

**Current User Experience:**
```powershell
PS> /speckit-update
Checking for updates...
ERROR: GitHub API rate limit exceeded. Resets at: 3:00 PM. Please try again later.
Exit Code: 3
```

**User Pain Points:**
- **Blocked workflow:** Cannot proceed with update for up to 60 minutes
- **Unpredictable:** Rate limit shared across unknown users on same IP
- **No workaround:** No way to authenticate even if user has GitHub account
- **Poor development UX:** Makes testing and iterating on the updater painful

**Real-World Scenarios:**
1. Developer testing updater changes makes 5 test runs → rate limited for 55 minutes
2. Team of 3 developers in office each run update → first developer succeeds, next two fail
3. CI/CD pipeline runs hourly checks → fails after first run, subsequent jobs blocked
4. Developer behind corporate NAT → rate limited by colleagues' usage

## Goals

### Primary Goals
1. **Support authenticated GitHub API requests** via `GITHUB_TOKEN` environment variable
2. **Maintain backward compatibility** - token is optional, skill works without it
3. **Increase rate limit** from 60 to 5,000 requests/hour for authenticated users
4. **Follow security best practices** - never log token values, use standard protocols

### Secondary Goals
- Provide helpful error messages when rate limited (suggest setting token)
- Document how to create and use GitHub tokens clearly
- Support the standard environment variable used across GitHub ecosystem
- Verbose logging shows authentication status without exposing secrets

### Non-Goals (v1)
- **Interactive token prompts:** Don't ask users for tokens during execution
- **Token storage in files:** Don't persist tokens in manifest or config files (security risk)
- **GitHub CLI integration:** Don't depend on `gh` CLI authentication
- **OAuth flows:** Don't implement complex OAuth (overkill for public read access)
- **Token validation:** Don't validate token before use (let GitHub API handle it)
- **Multi-token support:** Don't support multiple tokens or token rotation

## User Stories

### Story 1: Developer Testing Updater Changes
**As a** developer working on the SpecKit updater skill
**I want to** make multiple test runs without hitting rate limits
**So that** I can iterate quickly and validate changes efficiently

**Acceptance Criteria:**
- Can set `GITHUB_TOKEN` once in PowerShell session
- All subsequent `/speckit-update` invocations use authenticated requests
- Rate limit increases from 60 to 5,000 requests/hour
- No changes to command syntax or workflow

**Success Scenario:**
```powershell
# Set token once
$env:GITHUB_TOKEN = "ghp_xxxxxxxxxxxxxxxxxxxx"

# Make 20 test runs in an hour - all succeed
1..20 | ForEach-Object {
    Write-Host "Test run $_"
    /speckit-update -CheckOnly
}
```

### Story 2: Team in Shared Office Network
**As a** developer on a team sharing an office network
**I want to** use my personal GitHub token for API requests
**So that** my rate limit is independent of my colleagues' usage

**Acceptance Criteria:**
- Each team member can use their own `GITHUB_TOKEN`
- Rate limits are per-user, not per-IP
- Works without coordinating with team members

**Success Scenario:**
- Developer A runs 10 updates → succeeds (uses their token)
- Developer B runs 10 updates → succeeds (uses their token)
- Both on same office IP, no rate limit conflict

### Story 3: CI/CD Pipeline Integration
**As a** DevOps engineer maintaining CI/CD pipelines
**I want to** run SpecKit updates in automated workflows
**So that** I can validate template compatibility on every commit

**Acceptance Criteria:**
- Can set `GITHUB_TOKEN` from CI secrets/environment
- Supports GitHub Actions, Azure Pipelines, Jenkins, etc.
- Documentation includes CI/CD example

**Success Scenario:**
```yaml
# .github/workflows/speckit-update.yml
steps:
  - name: Check SpecKit Updates
    env:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    run: |
      pwsh -Command "& '.\.claude\skills\speckit-updater\scripts\update-orchestrator.ps1' -CheckOnly"
```

### Story 4: First-Time User Without Token
**As a** developer trying the updater for the first time
**I want to** run updates without configuring tokens
**So that** I can evaluate the skill quickly without setup friction

**Acceptance Criteria:**
- Works perfectly without `GITHUB_TOKEN` set
- No errors or warnings about missing token
- Rate limit error message suggests setting token if hit
- Clear documentation about when tokens are needed

**Success Scenario:**
```powershell
# Works immediately without token
PS> /speckit-update -CheckOnly
✓ No updates available. Current version: v0.0.72

# If rate limited, helpful message
PS> /speckit-update # (after 60 requests)
ERROR: GitHub API rate limit exceeded. Resets at: 3:00 PM.

Tip: Set GITHUB_TOKEN to increase rate limit from 60 to 5,000 requests/hour.
     See: https://github.com/NotMyself/claude-win11-speckit-update-skill#github-token
```

## Technical Design

### Current Implementation

**File:** [scripts/modules/GitHubApiClient.psm1](../../scripts/modules/GitHubApiClient.psm1)
**Function:** `Invoke-GitHubApiRequest` (lines 17-84)

Current headers sent with every request:
```powershell
$headers = @{
    "Accept" = "application/vnd.github.v3+json"
    "User-Agent" = "SpecKit-Updater-PowerShell"
}
```

No authentication header sent → unauthenticated request → 60 req/hour limit.

### Proposed Implementation

Add token detection and authorization header:

```powershell
function Invoke-GitHubApiRequest {
    <#
    .SYNOPSIS
        Makes authenticated or unauthenticated requests to GitHub API.

    .DESCRIPTION
        Sends HTTP requests to GitHub API endpoints. Automatically uses
        GitHub Personal Access Token from GITHUB_TOKEN environment variable
        if available, increasing rate limit from 60 to 5,000 requests/hour.

    .PARAMETER Uri
        The GitHub API endpoint URI.

    .PARAMETER Method
        HTTP method (GET, POST, etc.). Default: GET

    .EXAMPLE
        # Unauthenticated request (60 req/hour)
        $release = Invoke-GitHubApiRequest -Uri "https://api.github.com/repos/owner/repo/releases/latest"

    .EXAMPLE
        # Authenticated request (5,000 req/hour)
        $env:GITHUB_TOKEN = "ghp_xxxxxxxxxxxxxxxxxxxx"
        $release = Invoke-GitHubApiRequest -Uri "https://api.github.com/repos/owner/repo/releases/latest"

    .NOTES
        Token is never logged or displayed. Use -Verbose to see authentication status.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Uri,

        [Parameter()]
        [string]$Method = "GET"
    )

    Write-Verbose "Making $Method request to: $Uri"

    # Build headers
    $headers = @{
        "Accept" = "application/vnd.github.v3+json"
        "User-Agent" = "SpecKit-Updater-PowerShell"
    }

    # Add authentication if token is available
    if ($env:GITHUB_TOKEN) {
        $headers["Authorization"] = "Bearer $env:GITHUB_TOKEN"
        Write-Verbose "Using authenticated request (rate limit: 5,000 req/hour)"
    }
    else {
        Write-Verbose "Using unauthenticated request (rate limit: 60 req/hour)"
    }

    try {
        $response = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $headers -ErrorAction Stop
        return $response
    }
    catch {
        # Enhanced error message for rate limiting
        if ($_.Exception.Response.StatusCode -eq 403) {
            $rateLimitRemaining = $_.Exception.Response.Headers["X-RateLimit-Remaining"]
            $rateLimitReset = $_.Exception.Response.Headers["X-RateLimit-Reset"]

            if ($rateLimitRemaining -eq "0") {
                $resetTime = [DateTimeOffset]::FromUnixTimeSeconds($rateLimitReset).LocalDateTime

                $errorMsg = "GitHub API rate limit exceeded. Resets at: $resetTime"

                # Suggest token if not using one
                if (-not $env:GITHUB_TOKEN) {
                    $errorMsg += "`n`nTip: Set GITHUB_TOKEN environment variable to increase rate limit from 60 to 5,000 requests/hour."
                    $errorMsg += "`n     Learn more: https://github.com/NotMyself/claude-win11-speckit-update-skill#github-token"
                }

                Write-Error $errorMsg
                throw $errorMsg
            }
        }

        Write-Error "GitHub API request failed: $($_.Exception.Message)"
        throw
    }
}
```

### Key Changes

1. **Token Detection** (Line 46-48):
   - Check for `$env:GITHUB_TOKEN`
   - If present, add `Authorization: Bearer {token}` header

2. **Security Logging** (Lines 49-53):
   - Verbose message shows authentication status
   - Never logs token value itself
   - Clear distinction between authenticated/unauthenticated

3. **Enhanced Error Handling** (Lines 62-77):
   - Detect rate limit errors (HTTP 403 + X-RateLimit-Remaining: 0)
   - Show reset time
   - Suggest setting token if not using one
   - Include link to documentation

4. **Documentation** (Lines 7-31):
   - Updated comment-based help
   - Examples for both authenticated and unauthenticated usage
   - Security notes about token handling

### Token Format

GitHub Personal Access Tokens have format: `ghp_` + 36 alphanumeric characters

**Example:** `ghp_1234567890abcdefghijklmnopqrstuv`

**Required Scopes:**
- **None** (public repository read access)
- Or `public_repo` for explicit permission

### Standard Environment Variable

`GITHUB_TOKEN` is the **de facto standard** used by:

| Tool/Platform | Usage |
|--------------|--------|
| **GitHub Actions** | Automatically provided as `${{ secrets.GITHUB_TOKEN }}` |
| **GitHub CLI (`gh`)** | Uses `GITHUB_TOKEN` for authentication |
| **Various SDKs** | Octokit, PyGithub, etc. all check `GITHUB_TOKEN` |
| **CI/CD Tools** | Jenkins, CircleCI, Travis CI expect `GITHUB_TOKEN` |

Using this standard variable provides zero-friction integration with existing workflows.

### Security Considerations

1. **Never Log Tokens:**
   - No Write-Verbose or Write-Host with token value
   - Verbose shows only "Using authenticated request"
   - Exception messages never include Authorization header

2. **Environment Variable Only:**
   - Don't store in manifest.json (risk of committing to Git)
   - Don't store in config files (risk of exposure)
   - Don't prompt interactively (breaks automation)

3. **Fail Open, Not Closed:**
   - If token is invalid, GitHub API returns 401
   - Let GitHub handle token validation
   - Don't pre-validate tokens locally

4. **Token Scope Principle:**
   - Only needs read access to public repositories
   - No write permissions required
   - Recommend creating token with minimal scopes

### Implementation Location

**Primary Change:**
- **File:** [scripts/modules/GitHubApiClient.psm1](../../scripts/modules/GitHubApiClient.psm1)
- **Function:** `Invoke-GitHubApiRequest` (lines 17-84)
- **Changes:** Add token detection, authorization header, enhanced error message

**Documentation Changes:**
- **README.md:** Add "Using GitHub Tokens" section under Prerequisites
- **CLAUDE.md:** Update "Troubleshooting - GitHub API Issues" section
- **SKILL.md:** Mention token support in command description (optional)

**Test Changes:**
- **Unit Tests:** Add tests for token detection and header setting
- **Integration Tests:** Validate authenticated requests work (using test token)

### Backward Compatibility

**Guaranteed Compatibility:**
- ✅ Works without `GITHUB_TOKEN` (existing behavior)
- ✅ No command-line flag changes
- ✅ No breaking changes to API
- ✅ Exit codes remain the same

**Behavior Changes:**
- Enhanced rate limit error message (adds helpful tip)
- Verbose logging includes authentication status

**Migration Path:**
- Existing users: No action required, continues working
- Users hitting rate limits: Set `GITHUB_TOKEN` in profile or session
- CI/CD users: Add `GITHUB_TOKEN` to secrets/environment

## Command Behavior Specification

### Scenario 1: Without Token (Current Behavior)

```powershell
PS> /speckit-update -CheckOnly
Checking for updates...
✓ No updates available. Current version: v0.0.72
```

**Request Headers:**
```
Accept: application/vnd.github.v3+json
User-Agent: SpecKit-Updater-PowerShell
```

**Rate Limit:** 60 requests/hour per IP

### Scenario 2: With Token (New Behavior)

```powershell
PS> $env:GITHUB_TOKEN = "ghp_xxxxxxxxxxxxxxxxxxxx"
PS> /speckit-update -CheckOnly -Verbose
VERBOSE: Using authenticated request (rate limit: 5,000 req/hour)
Checking for updates...
✓ No updates available. Current version: v0.0.72
```

**Request Headers:**
```
Accept: application/vnd.github.v3+json
User-Agent: SpecKit-Updater-PowerShell
Authorization: Bearer ghp_xxxxxxxxxxxxxxxxxxxx
```

**Rate Limit:** 5,000 requests/hour per user

### Scenario 3: Rate Limit Without Token

```powershell
PS> /speckit-update  # After 60 unauthenticated requests
Checking for updates...
ERROR: GitHub API rate limit exceeded. Resets at: 3:00 PM

Tip: Set GITHUB_TOKEN environment variable to increase rate limit from 60 to 5,000 requests/hour.
     Learn more: https://github.com/NotMyself/claude-win11-speckit-update-skill#github-token

Exit Code: 3
```

### Scenario 4: Rate Limit With Token (Rare)

```powershell
PS> $env:GITHUB_TOKEN = "ghp_xxxxxxxxxxxxxxxxxxxx"
PS> /speckit-update  # After 5,000 authenticated requests (unlikely!)
Checking for updates...
ERROR: GitHub API rate limit exceeded. Resets at: 4:00 PM

Exit Code: 3
```

**Note:** 5,000 req/hour is ~83 requests/minute. Virtually impossible to hit during normal usage.

### Scenario 5: Invalid Token

```powershell
PS> $env:GITHUB_TOKEN = "invalid_token"
PS> /speckit-update
Checking for updates...
ERROR: GitHub API request failed: 401 Unauthorized

Exit Code: 3
```

**Behavior:** Invalid tokens fail gracefully with GitHub's error. User can fix or remove token.

## Implementation Plan

### Sprint 1: Core Implementation (2-3 days)

**Tasks:**
1. ✅ Create PRD (this document)
2. Modify `Invoke-GitHubApiRequest` to detect `GITHUB_TOKEN`
3. Add `Authorization: Bearer {token}` header when token present
4. Update verbose logging to show authentication status
5. Enhance rate limit error message with token suggestion
6. Update function comment-based help
7. Write unit tests for token detection
8. Write unit tests for header construction
9. Write unit tests for error message enhancement

**Definition of Done:**
- ✅ `Invoke-GitHubApiRequest` checks for `$env:GITHUB_TOKEN`
- ✅ Authorization header added when token present
- ✅ Token value never appears in logs
- ✅ Verbose logging shows authentication status
- ✅ Rate limit error suggests token when not using one
- ✅ Unit tests pass for all scenarios
- ✅ Code review completed

### Sprint 2: Documentation & Testing (1-2 days)

**Tasks:**
1. Update README.md with "Using GitHub Tokens" section
2. Update CLAUDE.md troubleshooting section
3. Add token setup instructions to docs/
4. Write integration test with test token
5. Manual testing: unauthenticated requests
6. Manual testing: authenticated requests
7. Manual testing: invalid token handling
8. Manual testing: rate limit errors
9. Update CHANGELOG.md under `[Unreleased]`

**Definition of Done:**
- ✅ README has clear token setup instructions
- ✅ CLAUDE.md troubleshooting updated
- ✅ Integration tests validate authenticated requests
- ✅ All manual test scenarios pass
- ✅ Documentation reviewed
- ✅ CHANGELOG updated

### Sprint 3: Release & Monitoring (1 day)

**Tasks:**
1. Create release notes highlighting token support
2. Merge PR to main branch
3. Tag release (v0.5.0)
4. Monitor GitHub issues for token-related questions
5. Update issue #21 with resolution

**Definition of Done:**
- ✅ Changes merged to main
- ✅ Release tagged and published
- ✅ Issue #21 closed
- ✅ No new token-related bug reports

## Testing Strategy

### Unit Tests

**File:** `tests/unit/GitHubApiClient.Tests.ps1`

```powershell
Describe "Invoke-GitHubApiRequest - Token Support" {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\..\scripts\modules\GitHubApiClient.psm1" -Force
    }

    Context "When GITHUB_TOKEN is set" {
        BeforeEach {
            $env:GITHUB_TOKEN = "ghp_test1234567890abcdefghijklmnopqr"
        }

        AfterEach {
            $env:GITHUB_TOKEN = $null
        }

        It "Should add Authorization header" {
            Mock Invoke-RestMethod {
                # Capture headers parameter
                $script:capturedHeaders = $Headers
                return @{ tag_name = "v1.0.0" }
            }

            Invoke-GitHubApiRequest -Uri "https://api.github.com/repos/test/repo/releases/latest"

            $script:capturedHeaders["Authorization"] | Should -Be "Bearer ghp_test1234567890abcdefghijklmnopqr"
        }

        It "Should log authentication status in verbose mode" {
            Mock Invoke-RestMethod { return @{ tag_name = "v1.0.0" } }

            $verboseOutput = Invoke-GitHubApiRequest -Uri "https://api.github.com/test" -Verbose 4>&1

            $verboseOutput | Should -Match "Using authenticated request"
            $verboseOutput | Should -Match "5,000 req/hour"
        }

        It "Should never log token value" {
            Mock Invoke-RestMethod { return @{ tag_name = "v1.0.0" } }

            $verboseOutput = Invoke-GitHubApiRequest -Uri "https://api.github.com/test" -Verbose 4>&1

            $verboseOutput | Should -Not -Match "ghp_"
            $verboseOutput | Should -Not -Match $env:GITHUB_TOKEN
        }
    }

    Context "When GITHUB_TOKEN is not set" {
        BeforeEach {
            $env:GITHUB_TOKEN = $null
        }

        It "Should not add Authorization header" {
            Mock Invoke-RestMethod {
                $script:capturedHeaders = $Headers
                return @{ tag_name = "v1.0.0" }
            }

            Invoke-GitHubApiRequest -Uri "https://api.github.com/test"

            $script:capturedHeaders.Keys | Should -Not -Contain "Authorization"
        }

        It "Should log unauthenticated status in verbose mode" {
            Mock Invoke-RestMethod { return @{ tag_name = "v1.0.0" } }

            $verboseOutput = Invoke-GitHubApiRequest -Uri "https://api.github.com/test" -Verbose 4>&1

            $verboseOutput | Should -Match "Using unauthenticated request"
            $verboseOutput | Should -Match "60 req/hour"
        }
    }

    Context "When rate limit exceeded without token" {
        BeforeEach {
            $env:GITHUB_TOKEN = $null
        }

        It "Should suggest setting GITHUB_TOKEN in error message" {
            $mockResponse = New-MockObject -Type System.Net.Http.HttpResponseMessage
            $mockResponse | Add-Member -MemberType NoteProperty -Name StatusCode -Value 403
            $mockResponse | Add-Member -MemberType NoteProperty -Name Headers -Value @{
                "X-RateLimit-Remaining" = "0"
                "X-RateLimit-Reset" = "1704067200"  # Unix timestamp
            }

            Mock Invoke-RestMethod {
                throw [System.Net.WebException]::new("Rate limit exceeded", $null, $mockResponse)
            }

            { Invoke-GitHubApiRequest -Uri "https://api.github.com/test" } | Should -Throw "*Set GITHUB_TOKEN*"
            { Invoke-GitHubApiRequest -Uri "https://api.github.com/test" } | Should -Throw "*5,000 requests/hour*"
        }
    }

    Context "When rate limit exceeded with token" {
        BeforeEach {
            $env:GITHUB_TOKEN = "ghp_test1234567890abcdefghijklmnopqr"
        }

        AfterEach {
            $env:GITHUB_TOKEN = $null
        }

        It "Should not suggest setting token (already using one)" {
            $mockResponse = New-MockObject -Type System.Net.Http.HttpResponseMessage
            $mockResponse | Add-Member -MemberType NoteProperty -Name StatusCode -Value 403
            $mockResponse | Add-Member -MemberType NoteProperty -Name Headers -Value @{
                "X-RateLimit-Remaining" = "0"
                "X-RateLimit-Reset" = "1704067200"
            }

            Mock Invoke-RestMethod {
                throw [System.Net.WebException]::new("Rate limit exceeded", $null, $mockResponse)
            }

            { Invoke-GitHubApiRequest -Uri "https://api.github.com/test" } | Should -Throw "*rate limit exceeded*"
            { Invoke-GitHubApiRequest -Uri "https://api.github.com/test" } | Should -Not -Throw "*Set GITHUB_TOKEN*"
        }
    }
}
```

### Integration Tests

**File:** `tests/integration/GitHubToken.Tests.ps1`

```powershell
Describe "GitHub Token Integration Tests" {
    BeforeAll {
        # Only run if test token is available
        if (-not $env:GITHUB_TEST_TOKEN) {
            Set-ItResult -Skipped -Because "GITHUB_TEST_TOKEN not set"
            return
        }

        Import-Module "$PSScriptRoot\..\..\scripts\modules\GitHubApiClient.psm1" -Force
    }

    It "Should successfully make authenticated request to GitHub API" {
        $env:GITHUB_TOKEN = $env:GITHUB_TEST_TOKEN

        $result = Get-LatestSpecKitRelease

        $result | Should -Not -BeNullOrEmpty
        $result.tag_name | Should -Match "^v\d+\.\d+\.\d+$"

        $env:GITHUB_TOKEN = $null
    }

    It "Should have higher rate limit with authentication" {
        # Make authenticated request
        $env:GITHUB_TOKEN = $env:GITHUB_TEST_TOKEN

        $authenticatedRequest = Invoke-GitHubApiRequest -Uri "https://api.github.com/rate_limit"

        # Check rate limit values
        $authenticatedRequest.rate.limit | Should -BeGreaterThan 1000

        $env:GITHUB_TOKEN = $null

        # Make unauthenticated request
        $unauthenticatedRequest = Invoke-GitHubApiRequest -Uri "https://api.github.com/rate_limit"

        # Authenticated should have higher limit
        $authenticatedRequest.rate.limit | Should -BeGreaterThan $unauthenticatedRequest.rate.limit
    }
}
```

### Manual Testing

```powershell
# Test 1: Unauthenticated request (baseline)
$env:GITHUB_TOKEN = $null
/speckit-update -CheckOnly -Verbose
# Expected: "Using unauthenticated request (rate limit: 60 req/hour)"

# Test 2: Authenticated request with valid token
$env:GITHUB_TOKEN = "ghp_YOUR_TOKEN_HERE"
/speckit-update -CheckOnly -Verbose
# Expected: "Using authenticated request (rate limit: 5,000 req/hour)"

# Test 3: Verify token not logged
$env:GITHUB_TOKEN = "ghp_YOUR_TOKEN_HERE"
$output = /speckit-update -CheckOnly -Verbose 2>&1 | Out-String
$output -match "ghp_"
# Expected: False (token should never appear)

# Test 4: Invalid token handling
$env:GITHUB_TOKEN = "invalid_token"
/speckit-update -CheckOnly
# Expected: GitHub API error (401 Unauthorized)

# Test 5: Rate limit error without token (simulate by making 61 requests)
$env:GITHUB_TOKEN = $null
1..61 | ForEach-Object {
    /speckit-update -CheckOnly
}
# Expected: After ~60 requests, error message suggests setting GITHUB_TOKEN

# Test 6: PowerShell profile integration
# Add to $PROFILE:
$env:GITHUB_TOKEN = "ghp_YOUR_TOKEN_HERE"
# Restart PowerShell, run command
/speckit-update -CheckOnly
# Expected: Works with authenticated request automatically

# Cleanup
$env:GITHUB_TOKEN = $null
```

### Security Testing

```powershell
# Test 1: Token never in exception messages
$env:GITHUB_TOKEN = "ghp_test1234567890"
try {
    # Force an error
    Invoke-GitHubApiRequest -Uri "https://api.github.com/invalid"
}
catch {
    $_.Exception.Message -match "ghp_"
    # Expected: False
}

# Test 2: Token never in verbose output
$env:GITHUB_TOKEN = "ghp_test1234567890"
$verbose = /speckit-update -CheckOnly -Verbose 4>&1 | Out-String
$verbose -match "ghp_test1234567890"
# Expected: False

# Test 3: Token never written to files
$env:GITHUB_TOKEN = "ghp_test1234567890"
/speckit-update -CheckOnly
Get-ChildItem .specify -Recurse -File | Select-String "ghp_test1234567890"
# Expected: No matches
```

## Success Metrics

### Primary Metrics
- **Rate limit errors reduced:** 95% reduction in "rate limit exceeded" errors
- **Development velocity:** Updater maintainers can make 20+ test runs/hour
- **Team adoption:** 80% of teams with 3+ developers use tokens
- **CI/CD success:** 100% of automated pipelines use tokens

### Secondary Metrics
- **Documentation clarity:** 90% of users can set up token without support
- **Security incidents:** Zero exposed tokens in logs or manifests
- **Backward compatibility:** Zero breaking changes reported
- **Token adoption:** 50% of active users adopt tokens within 3 months

### Measurement
- GitHub issue activity (rate limit complaints)
- Verbose logging data (if telemetry added in future)
- CI/CD pipeline success rates (before/after token support)
- User surveys in GitHub discussions

## Dependencies

### Technical Dependencies
- PowerShell 7+ (already required)
- GitHub Personal Access Token (user-provided, optional)
- No additional PowerShell modules needed

### External Dependencies
- GitHub API remains stable (Authorization: Bearer format)
- GitHub token format remains consistent (`ghp_` prefix)
- GitHub rate limits remain at 60/5,000 (documented behavior)

### Documentation Dependencies
- README.md structure supports new "GitHub Tokens" section
- CLAUDE.md troubleshooting section can be extended
- GitHub token creation flow remains at https://github.com/settings/tokens

## Risks and Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|---------|-----------|------------|
| Token accidentally logged | **Critical** | Low | Never log `$env:GITHUB_TOKEN`, comprehensive test coverage |
| Token committed to Git | **Critical** | Low | Only use env var, never store in files, document best practices |
| Invalid token breaks updates | Medium | Medium | Fail gracefully with clear error, show GitHub's error message |
| Users confused by token setup | Medium | Medium | Clear documentation with step-by-step instructions, screenshots |
| Rate limit still hit (5,000) | Low | Very Low | 5,000/hour is ~83/min, virtually impossible during normal usage |
| Token format changes | Low | Very Low | Monitor GitHub API changes, adjust header format if needed |
| Backward compatibility issues | Medium | Very Low | Maintain optional behavior, comprehensive regression testing |
| Security audit flags token usage | Medium | Low | Follow GitHub's standard practices, document security model |

## Design Decisions

### Decision 1: Environment Variable vs. Configuration File
**Options:**
- A) Use `GITHUB_TOKEN` environment variable (standard)
- B) Store in `.specify/config.json` file
- C) Store in user's `.claude/` directory
- D) Prompt interactively for token

**Decision:** A (Environment Variable)
**Rationale:**
- **Standard:** Used by GitHub Actions, CLI, and ecosystem tools
- **Security:** Environment variables less likely to be committed to Git
- **Flexibility:** Users control scope (session, profile, system)
- **Automation:** Works seamlessly in CI/CD without file dependencies
- **Backward Compatible:** Optional, doesn't break existing workflows

### Decision 2: Authorization Header Format
**Options:**
- A) `Authorization: Bearer {token}` (standard OAuth format)
- B) `Authorization: token {token}` (older GitHub format)
- C) Custom header like `X-GitHub-Token: {token}`

**Decision:** A (Bearer Token)
**Rationale:**
- **Standard:** RFC 6750 OAuth 2.0 Bearer Token format
- **Future-Proof:** GitHub recommends Bearer format for new implementations
- **Consistent:** Matches other modern APIs
- **Compatible:** GitHub API accepts both formats, Bearer is preferred

### Decision 3: Token Validation
**Options:**
- A) Pre-validate token before making requests (call `/user` endpoint)
- B) Let GitHub API validate during actual requests
- C) Regex validate token format only

**Decision:** B (Let GitHub Validate)
**Rationale:**
- **Simplicity:** No extra API calls needed
- **Accuracy:** GitHub knows if token is valid, we don't need to guess
- **Performance:** Avoid extra round-trip for validation
- **Fail Fast:** User gets immediate feedback on first request

### Decision 4: Error Message Enhancement
**Options:**
- A) Only add suggestion when not using token
- B) Always show suggestion (even if using token)
- C) Never mention tokens in error messages

**Decision:** A (Suggest When Not Using)
**Rationale:**
- **Relevant:** Only suggest if solution applies to current situation
- **Clean:** Don't clutter messages with irrelevant suggestions
- **Smart:** Shows we detect authentication state
- **Actionable:** User knows exactly what to do differently

### Decision 5: Verbose Logging Detail
**Options:**
- A) Show "Using authenticated request" (without token value)
- B) Show partial token like "Using token: ghp_****"
- C) Show full token in verbose mode
- D) Don't mention authentication status at all

**Decision:** A (Show Status, Not Token)
**Rationale:**
- **Security:** Never expose tokens, even partially
- **Useful:** Developers debugging know if token is detected
- **Simple:** Binary status (authenticated/unauthenticated) is clear
- **Safe:** No risk of accidental token exposure in logs

### Decision 6: Token Scope Requirements
**Options:**
- A) Require specific scopes (e.g., `public_repo`)
- B) Document no scopes required (public read access)
- C) Don't document scope requirements

**Decision:** B (Document No Scopes Required)
**Rationale:**
- **Minimal Permissions:** Reading public repos needs no scopes
- **Security:** Least privilege principle
- **Flexibility:** Users can add scopes if they want, not required
- **Clarity:** Explicit documentation prevents confusion

## Appendix: Token Setup Instructions

### Creating a GitHub Personal Access Token

**Step 1: Navigate to Token Settings**
1. Go to https://github.com/settings/tokens
2. Click "Generate new token" → "Generate new token (classic)"

**Step 2: Configure Token**
- **Note:** "SpecKit Updater" (helps you remember purpose)
- **Expiration:** 90 days (or your preference)
- **Scopes:** None required (or select `public_repo` for clarity)

**Step 3: Generate and Copy**
- Click "Generate token"
- Copy token immediately (shown only once): `ghp_xxxxxxxxxxxxxxxxxxxx`

**Step 4: Set Environment Variable**

**PowerShell (Session):**
```powershell
$env:GITHUB_TOKEN = "ghp_xxxxxxxxxxxxxxxxxxxx"
```

**PowerShell (Profile - Persistent):**
```powershell
# Edit profile
notepad $PROFILE

# Add line:
$env:GITHUB_TOKEN = "ghp_xxxxxxxxxxxxxxxxxxxx"

# Reload profile
. $PROFILE
```

**Windows System Environment Variable:**
1. Search "Environment Variables" in Windows
2. Click "Environment Variables" button
3. Under "User variables", click "New"
4. Variable name: `GITHUB_TOKEN`
5. Variable value: `ghp_xxxxxxxxxxxxxxxxxxxx`
6. Click OK, restart PowerShell

**Step 5: Verify**
```powershell
/speckit-update -CheckOnly -Verbose
# Should see: "Using authenticated request (rate limit: 5,000 req/hour)"
```

### CI/CD Integration Examples

**GitHub Actions:**
```yaml
name: Check SpecKit Updates

on: [push, pull_request]

jobs:
  check-updates:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3

      - name: Check SpecKit Updates
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}  # Automatically provided
        run: |
          pwsh -Command "& '.\.claude\skills\speckit-updater\scripts\update-orchestrator.ps1' -CheckOnly"
```

**Azure Pipelines:**
```yaml
trigger:
  - main

pool:
  vmImage: 'windows-latest'

steps:
- task: PowerShell@2
  displayName: 'Check SpecKit Updates'
  env:
    GITHUB_TOKEN: $(GITHUB_TOKEN)  # From pipeline variables
  inputs:
    targetType: 'inline'
    script: |
      & '.\.claude\skills\speckit-updater\scripts\update-orchestrator.ps1' -CheckOnly
```

**Jenkins:**
```groovy
pipeline {
    agent any

    environment {
        GITHUB_TOKEN = credentials('github-token')  // From Jenkins credentials
    }

    stages {
        stage('Check Updates') {
            steps {
                pwsh '''
                    & '.\.claude\skills\speckit-updater\scripts\update-orchestrator.ps1' -CheckOnly
                '''
            }
        }
    }
}
```

### Security Best Practices

**DO:**
- ✅ Store token in environment variable
- ✅ Use minimal scopes (none for public read)
- ✅ Set expiration date on tokens
- ✅ Rotate tokens periodically
- ✅ Use different tokens for different purposes
- ✅ Revoke tokens immediately if compromised

**DON'T:**
- ❌ Commit tokens to Git repositories
- ❌ Share tokens between team members
- ❌ Store tokens in plain text files
- ❌ Use tokens with unnecessary scopes
- ❌ Keep tokens indefinitely without expiration
- ❌ Use tokens in screenshot/demos (revoke after)

### Troubleshooting Token Issues

**Problem:** "401 Unauthorized" error with token set
**Solution:** Token may be expired or revoked. Create new token.

**Problem:** Still getting rate limited with token
**Solution:** Verify token is set correctly: `$env:GITHUB_TOKEN` should show token.

**Problem:** Token value visible in logs
**Solution:** Report security issue immediately. Should never happen.

**Problem:** Token not working in new PowerShell session
**Solution:** Set token in profile (`$PROFILE`) for persistence across sessions.

**Problem:** Different rate limit than expected
**Solution:** Check which endpoints you're hitting. Some have different limits.

## Related Files

- [scripts/modules/GitHubApiClient.psm1](../../scripts/modules/GitHubApiClient.psm1) - Main implementation
- [tests/unit/GitHubApiClient.Tests.ps1](../../tests/unit/GitHubApiClient.Tests.ps1) - Unit tests
- [CLAUDE.md](../../CLAUDE.md) - Troubleshooting documentation
- [README.md](../../README.md) - User-facing documentation

---

**Document Version:** 1.0.0 (Ready for Implementation)
**Last Updated:** 2025-10-23
**Status:** Ready for development
**Related Issue:** #21
**Owner:** TBD
**Stakeholders:** All SpecKit updater users, especially teams and CI/CD users

**Change Log:**
- **v1.0.0 (2025-10-23):** Initial PRD based on issue #21 analysis