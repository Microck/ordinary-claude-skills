# Phase 0: Research - Plugin-Based Distribution

**Feature**: Plugin-Based Distribution | **Date**: 2025-10-25
**Status**: Complete | **Plan**: [plan.md](plan.md)

## Overview

This document consolidates research findings on Claude Code's plugin system architecture, manifest requirements, and distribution patterns to inform the implementation of plugin-based distribution for the SpecKit Safe Update Skill.

## Research Questions

### Q1: How does Claude Code's plugin system handle installation?

**Decision**: Claude Code plugin system is Git-centric, not package-centric

**Rationale**:
- Plugin installation clones Git repositories rather than downloading archive files
- Marketplace manifests reference Git repository URLs (GitHub, GitLab, local Git)
- No support for file-based installation from downloaded packages (`.zip`, `.tar.gz`)
- Similar to npm's ability to install from Git URLs (e.g., `npm install user/repo`)

**Alternatives Considered**:
1. **Package-based distribution** (rejected) - Would require `.zip` archives attached to GitHub Releases for offline installation
   - **Why rejected**: Claude Code does not support `/plugin install <file-path>` syntax
   - Offline scenarios are already covered by manual `git clone` (backward compatibility)
   - Enterprise environments can use internal Git servers with marketplace manifests

2. **npm-style package registry** (rejected) - Would publish to a package registry like npm or PowerShell Gallery
   - **Why rejected**: Not how Claude Code plugin system works; requires marketplace + Git repository

3. **Git-based with marketplace** (chosen) - Marketplace manifest references Git repository URL
   - **Why chosen**: Aligns with Anthropic's design; enables discoverability; supports version management through Git tags

**Sources**:
- Claude Code Plugins documentation: https://docs.claude.com/en/docs/claude-code/plugins.md
- Claude Code Plugin Marketplaces: https://docs.claude.com/en/docs/claude-code/plugin-marketplaces.md
- Claude Code Plugins Reference: https://docs.claude.com/en/docs/claude-code/plugins-reference.md

---

### Q2: What is the required structure for plugin manifests?

**Decision**: Plugin manifest (`.claude-plugin/plugin.json`) must follow specific schema

**Rationale**:
- Claude Code requires `.claude-plugin/plugin.json` at repository root
- Manifest declares plugin metadata, skills path, requirements, and version
- Used by plugin system to validate installation and display plugin information

**Required Fields**:
```json
{
  "name": "speckit-updater",              // Plugin identifier (lowercase, no spaces)
  "version": "0.8.0",                      // Semantic version
  "description": "Safe updates...",        // Brief description (1-2 sentences)
  "author": {                              // Author information
    "name": "Bobby Johnson",
    "email": "bobby@notmyself.io",
    "url": "https://github.com/NotMyself"
  },
  "homepage": "https://github.com/...",   // Plugin homepage URL
  "repository": {                          // Repository information
    "type": "git",
    "url": "https://github.com/...git"
  },
  "license": "MIT",                        // License identifier
  "skills": "./skills/",                   // Path to skills directory (relative to repo root)
  "keywords": ["speckit", "automation"],   // Searchable tags
  "requirements": {                        // Prerequisites
    "powershell": ">=7.0",
    "git": ">=2.0"
  },
  "changelog": "https://github.com/.../CHANGELOG.md"  // Changelog URL
}
```

**Optional Fields**:
- `bugs`: Issue tracker URL
- `funding`: Sponsorship/funding links
- `engines`: Specific runtime version constraints

**Validation Rules**:
- `name` must be lowercase, alphanumeric + hyphens only
- `version` must follow semantic versioning (MAJOR.MINOR.PATCH)
- `skills` path must exist and contain at least one `.md` skill definition
- `repository.url` must be a valid Git URL

**Alternatives Considered**:
- Minimal manifest with only `name` and `version` - Rejected (insufficient metadata for discoverability)
- Embedding skills directly in manifest - Rejected (not supported by plugin system)
- Using `package.json` instead of `.claude-plugin/plugin.json` - Rejected (not the plugin system's convention)

---

### Q3: What is the required structure for marketplace manifests?

**Decision**: Marketplace manifest (`.claude-plugin/marketplace.json`) catalogs available plugins

**Rationale**:
- Marketplace serves as a directory of plugins for discoverability
- Users add marketplace once, then can browse and install multiple plugins
- Marketplace manifest hosted on GitHub, fetched via raw.githubusercontent.com

**Required Structure**:
```json
{
  "name": "notmyself-plugins",              // Marketplace identifier
  "description": "Claude Code plugins...",  // Marketplace description
  "author": {                               // Marketplace maintainer
    "name": "Bobby Johnson",
    "email": "bobby@notmyself.io",
    "url": "https://github.com/NotMyself"
  },
  "version": "1.0.0",                       // Marketplace catalog version
  "plugins": [                              // Array of plugin entries
    {
      "name": "speckit-updater",            // Must match plugin.json name
      "description": "Safe updates...",     // Plugin description
      "version": "0.8.0",                   // Current version (should match plugin.json)
      "source": "github:NotMyself/repo",    // Git repository reference
      "author": {                           // Plugin author
        "name": "Bobby Johnson",
        "email": "bobby@notmyself.io"
      },
      "homepage": "https://github.com/...", // Plugin homepage
      "tags": ["speckit", "automation"],     // Searchable tags
      "requirements": {                      // Prerequisites
        "powershell": ">=7.0",
        "git": ">=2.0"
      }
    }
  ]
}
```

**Source Format Options**:
- `"github:user/repo"` - GitHub repository
- `"gitlab:user/repo"` - GitLab repository
- `"git@github.com:user/repo.git"` - SSH Git URL
- `"https://github.com/user/repo.git"` - HTTPS Git URL
- `"file:///path/to/local/repo"` - Local Git repository (for development)

**Validation Rules**:
- Marketplace `name` must be unique across all marketplaces user has added
- Each plugin entry's `source` must be a valid Git repository
- Plugin `version` in marketplace should match latest version in plugin.json (not enforced, but recommended)

**Alternatives Considered**:
- Single plugin per marketplace repository - Rejected (limits scalability for future plugins)
- Flat array of plugin URLs without metadata - Rejected (insufficient for browsing/search)
- Dynamic plugin discovery via GitHub API - Rejected (not how Claude Code works; requires manifest)

---

### Q4: How does version management work in the plugin system?

**Decision**: Version management uses semantic versioning with Git tags

**Rationale**:
- Plugin system uses `version` field in plugin.json as source of truth
- Updates are handled by Git operations (pull latest, checkout tag)
- Marketplace manifest's `version` field should align with latest plugin release

**Best Practices**:
1. **Semantic Versioning** (MAJOR.MINOR.PATCH)
   - MAJOR: Breaking changes to plugin API or behavior
   - MINOR: New features, backward compatible
   - PATCH: Bug fixes, backward compatible

2. **Git Tag Alignment**
   - Create Git tag `v0.8.0` matching plugin.json version `0.8.0`
   - Users can reference specific versions via Git tags if supported by plugin system

3. **Release Workflow**
   1. Update `plugin.json` version field
   2. Update `CHANGELOG.md` with release notes
   3. Commit changes: `chore: prepare v0.8.0 release`
   4. Create Git tag: `git tag v0.8.0`
   5. Push tag: `git push origin v0.8.0`
   6. Create GitHub Release referencing tag
   7. Update marketplace.json in separate repository
   8. Commit marketplace update: `chore: update speckit-updater to v0.8.0`

4. **Version Synchronization**
   - Plugin repository's `plugin.json` version: `0.8.0`
   - Marketplace repository's plugin entry version: `0.8.0`
   - GitHub Release tag: `v0.8.0` (with 'v' prefix)
   - CHANGELOG.md header: `## [0.8.0] - 2025-10-25`

**Alternatives Considered**:
- Using branch names for versioning (e.g., `main`, `v1.x`) - Rejected (less precise than tags)
- Decoupling marketplace version from plugin version - Rejected (causes confusion and sync issues)
- Automatic version bumping via CI/CD - Deferred (manual versioning sufficient for v1)

---

### Q5: What are the installation commands and workflow?

**Decision**: Two-command installation via marketplace

**Installation Commands**:
```powershell
# Step 1: Add marketplace (one-time setup)
/plugin marketplace add NotMyself/claude-plugins

# Step 2: Install plugin
/plugin install speckit-updater

# Alternative: Specify marketplace explicitly
/plugin install speckit-updater@notmyself-plugins
```

**Browsing Commands**:
```powershell
# List all plugins in added marketplaces
/plugin

# Show plugin information
/plugin info speckit-updater
```

**Management Commands**:
```powershell
# Update plugin to latest version
/plugin update speckit-updater

# Disable plugin (don't remove)
/plugin disable speckit-updater

# Re-enable disabled plugin
/plugin enable speckit-updater

# Uninstall plugin completely
/plugin uninstall speckit-updater
```

**Installation Workflow** (Claude Code internal):
1. User runs `/plugin marketplace add NotMyself/claude-plugins`
2. Claude Code fetches `https://raw.githubusercontent.com/NotMyself/claude-plugins/main/.claude-plugin/marketplace.json`
3. Parses marketplace manifest and stores locally
4. User runs `/plugin install speckit-updater`
5. Claude Code looks up `speckit-updater` in added marketplaces
6. Finds entry in `notmyself-plugins` marketplace
7. Reads `source`: `github:NotMyself/claude-win11-speckit-update-skill`
8. Clones repository to `$env:USERPROFILE\.claude\plugins\speckit-updater`
9. Reads `.claude-plugin/plugin.json` from cloned repository
10. Validates manifest and checks requirements (PowerShell 7+, Git 2.0+)
11. Copies `skills/` directory to `$env:USERPROFILE\.claude\skills\speckit-updater`
12. Loads `SKILL.md` from skills directory
13. Makes `/speckit-update` command available

**Alternatives Considered**:
- Direct repository URL installation without marketplace - Not supported by Claude Code
- Interactive GUI for browsing plugins - Claude Code provides `/plugin` command for text-based browsing
- Automatic marketplace discovery - Not supported; users must explicitly add marketplaces

---

### Q6: How to ensure backward compatibility with manual installations?

**Decision**: Repository URL remains unchanged; restructuring is internal

**Rationale**:
- Manual installations clone the same GitHub repository (`NotMyself/claude-win11-speckit-update-skill`)
- Repository restructuring (adding `skills/` wrapper, `.claude-plugin/` directory) is transparent to manual installations
- Claude Code discovers skills in any `.claude/skills/` subdirectory, regardless of how they were installed

**Backward Compatibility Strategies**:

1. **Git Clone Compatibility**
   - Before: `git clone https://github.com/NotMyself/claude-win11-speckit-update-skill speckit-updater`
   - After: Same command, but cloned repository now has `skills/speckit-updater/SKILL.md` instead of `SKILL.md` at root
   - Claude Code behavior: Still loads skill from `skills/speckit-updater/SKILL.md` because it's in a subdirectory

2. **Test Suite Compatibility**
   - Move tests to `skills/speckit-updater/tests/` (alongside other skill content)
   - Update test runner paths if using absolute paths
   - Verify all 132 existing unit tests pass after restructuring

3. **Documentation Compatibility**
   - Keep `README.md`, `CLAUDE.md`, `CONTRIBUTING.md` at repository root (not moved to `skills/`)
   - Update documentation to reference new paths (e.g., `skills/speckit-updater/scripts/`)
   - Clearly document both installation methods (plugin vs manual)

4. **Workflow Compatibility**
   - GitHub Actions: Update workflow paths if referencing scripts directly
   - Test runner: Update module import paths if using relative paths
   - Example: `./scripts/update-orchestrator.ps1` → `./skills/speckit-updater/scripts/update-orchestrator.ps1`

**Testing Requirements**:
- Create `tests/integration/PluginCompatibility.Tests.ps1` to validate:
  - Manual installation from restructured repository works
  - Plugin installation works
  - Migration from manual to plugin works
  - Side-by-side installations are detected
- Run existing test suite from new location and verify 100% pass rate

**Alternatives Considered**:
- Creating separate branches for plugin vs manual - Rejected (increases maintenance burden)
- Using Git submodules to structure code - Rejected (overcomplicates; unnecessary for simple directory wrapper)
- Deprecating manual installation entirely - Rejected (violates backward compatibility requirement)

---

### Q7: What are the path resolution implications of restructuring?

**Decision**: Document all path changes and create validation tests

**Impacted Areas**:

1. **Test Runner** (`tests/test-runner.ps1`)
   - Current: `Join-Path $PSScriptRoot ".." "scripts" "modules"`
   - After restructuring: Path is now `Join-Path $PSScriptRoot "scripts" "modules"` (tests moved inside `skills/speckit-updater/`)
   - Validation: Run `./skills/speckit-updater/tests/test-runner.ps1` and verify all tests pass

2. **Module Imports** (`scripts/update-orchestrator.ps1`)
   - Current: `Import-Module (Join-Path $modulesPath "HashUtils.psm1")`
   - After restructuring: Paths remain valid (relative to orchestrator script location, which moves with modules)
   - Validation: Verify orchestrator can import all modules after restructuring

3. **Helper Script Dot-Sourcing** (`scripts/update-orchestrator.ps1`)
   - Current: `. (Join-Path $helpersPath "Show-UpdateSummary.ps1")`
   - After restructuring: Paths remain valid (relative paths preserved)
   - Validation: Verify all helper scripts load correctly

4. **Data File References** (`scripts/modules/FingerprintDetector.psm1`)
   - Current: `Join-Path $PSScriptRoot ".." ".." "data" "speckit-fingerprints.json"`
   - After restructuring: Path changes to `Join-Path $PSScriptRoot ".." "data" "speckit-fingerprints.json"` (fewer parent directory traversals)
   - Validation: Verify fingerprint database loads successfully

5. **GitHub Actions Workflows** (`.github/workflows/*.yml`)
   - Current: `run: pwsh -Command "./scripts/update-orchestrator.ps1"`
   - After restructuring: `run: pwsh -Command "./skills/speckit-updater/scripts/update-orchestrator.ps1"`
   - Validation: Run workflows in CI/CD after restructuring

6. **Spec File References** (`specs/` directory)
   - Current: Specs at root `specs/001-safe-update/spec.md`
   - After restructuring: Specs moved to `skills/speckit-updater/specs/`
   - Validation: Verify all spec file paths in documentation are updated

**Mitigation Strategy**:
- Phase 2 (tasks generation) will include explicit path validation tasks
- Create test that verifies all file references resolve correctly after restructuring
- Document path changes in migration guide (`docs/migration-guide-plugin.md`)

**Alternatives Considered**:
- Using absolute paths throughout codebase - Rejected (reduces portability)
- Creating symlinks for backward compatibility - Rejected (doesn't work cross-platform)
- Keeping scripts at root and only moving SKILL.md - Rejected (violates plugin system's `skills/` directory convention)

---

## Key Takeaways for Implementation

### Phase 1: Marketplace Setup

**Deliverables**:
1. Create `NotMyself/claude-plugins` repository on GitHub
2. Create `.claude-plugin/marketplace.json` with `speckit-updater` entry
3. Create marketplace `README.md` with installation instructions
4. Add `LICENSE` and `.gitignore`
5. Push to GitHub and verify manifest is accessible via raw.githubusercontent.com

**Success Criteria**:
- Marketplace manifest is valid JSON
- Can fetch manifest via `/plugin marketplace add NotMyself/claude-plugins`

---

### Phase 2: Repository Restructuring

**Deliverables**:
1. Create `.claude-plugin/plugin.json` at repository root
2. Create `skills/` directory at root
3. Move content to `skills/speckit-updater/`:
   - `SKILL.md`
   - `scripts/` (including modules, helpers, orchestrator)
   - `tests/` (including unit and integration tests)
   - `templates/`
   - `specs/`
   - `data/`
4. Update path references in test runner and workflows
5. Commit restructuring as atomic commit: `refactor: restructure as plugin for v0.8.0`

**Success Criteria**:
- All 132 existing unit tests pass from new location
- Test runner executes successfully: `./skills/speckit-updater/tests/test-runner.ps1`
- No broken module imports or file references

---

### Phase 3: Testing & Validation

**Deliverables**:
1. Create `tests/integration/PluginCompatibility.Tests.ps1`
2. Test scenarios:
   - Manual Git clone from restructured repository
   - Plugin installation via marketplace
   - Migration from manual to plugin
   - Side-by-side installation detection
3. Path validation tests for all relative file references
4. Documentation of test execution for both installation modes

**Success Criteria**:
- All backward compatibility tests pass
- Manual installation workflow verified
- Plugin installation workflow verified
- No regressions in existing test suite

---

### Phase 4: Documentation & Release

**Deliverables**:
1. Update `README.md` with plugin installation instructions (prominently featured)
2. Update `CLAUDE.md` distribution model section
3. Update `CONTRIBUTING.md` with plugin structure guidance
4. Create migration guide: `docs/migration-guide-plugin.md`
5. Update `CHANGELOG.md` with v0.8.0 release notes
6. Create GitHub Release with detailed notes
7. Update marketplace.json to reference v0.8.0

**Success Criteria**:
- Plugin installation is the recommended method in docs
- Manual installation method still documented as alternative
- Migration guide provides clear step-by-step instructions
- All documentation reviewed and validated for accuracy

---

## Unresolved Questions

**None** - All research questions have been answered with decisions documented above.

## References

- [Claude Code Plugins Documentation](https://docs.claude.com/en/docs/claude-code/plugins.md)
- [Claude Code Plugin Marketplaces](https://docs.claude.com/en/docs/claude-code/plugin-marketplaces.md)
- [Claude Code Plugins Reference](https://docs.claude.com/en/docs/claude-code/plugins-reference.md)
- [PRD: Plugin-Based Distribution](../../docs/PRDs/006-Plugin-Based-Distribution.md)
- [Project Constitution](.specify/memory/constitution.md)
