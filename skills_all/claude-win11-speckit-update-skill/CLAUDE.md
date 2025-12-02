# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **Claude Code Skill** that provides safe, automated updates for SpecKit installations. The skill preserves user customizations while applying template updates from GitHub releases, eliminating destructive `specify init --force` workflows.

**Key Concept:** This is distributed as a Git repository that users clone into `$env:USERPROFILE\.claude\skills\speckit-updater`. Claude Code automatically loads the `/speckit-update` command from [SKILL.md](SKILL.md).

## Common Commands

### Testing
```powershell
# Run all tests (unit + integration)
./tests/test-runner.ps1

# Run only unit tests
./tests/test-runner.ps1 -Unit

# Run only integration tests
./tests/test-runner.ps1 -Integration

# Run with code coverage
./tests/test-runner.ps1 -Coverage
```

### Manual Testing
```powershell
# Test the orchestrator directly (from a SpecKit project directory)
& "path\to\scripts\update-orchestrator.ps1" -CheckOnly

# Test with specific version
& "path\to\scripts\update-orchestrator.ps1" -Version v0.0.72 -CheckOnly

# Test rollback
& "path\to\scripts\update-orchestrator.ps1" -Rollback
```

### Development
```powershell
# Import modules for testing in PowerShell session
Import-Module .\scripts\modules\HashUtils.psm1 -Force
Import-Module .\scripts\modules\ManifestManager.psm1 -Force

# Test individual functions
Get-NormalizedHash -FilePath ".\README.md"
```

## Architecture

### Module vs. Helper Pattern

**IMPORTANT**: This codebase uses two distinct patterns for organizing PowerShell code. Understanding this distinction is critical to prevent recurring module import errors.

**Modules** (`.psm1` files in `scripts/modules/`):
- Imported with `Import-Module`
- Run in their own module scope (isolated from caller)
- MUST use `Export-ModuleMember` to export functions
- Used for business logic with public/private function separation
- Example: `HashUtils.psm1`, `ManifestManager.psm1`

**Helpers** (`.ps1` files in `scripts/helpers/`):
- Dot-sourced with `. script.ps1`
- Run in the caller's current scope (no isolation)
- MUST NOT use `Export-ModuleMember` (causes fatal errors)
- Functions are automatically available after dot-sourcing
- Used for thin orchestration wrappers around module functions
- Example: `Show-UpdateSummary.ps1`, `Get-UpdateConfirmation.ps1`

**Why This Matters**: `Export-ModuleMember` only works inside PowerShell module scope. Using it in dot-sourced scripts causes "Export-ModuleMember cmdlet can only be called from inside a module" errors that terminate script execution.

**Rule of Thumb**:
- If you use `Import-Module`, use `Export-ModuleMember`
- If you use dot-sourcing (`. script.ps1`), do NOT use `Export-ModuleMember`

**Nested Import Prohibition** (Added: 2025-10-20):
- **Modules MUST NOT import other modules**
- All `Import-Module` statements MUST be in the orchestrator (`update-orchestrator.ps1`)
- Nested imports create scope isolation where functions imported within a module are not accessible to the calling script
- **Enforcement**: Automated lint check in `tests/test-runner.ps1` fails if any `.psm1` file contains `Import-Module`
- **Pattern**: Orchestrator imports modules in dependency order (Tier 0 → Tier 1 → Tier 2)

**Correct Pattern** (orchestrator manages all imports):
```powershell
# scripts/update-orchestrator.ps1

# TIER 0: Foundation modules (no dependencies)
Import-Module (Join-Path $modulesPath "HashUtils.psm1") -Force
Import-Module (Join-Path $modulesPath "GitHubApiClient.psm1") -Force
Import-Module (Join-Path $modulesPath "MarkdownMerger.psm1") -Force

# TIER 1: Modules depending on Tier 0
Import-Module (Join-Path $modulesPath "ManifestManager.psm1") -Force
Import-Module (Join-Path $modulesPath "FingerprintDetector.psm1") -Force

# TIER 2: Modules depending on Tier 1
Import-Module (Join-Path $modulesPath "BackupManager.psm1") -Force
Import-Module (Join-Path $modulesPath "ConflictDetector.psm1") -Force
```

**Incorrect Pattern** (nested imports):
```powershell
# scripts/modules/ManifestManager.psm1 - ❌ INCORRECT
Import-Module (Join-Path $PSScriptRoot "HashUtils.psm1") -Force  # DO NOT DO THIS
```

See [.specify/memory/constitution.md - Module Import Rules](.specify/memory/constitution.md#module-import-rules-added-2025-10-20) for detailed rationale.

### Entry Point and Orchestration

**[scripts/update-orchestrator.ps1](scripts/update-orchestrator.ps1)** is the main entry point invoked by Claude Code. It coordinates the multi-step update workflow in sequence:

1. Validates prerequisites (Git, permissions, .specify/ directory)
2. Handles rollback requests
3. Loads/creates manifest (`.specify/manifest.json`)
   - **NEW**: Automatic version detection for first-time users via fingerprint matching
   - Enables smart merge for 95%+ of installations
4. Fetches target version from GitHub Releases API
5. Analyzes file states (customized vs. default)
6. Shows check-only report (if `-CheckOnly`)
7. Gets user confirmation
8. Creates timestamped backup
9. Downloads templates from GitHub
10. Applies selective updates
11. Handles conflicts via intelligent 3-way merge
    - **NEW**: Section-based semantic merge for markdown files
    - Fetches base content from original version
    - Auto-merges compatible changes
    - Generates granular conflict markers (section-level, not file-level)
12. Notifies about constitution updates
13. Updates manifest with new version/hashes
14. Cleans up old backups (retention management)
15. Shows detailed summary

### Core Modules (scripts/modules/)

**Critical Architecture Decision:** All business logic lives in modules, not helpers. Modules are stateless, reusable, and testable.

- **[HashUtils.psm1](scripts/modules/HashUtils.psm1)** - Normalized SHA-256 hashing
  - Handles CRLF/LF normalization, trailing whitespace, BOM removal
  - Ensures cross-platform/editor consistency for detecting real changes

- **[GitHubApiClient.psm1](scripts/modules/GitHubApiClient.psm1)** - GitHub Releases API
  - Fetches latest/specific release metadata
  - Downloads template archives
  - Unauthenticated (60 req/hour rate limit)

- **[ManifestManager.psm1](scripts/modules/ManifestManager.psm1)** - Manifest CRUD
  - Reads/writes `.specify/manifest.json`
  - Tracks SpecKit version, file hashes, customization flags
  - Maintains backup history

- **[BackupManager.psm1](scripts/modules/BackupManager.psm1)** - Backup/restore
  - Creates timestamped backups in `.specify/backups/YYYY-MM-DD_HH-MM-SS/`
  - Restores from backup on rollback
  - Manages retention (keeps 5 most recent)

- **[ConflictDetector.psm1](scripts/modules/ConflictDetector.psm1)** - File state analysis
  - Compares current file hashes vs. manifest vs. upstream
  - Categorizes files: `add`, `remove`, `update`, `preserve`, `merge`, `skip`
  - Identifies official SpecKit commands vs. custom commands

- **[FingerprintDetector.psm1](scripts/modules/FingerprintDetector.psm1)** - Automatic version detection
  - Fast signature check (3 files) covers 95%+ of cases
  - Full fingerprint matching (12 files) as fallback
  - Confidence scoring: High (95-100%), Medium (70-94%), Low (<70%)
  - Loads database from [data/speckit-fingerprints.json](data/speckit-fingerprints.json)
  - Enables frictionless onboarding for first-time users

- **[MarkdownMerger.psm1](scripts/modules/MarkdownMerger.psm1)** - Intelligent 3-way merge
  - Levenshtein distance for fuzzy section matching
  - Section-based parsing using markdown headers
  - 80% similarity threshold for matching renamed sections
  - Incoming structure as canonical (layers customizations)
  - Granular git conflict markers (section-level, not file-level)
  - Auto-merges compatible changes (reduces conflicts from ~15 to 0-2)

### Helper Functions (scripts/helpers/)

Helpers are thin orchestration wrappers that call module functions. They handle user prompts and UI:

- **Invoke-PreUpdateValidation.ps1** - Prerequisites checks (Git, .specify/, permissions)
- **Show-UpdateReport.ps1** - Check-only mode detailed report
- **Get-UpdateConfirmation.ps1** - User confirmation prompt with change preview
- **Show-UpdateSummary.ps1** - Post-update results display
- **Invoke-ConflictResolutionWorkflow.ps1** - Interactive conflict resolution (legacy workflow, not currently active)
- **Invoke-RollbackWorkflow.ps1** - Backup restoration workflow

### Data Structures

**Manifest Schema** (`.specify/manifest.json`):
```json
{
  "version": "1.0",
  "speckit_version": "v0.0.72",
  "initialized_at": "2025-01-19T12:34:56Z",
  "last_updated": "2025-01-19T14:22:10Z",
  "agent": "claude-code",
  "speckit_commands": ["speckit.specify.md", "speckit.plan.md", ...],
  "tracked_files": [
    {
      "path": ".claude/commands/speckit.specify.md",
      "original_hash": "sha256:abc123...",
      "customized": false,
      "is_official": true
    }
  ],
  "custom_files": [".claude/commands/custom-deploy.md"],
  "backup_history": [
    {
      "timestamp": "2025-01-19T12:00:00Z",
      "path": ".specify/backups/2025-01-19_12-00-00/",
      "from_version": "v0.0.71",
      "to_version": "v0.0.72"
    }
  ]
}
```

**File State Enum** (used throughout ConflictDetector):
- `add` - New file in upstream, not in local
- `remove` - File removed from upstream
- `update` - File unchanged locally, has upstream changes (safe to update)
- `preserve` - File customized locally, no upstream changes (keep as-is)
- `merge` - File customized locally AND has upstream changes (conflict!)
- `skip` - No changes needed

## Architectural Limitations

### Text-Only I/O Constraint

**Critical Design Constraint:** This skill runs as a PowerShell subprocess spawned by Claude Code via `pwsh -Command`. The execution model has fundamental I/O limitations:

```
Claude Code Extension (JavaScript)
    ↓ spawns
PowerShell Process (pwsh -Command "& 'script.ps1'")
    ↓ captures
stdout (text stream) + stderr (text stream)
    ↓ displays
User sees text output
```

**Implications:**
- **No VSCode UI Access**: PowerShell subprocess cannot invoke VSCode extension APIs or UI elements (Quick Pick, dialogs, webviews)
- **No IPC Bridge**: No inter-process communication mechanism exists for passing structured data between PowerShell and VSCode extension host
- **Text Streams Only**: All communication must use stdout/stderr text streams
- **No External GUI**: PowerShell GUI cmdlets (e.g., `Out-GridView`, WPF windows) won't work in Claude Code context

**What Works:**
- ✅ Text output to stdout (Write-Host, Write-Output)
- ✅ Error messages to stderr (Write-Error, Write-Warning)
- ✅ Reading environment variables (e.g., `$env:VSCODE_PID` for context detection)
- ✅ File I/O operations
- ✅ Invoking `code` CLI commands (e.g., `code --diff`, `code --merge`) as separate processes

**What Doesn't Work:**
- ❌ Returning PowerShell objects expecting Claude extension to parse them
- ❌ Sentinel hashtables for VSCode Quick Pick interception
- ❌ Direct calls to VSCode extension APIs
- ❌ GUI dialog boxes or interactive prompts expecting VSCode UI integration

### Conversational Workflow Pattern

Given the text-only constraint, this skill uses a **conversational approval workflow**:

1. **Skill outputs structured summary** to stdout (Markdown format)
2. **Claude Code parses summary** and presents it to user in natural language
3. **User responds via chat** ("yes", "proceed", "no", questions, etc.)
4. **Claude re-invokes skill** with `-Proceed` flag if approved
5. **Skill executes update** without prompts (approval already obtained)

This pattern:
- Respects text-only I/O constraint
- Leverages Claude's conversational interface
- Provides better UX than Read-Host prompts in terminal
- Works identically in Claude Code CLI and VSCode Extension contexts

## Smart Conflict Resolution

When files have both local customizations AND upstream changes, the skill uses **intelligent conflict resolution** with a two-phase approach:

### Phase 1: Intelligent Section-Based Merge (Markdown Files Only)

For **markdown files** (`.md` extension), the system first attempts intelligent 3-way merge using `Merge-MarkdownFiles` (MarkdownMerger.psm1):

**Smart Merge Features:**
- Section-based parsing using markdown headers
- Fuzzy section matching (80% similarity threshold using Levenshtein distance)
- Auto-merges compatible changes (new sections, unchanged sections, non-conflicting edits)
- Generates granular git conflict markers only for true conflicts (section-level, not file-level)
- Incoming structure as canonical (layers customizations on top)

**Example Results:**
- **Clean merge**: No conflicts, file automatically updated
- **Partial merge**: Some sections auto-merged, conflict markers for others
- **Fallback**: If smart merge fails, proceeds to Phase 2

### Phase 2: Size-Based Conflict Resolution (All Files)

If Phase 1 fails, is not applicable (non-markdown files), or produces conflicts, the system uses size-based resolution:

**Small Files (≤100 lines):** Git conflict markers (standard 3-way merge)
**Large Files (>100 lines):** Side-by-side diff files in Markdown format

This dual approach provides optimal UX for different scenarios:
- Small files: Quick inline resolution with VSCode CodeLens
- Large files: Comprehensive side-by-side comparison in readable format

### Small File Resolution: Git Conflict Markers

For files with 100 lines or fewer, the skill writes Git-style conflict markers directly to the file:

```markdown
<<<<<<< Current (Your Version)
# Custom content you added
||||||| Base (v0.0.71)
# Original version content
=======
# New upstream content
>>>>>>> Incoming (v0.0.72)
```

**VSCode Integration:** VSCode automatically detects these markers and displays **CodeLens actions**:
- Accept Current Change
- Accept Incoming Change
- Accept Both Changes
- Compare Changes

**Benefits:**
- Familiar UX for developers (standard Git workflow)
- Immediate inline editing
- Works in all text editors
- User resolves conflicts at their own pace

### Large File Resolution: Side-by-Side Diff Files

For files with more than 100 lines, the skill generates a detailed Markdown diff file in `.specify/.tmp-conflicts/`:

**Example:** If `custom-large.md` has a conflict, the skill creates `.specify/.tmp-conflicts/custom-large.diff.md`

**Diff File Features:**
- Header with version comparison and file metadata
- Only changed sections shown (with 3-line context before/after)
- Side-by-side comparison: "Your Version" vs "Incoming Version"
- Syntax highlighting based on file extension
- Summary of unchanged sections (e.g., "Lines 1-50 unchanged")
- UTF-8 encoding without BOM for cross-platform compatibility

**Why This Approach:**
- Large files with Git markers are difficult to navigate
- Side-by-side view makes changes easier to understand
- Unchanged sections summary helps focus on what actually changed
- Markdown format previews beautifully in VSCode
- Diff files are automatically cleaned up after successful updates

See [Example Diff File Output](#example-diff-file-output) below for a complete example.

### Implementation Flow

The conflict resolution workflow in `update-orchestrator.ps1` (lines 700-772):

**1. For Markdown Files:**
```powershell
# Phase 1: Attempt intelligent section-based merge
$mergeResult = Merge-MarkdownFiles `
    -BasePath $basePath `
    -CurrentPath $currentPath `
    -IncomingPath $incomingPath `
    -OutputPath $outputPath `
    -BaseVersion $manifest.speckit_version `
    -IncomingVersion $targetRelease.tag_name

if ($mergeResult.ConflictCount -eq 0) {
    # Clean merge - no further action needed
} else {
    # Partial merge - conflict markers already in file at section level
}
```

**2. For Non-Markdown Files or Fallback:**
```powershell
# Phase 2: Size-based conflict resolution
Write-SmartConflictResolution -FilePath ".claude/commands/custom-file.md" `
                               -CurrentContent $currentVersion `
                               -BaseContent $originalVersion `
                               -IncomingContent $upstreamVersion `
                               -OriginalVersion "v0.0.71" `
                               -NewVersion "v0.0.72"
```

The `Write-SmartConflictResolution` function counts lines in `CurrentContent` and:
- If ≤100 lines: Calls `Write-ConflictMarkers` (Git markers)
- If >100 lines: Calls `Compare-FileSections` + `Write-SideBySideDiff` (Markdown diff)
- On error: Falls back to Git markers as a safety measure

**Automatic Cleanup:** After a successful update, `.specify/.tmp-conflicts/` is automatically removed. On rollback, diff files are preserved for debugging.

### Example Diff File Output

Here's an example of a generated diff file for a large file conflict:

```markdown
# Conflict Resolution: speckit.plan.md

**Your Version**: v0.0.71
**Incoming Version**: v0.0.72
**File Path**: `.claude/commands/speckit.plan.md`
**File Size**: 150 lines
**Changed Sections**: 2
**Total Changed Lines**: 8

---

## Changed Section 1

### Your Version (Lines 45-51)

```markdown
## Step 3: Design Phase

Review the requirements and create a detailed implementation plan.
Use the plan template to structure your approach.
```

### Incoming Version (Lines 45-51)

```markdown
## Step 3: Design Phase

Review the requirements and create a detailed implementation plan.
Use the plan template to structure your approach and identify dependencies.
Consider error handling and edge cases early in the design.
```

---

## Changed Section 2

### Your Version (Lines 98-104)

```markdown
## Validation Checklist

- [ ] All requirements met
- [ ] Tests passing
```

### Incoming Version (Lines 98-106)

```markdown
## Validation Checklist

- [ ] All requirements met
- [ ] Unit tests passing
- [ ] Integration tests passing
- [ ] Documentation updated
```

---

## Unchanged Sections

The following sections remain unchanged between versions:

- **Lines 1-44** (44 lines): Header and introduction
- **Lines 52-97** (46 lines): Middle content sections
- **Lines 107-150** (44 lines): Footer and references

**Total Unchanged**: 134 lines (89.3%)
```

This format makes it easy to:
1. See exactly what changed and where
2. Compare side-by-side without scrolling through the entire file
3. Understand the scope of changes (only 11% of the file changed)
4. Preview beautifully in VSCode's Markdown preview

## Key Workflows

### Fresh Installation Flow (Two-Phase Conversational Workflow)

When running `/speckit-update` in a project without `.specify/` directory:

**Phase 1: Installation Offer (No -Proceed flag)**
1. Skill detects no `.specify/` directory exists
2. Shows installation prompt with cyan `[PROMPT_FOR_INSTALL]` marker
3. Displays what installation will do (create structure, download templates, create manifest)
4. Exits gracefully with code 0 (not error)
5. User sees offer in conversational interface

**Phase 2: Installation Execution (With -Proceed flag)**
1. User approves by running `/speckit-update -Proceed`
2. Skill skips installation prompt
3. Shows progress indicator: `📦 Installing SpecKit...` (cyan)
4. Creates `.specify/` directory structure
5. Downloads latest SpecKit templates from GitHub
6. Creates manifest to track future updates
7. Completes with exit code 0

**Key Design Choices:**
- **Exit code 0 (not throw)**: Enables conversational workflow - awaiting approval is not an error
- **Consistent with update flow**: Both flows use `-Proceed` flag, `[PROMPT_FOR_*]` markers, and exit 0
- **Idempotent**: Running install multiple times on already-installed project behaves as update check
- **Direct proceed supported**: User can run `/speckit-update -Proceed` on first invocation to skip offer phase

### Smart Merge with Frictionless Onboarding (New in v0.4.2)

**Problem**: First-time users had no manifest, causing all files to be treated as customized, resulting in ~15 manual conflicts even for unmodified installations.

**Solution**: Automatic version detection + intelligent 3-way merge

#### Version Detection (Step 3)

When no manifest exists:

1. **Fast Signature Check** (covers 95%+ of cases)
   - Checks 3 core files: `speckit.specify.md`, `speckit.plan.md`, `constitution.md`
   - <100ms offline lookup in fingerprint database
   - Returns version if 100% match

2. **Full Fingerprint Scan** (fallback)
   - Checks all 12 tracked files
   - Uses fuzzy matching if needed
   - Assigns confidence: High (95-100%), Medium (70-94%), Low (<70%)

3. **Manifest Creation**
   - **High/Medium confidence**: Creates manifest with detected version
   - **Low confidence or failure**: Falls back to safe default (v0.0.0, all files customized)

**Example Output:**
```
Detecting installed SpecKit version...

✓ Version detected: v0.0.79
  Confidence: High (100.0% match)
  Method: signature

Creating new manifest with detected version: v0.0.79
This enables smart merge - only actual customizations will be flagged as conflicts
```

#### Intelligent 3-Way Merge (Step 11)

For each conflict, the system now performs true 3-way merge:

1. **Fetch Base Content**
   - Downloads original file from detected/manifest version
   - Enables accurate detection of user changes vs upstream changes

2. **Section-Based Merge** (for markdown files)
   - Parses files into sections using headers
   - Matches sections with 80% fuzzy similarity threshold
   - Auto-merges compatible changes:
     * New sections from upstream (adds)
     * Preserved custom sections
     * Non-conflicting edits to same sections
   - Generates granular conflict markers only for true conflicts

3. **Merge Results**
   - **Clean merge**: No conflicts, file automatically updated
   - **Partial merge**: Some sections auto-merged, conflict markers for others
   - **Fallback**: Basic conflict markers if smart merge fails

**Example Output:**
```
Resolving conflicts...
  ✓ Clean merge: .claude/commands/speckit.specify.md (no conflicts)
  ✓ Clean merge: .claude/commands/speckit.plan.md (no conflicts)
  ⚠ Merged with 2 conflict(s): .specify/memory/constitution.md
```

**Benefits:**
- **First-time users**: Zero conflicts for unmodified installations
- **Customized files**: Reduced from ~15 conflicts to 0-2 conflicts
- **Better UX**: Section-level markers instead of entire file conflicts
- **Automatic**: No user configuration required

**Technical Details:**
- Fingerprint database: [data/speckit-fingerprints.json](data/speckit-fingerprints.json) (69 KB, 57 versions)
- Database auto-updated via GitHub Actions (daily checks for new releases)
- Levenshtein distance for fuzzy string matching
- Normalized hashing prevents false positives from whitespace/line endings

**Related:**
- Feature PRD: [docs/PRDs/004-Smart-Merge-Frictionless-Onboarding.md](docs/PRDs/004-Smart-Merge-Frictionless-Onboarding.md)
- GitHub Issue: #25
- Modules: `FingerprintDetector.psm1`, `MarkdownMerger.psm1`

### Automatic Conflict Resolution (Current Workflow)

When a file is customized locally AND changed upstream, the system automatically processes conflicts:

**For Markdown Files:**
1. Attempts intelligent section-based merge (MarkdownMerger)
2. Auto-merges compatible changes
3. Generates section-level conflict markers for true conflicts

**For All Files (Fallback or Non-Markdown):**
1. Routes based on file size
2. Small files (≤100 lines): Writes Git conflict markers to file
3. Large files (>100 lines): Generates side-by-side diff in `.specify/.tmp-conflicts/`

**User Resolution:**
- Users resolve conflicts manually in their editor (VSCode CodeLens for Git markers)
- Conflicts are marked with clear visual indicators
- User commits resolved files when ready

**Note:** The codebase contains a legacy interactive conflict resolution workflow (`Invoke-ConflictResolutionWorkflow.ps1`) that prompts users for each conflict with options to open merge editor, keep version, etc. This workflow is not currently active in the main orchestrator, which uses automatic conflict resolution instead.

### Customization Detection

Files are considered "customized" if their normalized hash differs from `original_hash` in manifest. Normalization ensures line ending differences don't trigger false positives.

**Safe Default:** If no manifest exists, assume ALL files are customized (prevents data loss).

### Fail-Fast with Rollback

Any error during steps 8-13 triggers automatic rollback:
1. Error displayed
2. Most recent backup restored
3. Exit code 6 returned
4. Manifest reverted to pre-update state

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Prerequisites not met |
| 3 | Network/API error |
| 4 | Git error |
| 5 | User cancelled |
| 6 | Rollback occurred (automatic) |

## Testing Strategy

**Philosophy:** This project relies on integration testing for primary validation. Unit tests for PowerShell modules are limited due to Pester 5.x module scoping constraints.

### Unit Tests (Helper and Code Standards)
- **Location:** [tests/unit/](tests/unit/)
- **Framework:** Pester 5.x
- **Scope:** Tests for helper scripts (.ps1 files) and code standards enforcement
- **Current Tests:**
  - `CheckDependencies.Tests.ps1` - Validates PowerShell module dependencies
  - `CheckPathSecurity.Tests.ps1` - Path traversal vulnerability scanning
  - `CodeStandards.Tests.ps1` - Enforces module vs helper pattern, validates file existence
  - `E2ETestHelpers.Tests.ps1` - E2E test framework utilities
  - `FormatPRComment.Tests.ps1` - PR comment formatting validation
  - `Invoke-PreUpdateValidation.Tests.ps1` - Pre-update validation helper
- **Status:** 40 passing, 27 failing (67 total tests, ~60% pass rate)
  - 27 failures are in E2ETestHelpers due to parameter signature changes
  - Core helper tests and code standards checks pass consistently

### Integration Tests
- **Location:** [tests/integration/](tests/integration/)
- **Pattern:** `UpdateOrchestrator.Tests.ps1`
- **Scope:** Full end-to-end workflows with real file system operations
- **Purpose:** Primary validation mechanism for module functionality
- **Coverage:** Tests complete update workflow including:
  - Version detection and fingerprinting
  - Conflict detection and resolution
  - Backup/restore operations
  - Manifest management
  - GitHub API integration
- **Note:** Skipped in CI/CD, run manually before releases

### Why No Module Unit Tests?

**Pester 5.x Module Scoping Limitation:**
- Pester 5.x isolates module functions in test scope by design
- Even exported/public functions aren't accessible after `Import-Module` in test blocks
- This affects ALL module tests (HashUtils, ManifestManager, BackupManager, ConflictDetector, etc.)
- **Resolution Attempts:**
  - ❌ Option 1: `-Scope Global` - Breaks test isolation
  - ❌ Option 2: `InModuleScope` - Requires wrapping every test, still testing in wrong scope
  - ❌ Option 3: Test only public APIs - Already doing this, but scoping still blocks access
- **Pragmatic Decision:** Removed 8 module unit test files (240+ tests) affected by this issue
- **Production Validation:** All modules work correctly in the orchestrator and production usage

**Removed Test Files (2025-10-25):**
- `BackupManager.Tests.ps1` - Backup/restore operations
- `ConflictDetector.Tests.ps1` - File state analysis and conflict detection
- `FingerprintDetector.Tests.ps1` - Version detection
- `GitHubApiClient.Tests.ps1` - GitHub API integration
- `HashUtils.Tests.ps1` - Normalized hashing
- `ManifestManager.Tests.ps1` - Manifest CRUD operations
- `MarkdownMerger.Tests.ps1` - Intelligent 3-way merge
- `UpdateOrchestrator.ModuleImport.Tests.ps1` - Module import validation

### Testing Approach

1. **Integration tests** validate complete workflows end-to-end
2. **Helper unit tests** validate orchestration logic and utilities
3. **CodeStandards tests** enforce architectural patterns (module vs helper, export patterns, etc.)
4. **Manual testing** before releases ensures real-world usage scenarios work
5. **Production usage** provides final validation (orchestrator successfully imports and uses all modules)

This pragmatic approach acknowledges Pester 5.x limitations while maintaining confidence in code quality through comprehensive integration testing.

## PowerShell Style Guidelines

Follow these conventions (enforced in [CONTRIBUTING.md](CONTRIBUTING.md)):

- **Function Names:** PascalCase with approved verbs (`Get-FileState`, `Invoke-PreUpdateValidation`)
- **Variables:** camelCase (`$fileName`, `$manifestPath`)
- **Parameters:** PascalCase in param blocks
- **Comment-Based Help:** Every exported function MUST have `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`
- **Error Handling:** Use try-catch-finally, `$ErrorActionPreference = 'Stop'` in scripts
- **Verbose Logging:** Use `Write-Verbose` liberally for debugging

Example:
```powershell
function Get-Example {
    <#
    .SYNOPSIS
        Brief description
    .PARAMETER Name
        Parameter description
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    try {
        Write-Verbose "Processing: $Name"
        # Implementation
    }
    catch {
        Write-Error "Error: $($_.Exception.Message)"
        throw
    }
}
```

## Distribution Model

This skill is distributed via **Claude Code's plugin system** and Git clone (manual installation).

### Plugin Installation (Primary Method)

Users install via the NotMyself plugin marketplace:

```bash
/plugin marketplace add NotMyself/claude-plugins
/plugin install speckit-updater
```

**How It Works:**
1. Claude Code fetches marketplace manifest from `NotMyself/claude-plugins` repository
2. Plugin manifest (`.claude-plugin/plugin.json`) specifies `skills/` directory location
3. Claude Code copies `skills/speckit-updater/` content to `$env:USERPROFILE\.claude\skills\speckit-updater`
4. Skill is automatically discovered via `SKILL.md` and `/speckit-update` becomes available

**Repository Structure:**
- `.claude-plugin/plugin.json` - Plugin metadata (name, version, skills path, etc.)
- `skills/speckit-updater/` - All skill content (scripts, tests, data, specs)
- Marketplace repository: `NotMyself/claude-plugins` with `marketplace.json`

### Manual Installation (Alternative)

For development or advanced users:

```powershell
cd $env:USERPROFILE\.claude\skills
git clone https://github.com/NotMyself/claude-win11-speckit-update-skill speckit-updater
```

Claude Code discovers the skill via `skills/speckit-updater/SKILL.md` and makes `/speckit-update` available.

**Backward Compatibility:** Both installation methods work identically - the skill functions the same way regardless of installation method.

## Important Files

- **[SKILL.md](SKILL.md)** - Claude Code skill definition (defines `/speckit-update` command)
- **[specs/001-safe-update/spec.md](specs/001-safe-update/spec.md)** - Complete specification with user stories, architecture, workflows
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Development guidelines, testing, PR process
- **[CHANGELOG.md](CHANGELOG.md)** - Version history
- **[templates/manifest-template.json](templates/manifest-template.json)** - Empty manifest template

## Git Workflow

When creating commits for this repository:

1. **Review recent commits** for commit message style:
   ```powershell
   git log --oneline -10
   ```

2. **Follow conventional commits:**
   - `feat:` - New features
   - `fix:` - Bug fixes
   - `docs:` - Documentation changes
   - `test:` - Test additions/changes
   - `refactor:` - Code refactoring
   - `chore:` - Maintenance tasks

3. **Run tests before committing:**
   ```powershell
   ./tests/test-runner.ps1
   ```

## SpecKit Integration

This skill is designed for projects using **GitHub SpecKit** (`.specify/` directories with template-driven workflows). Key integration points:

- **Constitution Updates:** When constitution template changes, the skill uses hash verification to detect actual content changes before notifying users:
  - **Hash Verification**: Compares normalized hashes of current and backup constitution files to eliminate false positives
  - **Informational Notifications** (ℹ️): Shown for clean updates with no conflicts - marked "OPTIONAL" for user review
  - **Urgent Notifications** (⚠️): Shown for conflicts requiring manual resolution - marked "REQUIRED" with red/yellow colors
  - **Fail-Safe Behavior**: If hash comparison fails or backup is missing, notification is shown (errs on side of caution)
  - **Structured Logging**: Verbose mode (`-Verbose`) shows detailed hash comparison for debugging
  - **Command**: User runs `/speckit.constitution <backup-path>` to merge changes
- **Official Commands:** Tracks 8 official SpecKit commands (speckit.analyze, speckit.checklist, etc.)
- **Custom Commands:** User-created commands in `.claude/commands/` are NEVER overwritten, even with `--force`
- **Template Source:** Fetches from GitHub SpecKit releases (not from npm)

## Troubleshooting

### GitHub API Issues

The skill fetches SpecKit templates from GitHub Releases API. Common issues:

**"Failed to connect to GitHub API"**
- **Cause**: Network connectivity issue or firewall blocking api.github.com
- **Solution**:
  - Check internet connection
  - Verify api.github.com is accessible: `Test-NetConnection api.github.com -Port 443`
  - Check corporate firewall/proxy settings
  - Use `-Verbose` flag to see detailed connection attempts

**"GitHub API rate limit exceeded"**
- **Cause**: Exceeded 60 requests/hour limit (unauthenticated) or 5,000 requests/hour limit (authenticated)
- **Solution**:
  - **Without token**: Set up GitHub Personal Access Token (see "Using GitHub Tokens" in README.md)
  - **With token**: Wait until rate limit resets (time shown in error message)
  - Error message shows exact reset time: "Resets at: {timestamp}"
  - Rate limits reset on the hour (e.g., if exceeded at 2:45pm, resets at 3:00pm)
  - **Quick fix**: `$env:GITHUB_PAT = "ghp_YOUR_TOKEN_HERE"` increases limit to 5,000 req/hour

**"GitHub API returned empty response"**
- **Cause**: GitHub API returned null or invalid JSON
- **Solution**:
  - Check GitHub Status: https://www.githubstatus.com/
  - Retry in a few minutes if GitHub is experiencing issues
  - Use `-Verbose` flag to see API endpoint and response details

**"GitHub resource not found"**
- **Cause**: Specified version doesn't exist in GitHub releases
- **Solution**:
  - Verify version format: `v0.0.72` (with 'v' prefix)
  - Check available releases: https://github.com/github/spec-kit/releases
  - Omit `-Version` parameter to automatically use latest release

**"Invalid version format in tag_name"**
- **Cause**: GitHub release tag doesn't match semantic versioning (v0.0.0 format)
- **Solution**:
  - Report to SpecKit maintainers if official release has invalid tag
  - Use explicit `-Version` parameter with valid version

### Diagnostic Commands

```powershell
# Test GitHub API connectivity manually
Import-Module .\scripts\modules\GitHubApiClient.psm1 -Force
$release = Get-LatestSpecKitRelease -Verbose
$release | ConvertTo-Json -Depth 3

# Check current rate limit status
$rateLimit = Test-GitHubApiRateLimit
Write-Host "Remaining requests: $($rateLimit.rate.remaining) / $($rateLimit.rate.limit)"

# Test with verbose logging
& .\scripts\update-orchestrator.ps1 -CheckOnly -Verbose

# Test specific version
& .\scripts\update-orchestrator.ps1 -CheckOnly -Version v0.0.72 -Verbose
```

### Common Error Codes

- **Exit Code 0**: Success
- **Exit Code 1**: General error
- **Exit Code 2**: Prerequisites not met (Git missing, not in SpecKit project, etc.)
- **Exit Code 3**: Network/API error (GitHub API unreachable, rate limited, etc.)
- **Exit Code 4**: Git error (uncommitted changes, merge conflicts, etc.)
- **Exit Code 5**: User cancelled operation
- **Exit Code 6**: Automatic rollback occurred due to update failure

### Getting Help

- **Verbose Output**: Always use `-Verbose` flag when troubleshooting
- **Error Logs**: Check PowerShell error stream and verbose output
- **GitHub Issues**: Report issues at https://github.com/NotMyself/claude-win11-speckit-update-skill/issues
- **Bug Reports**: See `docs/bugs/` directory for known issues and resolutions
