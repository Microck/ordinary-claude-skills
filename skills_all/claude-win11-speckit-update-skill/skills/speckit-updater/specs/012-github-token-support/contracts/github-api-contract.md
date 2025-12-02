# API Contract: GitHub REST API Integration

**Feature**: 012-github-token-support
**Phase**: 1 (Design Artifacts)
**Date**: 2025-10-23
**API Version**: GitHub REST API v3

## Overview

This document defines the contract between the SpecKit updater and the GitHub REST API. The integration focuses on fetching release information from public repositories with optional authentication for increased rate limits.

**Base URL**: `https://api.github.com`
**Authentication**: Optional (Bearer token)
**API Documentation**: https://docs.github.com/en/rest

---

## Endpoint: Get Latest Release

### Request

**Method**: `GET`
**Path**: `/repos/{owner}/{repo}/releases/latest`
**Example**: `GET https://api.github.com/repos/github/spec-kit/releases/latest`

**Headers** (Unauthenticated):
```http
Accept: application/vnd.github.v3+json
User-Agent: SpecKit-Updater-PowerShell
```

**Headers** (Authenticated):
```http
Accept: application/vnd.github.v3+json
User-Agent: SpecKit-Updater-PowerShell
Authorization: Bearer ghp_1A2b3C4d5E6f7G8h9I0jK1lM2nO3pQ4rS5t
```

**PowerShell Implementation**:
```powershell
$headers = @{
    "Accept"     = "application/vnd.github.v3+json"
    "User-Agent" = "SpecKit-Updater-PowerShell"
}

if ($env:GITHUB_PAT) {
    $headers["Authorization"] = "Bearer $env:GITHUB_PAT"
}

$uri = "https://api.github.com/repos/github/spec-kit/releases/latest"
$response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
```

---

### Response (Success)

**Status Code**: `200 OK`

**Headers**:
```http
Content-Type: application/json; charset=utf-8
X-RateLimit-Limit: 5000
X-RateLimit-Remaining: 4850
X-RateLimit-Reset: 1704067200
X-RateLimit-Used: 150
X-RateLimit-Resource: core
```

**Body** (Partial - only fields used by updater):
```json
{
  "url": "https://api.github.com/repos/github/spec-kit/releases/123456",
  "html_url": "https://github.com/github/spec-kit/releases/tag/v0.0.72",
  "id": 123456,
  "tag_name": "v0.0.72",
  "name": "Release v0.0.72",
  "published_at": "2024-01-15T14:22:10Z",
  "zipball_url": "https://api.github.com/repos/github/spec-kit/zipball/v0.0.72",
  "tarball_url": "https://api.github.com/repos/github/spec-kit/tarball/v0.0.72"
}
```

**Fields Used by Updater**:

| Field | Type | Description | Usage |
|-------|------|-------------|-------|
| `tag_name` | String | Release version tag | Compare with current version |
| `tarball_url` | String | Download URL for release archive | Download templates |
| `published_at` | ISO 8601 Date | Release publication timestamp | Display to user |

**PowerShell Access**:
```powershell
$release = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers

$version = $release.tag_name              # "v0.0.72"
$downloadUrl = $release.tarball_url       # "https://api.github.com/..."
$publishDate = $release.published_at      # "2024-01-15T14:22:10Z"
```

---

### Response (Rate Limit Exceeded)

**Status Code**: `403 Forbidden`

**Headers**:
```http
Content-Type: application/json; charset=utf-8
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1704067200
X-RateLimit-Used: 60
X-RateLimit-Resource: core
```

**Body**:
```json
{
  "message": "API rate limit exceeded for 203.0.113.1. (But here's the good news: Authenticated requests get a higher rate limit. Check out the documentation for more details.)",
  "documentation_url": "https://docs.github.com/rest/overview/resources-in-the-rest-api#rate-limiting"
}
```

**PowerShell Error Handling**:
```powershell
try {
    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
}
catch {
    $statusCode = $_.Exception.Response.StatusCode

    if ($statusCode -eq 403) {
        $responseHeaders = $_.Exception.Response.Headers
        $remaining = $responseHeaders["X-RateLimit-Remaining"]
        $reset = $responseHeaders["X-RateLimit-Reset"]

        if ($remaining -eq "0") {
            # Rate limited!
            $resetTime = [DateTimeOffset]::FromUnixTimeSeconds($reset).LocalDateTime

            $errorMsg = "GitHub API rate limit exceeded. Resets at: $resetTime"

            # Suggest token if not using one
            if (-not $env:GITHUB_PAT) {
                $errorMsg += "`n`nTip: Set GITHUB_PAT environment variable"
                $errorMsg += " to increase rate limit from 60 to 5,000 requests/hour."
                $errorMsg += "`n     Learn more: https://github.com/NotMyself/claude-win11-speckit-update-skill#github-token"
            }

            Write-Error $errorMsg
            throw
        }
    }

    # Re-throw other errors
    throw
}
```

---

### Response (Unauthorized - Invalid Token)

**Status Code**: `401 Unauthorized`

**Headers**:
```http
Content-Type: application/json; charset=utf-8
```

**Body**:
```json
{
  "message": "Bad credentials",
  "documentation_url": "https://docs.github.com/rest"
}
```

**Causes**:
- Token is malformed (invalid format)
- Token is expired (exceeded expiration date)
- Token is revoked (manually revoked by user or GitHub)
- Token is invalid (never existed or typo)

**PowerShell Error Handling**:
```powershell
try {
    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
}
catch {
    $statusCode = $_.Exception.Response.StatusCode

    if ($statusCode -eq 401) {
        $errorMsg = "GitHub API request failed: 401 Unauthorized"
        $errorMsg += "`nYour GITHUB_PAT may be invalid, expired, or revoked."
        $errorMsg += "`nVerify your token or remove it to use unauthenticated requests."

        Write-Error $errorMsg
        throw
    }

    throw
}
```

---

### Response (Not Found)

**Status Code**: `404 Not Found`

**Headers**:
```http
Content-Type: application/json; charset=utf-8
```

**Body**:
```json
{
  "message": "Not Found",
  "documentation_url": "https://docs.github.com/rest/releases/releases#get-the-latest-release"
}
```

**Causes**:
- Repository doesn't exist
- Repository has no releases
- Repository owner/name typo in URL

**PowerShell Error Handling**:
```powershell
try {
    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
}
catch {
    $statusCode = $_.Exception.Response.StatusCode

    if ($statusCode -eq 404) {
        $errorMsg = "GitHub repository or release not found."
        $errorMsg += "`nVerify repository exists and has published releases."

        Write-Error $errorMsg
        throw
    }

    throw
}
```

---

## Rate Limiting Contract

### Rate Limit Quotas

| Authentication | Requests/Hour | Per | Reset Window |
|---------------|---------------|-----|--------------|
| Unauthenticated | 60 | IP Address | 60 minutes |
| Authenticated (Token) | 5,000 | User | 60 minutes |
| Authenticated (OAuth App) | 5,000 | User | 60 minutes |
| Authenticated (GitHub App) | 5,000 | Installation | 60 minutes |

**Rate Limit Headers** (included on every response):

| Header | Type | Description | Example |
|--------|------|-------------|---------|
| `X-RateLimit-Limit` | Integer | Maximum requests per hour | `5000` |
| `X-RateLimit-Remaining` | Integer | Requests remaining | `4850` |
| `X-RateLimit-Reset` | Unix Timestamp | Reset time (UTC) | `1704067200` |
| `X-RateLimit-Used` | Integer | Requests used | `150` |
| `X-RateLimit-Resource` | String | Resource category | `core` |

**Rate Limit Calculation**:
```
Remaining = Limit - Used
Time Until Reset = Reset - CurrentTime
```

**PowerShell Rate Limit Parsing**:
```powershell
$headers = $response.Headers

$limit = [int]$headers["X-RateLimit-Limit"][0]
$remaining = [int]$headers["X-RateLimit-Remaining"][0]
$reset = [int]$headers["X-RateLimit-Reset"][0]

$resetTime = [DateTimeOffset]::FromUnixTimeSeconds($reset).LocalDateTime

Write-Host "Rate Limit: $remaining / $limit remaining"
Write-Host "Resets at: $resetTime"
```

---

## Authentication Contract

### Bearer Token Format

**Header**: `Authorization: Bearer {token}`

**Token Format**: `ghp_` + 36 alphanumeric characters

**Example**: `Authorization: Bearer ghp_1A2b3C4d5E6f7G8h9I0jK1lM2nO3pQ4rS5t`

**Required Scopes**:
- **None** (for public repository read access)
- Tokens with no scopes selected can read public repositories

**Token Validation**:
- ✅ GitHub validates token on each request
- ❌ We do NOT validate token format locally
- ❌ We do NOT check token expiration locally
- ❌ We do NOT verify token scopes locally

**Rationale**: GitHub is authoritative source for token validity. Local validation risks false positives/negatives.

---

## Error Handling Strategy

### Error Priority

1. **401 Unauthorized** → Token problem (fix token or remove)
2. **403 Rate Limit** → Too many requests (wait or add token)
3. **404 Not Found** → Repository/release missing (verify URL)
4. **Other 4xx/5xx** → Unexpected errors (report to user)

### Error Message Requirements

| Error Type | Status Code | Message Must Include | Example |
|------------|-------------|----------------------|---------|
| Rate Limit | 403 | Reset time, token suggestion (if no token) | "Resets at: 3:00 PM. Tip: Set GITHUB_PAT..." |
| Unauthorized | 401 | Token validity hint | "Your token may be invalid or expired" |
| Not Found | 404 | Resource identification | "Repository or release not found" |
| Network | N/A | Connectivity context | "Failed to connect to api.github.com" |

---

## Versioning & Stability

**API Version**: GitHub REST API v3
**Stability**: Stable (production-ready, backward compatible)
**Deprecation Policy**: GitHub provides 18-month deprecation notice
**Header**: `Accept: application/vnd.github.v3+json`

**Future-Proofing**:
- API v3 is stable and will be supported indefinitely
- If we need v4 (GraphQL) features in future, create new module
- Current implementation does not need changes for API v3

---

## Testing Contract

### Unit Test Mocking

**Mock Successful Response**:
```powershell
Mock Invoke-RestMethod {
    return @{
        tag_name      = "v0.0.72"
        tarball_url   = "https://api.github.com/repos/github/spec-kit/tarball/v0.0.72"
        published_at  = "2024-01-15T14:22:10Z"
    }
}
```

**Mock Rate Limit Error**:
```powershell
Mock Invoke-RestMethod {
    $exception = [System.Net.WebException]::new("Rate limit exceeded")
    $response = New-Object PSObject
    $response | Add-Member -NotePropertyName StatusCode -NotePropertyValue 403
    $response | Add-Member -NotePropertyName Headers -NotePropertyValue @{
        "X-RateLimit-Remaining" = "0"
        "X-RateLimit-Reset"     = "1704067200"
    }

    $exception | Add-Member -NotePropertyName Response -NotePropertyValue $response
    throw $exception
}
```

**Mock Unauthorized Error**:
```powershell
Mock Invoke-RestMethod {
    $exception = [System.Net.WebException]::new("Unauthorized")
    $response = New-Object PSObject
    $response | Add-Member -NotePropertyName StatusCode -NotePropertyValue 401

    $exception | Add-Member -NotePropertyName Response -NotePropertyValue $response
    throw $exception
}
```

### Integration Test Requirements

**Real API Call** (with test token):
```powershell
$env:GITHUB_PAT = $env:GITHUB_TEST_TOKEN  # From CI secrets

$uri = "https://api.github.com/repos/github/spec-kit/releases/latest"
$headers = @{
    "Accept"        = "application/vnd.github.v3+json"
    "User-Agent"    = "SpecKit-Updater-PowerShell"
    "Authorization" = "Bearer $env:GITHUB_PAT"
}

$release = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers

# Assertions
$release.tag_name | Should -Match "^v\d+\.\d+\.\d+$"
$release.tarball_url | Should -Match "^https://api.github.com/"
```

---

## Security Considerations

### Token Exposure Prevention

**Safe Operations**:
```powershell
# ✅ SAFE: Add token to Authorization header
$headers["Authorization"] = "Bearer $env:GITHUB_PAT"

# ✅ SAFE: Check for token presence
if ($env:GITHUB_PAT) { ... }

# ✅ SAFE: Log authentication status
Write-Verbose "Using authenticated request"
```

**Unsafe Operations** (FORBIDDEN):
```powershell
# ❌ FORBIDDEN: Log token value
Write-Verbose "Token: $env:GITHUB_PAT"

# ❌ FORBIDDEN: Include token in error
Write-Error "Failed with token $env:GITHUB_PAT"

# ❌ FORBIDDEN: Write token to file
Set-Content "token.txt" $env:GITHUB_PAT
```

### HTTPS Requirement

**All requests MUST use HTTPS** (`https://api.github.com`).

**Rationale**:
- Tokens transmitted in Authorization header
- HTTPS encrypts headers (prevents token interception)
- GitHub API only available via HTTPS (HTTP redirects to HTTPS)

**Verification**:
```powershell
# ✅ CORRECT
$uri = "https://api.github.com/repos/owner/repo/releases/latest"

# ❌ INCORRECT (will be redirected, but avoid)
$uri = "http://api.github.com/repos/owner/repo/releases/latest"
```

---

## Contract Summary

| Aspect | Specification |
|--------|--------------|
| **Base URL** | `https://api.github.com` |
| **Authentication** | Optional Bearer token via Authorization header |
| **Rate Limits** | 60/hour (unauth) or 5,000/hour (auth) |
| **Response Format** | JSON |
| **Error Codes** | 200 (success), 401 (invalid token), 403 (rate limit), 404 (not found) |
| **Required Headers** | Accept, User-Agent, Authorization (optional) |
| **Rate Limit Headers** | X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset |
| **Security** | HTTPS only, never log token values |
| **API Version** | v3 (stable) |
| **Documentation** | https://docs.github.com/en/rest |

---

## References

- [GitHub REST API Documentation](https://docs.github.com/en/rest)
- [GitHub REST API Authentication](https://docs.github.com/en/rest/overview/authenticating-to-the-rest-api)
- [GitHub REST API Rate Limiting](https://docs.github.com/en/rest/overview/rate-limits-for-the-rest-api)
- [GitHub Releases API](https://docs.github.com/en/rest/releases/releases)
- [OAuth 2.0 Bearer Token Usage (RFC 6750)](https://datatracker.ietf.org/doc/html/rfc6750)
