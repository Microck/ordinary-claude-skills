# Claudisms Settings Documentation

## Overview

Claudisms 2.2 introduces a JSON-based settings system for fine-grained control over plugin behavior. Settings are stored in `~/.claude/plugins/marketplaces/claudisms/settings.json`.

## Quick Start

```bash
# Interactive TUI configuration
/home/agent/claudisms/bin/set-claudisms

# View current settings
/home/agent/claudisms/bin/set-claudisms --show
```

## Settings Schema

### intelligentWrites

**Type:** `boolean`
**Default:** `true`
**Description:** Enables context-aware write policies with length limits for documentation files.

**Behavior:**
- CLAUDE.md: Max 50 lines, enforces "## Update: [date]" format
- agents.md: Max 30 lines
- *.plan.md: Structured updates with section headers
- Other files: Full access

### selfConfigAccess

**Type:** `object`
**Default:** `{ "enabled": true, ... }`
**Description:** Controls Claude's ability to modify plugin configuration files.

**Fields:**
- `enabled` (boolean): Allow self-configuration (default: true)
- `allowedFiles` (array): Whitelisted config files
- `requireBackup` (boolean): Auto-backup before changes (default: true)
- `maxChangesPerSession` (number): Limit edits per session (default: 10)

**Safeguards:**
- Auto-backup to `.settings-backups/settings.TIMESTAMP.json`
- JSON validation after write
- Rollback on validation failure
- Audit log in `.claudisms/changes.log`

**Example:**
```json
{
  "selfConfigAccess": {
    "enabled": true,
    "allowedFiles": [
      "settings.json",
      "hooks.json",
      "preferences.json",
      ".claudisms/config.json"
    ],
    "requireBackup": true,
    "maxChangesPerSession": 10
  }
}
```

### directoryJail

**Type:** `object`
**Default:** `{ "enabled": false, ... }`
**Description:** Optional filesystem access restrictions. **Disabled by default** for full access.

**Fields:**
- `enabled` (boolean): Enable jail mode (default: false)
- `jailRoot` (string|null): Root directory when jailed (e.g., "/home/agent")
- `allowedPaths` (array): Whitelist additional paths when jailed
- `blockPaths` (array): Blacklist paths (enforced when jailed)

**Behavior:**
- `enabled: false` → Full filesystem access (respects OS permissions)
- `enabled: true` → Restrict to jailRoot + allowedPaths
- Always respects OS-level permissions (can't read root-only files as user)

**Example:**
```json
{
  "directoryJail": {
    "enabled": false,
    "jailRoot": null,
    "allowedPaths": [],
    "blockPaths": [
      "/etc/shadow",
      "/root",
      "/proc"
    ]
  }
}
```

### verboseHooks

**Type:** `boolean`
**Default:** `false`
**Description:** Show hook execution details for debugging.

**Output Example:**
```
[Hook] SessionStart: injecting operational guidelines
[Hook] PreToolUse(Write): checking CLAUDE.md length limit
```

### autoSubagents

**Type:** `boolean`
**Default:** `true`
**Description:** Automatically suggest subagents for complex search tasks.

**Triggers:**
- Multi-file searches (>3 files)
- Ambiguous queries requiring exploration
- Architecture understanding tasks

### conciseMode

**Type:** `boolean`
**Default:** `true`
**Description:** Enforce terse responses (1-2 sentences for simple tasks).

**Guidelines:**
- Simple tasks: 1-2 sentences
- Complex tasks: Structured sections
- No preambles or pleasantries

### blockEssays

**Type:** `boolean`
**Default:** `true`
**Description:** Prevent 500-line documentation dumps to CLAUDE.md.

**Behavior:**
- Detect essays (>200 words) before write
- Suggest creating separate project-specific docs
- Enforce summary-only updates

### backupConfigs

**Type:** `boolean`
**Default:** `true`
**Description:** Auto-backup configuration files before changes.

**Backup Location:** `.settings-backups/settings.TIMESTAMP.json`

## Advanced Configuration

### Write Policy Rules

Controlled by `intelligentWrites`, these rules apply per file type:

```typescript
const writeRules = {
  'CLAUDE.md': {
    mode: WriteMode.SUMMARY_ONLY,
    maxLines: 50,
    requireConciseness: true,
    blockEssays: true
  },
  'agents.md': {
    mode: WriteMode.SUMMARY_ONLY,
    maxLines: 30
  },
  '*.plan.md': {
    mode: WriteMode.STRUCTURED,
    allowAppends: true,
    requireSectionHeaders: true
  },
  'settings.json': {
    mode: WriteMode.FULL_ACCESS,
    requireValidation: true
  }
}
```

### Directory Jail Example (Restricted Mode)

```json
{
  "directoryJail": {
    "enabled": true,
    "jailRoot": "/home/agent",
    "allowedPaths": [
      "/tmp",
      "/var/log/myapp"
    ],
    "blockPaths": [
      "/etc/shadow",
      "/root",
      "/proc"
    ]
  }
}
```

## Migration from v2.1

Claudisms 2.2 is backward compatible. Existing `.claudisms-settings` files are still respected.

To migrate to JSON settings:

```bash
# Create default settings.json
/home/agent/claudisms/bin/set-claudisms --show

# Edit settings interactively
/home/agent/claudisms/bin/set-claudisms
```

Legacy mode: Add `"legacy_mode": true` to preserve v2.1 behavior.

## Troubleshooting

### Settings not applying

1. Check file location: `~/.claude/plugins/marketplaces/claudisms/settings.json`
2. Validate JSON: `jq . settings.json` or `python3 -m json.tool settings.json`
3. Restart Claude Code to reload plugin

### Backup restoration

```bash
# List backups
ls -lt ~/.claude/plugins/marketplaces/claudisms/.settings-backups/

# Restore from backup
cp ~/.claude/plugins/marketplaces/claudisms/.settings-backups/settings.20251104_120000.json \
   ~/.claude/plugins/marketplaces/claudisms/settings.json
```

### Invalid JSON errors

The TUI automatically validates and rolls back on errors. Manual edits require validation:

```bash
# Validate JSON
jq empty settings.json && echo "Valid" || echo "Invalid"
```

## File Locations

- **Development:** `/home/agent/claudisms/settings.example.json`
- **Production:** `~/.claude/plugins/marketplaces/claudisms/settings.json`
- **Backups:** `~/.claude/plugins/marketplaces/claudisms/.settings-backups/`
- **TUI Tool:** `/home/agent/claudisms/bin/set-claudisms`
