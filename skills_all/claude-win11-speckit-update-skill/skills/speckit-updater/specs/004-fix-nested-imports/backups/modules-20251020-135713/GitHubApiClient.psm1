#Requires -Version 7.0

<#
.SYNOPSIS
    GitHub API client for SpecKit Safe Update Skill.

.DESCRIPTION
    Provides functions to interact with the GitHub Releases API to fetch
    SpecKit release information and download templates.

.NOTES
    Author: SpecKit Safe Update Skill
    Version: 1.0
#>

# Internal helper function for making GitHub API requests
function Invoke-GitHubApiRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Uri,

        [Parameter()]
        [ValidateSet('GET', 'HEAD')]
        [string]$Method = 'GET'
    )

    try {
        $headers = @{
            'Accept' = 'application/vnd.github+json'
            'User-Agent' = 'SpecKit-Update-Skill/1.0'
        }

        $response = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $headers -ErrorAction Stop

        return $response
    }
    catch {
        # Handle specific HTTP status codes
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode

            if ($statusCode -eq 403) {
                # Rate limit exceeded
                $resetTime = $null
                try {
                    $resetHeader = $_.Exception.Response.Headers | Where-Object { $_.Key -eq 'X-RateLimit-Reset' }
                    if ($resetHeader) {
                        $resetUnix = $resetHeader.Value[0]
                        $resetTime = [DateTimeOffset]::FromUnixTimeSeconds($resetUnix).LocalDateTime
                    }
                }
                catch {
                    # If we can't parse the reset time, just continue without it
                }

                if ($resetTime) {
                    throw "GitHub API rate limit exceeded. Resets at: $resetTime. Please try again later."
                }
                else {
                    throw "GitHub API rate limit exceeded. Please try again later."
                }
            }
            elseif ($statusCode -eq 404) {
                throw "GitHub resource not found: $Uri"
            }
            else {
                throw "GitHub API error (HTTP $statusCode): $($_.Exception.Message)"
            }
        }
        else {
            # Network or other error
            throw "Failed to connect to GitHub API: $($_.Exception.Message)"
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
    $release = Invoke-GitHubApiRequest -Uri $uri -Method GET

    return $release
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
    $release = Invoke-GitHubApiRequest -Uri $uri -Method GET

    return $release
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

    # Find the Claude templates asset
    $templateAsset = $assets | Where-Object { $_.name -eq 'claude-templates.zip' }

    if (-not $templateAsset) {
        throw "Claude templates asset not found in release $Version. Available assets: $($assets.name -join ', ')"
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
    'Test-GitHubApiRateLimit'
)
