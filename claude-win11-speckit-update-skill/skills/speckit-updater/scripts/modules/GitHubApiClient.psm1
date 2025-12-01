#Requires -Version 7.0

<#
.SYNOPSIS
    GitHub API client for SpecKit Safe Update Skill.

.DESCRIPTION
    Provides functions to interact with the GitHub Releases API to fetch
    SpecKit release information and download templates.

    Supports GitHub Personal Access Token authentication via the GITHUB_PAT
    environment variable to increase rate limits from 60 to 5,000 requests/hour.

.NOTES
    Author: SpecKit Safe Update Skill
    Version: 1.1

.ENVIRONMENT VARIABLES
    GITHUB_PAT - Optional GitHub Personal Access Token for authenticated requests.
                 When set, increases API rate limit from 60 to 5,000 requests/hour.
                 No scopes are required for reading public repository releases.
#>

# Internal helper function for making GitHub API requests
function Invoke-GitHubApiRequest {
    <#
    .SYNOPSIS
        Makes authenticated or unauthenticated requests to the GitHub API.

    .DESCRIPTION
        Internal helper function that handles GitHub API requests with optional
        token authentication. Detects GITHUB_PAT environment variable and adds
        Authorization Bearer header when present. Provides enhanced error messages
        with rate limit guidance.

    .PARAMETER Uri
        The GitHub API endpoint URI to request.

    .PARAMETER Method
        The HTTP method to use (GET or HEAD). Defaults to GET.

    .NOTES
        Token Detection: Checks $env:GITHUB_PAT for Personal Access Token.
        Rate Limits: 60 req/hour (unauthenticated) or 5,000 req/hour (authenticated).
        Security: Token value is never logged or included in error messages.

    .EXAMPLE
        # Unauthenticated request (no GITHUB_PAT set)
        $release = Invoke-GitHubApiRequest -Uri 'https://api.github.com/repos/owner/repo/releases/latest'

    .EXAMPLE
        # Authenticated request (GITHUB_PAT environment variable set)
        $env:GITHUB_PAT = "ghp_..."
        $release = Invoke-GitHubApiRequest -Uri 'https://api.github.com/repos/owner/repo/releases/latest' -Verbose
        # Output: VERBOSE: Using authenticated request (rate limit: 5,000 req/hour)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Uri,

        [Parameter()]
        [ValidateSet('GET', 'HEAD')]
        [string]$Method = 'GET'
    )

    try {
        # Build base headers
        $headers = @{
            'Accept' = 'application/vnd.github+json'
            'User-Agent' = 'SpecKit-Update-Skill/1.1'
        }

        # T001: Token detection logic
        # Security Decision: Read token once from environment variable
        # Token value stored in local $token variable for header construction only
        # Never logged, never included in error messages, never written to files
        # Priority: GITHUB_TOKEN (CI) > GITHUB_PAT (local development)
        $token = if ($env:GITHUB_TOKEN) { $env:GITHUB_TOKEN } else { $env:GITHUB_PAT }
        $isAuthenticated = -not [string]::IsNullOrWhiteSpace($token)

        # T002: Add Authorization Bearer header when token present
        # Security Decision: Only use of $token variable - added to Authorization header
        # Header sent over HTTPS (GitHub API only accessible via HTTPS)
        # Token transmitted securely, never exposed in logs or error messages
        if ($isAuthenticated) {
            $headers['Authorization'] = "Bearer $token"
        }

        # T003: Conditional verbose logging for authentication status
        # Security Decision: Log only boolean authentication status, never token value
        # Using $isAuthenticated boolean flag instead of referencing $token
        # Provides visibility for debugging without exposing sensitive data
        if ($isAuthenticated) {
            Write-Verbose "Using authenticated request (rate limit: 5,000 req/hour)"
        }
        else {
            Write-Verbose "Using unauthenticated request (rate limit: 60 req/hour)"
        }

        Write-Verbose "Calling GitHub API: $Method $Uri"
        $response = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $headers -TimeoutSec 30 -ErrorAction Stop
        Write-Verbose "GitHub API request successful"

        return $response
    }
    catch {
        Write-Verbose "GitHub API request failed: $($_.Exception.Message)"

        # Handle specific HTTP status codes
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
            Write-Verbose "HTTP Status Code: $statusCode"

            # T006 & T007: Handle 401 Unauthorized (invalid token)
            if ($statusCode -eq 401) {
                $errorMsg = "GitHub API request failed: 401 Unauthorized"

                # Check if token was used
                if ($isAuthenticated) {
                    $errorMsg += "`n`nYour GITHUB_PAT may be invalid, expired, or revoked."
                    $errorMsg += "`nVerify your token at https://github.com/settings/tokens"
                    $errorMsg += "`nOr remove the token to use unauthenticated requests."
                }

                throw $errorMsg
            }
            # T004, T005, T006, T007: Enhanced rate limit error handling
            elseif ($statusCode -eq 403) {
                # T004: Parse rate limit response headers
                $resetTime = $null
                $remaining = $null

                try {
                    $resetHeader = $_.Exception.Response.Headers | Where-Object { $_.Key -eq 'X-RateLimit-Reset' }
                    $remainingHeader = $_.Exception.Response.Headers | Where-Object { $_.Key -eq 'X-RateLimit-Remaining' }

                    if ($resetHeader) {
                        $resetUnix = $resetHeader.Value[0]
                        # T005: Unix timestamp to local DateTime conversion
                        $resetTime = [DateTimeOffset]::FromUnixTimeSeconds($resetUnix).LocalDateTime
                    }

                    if ($remainingHeader) {
                        $remaining = $remainingHeader.Value[0]
                    }
                }
                catch {
                    # If we can't parse headers, continue without them
                    Write-Verbose "Unable to parse rate limit headers: $($_.Exception.Message)"
                }

                # Check if this is a rate limit error (remaining = 0)
                if ($remaining -eq "0" -or $remaining -eq 0) {
                    # T006: Conditional error message enhancement
                    $errorMsg = "GitHub API rate limit exceeded"

                    if ($resetTime) {
                        $errorMsg += ". Resets at: $resetTime"
                    }
                    else {
                        $errorMsg += ". Please try again later"
                    }

                    # T006: Show token tip only WITHOUT token (conditional guidance)
                    # Security Decision: Context-aware error messages
                    # Only show token setup tip to users who don't have token set
                    # Avoids redundant/confusing guidance for authenticated users
                    if (-not $isAuthenticated) {
                        $errorMsg += "`n`nTip: Set GITHUB_PAT environment variable to increase rate limit from 60 to 5,000 requests/hour."
                        # T007: Add documentation link
                        $errorMsg += "`n     Learn more: https://github.com/NotMyself/claude-win11-speckit-update-skill#using-github-tokens"
                    }

                    throw $errorMsg
                }
                else {
                    # Other 403 errors (not rate limiting)
                    throw "GitHub API access forbidden (HTTP 403). Check repository permissions: $($_.Exception.Message)"
                }
            }
            elseif ($statusCode -eq 404) {
                throw "GitHub resource not found. Verify repository and release exist: $Uri"
            }
            elseif ($statusCode -ge 500) {
                throw "GitHub API server error (HTTP $statusCode). Try again later: $($_.Exception.Message)"
            }
            else {
                throw "GitHub API error (HTTP $statusCode): $($_.Exception.Message)"
            }
        }
        else {
            # Network or other error - no HTTP response received
            throw "Failed to connect to GitHub API. Check network connectivity: $($_.Exception.Message)"
        }
    }
}

<#
.SYNOPSIS
    Gets the latest SpecKit release from GitHub.

.DESCRIPTION
    Fetches the latest release information for the github/spec-kit repository
    from the GitHub Releases API.

.EXAMPLE
    $release = Get-LatestSpecKitRelease
    Write-Host "Latest version: $($release.tag_name)"

.OUTPUTS
    PSCustomObject with release information including tag_name, name, published_at, and assets.
#>
function Get-LatestSpecKitRelease {
    [CmdletBinding()]
    param()

    $uri = 'https://api.github.com/repos/github/spec-kit/releases/latest'

    Write-Verbose "Fetching latest SpecKit release from GitHub API"
    Write-Verbose "API endpoint: $uri"

    try {
        $release = Invoke-GitHubApiRequest -Uri $uri -Method GET

        # Validate response is not null
        if (-not $release) {
            throw "GitHub API returned empty response. Unable to fetch release information."
        }

        Write-Verbose "Response received, validating structure..."

        # Validate required properties exist
        if (-not $release.tag_name) {
            $availableProps = $release.PSObject.Properties.Name -join ', '
            Write-Verbose "Available properties: $availableProps"
            throw "GitHub API returned invalid data. Missing required property: tag_name"
        }

        if (-not $release.assets) {
            throw "GitHub API returned invalid data. Missing required property: assets"
        }

        # Validate tag_name format (semantic version with 'v' prefix)
        if ($release.tag_name -notmatch '^v\d+\.\d+\.\d+') {
            throw "Invalid version format in tag_name: $($release.tag_name). Expected format: v0.0.72"
        }

        Write-Verbose "Release validated successfully: $($release.tag_name)"
        Write-Verbose "Assets count: $($release.assets.Count)"

        return $release
    }
    catch {
        Write-Error "Failed to get latest SpecKit release: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Gets a specific SpecKit release by version tag.

.DESCRIPTION
    Fetches release information for a specific version tag of the github/spec-kit
    repository from the GitHub Releases API. Automatically adds 'v' prefix if not present.

.PARAMETER Version
    The release version tag (e.g., "v0.0.72" or "0.0.72").

.EXAMPLE
    $release = Get-SpecKitRelease -Version "v0.0.72"

.EXAMPLE
    $release = Get-SpecKitRelease -Version "0.0.72"

.OUTPUTS
    PSCustomObject with release information including tag_name, name, published_at, and assets.
#>
function Get-SpecKitRelease {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Version
    )

    # Normalize version - add 'v' prefix if missing
    $normalizedVersion = $Version
    if (-not $normalizedVersion.StartsWith('v')) {
        $normalizedVersion = "v$normalizedVersion"
    }

    $uri = "https://api.github.com/repos/github/spec-kit/releases/tags/$normalizedVersion"

    Write-Verbose "Fetching SpecKit release $normalizedVersion from GitHub API"
    Write-Verbose "API endpoint: $uri"

    try {
        $release = Invoke-GitHubApiRequest -Uri $uri -Method GET

        # Validate response is not null
        if (-not $release) {
            throw "GitHub API returned empty response. Unable to fetch release information."
        }

        Write-Verbose "Response received, validating structure..."

        # Validate required properties exist
        if (-not $release.tag_name) {
            $availableProps = $release.PSObject.Properties.Name -join ', '
            Write-Verbose "Available properties: $availableProps"
            throw "GitHub API returned invalid data. Missing required property: tag_name"
        }

        if (-not $release.assets) {
            throw "GitHub API returned invalid data. Missing required property: assets"
        }

        # Validate tag_name format (semantic version with 'v' prefix)
        if ($release.tag_name -notmatch '^v\d+\.\d+\.\d+') {
            throw "Invalid version format in tag_name: $($release.tag_name). Expected format: v0.0.72"
        }

        Write-Verbose "Release validated successfully: $($release.tag_name)"
        Write-Verbose "Assets count: $($release.assets.Count)"

        return $release
    }
    catch {
        Write-Error "Failed to get SpecKit release ${normalizedVersion}: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
    Gets the assets for a specific SpecKit release.

.DESCRIPTION
    Fetches the release assets (downloadable files) for a specific version
    of the github/spec-kit repository.

.PARAMETER Version
    The release version tag (e.g., "v0.0.72" or "0.0.72").

.EXAMPLE
    $assets = Get-SpecKitReleaseAssets -Version "v0.0.72"
    foreach ($asset in $assets) {
        Write-Host "$($asset.name) - $($asset.size) bytes"
    }

.OUTPUTS
    Array of PSCustomObject with asset information including name, browser_download_url, and size.
#>
function Get-SpecKitReleaseAssets {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Version
    )

    $release = Get-SpecKitRelease -Version $Version

    return $release.assets
}

<#
.SYNOPSIS
    Downloads and extracts SpecKit templates for Claude Code.

.DESCRIPTION
    Downloads the Claude templates asset from a specific SpecKit release,
    extracts the ZIP file, and returns all template files as a hashtable
    of relative path to file content.

.PARAMETER Version
    The release version tag (e.g., "v0.0.72" or "0.0.72").

.PARAMETER DestinationPath
    The temporary directory where the ZIP will be downloaded and extracted.

.EXAMPLE
    $templates = Download-SpecKitTemplates -Version "v0.0.72" -DestinationPath "C:\temp"
    $templates['.claude/commands/speckit.specify.md']

.OUTPUTS
    Hashtable with keys as relative file paths and values as file content strings.
#>
function Download-SpecKitTemplates {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Version,

        [Parameter(Mandatory)]
        [string]$DestinationPath
    )

    # Get release assets
    $assets = Get-SpecKitReleaseAssets -Version $Version

    # Find the Claude templates asset (PowerShell version)
    # Asset naming format: spec-kit-template-claude-ps-vX.Y.Z.zip
    $templateAsset = $assets | Where-Object { $_.name -like "spec-kit-template-claude-ps-*.zip" }

    if (-not $templateAsset) {
        throw "Claude PowerShell templates asset not found in release $Version. Available assets: $($assets.name -join ', ')"
    }

    # Create destination directory if it doesn't exist
    if (-not (Test-Path $DestinationPath)) {
        New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
    }

    # Download the ZIP file
    $zipPath = Join-Path $DestinationPath "claude-templates-$Version.zip"
    $extractPath = Join-Path $DestinationPath "claude-templates-$Version-extracted"

    try {
        Write-Verbose "Downloading templates from: $($templateAsset.browser_download_url)"
        Invoke-WebRequest -Uri $templateAsset.browser_download_url -OutFile $zipPath -ErrorAction Stop

        # Extract the ZIP file
        Write-Verbose "Extracting templates to: $extractPath"
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force -ErrorAction Stop

        # Read all files into a hashtable
        $templates = @{}
        $files = Get-ChildItem -Path $extractPath -Recurse -File

        foreach ($file in $files) {
            # Get relative path from extract directory
            $relativePath = $file.FullName.Substring($extractPath.Length + 1)

            # Normalize path separators to forward slashes
            $relativePath = $relativePath -replace '\\', '/'

            # Read file content
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop

            $templates[$relativePath] = $content
        }

        Write-Verbose "Loaded $($templates.Count) template files"

        return $templates
    }
    finally {
        # Cleanup temporary files
        if (Test-Path $zipPath) {
            Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $extractPath) {
            Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

<#
.SYNOPSIS
    Downloads and extracts a specific file from a SpecKit release.

.DESCRIPTION
    Downloads the Claude templates asset from a specific SpecKit release,
    extracts the specified file only, and returns its content. Optimized
    for 3-way merge operations where only specific files are needed.

.PARAMETER Version
    The release version tag (e.g., "v0.0.72" or "0.0.72").

.PARAMETER FilePath
    The relative file path within the archive (e.g., ".claude/commands/speckit.specify.md").

.PARAMETER DestinationPath
    The temporary directory for intermediate files. Default: system temp directory.

.EXAMPLE
    $content = Get-SpecKitFile -Version "v0.0.72" `
                                -FilePath ".claude/commands/speckit.specify.md"

.EXAMPLE
    # Get file for 3-way merge (base version)
    $baseContent = Get-SpecKitFile -Version "v0.0.71" `
                                    -FilePath ".specify/memory/constitution.md"

.OUTPUTS
    String
    The file content, or $null if file not found in archive.
#>
function Get-SpecKitFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Version,

        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter()]
        [string]$DestinationPath = [System.IO.Path]::GetTempPath()
    )

    # Get release assets
    $assets = Get-SpecKitReleaseAssets -Version $Version

    # Find the Claude templates asset
    $templateAsset = $assets | Where-Object { $_.name -like "spec-kit-template-claude-ps-*.zip" }

    if (-not $templateAsset) {
        throw "Claude PowerShell templates asset not found in release $Version"
    }

    # Create unique temp directory for this operation
    $tempDir = Join-Path $DestinationPath "speckit-$Version-$(New-Guid)"
    $zipPath = Join-Path $tempDir "archive.zip"

    try {
        # Create temp directory
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

        # Download the ZIP file
        Write-Verbose "Downloading archive from: $($templateAsset.browser_download_url)"
        Invoke-WebRequest -Uri $templateAsset.browser_download_url -OutFile $zipPath -ErrorAction Stop

        # Extract only the specific file we need
        Write-Verbose "Extracting file: $FilePath"

        # Expand archive to temp location
        $extractPath = Join-Path $tempDir "extracted"
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force -ErrorAction Stop

        # Normalize file path for Windows
        $normalizedPath = $FilePath -replace '/', '\'

        # Find the extracted file
        $targetFile = Join-Path $extractPath $normalizedPath

        if (-not (Test-Path $targetFile)) {
            Write-Warning "File not found in archive: $FilePath"
            return $null
        }

        # Read and return content
        $content = Get-Content -Path $targetFile -Raw -ErrorAction Stop
        Write-Verbose "Successfully extracted file ($($content.Length) bytes)"

        return $content
    }
    finally {
        # Cleanup
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

<#
.SYNOPSIS
    Tests the GitHub API rate limit status.

.DESCRIPTION
    Queries the GitHub API rate limit endpoint to check the current
    rate limit status and remaining requests.

.EXAMPLE
    $rateLimit = Test-GitHubApiRateLimit
    Write-Host "Remaining: $($rateLimit.rate.remaining) / $($rateLimit.rate.limit)"

.OUTPUTS
    PSCustomObject with rate limit information including rate.limit, rate.remaining, and rate.reset.
#>
function Test-GitHubApiRateLimit {
    [CmdletBinding()]
    param()

    $uri = 'https://api.github.com/rate_limit'

    Write-Verbose "Checking GitHub API rate limit"
    $rateLimit = Invoke-GitHubApiRequest -Uri $uri -Method GET

    return $rateLimit
}

# Export public functions
Export-ModuleMember -Function @(
    'Get-LatestSpecKitRelease',
    'Get-SpecKitRelease',
    'Get-SpecKitReleaseAssets',
    'Download-SpecKitTemplates',
    'Get-SpecKitFile',
    'Test-GitHubApiRateLimit'
)
