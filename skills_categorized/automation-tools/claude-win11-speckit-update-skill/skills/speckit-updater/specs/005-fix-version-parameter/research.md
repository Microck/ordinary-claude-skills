# Research: Fix Version Parameter Handling in Update Orchestrator

**Feature**: `005-fix-version-parameter`
**Date**: 2025-10-20
**Phase**: 0 (Outline & Research)

## Overview

This document captures research findings for fixing the version parameter handling bug in the update orchestrator. The bug manifests as "missing mandatory parameters: SpecKitVersion" when running updates without an explicit version parameter.

## Research Topics

### 1. GitHub API Error Handling Best Practices

**Research Question**: What are the best practices for handling GitHub REST API errors in PowerShell, particularly for unauthenticated requests?

**Decision**: Implement structured error handling with specific handling for common GitHub API failure modes.

**Rationale**:
- GitHub API returns well-defined HTTP status codes (403 for rate limiting, 404 for not found, etc.)
- PowerShell's `Invoke-RestMethod` throws exceptions that include the HTTP response
- We can extract rate limit reset times from response headers
- Different error types require different user guidance

**Implementation Pattern**:
```powershell
try {
    $response = Invoke-RestMethod -Uri $uri -Headers $headers

    # Validate response structure
    if (-not $response.tag_name) {
        throw "API response missing required 'tag_name' property"
    }

    return $response
}
catch {
    if ($_.Exception.Response) {
        $statusCode = [int]$_.Exception.Response.StatusCode

        switch ($statusCode) {
            403 {
                # Rate limit - extract reset time from headers
                $resetTime = Get-RateLimitResetTime $_.Exception.Response
                throw "GitHub API rate limit exceeded. Resets at: $resetTime"
            }
            404 {
                throw "GitHub resource not found. Verify repository and release exist."
            }
            default {
                throw "GitHub API error (HTTP $statusCode): $($_.Exception.Message)"
            }
        }
    }
    else {
        # Network error - no HTTP response
        throw "Failed to connect to GitHub API. Check network connectivity: $($_.Exception.Message)"
    }
}
```

**Alternatives Considered**:
- **Simple error propagation**: Just let exceptions bubble up → Rejected because error messages would be PowerShell-internal, not user-friendly
- **Retry logic with exponential backoff**: Automatically retry failed requests → Rejected as out of scope for this bug fix (can be added later)
- **Authenticated API calls**: Use GitHub token for higher rate limits → Rejected because skill should work without setup

**References**:
- GitHub REST API documentation: https://docs.github.com/en/rest
- PowerShell error handling: https://docs.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-exceptions

---

### 2. PowerShell Null Reference Validation Patterns

**Research Question**: What is the most robust way to validate PowerShell objects before accessing properties to prevent "property does not exist" errors?

**Decision**: Use multi-stage validation with explicit null checks and property existence verification.

**Rationale**:
- PowerShell allows accessing non-existent properties without errors (returns $null)
- Accessing properties on $null objects can cause "Cannot index into a null array" errors
- Validate at two levels: (1) object exists, (2) required properties exist
- Provide specific error messages for each validation failure

**Implementation Pattern**:
```powershell
# Pattern 1: Validate in the module function (producer)
function Get-LatestSpecKitRelease {
    try {
        $release = Invoke-GitHubApiRequest -Uri $uri

        # Validate object returned
        if (-not $release) {
            throw "GitHub API returned empty response"
        }

        # Validate required properties
        if (-not $release.tag_name) {
            throw "Release data missing 'tag_name' property"
        }

        if (-not $release.assets) {
            throw "Release data missing 'assets' array"
        }

        Write-Verbose "Successfully fetched release: $($release.tag_name)"
        return $release
    }
    catch {
        Write-Error "Failed to get latest SpecKit release: $_"
        throw
    }
}

# Pattern 2: Defensive validation in orchestrator (consumer)
$targetRelease = Get-LatestSpecKitRelease

if (-not $targetRelease) {
    Write-Error "Could not retrieve target release information from GitHub"
    exit 3
}

if (-not $targetRelease.tag_name) {
    Write-Error "Release information missing version identifier"
    exit 3
}

Write-Verbose "Target version validated: $($targetRelease.tag_name)"
```

**Alternatives Considered**:
- **Single validation point**: Only validate in module OR orchestrator → Rejected because defense-in-depth is better
- **Property existence testing**: Use `[bool]($obj.PSObject.Properties[$propName])` → Rejected as overly verbose for this use case
- **Try-catch around property access**: Catch errors when accessing `$obj.tag_name` → Rejected because it doesn't fail with useful errors

**Best Practice**:
- Producer (module function): Validate structure and throw specific errors
- Consumer (orchestrator): Defensive null checks before using returned objects
- Use `Write-Verbose` to log successful validations for debugging

---

### 3. Parameter Naming Consistency

**Research Question**: What's the root cause of the "missing mandatory parameters: SpecKitVersion" error when the code uses `-Version`?

**Decision**: Audit all function signatures and call sites to ensure parameter name consistency. The actual issue is that `Get-OfficialSpecKitCommands` expects `-SpecKitVersion` while most other functions use `-Version`.

**Findings**:
After code review, these functions use different parameter names:

**Functions using `-Version`**:
- `Download-SpecKitTemplates -Version`
- `Get-SpecKitRelease -Version`
- `Get-SpecKitReleaseAssets -Version`

**Functions using `-SpecKitVersion`**:
- `Get-OfficialSpecKitCommands -SpecKitVersion` ← INCONSISTENT

**Rationale for Standardization**:
- Consistency improves code readability and reduces bugs
- `-Version` is more generic and follows PowerShell conventions (e.g., `Get-Package -Version`)
- The term "SpecKit" is implied by the module context
- Shorter parameter names reduce line length and improve clarity

**Decision**: Standardize all functions to use `-Version` parameter name.

**Implementation**:
```powershell
# Change Get-OfficialSpecKitCommands signature from:
function Get-OfficialSpecKitCommands {
    param([string]$SpecKitVersion)  # OLD
}

# To:
function Get-OfficialSpecKitCommands {
    param([string]$Version)  # NEW - consistent with other functions
}
```

**Alternatives Considered**:
- **Keep both naming conventions**: Allow `-Version` and `-SpecKitVersion` as aliases → Rejected because it adds complexity
- **Standardize to `-SpecKitVersion`**: Make all functions use the longer name → Rejected because `-Version` is more conventional
- **Parameter transformation attribute**: Automatically map between names → Rejected as over-engineering

---

### 4. Diagnostic Logging for Troubleshooting

**Research Question**: How should we add diagnostic logging to help users and developers debug GitHub API issues?

**Decision**: Use `Write-Verbose` extensively with structured messages at key checkpoints.

**Rationale**:
- Users can run with `-Verbose` flag to see detailed execution flow
- Verbose output doesn't pollute normal execution
- Helps diagnose: network issues, API response structure, validation failures
- Essential for debugging rare edge cases in production

**Implementation Pattern**:
```powershell
function Get-LatestSpecKitRelease {
    Write-Verbose "Fetching latest SpecKit release from GitHub API"
    Write-Verbose "API endpoint: $uri"

    try {
        $response = Invoke-GitHubApiRequest -Uri $uri
        Write-Verbose "API request successful"
        Write-Verbose "Response type: $($response.GetType().Name)"

        if ($response.tag_name) {
            Write-Verbose "Release version: $($response.tag_name)"
            Write-Verbose "Release assets count: $($response.assets.Count)"
        }
        else {
            Write-Verbose "WARNING: Response missing 'tag_name' property"
            Write-Verbose "Available properties: $($response.PSObject.Properties.Name -join ', ')"
        }

        return $response
    }
    catch {
        Write-Verbose "API request failed: $_"
        throw
    }
}
```

**Logging Checkpoints**:
1. Before API call: Log endpoint URL
2. After API call: Log success and response type
3. During validation: Log property existence checks
4. On error: Log error details and context
5. In orchestrator: Log validation results before using objects

**Alternatives Considered**:
- **Write-Debug instead of Write-Verbose**: → Rejected because Debug requires `-Debug` flag, less commonly used
- **Structured logging to file**: Write JSON logs to `.specify/logs/` → Rejected as out of scope for this bug fix
- **No additional logging**: Rely on error messages alone → Rejected because troubleshooting would be difficult

---

### 5. Testing Strategy for API Failure Scenarios

**Research Question**: How do we effectively test GitHub API failure scenarios without making actual API calls or requiring network access?

**Decision**: Use Pester mocking with `Mock Invoke-RestMethod` to simulate various API responses and failures.

**Rationale**:
- Pester 5.x supports mocking cmdlets effectively
- Can simulate any HTTP status code or response structure
- Tests run offline and deterministically
- Can test edge cases that are hard to reproduce with real API (rate limiting, malformed JSON, etc.)

**Implementation Pattern**:
```powershell
Describe "Get-LatestSpecKitRelease Error Handling" {
    BeforeAll {
        Import-Module "$PSScriptRoot/../../scripts/modules/GitHubApiClient.psm1" -Force
    }

    Context "When GitHub API is unreachable" {
        It "Should throw network error with helpful message" {
            Mock Invoke-RestMethod {
                throw [System.Net.WebException]::new("Unable to connect to remote server")
            }

            { Get-LatestSpecKitRelease } | Should -Throw "*Failed to connect to GitHub API*"
        }
    }

    Context "When rate limit is exceeded" {
        It "Should throw rate limit error with reset time" {
            $response = [PSCustomObject]@{
                StatusCode = 403
            } | Add-Member -MemberType ScriptMethod -Name 'Headers' -Value {
                return @{ 'X-RateLimit-Reset' = '1697558400' }
            } -PassThru

            Mock Invoke-RestMethod {
                throw [Microsoft.PowerShell.Commands.HttpResponseException]::new("Rate limit exceeded", $response)
            }

            { Get-LatestSpecKitRelease } | Should -Throw "*rate limit exceeded*"
        }
    }

    Context "When response is missing tag_name" {
        It "Should throw validation error" {
            Mock Invoke-RestMethod {
                return [PSCustomObject]@{
                    name = "Release v1.0"
                    # tag_name is missing!
                    assets = @()
                }
            }

            { Get-LatestSpecKitRelease } | Should -Throw "*missing*tag_name*"
        }
    }

    Context "When response is null" {
        It "Should throw empty response error" {
            Mock Invoke-RestMethod {
                return $null
            }

            { Get-LatestSpecKitRelease } | Should -Throw "*empty response*"
        }
    }
}
```

**Test Fixtures**:
Create mock response files in `tests/fixtures/mock-responses/`:
- `valid-release.json` - Successful API response
- `missing-tag-name.json` - Malformed response
- `invalid-json.json` - Invalid JSON structure
- `rate-limit-error.json` - 403 rate limit response
- `not-found-error.json` - 404 not found response

**Alternatives Considered**:
- **Integration tests against real GitHub API**: → Rejected because tests would be flaky and consume rate limit
- **Record/replay HTTP interactions**: Use tools like Polly to record real API calls → Rejected as over-engineering for this project
- **No mocking, test error handling manually**: → Rejected because manual testing doesn't prevent regressions

---

## Summary of Decisions

| Decision Area | Chosen Approach | Key Benefit |
|--------------|-----------------|-------------|
| **Error Handling** | Structured error handling with specific messages for HTTP status codes | Users get actionable error messages |
| **Null Validation** | Two-stage validation (module + orchestrator) | Defense-in-depth prevents crashes |
| **Parameter Names** | Standardize all functions to use `-Version` | Consistency reduces confusion |
| **Diagnostic Logging** | Extensive `Write-Verbose` at checkpoints | Troubleshooting without code changes |
| **Testing** | Pester mocking with test fixtures | Reliable offline tests for edge cases |

## Implementation Checklist

Based on research findings, implementation must:

- [ ] Enhance `Invoke-GitHubApiRequest` with specific error handling for 403, 404, and network errors
- [ ] Add validation to `Get-LatestSpecKitRelease` for null responses and missing properties
- [ ] Add defensive null checks in orchestrator after calling `Get-LatestSpecKitRelease`
- [ ] Rename parameter in `Get-OfficialSpecKitCommands` from `-SpecKitVersion` to `-Version`
- [ ] Add `Write-Verbose` logging at all validation checkpoints
- [ ] Create Pester unit tests for all error scenarios
- [ ] Create mock API response fixtures for testing
- [ ] Update integration tests to cover API failure cases
- [ ] Update function documentation to reflect error handling behavior

## Next Phase

With research complete, proceed to **Phase 1: Design & Contracts** to:
1. Document API response data model (`data-model.md`)
2. Define error type taxonomy
3. Create quickstart guide for testing the fix
