# PRD: SpecKit Safe Update Command for Claude Code

## Executive Summary

A Claude Code Skill providing a `/speckit-update` slash command that safely updates SpecKit templates, commands, and scripts while preserving user customizations. Leverages VSCode's native diff and merge tools for conflict resolution. Packaged as a portable Claude Code Skill that can be shared across projects. Addresses the critical gap where `specify init --force` destroys customizations and no official update mechanism exists.

## Clarifications

**Execution Context:** This command supports multiple execution contexts:
- **Claude Code VSCode extension** (primary interface) - Uses VSCode Quick Pick for prompts
- **VSCode PowerShell integrated terminal** - Full VSCode integration available
- **Standalone PowerShell terminal** - Graceful fallback to text-based prompts
- Context detection automatic via environment variables (`$env:VSCODE_PID`)

**User Interface Strategy:**
- **Claude Code orchestration:** When invoked as slash command, Claude presents choices via Quick Pick and passes decisions to PowerShell scripts
- **Graceful degradation:** PowerShell scripts detect execution context and adapt UI (VSCode Quick Pick vs terminal prompts)
- **File operations:** Always use `code --diff` and `code --merge` for visualizations (works from any context)

**Tooling Approach:** Leverages VSCode native capabilities:
- VSCode diff viewer for side-by-side comparisons
- VSCode 3-way merge editor for conflict resolution
- VSCode file operations and UI notifications
- Claude Code native Quick Pick when available

**Packaging:** Delivered as a Claude Code Skill:
- Structured as SKILL.md with supporting scripts
- Portable across projects via Skill installation
- Follows Claude Code Skill best practices
- Claude-only focus (does not update other agent directories)

## Problem Statement

SpecKit users face an impossible choice:
- **Update and lose customizations**: Running `specify init --force` overwrites `.claude/commands/`, constitution.md, and custom templates
- **Stay outdated and miss fixes**: Not updating means missing bug fixes, new features, and security patches
- **Manual merge hell**: Current workaround requires Git-based 3-way merges that are error-prone and time-consuming

Production teams cannot adopt SpecKit without a safe update path. 38,800+ stars but multiple high-engagement issues (#324, #361, #655, #916) request update functionality.

## Goals

### Primary Goals
1. **Preserve customizations** during SpecKit template updates
2. **Provide clear visibility** into what will change before applying updates
3. **Enable rollback** if updates cause issues
4. **Support Windows 11/PowerShell** workflows natively

### Secondary Goals
- Automate detection of which SpecKit version is currently installed
- Detect conflicts between customizations and new templates
- Provide guided merge workflow for conflicting changes
- Support team version consistency (lock file approach)

### Non-Goals (v1)
- **Multi-agent support:** Only updates `.claude/commands/` directory, ignores other agents (Cursor, Copilot, etc.)
- **Automated conflict resolution:** Flag conflicts, require manual resolution via merge editor
- **Migration from other spec-driven tools:** SpecKit-only focus
- **GitHub authentication:** Unauthenticated API only (60 req/hour limit, show helpful error on rate limit)

## User Stories

### Story 1: Safe Update with Customizations
**As a** developer with customized SpecKit commands  
**I want to** update to latest templates without losing my customizations  
**So that** I can get bug fixes while keeping my team's workflows

**Acceptance Criteria:**
- Command identifies which files are customized vs. default
- Update process preserves constitution.md automatically
- Custom commands in .claude/commands/ are not overwritten
- Script modifications in .specify/scripts/ are preserved
- Dry-run mode shows exactly what will change

### Story 2: Version Awareness
**As a** team lead coordinating multiple developers  
**I want to** know which SpecKit version each project uses  
**So that** we can ensure consistency across the team

**Acceptance Criteria:**
- Command reports current installed SpecKit version (commit SHA or tag)
- Command reports available updates
- Version information stored in .specify/manifest.json
- Command works without internet connection (reports local version only)

### Story 3: Conflict Detection and Resolution
**As a** developer who customized templates  
**I want to** see conflicts between my changes and new templates  
**So that** I can merge them intelligently

**Acceptance Criteria:**
- Command detects when user-modified files have upstream changes
- Lists conflicts clearly with file paths
- Provides diff view comparing [old default] vs [my version] vs [new default]
- Offers options: keep mine, use new, manual merge, skip
- Generates merge markers for manual resolution

## Technical Design

### Command Signature
```powershell
/speckit-update [--check-only] [--version ] [--force] [--no-backup] [--auto-merge]
```

### Skill Structure
```
/mnt/skills/user/speckit-updater/
├── SKILL.md                          # Main skill definition with slash command
├── scripts/
│   ├── update-orchestrator.ps1       # Core update logic
│   ├── manifest-manager.ps1          # Version tracking
│   ├── conflict-detector.ps1         # Customization detection
│   ├── vscode-integration.ps1        # VSCode API interactions
│   └── backup-manager.ps1            # Backup/rollback
├── templates/
│   └── manifest-template.json        # Default manifest structure
└── README.md                         # Installation and usage guide
```

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│ Claude Code Skill: /speckit-update                          │
│ (SKILL.md defines command, invokes PowerShell)              │
└────────────────────┬────────────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         ▼                       ▼
┌─────────────────┐    ┌──────────────────────┐
│ Version Manager │    │ Customization Tracker │
│ - Detect current │    │ - Compare file hashes │
│ - Check updates  │    │ - Identify custom files│
│ - Fetch specific │    │ - Generate manifest   │
└────────┬────────┘    └──────────┬────────────┘
         │                        │
         └────────┬───────────────┘
                  ▼
        ┌──────────────────┐
        │ Update Orchestrator│
        │ - Backup current   │
        │ - Selective update │
        │ - Conflict resolver│
        └─────────┬──────────┘
                  │
         ┌────────┴────────┐
         ▼                 ▼
┌────────────────────┐  ┌───────────────────────┐
│ VSCode Integration │  │ Backup/Rollback Mgr  │
│ - Open diff views  │  │ - Create backups     │
│ - Trigger merge UI │  │ - Restore versions   │
│ - Show notifications│ │ - List history       │
└────────────────────┘  └───────────────────────┘
```

### VSCode Integration Points

#### Diff Viewer for File Comparisons
When customizations are detected, open VSCode's native diff:
```powershell
# Using VSCode's diff command
code --diff "path/to/original.md" "path/to/modified.md"
```

Claude Code can also invoke VSCode commands via URI:
```
vscode://file/path/to/file?line=10&column=5
vscode://vscode.diff?left=file1&right=file2
```

#### 3-Way Merge Editor for Conflicts
For files with both user customizations AND upstream changes:
```powershell
# VSCode merge editor (VSCode 1.69+)
code --merge "base.md" "current.md" "incoming.md" "result.md"
```

#### Notifications and Progress
```typescript
// Via Claude Code extension API (if available)
vscode.window.showInformationMessage('SpecKit update: 3 files preserved, 5 updated');
vscode.window.showWarningMessage('Conflict detected in plan.md', 'Open Diff', 'Skip');
```

#### Output Channel for Logging
Create dedicated output channel for detailed update logs:
```powershell
# PowerShell can write to files that VSCode Output panel monitors
Write-Host "SpecKit Update Log" | Out-File -Append $env:TEMP/speckit-update.log
```

### Claude Code Skill Structure (SKILL.md)

```markdown
# SpecKit Safe Update Skill

This skill provides safe update capabilities for GitHub SpecKit installations,
preserving customizations while applying template updates.

## Commands

### /speckit-update
Updates SpecKit templates, commands, and scripts while preserving customizations.

**Usage:**
- `/speckit-update` - Interactive update with conflict detection
- `/speckit-update --check-only` - Check for updates without applying
- `/speckit-update --version abc123` - Update to specific commit
- `/speckit-update --force` - Destructive update (overwrites customizations)

**Process:**
1. Detects current SpecKit version from manifest
2. Fetches target version from GitHub
3. Compares file hashes to identify customizations
4. Creates timestamped backup
5. Applies selective updates preserving custom files
6. Opens VSCode diff/merge tools for conflicts
7. Updates manifest with new version

**Requirements:**
- Git installed and in PATH
- Internet connection for fetching updates
- Write permissions to .specify/ and .claude/ directories

When you invoke this command, I will:
1. Execute the update-orchestrator.ps1 script
2. Present a summary of proposed changes
3. Ask for your confirmation before applying updates
4. Open VSCode diff viewers for any conflicts
5. Report results with preserved/updated file counts

The script is located at: {skill_path}/scripts/update-orchestrator.ps1
```

### SKILL.md Implementation Details

The SKILL.md will:
1. **Define the slash command** `/speckit-update` with clear description
2. **Specify the entry point** to PowerShell orchestrator script
3. **Document parameters** and their effects
4. **Set expectations** for Claude Code's behavior when command is invoked
5. **Provide context** about SpecKit's update problem being solved

### File Classification Strategy

#### Constitution Special Handling
- `.specify/memory/constitution.md` is handled via **automatic `/speckit.constitution` invocation**
- After update completes, Claude automatically triggers `/speckit.constitution` command
- Leverages SpecKit's existing command to intelligently merge constitution updates
- User reviews and approves constitution changes through Claude's guidance
- Preserves user customizations while offering to merge new template sections

#### Custom Commands Management
- **Tracked official SpecKit commands** in manifest: `"speckit_commands": ["speckit.constitution.md", "speckit.specify.md", ...]`
- **Lifecycle handling:**
  - New official command added → Install it automatically
  - Official command updated → Update it (unless user customized, then conflict flow)
  - Official command removed → Delete it (unless user customized, then preserve + warn)
  - Custom commands (not in official list) → Always preserve
- **Customization detection:** Uses normalized hash comparison (ignore line endings/trailing whitespace)

#### Selective Update (Check for Customization)
- `.specify/templates/*.md` - Compare normalized hashes, preserve if modified
- `.specify/scripts/*.sh` / `*.ps1` - Preserve if customized
- `.specify/memory/*.md` (except constitution, which uses special flow)
- `.claude/commands/*.md` - Track official vs custom, handle lifecycle

#### Always Update (Unless Customized)
- Template metadata files
- Version-specific compatibility files
- Official SpecKit command templates (only if hash matches default)

### Detection Algorithm

```csharp
// Pseudocode for customization detection
class CustomizationDetector 
{
    Dictionary CheckCustomizations(string projectRoot)
    {
        var manifest = LoadOrCreateManifest(projectRoot);
        var results = new Dictionary();
        
        foreach (var file in manifest.TrackedFiles)
        {
            var currentHash = ComputeFileHash(file.Path);
            var state = new FileState {
                Path = file.Path,
                IsCustomized = currentHash != file.OriginalHash,
                HasUpstreamChanges = CheckUpstreamChanges(file.Path, manifest.Version),
                IsConflict = IsCustomized && HasUpstreamChanges
            };
            results[file.Path] = state;
        }
        
        return results;
    }
}
```

### Manifest File Structure

`.specify/manifest.json`:
```json
{
  "speckit_version": "v0.0.72",
  "initialized_at": "2025-10-19T12:34:56Z",
  "last_updated": "2025-10-19T14:22:10Z",
  "agent": "claude-code",
  "speckit_commands": [
    "speckit.constitution.md",
    "speckit.specify.md",
    "speckit.clarify.md",
    "speckit.plan.md",
    "speckit.tasks.md",
    "speckit.implement.md",
    "speckit.analyze.md",
    "speckit.checklist.md"
  ],
  "tracked_files": [
    {
      "path": ".claude/commands/speckit.specify.md",
      "original_hash": "sha256:abc123...",
      "customized": false,
      "is_official": true
    },
    {
      "path": ".specify/memory/constitution.md",
      "original_hash": "sha256:def456...",
      "customized": true,
      "is_official": true
    },
    {
      "path": ".specify/templates/spec-template.md",
      "original_hash": "sha256:ghi789...",
      "customized": false,
      "is_official": true
    }
  ],
  "custom_files": [
    ".claude/commands/custom-deploy.md",
    ".claude/commands/run-security-scan.md"
  ]
}
```

**Note on manifest generation for existing installations:**
- When no manifest exists, assume ALL files are customized (safe default)
- User can run first update to see what would change, then decide

### Update Workflow

```mermaid
graph TD
    A[/speckit-update invoked] --> B{--check-only?}
    B -->|Yes| C[Show available updates]
    B -->|No| D[Create backup]
    D --> E[Load manifest.json]
    E --> F[Fetch target version]
    F --> G[Compare file states]
    G --> H{Conflicts found?}
    H -->|No| I[Apply updates selectively]
    H -->|Yes| J[Present conflict report]
    J --> K{User action}
    K -->|Keep mine| I
    K -->|Use new| I
    K -->|Manual| L[Generate merge markers]
    I --> M[Update manifest.json]
    M --> N[Success report]
    L --> N
    C --> END
    N --> END
```

### PowerShell Implementation Notes

```powershell
# Core update script structure
# Location: .specify/scripts/update-speckit.ps1

param(
    [switch]$CheckOnly,
    [string]$Version,
    [switch]$Force,
    [switch]$NoBackup
)

function Get-CurrentSpecKitVersion {
    # Read from manifest.json or detect via git
    $manifest = Get-Content ".specify/manifest.json" | ConvertFrom-Json
    return $manifest.speckit_version
}

function Get-FileCustomizationState {
    param([string]$FilePath, [string]$OriginalHash)
    
    $currentHash = (Get-FileHash $FilePath -Algorithm SHA256).Hash
    return $currentHash -ne $OriginalHash
}

function Backup-SpecKitState {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = ".specify/backups/$timestamp"
    
    New-Item -ItemType Directory -Path $backupPath -Force
    Copy-Item -Recurse -Path ".specify/*" -Destination "$backupPath/.specify"
    Copy-Item -Recurse -Path ".claude/*" -Destination "$backupPath/.claude"
    
    return $backupPath
}
```

## Command Behavior Specification

### `--check-only` Flag
Shows what would change without applying updates:
```
SpecKit Update Check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Current Version:  abc123def456 (0.0.52)
Latest Version:   xyz789abc012 (0.0.72)
Available Update: 20 versions behind

Files that would update (no conflicts):
  ✓ .specify/templates/plan-template.md
  ✓ .specify/scripts/create-new-feature.sh

Files with customizations (will preserve):
  ⚠ .specify/memory/constitution.md (customized)
  ⚠ .claude/commands/specify.md (customized)

Conflicts detected (require manual merge):
  ⚠ .claude/commands/plan.md
    - You modified: Added custom tech stack section
    - Upstream changed: New architecture validation step
  
Run '/speckit-update' to apply updates.
```

### Default Behavior (No Flags)
1. Create timestamped backup in `.specify/backups/`
2. Show files to be updated
3. Prompt for confirmation (Y/n)
4. Apply selective updates preserving customizations
5. Report success with list of preserved files

### `--force` Flag
Overwrites SpecKit files even if customized, but preserves user-created custom commands:
```
⚠ WARNING: --force will OVERWRITE customized SpecKit files

Files that will be reset to defaults:
  - .specify/memory/constitution.md (your customizations will be lost)
  - .claude/commands/speckit.specify.md (your customizations will be lost)
  - .claude/commands/speckit.plan.md (your customizations will be lost)

Files that will be PRESERVED:
  - .claude/commands/custom-deploy.md (custom command)
  - .claude/commands/run-security-scan.md (custom command)

Backup will be created at: .specify/backups/20251019-183907/

Type 'YES' to confirm destructive update: _
```

**Note:** User-created custom commands are always preserved, even with `--force`. Only official SpecKit files are overwritten.

### `--version <tag>` Flag
Updates to specific release version:
```powershell
/speckit-update --version v0.0.72
/speckit-update --version 0.0.72  # 'v' prefix optional
```

**Accepted formats:**
- Release tags only: `v0.0.72` or `0.0.72`
- Commit SHAs are NOT supported (use release tags)
- Fetches from GitHub Releases API

### Error Handling

**No manifest.json found:**
```
⚠ No SpecKit manifest found.
This may be an older SpecKit installation or not initialized via specify CLI.

Would you like to:
  1. Create manifest from current state (recommended)
  2. Run full re-initialization (destructive)
  3. Cancel

Choice [1]: _
```

**Internet connection required but unavailable:**
```
⚠ Cannot fetch updates: No internet connection
  
Local version: abc123def456 (0.0.52)
Last check: 2025-10-18 14:22:10

Run with --check-only when online to see available updates.
```

**Git not available:**
```
⚠ Git not found in PATH
SpecKit updates require Git to fetch templates from GitHub.

Install Git: winget install Git.Git
Then restart PowerShell.
```

## Implementation Plan

### Single Implementation Sprint (AI-Assisted)
**Timeline:** 1-2 weeks
**Approach:** Complete feature implementation and GitHub repository setup before any manual testing begins

**Critical Requirement:** The skill must be fully installable from GitHub repository before manual testing starts. Manual testing MUST begin with: `git clone <repo-url>` or skill installation from GitHub.

**Deliverables - Complete, Installable Claude Skill:**

#### Core Infrastructure
- Manifest generation and tracking (with `speckit_commands` list)
- Version detection via GitHub Releases API (unauthenticated)
- Normalized file hash comparison (ignore line endings/whitespace)
- Custom command lifecycle management (add/update/remove with customization detection)
- Backup creation with retention policy (warn + auto-cleanup, keep last 5)
- Git state validation (require clean or staged changes)

#### Update Workflow
- `--check-only` flag with file-level detail
- Selective updates preserving customizations
- Conflict detection and resolution (Flow A: list → Claude asks → selective opening)
- VSCode merge editor integration via `code --merge`
- Temporary merge file management (`.specify/.tmp-merge/` with auto-cleanup)
- Constitution updates via automatic `/speckit.constitution` invocation

#### Flags and Options
- `--version <tag>` for specific release (strict: tags only, no SHAs)
- `--force` with confirmation (overwrite SpecKit files, preserve custom commands)
- `--rollback` for manual rollback
- `--no-backup` to skip backup creation

#### Error Handling
- Automatic rollback on failure (fail-fast, no partial states)
- Pre-update validation (strict on essentials, warn on non-critical)
- Graceful context detection (VSCode Quick Pick vs terminal prompts)
- Helpful error messages for common issues (rate limits, Git missing, etc.)

#### User Experience
- Detailed success summary with complete file lists
- Claude Code orchestration for prompts and Quick Pick
- PowerShell context detection and graceful fallback
- Backup management with user confirmation before cleanup

#### Skill Packaging and Distribution
- Complete GitHub repository structure:
  - `SKILL.md` - Main skill definition with slash command documentation
  - `scripts/` - All PowerShell modules properly organized
  - `templates/` - Manifest templates and fixtures
  - `tests/` - Pester test suite
  - `README.md` - Installation and usage instructions
  - `LICENSE` - MIT or appropriate license
  - `.gitignore` - Proper exclusions
- Installation documentation:
  - Clone/download instructions
  - Manual installation to Claude Code skills directory
  - Prerequisites and dependencies
  - Quick start guide
- Repository tagged with initial version (v0.1.0)

#### Testing
- **Automated tests:** PowerShell Pester framework with mocked GitHub API
- **Test fixtures:** Various project states for automated validation
- **Manual testing:** Begins ONLY after skill is installable from GitHub
- **Manual test process:**
  1. Clone repository from GitHub
  2. Install skill to Claude Code
  3. Test all workflows end-to-end
  4. Validate error handling
  5. Confirm rollback scenarios

**Definition of Done for Implementation Sprint:**
- ✅ Complete skill functionality implemented
- ✅ Automated tests passing
- ✅ Skill installable from GitHub repository
- ✅ README with clear installation instructions
- ✅ Repository ready for distribution
- ✅ Can run `/speckit-update` successfully after installation

**Manual Testing Phase:** Begins after skill is GitHub-installable

**Total Timeline:** 1-2 weeks with AI-assisted development

### Skill Installation Process

**Primary Installation Method (GitHub):**
```powershell
# Navigate to Claude Code skills directory
cd $env:USERPROFILE\.claude\skills

# Clone the skill repository
git clone https://github.com/[username]/claude-speckit-safe-update speckit-updater

# Restart VSCode or reload window
# Then /speckit-update is available
```

**Alternative: Manual Download**
```powershell
# Download ZIP from GitHub releases
# Extract to: %USERPROFILE%\.claude\skills\speckit-updater\
# Restart VSCode
```

**Future: Claude Code Skill Marketplace**
```
Claude Code UI → Skills → Search "SpecKit Safe Update" → Install
```

**Installation Verification:**
```powershell
# After installation, verify skill is loaded:
# 1. Restart VSCode
# 2. Open Claude Code
# 3. Type /speckit-update --help
# Should show usage information
```

**Prerequisites:**
- Git installed (for cloning)
- PowerShell 7+
- VSCode with Claude Code extension
- Write permissions to skills directory

**Repository Structure Users Will See:**
```
speckit-updater/
├── SKILL.md                    # Skill definition (Claude Code reads this)
├── README.md                   # Installation and usage guide
├── LICENSE                     # MIT License
├── scripts/
│   ├── update-orchestrator.ps1
│   ├── manifest-manager.ps1
│   ├── conflict-detector.ps1
│   └── backup-manager.ps1
├── templates/
│   └── manifest-template.json
└── tests/
    └── *.Tests.ps1            # Pester tests
```

## Success Metrics

### Primary Metrics
- **Zero data loss:** No reports of lost customizations after update
- **Adoption rate:** 70%+ of SpecKit users use update command within 30 days of release
- **Conflict resolution success:** 80%+ of conflicts resolved without issue reports

### Secondary Metrics
- **Update frequency:** Users update 2x more frequently with safe update command
- **Support ticket reduction:** 60% reduction in "lost customizations" issues
- **Time saved:** Average update time reduces from 45min to 5min

## Dependencies

### Technical Dependencies
- Git (required, must be in PATH)
- PowerShell 7+ (user's environment)
- SpecKit CLI installed via uv/uvx
- Write permissions to .specify/ and .claude/ directories

### External Dependencies
- GitHub.com accessibility (for fetching updates)
- SpecKit repository remains at github.com/github/spec-kit

## Risks and Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|---------|-----------|------------|
| Manifest.json doesn't exist for old installations | High | High | Auto-generate manifest from current state with warning |
| Hash comparison fails for intentional whitespace changes | Medium | Medium | Normalize whitespace before hashing, provide override flag |
| Network failures during update | Medium | Medium | Transactional updates with automatic rollback on failure |
| User accidentally uses --force | High | Low | Require typed confirmation, show exactly what will be lost |
| SpecKit changes manifest format | Medium | Low | Version manifest schema, support migration |

## Design Decisions

All design questions have been resolved through clarification discussions. Key decisions documented below:

### Execution and User Interface
1. **Execution Context:** Detect and gracefully fallback (VSCode Quick Pick → terminal prompts)
2. **VSCode Integration:** Claude Code orchestrates prompts via Quick Pick, PowerShell handles file operations
3. **Conflict Resolution Flow:** List → Claude asks → Selective opening (one conflict at a time, Flow A)

### File Management
4. **Constitution Updates:** Automatically invoke `/speckit.constitution` after update completes
5. **Custom Commands:** Track official SpecKit commands in manifest; preserve customs; handle lifecycle (add/update/remove)
6. **Hash Algorithm:** Normalized hash (ignore line endings and trailing whitespace)
7. **Manifest Generation:** Assume everything is customized for existing installations (safe default)

### Update Behavior
8. **Backup Retention:** Warn then auto-cleanup (keep last 5, require confirmation before deletion)
9. **Git State Requirements:** Require clean state OR staged changes (enable safe rollback)
10. **Update Source:** GitHub Releases API, unauthenticated (60 req/hour)
11. **Version Format:** Strict - release tags only (`v0.0.72` or `0.0.72`, no commit SHAs)

### Flags and Error Handling
12. **`--force` Behavior:** Overwrite SpecKit files even if customized, preserve user-created customs
13. **Rollback:** Automatic on failure + manual `--rollback` flag
14. **Merge File Storage:** Temporary directory with auto-cleanup (`.specify/.tmp-merge/`)
15. **Error Recovery:** Fail-fast with automatic rollback (no partial states)
16. **Pre-Update Validation:** Warn on non-critical issues (strict on essentials, flexible on nice-to-haves)

### Scope and Testing
17. **Multi-Agent Support:** Claude-only (does not update other agent directories)
18. **GitHub Authentication:** Unauthenticated only (show helpful error on rate limit)
19. **`--check-only` Detail:** File-level detail with categorized lists
20. **Success Message:** Detailed summary with complete file lists
21. **Testing Strategy:** Automated test suite using Pester framework
22. **Implementation Approach:** Single sprint to complete implementation (1-2 weeks AI-assisted)
23. **Distribution Requirement:** Skill must be fully installable from GitHub before any manual testing begins

### Future Considerations
- **Manifest commit:** Yes, commit `.specify/manifest.json` to Git (like package-lock.json)
- **Downgrade support:** Yes, via `--version <older-tag>` with same safety guarantees
- **Selective updates:** Not in v1 (all-or-nothing approach)
- **Team version locking:** Not in v1 (manifest provides team consistency)

## Appendix: Windows 11 Environment Considerations

### PowerShell Execution Policy
Users may need to adjust execution policy for scripts:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Path Considerations
- Use `$PSScriptRoot` for script-relative paths
- Support both forward slashes and backslashes
- Handle spaces in paths (quote appropriately)

### File Operations
- Use `Copy-Item -Force` for overwrite scenarios
- Check file locks before operations (common on Windows)
- Use `Test-Path` instead of file existence checks

### Git Integration
- Detect Git via `Get-Command git -ErrorAction SilentlyContinue`
- Use `git.exe` explicitly (not rely on PATH shell resolution)
- Handle Windows Git credential manager integration

---

**Document Version:** 0.2.0 (Design Complete)
**Last Updated:** 2025-01-19
**Status:** All design decisions clarified and documented
**Owner:** TBD
**Stakeholders:** SpecKit users, Claude Code team, GitHub Spec Kit maintainers

**Change Log:**
- **v0.2.0 (2025-01-19):** Resolved all open questions through clarification discussions; updated execution context, file management strategies, and implementation plan to single-sprint AI-assisted approach; **critical requirement added:** skill must be GitHub-installable before manual testing begins
- **v0.1.0 (2025-10-19):** Initial draft with proposed approaches
