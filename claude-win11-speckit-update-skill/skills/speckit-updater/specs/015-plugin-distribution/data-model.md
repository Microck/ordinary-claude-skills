# Phase 1: Data Model - Plugin-Based Distribution

**Feature**: Plugin-Based Distribution | **Date**: 2025-10-25
**Status**: Complete | **Plan**: [plan.md](plan.md) | **Research**: [research.md](research.md)

## Overview

This document defines the structure of plugin and marketplace manifest files used by Claude Code's plugin system for distributing the SpecKit Safe Update Skill.

## Entities

### Plugin Manifest

**Purpose**: Declares plugin metadata and configuration for Claude Code's plugin system

**Location**: `.claude-plugin/plugin.json` (repository root)

**Lifecycle**: Created once during repository restructuring; updated when version changes or metadata needs updating

**Fields**:

| Field | Type | Required | Description | Validation Rules |
|-------|------|----------|-------------|------------------|
| `name` | string | Yes | Plugin identifier (used in install commands) | Lowercase, alphanumeric + hyphens only; no spaces |
| `version` | string | Yes | Semantic version | Format: `MAJOR.MINOR.PATCH` (e.g., `0.8.0`) |
| `description` | string | Yes | Brief plugin description | 1-2 sentences; displayed in `/plugin` browse output |
| `author` | object | Yes | Author information | See Author structure below |
| `homepage` | string | Yes | Plugin homepage URL | Valid HTTPS URL; typically GitHub repository |
| `repository` | object | Yes | Git repository details | See Repository structure below |
| `license` | string | Yes | License identifier | SPDX license identifier (e.g., `MIT`, `Apache-2.0`) |
| `skills` | string | Yes | Path to skills directory | Relative path from repo root; must exist and contain `.md` files |
| `keywords` | array[string] | Yes | Searchable tags | Lowercase keywords for discoverability |
| `requirements` | object | Yes | Prerequisites | Key-value pairs of tool: version constraint |
| `changelog` | string | Yes | Changelog URL | Valid HTTPS URL; typically GitHub CHANGELOG.md |
| `bugs` | string | No | Issue tracker URL | Valid HTTPS URL; typically GitHub issues |
| `funding` | array[object] | No | Sponsorship links | See Funding structure below |

**Author Structure**:
```typescript
{
  name: string      // Full name (e.g., "Bobby Johnson")
  email: string     // Contact email
  url?: string      // Personal website or GitHub profile URL
}
```

**Repository Structure**:
```typescript
{
  type: "git"       // Always "git" for Claude Code plugins
  url: string       // Full Git repository URL with .git extension
}
```

**Funding Structure** (optional):
```typescript
{
  type: string      // "github", "patreon", "opencollective", "custom"
  url: string       // Funding platform URL
}
```

**Requirements Structure**:
```typescript
{
  [tool: string]: string    // Tool name: version constraint (npm semver format)
}
// Example:
{
  "powershell": ">=7.0",
  "git": ">=2.0"
}
```

**Example** (for SpecKit Safe Update Skill):
```json
{
  "name": "speckit-updater",
  "version": "0.8.0",
  "description": "Safe updates for GitHub SpecKit installations, preserving your customizations",
  "author": {
    "name": "Bobby Johnson",
    "email": "bobby@notmyself.io",
    "url": "https://github.com/NotMyself"
  },
  "homepage": "https://github.com/NotMyself/claude-win11-speckit-safe-update-skill",
  "repository": {
    "type": "git",
    "url": "https://github.com/NotMyself/claude-win11-speckit-safe-update-skill.git"
  },
  "license": "MIT",
  "skills": "./skills/",
  "keywords": [
    "speckit",
    "automation",
    "templates",
    "powershell",
    "updates"
  ],
  "requirements": {
    "powershell": ">=7.0",
    "git": ">=2.0"
  },
  "changelog": "https://github.com/NotMyself/claude-win11-speckit-safe-update-skill/blob/main/CHANGELOG.md"
}
```

**Relationships**:
- **One-to-many with skills**: Plugin contains one or more skill definitions (`.md` files) in the `skills/` directory
- **Referenced by marketplace**: Marketplace manifest entries point to this plugin via `source` field

**State Transitions**: None (static metadata file; version updates are discrete changes, not state transitions)

---

### Marketplace Manifest

**Purpose**: Catalog of available plugins for discoverability and installation

**Location**: `.claude-plugin/marketplace.json` (marketplace repository root, e.g., `NotMyself/claude-plugins`)

**Lifecycle**: Created once when marketplace is established; updated when plugins are added/updated/removed

**Fields**:

| Field | Type | Required | Description | Validation Rules |
|-------|------|----------|-------------|------------------|
| `name` | string | Yes | Marketplace identifier | Lowercase, alphanumeric + hyphens; unique across user's added marketplaces |
| `description` | string | Yes | Marketplace description | Brief summary of marketplace purpose and scope |
| `author` | object | Yes | Marketplace maintainer | See Author structure (same as Plugin Manifest) |
| `version` | string | Yes | Marketplace catalog version | Semantic version; increment when plugins added/updated |
| `plugins` | array[object] | Yes | Plugin entries | Array of Plugin Entry objects; at least one required |

**Plugin Entry Structure**:
```typescript
{
  name: string                 // Plugin identifier (must match plugin.json name)
  description: string          // Plugin description (brief summary)
  version: string              // Current plugin version (should match plugin.json)
  source: string               // Git repository reference (see Source Formats below)
  author: object               // Plugin author (see Author structure)
  homepage: string             // Plugin homepage URL
  tags: array[string]          // Searchable tags/keywords
  requirements: object         // Prerequisites (see Requirements structure)
}
```

**Source Formats**:
- `github:user/repo` - GitHub repository shorthand
- `gitlab:user/repo` - GitLab repository shorthand
- `git@github.com:user/repo.git` - SSH Git URL
- `https://github.com/user/repo.git` - HTTPS Git URL
- `file:///path/to/repo` - Local Git repository (development only)

**Example** (NotMyself marketplace):
```json
{
  "name": "notmyself-plugins",
  "description": "Claude Code plugins by NotMyself for SpecKit workflow automation",
  "author": {
    "name": "Bobby Johnson",
    "email": "bobby@notmyself.io",
    "url": "https://github.com/NotMyself"
  },
  "version": "1.0.0",
  "plugins": [
    {
      "name": "speckit-updater",
      "description": "Safe updates for GitHub SpecKit installations, preserving your customizations",
      "version": "0.8.0",
      "source": "github:NotMyself/claude-win11-speckit-safe-update-skill",
      "author": {
        "name": "Bobby Johnson",
        "email": "bobby@notmyself.io"
      },
      "homepage": "https://github.com/NotMyself/claude-win11-speckit-safe-update-skill",
      "tags": ["speckit", "automation", "templates", "powershell"],
      "requirements": {
        "powershell": ">=7.0",
        "git": ">=2.0"
      }
    }
  ]
}
```

**Relationships**:
- **Many-to-many with plugins**: Marketplace can list multiple plugins; a plugin can appear in multiple marketplaces
- **References plugin manifest**: Each plugin entry's `source` points to a Git repository containing `.claude-plugin/plugin.json`

**State Transitions**: None (static catalog; additions/updates are discrete changes, not state transitions)

---

### Skill Directory Structure

**Purpose**: Contains skill operational files after restructuring

**Location**: `skills/speckit-updater/` (within plugin repository)

**Contents**:

| Item | Type | Description |
|------|------|-------------|
| `SKILL.md` | File | Skill definition for Claude Code |
| `scripts/` | Directory | PowerShell modules, helpers, orchestrator |
| `scripts/modules/` | Directory | Business logic modules (`.psm1` files) |
| `scripts/helpers/` | Directory | Orchestration helpers (`.ps1` files) |
| `scripts/update-orchestrator.ps1` | File | Main skill entry point |
| `tests/` | Directory | Pester test suites |
| `tests/unit/` | Directory | Module unit tests |
| `tests/integration/` | Directory | End-to-end workflow tests |
| `templates/` | Directory | Manifest templates |
| `specs/` | Directory | Feature specifications |
| `data/` | Directory | Fingerprint database |

**Relationships**:
- **Parent**: Plugin repository (contains this directory structure)
- **Referenced by**: Plugin manifest's `skills` field (`"./skills/"`)
- **Discovered by**: Claude Code plugin system (copies to `$env:USERPROFILE\.claude\skills\speckit-updater`)

**State Transitions**:
- **Pre-restructuring**: Content at repository root
- **Post-restructuring**: Content moved to `skills/speckit-updater/` subdirectory
- **Transition trigger**: Repository restructuring (Phase 2 of implementation)

---

## Validation Rules

### Plugin Manifest Validation

**Required Field Checks**:
- All required fields must be present
- No fields can be `null` or empty strings

**Format Validation**:
- `name`: Matches regex `^[a-z0-9]+(-[a-z0-9]+)*$` (lowercase alphanumeric + hyphens)
- `version`: Matches semantic version regex `^\d+\.\d+\.\d+$`
- `homepage`: Valid HTTPS URL
- `repository.url`: Valid Git URL (ends with `.git`)
- `skills`: Path exists and contains at least one `.md` file
- `license`: Valid SPDX identifier
- `changelog`: Valid HTTPS URL

**Relationship Validation**:
- `skills` directory contains `SKILL.md` or other skill definitions
- Referenced repository (in `repository.url`) exists and is accessible

### Marketplace Manifest Validation

**Required Field Checks**:
- All required fields must be present
- `plugins` array must contain at least one entry

**Plugin Entry Validation**:
- Each plugin entry has all required fields
- `source` is a valid Git repository reference
- `version` matches semantic version format

**Uniqueness Checks**:
- All plugin `name` values in `plugins` array are unique
- Marketplace `name` is unique across user's added marketplaces (validated by Claude Code)

**Relationship Validation**:
- Each plugin's `source` points to a Git repository
- Target repository contains `.claude-plugin/plugin.json`
- Plugin entry's `name` matches the `name` in target repository's `plugin.json`

---

## Assumptions

1. **Claude Code Version**: Plugin system behavior is based on current Claude Code documentation (as of 2025-10-25)
2. **JSON Format**: All manifests are standard JSON (not JSON5, JSONC, or other variants)
3. **UTF-8 Encoding**: All manifest files use UTF-8 encoding without BOM
4. **Git Availability**: Git must be installed and accessible for plugin installation to work
5. **Network Access**: Installing plugins requires network access to fetch Git repositories (except local development with `file://` URLs)
6. **Semantic Versioning**: All versions follow semantic versioning strictly (no pre-release tags like `0.8.0-beta`)

---

## Edge Cases

### Plugin Manifest Edge Cases

1. **Missing Skills Directory**
   - **Scenario**: `skills` path in manifest doesn't exist in repository
   - **Behavior**: Plugin installation should fail with clear error message
   - **Mitigation**: Validate directory existence during Phase 2 restructuring

2. **Version Mismatch**
   - **Scenario**: `plugin.json` version (`0.8.0`) doesn't match marketplace entry version (`0.7.0`)
   - **Behavior**: Claude Code uses plugin.json version as source of truth; marketplace version is informational
   - **Mitigation**: Document version synchronization in release workflow

3. **Invalid Semantic Version**
   - **Scenario**: Version like `v0.8.0` (with 'v' prefix) or `0.8` (missing patch)
   - **Behavior**: Plugin system should reject invalid version format
   - **Mitigation**: Use version validation in CI/CD pipeline

4. **Circular Dependencies**
   - **Scenario**: Plugin requires another plugin that doesn't exist or creates circular dependency
   - **Behavior**: Not applicable (Claude Code plugin system doesn't support plugin dependencies)
   - **Mitigation**: None needed; requirements are for external tools (PowerShell, Git), not other plugins

### Marketplace Manifest Edge Cases

1. **Duplicate Plugin Names**
   - **Scenario**: Two plugin entries in marketplace have same `name`
   - **Behavior**: Claude Code behavior undefined; likely uses first match
   - **Mitigation**: Add validation check in marketplace repository CI/CD

2. **Unreachable Git Repository**
   - **Scenario**: Plugin entry's `source` points to private repository or non-existent URL
   - **Behavior**: Installation fails with network error
   - **Mitigation**: Document that all plugin repositories must be public and accessible

3. **Malformed JSON**
   - **Scenario**: Marketplace manifest contains invalid JSON syntax
   - **Behavior**: Claude Code cannot parse manifest; marketplace addition fails
   - **Mitigation**: Use JSON validation in marketplace repository CI/CD

4. **Empty Plugins Array**
   - **Scenario**: Marketplace has `"plugins": []` (no plugins listed)
   - **Behavior**: Marketplace adds successfully but has no installable plugins
   - **Mitigation**: Document that marketplaces should have at least one plugin before publishing

---

## Migration Considerations

### From Manual Installation to Plugin Format

**Data Preservation**:
- Existing `.specify/manifest.json` is NOT affected by repository restructuring
- User's SpecKit project manifests remain unchanged
- No data migration required for user projects

**Path Updates**:
- Test runner paths: Update relative imports after moving to `skills/speckit-updater/tests/`
- Module imports: Paths relative to orchestrator script remain valid (move together)
- Data file references: Update parent directory traversals (fewer `..` after restructuring)

**Backward Compatibility**:
- Manual `git clone` continues to work (repository URL unchanged)
- Claude Code discovers skills in `skills/speckit-updater/SKILL.md` regardless of installation method
- Existing users can continue using manual installation indefinitely (no forced migration)

---

## References

- [Plugin Manifest Schema (Contract)](contracts/plugin-manifest.schema.json)
- [Marketplace Manifest Schema (Contract)](contracts/marketplace-manifest.schema.json)
- [Research Document](research.md)
- [Claude Code Plugins Reference](https://docs.claude.com/en/docs/claude-code/plugins-reference.md)
