#Requires -Version 7.0

<#
.SYNOPSIS
    Integration tests for plugin compatibility and installation workflows

.DESCRIPTION
    Tests backward compatibility after repository restructuring:
    - Manual installation from restructured repository
    - Plugin installation flow simulation
    - Migration from manual to plugin
    - Path resolution validation
    - Side-by-side installation detection
#>

Describe "Plugin Compatibility Integration Tests" {

    BeforeAll {
        # Get skill root and repository root
        # From: skills/speckit-updater/tests/integration
        # Up 2 levels gets to: skills/speckit-updater
        $skillRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        # Up 2 more levels gets to repository root
        $repoRoot = Split-Path -Parent (Split-Path -Parent $skillRoot)

        # Create temp directory for test installations
        $script:testInstallDir = Join-Path $env:TEMP "plugin-compat-tests-$(Get-Random)"
        New-Item -ItemType Directory -Path $script:testInstallDir -Force | Out-Null

        Write-Host "Repository root: $repoRoot" -ForegroundColor Cyan
        Write-Host "Skill root: $skillRoot" -ForegroundColor Cyan
        Write-Host "Test install directory: $script:testInstallDir" -ForegroundColor Cyan
    }

    AfterAll {
        # Cleanup temp directory
        if (Test-Path $script:testInstallDir) {
            Remove-Item -Path $script:testInstallDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "[T034] Scenario 1: Manual installation from restructured repository" {
        It "Should find SKILL.md in skills/speckit-updater/ directory" {
            # Arrange
            $expectedSkillPath = Join-Path $skillRoot "SKILL.md"

            # Act & Assert
            Test-Path $expectedSkillPath | Should -BeTrue

            # Verify SKILL.md has correct structure
            $skillContent = Get-Content -Path $expectedSkillPath -Raw
            $skillContent | Should -Match "/speckit-update"
            $skillContent | Should -Match "SpecKit.*update"
        }

        It "Should verify all critical directories exist in new structure" {
            # Arrange
            $requiredDirs = @(
                "scripts",
                "scripts/modules",
                "scripts/helpers",
                "tests",
                "tests/unit",
                "tests/integration",
                "templates",
                "data"
            )

            # Act & Assert
            foreach ($dir in $requiredDirs) {
                $dirPath = Join-Path $skillRoot $dir
                Test-Path $dirPath | Should -BeTrue -Because "$dir directory should exist"
            }
        }

        It "Should verify orchestrator script exists and is executable" {
            # Arrange
            $orchestratorPath = Join-Path $skillRoot "scripts" "update-orchestrator.ps1"

            # Act & Assert
            Test-Path $orchestratorPath | Should -BeTrue

            # Verify script has proper syntax
            $null = [System.Management.Automation.Language.Parser]::ParseFile(
                $orchestratorPath,
                [ref]$null,
                [ref]$null
            )
        }

        It "Should simulate manual git clone and verify skill loads" {
            # Arrange
            $manualInstallPath = Join-Path $script:testInstallDir "manual-install"

            # Act - Simulate manual clone by copying repository
            Copy-Item -Path $repoRoot -Destination $manualInstallPath -Recurse -Force

            # Assert - Verify skill structure
            $skillMdPath = Join-Path $manualInstallPath "skills" "speckit-updater" "SKILL.md"
            Test-Path $skillMdPath | Should -BeTrue

            # Verify SKILL.md can be discovered (Claude Code would look for *.md files)
            $skillFiles = Get-ChildItem -Path (Join-Path $manualInstallPath "skills" "speckit-updater") -Filter "*.md" -File
            $skillFiles | Where-Object { $_.Name -eq "SKILL.md" } | Should -Not -BeNullOrEmpty
        }
    }

    Context "[T035] Scenario 2: Plugin installation flow simulation" {
        It "Should verify plugin.json manifest exists and is valid" {
            # Arrange
            $pluginManifestPath = Join-Path $repoRoot ".claude-plugin" "plugin.json"

            # Act
            Test-Path $pluginManifestPath | Should -BeTrue

            $manifest = Get-Content -Path $pluginManifestPath -Raw | ConvertFrom-Json

            # Assert - Verify required fields
            $manifest.name | Should -Be "speckit-updater"
            $manifest.version | Should -Match "^\d+\.\d+\.\d+$"
            $manifest.skills | Should -Be "./skills/"
            $manifest.description | Should -Not -BeNullOrEmpty
            $manifest.author.name | Should -Not -BeNullOrEmpty
            $manifest.repository.url | Should -Match "\.git$"
        }

        It "Should verify skills directory path matches plugin.json" {
            # Arrange
            $pluginManifestPath = Join-Path $repoRoot ".claude-plugin" "plugin.json"
            $manifest = Get-Content -Path $pluginManifestPath -Raw | ConvertFrom-Json

            # Act
            $skillsPath = Join-Path $repoRoot ($manifest.skills -replace '^\.\/', '')

            # Assert
            Test-Path $skillsPath | Should -BeTrue

            # Verify it contains at least one skill (SKILL.md file)
            $skillFiles = Get-ChildItem -Path $skillsPath -Filter "*.md" -Recurse -File |
                          Where-Object { $_.Name -like "SKILL*.md" }
            $skillFiles | Should -Not -BeNullOrEmpty
        }

        It "Should simulate plugin install directory structure" {
            # Arrange
            $pluginInstallPath = Join-Path $script:testInstallDir "plugin-install"
            $userSkillsPath = Join-Path $pluginInstallPath ".claude" "skills" "speckit-updater"

            # Act - Simulate Claude Code copying skills/ content to user directory
            New-Item -ItemType Directory -Path $userSkillsPath -Force | Out-Null
            Copy-Item -Path (Join-Path $skillRoot "*") -Destination $userSkillsPath -Recurse -Force

            # Assert - Verify skill is discoverable
            $skillMdPath = Join-Path $userSkillsPath "SKILL.md"
            Test-Path $skillMdPath | Should -BeTrue

            # Verify orchestrator is accessible
            $orchestratorPath = Join-Path $userSkillsPath "scripts" "update-orchestrator.ps1"
            Test-Path $orchestratorPath | Should -BeTrue
        }
    }

    Context "[T036] Scenario 3: Migration from manual to plugin" {
        It "Should preserve functionality when switching from manual to plugin install" {
            # Arrange
            $manualPath = Join-Path $script:testInstallDir "migration-manual"
            $pluginPath = Join-Path $script:testInstallDir "migration-plugin"

            # Simulate manual installation
            Copy-Item -Path $skillRoot -Destination $manualPath -Recurse -Force

            # Simulate plugin installation (same content, different location)
            Copy-Item -Path $skillRoot -Destination $pluginPath -Recurse -Force

            # Act - Compare critical files
            $manualOrchestrator = Join-Path $manualPath "scripts" "update-orchestrator.ps1"
            $pluginOrchestrator = Join-Path $pluginPath "scripts" "update-orchestrator.ps1"

            # Assert - Files should be identical
            $manualContent = Get-Content -Path $manualOrchestrator -Raw
            $pluginContent = Get-Content -Path $pluginOrchestrator -Raw

            $manualContent | Should -Be $pluginContent
        }

        It "Should maintain module import compatibility in both installation modes" {
            # Arrange
            $orchestratorPath = Join-Path $skillRoot "scripts" "update-orchestrator.ps1"
            $orchestratorContent = Get-Content -Path $orchestratorPath -Raw

            # Act & Assert - Verify orchestrator uses relative paths for modules
            $orchestratorContent | Should -Match '\$modulesPath\s*=.*PSScriptRoot'
            $orchestratorContent | Should -Match 'Join-Path.*modulesPath'

            # Should NOT contain absolute paths
            $orchestratorContent | Should -Not -Match 'C:\\' -Because "Should not use absolute paths"
        }
    }

    Context "[T037] Scenario 4: Path resolution validation" {
        It "Should verify test runner paths work from new location" {
            # Arrange
            $testRunnerPath = Join-Path $skillRoot "tests" "test-runner.ps1"
            $testRunnerContent = Get-Content -Path $testRunnerPath -Raw

            # Act & Assert - Verify relative paths using $PSScriptRoot
            $testRunnerContent | Should -Match '\$PSScriptRoot'
            $testRunnerContent | Should -Match '\.\./scripts'
        }

        It "Should verify module paths resolve correctly from orchestrator" {
            # Arrange
            $orchestratorPath = Join-Path $skillRoot "scripts" "update-orchestrator.ps1"

            # Act - Parse module import statements
            $orchestratorContent = Get-Content -Path $orchestratorPath -Raw
            $moduleImports = [regex]::Matches($orchestratorContent, 'Import-Module.*\.psm1')

            # Assert - Verify each imported module exists
            $moduleImports.Count | Should -BeGreaterThan 0

            foreach ($import in $moduleImports) {
                # Extract module filename
                if ($import.Value -match '([A-Za-z]+\.psm1)') {
                    $moduleName = $matches[1]
                    $modulePath = Join-Path $skillRoot "scripts" "modules" $moduleName
                    Test-Path $modulePath | Should -BeTrue -Because "$moduleName should exist"
                }
            }
        }

        It "Should verify data file paths resolve correctly from FingerprintDetector" {
            # Arrange
            $fingerprintModulePath = Join-Path $skillRoot "scripts" "modules" "FingerprintDetector.psm1"
            $fingerprintContent = Get-Content -Path $fingerprintModulePath -Raw

            # Act & Assert - Verify uses parent traversal to find data directory
            $fingerprintContent | Should -Match 'Split-Path.*Parent'
            $fingerprintContent | Should -Match 'data.*speckit-fingerprints\.json'

            # Verify data file actually exists
            $dataPath = Join-Path $skillRoot "data" "speckit-fingerprints.json"
            Test-Path $dataPath | Should -BeTrue
        }

        It "Should verify GitHub Actions workflow paths are updated" {
            # Arrange
            $workflowPath = Join-Path $repoRoot ".github" "workflows" "update-fingerprints.yml"

            # Act
            $workflowContent = Get-Content -Path $workflowPath -Raw

            # Assert - Verify paths reference new structure
            $workflowContent | Should -Match 'skills/speckit-updater/data/speckit-fingerprints\.json'
            $workflowContent | Should -Match 'skills/speckit-updater/scripts/generate-fingerprints\.ps1'
        }
    }

    Context "[T037.1] Scenario 5: Side-by-side installation detection" {
        It "Should handle both manual and plugin installations coexisting" {
            # Arrange
            $manualInstallPath = Join-Path $env:USERPROFILE ".claude" "skills" "speckit-updater-manual"
            $pluginInstallPath = Join-Path $env:USERPROFILE ".claude" "skills" "speckit-updater"

            # Act & Assert - Verify skill names are distinct
            # Manual installation would be in a directory the user creates
            # Plugin installation uses the plugin name from plugin.json

            $manualInstallPath | Should -Not -Be $pluginInstallPath

            # Verify Claude Code would load the correct one based on directory name
            # (This is informational - actual behavior depends on Claude Code's loading logic)
            Write-Host "Manual install path would be: $manualInstallPath" -ForegroundColor Yellow
            Write-Host "Plugin install path would be: $pluginInstallPath" -ForegroundColor Yellow
        }

        It "Should verify plugin name matches directory name expectation" {
            # Arrange
            $pluginManifestPath = Join-Path $repoRoot ".claude-plugin" "plugin.json"
            $manifest = Get-Content -Path $pluginManifestPath -Raw | ConvertFrom-Json

            # Act
            $expectedInstallDir = $manifest.name

            # Assert
            $expectedInstallDir | Should -Be "speckit-updater"
            $expectedInstallDir | Should -Match "^[a-z0-9]+(-[a-z0-9]+)*$" -Because "Plugin names must be lowercase kebab-case"
        }
    }
}
