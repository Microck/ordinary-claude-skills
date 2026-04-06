# Implementation Plan: Plugin-Based Distribution

**Branch**: `015-plugin-distribution` | **Date**: 2025-10-25 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from [specs/015-plugin-distribution/spec.md](spec.md)

## Summary

Transform the SpecKit Safe Update Skill from manual Git clone installation to professional plugin-based distribution following Anthropic's recommended approach. Enable installation via `/plugin install speckit-updater` command after adding the NotMyself marketplace, while maintaining 100% backward compatibility with existing manual installations. Create a marketplace repository (`NotMyself/claude-plugins`) and restructure the current repository to support plugin format (`.claude-plugin/plugin.json`, `skills/` directory) without breaking existing functionality.

## Technical Context

**Language/Version**: PowerShell 7.0+ (existing project, no changes)
**Primary Dependencies**:
- Git 2.0+ (existing requirement, no changes)
- Claude Code plugin system (new integration)
- GitHub API (existing, for marketplace manifest hosting)
- Existing PowerShell modules (no new module dependencies)

**Storage**:
- Plugin manifest JSON (`.claude-plugin/plugin.json` in skill repository)
- Marketplace manifest JSON (`.claude-plugin/marketplace.json` in marketplace repository)
- Restructured directory layout (`skills/speckit-updater/` wrapper for existing content)

**Testing**: Pester 5.x (existing framework, tests for backward compatibility required)

**Target Platform**: Windows/macOS/Linux (cross-platform PowerShell, existing, no changes)

**Project Type**: Skill/Plugin (development tool, not single/web/mobile application)

**Performance Goals**:
- Plugin installation completes in <30 seconds (excluding network latency)
- Repository restructuring has zero performance impact on skill execution
- Marketplace manifest fetches in <5 seconds

**Constraints**:
- 100% backward compatibility required (manual installations must continue working)
- Text-only I/O (existing PowerShell subprocess constraint, no GUI operations)
- No breaking changes to existing test suite (all tests must pass after restructuring)
- Git-based distribution only (Claude Code plugin system is Git-centric, no package files supported)

**Scale/Scope**:
- 1 marketplace repository to create (`NotMyself/claude-plugins`)
- 1 skill repository to restructure (existing `claude-win11-speckit-update-skill`)
- 7 phases of implementation (Setup, Foundational, 4 User Stories [P1, P2, P3, P3], Polish & Release; consolidated from PRD's 8 phases)
- 3 manifest files total (1 marketplace, 1 plugin, 1 existing `.specify/manifest.json` unchanged)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Modular Architecture (Principle I)

**Status**: ✅ PASS (Not Applicable)

**Rationale**: This feature involves repository restructuring and creating manifest files, not adding new PowerShell business logic. No new modules are required. Existing modules remain unchanged and properly structured.

**Action**: None required

---

### Fail-Fast with Rollback (Principle II)

**Status**: ✅ PASS (Not Applicable)

**Rationale**: This feature does not modify the update orchestration workflow or error handling. The existing rollback mechanisms for SpecKit updates are unaffected by repository restructuring.

**Action**: None required

---

### Customization Detection via Normalized Hashing (Principle III)

**Status**: ✅ PASS (Not Applicable)

**Rationale**: This feature does not change file customization detection or hashing logic. The existing `HashUtils.psm1` module remains unchanged.

**Action**: None required

---

### User Confirmation Required (Principle IV)

**Status**: ✅ PASS (Not Applicable)

**Rationale**: This feature does not introduce new interactive workflows requiring user confirmation. Plugin installation is handled by Claude Code's plugin system, not by this skill's code.

**Action**: None required

---

### Testing Discipline (Principle V)

**Status**: ⚠️ REQUIRES ATTENTION

**Rationale**: Repository restructuring requires comprehensive backward compatibility testing to ensure:
- Manual Git clone installations continue working after restructuring
- Existing test suite passes without modification
- Relative paths in test runner and workflows remain valid
- Side-by-side installations (manual + plugin) are handled gracefully

**Action Required**:
- Create new integration tests in `tests/integration/PluginCompatibility.Tests.ps1`
- Test scenarios:
  1. Manual installation from restructured repository
  2. Plugin installation flow
  3. Migration from manual to plugin
  4. Path resolution in both installation modes
- Validate all 132 existing unit tests pass after restructuring
- Document test execution for both manual and plugin installations

---

### Architectural Verification Before Suggestions (Principle VI)

**Status**: ⚠️ REQUIRES ATTENTION

**Rationale**: Must verify that Claude Code's plugin system supports Git-based distribution and validate the plugin manifest schema before implementing. Research already confirmed:
- ✅ Claude Code plugin system is Git-centric (no file-based package installation)
- ✅ Marketplace manifests reference Git repositories
- ✅ Plugin installation clones Git repositories

**Action Required**:
- Phase 0 Research: Document Claude Code plugin manifest schema requirements
- Phase 0 Research: Validate marketplace manifest format with real examples
- Phase 1 Design: Create contract schemas matching verified plugin system requirements
- Verify `.claude-plugin/plugin.json` structure matches Anthropic's specification

---

### Module Import Rules (Constitution Section)

**Status**: ✅ PASS (Not Applicable)

**Rationale**: No new modules are being created. Repository restructuring moves existing files to `skills/speckit-updater/` directory but does not change module import logic in `update-orchestrator.ps1`.

**Action**: Verify that orchestrator's module import paths remain valid after moving to `skills/speckit-updater/scripts/` (handled in Phase 2 path validation)

---

### Text-Only I/O Constraint (Constitution Section)

**Status**: ✅ PASS

**Rationale**: Plugin installation is handled entirely by Claude Code's plugin system, not by PowerShell code in this skill. No GUI or interactive prompts are introduced. Repository restructuring is a file system operation with no I/O changes.

**Action**: None required

---

### **GATE EVALUATION**: ✅ PASS WITH CONDITIONS

**Conditions**:
1. Phase 0 must include research on Claude Code plugin manifest schema
2. Phase 1 must create backward compatibility integration tests
3. Phase 2 path validation must verify all relative paths work after restructuring

**Proceed to Phase 0**: Yes

## Project Structure

### Documentation (this feature)

```
specs/015-plugin-distribution/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   ├── plugin-manifest.schema.json
│   └── marketplace-manifest.schema.json
├── checklists/          # Created by /speckit.specify
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

**Current Structure** (before restructuring):
```
claude-win11-speckit-safe-update-skill/
├── SKILL.md                    # Root level (skill definition)
├── scripts/                    # Root level (PowerShell modules and orchestrator)
│   ├── modules/
│   │   ├── HashUtils.psm1
│   │   ├── ManifestManager.psm1
│   │   ├── BackupManager.psm1
│   │   └── [others]
│   ├── helpers/
│   │   └── [helper scripts]
│   └── update-orchestrator.ps1
├── tests/                      # Root level (Pester test suites)
│   ├── unit/
│   └── integration/
├── templates/                  # Root level (manifest templates)
├── specs/                      # Root level (feature specifications)
├── data/                       # Root level (fingerprint database)
├── README.md
├── CLAUDE.md
├── CONTRIBUTING.md
└── CHANGELOG.md
```

**Target Structure** (after restructuring):
```
claude-win11-speckit-safe-update-skill/
├── .claude-plugin/             # NEW: Plugin metadata directory
│   └── plugin.json             # NEW: Plugin manifest
├── skills/                     # NEW: Wrapper directory for plugin format
│   └── speckit-updater/        # NEW: Skill content moved here
│       ├── SKILL.md            # Moved from root
│       ├── scripts/            # Moved from root
│       │   ├── modules/
│       │   ├── helpers/
│       │   └── update-orchestrator.ps1
│       ├── tests/              # Moved from root
│       ├── templates/          # Moved from root
│       ├── specs/              # Moved from root
│       └── data/               # Moved from root
├── README.md                   # Updated with plugin installation instructions
├── CLAUDE.md                   # Updated distribution model documentation
├── CONTRIBUTING.md             # Updated with plugin structure guidance
├── CHANGELOG.md                # Updated with v0.8.0 release notes
├── LICENSE
└── .gitignore
```

**New Marketplace Repository** (`NotMyself/claude-plugins`):
```
claude-plugins/
├── .claude-plugin/
│   └── marketplace.json        # Marketplace manifest
├── README.md                   # Marketplace documentation
├── LICENSE
└── .gitignore
```

**Structure Decision**:
- **Skill Repository**: Restructure existing repository to support plugin format by creating `.claude-plugin/` directory and wrapping existing content in `skills/speckit-updater/` subdirectory. This maintains backward compatibility because Git clone targets remain valid (users clone the same repository, just with internal restructuring).
- **Marketplace Repository**: Create new standalone repository (`NotMyself/claude-plugins`) containing only marketplace manifest and documentation. This follows Claude Code's marketplace pattern.
- **Backward Compatibility**: Manual installations via `git clone` continue working because the repository URL remains unchanged. Plugin installations reference the same repository via marketplace entry.

## Complexity Tracking

*No Constitution violations requiring justification. All gates passed or have actionable conditions documented above.*

---

## Post-Design Constitution Re-Evaluation

*Re-checked after Phase 0 (Research) and Phase 1 (Design) completion*

### Phase 0 & 1 Deliverables Completed

✅ **Phase 0: Research**
- [research.md](research.md) - Complete (7 research questions answered)
- Claude Code plugin system architecture documented
- Manifest schema requirements validated
- Installation workflows defined

✅ **Phase 1: Design**
- [data-model.md](data-model.md) - Complete (3 entities defined)
- [contracts/plugin-manifest.schema.json](contracts/plugin-manifest.schema.json) - JSON Schema created
- [contracts/marketplace-manifest.schema.json](contracts/marketplace-manifest.schema.json) - JSON Schema created
- [quickstart.md](quickstart.md) - Installation guide created
- Agent context updated (CLAUDE.md)

### Constitution Check Updates

**Testing Discipline (Principle V) - Status: ✅ READY FOR IMPLEMENTATION**

Phase 1 design has identified specific test requirements:
- Integration tests documented in data-model.md (Edge Cases section)
- Path validation tests specified in research.md (Q7: Path resolution implications)
- Backward compatibility test scenarios defined in quickstart.md (Migration section)
- Test execution from new location (`skills/speckit-updater/tests/`) planned

**Action for Phase 2 (Tasks)**: Create specific test tasks in tasks.md for PluginCompatibility.Tests.ps1

---

**Architectural Verification (Principle VI) - Status: ✅ VERIFIED**

Phase 0 research confirmed all architectural assumptions:
- ✅ Claude Code plugin system uses Git-based distribution (not package files)
- ✅ Marketplace manifests validated against real examples
- ✅ Plugin manifest schema matches Anthropic's specifications
- ✅ No architectural incompatibilities identified

**Action**: None required - design aligns with Claude Code's plugin architecture

---

**Module Import Rules - Status: ✅ PASS**

Phase 1 design confirmed:
- No new PowerShell modules required
- Existing orchestrator import logic unchanged by restructuring
- Module files move together with orchestrator (relative paths preserved)

**Action for Phase 2 (Tasks)**: Add path validation task to verify orchestrator imports after restructuring

---

### **FINAL GATE EVALUATION**: ✅ PASS - READY FOR PHASE 2 (TASKS)

**Summary**:
- All Phase 0 research questions answered with documented decisions
- All Phase 1 design artifacts created and validated
- No Constitution violations introduced
- No blockers identified
- Ready to proceed with `/speckit.tasks` to generate implementation tasks

**Conditions Met**:
1. ✅ Claude Code plugin manifest schema researched and documented
2. ✅ Backward compatibility requirements captured in design artifacts
3. ✅ Path validation requirements documented for Phase 2

**Next Step**: Run `/speckit.tasks` to generate dependency-ordered implementation tasks
