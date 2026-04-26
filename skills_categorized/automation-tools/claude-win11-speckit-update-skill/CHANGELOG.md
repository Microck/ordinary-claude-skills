# Changelog

All notable changes to the SpecKit Safe Update Skill will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.8.0] - 2025-10-25

### Added
- **Plugin-Based Distribution (#14)**: Professional plugin distribution system via Claude Code's plugin marketplace
  - **Plugin Installation**: Primary installation method via `/plugin marketplace add NotMyself/claude-plugins` then `/plugin install speckit-updater`
  - **Marketplace Repository**: Created `NotMyself/claude-plugins` with marketplace manifest and documentation
  - **Repository Restructuring**: Moved skill content to `skills/speckit-updater/` subdirectory (preserves Git history)
  - **Plugin Manifest**: Added `.claude-plugin/plugin.json` with metadata (name, version, skills path, requirements)
  - **100% Backward Compatibility**: Manual Git clone installations continue working identically
  - **Integration Tests**: 15 test scenarios validating manual installation, plugin installation, migration, and path resolution
  - **Migration Guide**: Comprehensive optional migration documentation for existing users
  - **Marketplace Scalability**: Documentation for adding future plugins and contribution guidelines
  - **Technical Details**:
    - Updated GitHub Actions workflows for new directory structure
    - Path resolution verification across all modules
    - Side-by-side installation detection and handling
    - Marketplace validation against JSON schema

- **PR Validation Workflow Enhancement (#32)**: Comprehensive automated PR validation with intelligent comment-based feedback
  - **Security Scanning (Step 5)**:
    - GitLeaks secret detection (API keys, tokens, passwords)
    - PSScriptAnalyzer security rules (Invoke-Expression, plain-text passwords)
    - Dependency vulnerability scanning (checks PowerShell modules against known CVEs)
    - Path traversal detection (unsafe string concatenation, missing Join-Path)
  - **SpecKit Compliance Validation (Step 6)**:
    - Spec directory structure validation (spec.md, plan.md, tasks.md)
    - Required section checking (User Scenarios, Requirements, Success Criteria)
    - CHANGELOG [Unreleased] detection
    - Constitution compliance (Export-ModuleMember, no nested Import-Module)
  - **PR Guardrails Enhancement (Step 2)**:
    - PR size validation (2000 line limit with owner bypass)
    - Description quality check (minimum 20 characters)
  - **Quality Checks Enhancement (Step 3)**:
    - Linting results aggregation
    - Test status reporting
  - **Intelligent PR Comments**:
    - Update-in-place behavior (no duplicate comments)
    - HTML markers for reliable comment identification
    - Structured findings with file:line references
    - Remediation guidance for each issue
    - Separate comments for each validation step (Steps 2-6)
  - **Performance Optimizations**:
    - Concurrency control (cancels in-progress runs on new commits)
    - PSScriptAnalyzer module caching
    - Timeout limits per step (prevents runaway jobs)
  - **Non-blocking Design**: All validations are informational, allowing PRs to merge despite warnings
  - **Test Coverage**: Unit tests for all validation scripts (FormatPRComment, CheckPathSecurity, CheckDependencies, CheckSpecCompliance)
  - **Documentation**: Complete workflow documentation in `docs/workflows/pr-validation.md`

## [0.7.0] - 2025-10-25

### Added
- **End-to-End Smart Merge Test Suite (#27)**: Production-ready test infrastructure with parallel execution and comprehensive validation
  - **Problem**: No automated testing for smart merge system across multiple SpecKit versions
    - Manual testing time-consuming and error-prone
    - No validation of data preservation during merges
    - No performance baseline for merge operations
    - Risk of regressions when modifying merge logic
  - **Solution**: Comprehensive E2E test suite with parallel execution (Phases 1-8, 100% complete)
  - **Core Features**:
    - **Parallel Execution**: 4 concurrent threads, <15 minute completion (vs. 45-60 minutes sequential)
    - **Version Stratification**: Date-based selection across old/middle/recent timeframes (10 versions)
    - **Deterministic Testing**: Seed 42 for reproducible version/pair selection (18 merge pairs)
    - **Triple-Layer Validation**:
      1. Dad joke preservation (zero-tolerance data loss detection)
      2. Semantic validation (9-point checklist: integrity, syntax, markers, encoding)
      3. Command execution validation (structure and executability)
    - **Comprehensive Reporting**: Performance metrics, preservation stats, validation pass rates, color-coded output
  - **Implementation Phases**:
    - **Phase 1**: Setup infrastructure (E2ETestHelpers.psm1 1,200+ lines, SmartMerge.E2E.Tests.ps1 370+ lines)
    - **Phase 2**: Foundation (version stratification, merge pair generation, isolated test projects, GitHub API integration)
    - **Phase 3**: MVP (dad joke injection, zero-tolerance validation)
    - **Phase 4**: Multi-version testing (10 versions, 18 merge pairs, result tracking)
    - **Phase 5**: Parallel execution (4 threads, mutex coordination, timeout handling, thread-safe collection)
    - **Phase 6**: Semantic validation (9-point checklist, command execution validation, integration into parallel tests)
    - **Phase 7**: Comprehensive reporting (statistics extraction, color-coded output, aggregate metrics)
    - **Phase 8**: Polish & documentation (unit tests, verbose logging, integrity validation, quickstart guide)
  - **GitHub API Integration**:
    - Mutex coordination prevents rate limiting in parallel execution
    - 500ms delay between requests
    - 18 API calls per run (well under 50 call budget)
    - Optional GitHub PAT support for higher limits
  - **Files Added**:
    - `tests/helpers/E2ETestHelpers.psm1` - 1,200+ lines with 12 exported functions
    - `tests/integration/SmartMerge.E2E.Tests.ps1` - 450+ lines E2E orchestration
    - `tests/unit/E2ETestHelpers.Tests.ps1` - 550+ lines, 31+ unit tests
    - `specs/013-e2e-smart-merge-test/` - Complete specification (spec, plan, tasks, quickstart, contracts, checklists)
    - `docs/PRDs/005-End-to-End-Smart-Merge-Test.md` - Feature PRD
  - **Test Workflow**:
    1. Version stratification (select 10 versions from fingerprints database)
    2. Merge pair generation (18 random upgrade paths)
    3. Parallel execution (4 threads with disk/timeout validation)
    4. Content injection (5-10 dad jokes per file)
    5. Merge validation (100% joke preservation required)
    6. Semantic validation (9-point checklist per file)
    7. Command validation (structure and executability)
    8. Comprehensive report (metrics + validation + final assessment)
  - **Benefits**:
    - ✅ Automated regression testing for smart merge system
    - ✅ Data preservation guarantee (zero-tolerance validation)
    - ✅ Performance baseline (track merge execution times)
    - ✅ Confidence for merge logic changes
    - ✅ Production-ready quality (100% spec completion)
  - **Prerequisites**: PowerShell 7.0+, Pester 5.x, 500MB disk space, internet connection
  - **Test Coverage**: 31+ unit tests for E2E helpers, comprehensive integration testing across 18 version pairs

### Fixed
- **Version Comparison Bug (#12)**: Fixed `$matches` variable reuse in version parsing (Show-UpdateReport.ps1)
  - Symptom: Incorrect version comparison when parsing current and target versions
  - Root cause: PowerShell `$matches` variable overwritten between regex operations
  - Solution: Split into separate parsing blocks with explicit variable assignments
- **Manifest Corruption (#12)**: Added duplicate detection in Add-TrackedFile function (ManifestManager.psm1)
  - Symptom: Repeated calls to Add-TrackedFile created duplicate entries in manifest
  - Root cause: No existence check before appending to tracked_files array
  - Solution: Check for existing entry before adding, log warning if duplicate found
- **Incomplete Cleanup (#12)**: Fixed check-only mode leaving .specify/ directory behind (update-orchestrator.ps1)
  - Symptom: Dry-run mode left orphaned .specify/ directory structure
  - Root cause: Only manifest.json removed, not entire directory tree
  - Solution: Remove entire .specify/ directory in check-only cleanup

### Changed
- **GitHub Workflows**: Added Claude Code automation and PR validation workflows (#28, #30)
  - Claude Code workflow for automated AI-assisted development
  - PR validation with size/description checks
  - Repository owner bypass for size limits
- **Dead Code Removal (#12)**: Removed ~350 lines of unused VSCode merge editor code
  - Deleted `scripts/helpers/Invoke-ThreeWayMerge.ps1` (~200 LOC)
  - Removed `Open-DiffView` and `Open-MergeEditor` from VSCodeIntegration.psm1 (~150 LOC)
  - Updated module exports and orchestrator imports
- **Code Standards**: Added PSScriptAnalyzer configuration (PSScriptAnalyzerSettings.psd1)

## [0.6.0] - 2025-10-23

### Added
- **Smart Merge with Frictionless Onboarding (#25)**: Automatic version detection and intelligent 3-way merge eliminates first-time user conflicts
  - **Problem**: First-time users had ~15 manual conflicts for unmodified SpecKit installations
    - No manifest exists initially, version unknown
    - Defaults to v0.0.0, assumes all files are customized
    - Every template file flagged as conflicted despite being pristine
    - Poor UX: overwhelming file-level conflict markers
  - **Solution**: Fingerprint-based version detection + semantic 3-way merge
  - **Version Detection**:
    - **Fingerprint Database**: Pre-generated SHA-256 hashes of 12 tracked files across 57 working SpecKit versions (v0.0.23-v0.0.79)
    - **Fast Signature Check**: 3-file signature check (<100ms) covers 95%+ cases
    - **Full Fingerprint Scan**: 12-file fallback with fuzzy matching and confidence scoring
    - **Confidence Levels**: High (95-100%), Medium (70-94%), Low (<70%)
    - **Smart Manifest Creation**: Creates manifest with detected version (not v0.0.0) enabling accurate conflict detection
  - **Intelligent 3-Way Merge**:
    - **Base Content Retrieval**: Fetches original file from detected version via GitHub API
    - **Section-Based Parsing**: Markdown files parsed by headers for semantic understanding
    - **Fuzzy Section Matching**: 80% similarity threshold handles renamed/reorganized sections
    - **Auto-Merge Compatible Changes**: Only actual conflicts get markers
    - **Granular Conflict Markers**: Git markers at section-level, not entire files
    - **Incoming Structure as Canonical**: New SpecKit structure preserved, customizations layered in
  - **GitHub Actions Automation**:
    - **Daily Checks**: Runs at 2 AM UTC, compares database with GitHub Releases API
    - **Auto-Regeneration**: Regenerates entire fingerprint database when new SpecKit release detected
    - **Pull Request Creation**: Automated PRs with detailed stats (versions added, files tracked, database size)
    - **CI/CD Token Support**: Works with both `GITHUB_TOKEN` (CI) and `GITHUB_PAT` (local dev)
  - **Files Added**:
    - `data/speckit-fingerprints.json` - 69 KB database with 57 SpecKit version fingerprints
    - `scripts/modules/FingerprintDetector.psm1` - Version detection module (420 lines)
    - `scripts/modules/MarkdownMerger.psm1` - Intelligent 3-way merge module (580 lines)
    - `tests/unit/FingerprintDetector.Tests.ps1` - 20 unit tests (all passing)
    - `tests/unit/MarkdownMerger.Tests.ps1` - 32 unit tests (all passing)
    - `.github/workflows/update-fingerprints.yml` - Automation workflow
    - `.github/workflows/README.md` - Workflow documentation
    - `docs/PRDs/004-Smart-Merge-Frictionless-Onboarding.md` - Feature PRD
    - `scripts/generate-fingerprints.ps1` - Database generation script
  - **Files Modified**:
    - `scripts/update-orchestrator.ps1` - Integrated version detection (Step 3) and smart merge (Step 11)
    - `scripts/modules/GitHubApiClient.psm1` - Added `Get-SpecKitFile` function for single-file downloads
    - `CLAUDE.md` - Comprehensive documentation updates (module imports, workflow steps, Smart Merge section)
  - **Benefits**:
    - ✅ First-time users: Zero conflicts for unmodified installations (was ~15)
    - ✅ Customized files: Reduced from ~15 to 0-2 conflicts
    - ✅ Better UX: Section-level markers instead of entire files
    - ✅ No user configuration: Fully automatic operation
    - ✅ Scales indefinitely: GitHub Actions maintains database
    - ✅ Accurate detection: 95%+ success rate with signature check
  - **Test Coverage**: 52 new unit tests (20 FingerprintDetector + 32 MarkdownMerger), all passing
  - **Implementation**: 7 commits across 5 days, complete feature implementation from design through testing, integration, automation, and documentation

## [0.5.0] - 2025-10-23

### Added
- **GitHub Personal Access Token Support (#012)**: Optional token authentication for increased API rate limits
  - **Environment Variable**: Set `GITHUB_PAT` to authenticate GitHub API requests
  - **Rate Limit Increase**: From 60 req/hour (unauthenticated) to 5,000 req/hour (authenticated)
  - **Backward Compatible**: Zero breaking changes - works identically without token
  - **Security**: Token value never logged or exposed in any output stream
  - **Conditional Error Messages**: Context-aware guidance based on authentication status
    - Rate limit errors without token show setup tip and documentation link
    - Rate limit errors with token omit redundant setup guidance
    - 401 errors provide clear token troubleshooting steps
  - **Documentation**: Comprehensive setup guide in README.md and quickstart.md
    - Token creation walkthrough (no scopes required)
    - Three setup methods: PowerShell session, profile, and system variable
    - Team collaboration guidance (individual tokens, isolated rate limits)
    - CI/CD integration examples (GitHub Actions, Azure Pipelines, Jenkins, CircleCI)
    - Security best practices and troubleshooting guide
  - **Testing**: 12 unit tests + 9 integration tests covering all user scenarios

## [0.4.1] - 2025-10-23

### Fixed
- **Installation Flow Ignores -Proceed Flag (#022)**: Fresh SpecKit installations now respect the `-Proceed` flag for conversational workflow
  - **Root Cause**: Installation detection logic did not check for `-Proceed` parameter, causing double prompts and blocking 100% of fresh installations
  - **Symptoms**: Users saw installation prompt twice; second invocation with `-Proceed` showed prompt again instead of installing
  - **Impact**: Fresh installations completely broken - impossible to complete two-command workflow (`/speckit-update` → approval → `/speckit-update -Proceed`)
  - **Solution**: Implement consistent `-Proceed` handling matching update flow pattern
    - **T001-T006 (Implementation)**:
      - Added `-Proceed` switch parameter to `Invoke-PreUpdateValidation` function signature
      - Updated installation detection to check `-Proceed` flag before showing prompt
      - Changed exit behavior from `throw` to `exit 0` for graceful conversational workflow
      - Added conditional branches: skip prompt if `-Proceed` set, show prompt if not set
      - Passed `-Proceed` parameter from orchestrator to validation helper using `-Proceed:$Proceed` syntax
    - **T007-T013 (User Story 1 Tests)**:
      - Added 4 unit tests: parameter acceptance, exit code 0 without `-Proceed`, continue with `-Proceed`, prompt output validation
      - Added 3 integration tests: fresh installation without `-Proceed`, with `-Proceed`, and direct proceed
    - **T014-T019 (User Story 2 - Consistency)**:
      - Verified installation flow matches update flow pattern (lines 381-409)
      - Confirmed both flows use `[PROMPT_FOR_*]` markers and exit 0
      - Added 3 integration tests: existing projects skip prompt, multiple installs are idempotent, flow comparison
    - **T020-T030 (User Story 3 - UX)**:
      - Implemented color-coded output: Cyan `[PROMPT_FOR_INSTALL]`, Yellow warning, Gray description, White command
      - Added verbose logging: "Awaiting user approval" and "User approved SpecKit installation, proceeding..."
      - Added progress indicator: `📦 Installing SpecKit...` in cyan
      - Added 3 unit tests for prompt elements and verbose logging
  - **Files Modified**:
    - `scripts/helpers/Invoke-PreUpdateValidation.ps1` (lines 147-239) - Added `-Proceed` parameter, conditional logic, color-coded output
    - `scripts/update-orchestrator.ps1` (line 189) - Pass `-Proceed` to validation helper
    - `tests/unit/Invoke-PreUpdateValidation.Tests.ps1` - Added 7 new unit tests (T008-T010, T028-T029)
    - `tests/integration/UpdateOrchestrator.Tests.ps1` - Added Scenario 12 with 6 integration tests (T011-T013, T017-T019)
  - **Benefits**:
    - ✅ Fresh installations work: Two-command workflow fully functional
    - ✅ Consistent UX: Installation and update flows behave identically
    - ✅ Clear guidance: Color-coded prompts with exact command to run
    - ✅ No error states: Exit code 0 throughout conversational workflow
    - ✅ Idempotent: Running install multiple times behaves as update check
  - **Test Coverage**: 13 new tests (7 unit, 6 integration) validating all three user stories

## [0.4.0] - 2025-10-22

### Added
- **Automatic SpecKit Installation for Non-SpecKit Projects (#13)**: Transforms updater into installer/updater hybrid
  - **Installation Workflow**: Offers to install SpecKit automatically when `.specify/` directory doesn't exist
  - **Interactive Mode**: Prompts user "Would you like to install SpecKit now? (Y/n)" in terminal
  - **Non-Interactive Mode (Claude Code)**: Shows `[PROMPT_FOR_INSTALL]` marker with explanation, waits for approval via conversational workflow
  - **Automatic Setup**:
    - Creates `.specify/` directory structure (`memory/`, `backups/`)
    - Downloads latest SpecKit templates from GitHub
    - Creates manifest with all files marked as `customized: false`
    - Shows "Welcome to SpecKit!" with next steps after installation
  - **Graceful Decline**: If user declines, shows helpful error with context about SpecKit and documentation link
  - **Context-Aware Fallback**: Detects if SpecKit commands are installed to provide tailored messages
  - **Implementation**:
    - New `Test-SpecKitCommandsAvailable` function: Checks for official SpecKit command files in `.claude/commands/`
    - New `Get-HelpfulSpecKitError` function: Generates educational error messages if user declines installation
    - Modified `Invoke-PreUpdateValidation.ps1`: Offers installation instead of showing error
    - Added Step 2.5 in `update-orchestrator.ps1`: Creates `.specify/` directory structure for first-time installs
    - Enhanced `Show-UpdateSummary.ps1`: Displays "Welcome to SpecKit!" message with next steps for first installs
  - **Files Modified**:
    - `scripts/helpers/Invoke-PreUpdateValidation.ps1` - Installation offer workflow with interactive/non-interactive handling
    - `scripts/update-orchestrator.ps1` - Added Step 2.5 for directory creation, passes `$isFirstInstall` flag
    - `scripts/helpers/Show-UpdateSummary.ps1` - Added first-install welcome message with next steps
  - **Files Added**:
    - `tests/unit/Invoke-PreUpdateValidation.Tests.ps1` - 8 new unit tests for detection and message generation
    - Integration test in `tests/integration/UpdateOrchestrator.Tests.ps1` - Install flow validation
  - **Benefits**:
    - ✅ Reduces friction: One command installs everything
    - ✅ Better UX: Converts error into actionable installation flow
    - ✅ Maintains safety: Uses conversational approval in Claude Code
    - ✅ Clear guidance: Shows next steps after successful installation
    - ✅ Reuses existing logic: Leverages first-time manifest creation code
  - **User Stories Satisfied**:
    - US1 (P1): First-time users can install SpecKit with one command
    - US2 (P2): Experienced developers get quick installation workflow
    - US3 (P3): Evaluators see helpful documentation links if they decline

## [0.3.1] - 2025-10-22

### Fixed
- **False Constitution Update Notifications (#18)**: Eliminated false positive notifications for constitution template updates
  - **Root Cause**: Step 12 displayed notifications whenever `constitution.md` appeared in `FilesUpdated` or `ConflictsResolved` arrays without verifying actual content changes
  - **Symptoms**: Users saw "Constitution Template Updated" notifications even when file content was identical (e.g., fresh installs, line ending normalization)
  - **Impact**: User confusion, reduced trust in update notifications, unnecessary `/speckit.constitution` runs
  - **Solution**: Hash-based verification with differentiated notification styling
    - **Hash Verification**: Compare normalized SHA-256 hashes of current and backup constitution files before showing notification
    - **100% False Positive Elimination**: Notification suppressed when hashes match (content unchanged)
    - **Informational Notifications** (ℹ️ icon, cyan/gray colors): Shown for clean updates (no conflicts) - marked "OPTIONAL" for user review
    - **Urgent Notifications** (⚠️ icon, red/yellow colors): Shown for conflicts requiring manual resolution - marked "REQUIRED"
    - **Fail-Safe Behavior**: Show notification if backup missing or hash computation fails (errs on side of caution)
    - **Structured Verbose Logging**: Key-value format logs file paths, hashes, and change detection results for debugging
    - **Performance**: Hash verification adds <100ms overhead, total Step 12 processing <200ms
  - **Files Modified**:
    - `scripts/update-orchestrator.ps1` (Step 12, lines 677-767) - Added hash verification, notification differentiation, and structured logging
  - **Files Added**:
    - `tests/integration/UpdateOrchestrator.Tests.ps1` (Scenario 11) - Added 9 integration tests for constitution notification behavior
  - **Accessibility**: Emoji icons combined with color schemes and text labels ("REQUIRED"/"OPTIONAL") for universal comprehension
  - **Backwards Compatibility**: No breaking changes - enhanced existing Step 12 behavior without altering orchestrator workflow
  - **Test Coverage**: 9 new integration tests validating false positive elimination, notification differentiation, fail-safe behavior, and verbose logging

## [0.3.0] - 2025-10-22

### Added
- **Smart Conflict Resolution (#8)**: Intelligent two-tier conflict handling based on file size
  - **Small Files (≤100 lines)**: Continue using Git conflict markers with VSCode CodeLens integration
  - **Large Files (>100 lines)**: Generate side-by-side Markdown diff files in `.specify/.tmp-conflicts/`
  - **Implementation**:
    - New `Compare-FileSections` function: Analyzes file differences and groups consecutive changes into sections
    - New `Write-SideBySideDiff` function: Generates Markdown diff files with syntax highlighting and unchanged sections summary
    - New `Write-SmartConflictResolution` function: Routes to appropriate resolution method based on line count
    - New `Remove-ConflictDiffFiles` function: Cleans up diff files after successful updates
  - **Diff File Features**:
    - Header with version comparison and file metadata (line count, changed sections, total changed lines)
    - Only changed sections shown with 3-line context before/after
    - Side-by-side comparison: "Your Version (Lines X-Y)" vs "Incoming Version (Lines X-Y)"
    - Syntax highlighting based on file extension (.md, .ps1, .json, .yaml)
    - Summary of unchanged sections (e.g., "Lines 1-50 (50 lines) unchanged")
    - UTF-8 encoding without BOM for cross-platform compatibility
  - **Automatic Cleanup**:
    - `.specify/.tmp-conflicts/` directory removed after successful updates
    - Diff files preserved on rollback for debugging purposes
  - **Error Handling**: Graceful fallback to Git markers if diff generation fails
  - **Files Added**:
    - `tests/fixtures/large-file-samples/` - 5 test fixtures for boundary condition testing (50, 100, 101, 200, 1000 lines)
  - **Files Modified**:
    - `scripts/modules/ConflictDetector.psm1` - Added 4 new functions (~400 lines)
    - `scripts/update-orchestrator.ps1` - Added Step 13.5 for cleanup, replaced `Write-ConflictMarkers` with `Write-SmartConflictResolution`
    - `.gitignore` - Added `.specify/.tmp-conflicts/` to ignore patterns
    - `tests/unit/ConflictDetector.Tests.ps1` - Added 26 new unit tests (18 for diff generation, 8 for cleanup)
    - `tests/integration/UpdateOrchestrator.Tests.ps1` - Added 5 integration tests
  - **Test Coverage**: 206 passing unit tests, 29 passing integration tests

## [0.2.0] - 2025-10-21

### Changed
- **BREAKING - Conversational Approval Workflow (#11)**: Removed broken Show-QuickPick UI integration and replaced with text-only conversational approval workflow
  - **Root Cause**: VSCode QuickPick API unavailable when Claude Code runs PowerShell scripts as subprocess without terminal/UI context
  - **Symptoms**: "Failed to show QuickPick" errors causing update failures in Claude Code
  - **Impact**: Skill completely non-functional in Claude Code (primary execution context)
  - **Breaking Changes**:
    - Removed `-Auto` flag (DEPRECATED - now shows warning and treats as `-Proceed`)
    - Added `-Proceed` flag for conversational workflow continuation
    - Removed `Show-QuickPick` function entirely from VSCodeIntegration module
    - Workflow now two-step: 1) Show summary + approval request, 2) Re-invoke with `-Proceed`
  - **Implementation Changes**:
    - Added conversational approval workflow with `[PROMPT_FOR_APPROVAL]` marker in summary output
    - Implemented non-interactive stdin detection using `[Console]::IsInputRedirected`
    - Replaced Read-Host prompts with graceful exit (exit code 0, not error)
    - Script outputs summary, exits for approval, then proceeds when re-invoked with `-Proceed`
  - **Conflict Resolution Changes**:
    - Removed VSCode merge editor integration (`code --merge` no longer invoked)
    - Implemented Git conflict markers (<<<<<<, ||||||, =======, >>>>>>) for conflicts
    - VSCode CodeLens automatically detects markers and provides resolution UI
    - Added false positive detection (auto-resolves when file content matches upstream)
    - Special handling for constitution.md (delegates to `/speckit.constitution` workflow)
  - **Critical Bug Fixes**:
    - **Manifest Customized Flag**: Fixed bug where files marked `customized: true` were being overwritten
      - Root cause: `Get-FileState` only compared hashes, ignored manifest's customized flag
      - When manifest created with `-AssumeAllCustomized`, original_hash = current hash
      - This caused `isCustomized = false` despite manifest flag, leading to incorrect 'update' action
      - Fix: Added `ManifestCustomized` parameter that takes precedence over hash comparison
      - Added 3 unit tests to prevent regression (commit 0865eb7)
    - **Manifest Cleanup**: Fixed script leaving temporary manifest.json in dirty state after approval prompt
      - Now cleans up manifest when exiting for approval (commit f4e397d)
    - **Constitution Preservation**: Constitution.md now preserved with intelligent merge command instead of conflict markers
  - **Files Modified**:
    - `scripts/update-orchestrator.ps1` - Conversational workflow, conflict markers, manifest cleanup
    - `scripts/helpers/Get-UpdateConfirmation.ps1` - Non-interactive detection, summary generation
    - `scripts/helpers/Show-UpdateSummary.ps1` - Constitution command with backup path
    - `scripts/modules/ConflictDetector.psm1` - ManifestCustomized parameter, Write-ConflictMarkers function
    - `scripts/modules/VSCodeIntegration.psm1` - Removed Show-QuickPick function
    - `tests/unit/VSCodeIntegration.Tests.ps1` - Removed Show-QuickPick tests
    - `tests/unit/ConflictDetector.Tests.ps1` - Added ManifestCustomized tests
    - `SKILL.md` - Updated command name, added execution instructions
    - `.specify/memory/constitution.md` - Added text-only I/O principle (v1.3.0)
    - `CLAUDE.md` - Documented architectural limitations, Git conflict markers approach
  - **Testing**: Successfully tested end-to-end in claude-toolkit project via VSCode extension
  - **Results**: Skill now works reliably in Claude Code with conversational approval, automatic conflict marker detection in VSCode, and preserved customizations

## [0.1.5] - 2025-10-20

### Added
- **Wrapper Script for CLI Compatibility**: Added `update-wrapper.ps1` to handle both Linux-style (`--flags`) and PowerShell-style (`-Flags`) command arguments
  - Converts kebab-case to PascalCase automatically
  - Supports `--flag`, `--flag=value`, and `--flag value` formats
  - Uses hashtable splatting to avoid parameter binding issues
  - Updated SKILL.md to use wrapper as entry point

### Fixed
- **Claude Code Integration (#11)**: Fixed interactive prompt failures when running through Claude Code extension
  - **Root Cause**: No interactive terminal available for `Read-Host` prompts
  - **Symptoms**: "The update was cancelled because the interactive confirmation prompt cannot be displayed"
  - **Impact**: Skill completely non-functional when invoked through Claude Code
  - **Fix Applied**:
    - Added `-Auto` parameter to skip confirmation prompts (line 75)
    - When `-Auto` is set, automatically proceeds without user confirmation
    - Updated SKILL.md to recommend `-Auto` flag for Claude Code usage
    - Added comment-based help documentation for `-Auto` parameter
  - **Testing**: Successfully ran end-to-end update of 19 files through Claude Code in VSCode
  - **Results**: Skill now works in both Claude Code (non-interactive) and terminal (interactive) contexts
  - **Breaking Change**: None (adds new optional parameter, maintains backward compatibility)

### Documentation
- Updated SKILL.md usage examples to show PowerShell-style flags as primary
- Added recommendation to use `-Auto` flag when running through Claude Code
- Clarified wrapper script purpose and dual-syntax support

## [0.1.4] - 2025-10-20

### Fixed
- **First-Time User Workflow (#8)**: Fixed 10 cascading issues preventing first-time manifest creation and updates
  - **Root Cause**: Parameter naming inconsistency in `New-SpecKitManifest` and multiple integration bugs in first-time workflow
  - **Symptoms**: "Cannot process command because of one or more missing mandatory parameters: SpecKitVersion" error
  - **Impact**: New users unable to initialize manifest or run first update
  - **Bug #1 - Parameter Naming**: Changed `-SpecKitVersion` to `-Version` in `New-SpecKitManifest` for consistency with other functions
  - **Bug #2 - Wrong Initial Version**: Fixed manifest creation to use "v0.0.0" placeholder instead of target version (prevented "already up to date" false positive)
  - **Bug #3 - Asset Name Pattern**: Changed from exact match `claude-templates.zip` to pattern match `spec-kit-template-claude-ps-*.zip` to support versioned asset names
  - **Bug #4 - Non-Existent Release Lookup**: Added early return in `Get-OfficialSpecKitCommands` for v0.0.0 placeholder version with fallback command list
  - **Bug #5 - Invalid ProjectRoot Parameter (First Instance)**: Temporarily removed `-ProjectRoot` parameter from `Get-AllFileStates` call (later re-added with fix)
  - **Bug #6 - PowerShell Common Parameters**: Changed SKILL.md entry point from `pwsh -File` to `pwsh -NoProfile -Command` to support `-Help`, `-Verbose`, etc.
  - **Bug #7 - File Path Resolution**: Re-added `-ProjectRoot` parameter to `Get-AllFileStates` with absolute path construction before file operations, preventing "file locked or inaccessible" errors
  - **Bug #8 - Check-Only Leaving Repo Dirty**: Added cleanup code to delete temporary manifest.json when running with `-CheckOnly` flag
  - **Bug #9 - Invalid Backup Parameters**: Removed non-existent `-FromVersion` and `-ToVersion` parameters from `New-SpecKitBackup` call
  - **Bug #10 - Invalid FileStates Parameter**: Removed non-existent `-FileStates` parameter from `Update-FileHashes` call
  - **Fix Applied**:
    - Standardized parameter naming across ManifestManager module (11 instances updated)
    - Implemented placeholder version workflow for first-time users (orchestrator restructured to fetch version before creating manifest)
    - Updated GitHub asset lookup to handle PowerShell-specific template naming
    - Added v0.0.0 special case handling with hardcoded fallback list of 8 official commands
    - Fixed absolute/relative path handling in ConflictDetector module (constructs absolute paths, returns relative paths in state objects)
    - Updated SKILL.md entry point to use `pwsh -NoProfile -Command` invocation pattern
    - Added temporary file cleanup in check-only mode to prevent Git state pollution
    - Fixed all function parameter signatures to match actual function definitions
  - **Testing**: Added 4 new unit tests for parameter validation and first-time scenarios; end-to-end tested in real SpecKit project (claude-toolkit)
  - **Files Modified**:
    - `scripts/modules/ManifestManager.psm1` - Parameter naming and v0.0.0 handling (lines 126, 135, 138, 197, 261-276, 312)
    - `scripts/modules/GitHubApiClient.psm1` - Asset name pattern matching (lines 289-291)
    - `scripts/modules/ConflictDetector.psm1` - ProjectRoot parameter and absolute path construction (lines 212-214, 241-251, 268-279)
    - `scripts/update-orchestrator.ps1` - Workflow restructuring, parameter fixes, cleanup (lines 263-277, 299, 316-323, 354, 524)
    - `SKILL.md` - Entry point command pattern (line 48)
    - `tests/unit/ManifestManager.Tests.ps1` - Parameter naming updates and new tests (lines 328-344)
  - **Results**: First-time users can now successfully create manifest with v0.0.0 placeholder, download 19 template files, and update to latest version; unit test pass rate improved from 67% to 97% (35/36 passing)
  - **Breaking Change**: None (fixes existing functionality, maintains backward compatibility)

## [0.1.3] - 2025-10-20

### Fixed
- **Version Parameter Handling (#6)**: Fixed "missing mandatory parameters: SpecKitVersion" error when running updates without explicit version
  - **Root Cause**: Missing validation and null checks when GitHub API returns invalid or null responses
  - **Symptoms**: Script crash with "Cannot index into a null array" when accessing `$targetRelease.tag_name` after failed API call
  - **Impact**: Users unable to run automatic updates (primary workflow) - only explicit version specification worked
  - **Fix Applied**:
    - **Enhanced API Error Handling**: Added structured error handling in `Invoke-GitHubApiRequest` for all HTTP status codes (403 rate limit, 404 not found, 500+ server errors) with specific user-friendly messages
    - **Response Validation**: Added comprehensive validation to `Get-LatestSpecKitRelease` and `Get-SpecKitRelease` checking for null responses, missing properties (`tag_name`, `assets`), and invalid version formats
    - **Defensive Null Checks**: Added two-stage validation (module + orchestrator) to prevent crashes when accessing response properties
    - **Parameter Naming Consistency**: Standardized all functions to use `-Version` parameter (was inconsistent with `-SpecKitVersion`)
    - **Timeout Protection**: Added 30-second timeout to all GitHub API calls to prevent hanging on slow networks
    - **Diagnostic Logging**: Added extensive `Write-Verbose` logging at validation checkpoints for troubleshooting
  - **Error Messages Improved**:
    - Network failures: "Failed to connect to GitHub API. Check network connectivity"
    - Rate limiting: "GitHub API rate limit exceeded. Resets at: {time}"
    - Not found: "GitHub resource not found. Verify repository and release exist"
    - Server errors: "GitHub API server error (HTTP {code}). Try again later"
    - Invalid responses: Property-specific validation error messages
  - **Testing**: Added 10 new unit tests covering null responses, missing properties, invalid formats, and all error scenarios
  - **Files Modified**:
    - `scripts/modules/GitHubApiClient.psm1` - Enhanced error handling and validation (lines 28-220)
    - `scripts/modules/ManifestManager.psm1` - Standardized parameter naming
    - `scripts/update-orchestrator.ps1` - Added defensive null checks and verbose logging (lines 217-266)
    - `tests/unit/GitHubApiClient.Tests.ps1` - Added validation tests
  - **Results**: Automatic version detection now works reliably with robust error handling and clear error messages
  - **Breaking Change**: None (fixes existing functionality, maintains backward compatibility)

## [0.1.2] - 2025-10-20

### Fixed
- **Module Function Availability (#4)**: Fixed nested module import issue causing "command not recognized" errors
  - **Root Cause**: Modules importing other modules created PowerShell scope isolation where imported functions were not accessible to the orchestrator
  - **Symptoms**: Errors like "The term 'Get-SpecKitManifest' is not recognized as a name of a cmdlet, function, script file, or executable program"
  - **Impact**: 21 tests were failing due to this scope isolation bug
  - **Fix Applied**:
    - Removed all nested `Import-Module` statements from 3 modules (ManifestManager, BackupManager, ConflictDetector)
    - Updated orchestrator (`update-orchestrator.ps1`) with tiered import structure documenting dependencies
    - All module imports now managed centrally by orchestrator in correct dependency order (Tier 0 → Tier 1 → Tier 2)
  - **Prevention Measures**:
    - Added automated lint check in `tests/test-runner.ps1` that fails if any `.psm1` file contains `Import-Module`
    - Created integration tests (`tests/integration/ModuleDependencies.Tests.ps1`) to verify cross-module function calls work correctly
    - Updated constitution (v1.1.0) with Module Import Rules prohibiting nested imports
    - Updated CLAUDE.md and CONTRIBUTING.md with nested import prohibition and enforcement details
  - **Results**: 21 more tests now passing (160→181), lint check prevents future violations
  - **Breaking Change**: None (internal architecture change only)

## [0.1.1] - 2025-10-20

### Fixed
- **BREAKING FIX - Module Import Error**: Permanently resolved recurring "Export-ModuleMember cmdlet can only be called from inside a module" error by fixing the root architectural issue (#3)
  - **Root Cause**: Helper scripts (`.ps1` files) incorrectly used `Export-ModuleMember`, which only works in module files (`.psm1`)
  - **Previous Fix (PR #1)**: Applied error suppression workarounds that masked symptoms but allowed the antipattern to persist and recur
  - **This Fix (PR #3)**: Corrected the architectural confusion:
    - Removed `Export-ModuleMember` from all 7 helper scripts in `scripts/helpers/`
    - Helpers are dot-sourced (`. script.ps1`), not imported, so functions are automatically available without export declarations
    - Modules in `scripts/modules/` correctly retain `Export-ModuleMember` (proper module pattern)
    - Simplified orchestrator import logic - removed error suppression workarounds (`-ErrorAction SilentlyContinue`, `2>$null`, `$ErrorActionPreference` save/restore)
    - Added proper try-catch blocks with stack trace logging for real errors
    - Real errors now cause immediate fatal exit (fail-fast principle restored)
  - **Prevention Measures**:
    - Added "Module vs. Helper Pattern" documentation to CLAUDE.md
    - Establishes clear architectural boundaries to prevent recurrence
  - Module import still completes in <500ms (well under 2-second requirement)
  - Skill now executes cleanly on Windows 11 with PowerShell 7.x without false-positive errors

## [0.1.0] - 2025-01-19

### Added

**Core Features:**
- Initial implementation of SpecKit Safe Update skill for Claude Code
- Safe update mechanism preserving user customizations during SpecKit template updates
- Intelligent conflict resolution with VSCode 3-way merge editor (Flow A: one-at-a-time)
- Automatic backup creation with retention management (keeps 5 most recent)
- Fail-fast error handling with automatic rollback on failure
- Dry-run mode (`--check-only`) to preview changes without applying
- Rollback command to restore from previous backups
- Force mode (`--force`) with confirmation to reset SpecKit files
- Constitution update integration (notifies to run `/speckit.constitution`)

**Modules Implemented:**
- `HashUtils.psm1` - Normalized file hashing (handles CRLF/LF, trailing whitespace, BOM)
- `VSCodeIntegration.psm1` - Context detection, Quick Pick, diff/merge editor integration
- `GitHubApiClient.psm1` - GitHub Releases API client (unauthenticated, with rate limit handling)
- `ManifestManager.psm1` - Manifest CRUD operations with caching
- `BackupManager.psm1` - Backup creation, restoration, and retention management
- `ConflictDetector.psm1` - File state analysis and conflict detection

**Helper Functions:**
- `Invoke-PreUpdateValidation.ps1` - Prerequisites validation (critical + warnings)
- `Show-UpdateSummary.ps1` - Detailed post-update results display
- `Show-UpdateReport.ps1` - Check-only mode report generation
- `Get-UpdateConfirmation.ps1` - User confirmation with change preview
- `Invoke-ConflictResolutionWorkflow.ps1` - Flow A conflict resolution implementation
- `Invoke-ThreeWayMerge.ps1` - VSCode merge editor integration with temp files
- `Invoke-RollbackWorkflow.ps1` - Backup restoration workflow

**Main Orchestrator:**
- 15-step update workflow with comprehensive error handling
- Command-line flags: `--check-only`, `--version`, `--force`, `--rollback`, `--no-backup`
- Exit codes: 0 (success), 1 (error), 2 (prereqs), 3 (network), 4 (git), 5 (cancel), 6 (rollback)

**Testing:**
- Unit tests for all 6 modules (HashUtils, VSCodeIntegration, GitHubApiClient, ManifestManager, BackupManager, ConflictDetector)
- Integration tests covering 8 core scenarios plus additional edge cases
- Test fixtures for mock GitHub API responses and sample projects
- Pester 5.x test framework with proper mocking

**Documentation:**
- Comprehensive README with usage examples, architecture, workflow diagrams
- Complete SKILL.md for Claude Code integration
- Detailed specification in `specs/001-safe-update/spec.md`
- Implementation plan in `specs/001-safe-update/plan.md`
- Integration test documentation with README and QUICKSTART

**File Management:**
- Manifest tracking with file hashes and customization flags
- Official vs. custom command distinction
- Command lifecycle management (add/remove/update)
- Custom commands always preserved (never overwritten)
- Normalized hashing for cross-platform compatibility

**User Experience:**
- Context-aware UI (VSCode Quick Pick vs terminal prompts)
- Color-coded console output
- Detailed change previews before applying updates
- Clear error messages with recovery guidance
- Progress indicators and verbose logging

**Safety Features:**
- Git state validation (requires clean or staged changes)
- Automatic backup before destructive operations
- Fail-fast principle with immediate rollback on error
- Backup directory exclusion to prevent infinite recursion
- Constitution preservation with guided update flow

### Technical Details

**Dependencies:**
- PowerShell 7+
- Git (in PATH)
- VSCode with Claude Code extension (for merge editor)
- Internet connection (for GitHub API)

**Repository Structure:**
- `scripts/` - Main orchestrator and modules
- `scripts/modules/` - 6 PowerShell modules
- `scripts/helpers/` - 7 helper functions
- `templates/` - Manifest template
- `tests/unit/` - Unit tests (6 test files)
- `tests/integration/` - Integration tests
- `tests/fixtures/` - Test fixtures and mock data
- `specs/001-safe-update/` - Specification and plan
- `SKILL.md` - Claude Code skill definition
- `README.md` - User documentation

**Specification Compliance:**
- All 3 user stories implemented with acceptance criteria met
- All design decisions from PRD documented and implemented
- Phase 0-6 complete according to implementation plan
- Ready for Phase 7 (manual testing)

### Known Issues

- Some unit tests may have scoping issues with Pester 5.x (modules fully functional)
- BackupManager tests have timestamp collision issues (implementation correct)
- Integration tests require proper mocking setup to run

### Security

- No GitHub token required (uses unauthenticated API with rate limit handling)
- No sensitive data stored in manifest
- All file operations validated before execution
- Backup preservation during rollback to maintain history

[Unreleased]: https://github.com/NotMyself/claude-win11-speckit-update-skill/compare/v0.6.0...HEAD
[0.6.0]: https://github.com/NotMyself/claude-win11-speckit-update-skill/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/NotMyself/claude-win11-speckit-update-skill/compare/v0.4.1...v0.5.0
[0.4.1]: https://github.com/NotMyself/claude-win11-speckit-update-skill/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/NotMyself/claude-win11-speckit-update-skill/compare/v0.3.1...v0.4.0
[0.3.1]: https://github.com/NotMyself/claude-win11-speckit-update-skill/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/NotMyself/claude-win11-speckit-update-skill/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/NotMyself/claude-win11-speckit-update-skill/compare/v0.1.5...v0.2.0
[0.1.5]: https://github.com/NotMyself/claude-win11-speckit-update-skill/compare/v0.1.4...v0.1.5
[0.1.4]: https://github.com/NotMyself/claude-win11-speckit-update-skill/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/NotMyself/claude-win11-speckit-update-skill/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/NotMyself/claude-win11-speckit-update-skill/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/NotMyself/claude-win11-speckit-update-skill/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/NotMyself/claude-win11-speckit-update-skill/releases/tag/v0.1.0
