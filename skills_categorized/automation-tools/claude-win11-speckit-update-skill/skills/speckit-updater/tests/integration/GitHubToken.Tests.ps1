#Requires -Version 7.0
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

<#
.SYNOPSIS
    Integration tests for GitHub Personal Access Token authentication.

.DESCRIPTION
    Tests real GitHub API integration with token authentication using the
    GitHubApiClient module. These tests make actual API calls to GitHub.

    IMPORTANT: These tests require GITHUB_TEST_TOKEN environment variable.
    Tests are skipped if token is not set (safe for CI/CD without token).

.NOTES
    Test Type: Integration (makes real API calls)
    Feature: 012-github-token-support
    Phase: 3
    Tasks: T021-T024
#>

BeforeAll {
    # Import module under test
    $modulePath = Join-Path $PSScriptRoot "..\..\scripts\modules\GitHubApiClient.psm1"
    Import-Module $modulePath -Force

    # Check if integration test token is available
    $script:hasTestToken = -not [string]::IsNullOrWhiteSpace($env:GITHUB_TEST_TOKEN)

    if ($script:hasTestToken) {
        Write-Host "✓ Integration tests will run (GITHUB_TEST_TOKEN is set)" -ForegroundColor Green
    }
    else {
        Write-Host "⚠ Integration tests will be skipped (GITHUB_TEST_TOKEN not set)" -ForegroundColor Yellow
        Write-Host "  To enable: Set `$env:GITHUB_TEST_TOKEN to a valid GitHub Personal Access Token" -ForegroundColor Yellow
    }
}

Describe 'GitHubToken Integration Tests' {
    Context '[T022] Authenticated request to real GitHub API succeeds' {
        It 'Makes authenticated request to GitHub API when GITHUB_TEST_TOKEN is set' -Skip:(-not $script:hasTestToken) {
            # Backup current GITHUB_PAT
            $originalToken = $env:GITHUB_PAT

            try {
                # Set test token for this request
                $env:GITHUB_PAT = $env:GITHUB_TEST_TOKEN

                # Make real API call
                $release = Get-LatestSpecKitRelease -Verbose

                # Validate response structure
                $release | Should -Not -BeNullOrEmpty
                $release.tag_name | Should -Match '^v\d+\.\d+\.\d+$'
                $release.assets | Should -Not -BeNullOrEmpty
            }
            finally {
                # Restore original token
                $env:GITHUB_PAT = $originalToken
            }
        }

        It 'Verbose output confirms authenticated request' -Skip:(-not $script:hasTestToken) {
            $originalToken = $env:GITHUB_PAT

            try {
                $env:GITHUB_PAT = $env:GITHUB_TEST_TOKEN

                # Capture verbose output
                $verboseOutput = Get-LatestSpecKitRelease -Verbose 4>&1 | Out-String

                # Verify authentication status logged
                $verboseOutput | Should -BeLike '*Using authenticated request*'
                $verboseOutput | Should -BeLike '*5,000 req/hour*'
            }
            finally {
                $env:GITHUB_PAT = $originalToken
            }
        }
    }

    Context '[T023] Rate limit comparison (authenticated vs unauthenticated)' {
        It 'Authenticated request returns higher rate limit than unauthenticated' -Skip:(-not $script:hasTestToken) {
            $originalToken = $env:GITHUB_PAT

            try {
                # Test unauthenticated request first
                $env:GITHUB_PAT = $null
                $unauthRateLimit = Test-GitHubApiRateLimit
                $unauthLimit = [int]$unauthRateLimit.rate.limit

                # Test authenticated request
                $env:GITHUB_PAT = $env:GITHUB_TEST_TOKEN
                $authRateLimit = Test-GitHubApiRateLimit
                $authLimit = [int]$authRateLimit.rate.limit

                # Verify authenticated limit is higher
                $authLimit | Should -BeGreaterThan $unauthLimit
                $authLimit | Should -Be 5000
                $unauthLimit | Should -Be 60
            }
            finally {
                $env:GITHUB_PAT = $originalToken
            }
        }

        It 'Unauthenticated request returns 60 requests/hour limit' -Skip:(-not $script:hasTestToken) {
            $originalToken = $env:GITHUB_PAT

            try {
                $env:GITHUB_PAT = $null

                $rateLimit = Test-GitHubApiRateLimit
                $limit = [int]$rateLimit.rate.limit

                $limit | Should -Be 60
            }
            finally {
                $env:GITHUB_PAT = $originalToken
            }
        }

        It 'Authenticated request returns 5000 requests/hour limit' -Skip:(-not $script:hasTestToken) {
            $originalToken = $env:GITHUB_PAT

            try {
                $env:GITHUB_PAT = $env:GITHUB_TEST_TOKEN

                $rateLimit = Test-GitHubApiRateLimit
                $limit = [int]$rateLimit.rate.limit

                $limit | Should -Be 5000
            }
            finally {
                $env:GITHUB_PAT = $originalToken
            }
        }
    }

    Context '[T024] Token value never exposed in any output stream' {
        It 'Token does not appear in standard output' -Skip:(-not $script:hasTestToken) {
            $originalToken = $env:GITHUB_PAT

            try {
                $env:GITHUB_PAT = $env:GITHUB_TEST_TOKEN

                # Capture standard output
                $stdout = Get-LatestSpecKitRelease | Out-String

                # Verify token not present
                $stdout | Should -Not -BeLike "*$env:GITHUB_TEST_TOKEN*"
            }
            finally {
                $env:GITHUB_PAT = $originalToken
            }
        }

        It 'Token does not appear in verbose output' -Skip:(-not $script:hasTestToken) {
            $originalToken = $env:GITHUB_PAT

            try {
                $env:GITHUB_PAT = $env:GITHUB_TEST_TOKEN

                # Capture verbose stream
                $verbose = Get-LatestSpecKitRelease -Verbose 4>&1 | Out-String

                # Verify token not present
                $verbose | Should -Not -BeLike "*$env:GITHUB_TEST_TOKEN*"
            }
            finally {
                $env:GITHUB_PAT = $originalToken
            }
        }

        It 'Token does not appear in error output when API call fails' -Skip:(-not $script:hasTestToken) {
            $originalToken = $env:GITHUB_PAT

            try {
                $env:GITHUB_PAT = $env:GITHUB_TEST_TOKEN

                # Force error by requesting non-existent version
                try {
                    Get-SpecKitRelease -Version "v999.999.999" -ErrorAction Stop
                }
                catch {
                    # Capture error message
                    $errorMsg = $_.Exception.Message

                    # Verify token not present in error
                    $errorMsg | Should -Not -BeLike "*$env:GITHUB_TEST_TOKEN*"
                }
            }
            finally {
                $env:GITHUB_PAT = $originalToken
            }
        }

        It 'Token does not appear in warning output' -Skip:(-not $script:hasTestToken) {
            $originalToken = $env:GITHUB_PAT

            try {
                $env:GITHUB_PAT = $env:GITHUB_TEST_TOKEN

                # Capture all streams including warnings
                $allOutput = Get-LatestSpecKitRelease -Verbose -WarningAction Continue 3>&1 4>&1 | Out-String

                # Verify token not present
                $allOutput | Should -Not -BeLike "*$env:GITHUB_TEST_TOKEN*"
            }
            finally {
                $env:GITHUB_PAT = $originalToken
            }
        }
    }
}
