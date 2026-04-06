# Claudeisms

Claude Code plugin enforcing operational guidelines and terse responses.

## Features

- Terse, code-first responses (1-2 sentences max)
- Sequential execution protocols
- No destructive operations without confirmation
- Minimal documentation (200 words max for .md files)
- Test after every task
- RCA after 2+ revisits
- No emoji, no production claims
- Script reuse over recreation
- Prefer fd/rg over find/grep when available

## Installation

### Via Claude Code Marketplace (Recommended)

1. Run `/plugin` in Claude Code
2. Add marketplace: `jeffersonwarrior/claudisms`
3. Install the plugin
4. Restart Claude Code

### Clean Install/Reinstall

If experiencing issues or upgrading from a broken version:

```bash
cd ~/.claude/plugins/marketplaces
git clone https://github.com/jeffersonwarrior/claudisms.git
cd claudisms
./clean-install.sh
```

The script removes old installations, backs up settings, reinstalls the plugin, and restarts Claude Code.

### Manual Installation

```bash
cd ~/.claude/plugins
git clone https://github.com/jeffersonwarrior/claudisms.git
```

Then restart Claude Code and enable hooks in Settings → Plugins → Claudisms

## Hooks

- **SessionStart**: Activates core guidelines
- **BeforeToolUse(Write)**: Limits .md files to 200 words

## Configuration

Plugin settings stored in `claudisms.json` at plugin root:

```json
{
  "enabled": true,
  "responseStyle": "terse",
  "useCodeReferences": true,
  "useSubagents": true,
  "testAfterChanges": true,
  "maxResponseLength": 2,
  "avoidWorkarounds": true,
  "requireConfirmationForDestructiveOps": true,
  "requireConfirmationForProductionPush": true,
  "preferCurrentVersions": true,
  "performRCAAfterMultipleRevisits": true,
  "reuseScripts": true,
  "preferFdRg": true,
  "noEmoji": true,
  "noPleasantries": true
}
```

### Settings Reference

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `enabled` | boolean | true | Master switch for plugin |
| `responseStyle` | string | "terse" | Response verbosity ("terse" or "verbose") |
| `useCodeReferences` | boolean | true | Include file:line references in responses |
| `useSubagents` | boolean | true | Use Task tool for multi-file searches |
| `testAfterChanges` | boolean | true | Run tests after code modifications |
| `maxResponseLength` | number | 2 | Max sentences for simple tasks |
| `avoidWorkarounds` | boolean | true | Implement primary solution first |
| `requireConfirmationForDestructiveOps` | boolean | true | Confirm `rm -rf`, database deletes |
| `requireConfirmationForProductionPush` | boolean | true | Confirm production deployments |
| `preferCurrentVersions` | boolean | true | Use latest stable versions |
| `performRCAAfterMultipleRevisits` | boolean | true | Root cause analysis after 2+ attempts |
| `reuseScripts` | boolean | true | Reuse working scripts vs recreate |
| `preferFdRg` | boolean | true | Use fd/rg over find/grep |
| `noEmoji` | boolean | true | Disable emoji in responses |
| `noPleasantries` | boolean | true | Skip greetings/confirmations |

### Slash Commands

**View current settings:**
```
/claudisms-settings
```

**Reload settings after manual edits:**
```
/claudisms-reload
```

Settings location: `~/.claude/plugins/marketplaces/claudisms/claudisms.json` (marketplace) or `~/.claude/plugins/claudisms/claudisms.json` (manual install)


## Core Principles

- Sequential execution only - no weeks, numerical order
- Terse responses - less is more
- Code-first - show immediately without preamble
- Test after every task
- No database/folder deletion without confirmation
- No production pushes without confirmation
- Current versions only
- Ask for clarification when irrational
- Never blame user
- RCA after 2+ revisits
- Prefer fd/rg over find/grep when available
- Recommend fd/rg installation if not available
- Implement primary solution - try harder before choosing workarounds

## Author

Jefferson Warrior - [GitHub](https://github.com/jeffersonwarrior)

## License

GPL v3

---

## Uninstallation

Removing the plugin from the marketplace does not clean up all configuration. Use the included uninstaller script:

```bash
# Remove this plugin
~/claudisms/claude-plugin-uninstall.sh claudeisms@claudisms

# Remove all plugins
~/claudisms/claude-plugin-uninstall.sh --all

# Check plugin status
~/claudisms/claude-plugin-uninstall.sh
```

The uninstaller:
- Creates automatic backups before removal
- Cleans `~/.claude/plugins/installed_plugins.json`
- Removes plugin files from `~/.claude/plugins/marketplaces/`
- Detects and reports broken plugins (missing files)

## Settings File Locations

**Installed plugin:** `~/.claude/plugins/marketplaces/claudisms/.claudisms-settings` (active hooks read from here)

**Dev repo:** `/path/to/claudisms/.claudisms-settings` (for local development only)

Slash commands automatically target the marketplace location when installed, or dev repo location when running from source.

**Editing settings:**
```bash
# Use slash commands (recommended)
/claudisms-settings set doc_limits off
/claudisms-reload

# Or edit manually
nano ~/.claude/plugins/marketplaces/claudisms/.claudisms-settings
# Then reload: /claudisms-reload
```

## Troubleshooting

**Settings not applying:**
1. Verify correct file: `cat ~/.claude/plugins/marketplaces/claudisms/.claudisms-settings`
2. Run `/claudisms-reload` after changes
3. Enable debug: `/claudisms-settings set debug_logging on`
4. Check logs: `ls -lt ${PWD}/tmp/hook-env-*.log | head -5`

**Marketplace naming:** Use `jeffersonwarrior/claudisms` when adding. Plugin name is `claudeisms`, marketplace is `claudisms`, settings show `claudeisms@claudisms` - this is correct.

**Path requirements:** All manifest paths must start with `./` and resolve from plugin root. Example: `.claude-plugin/plugin.json` uses `"hooks": "./hooks.json"` not `"../../hooks.json"`.
