#Requires -Version 7.0

<#
.SYNOPSIS
    Generates complete fingerprint database for all SpecKit releases.

.DESCRIPTION
    One-time script to generate fingerprints for all SpecKit versions available
    on GitHub. Downloads each release archive, computes normalized hashes for
    tracked files, and builds a comprehensive database.

    Output: data/speckit-fingerprints.json (~120 KB for 77 versions)

.PARAMETER GithubToken
    GitHub Personal Access Token for API authentication.
    Recommended to avoid rate limits (5,000 req/hour vs 60 req/hour).
    Defaults to GITHUB_PAT environment variable.

.PARAMETER MaxVersions
    Maximum number of versions to process (for testing).
    Default: Process all available versions.

.PARAMETER OutputPath
    Path to save the fingerprint database.
    Default: data/speckit-fingerprints.json

.EXAMPLE
    # Generate full database (requires GitHub PAT)
    $env:GITHUB_PAT = "ghp_..."
    .\scripts\generate-fingerprints.ps1

.EXAMPLE
    # Test with first 10 versions only
    .\scripts\generate-fingerprints.ps1 -MaxVersions 10

.NOTES
    Execution time: ~2 minutes with GitHub PAT for all 77 versions
    Without token: Several hours due to rate limiting
#>

param(
    [string]$GithubToken = $(if ($env:GITHUB_TOKEN) { $env:GITHUB_TOKEN } else { $env:GITHUB_PAT }),

    [int]$MaxVersions = 0,  # 0 = all versions

    [string]$OutputPath = (Join-Path $PSScriptRoot "../data/speckit-fingerprints.json")
)

$ErrorActionPreference = 'Stop'

# Import required modules
$modulesPath = Join-Path $PSScriptRoot "modules"
Import-Module (Join-Path $modulesPath "HashUtils.psm1") -Force

# Files to track per version (12 files)
$TrackedFiles = @(
    ".claude/commands/speckit.specify.md"
    ".claude/commands/speckit.plan.md"
    ".claude/commands/speckit.tasks.md"
    ".claude/commands/speckit.implement.md"
    ".claude/commands/speckit.analyze.md"
    ".claude/commands/speckit.clarify.md"
    ".claude/commands/speckit.checklist.md"
    ".claude/commands/speckit.constitution.md"
    ".specify/memory/constitution.md"
    ".specify/templates/spec-template.md"
    ".specify/templates/plan-template.md"
    ".specify/templates/tasks-template.md"
)

# Signature files (3 core files for fast detection)
$SignatureFiles = @(
    ".claude/commands/speckit.specify.md"
    ".claude/commands/speckit.plan.md"
    ".specify/memory/constitution.md"
)

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  SpecKit Fingerprint Database Generator                       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Validate GitHub token
if (-not $GithubToken) {
    Write-Warning "No GitHub token provided. Using unauthenticated requests."
    Write-Warning "This will be VERY SLOW due to rate limits (60 req/hour)."
    Write-Warning "Set GITHUB_PAT environment variable or use -GithubToken parameter."
    Write-Host ""

    $response = Read-Host "Continue anyway? (y/N)"
    if ($response -ne 'y') {
        Write-Host "Aborted. Please set GitHub PAT and try again." -ForegroundColor Yellow
        exit 0
    }
}

# Setup API headers
$headers = @{
    'Accept' = 'application/vnd.github+json'
    'User-Agent' = 'SpecKit-Updater-FingerprintGenerator/1.0'
}

if ($GithubToken) {
    $headers['Authorization'] = "Bearer $GithubToken"
    Write-Host "✓ Using authenticated requests (5,000 req/hour limit)" -ForegroundColor Green
} else {
    Write-Host "⚠ Using unauthenticated requests (60 req/hour limit)" -ForegroundColor Yellow
}
Write-Host ""

# Fetch all SpecKit releases
Write-Host "📥 Fetching SpecKit releases from GitHub..." -ForegroundColor Cyan

$allReleases = @()
$page = 1
$perPage = 100

try {
    do {
        Write-Verbose "Fetching page $page..."
        $url = "https://api.github.com/repos/github/spec-kit/releases?per_page=$perPage&page=$page"

        $releases = Invoke-RestMethod -Uri $url -Headers $headers -ErrorAction Stop
        $allReleases += $releases

        Write-Verbose "  Retrieved $($releases.Count) releases from page $page"

        $page++
    } while ($releases.Count -eq $perPage)

    Write-Host "✓ Found $($allReleases.Count) SpecKit releases" -ForegroundColor Green
    Write-Host ""

} catch {
    Write-Error "Failed to fetch releases from GitHub: $_"
    Write-Host ""
    Write-Host "Possible causes:" -ForegroundColor Yellow
    Write-Host "  - Network connection issue" -ForegroundColor Yellow
    Write-Host "  - GitHub API rate limit exceeded" -ForegroundColor Yellow
    Write-Host "  - Invalid GitHub token" -ForegroundColor Yellow
    exit 1
}

# Limit versions if testing
if ($MaxVersions -gt 0 -and $allReleases.Count -gt $MaxVersions) {
    Write-Host "⚠ Limiting to first $MaxVersions versions (testing mode)" -ForegroundColor Yellow
    $allReleases = $allReleases | Select-Object -First $MaxVersions
    Write-Host ""
}

# Initialize database
$database = [ordered]@{
    schema_version = "1.0"
    generated_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    generator_version = "1.0.0"
    last_updated = $null  # Will be set at the end
    total_versions = $allReleases.Count
    latest_version = $allReleases[0].tag_name
    tracked_files = $TrackedFiles
    signature_files = $SignatureFiles
    versions = [ordered]@{}
}

# Process each release
$processed = 0
$failed = 0
$tempBase = Join-Path $env:TEMP "speckit-fingerprints"

# Create temp directory
if (Test-Path $tempBase) {
    Remove-Item $tempBase -Recurse -Force
}
New-Item -ItemType Directory -Path $tempBase -Force | Out-Null

Write-Host "🔨 Processing $($allReleases.Count) releases..." -ForegroundColor Cyan
Write-Host ""

foreach ($release in $allReleases) {
    $version = $release.tag_name
    $processed++

    Write-Host "[$processed/$($allReleases.Count)] Processing $version..." -NoNewline

    try {
        # Create temp directory for this version
        $tempDir = Join-Path $tempBase $version
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

        # Download archive
        $archiveUrl = "https://github.com/github/spec-kit/releases/download/$version/spec-kit-template-claude-ps-$version.zip"
        $archivePath = Join-Path $tempDir "archive.zip"

        Invoke-WebRequest -Uri $archiveUrl -OutFile $archivePath -Headers $headers -ErrorAction Stop | Out-Null

        # Extract archive
        Expand-Archive -Path $archivePath -DestinationPath $tempDir -Force -ErrorAction Stop

        # Compute fingerprints for tracked files
        $fingerprints = [ordered]@{}
        $foundFiles = 0

        foreach ($file in $TrackedFiles) {
            $fullPath = Join-Path $tempDir $file

            if (Test-Path $fullPath) {
                $hash = Get-NormalizedHash -FilePath $fullPath
                $fingerprints[$file] = $hash
                $foundFiles++
            } else {
                Write-Verbose "  File not found: $file (may not exist in this version)"
            }
        }

        # Add version to database
        $database.versions[$version] = [ordered]@{
            release_date = $release.published_at
            release_url = $release.html_url
            files_tracked = $foundFiles
            fingerprints = $fingerprints
        }

        # Cleanup this version's temp files
        Remove-Item $tempDir -Recurse -Force

        Write-Host " ✓ ($foundFiles files)" -ForegroundColor Green

    } catch {
        $failed++
        Write-Host " ✗ FAILED: $_" -ForegroundColor Red

        # Log error but continue
        Write-Verbose "Error details: $($_.Exception.Message)"

        # Add failed entry to database for debugging
        $database.versions[$version] = [ordered]@{
            release_date = $release.published_at
            release_url = $release.html_url
            error = $_.Exception.Message
            files_tracked = 0
            fingerprints = @{}
        }
    }
}

# Cleanup temp directory
if (Test-Path $tempBase) {
    Remove-Item $tempBase -Recurse -Force
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

# Update metadata
$database.last_updated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")

# Save database
Write-Host "💾 Saving fingerprint database..." -ForegroundColor Cyan

# Ensure output directory exists
$outputDir = Split-Path $OutputPath -Parent
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Convert to JSON and save
$json = $database | ConvertTo-Json -Depth 10
$json | Set-Content -Path $OutputPath -Encoding UTF8 -Force

$fileSize = (Get-Item $OutputPath).Length
$fileSizeKB = [math]::Round($fileSize / 1KB, 1)

Write-Host ""
Write-Host "✅ Fingerprint database generated successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "  Output File:      $OutputPath" -ForegroundColor Cyan
Write-Host "  File Size:        $fileSizeKB KB" -ForegroundColor Cyan
Write-Host "  Total Versions:   $($database.total_versions)" -ForegroundColor Cyan
Write-Host "  Processed:        $processed" -ForegroundColor Cyan
Write-Host "  Failed:           $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Yellow" })
Write-Host "  Latest Version:   $($database.latest_version)" -ForegroundColor Cyan
Write-Host "  Tracked Files:    $($TrackedFiles.Count) per version" -ForegroundColor Cyan
Write-Host "  Signature Files:  $($SignatureFiles.Count)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""

if ($failed -gt 0) {
    Write-Warning "$failed version(s) failed to process. Check verbose output for details."
    Write-Host ""
}

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review the generated database: $OutputPath" -ForegroundColor White
Write-Host "  2. Commit to repository: git add $OutputPath" -ForegroundColor White
Write-Host "  3. Commit: git commit -m 'chore: Add fingerprint database (77 versions)'" -ForegroundColor White
Write-Host ""

# Exit with success
exit 0
