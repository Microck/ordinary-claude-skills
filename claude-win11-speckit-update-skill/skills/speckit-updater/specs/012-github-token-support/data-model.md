# Data Model: GitHub Personal Access Token Support

**Feature**: 012-github-token-support
**Phase**: 1 (Design Artifacts)
**Date**: 2025-10-23

## Overview

This feature introduces minimal data structures for token-based authentication. All data is ephemeral (runtime only) with no persistence requirements. The model focuses on environment variable input, authentication state, and API response headers.

---

## Data Structures

### 1. GitHub Personal Access Token

**Source**: Environment variable `GITHUB_TOKEN`

**Format**:
- **Type**: String (environment variable value)
- **Pattern**: `ghp_` + 36 alphanumeric characters (total 40 characters)
- **Example**: `ghp_1A2b3C4d5E6f7G8h9I0jK1lM2nO3pQ4rS5t`
- **Alternative Format**: Fine-grained tokens use `github_pat_` prefix (variable length)

**Lifecycle**:
1. **Read**: Retrieved from `$env:GITHUB_TOKEN` at function invocation time
2. **Use**: Added to Authorization header if present
3. **Scope**: Single function execution (no caching or persistence)
4. **Disposal**: Cleared from scope when function exits

**Validation**:
- **None**: Token format is NOT validated by our code
- **Rationale**: GitHub API is authoritative source for token validity
- **Error Handling**: Invalid tokens result in HTTP 401 from GitHub

**Properties**:

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| Value | String | The complete token string | `ghp_1A2b3C...` |
| IsPresent | Boolean | Whether `$env:GITHUB_TOKEN` exists | `$true` or `$false` |

**Pseudocode Access**:
```powershell
$token = $env:GITHUB_TOKEN  # May be $null
$isAuthenticated = -not [string]::IsNullOrWhiteSpace($token)
```

**Security Constraints**:
- ❌ NEVER logged to any output stream
- ❌ NEVER persisted to files (manifest, config, backups)
- ❌ NEVER included in error messages
- ❌ NEVER displayed in verbose/debug output
- ✅ ONLY used in Authorization header construction

---

### 2. Authentication Status

**Source**: Computed at runtime based on `GITHUB_TOKEN` presence

**Format**:
- **Type**: Boolean (authenticated vs unauthenticated)
- **Computation**: `$env:GITHUB_TOKEN` is not null/empty

**Purpose**:
- Determines which Authorization header to add (Bearer vs none)
- Controls verbose logging message (authenticated vs unauthenticated)
- Controls error message content (show token tip vs hide tip)

**Properties**:

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| IsAuthenticated | Boolean | True if token present and non-empty | `$true` |
| RateLimitQuota | Integer | Expected requests/hour (60 or 5000) | `5000` |
| LoggingMessage | String | Verbose output message | "Using authenticated request (rate limit: 5,000 req/hour)" |

**State Transitions**:
```
┌─────────────────────┐
│  Function Invoked   │
└──────────┬──────────┘
           │
           ▼
    ┌──────────────┐
    │ Check Token  │
    └──────┬───────┘
           │
      ┌────┴────┐
      │         │
      ▼         ▼
┌───────────┐ ┌────────────────┐
│ Token Set │ │ Token Not Set  │
└─────┬─────┘ └────────┬───────┘
      │                │
      ▼                ▼
┌────────────────┐ ┌─────────────────┐
│ Authenticated  │ │ Unauthenticated │
│ 5000 req/hour  │ │ 60 req/hour     │
└────────────────┘ └─────────────────┘
```

**Pseudocode**:
```powershell
function Get-AuthenticationStatus {
    $token = $env:GITHUB_TOKEN
    $isAuthenticated = -not [string]::IsNullOrWhiteSpace($token)

    return [PSCustomObject]@{
        IsAuthenticated = $isAuthenticated
        RateLimitQuota  = if ($isAuthenticated) { 5000 } else { 60 }
        LoggingMessage  = if ($isAuthenticated) {
            "Using authenticated request (rate limit: 5,000 req/hour)"
        } else {
            "Using unauthenticated request (rate limit: 60 req/hour)"
        }
    }
}
```

---

### 3. GitHub API Request Headers

**Source**: Constructed at request time based on authentication status

**Format**: PowerShell hashtable

**Structure**:

**Unauthenticated Request** (no token):
```powershell
@{
    "Accept"     = "application/vnd.github.v3+json"
    "User-Agent" = "SpecKit-Updater-PowerShell"
}
```

**Authenticated Request** (with token):
```powershell
@{
    "Accept"        = "application/vnd.github.v3+json"
    "User-Agent"    = "SpecKit-Updater-PowerShell"
    "Authorization" = "Bearer ghp_1A2b3C4d5E6f7G8h9I0jK1lM2nO3pQ4rS5t"
}
```

**Properties**:

| Header | Required | Description | Value |
|--------|----------|-------------|-------|
| Accept | ✅ | API version selection | `application/vnd.github.v3+json` |
| User-Agent | ✅ | Client identification | `SpecKit-Updater-PowerShell` |
| Authorization | ⚠️ | Authentication token (conditional) | `Bearer {token}` (only if token present) |

**Header Construction Logic**:
```powershell
$headers = @{
    "Accept"     = "application/vnd.github.v3+json"
    "User-Agent" = "SpecKit-Updater-PowerShell"
}

# Conditional Authorization header
if ($env:GITHUB_TOKEN) {
    $headers["Authorization"] = "Bearer $env:GITHUB_TOKEN"
    Write-Verbose "Using authenticated request (rate limit: 5,000 req/hour)"
} else {
    Write-Verbose "Using unauthenticated request (rate limit: 60 req/hour)"
}

$response = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $headers
```

---

### 4. GitHub API Rate Limit Response Headers

**Source**: HTTP response headers from GitHub API (included on every response)

**Format**: HTTP headers (key-value pairs)

**Structure**:

| Header | Type | Description | Example |
|--------|------|-------------|---------|
| X-RateLimit-Limit | Integer | Maximum requests per hour | `5000` (authenticated) or `60` (unauthenticated) |
| X-RateLimit-Remaining | Integer | Requests remaining in current window | `4850` |
| X-RateLimit-Reset | Unix Timestamp | When rate limit resets (UTC) | `1704067200` |
| X-RateLimit-Used | Integer | Requests used in current window | `150` |
| X-RateLimit-Resource | String | Resource type (core, search, graphql) | `core` |

**Usage in Error Handling**:
```powershell
try {
    $response = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $headers
}
catch {
    $statusCode = $_.Exception.Response.StatusCode

    if ($statusCode -eq 403) {
        # Extract rate limit headers
        $headers = $_.Exception.Response.Headers
        $remaining = $headers["X-RateLimit-Remaining"]
        $reset = $headers["X-RateLimit-Reset"]

        # Check if this is a rate limit error (not access denial)
        if ($remaining -eq "0") {
            # Convert Unix timestamp to local time
            $resetTime = [DateTimeOffset]::FromUnixTimeSeconds($reset).LocalDateTime

            $errorMsg = "GitHub API rate limit exceeded. Resets at: $resetTime"

            # Conditionally suggest token setup
            if (-not $env:GITHUB_TOKEN) {
                $errorMsg += "`n`nTip: Set GITHUB_TOKEN environment variable"
                $errorMsg += " to increase rate limit from 60 to 5,000 requests/hour."
            }

            Write-Error $errorMsg
            throw $errorMsg
        }
    }

    # Re-throw other errors
    throw
}
```

**Rate Limit Reset Time Conversion**:
```powershell
# GitHub provides Unix timestamp (seconds since 1970-01-01 00:00:00 UTC)
$unixTimestamp = 1704067200

# Convert to local DateTime for user display
$resetTime = [DateTimeOffset]::FromUnixTimeSeconds($unixTimestamp).LocalDateTime
# Example output: "1/1/2024 3:00:00 PM" (user's local timezone)
```

---

### 5. Error Response Structure

**Source**: Constructed by our code when rate limiting or authentication errors occur

**Format**: PowerShell error message string

**Structure**:

**Rate Limit Error (without token)**:
```
GitHub API rate limit exceeded. Resets at: 3:00 PM

Tip: Set GITHUB_TOKEN environment variable to increase rate limit from 60 to 5,000 requests/hour.
     Learn more: https://github.com/NotMyself/claude-win11-speckit-update-skill#github-token
```

**Rate Limit Error (with token)**:
```
GitHub API rate limit exceeded. Resets at: 3:00 PM
```

**Authentication Error (invalid/expired token)**:
```
GitHub API request failed: 401 Unauthorized
```

**Properties**:

| Component | Type | Description | Example |
|-----------|------|-------------|---------|
| Error Type | String | Brief error classification | "GitHub API rate limit exceeded" |
| Context | DateTime | When rate limit resets | "Resets at: 3:00 PM" |
| Guidance | String (optional) | Actionable suggestion | "Tip: Set GITHUB_TOKEN..." |
| Documentation Link | URL (optional) | Link to setup instructions | "https://github.com/..." |

**Conditional Guidance Logic**:
```powershell
$errorMsg = "GitHub API rate limit exceeded. Resets at: $resetTime"

# Only show token setup tip if user is NOT already using a token
if (-not $env:GITHUB_TOKEN) {
    $errorMsg += "`n`nTip: Set GITHUB_TOKEN environment variable"
    $errorMsg += " to increase rate limit from 60 to 5,000 requests/hour."
    $errorMsg += "`n     Learn more: https://github.com/NotMyself/claude-win11-speckit-update-skill#github-token"
}
```

---

## Data Flow Diagram

```
┌────────────────────────────────────────────────────┐
│ User Environment                                   │
│  ┌────────────────────────────┐                    │
│  │ $env:GITHUB_TOKEN          │                    │
│  │ (Optional, set by user)    │                    │
│  └─────────────┬──────────────┘                    │
└────────────────┼───────────────────────────────────┘
                 │
                 ▼
┌────────────────────────────────────────────────────┐
│ Invoke-GitHubApiRequest Function                   │
│                                                     │
│  ┌──────────────────────────────────────┐          │
│  │ 1. Read Token from Environment       │          │
│  │    $token = $env:GITHUB_TOKEN        │          │
│  └─────────────┬────────────────────────┘          │
│                │                                    │
│                ▼                                    │
│  ┌──────────────────────────────────────┐          │
│  │ 2. Build Request Headers             │          │
│  │    - Accept: application/vnd.github  │          │
│  │    - User-Agent: SpecKit-Updater     │          │
│  │    - Authorization: Bearer {token}   │◄─ Only if token present
│  └─────────────┬────────────────────────┘          │
│                │                                    │
│                ▼                                    │
│  ┌──────────────────────────────────────┐          │
│  │ 3. Log Authentication Status         │          │
│  │    Write-Verbose "Using auth..."     │          │
│  └─────────────┬────────────────────────┘          │
└────────────────┼───────────────────────────────────┘
                 │
                 ▼
┌────────────────────────────────────────────────────┐
│ GitHub API (api.github.com)                        │
│                                                     │
│  ┌──────────────────────────────────────┐          │
│  │ Validate Authorization Header        │          │
│  └─────────────┬────────────────────────┘          │
│                │                                    │
│       ┌────────┴────────┐                          │
│       │                 │                          │
│       ▼                 ▼                          │
│  ┌─────────┐       ┌──────────┐                   │
│  │ Valid   │       │ Invalid  │                    │
│  └────┬────┘       └────┬─────┘                   │
│       │                 │                          │
│       ▼                 ▼                          │
│  ┌─────────────┐   ┌────────────┐                 │
│  │ 200 OK      │   │ 401 Unauth │                 │
│  │ + Payload   │   │            │                 │
│  └─────┬───────┘   └────┬───────┘                 │
└────────┼────────────────┼────────────────────────┘
         │                │
         ▼                ▼
┌────────────────────────────────────────────────────┐
│ Response Processing                                 │
│                                                     │
│  Success Path:                                      │
│  ┌──────────────────────────────────────┐          │
│  │ Return Response Data                 │          │
│  └──────────────────────────────────────┘          │
│                                                     │
│  Error Path (401):                                  │
│  ┌──────────────────────────────────────┐          │
│  │ Write-Error "401 Unauthorized"       │          │
│  └──────────────────────────────────────┘          │
│                                                     │
│  Error Path (403 Rate Limit):                       │
│  ┌──────────────────────────────────────┐          │
│  │ 1. Parse X-RateLimit-Reset           │          │
│  │ 2. Convert to local DateTime         │          │
│  │ 3. Build error message               │          │
│  │ 4. Conditionally add token tip       │          │
│  │ 5. Write-Error with guidance         │          │
│  └──────────────────────────────────────┘          │
└────────────────────────────────────────────────────┘
```

---

## State Transitions

### Authentication State Machine

```
     ┌─────────────────┐
     │ Function Start  │
     └────────┬────────┘
              │
              ▼
      ┌───────────────┐
      │ Read $env var │
      └───────┬───────┘
              │
         ┌────┴────┐
         │         │
         ▼         ▼
   ┌─────────┐  ┌──────────┐
   │ Present │  │ Absent   │
   └────┬────┘  └────┬─────┘
        │            │
        ▼            ▼
┌──────────────┐ ┌─────────────────┐
│ Add Auth     │ │ Skip Auth       │
│ Header       │ │ Header          │
└──────┬───────┘ └────┬────────────┘
       │              │
       └──────┬───────┘
              │
              ▼
     ┌─────────────────┐
     │ Make API Call   │
     └────────┬────────┘
              │
         ┌────┴────┐
         │         │
         ▼         ▼
   ┌─────────┐  ┌───────┐
   │ Success │  │ Error │
   └─────────┘  └───┬───┘
                    │
               ┌────┴─────┐
               │          │
               ▼          ▼
         ┌─────────┐ ┌─────────┐
         │ 401     │ │ 403     │
         │ Invalid │ │ Limited │
         └─────────┘ └────┬────┘
                          │
                     ┌────┴────┐
                     │         │
                     ▼         ▼
              ┌──────────┐ ┌──────────┐
              │ Has      │ │ No       │
              │ Token    │ │ Token    │
              └──────────┘ └────┬─────┘
                                │
                                ▼
                         ┌─────────────┐
                         │ Add Token   │
                         │ Setup Tip   │
                         └─────────────┘
```

---

## Persistence Strategy

**NO PERSISTENCE REQUIRED**

All data structures are ephemeral (runtime only):

| Structure | Lifetime | Persistence |
|-----------|----------|-------------|
| GitHub Token | Function execution | ❌ Never persisted (environment variable only) |
| Authentication Status | Computed per call | ❌ Not cached, recomputed each time |
| Request Headers | Single API call | ❌ Built per request, discarded after |
| Rate Limit Headers | Single API response | ❌ Parsed for error messages only |
| Error Messages | Exception lifetime | ❌ Logged to console, not saved |

**Rationale**: Token authentication is stateless. Each function invocation independently checks for token presence and constructs request headers. No caching or persistence reduces complexity and eliminates security risks (token exposure via files).

---

## Security Model

### Token Handling Security

```
┌────────────────────────────────────────────────────┐
│ Security Boundaries                                 │
│                                                     │
│  ┌──────────────────────────────────────┐          │
│  │ ✅ SAFE ZONE                         │          │
│  │ - Read from $env:GITHUB_TOKEN        │          │
│  │ - Store in local variable $token     │          │
│  │ - Add to Authorization header        │          │
│  └──────────────────────────────────────┘          │
│                                                     │
│  ┌──────────────────────────────────────┐          │
│  │ ❌ FORBIDDEN ZONE                    │          │
│  │ - Write-Verbose with $token          │          │
│  │ - Write-Host with $token             │          │
│  │ - Write-Error with $token            │          │
│  │ - Exception messages with $token     │          │
│  │ - Set-Content with $token            │          │
│  │ - Add-Content with $token            │          │
│  │ - Any file I/O with $token           │          │
│  └──────────────────────────────────────┘          │
└────────────────────────────────────────────────────┘
```

### Approved Data Flows

```
✅ ALLOWED:
$env:GITHUB_TOKEN → $headers["Authorization"] → Invoke-RestMethod

✅ ALLOWED:
$env:GITHUB_TOKEN → Boolean check → Write-Verbose "Using authenticated request"

❌ FORBIDDEN:
$env:GITHUB_TOKEN → Write-Verbose "Token: $token"

❌ FORBIDDEN:
$env:GITHUB_TOKEN → Set-Content "token.txt" $token

❌ FORBIDDEN:
$env:GITHUB_TOKEN → Exception message interpolation
```

---

## Validation Rules

| Validation | Enforced By | Failure Mode |
|------------|-------------|--------------|
| Token format | ❌ Not validated (GitHub validates) | HTTP 401 from GitHub |
| Token expiration | ❌ Not validated (GitHub validates) | HTTP 401 from GitHub |
| Token scopes | ❌ Not validated (GitHub validates) | HTTP 403 from GitHub |
| Environment variable presence | ✅ Checked (`-not [string]::IsNullOrWhiteSpace`) | Fallback to unauthenticated |
| Rate limit headers | ✅ Parsed (presence of `X-RateLimit-Remaining`) | Generic 403 error if missing |

**Rationale for Minimal Validation**: GitHub API is the authoritative source for token validity. Local validation would duplicate logic, risk false positives/negatives, and add complexity. Let GitHub provide accurate error responses.

---

## Data Model Summary

| Entity | Type | Lifetime | Persistence | Security |
|--------|------|----------|-------------|----------|
| GitHub Token | Environment Variable | Session/Profile | ❌ None | 🔒 Never logged |
| Auth Status | Computed Boolean | Function call | ❌ None | ✅ Safe to log |
| Request Headers | Hashtable | API call | ❌ None | ⚠️ Contains token |
| Rate Limit Headers | HTTP Response | Error handling | ❌ None | ✅ Safe to log |
| Error Messages | String | Exception | ❌ None | ✅ No token values |

**Complexity**: Minimal. This feature introduces no persistent state, no data schema changes, no database interactions. All structures are simple PowerShell primitives (strings, hashtables, booleans).
