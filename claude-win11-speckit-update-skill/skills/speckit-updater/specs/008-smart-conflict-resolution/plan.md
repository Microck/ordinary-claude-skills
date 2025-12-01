# Implementation Plan: Smart Conflict Resolution for Large Files

**Branch**: `008-smart-conflict-resolution` | **Date**: 2025-10-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/008-smart-conflict-resolution/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Enhance the conflict resolution system to intelligently handle large template files (>100 lines) by generating side-by-side diff files showing only changed sections instead of full Git conflict markers. This addresses a critical usability issue where large file conflicts (e.g., 543-line templates) show the entire file duplicated with no indication of what actually changed, making informed conflict resolution impossible.

**Technical Approach**: Add smart resolution logic to the existing `ConflictDetector.psm1` module that detects file size and either generates a structured Markdown diff file (for large files) or uses existing Git conflict markers (for small files). Diff files are written to `.specify/.tmp-conflicts/` and cleaned up after successful updates.

## Technical Context

**Language/Version**: PowerShell 7.x (pwsh.exe)
**Primary Dependencies**: Existing PowerShell modules (HashUtils, ConflictDetector, ManifestManager), PowerShell core cmdlets (Compare-Object)
**Storage**: File system (`.specify/` directory structure, temporary diff files in `.specify/.tmp-conflicts/`)
**Testing**: Pester 5.x with unit tests and integration tests
**Target Platform**: Windows 11 (primary), cross-platform PowerShell support (macOS/Linux via pwsh)
**Project Type**: Single project - PowerShell skill enhancement
**Performance Goals**: Diff generation completes in under 2 seconds for files up to 1000 lines
**Constraints**: Text-only I/O (subprocess isolation), no GUI/VSCode extension APIs, must work in Claude Code and terminal contexts, Markdown output must render correctly in VSCode preview
**Scale/Scope**: Enhancement to existing 6 modules and 1 orchestrator script, adding 3 new functions to ConflictDetector module, 26 unit tests + 5 integration tests

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### ✅ I. Modular Architecture (NON-NEGOTIABLE)

**Status**: PASS

- All new business logic (smart conflict detection, file comparison, diff generation) will be implemented in the existing `ConflictDetector.psm1` module
- Three new functions will be added: `Write-SmartConflictResolution`, `Compare-FileSections`, `Write-SideBySideDiff`
- Functions will be stateless (all state passed via parameters) and independently testable
- Helper functions may be updated to guide users to review diff files, but contain no business logic

### ✅ II. Fail-Fast with Rollback (NON-NEGOTIABLE)

**Status**: PASS

- Diff file generation errors will fall back to Git conflict markers (graceful degradation) and log warning
- No changes to existing rollback mechanism
- Cleanup failures will be logged but won't fail the update (non-critical operation)
- Diff files are preserved on rollback for debugging (per FR-015)

### ✅ III. Customization Detection via Normalized Hashing

**Status**: PASS

- Feature leverages existing `HashUtils.psm1` normalized hashing for file comparison
- No changes to customization detection logic
- Diff generation uses same normalized content that was already compared for conflict detection

### ✅ IV. User Confirmation Required

**Status**: PASS

- No changes to existing confirmation workflow
- Users still approve updates before any file modifications
- Diff files are informational only (help users make informed decisions)

### ✅ V. Testing Discipline

**Status**: PASS

- Will add comprehensive unit tests to `tests/unit/ConflictDetector.Tests.ps1` for all 3 new functions
- Will add integration tests to `tests/integration/UpdateOrchestrator.Tests.ps1` for end-to-end diff generation workflow
- Test coverage includes: file size detection, diff format validation, boundary conditions (100-line threshold), error handling, cleanup

### ✅ VI. Architectural Verification Before Suggestions

**Status**: PASS - Text-Only I/O Constraint Respected

This feature was designed with full awareness of the text-only I/O constraint:

- **No GUI assumptions**: Diff files are text-based Markdown, not GUI dialogs
- **No VSCode extension APIs**: Uses Git conflict marker format that VSCode auto-detects via CodeLens (file-based integration, not API calls)
- **Subprocess compatible**: All output is via Write-Host/Write-Output to stdout
- **Conversational workflow**: Diff file paths are displayed to user; Claude Code can present the content in chat
- **Fallback pattern**: External tool invocation (`code --diff`) is mentioned in bug report as "optional" and "don't rely on it" - not a primary approach

**Anti-patterns avoided**:
- ❌ NOT using Out-GridView or PowerShell GUI for diff display
- ❌ NOT attempting to invoke VSCode extension APIs from subprocess
- ❌ NOT relying on IPC mechanisms that don't exist

**Approved pattern used**:
- ✅ Write text-based Markdown diff files to disk
- ✅ Display file paths to user via stdout
- ✅ Let VSCode auto-detect conflict markers in files (passive file integration)
- ✅ Cleanup is file system operation (no subprocess coordination)

## Project Structure

### Documentation (this feature)

```
specs/008-smart-conflict-resolution/
├── spec.md                      # Feature specification (completed by /speckit.specify)
├── plan.md                      # This file (/speckit.plan command output)
├── research.md                  # Phase 0 output (/speckit.plan command)
├── data-model.md                # Phase 1 output (/speckit.plan command)
├── quickstart.md                # Phase 1 output (/speckit.plan command)
├── contracts/                   # Phase 1 output (function signatures, data contracts)
│   ├── Write-SmartConflictResolution.md
│   ├── Compare-FileSections.md
│   └── Write-SideBySideDiff.md
├── checklists/                  # Quality validation checklists
│   └── requirements.md          # Spec quality checklist (completed)
└── tasks.md                     # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```
scripts/
├── modules/
│   ├── ConflictDetector.psm1    # MODIFIED: Add 3 new functions for smart conflict resolution
│   ├── HashUtils.psm1            # UNCHANGED: Used for normalized comparison
│   ├── ManifestManager.psm1     # UNCHANGED: Manifest CRUD operations
│   ├── BackupManager.psm1        # MODIFIED: May need cleanup integration
│   └── [other modules]
├── helpers/
│   ├── Invoke-ConflictResolutionWorkflow.ps1  # MODIFIED: Guide users to diff files
│   └── [other helpers]
└── update-orchestrator.ps1      # MODIFIED: Call new smart resolution function, handle cleanup

tests/
├── unit/
│   ├── ConflictDetector.Tests.ps1   # MODIFIED: Add tests for 3 new functions
│   └── [other test files]
├── integration/
│   └── UpdateOrchestrator.Tests.ps1 # MODIFIED: Add end-to-end diff generation tests
└── fixtures/
    └── large-file-samples/          # NEW: Sample large files for testing

.specify/
└── .tmp-conflicts/                  # NEW: Temporary diff files (created at runtime, in .gitignore)
```

**Structure Decision**: This is a single-project PowerShell skill. All code is organized under `scripts/` with clear separation between modules (business logic) and helpers (orchestration). Tests mirror the source structure. The `.specify/.tmp-conflicts/` directory is created at runtime for temporary diff files and is already in `.gitignore`.

## Complexity Tracking

*No constitution violations detected. This section is not applicable.*

All constitution principles are satisfied:
- Modular architecture maintained (new functions in ConflictDetector module)
- Fail-fast with graceful fallback (diff errors → Git markers)
- Normalized hashing reused from existing HashUtils
- No changes to user confirmation workflow
- Comprehensive testing planned
- Text-only I/O constraint respected throughout design

---

## Phase 1 Completion: Post-Design Constitution Re-Evaluation

*Required by Constitution Check gate: "Re-check after Phase 1 design"*

**Date**: 2025-10-21
**Status**: ✅ ALL PRINCIPLES VALIDATED

### Re-Evaluation Results

After completing Phase 1 design (research.md, data-model.md, function contracts, quickstart.md), the Constitution Check results remain **PASS** for all principles:

#### I. Modular Architecture ✅

**Design Confirmation**:
- All three new functions (`Write-SmartConflictResolution`, `Compare-FileSections`, `Write-SideBySideDiff`) are defined in the existing `ConflictDetector.psm1` module
- Functions are stateless (all state passed via parameters - see function contracts)
- Each function has single, clear responsibility:
  - `Write-SmartConflictResolution`: Entry point and routing logic
  - `Compare-FileSections`: Core comparison algorithm
  - `Write-SideBySideDiff`: Output generation
- All functions are independently testable (24+ unit tests planned in quickstart.md)
- Module exports updated to include new functions

**Evidence**: See [contracts/](contracts/) directory for detailed function signatures

#### II. Fail-Fast with Rollback ✅

**Design Confirmation**:
- Error handling pattern implemented in `Write-SmartConflictResolution` contract:
  - Try-catch wraps diff generation
  - Any exception triggers fallback to `Write-ConflictMarkers`
  - Warning logged with error details
- Cleanup failures are non-critical (logged but don't fail update)
- Diff files preserved on rollback per FR-015
- No changes to existing rollback mechanism in orchestrator

**Evidence**: See [contracts/Write-SmartConflictResolution.md](contracts/Write-SmartConflictResolution.md) - Error Handling section

#### III. Customization Detection via Normalized Hashing ✅

**Design Confirmation**:
- `Compare-FileSections` accepts pre-normalized content (parameter documentation specifies "Must be normalized")
- Reuses existing `HashUtils.psm1` module for normalization (no new normalization logic)
- Data model defines normalized content as requirement for comparison accuracy

**Evidence**: See [data-model.md](data-model.md) - Testing Data Fixtures section

#### IV. User Confirmation Required ✅

**Design Confirmation**:
- No changes to existing confirmation workflow
- Diff files are informational only (help users make decisions after approval)
- Quickstart.md confirms orchestrator integration is drop-in replacement (same confirmation flow)

**Evidence**: See [quickstart.md](quickstart.md) - Step 6: Update Orchestrator

#### V. Testing Discipline ✅

**Design Confirmation**:
- Comprehensive testing plan in quickstart.md:
  - 26 unit tests (including boundary conditions, error handling, and performance benchmarks)
  - 5 integration tests (end-to-end scenarios)
  - Performance benchmarks (100ms, 2000ms targets)
  - Test fixtures created (`tests/fixtures/large-file-samples/`)
- All function contracts include detailed testing requirements
- Coverage targets specified (80% minimum per constitution)

**Evidence**: See [quickstart.md](quickstart.md) - Step 8, 10, 11 (Testing sections)

#### VI. Architectural Verification Before Suggestions ✅

**Design Confirmation**:
- Text-only I/O constraint explicitly addressed in design:
  - Diff files are Markdown text files (no GUI)
  - Output via `Write-Host` to stdout
  - No VSCode extension API calls
  - No interactive UI elements
- Research.md documents verification of PowerShell `Compare-Object` compatibility
- All suggested technologies are PowerShell built-ins (no external dependencies)

**Evidence**: See [research.md](research.md) - All alternatives evaluated against subprocess constraint

### Phase 1 Artifacts Validation

| Artifact | Status | Validation |
|----------|--------|------------|
| research.md | ✅ Complete | All technology choices justified, alternatives evaluated |
| data-model.md | ✅ Complete | Entities defined with validation rules, performance analysis included |
| contracts/ | ✅ Complete | 3 function contracts with signatures, parameters, testing requirements |
| quickstart.md | ✅ Complete | 13-step implementation guide with code patterns and troubleshooting |
| Agent context | ✅ Updated | CLAUDE.md updated with PowerShell 7.x technology |

### Gate Status: ✅ CLEARED FOR PHASE 2

All constitution principles validated after Phase 1 design. Ready to proceed to Phase 2 (Task Generation via `/speckit.tasks`).

**Next Command**: `/speckit.tasks` to generate implementation task breakdown

---

## Planning Phase Summary

**Phase 0 (Research)**: ✅ Complete
- Technology choices documented (PowerShell `Compare-Object`, Markdown format)
- Performance analysis completed (<2s target for 1000 lines)
- Error handling strategy defined (fallback to Git markers)

**Phase 1 (Design & Contracts)**: ✅ Complete
- Data model defined (4 entities: DiffSection, UnchangedRange, ConflictMetadata, ComparisonResult)
- Function contracts specified (3 new public functions)
- Developer quickstart guide created (13-step implementation)
- Agent context updated (Claude Code integration)

**Phase 2 (Tasks)**: ⏸️ Not Started
- Run `/speckit.tasks` to generate dependency-ordered task breakdown
- Tasks will be based on quickstart.md implementation steps

**Constitution Check**: ✅ PASS (both pre-research and post-design)

**Branch**: `008-smart-conflict-resolution`
**Spec**: [spec.md](spec.md)
**Next Step**: `/speckit.tasks` to begin implementation planning
