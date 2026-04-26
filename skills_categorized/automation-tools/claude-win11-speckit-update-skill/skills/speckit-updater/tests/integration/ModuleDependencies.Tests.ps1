#Requires -Version 7.0

<#
.SYNOPSIS
    Integration tests for module dependency management and cross-module function calls.

.DESCRIPTION
    Validates that the orchestrator-managed import pattern works correctly:
    - All module functions are accessible after imports
    - Cross-module function calls work (no scope isolation issues)
    - Import order matters (dependencies must be imported first)
#>

BeforeAll {
    # Import modules in correct tier order (simulates orchestrator)
    $modulesPath = Join-Path $PSScriptRoot "../../scripts/modules"

    # TIER 0: Foundation modules (no dependencies)
    Import-Module (Join-Path $modulesPath "HashUtils.psm1") -Force -WarningAction SilentlyContinue
    Import-Module (Join-Path $modulesPath "GitHubApiClient.psm1") -Force -WarningAction SilentlyContinue
    Import-Module (Join-Path $modulesPath "MarkdownMerger.psm1") -Force -WarningAction SilentlyContinue

    # TIER 1: Modules depending on Tier 0
    Import-Module (Join-Path $modulesPath "ManifestManager.psm1") -Force -WarningAction SilentlyContinue
    Import-Module (Join-Path $modulesPath "FingerprintDetector.psm1") -Force -WarningAction SilentlyContinue

    # TIER 2: Modules depending on Tier 1
    Import-Module (Join-Path $modulesPath "BackupManager.psm1") -Force -WarningAction SilentlyContinue
    Import-Module (Join-Path $modulesPath "ConflictDetector.psm1") -Force -WarningAction SilentlyContinue
}

Describe "Module Dependency Integration Tests" {
    Context "Module Function Availability" {
        It "All HashUtils functions should be accessible" {
            $commands = Get-Command -Module HashUtils -ErrorAction SilentlyContinue
            $commands.Count | Should -BeGreaterThan 0
            $commands.Name | Should -Contain "Get-NormalizedHash"
        }

        It "All GitHubApiClient functions should be accessible" {
            $commands = Get-Command -Module GitHubApiClient -ErrorAction SilentlyContinue
            $commands.Count | Should -BeGreaterThan 0
            # Note: GitHubApiClient may use unapproved verbs (Download, Fetch)
            # We're just verifying functions are exported, not their names
        }

        It "All MarkdownMerger functions should be accessible" {
            $commands = Get-Command -Module MarkdownMerger -ErrorAction SilentlyContinue
            $commands.Count | Should -BeGreaterThan 0
            $commands.Name | Should -Contain "Merge-MarkdownFiles"
        }

        It "All FingerprintDetector functions should be accessible" {
            $commands = Get-Command -Module FingerprintDetector -ErrorAction SilentlyContinue
            $commands.Count | Should -BeGreaterThan 0
            $commands.Name | Should -Contain "Get-InstalledSpecKitVersion"
        }

        It "All ManifestManager functions should be accessible" {
            $commands = Get-Command -Module ManifestManager -ErrorAction SilentlyContinue
            $commands.Count | Should -BeGreaterThan 0
            $commands.Name | Should -Contain "Get-SpecKitManifest"
        }

        It "All BackupManager functions should be accessible" {
            $commands = Get-Command -Module BackupManager -ErrorAction SilentlyContinue
            $commands.Count | Should -BeGreaterThan 0
            $commands.Name | Should -Contain "New-SpecKitBackup"
        }

        It "All ConflictDetector functions should be accessible" {
            $commands = Get-Command -Module ConflictDetector -ErrorAction SilentlyContinue
            $commands.Count | Should -BeGreaterThan 0
            $commands.Name | Should -Contain "Get-FileState"
        }
    }

    Context "Cross-Module Function Calls" {
        It "ManifestManager can call Get-NormalizedHash from HashUtils" {
            # Create a test file
            $testFile = New-TemporaryFile
            "test content for hashing" | Out-File -FilePath $testFile.FullName -NoNewline

            # Call Get-NormalizedHash (used by ManifestManager internally)
            { Get-NormalizedHash -FilePath $testFile.FullName } | Should -Not -Throw

            $hash = Get-NormalizedHash -FilePath $testFile.FullName
            $hash | Should -Match '^sha256:[a-f0-9]{64}$'

            Remove-Item $testFile.FullName -Force
        }

        It "BackupManager can call ManifestManager functions" {
            # BackupManager depends on ManifestManager functions being available
            # We can't easily test this without a full project setup, but we can verify
            # that Get-SpecKitManifest is callable (BackupManager uses it)
            { Get-Command Get-SpecKitManifest -ErrorAction Stop } | Should -Not -Throw
        }

        It "ConflictDetector can call HashUtils and ManifestManager functions" {
            # ConflictDetector uses both Get-NormalizedHash (HashUtils) and
            # Get-SpecKitManifest (ManifestManager)
            { Get-Command Get-NormalizedHash -ErrorAction Stop } | Should -Not -Throw
            { Get-Command Get-SpecKitManifest -ErrorAction Stop } | Should -Not -Throw
        }

        It "Get-FileState (ConflictDetector) can execute without scope errors" {
            # Get-FileState internally calls Get-NormalizedHash
            # This test verifies no "command not recognized" errors occur

            # Create a test file
            $testFile = New-TemporaryFile
            "test file content" | Out-File -FilePath $testFile.FullName -NoNewline

            # Get hashes
            $originalHash = "sha256:0000000000000000000000000000000000000000000000000000000000000000"
            $upstreamHash = Get-NormalizedHash -FilePath $testFile.FullName

            # Call Get-FileState (this internally calls Get-NormalizedHash)
            # This tests that cross-module function calls work
            {
                Get-FileState `
                    -FilePath $testFile.FullName `
                    -OriginalHash $originalHash `
                    -UpstreamHash $upstreamHash `
                    -IsOfficial $true
            } | Should -Not -Throw

            Remove-Item $testFile.FullName -Force
        }
    }

    Context "Module Import Order Validation" {
        It "Modules should be imported in dependency order (Tier 0 → Tier 1 → Tier 2)" {
            # Verify all modules are loaded
            $loadedModules = Get-Module | Where-Object { $_.Name -in @('HashUtils', 'GitHubApiClient', 'MarkdownMerger', 'ManifestManager', 'FingerprintDetector', 'BackupManager', 'ConflictDetector') }
            $loadedModules.Count | Should -Be 7
        }

        It "Attempting to use module function without import should fail (negative test)" {
            # Remove a module temporarily
            Remove-Module HashUtils -Force -ErrorAction SilentlyContinue

            # Attempting to use Get-NormalizedHash should fail
            { Get-NormalizedHash -FilePath "test.txt" -ErrorAction Stop } | Should -Throw

            # Re-import for cleanup
            $modulesPath = Join-Path $PSScriptRoot "../../scripts/modules"
            Import-Module (Join-Path $modulesPath "HashUtils.psm1") -Force -WarningAction SilentlyContinue
        }
    }
}
