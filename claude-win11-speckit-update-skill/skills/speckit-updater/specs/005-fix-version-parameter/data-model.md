# Data Model: Fix Version Parameter Handling in Update Orchestrator

**Feature**: `005-fix-version-parameter`
**Date**: 2025-10-20
**Phase**: 1 (Design & Contracts)

## Overview

This document defines the data structures used by the GitHub API client and update orchestrator, focusing on API response formats, validation requirements, and error classifications.

## GitHub API Response Models

### 1. Release Object (Successful Response)

**Description**: Object returned by GitHub Releases API for a single release.

**Source**: `GET /repos/{owner}/{repo}/releases/latest` or `GET /repos/{owner}/{repo}/releases/tags/{tag}`

**Structure**:
```json
{
  "tag_name": "v0.0.72",
  "name": "Release v0.0.72",
  "published_at": "2025-01-15T10:30:00Z",
  "assets": [
    {
      "name": "claude-templates.zip",
      "browser_download_url": "https://github.com/.../claude-templates.zip",
      "size": 12345,
      "content_type": "application/zip"
    }
  ],
  "body": "Release notes...",
  "draft": false,
  "prerelease": false
}
```

**Required Properties** (for SpecKit updates):
- `tag_name` (string): Version identifier (e.g., "v0.0.72") - **MANDATORY**
- `assets` (array): List of downloadable artifacts - **MANDATORY**

**Optional Properties** (informational):
- `name` (string): Human-readable release name
- `published_at` (string): ISO 8601 timestamp
- `body` (string): Release notes markdown
- `draft` (boolean): Whether release is a draft
- `prerelease` (boolean): Whether release is a pre-release

**Validation Rules**:
1. Object must not be null
2. `tag_name` property must exist and be non-empty string
3. `tag_name` must match pattern: `v\d+\.\d+\.\d+` (semantic version)
4. `assets` array must exist (can be empty, validated later)

**PowerShell Representation**:
```powershell
[PSCustomObject]@{
    tag_name = [string]    # REQUIRED
    name = [string]        # optional
    published_at = [string] # optional
    assets = [array]       # REQUIRED
    body = [string]        # optional
    draft = [bool]         # optional
    prerelease = [bool]    # optional
}
```

---

### 2. Release Asset Object

**Description**: Individual downloadable file within a release.

**Structure**:
```json
{
  "name": "claude-templates.zip",
  "browser_download_url": "https://github.com/owner/repo/releases/download/v0.0.72/claude-templates.zip",
  "size": 12345,
  "content_type": "application/zip",
  "state": "uploaded",
  "download_count": 42
}
```

**Required Properties**:
- `name` (string): Asset filename - **MANDATORY**
- `browser_download_url` (string): Direct download URL - **MANDATORY**

**Validation Rules**:
1. `name` must equal "claude-templates.zip" (SpecKit-specific requirement)
2. `browser_download_url` must be valid HTTPS URL
3. `size` should be > 0 (optional validation)

**PowerShell Representation**:
```powershell
[PSCustomObject]@{
    name = [string]                 # REQUIRED
    browser_download_url = [string] # REQUIRED
    size = [int]                    # optional
    content_type = [string]         # optional
    state = [string]                # optional
}
```

---

## Error Response Models

### 3. GitHub API Error Response (HTTP 4xx/5xx)

**Description**: Error response structure when GitHub API request fails.

**Common Status Codes**:
- `403 Forbidden`: Rate limit exceeded
- `404 Not Found`: Repository or release doesn't exist
- `500 Internal Server Error`: GitHub server error
- `503 Service Unavailable`: GitHub temporarily unavailable

**Structure** (for HTTP errors):
```json
{
  "message": "API rate limit exceeded for [IP address]",
  "documentation_url": "https://docs.github.com/rest/overview/resources-in-the-rest-api#rate-limiting"
}
```

**Rate Limit Headers** (HTTP 403 responses):
- `X-RateLimit-Limit`: Maximum requests per hour (e.g., "60")
- `X-RateLimit-Remaining`: Requests remaining (e.g., "0")
- `X-RateLimit-Reset`: Unix timestamp when limit resets (e.g., "1697558400")

**PowerShell Exception Structure**:
```powershell
try {
    Invoke-RestMethod -Uri $uri
}
catch {
    # $_.Exception has these properties:
    $_.Exception.Message          # Error message
    $_.Exception.Response         # HttpWebResponse object (if HTTP error)
    $_.Exception.Response.StatusCode  # HTTP status code enum
    $_.Exception.Response.Headers     # Response headers collection
}
```

---

### 4. Error Classification Taxonomy

**Description**: Categorization of error types for appropriate handling and user messaging.

| Error Type | HTTP Code | Detection | User Message Template | Exit Code |
|------------|-----------|-----------|----------------------|-----------|
| **Network Failure** | N/A | No `Response` object | "Failed to connect to GitHub API. Check network connectivity: {details}" | 3 |
| **Rate Limit** | 403 | Status = 403 | "GitHub API rate limit exceeded. Resets at: {time}. Please try again later." | 3 |
| **Not Found** | 404 | Status = 404 | "GitHub resource not found. Verify repository and release exist: {uri}" | 3 |
| **Server Error** | 500-599 | Status >= 500 | "GitHub API server error (HTTP {code}). Try again later: {message}" | 3 |
| **Invalid Response** | 200 | Missing required properties | "GitHub API returned invalid data. Missing required property: {property}" | 3 |
| **Empty Response** | 200 | Response is null | "GitHub API returned empty response. Unable to fetch release information." | 3 |

**PowerShell Error Handling Structure**:
```powershell
enum ErrorType {
    NetworkFailure
    RateLimitExceeded
    NotFound
    ServerError
    InvalidResponse
    EmptyResponse
}

function Get-ErrorClassification {
    param($Exception)

    if (-not $Exception.Response) {
        return [ErrorType]::NetworkFailure
    }

    $statusCode = [int]$Exception.Response.StatusCode

    switch ($statusCode) {
        403 { return [ErrorType]::RateLimitExceeded }
        404 { return [ErrorType]::NotFound }
        { $_ -ge 500 } { return [ErrorType]::ServerError }
        default { return [ErrorType]::NetworkFailure }
    }
}
```

---

## Validation State Models

### 5. Release Validation Result

**Description**: Internal object tracking validation status of GitHub API responses.

**Structure**:
```powershell
[PSCustomObject]@{
    IsValid = [bool]           # Overall validation status
    Release = [PSCustomObject] # The release object (or $null)
    Errors = [array]           # List of validation error messages
    ValidationTime = [datetime] # When validation occurred
}
```

**Usage Pattern**:
```powershell
function Test-ReleaseValidity {
    param($Release)

    $result = @{
        IsValid = $true
        Release = $Release
        Errors = @()
        ValidationTime = Get-Date
    }

    # Check if release exists
    if (-not $Release) {
        $result.IsValid = $false
        $result.Errors += "Release object is null"
        return [PSCustomObject]$result
    }

    # Check for tag_name
    if (-not $Release.tag_name) {
        $result.IsValid = $false
        $result.Errors += "Release missing 'tag_name' property"
    }

    # Check tag_name format
    if ($Release.tag_name -and $Release.tag_name -notmatch '^v\d+\.\d+\.\d+') {
        $result.IsValid = $false
        $result.Errors += "Invalid version format: $($Release.tag_name)"
    }

    # Check for assets
    if (-not $Release.assets) {
        $result.IsValid = $false
        $result.Errors += "Release missing 'assets' array"
    }

    return [PSCustomObject]$result
}
```

---

## State Transitions

### 6. API Call Lifecycle

**Flow**:
```
[Start]
   ↓
[Invoke API Request]
   ↓
   ├─→ [Network Error] → [Classify: NetworkFailure] → [Throw with user message] → [Exit Code 3]
   ├─→ [HTTP 403] → [Classify: RateLimitExceeded] → [Extract reset time] → [Throw with reset time] → [Exit Code 3]
   ├─→ [HTTP 404] → [Classify: NotFound] → [Throw with repository info] → [Exit Code 3]
   ├─→ [HTTP 500-599] → [Classify: ServerError] → [Throw with error details] → [Exit Code 3]
   ↓
[HTTP 200 - Response Received]
   ↓
[Validate Response Structure]
   ↓
   ├─→ [Response is null] → [Classify: EmptyResponse] → [Throw] → [Exit Code 3]
   ├─→ [Missing tag_name] → [Classify: InvalidResponse] → [Throw with property name] → [Exit Code 3]
   ├─→ [Missing assets] → [Classify: InvalidResponse] → [Throw with property name] → [Exit Code 3]
   ↓
[Validation Passed]
   ↓
[Log Success with Write-Verbose]
   ↓
[Return Validated Release Object]
   ↓
[Orchestrator: Defensive Null Check]
   ↓
[Use $targetRelease.tag_name safely]
```

---

## Data Persistence

**Note**: This bug fix does not introduce new persistent data structures. Existing manifest structure remains unchanged:

```json
{
  "version": "1.0",
  "speckit_version": "v0.0.72",  // Updated after successful update
  "last_updated": "2025-01-20T10:30:00Z",
  // ... rest of manifest
}
```

The `speckit_version` field is updated only after successful update completion, not during API validation phase.

---

## Summary

This data model defines:
1. **Release Object**: Structure of GitHub API responses with required properties
2. **Asset Object**: Structure of downloadable artifacts within releases
3. **Error Classification**: Taxonomy of error types for appropriate handling
4. **Validation Results**: Internal objects for tracking validation state
5. **State Transitions**: Flow from API call through validation to usage

All validation occurs before accessing properties, preventing the "missing mandatory parameters" error by ensuring `$targetRelease.tag_name` is always valid when used.
