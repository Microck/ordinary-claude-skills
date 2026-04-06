# GitHubApiClient Module Implementation

## Overview

The `GitHubApiClient.psm1` module provides a PowerShell interface to the GitHub Releases API for the SpecKit Safe Update Skill. It handles fetching release information, downloading templates, and managing API rate limits.

## Implementation Details

### Location
- **Module**: `C:\Users\bobby\src\claude-Win11-SpecKit-Safe-Update-Skill\scripts\modules\GitHubApiClient.psm1`
- **Tests**: `C:\Users\bobby\src\claude-Win11-SpecKit-Safe-Update-Skill\tests\unit\GitHubApiClient.Tests.ps1`

### Metrics
- **Module Lines**: 240
- **Test Lines**: 341
- **Test Coverage**: 17 unit tests (all passing)
- **Functions Exported**: 5 public functions

## Exported Functions

### 1. Get-LatestSpecKitRelease
Fetches the latest release information from the github/spec-kit repository.

**Usage:**
```powershell
$release = Get-LatestSpecKitRelease
Write-Host "Latest version: $($release.tag_name)"
```

**Returns:** PSCustomObject with release information including:
- `tag_name` - Release version tag (e.g., "v0.0.72")
- `name` - Release name
- `published_at` - Publication timestamp
- `assets` - Array of downloadable assets

### 2. Get-SpecKitRelease
Fetches a specific release by version tag.

**Parameters:**
- `Version` (string, required) - Release tag (e.g., "v0.0.72" or "0.0.72")

**Usage:**
```powershell
$release = Get-SpecKitRelease -Version "v0.0.72"
# or
$release = Get-SpecKitRelease -Version "0.0.72"  # Automatically adds 'v' prefix
```

**Returns:** PSCustomObject with release information

### 3. Get-SpecKitReleaseAssets
Gets the assets (downloadable files) for a specific release.

**Parameters:**
- `Version` (string, required) - Release tag

**Usage:**
```powershell
$assets = Get-SpecKitReleaseAssets -Version "v0.0.72"
foreach ($asset in $assets) {
    Write-Host "$($asset.name) - $($asset.size) bytes"
}
```

**Returns:** Array of PSCustomObject with asset information:
- `name` - Asset filename
- `browser_download_url` - Download URL
- `size` - File size in bytes

### 4. Download-SpecKitTemplates
Downloads and extracts the Claude templates from a specific release.

**Parameters:**
- `Version` (string, required) - Release tag
- `DestinationPath` (string, required) - Temporary directory for download

**Usage:**
```powershell
$templates = Download-SpecKitTemplates -Version "v0.0.72" -DestinationPath "C:\temp"
# Access template content
$specifyContent = $templates['.claude/commands/speckit.specify.md']
```

**Returns:** Hashtable where:
- Keys are relative file paths (with forward slashes)
- Values are file content strings

**Features:**
- Automatically finds the `claude-templates.zip` asset
- Downloads and extracts the ZIP
- Normalizes all paths to use forward slashes
- Cleans up temporary files after extraction
- Returns all files as an in-memory hashtable

### 5. Test-GitHubApiRateLimit
Checks the current GitHub API rate limit status.

**Usage:**
```powershell
$rateLimit = Test-GitHubApiRateLimit
Write-Host "Remaining: $($rateLimit.rate.remaining) / $($rateLimit.rate.limit)"
```

**Returns:** PSCustomObject with rate limit information:
- `rate.limit` - Maximum requests per hour
- `rate.remaining` - Remaining requests
- `rate.reset` - Unix timestamp when limit resets

## Internal Functions

### Invoke-GitHubApiRequest
Internal helper function (not exported) that handles all API requests with proper error handling.

**Features:**
- Sets required headers:
  - `Accept: application/vnd.github+json`
  - `User-Agent: SpecKit-Update-Skill/1.0`
- Comprehensive error handling:
  - **403 (Rate Limit)**: Extracts reset time from `X-RateLimit-Reset` header
  - **404 (Not Found)**: Clear error message
  - **Other HTTP errors**: Generic error with status code
  - **Network errors**: Connection failure messages

## Error Handling

The module provides detailed error messages for common scenarios:

### Rate Limiting (403)
```
GitHub API rate limit exceeded. Resets at: 1/19/2025 3:00:00 PM. Please try again later.
```

### Not Found (404)
```
GitHub resource not found: https://api.github.com/repos/github/spec-kit/releases/tags/v9.9.9
```

### Network Errors
```
Failed to connect to GitHub API: Unable to connect to remote server
```

### Missing Asset
```
Claude templates asset not found in release v0.0.72. Available assets: other-asset.zip
```

## Test Coverage

All 17 unit tests passing with comprehensive coverage:

### Get-LatestSpecKitRelease (4 tests)
- ✅ Returns latest release information from API
- ✅ Throws error when rate limit is exceeded
- ✅ Throws error when API returns 404
- ✅ Throws error when network is unavailable

### Get-SpecKitRelease (3 tests)
- ✅ Returns specific release when version has v prefix
- ✅ Adds v prefix when version does not have it
- ✅ Throws error when release version does not exist

### Get-SpecKitReleaseAssets (2 tests)
- ✅ Returns assets array from specific release
- ✅ Normalizes version before fetching assets

### Download-SpecKitTemplates (4 tests)
- ✅ Downloads and extracts templates into hashtable
- ✅ Throws error when Claude templates asset is not found
- ✅ Cleans up temporary files after download
- ✅ Creates destination directory if it does not exist

### Test-GitHubApiRateLimit (1 test)
- ✅ Returns rate limit status from API

### Module Exports (1 test)
- ✅ Exports only public functions (internal functions not exposed)

### Error Handling (2 tests)
- ✅ Handles rate limit error with reset time
- ✅ Handles generic HTTP errors

## Spec Compliance

All requirements from `specs/001-safe-update/spec.md` have been implemented:

### ✅ Invoke-GitHubApiRequest (Internal)
- Parameters: Uri, Method (default GET)
- Headers: Accept (application/vnd.github+json), User-Agent (SpecKit-Update-Skill/1.0)
- Uses Invoke-RestMethod
- Error handling for 403 (rate limit with X-RateLimit-Reset), 404, and other errors

### ✅ Get-LatestSpecKitRelease
- URI: https://api.github.com/repos/github/spec-kit/releases/latest
- Returns release object

### ✅ Get-SpecKitRelease
- Parameter: Version (string)
- Normalizes version (adds 'v' prefix if missing)
- URI: https://api.github.com/repos/github/spec-kit/releases/tags/$Version
- Returns release object

### ✅ Get-SpecKitReleaseAssets
- Parameter: Version
- Gets release, returns assets array

### ✅ Download-SpecKitTemplates
- Parameters: Version, DestinationPath
- Finds Claude templates asset in release
- Downloads ZIP with Invoke-WebRequest
- Extracts with Expand-Archive
- Reads all files into hashtable (relativePath => content)
- Cleanup temp files
- Returns hashtable

### ✅ Test-GitHubApiRateLimit
- URI: https://api.github.com/rate_limit
- Returns rate limit status

### ✅ Module Exports
- All public functions exported
- Invoke-GitHubApiRequest kept internal

## Testing

Run the tests with Pester:

```powershell
Import-Module Pester -MinimumVersion 5.0
Invoke-Pester -Path 'tests\unit\GitHubApiClient.Tests.ps1' -Output Detailed
```

Expected output:
```
Tests Passed: 17, Failed: 0, Skipped: 0
```

## Dependencies

- PowerShell 7.0+
- Pester 5.x (for testing)
- Internet connection (for API access)

## Integration

This module is designed to be imported by the main update orchestrator:

```powershell
Import-Module "$PSScriptRoot/modules/GitHubApiClient.psm1"

# Example usage in orchestrator
$latestRelease = Get-LatestSpecKitRelease
$currentVersion = $manifest.speckit_version

if ($latestRelease.tag_name -ne $currentVersion) {
    $templates = Download-SpecKitTemplates -Version $latestRelease.tag_name -DestinationPath $tempDir
    # Process templates...
}
```

## Next Steps

This module is complete and ready for integration with:
1. ManifestManager.psm1
2. ConflictDetector.psm1
3. BackupManager.psm1
4. update-orchestrator.ps1

---

**Implementation Date**: 2025-10-19
**Status**: ✅ Complete - All tests passing
**Spec Version**: 1.0
