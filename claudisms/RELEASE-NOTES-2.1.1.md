# Claudisms v2.1.1 Release Notes

**Release Date:** 2025-11-03

## Fixed

### Slash Commands Marketplace Targeting
- **Critical Fix:** Slash commands now correctly target marketplace installation location (`~/.claude/plugins/marketplaces/claudisms/`) instead of dev repo
- Previously, `/claudisms-settings` modified dev repo settings while active hooks read from marketplace location
- Both `claudisms-settings.sh` and `claudisms-reload.sh` now detect and prioritize marketplace location
- Resolves issue where `doc_limits=off` setting appeared to not work

### Enhanced Settings Documentation
- Added comprehensive settings behavior documentation to README.md
- Detailed how settings work (key=value format, read via `lib/settings-loader.sh`)
- Documented hook behavior for each setting value (on/off/exclude)
- Added settings file location guide (marketplace vs dev repo)
- Included troubleshooting steps for settings not applying

### Code Quality & Tooling
- Added fd/rg (ripgrep) preference to core principles
- Session hook now recommends fd/rg over find/grep when available
- Removed duplicate `claude.md` file (kept `CLAUDE.md` for project guidance)

## Changed

### README.md Enhancements
- Expanded settings reference table with detailed descriptions
- Added "How settings work" section explaining execution-time behavior
- Added "Hook behavior" section with examples for each setting mode
- Added "Settings File Locations" section
- Added "Editing settings" instructions (slash commands + manual)
- Enhanced troubleshooting guide

### Documentation Structure
- Clarified distinction between `/home/agent/CLAUDE.md` (general) and `/home/agent/claudisms/CLAUDE.md` (plugin-specific)
- Removed lowercase `claude.md` to avoid confusion
- Updated CLAUDE.md with fd/rg preference guidelines

## Technical Details

### RCA: doc_limits Setting Not Working
**Root Cause:** Slash commands modified `/home/agent/claudisms/.claudisms-settings` (dev repo), but active hooks read from `~/.claude/plugins/marketplaces/claudisms/.claudisms-settings` (installed location).

**Fix:** Modified both slash command scripts (commands/claudisms-settings.sh:7-12, commands/claudisms-reload.sh:7-12) to check for marketplace directory first:

```bash
if [[ -d ~/.claude/plugins/marketplaces/claudisms ]]; then
  CLAUDE_PLUGIN_ROOT=~/.claude/plugins/marketplaces/claudisms
elif [[ -z "${CLAUDE_PLUGIN_ROOT}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  CLAUDE_PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
fi
```

## Installation

```bash
# Via Claude Code Marketplace (recommended)
/plugin
# Add marketplace: jeffersonwarrior/claudisms
# Install and enable

# Update existing installation
/plugin
# Select claudeisms and update
```

## Upgrade Notes

**Settings Migration:** If you previously modified settings in dev repo, re-apply them:

```bash
/claudisms-settings set doc_limits off  # Example
/claudisms-reload
```

Settings now correctly persist to marketplace location.

## Files Changed

- `claude-plugin.json` (version bump to 2.1.1)
- `.claude-plugin/plugin.json` (version bump to 2.1.1)
- `CLAUDE.md` (added fd/rg preference)
- `README.md` (enhanced settings documentation)
- `commands/claudisms-reload.sh` (marketplace targeting fix)
- `commands/claudisms-settings.sh` (marketplace targeting fix)
- `hooks-handlers/session-start.sh` (fd/rg preference)
- `claude.md` (removed duplicate)

## Commits Since v2.1.0

- edd41d1 Fix slash commands marketplace targeting and add fd/rg preference
- 8dece89 Fix plugin.json commands schema - use .md files not objects
- 48d269d Fix uninstaller to clean settings.json files
- 89f5820 Add uninstaller script for complete plugin removal

## Contributors

- Jefferson Warrior (@jeffersonwarrior)
- Claude (AI pair programmer)

## Links

- Repository: https://github.com/jeffersonwarrior/claudisms
- Issues: https://github.com/jeffersonwarrior/claudisms/issues
- Marketplace: `jeffersonwarrior/claudisms`
