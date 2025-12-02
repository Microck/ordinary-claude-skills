# Implementation Plan: SpecKit Safe Update Skill

**Specification:** `001-safe-update.md`
**Timeline:** 1-2 weeks (AI-assisted development)
**Status:** Ready for Implementation

## Executive Summary

This plan breaks down the implementation into 7 sequential phases with clear dependencies, validation checkpoints, and success criteria. The critical requirement is that **Phase 6 must produce a fully installable GitHub repository before Phase 7 (manual testing) begins**.

## Implementation Phases Overview

```
Phase 0: Repository Setup (Day 1)
    ↓
Phase 1: Core Utilities (Day 1-2)
    ├── HashUtils.psm1 ⚡ (parallel)
    ├── VSCodeIntegration.psm1 ⚡ (parallel)
    └── GitHubApiClient.psm1 ⚡ (parallel)
    ↓
Phase 2: Data Management (Day 2-3)
    ├── ManifestManager.psm1 (depends on Phase 1)
    └── BackupManager.psm1 (depends on ManifestManager)
    ↓
Phase 3: Business Logic (Day 4-5)
    └── ConflictDetector.psm1 (depends on Phase 1 & 2)
    ↓
Phase 4: Orchestration (Day 6-7)
    ├── update-orchestrator.ps1 (depends on all modules)
    └── Helper functions (depends on orchestrator)
    ↓
Phase 5: Testing (Day 8-9)
    ├── Unit tests (parallel with implementation)
    ├── Integration tests (after Phase 4)
    └── Test fixtures and mocks
    ↓
Phase 6: Distribution (Day 10)
    ├── Complete documentation
    ├── Final repository structure
    └── GitHub release preparation
    ↓
Phase 7: Manual Testing (Day 11+)
    └── Begins ONLY after GitHub installation works

⚡ = Can be implemented in parallel
```

## Critical Path Analysis

**Blocking Dependencies:**
1. **Phase 0 blocks everything** - Need repository structure first
2. **Phase 1 blocks Phase 2** - Data management needs utilities
3. **Phase 2 blocks Phase 3** - Conflict detection needs manifest system
4. **Phase 3 blocks Phase 4** - Orchestrator needs all business logic
5. **Phase 4 blocks Phase 5** - Integration tests need complete orchestrator
6. **Phase 5 blocks Phase 6** - Can't document/release untested code
7. **Phase 6 blocks Phase 7** - Manual testing requires GitHub installation

**Longest Path (Critical Path):** Phase 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7

**Opportunities for Parallelization:**
- Phase 1: All three modules can be built simultaneously
- Unit tests can be written alongside each module
- Documentation drafts can be started during implementation

## Phase 0: Repository & Infrastructure Setup

**Timeline:** Day 1 (2-4 hours)
**Status:** Must complete before any coding

### Tasks

#### 0.1: Create GitHub Repository
- [ ] Create new repository: `claude-speckit-safe-update`
- [ ] Initialize with README.md (basic structure)
- [ ] Add MIT License
- [ ] Set repository visibility (public recommended)
- [ ] Configure repository settings (issues, discussions, wiki)

#### 0.2: Create Directory Structure
```powershell
# Create all directories
New-Item -ItemType Directory -Path @(
    'scripts/modules',
    'scripts/helpers',
    'templates',
    'tests/unit',
    'tests/integration',
    'tests/fixtures/sample-project-with-manifest/.specify/memory',
    'tests/fixtures/sample-project-with-manifest/.claude/commands',
    'tests/fixtures/sample-project-without-manifest/.specify',
    'tests/fixtures/sample-project-with-customizations/.claude/commands',
    'tests/fixtures/mock-github-responses',
    'docs'
) -Force
```

#### 0.3: Create Base Files
- [ ] `.gitignore` - Exclude `.tmp-merge/`, test outputs, logs
  ```gitignore
  # PowerShell
  *.log
  *.tmp

  # Test outputs
  tests/TestResults/
  coverage/

  # SpecKit internals
  .specify/.tmp-merge/
  .specify/backups/

  # OS
  .DS_Store
  Thumbs.db
  ```

- [ ] `LICENSE` - MIT License text

- [ ] `README.md` - Basic structure (will complete in Phase 6)
  ```markdown
  # SpecKit Safe Update - Claude Code Skill

  🚧 **Status: Under Development**

  Safe updates for GitHub SpecKit installations, preserving your customizations.

  ## Coming Soon
  - Full installation instructions
  - Usage documentation
  - Features overview
  ```

- [ ] `SKILL.md` - Skeleton (will complete in Phase 6)
  ```markdown
  # SpecKit Safe Update

  🚧 **Status: Under Development**

  This skill provides safe update capabilities for GitHub SpecKit installations.
  ```

#### 0.4: Set Up Testing Framework
- [ ] Install Pester if not already available:
  ```powershell
  Install-Module -Name Pester -Force -SkipPublisherCheck
  ```

- [ ] Create `tests/test-runner.ps1`:
  ```powershell
  $config = New-PesterConfiguration
  $config.Run.Path = "$PSScriptRoot"
  $config.Output.Verbosity = 'Detailed'
  $config.CodeCoverage.Enabled = $true
  Invoke-Pester -Configuration $config
  ```

- [ ] Create `.github/workflows/test.yml` for CI:
  ```yaml
  name: Test
  on: [push, pull_request]
  jobs:
    test:
      runs-on: windows-latest
      steps:
        - uses: actions/checkout@v3
        - name: Run Pester Tests
          shell: pwsh
          run: |
            Install-Module Pester -Force -SkipPublisherCheck
            ./tests/test-runner.ps1
  ```

#### 0.5: Create Test Fixtures
- [ ] `tests/fixtures/sample-project-with-manifest/.specify/manifest.json`:
  ```json
  {
    "version": "1.0",
    "speckit_version": "v0.0.45",
    "initialized_at": "2025-01-01T10:00:00Z",
    "last_updated": "2025-01-01T10:00:00Z",
    "agent": "claude-code",
    "speckit_commands": [
      "speckit.constitution.md",
      "speckit.specify.md",
      "speckit.plan.md",
      "speckit.tasks.md",
      "speckit.implement.md"
    ],
    "tracked_files": [
      {
        "path": ".claude/commands/speckit.specify.md",
        "original_hash": "sha256:ABC123",
        "customized": false,
        "is_official": true
      }
    ],
    "custom_files": [],
    "backup_history": []
  }
  ```

- [ ] Create sample command files in fixture directories
- [ ] Create sample template files in fixture directories

- [ ] `tests/fixtures/mock-github-responses/latest-release.json`:
  ```json
  {
    "tag_name": "v0.0.72",
    "name": "Release v0.0.72",
    "published_at": "2025-01-15T10:30:00Z",
    "assets": [
      {
        "name": "claude-templates.zip",
        "browser_download_url": "https://example.com/templates.zip",
        "size": 245678
      }
    ]
  }
  ```

### Validation Checkpoint 0
- [ ] Repository exists on GitHub
- [ ] All directories created
- [ ] Base files in place
- [ ] Pester runs successfully (no tests yet, should pass with 0 tests)
- [ ] Test fixtures loadable
- [ ] Can commit and push to GitHub

**Exit Criteria:** Repository structure complete, ready for code implementation.

---

## Phase 1: Core Utilities (No Dependencies)

**Timeline:** Day 1-2 (8-12 hours)
**Parallelization:** All three modules can be built simultaneously

### Module 1.1: HashUtils.psm1

**File:** `scripts/modules/HashUtils.psm1`

**Purpose:** Provide normalized hashing for cross-platform file comparison.

#### Implementation Tasks

**1.1.1: Create Module Structure**
```powershell
# HashUtils.psm1

function Get-NormalizedHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )
    # Implementation here
}

function Compare-FileHashes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Hash1,
        [Parameter(Mandatory)]
        [string]$Hash2
    )
    return $Hash1 -eq $Hash2
}

Export-ModuleMember -Function @('Get-NormalizedHash', 'Compare-FileHashes')
```

**1.1.2: Implement Normalization Algorithm**

Key steps:
1. Read file content as UTF-8 string
2. Normalize line endings (CRLF → LF)
3. Trim trailing whitespace from each line
4. Remove BOM if present
5. Compute SHA-256 hash
6. Return as "sha256:HEXSTRING" format

**Critical Implementation Details:**
```powershell
# Handle BOM removal
if ($normalized.Length -gt 0 -and $normalized[0] -eq [char]0xFEFF) {
    $normalized = $normalized.Substring(1)
}

# Normalize line endings
$normalized = $normalized -replace "`r`n", "`n"

# Trim trailing whitespace per line
$lines = $normalized -split "`n"
$trimmedLines = $lines | ForEach-Object { $_.TrimEnd() }
$normalized = $trimmedLines -join "`n"

# Compute hash
$bytes = [System.Text.Encoding]::UTF8.GetBytes($normalized)
$sha256 = [System.Security.Cryptography.SHA256]::Create()
$hashBytes = $sha256.ComputeHash($bytes)
$hashString = [System.BitConverter]::ToString($hashBytes) -replace '-', ''
```

**1.1.3: Add Error Handling**
- File not found → throw with clear message
- File locked → throw with suggestion to close file
- Binary files → skip normalization, hash raw bytes
- Permission denied → throw with permission guidance

**1.1.4: Write Unit Tests**

File: `tests/unit/HashUtils.Tests.ps1`

Test cases:
- [ ] Same content with CRLF vs LF produces same hash
- [ ] Same content with trailing whitespace vs without produces same hash
- [ ] Different content produces different hashes
- [ ] BOM vs no BOM produces same hash (for same content)
- [ ] Empty file has consistent hash
- [ ] Large file (>1MB) hashes correctly
- [ ] Non-existent file throws appropriate error
- [ ] Locked file throws appropriate error

**1.1.5: Validate Module**
```powershell
# Manual test
Import-Module ./scripts/modules/HashUtils.psm1 -Force
$hash1 = Get-NormalizedHash -FilePath "test1.txt"
$hash2 = Get-NormalizedHash -FilePath "test2.txt"
Compare-FileHashes -Hash1 $hash1 -Hash2 $hash2
```

### Module 1.2: VSCodeIntegration.psm1

**File:** `scripts/modules/VSCodeIntegration.psm1`

**Purpose:** Detect execution context and integrate with VSCode CLI.

#### Implementation Tasks

**1.2.1: Create Module Structure**
```powershell
function Get-ExecutionContext {
    # Returns: 'vscode-extension' | 'vscode-terminal' | 'standalone-terminal'
}

function Show-QuickPick {
    param([string]$Prompt, [string[]]$Options, [switch]$MultiSelect)
    # VSCode: delegate to Claude Code (return sentinel for orchestrator to handle)
    # Terminal: fallback to numbered menu
}

function Open-DiffView {
    param([string]$LeftPath, [string]$RightPath, [string]$Title)
    # Execute: code --diff
}

function Open-MergeEditor {
    param([string]$BasePath, [string]$CurrentPath, [string]$IncomingPath, [string]$ResultPath)
    # Execute: code --merge --wait
}

function Show-Notification {
    param([string]$Message, [string]$Level)
    # VSCode: could use extension API (future)
    # Terminal: Write-Host with color
}

Export-ModuleMember -Function @(
    'Get-ExecutionContext',
    'Show-QuickPick',
    'Open-DiffView',
    'Open-MergeEditor',
    'Show-Notification'
)
```

**1.2.2: Implement Context Detection**
```powershell
function Get-ExecutionContext {
    if ($env:VSCODE_PID) {
        if ($env:TERM_PROGRAM -eq 'vscode') {
            return 'vscode-terminal'
        }
        else {
            return 'vscode-extension'
        }
    }
    else {
        return 'standalone-terminal'
    }
}
```

**1.2.3: Implement Quick Pick with Fallback**
```powershell
function Show-QuickPick {
    param(
        [string]$Prompt,
        [string[]]$Options,
        [switch]$MultiSelect
    )

    $context = Get-ExecutionContext

    if ($context -eq 'vscode-extension') {
        # Signal to Claude Code to handle this via Quick Pick
        # Return sentinel value that orchestrator recognizes
        return @{
            NeedsClaudeOrchestration = $true
            Prompt = $Prompt
            Options = $Options
            MultiSelect = $MultiSelect.IsPresent
        }
    }
    else {
        # Terminal fallback: numbered menu
        Write-Host $Prompt
        for ($i = 0; $i -lt $Options.Count; $i++) {
            Write-Host "  $($i + 1). $($Options[$i])"
        }

        if ($MultiSelect) {
            Write-Host "Enter numbers separated by commas (e.g., 1,3): " -NoNewline
            $input = Read-Host
            $selections = $input -split ',' | ForEach-Object { [int]$_.Trim() - 1 }
            return $selections | ForEach-Object { $Options[$_] }
        }
        else {
            Write-Host "Enter number: " -NoNewline
            $input = Read-Host
            return $Options[[int]$input - 1]
        }
    }
}
```

**1.2.4: Implement VSCode CLI Integration**
```powershell
function Open-DiffView {
    param(
        [string]$LeftPath,
        [string]$RightPath,
        [string]$Title = "Diff"
    )

    # Check if code CLI is available
    $codeCommand = Get-Command code -ErrorAction SilentlyContinue
    if (-not $codeCommand) {
        throw "VSCode 'code' CLI not found in PATH. Install VSCode and ensure 'code' command is available."
    }

    # Resolve to absolute paths
    $leftAbs = Resolve-Path $LeftPath -ErrorAction Stop
    $rightAbs = Resolve-Path $RightPath -ErrorAction Stop

    # Execute diff
    & code --diff "$leftAbs" "$rightAbs"
}

function Open-MergeEditor {
    param(
        [string]$BasePath,
        [string]$CurrentPath,
        [string]$IncomingPath,
        [string]$ResultPath
    )

    $codeCommand = Get-Command code -ErrorAction SilentlyContinue
    if (-not $codeCommand) {
        throw "VSCode 'code' CLI not found in PATH."
    }

    # Resolve paths
    $baseAbs = Resolve-Path $BasePath
    $currentAbs = Resolve-Path $CurrentPath
    $incomingAbs = Resolve-Path $IncomingPath
    $resultAbs = $ResultPath # May not exist yet

    # Execute merge with --wait flag (blocks until editor closes)
    & code --merge "$baseAbs" "$currentAbs" "$incomingAbs" "$resultAbs" --wait

    # Check if result file was saved
    if (Test-Path $resultAbs) {
        return $true
    }
    else {
        return $false
    }
}
```

**1.2.5: Write Unit Tests**

File: `tests/unit/VSCodeIntegration.Tests.ps1`

Test cases:
- [ ] Get-ExecutionContext returns correct value based on environment variables
- [ ] Show-QuickPick returns sentinel in VSCode context
- [ ] Show-QuickPick falls back to terminal menu in standalone
- [ ] Open-DiffView throws if code CLI not available
- [ ] Open-MergeEditor throws if code CLI not available
- [ ] (Mock `code` command for tests)

### Module 1.3: GitHubApiClient.psm1

**File:** `scripts/modules/GitHubApiClient.psm1`

**Purpose:** Interact with GitHub Releases API.

#### Implementation Tasks

**1.3.1: Create Module Structure**
```powershell
function Get-LatestSpecKitRelease { }
function Get-SpecKitRelease { param([string]$Version) }
function Get-SpecKitReleaseAssets { param([string]$Version) }
function Download-SpecKitTemplates { param([string]$Version, [string]$DestinationPath) }
function Test-GitHubApiRateLimit { }

Export-ModuleMember -Function @(
    'Get-LatestSpecKitRelease',
    'Get-SpecKitRelease',
    'Get-SpecKitReleaseAssets',
    'Download-SpecKitTemplates',
    'Test-GitHubApiRateLimit'
)
```

**1.3.2: Implement Base API Request Function**
```powershell
function Invoke-GitHubApiRequest {
    param(
        [string]$Uri,
        [string]$Method = 'GET'
    )

    $headers = @{
        'Accept' = 'application/vnd.github+json'
        'User-Agent' = 'SpecKit-Update-Skill/1.0'
    }

    try {
        $response = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $headers
        return $response
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__

        if ($statusCode -eq 403) {
            # Rate limit exceeded
            $resetTime = $_.Exception.Response.Headers['X-RateLimit-Reset']
            if ($resetTime) {
                $resetDate = [DateTimeOffset]::FromUnixTimeSeconds($resetTime).LocalDateTime
                throw "GitHub API rate limit exceeded. Resets at: $resetDate. Consider setting GITHUB_TOKEN environment variable."
            }
            else {
                throw "GitHub API rate limit exceeded."
            }
        }
        elseif ($statusCode -eq 404) {
            throw "Resource not found: $Uri"
        }
        else {
            throw "GitHub API error ($statusCode): $($_.Exception.Message)"
        }
    }
}
```

**1.3.3: Implement Release Fetching**
```powershell
function Get-LatestSpecKitRelease {
    $uri = "https://api.github.com/repos/github/spec-kit/releases/latest"
    return Invoke-GitHubApiRequest -Uri $uri
}

function Get-SpecKitRelease {
    param([string]$Version)

    # Normalize version (add 'v' prefix if missing)
    if ($Version -notmatch '^v') {
        $Version = "v$Version"
    }

    $uri = "https://api.github.com/repos/github/spec-kit/releases/tags/$Version"
    return Invoke-GitHubApiRequest -Uri $uri
}
```

**1.3.4: Implement Template Download**
```powershell
function Download-SpecKitTemplates {
    param(
        [string]$Version,
        [string]$DestinationPath
    )

    # Get release
    $release = Get-SpecKitRelease -Version $Version

    # Find Claude templates asset
    $claudeAsset = $release.assets | Where-Object { $_.name -like '*claude*' }
    if (-not $claudeAsset) {
        throw "No Claude templates found in release $Version"
    }

    # Download ZIP
    $zipPath = Join-Path $DestinationPath "templates.zip"
    Invoke-WebRequest -Uri $claudeAsset.browser_download_url -OutFile $zipPath

    # Extract
    $extractPath = Join-Path $DestinationPath "extracted"
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

    # Read all files into hashtable (filename => content)
    $templates = @{}
    Get-ChildItem -Path $extractPath -Recurse -File | ForEach-Object {
        $relativePath = $_.FullName.Substring($extractPath.Length + 1)
        $templates[$relativePath] = Get-Content $_.FullName -Raw
    }

    # Cleanup
    Remove-Item $zipPath
    Remove-Item $extractPath -Recurse

    return $templates
}
```

**1.3.5: Write Unit Tests**

File: `tests/unit/GitHubApiClient.Tests.ps1`

Test cases (all mocked):
- [ ] Get-LatestSpecKitRelease returns release object
- [ ] Get-SpecKitRelease with version returns specific release
- [ ] Version normalization (adds 'v' prefix if missing)
- [ ] Rate limit error throws with helpful message
- [ ] 404 error throws with clear message
- [ ] Download-SpecKitTemplates returns hashtable of templates
- [ ] Mock Invoke-RestMethod for all tests

### Validation Checkpoint 1

**Exit Criteria:**
- [ ] All three modules implemented
- [ ] All unit tests written and passing
- [ ] Modules importable without errors
- [ ] Can compute normalized hashes correctly
- [ ] Can detect VSCode context correctly
- [ ] Can fetch GitHub releases (with mocked responses)

---

## Phase 2: Data Management

**Timeline:** Day 2-3 (8-12 hours)
**Dependencies:** Phase 1 complete

### Module 2.1: ManifestManager.psm1

**File:** `scripts/modules/ManifestManager.psm1`

**Purpose:** Manage manifest file CRUD operations.

#### Implementation Tasks

**2.1.1: Create Module Structure**
```powershell
Import-Module "$PSScriptRoot/HashUtils.psm1"
Import-Module "$PSScriptRoot/GitHubApiClient.psm1"

function Get-SpecKitManifest { param([string]$ProjectRoot) }
function New-SpecKitManifest { param([string]$ProjectRoot, [string]$SpecKitVersion, [switch]$AssumeAllCustomized) }
function Update-ManifestVersion { param([string]$ProjectRoot, [string]$NewVersion) }
function Add-TrackedFile { param([string]$ProjectRoot, [string]$FilePath, [string]$Hash, [bool]$IsOfficial) }
function Remove-TrackedFile { param([string]$ProjectRoot, [string]$FilePath) }
function Get-OfficialSpecKitCommands { param([string]$SpecKitVersion) }
function Update-FileHashes { param([string]$ProjectRoot) }

Export-ModuleMember -Function @(
    'Get-SpecKitManifest',
    'New-SpecKitManifest',
    'Update-ManifestVersion',
    'Add-TrackedFile',
    'Remove-TrackedFile',
    'Get-OfficialSpecKitCommands',
    'Update-FileHashes'
)
```

**2.1.2: Implement Get-SpecKitManifest**
```powershell
function Get-SpecKitManifest {
    param([string]$ProjectRoot = $PWD)

    $manifestPath = Join-Path $ProjectRoot ".specify/manifest.json"

    if (-not (Test-Path $manifestPath)) {
        return $null
    }

    try {
        $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json

        # Validate schema version
        if (-not $manifest.version) {
            throw "Manifest missing schema version"
        }

        if ($manifest.version -ne "1.0") {
            throw "Unsupported manifest schema version: $($manifest.version)"
        }

        return $manifest
    }
    catch {
        throw "Failed to load manifest: $($_.Exception.Message)"
    }
}
```

**2.1.3: Implement New-SpecKitManifest**

This is complex - need to:
1. Scan `.specify/` and `.claude/commands/` directories
2. Compute hashes for all files
3. Fetch official command list from GitHub (or use cached)
4. Classify files as official vs custom
5. Set `customized` flag based on `AssumeAllCustomized` parameter

```powershell
function New-SpecKitManifest {
    param(
        [string]$ProjectRoot = $PWD,
        [string]$SpecKitVersion,
        [switch]$AssumeAllCustomized
    )

    $manifestPath = Join-Path $ProjectRoot ".specify/manifest.json"

    # Get official commands for this version
    $officialCommands = Get-OfficialSpecKitCommands -SpecKitVersion $SpecKitVersion

    # Scan directories
    $trackedFiles = @()
    $customFiles = @()

    # Scan .claude/commands/
    $commandsDir = Join-Path $ProjectRoot ".claude/commands"
    if (Test-Path $commandsDir) {
        Get-ChildItem $commandsDir -Filter "*.md" | ForEach-Object {
            $relativePath = ".claude/commands/$($_.Name)"
            $hash = Get-NormalizedHash -FilePath $_.FullName
            $isOfficial = $officialCommands -contains $_.Name

            if ($isOfficial) {
                $trackedFiles += @{
                    path = $relativePath
                    original_hash = $hash
                    customized = $AssumeAllCustomized.IsPresent
                    is_official = $true
                }
            }
            else {
                $customFiles += $relativePath
            }
        }
    }

    # Scan .specify/
    $specifyDir = Join-Path $ProjectRoot ".specify"
    Get-ChildItem $specifyDir -Recurse -File | Where-Object {
        $_.Name -ne "manifest.json" -and $_.FullName -notlike "*backups*"
    } | ForEach-Object {
        $relativePath = $_.FullName.Substring($ProjectRoot.Length + 1) -replace '\\', '/'
        $hash = Get-NormalizedHash -FilePath $_.FullName

        $trackedFiles += @{
            path = $relativePath
            original_hash = $hash
            customized = $AssumeAllCustomized.IsPresent
            is_official = $true
        }
    }

    # Create manifest object
    $manifest = @{
        version = "1.0"
        speckit_version = $SpecKitVersion
        initialized_at = (Get-Date).ToUniversalTime().ToString("o")
        last_updated = (Get-Date).ToUniversalTime().ToString("o")
        agent = "claude-code"
        speckit_commands = $officialCommands
        tracked_files = $trackedFiles
        custom_files = $customFiles
        backup_history = @()
    }

    # Save
    $manifest | ConvertTo-Json -Depth 10 | Set-Content $manifestPath -Encoding utf8

    return Get-SpecKitManifest -ProjectRoot $ProjectRoot
}
```

**2.1.4: Implement Get-OfficialSpecKitCommands**

This needs to fetch the list from GitHub or use a cached list.

```powershell
# Cache for official commands
$script:OfficialCommandsCache = @{}

function Get-OfficialSpecKitCommands {
    param([string]$SpecKitVersion)

    # Check cache
    if ($script:OfficialCommandsCache.ContainsKey($SpecKitVersion)) {
        return $script:OfficialCommandsCache[$SpecKitVersion]
    }

    try {
        # Download templates to temporary location
        $tempDir = Join-Path $env:TEMP "speckit-temp-$(Get-Random)"
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

        $templates = Download-SpecKitTemplates -Version $SpecKitVersion -DestinationPath $tempDir

        # Extract command filenames
        $commands = $templates.Keys | Where-Object { $_ -like '.claude/commands/*.md' } | ForEach-Object {
            Split-Path $_ -Leaf
        }

        # Cache result
        $script:OfficialCommandsCache[$SpecKitVersion] = $commands

        return $commands
    }
    catch {
        # Fallback: known commands as of spec writing
        Write-Warning "Could not fetch official commands from GitHub. Using fallback list."

        $fallbackCommands = @(
            "speckit.constitution.md",
            "speckit.specify.md",
            "speckit.clarify.md",
            "speckit.plan.md",
            "speckit.tasks.md",
            "speckit.implement.md",
            "speckit.analyze.md",
            "speckit.checklist.md"
        )

        return $fallbackCommands
    }
}
```

**2.1.5: Implement Remaining Functions**

- `Update-ManifestVersion`: Update version and timestamp
- `Add-TrackedFile`: Append to tracked_files array
- `Remove-TrackedFile`: Remove from tracked_files array
- `Update-FileHashes`: Recompute all hashes and update customized flags

**2.1.6: Write Unit Tests**

File: `tests/unit/ManifestManager.Tests.ps1`

Test cases:
- [ ] Get-SpecKitManifest returns null when not found
- [ ] Get-SpecKitManifest returns manifest when found
- [ ] Get-SpecKitManifest throws on corrupted manifest
- [ ] New-SpecKitManifest creates valid manifest
- [ ] New-SpecKitManifest with AssumeAllCustomized marks all as customized
- [ ] Get-OfficialSpecKitCommands returns command list
- [ ] Get-OfficialSpecKitCommands caches results
- [ ] Update-ManifestVersion updates version field
- [ ] Add-TrackedFile appends to tracked_files
- [ ] Remove-TrackedFile removes from tracked_files

### Module 2.2: BackupManager.psm1

**File:** `scripts/modules/BackupManager.psm1`

**Purpose:** Create, manage, and restore backups.

#### Implementation Tasks

**2.2.1: Create Module Structure**
```powershell
Import-Module "$PSScriptRoot/ManifestManager.psm1"

function New-SpecKitBackup { param([string]$ProjectRoot) }
function Restore-SpecKitBackup { param([string]$ProjectRoot, [string]$BackupPath) }
function Get-SpecKitBackups { param([string]$ProjectRoot) }
function Remove-OldBackups { param([string]$ProjectRoot, [int]$KeepCount = 5, [switch]$WhatIf) }
function Invoke-AutomaticRollback { param([string]$ProjectRoot, [string]$BackupPath) }

Export-ModuleMember -Function @(
    'New-SpecKitBackup',
    'Restore-SpecKitBackup',
    'Get-SpecKitBackups',
    'Remove-OldBackups',
    'Invoke-AutomaticRollback'
)
```

**2.2.2: Implement New-SpecKitBackup**
```powershell
function New-SpecKitBackup {
    param([string]$ProjectRoot = $PWD)

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupDir = Join-Path $ProjectRoot ".specify/backups/$timestamp"

    # Create backup directory
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

    # Copy .specify/ (excluding backups directory itself)
    $specifyBackup = Join-Path $backupDir ".specify"
    Copy-Item -Path (Join-Path $ProjectRoot ".specify") -Destination $specifyBackup -Recurse -Force -Exclude "backups"

    # Copy .claude/
    $claudeBackup = Join-Path $backupDir ".claude"
    if (Test-Path (Join-Path $ProjectRoot ".claude")) {
        Copy-Item -Path (Join-Path $ProjectRoot ".claude") -Destination $claudeBackup -Recurse -Force
    }

    # Update manifest backup history
    $manifest = Get-SpecKitManifest -ProjectRoot $ProjectRoot
    if ($manifest) {
        $backupEntry = @{
            timestamp = (Get-Date).ToUniversalTime().ToString("o")
            path = ".specify/backups/$timestamp"
            from_version = $manifest.speckit_version
            to_version = $manifest.speckit_version  # Will be updated after successful update
        }

        # This would require updating the manifest, but we don't want to modify
        # the original during backup creation. Instead, orchestrator will update
        # backup_history after successful update.
    }

    Write-Host "Backup created: .specify/backups/$timestamp"

    return $backupDir
}
```

**2.2.3: Implement Restore-SpecKitBackup**
```powershell
function Restore-SpecKitBackup {
    param(
        [string]$ProjectRoot = $PWD,
        [string]$BackupPath
    )

    if (-not (Test-Path $BackupPath)) {
        throw "Backup not found: $BackupPath"
    }

    # Restore .specify/
    $specifyBackup = Join-Path $BackupPath ".specify"
    if (Test-Path $specifyBackup) {
        $specifyDest = Join-Path $ProjectRoot ".specify"
        Remove-Item $specifyDest -Recurse -Force
        Copy-Item -Path $specifyBackup -Destination $specifyDest -Recurse -Force
    }

    # Restore .claude/
    $claudeBackup = Join-Path $BackupPath ".claude"
    if (Test-Path $claudeBackup) {
        $claudeDest = Join-Path $ProjectRoot ".claude"
        Remove-Item $claudeDest -Recurse -Force -ErrorAction SilentlyContinue
        Copy-Item -Path $claudeBackup -Destination $claudeDest -Recurse -Force
    }

    Write-Host "Restored from backup: $BackupPath"
}
```

**2.2.4: Implement Get-SpecKitBackups**
```powershell
function Get-SpecKitBackups {
    param([string]$ProjectRoot = $PWD)

    $backupsDir = Join-Path $ProjectRoot ".specify/backups"

    if (-not (Test-Path $backupsDir)) {
        return @()
    }

    $backups = Get-ChildItem $backupsDir -Directory | ForEach-Object {
        $timestamp = $_.Name
        @{
            Timestamp = $timestamp
            Path = $_.FullName
            CreatedAt = $_.CreationTime
            SizeKB = [math]::Round((Get-ChildItem $_.FullName -Recurse | Measure-Object -Property Length -Sum).Sum / 1KB, 2)
        }
    } | Sort-Object CreatedAt -Descending

    return $backups
}
```

**2.2.5: Implement Remove-OldBackups**
```powershell
function Remove-OldBackups {
    param(
        [string]$ProjectRoot = $PWD,
        [int]$KeepCount = 5,
        [switch]$WhatIf
    )

    $backups = Get-SpecKitBackups -ProjectRoot $ProjectRoot

    if ($backups.Count -le $KeepCount) {
        return @()  # Nothing to remove
    }

    # Keep newest $KeepCount, remove rest
    $toRemove = $backups | Select-Object -Skip $KeepCount

    if ($WhatIf) {
        return $toRemove
    }

    foreach ($backup in $toRemove) {
        Remove-Item $backup.Path -Recurse -Force
        Write-Host "Removed old backup: $($backup.Timestamp)"
    }

    return $toRemove
}
```

**2.2.6: Write Unit Tests**

File: `tests/unit/BackupManager.Tests.ps1`

Test cases:
- [ ] New-SpecKitBackup creates backup directory
- [ ] New-SpecKitBackup copies all necessary files
- [ ] Restore-SpecKitBackup restores files correctly
- [ ] Get-SpecKitBackups lists backups sorted by date
- [ ] Remove-OldBackups with WhatIf doesn't delete
- [ ] Remove-OldBackups keeps correct count
- [ ] Invoke-AutomaticRollback calls Restore-SpecKitBackup

### Validation Checkpoint 2

**Exit Criteria:**
- [ ] ManifestManager.psm1 complete and tested
- [ ] BackupManager.psm1 complete and tested
- [ ] Can create and read manifests
- [ ] Can create and restore backups
- [ ] Unit tests passing for both modules

---

## Phase 3: Business Logic

**Timeline:** Day 4-5 (8-12 hours)
**Dependencies:** Phase 1 & 2 complete

### Module 3.1: ConflictDetector.psm1

**File:** `scripts/modules/ConflictDetector.psm1`

**Purpose:** Detect customizations and conflicts.

#### Implementation Tasks

**3.1.1: Create Module Structure**
```powershell
Import-Module "$PSScriptRoot/HashUtils.psm1"
Import-Module "$PSScriptRoot/ManifestManager.psm1"

function Get-FileState { }
function Get-AllFileStates { }
function Test-FileCustomized { }
function Find-CustomCommands { }

Export-ModuleMember -Function @(
    'Get-FileState',
    'Get-AllFileStates',
    'Test-FileCustomized',
    'Find-CustomCommands'
)
```

**3.1.2: Implement Get-FileState**

This is the core logic for determining what action to take for each file.

```powershell
function Get-FileState {
    param(
        [string]$FilePath,
        [string]$OriginalHash,
        [string]$UpstreamHash,
        [bool]$IsOfficial
    )

    # Compute current hash
    $currentHash = if (Test-Path $FilePath) {
        Get-NormalizedHash -FilePath $FilePath
    } else {
        $null
    }

    # Determine states
    $isCustomized = $currentHash -and (Compare-FileHashes -Hash1 $currentHash -Hash2 $OriginalHash) -eq $false
    $hasUpstreamChanges = (Compare-FileHashes -Hash1 $OriginalHash -Hash2 $UpstreamHash) -eq $false
    $isConflict = $isCustomized -and $hasUpstreamChanges

    # Determine action
    $action = if (-not $currentHash) {
        'add'  # File doesn't exist, upstream has it
    }
    elseif (-not $UpstreamHash) {
        if ($isCustomized) {
            'preserve'  # Custom file, upstream removed it
        } else {
            'remove'  # Official file removed upstream
        }
    }
    elseif ($isConflict) {
        'merge'  # Both modified
    }
    elseif ($isCustomized) {
        'preserve'  # User modified, no upstream change
    }
    elseif ($hasUpstreamChanges) {
        'update'  # Not modified, upstream changed
    }
    else {
        'skip'  # No changes
    }

    return @{
        Path = $FilePath
        CurrentHash = $currentHash
        OriginalHash = $OriginalHash
        UpstreamHash = $UpstreamHash
        IsCustomized = $isCustomized
        HasUpstreamChanges = $hasUpstreamChanges
        IsConflict = $isConflict
        IsOfficial = $IsOfficial
        Action = $action
    }
}
```

**3.1.3: Implement Get-AllFileStates**

```powershell
function Get-AllFileStates {
    param(
        [PSCustomObject]$Manifest,
        [hashtable]$UpstreamTemplates
    )

    $fileStates = @()

    # Check tracked files
    foreach ($trackedFile in $Manifest.tracked_files) {
        $upstreamHash = if ($UpstreamTemplates.ContainsKey($trackedFile.path)) {
            Get-NormalizedHash -FilePath ([System.IO.Path]::GetTempFileName())  # TODO: write upstream content to temp file
        } else {
            $null
        }

        $state = Get-FileState `
            -FilePath $trackedFile.path `
            -OriginalHash $trackedFile.original_hash `
            -UpstreamHash $upstreamHash `
            -IsOfficial $trackedFile.is_official

        $fileStates += $state
    }

    # Check for new files in upstream (not in manifest)
    foreach ($upstreamPath in $UpstreamTemplates.Keys) {
        $existsInManifest = $Manifest.tracked_files | Where-Object { $_.path -eq $upstreamPath }

        if (-not $existsInManifest) {
            # New file in upstream
            $state = Get-FileState `
                -FilePath $upstreamPath `
                -OriginalHash $null `
                -UpstreamHash (Get-NormalizedHash -FilePath (Write upstream to temp)) `
                -IsOfficial $true

            $fileStates += $state
        }
    }

    return $fileStates
}
```

**3.1.4: Implement Find-CustomCommands**

```powershell
function Find-CustomCommands {
    param(
        [string]$ProjectRoot,
        [string[]]$OfficialCommands
    )

    $commandsDir = Join-Path $ProjectRoot ".claude/commands"

    if (-not (Test-Path $commandsDir)) {
        return @()
    }

    $customCommands = Get-ChildItem $commandsDir -Filter "*.md" | Where-Object {
        $OfficialCommands -notcontains $_.Name
    } | ForEach-Object {
        $_.Name
    }

    return $customCommands
}
```

**3.1.5: Write Unit Tests**

File: `tests/unit/ConflictDetector.Tests.ps1`

Test cases:
- [ ] Get-FileState detects customization correctly
- [ ] Get-FileState detects upstream changes
- [ ] Get-FileState identifies conflicts
- [ ] Get-FileState determines correct action (update/preserve/merge/add/remove)
- [ ] Find-CustomCommands identifies custom commands
- [ ] Get-AllFileStates processes all tracked files

### Validation Checkpoint 3

**Exit Criteria:**
- [ ] ConflictDetector.psm1 complete and tested
- [ ] Can detect customizations accurately
- [ ] Can identify conflicts correctly
- [ ] All unit tests passing

---

## Phase 4: Orchestration

**Timeline:** Day 6-7 (10-14 hours)
**Dependencies:** All previous phases complete

### Main Script: update-orchestrator.ps1

**File:** `scripts/update-orchestrator.ps1`

**Purpose:** Main entry point that coordinates all modules.

#### Implementation Tasks

**4.1: Create Main Script Structure**

```powershell
#Requires -Version 7.0

[CmdletBinding()]
param(
    [switch]$CheckOnly,
    [string]$Version,
    [switch]$Force,
    [switch]$Rollback,
    [switch]$NoBackup
)

# Import all modules
$modulesPath = Join-Path $PSScriptRoot "modules"
Import-Module (Join-Path $modulesPath "HashUtils.psm1") -Force
Import-Module (Join-Path $modulesPath "VSCodeIntegration.psm1") -Force
Import-Module (Join-Path $modulesPath "GitHubApiClient.psm1") -Force
Import-Module (Join-Path $modulesPath "ManifestManager.psm1") -Force
Import-Module (Join-Path $modulesPath "BackupManager.psm1") -Force
Import-Module (Join-Path $modulesPath "ConflictDetector.psm1") -Force

# Import helper functions
. (Join-Path $PSScriptRoot "helpers/Invoke-PreUpdateValidation.ps1")
. (Join-Path $PSScriptRoot "helpers/Show-UpdateSummary.ps1")

# Main execution
try {
    # 1. Validate prerequisites
    Invoke-PreUpdateValidation

    # 2. Handle rollback if requested
    if ($Rollback) {
        # ... rollback workflow
        exit 0
    }

    # 3-15. Continue with update workflow (see spec)

    exit 0
}
catch {
    Write-Error $_.Exception.Message

    # Automatic rollback on failure
    if (-not $NoBackup -and $backupPath) {
        Invoke-AutomaticRollback -ProjectRoot $PWD -BackupPath $backupPath
    }

    exit 6
}
```

**4.2: Implement Helper Functions**

**File:** `scripts/helpers/Invoke-PreUpdateValidation.ps1`

Implement all validation checks from spec:
- Git installed
- .specify/ exists
- Write permissions
- Git state (clean or staged)
- VSCode available (warning)
- Internet connectivity (warning)
- Disk space (warning)

**File:** `scripts/helpers/Show-UpdateSummary.ps1`

Implement detailed summary output from spec.

**File:** `scripts/helpers/Get-UpdateConfirmation.ps1`

Handle user confirmation before applying updates.

**File:** `scripts/helpers/Invoke-ConflictResolutionWorkflow.ps1`

Implement Flow A conflict resolution (one at a time).

**File:** `scripts/helpers/Invoke-ThreeWayMerge.ps1`

Handle 3-way merge with temp files and cleanup.

**4.3: Implement Check-Only Mode**

This should be relatively straightforward - fetch data, analyze, display report, exit.

**4.4: Implement Standard Update Flow**

Core logic:
1. Get/create manifest
2. Fetch target version
3. Analyze file states
4. Get confirmation
5. Create backup
6. Download templates
7. Apply updates (loop through file states)
8. Handle conflicts if any
9. Update constitution
10. Update manifest
11. Cleanup old backups
12. Show summary

**4.5: Implement Rollback Workflow**

List backups, let user select, restore, show confirmation.

**4.6: Implement Force Mode**

Override customization preservation, require "YES" confirmation.

### Validation Checkpoint 4

**Exit Criteria:**
- [ ] Orchestrator script complete
- [ ] All helper functions implemented
- [ ] Check-only mode works
- [ ] Standard update flow works (with mocked GitHub)
- [ ] Rollback works
- [ ] Force mode works
- [ ] Error handling and automatic rollback works

---

## Phase 5: Testing

**Timeline:** Day 8-9 (10-14 hours)
**Dependencies:** Phase 4 complete

### Integration Tests

**File:** `tests/integration/UpdateOrchestrator.Tests.ps1`

#### Test Scenarios

**5.1: Standard Update (No Conflicts)**
- Fresh project with manifest
- Available update
- No customizations
- Should update cleanly

**5.2: Update with Customizations**
- Project with customized files
- No upstream changes to customized files
- Should preserve customizations

**5.3: Update with Conflicts**
- Customized files with upstream changes
- Should detect conflicts
- Should guide through resolution

**5.4: First-Time Manifest Generation**
- Old project without manifest
- Should offer to create manifest
- Should assume all files customized

**5.5: Custom Commands Preservation**
- Project with custom commands
- Official commands updated
- Custom commands preserved

**5.6: Rollback on Failure**
- Simulate failure mid-update
- Should automatically rollback
- Files restored to original state

**5.7: Backup Retention**
- Multiple updates creating backups
- Should prompt to cleanup old backups
- Should keep correct count

**5.8: Command Lifecycle**
- New official command added upstream
- Old official command removed upstream
- Custom command not affected

### Test Fixture Updates

Update all fixture projects to be realistic:
- Add actual SpecKit file content
- Create scenarios for each test case
- Mock GitHub API responses for various versions

### Code Coverage

Aim for >80% code coverage using Pester's code coverage feature.

### Validation Checkpoint 5

**Exit Criteria:**
- [ ] All integration tests written
- [ ] All integration tests passing
- [ ] Code coverage >80%
- [ ] Edge cases tested
- [ ] Error scenarios tested

---

## Phase 6: Distribution

**Timeline:** Day 10 (6-8 hours)
**Dependencies:** Phase 5 complete
**Critical:** Must produce GitHub-installable repository

### Documentation

**6.1: Complete README.md**

Sections:
- Overview with badges (license, tests status)
- Features list
- Prerequisites
- Installation instructions (GitHub clone)
- Usage examples for all flags
- Troubleshooting common issues
- Contributing guidelines
- License

**6.2: Complete SKILL.md**

Follow spec exactly - this is what Claude Code reads.

Include:
- Command description
- Usage patterns
- Requirements
- Process flow
- Entry point command

**6.3: Create docs/ARCHITECTURE.md**

- System architecture diagram
- Module dependencies
- Data flow
- Design decisions

**6.4: Create CHANGELOG.md**

Start with v0.1.0 release notes.

### Repository Finalization

**6.5: Final Repository Structure Check**

Ensure structure matches spec exactly:
```
speckit-updater/
├── .github/workflows/test.yml
├── .gitignore
├── LICENSE
├── README.md
├── SKILL.md
├── CHANGELOG.md
├── scripts/
│   ├── update-orchestrator.ps1
│   ├── modules/ (5 modules)
│   └── helpers/ (all helpers)
├── templates/
│   └── manifest-template.json
├── tests/
│   ├── unit/ (6 test files)
│   ├── integration/ (1 test file)
│   ├── fixtures/ (all fixtures)
│   └── test-runner.ps1
└── docs/
    └── ARCHITECTURE.md
```

**6.6: Create GitHub Release v0.1.0**

- Tag: `v0.1.0`
- Title: "SpecKit Safe Update v0.1.0 - Initial Release"
- Release notes from CHANGELOG.md
- Mark as pre-release if needed

**6.7: Test Installation from GitHub**

**Critical validation step:**

```powershell
# Fresh directory
cd $env:USERPROFILE\.claude\skills

# Remove if exists
Remove-Item speckit-updater -Recurse -Force -ErrorAction SilentlyContinue

# Clone
git clone https://github.com/[username]/claude-speckit-safe-update speckit-updater

# Verify structure
Test-Path speckit-updater/SKILL.md
Test-Path speckit-updater/scripts/update-orchestrator.ps1

# Restart VSCode
# Verify /speckit-update command available
```

### Validation Checkpoint 6

**Exit Criteria:**
- [ ] All documentation complete
- [ ] README has clear installation instructions
- [ ] SKILL.md properly formatted
- [ ] Repository tagged with v0.1.0
- [ ] Can clone from GitHub successfully
- [ ] Directory structure correct after clone
- [ ] SKILL.md readable by Claude Code
- [ ] /speckit-update command shows in Claude Code after VSCode restart

**CRITICAL:** Phase 7 cannot begin until all Phase 6 criteria met.

---

## Phase 7: Manual Testing

**Timeline:** Day 11+ (variable)
**Dependencies:** Phase 6 complete - repository must be GitHub-installable
**Critical:** Testing MUST begin with GitHub installation

### Pre-Testing Setup

**7.1: Prepare Test Environment**

- [ ] Fresh Windows 11 VM or clean user profile
- [ ] Install prerequisites:
  - Git
  - PowerShell 7+
  - VSCode with Claude Code extension
  - SpecKit CLI (uv/uvx)
- [ ] Create test SpecKit projects at various versions

### Installation Test

**7.2: Test GitHub Installation**

Following spec's manual test checklist:

- [ ] Clone repository from GitHub to skills directory
- [ ] Restart VSCode
- [ ] Verify `/speckit-update --help` works
- [ ] Verify skill appears in Claude Code

### Functional Tests

Run through all scenarios from spec's manual test checklist:

**7.3: Fresh Project Test**
- [ ] Create new SpecKit project
- [ ] Run --check-only
- [ ] Create manifest
- [ ] Verify manifest structure

**7.4: Standard Update Test**
- [ ] Existing project (old version)
- [ ] Check for updates
- [ ] Apply update
- [ ] Verify files updated
- [ ] Verify manifest updated

**7.5: Conflict Resolution Test**
- [ ] Customize file
- [ ] Update to version with upstream changes
- [ ] Verify conflict detected
- [ ] Test Flow A (selective opening)
- [ ] Resolve via merge editor
- [ ] Verify temp files cleaned up

**7.6: Custom Commands Test**
- [ ] Add custom command
- [ ] Run update
- [ ] Verify custom preserved
- [ ] Verify in summary

**7.7: Rollback Test**
- [ ] Complete update
- [ ] Run --rollback
- [ ] Select backup
- [ ] Verify restoration

**7.8: Error Handling Test**
- [ ] Dirty Git state
- [ ] No internet
- [ ] Invalid version
- [ ] Automatic rollback

**7.9: Backup Retention Test**
- [ ] Run 6 updates
- [ ] Verify cleanup prompt
- [ ] Confirm cleanup
- [ ] Verify correct count remains

**7.10: Context Detection Test**
- [ ] Run from Claude Code chat
- [ ] Run from VSCode terminal
- [ ] Run from standalone PowerShell
- [ ] Verify appropriate UI in each

### Issue Tracking

**7.11: Bug Tracking**

Create GitHub issues for any bugs found:
- Label: `bug`
- Severity: critical/high/medium/low
- Steps to reproduce
- Expected vs actual behavior

**7.12: Fix Critical Bugs**

Block release on critical bugs.

### Validation Checkpoint 7

**Exit Criteria:**
- [ ] All manual tests passed
- [ ] No critical bugs
- [ ] High/medium bugs documented
- [ ] Skill works end-to-end from GitHub installation
- [ ] Ready for production use

---

## Risk Management

### Identified Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| **GitHub API rate limiting during testing** | High | Medium | Mock API responses in tests; provide clear error messages; cache API results |
| **Git state detection edge cases** | Medium | High | Comprehensive test cases for all Git states; clear error messages |
| **VSCode CLI not available in PATH** | Medium | Medium | Clear prerequisite validation; helpful error with installation link |
| **Manifest schema evolution breaks compatibility** | Low | High | Version manifest schema; plan migration path; backward compatibility |
| **Cross-platform line ending issues** | Medium | Medium | Normalized hashing handles this; test with CRLF and LF files |
| **PowerShell version incompatibilities** | Low | Medium | Require PowerShell 7+; use #Requires directive |
| **Constitution integration complexity** | Medium | Low | For v1, just notify user; full automation is future enhancement |
| **Users skip backups with --no-backup** | Medium | High | Warn prominently; require additional confirmation |
| **Partial update leaves project in bad state** | Low | High | Fail-fast with automatic rollback; transactional approach |
| **Testing requires actual SpecKit projects** | Medium | Medium | Create realistic test fixtures; document setup process |

### Contingency Plans

**If GitHub API rate limited:**
- Implement basic caching layer
- Provide option to use local ZIP files

**If VSCode integration too complex:**
- Simplify to just `code --diff` and `code --merge`
- Document manual workarounds

**If testing reveals fundamental issues:**
- Pause, reassess approach
- May need to refactor orchestrator
- Timeline extends accordingly

---

## Quality Gates

Each phase must pass these gates before proceeding:

### Code Quality
- [ ] PowerShell ScriptAnalyzer warnings resolved
- [ ] Consistent code style (indentation, naming)
- [ ] Comprehensive error handling
- [ ] Logging for debugging

### Testing Quality
- [ ] All unit tests passing
- [ ] All integration tests passing
- [ ] Code coverage >80%
- [ ] Edge cases covered

### Documentation Quality
- [ ] All functions have comment-based help
- [ ] README has clear examples
- [ ] Installation steps tested
- [ ] Architecture documented

### Distribution Quality
- [ ] Repository structure correct
- [ ] GitHub installation works
- [ ] Claude Code recognizes skill
- [ ] Manual tests passing

---

## Success Metrics

### Implementation Success
- [ ] All phases completed on schedule (1-2 weeks)
- [ ] All automated tests passing
- [ ] All manual tests passing
- [ ] Zero critical bugs

### Distribution Success
- [ ] Repository publicly accessible
- [ ] Installation documentation clear
- [ ] Can install from GitHub in <5 minutes
- [ ] Command works after installation

### Functional Success
- [ ] Updates preserve customizations
- [ ] Conflicts resolved via merge editor
- [ ] Rollback works reliably
- [ ] Backup retention managed automatically
- [ ] Constitution integration functional

---

## Timeline Summary

| Phase | Days | Focus | Critical Deliverable |
|-------|------|-------|---------------------|
| Phase 0 | 1 | Setup | Repository structure |
| Phase 1 | 1-2 | Utilities | Core modules (3) |
| Phase 2 | 2-3 | Data | Manifest & backup |
| Phase 3 | 4-5 | Logic | Conflict detection |
| Phase 4 | 6-7 | Orchestration | Main script |
| Phase 5 | 8-9 | Testing | Test suite |
| Phase 6 | 10 | Distribution | **GitHub-installable repo** |
| Phase 7 | 11+ | Validation | Manual testing |

**Total:** 11+ days (1-2 weeks with AI assistance)

**Critical Milestone:** End of Day 10 - Repository must be fully installable from GitHub

---

## Implementation Checklist

### Pre-Implementation
- [ ] Review spec thoroughly
- [ ] Set up development environment
- [ ] Create GitHub repository
- [ ] Initialize project structure

### During Implementation
- [ ] Follow phase order strictly
- [ ] Write tests alongside code
- [ ] Commit frequently with clear messages
- [ ] Document as you go

### Post-Implementation
- [ ] Complete all manual tests
- [ ] Create GitHub release
- [ ] Update documentation
- [ ] Prepare for distribution

---

**Plan Version:** 1.0
**Last Updated:** 2025-01-19
**Status:** Ready for Execution
**Critical Success Factor:** Repository fully installable from GitHub before manual testing begins
