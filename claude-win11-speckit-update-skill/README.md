# SpecKit Safe Update - Claude Code Skill

Safe updates for GitHub SpecKit installations, preserving your customizations.

## Overview

This Claude Code skill provides a safe, automated way to update SpecKit templates, commands, and scripts while preserving user customizations, eliminating the need for destructive `specify init --force` updates.

## Features

- **Smart Merge with Frictionless Onboarding** (New in v0.6.0): Automatic version detection and intelligent 3-way merge
  - **Zero conflicts** for first-time users with unmodified SpecKit installations (was ~15)
  - **Fingerprint-based version detection**: Fast signature check (<100ms) identifies installed SpecKit version automatically
  - **Intelligent 3-way merge**: Section-level semantic understanding reduces conflicts from ~15 to 0-2
  - **No user configuration**: Fully automatic operation, works out of the box
- **Automatic SpecKit Installation** (v0.4.0): Offers to install SpecKit in non-SpecKit projects with one command
- **Customization Preservation**: Automatically detects and preserves your customized files
- **Smart Conflict Resolution**: Intelligent two-tier conflict handling
  - Small files (â‰¤100 lines): Git conflict markers with VSCode CodeLens integration
  - Large files (>100 lines): Side-by-side Markdown diff files for easier review
- **False Positive Detection**: Auto-resolves conflicts where files are identical to upstream
- **Conversational Approval**: Two-step workflow designed for Claude Code
- **Version Tracking**: Maintains manifest with file hashes and version information
- **Automatic Backups**: Creates timestamped backups with retention management
- **Fail-Fast with Rollback**: Automatic rollback on failure, preserves diff files for debugging
- **Dry-Run Mode**: Check what would change before applying updates
- **Constitution Integration**: Seamless integration with `/speckit.constitution` command
- **Welcome Experience**: First-time installs show helpful next steps

## Prerequisites

**Supported Environment**:
- **OS**: Windows 11 (macOS/Linux support welcome - see [#15](https://github.com/NotMyself/claude-win11-speckit-update-skill/issues/15))
- **Shell**: PowerShell 7+
- **AI**: Claude Code (CLI or VSCode extension)
- **Git**: In PATH
- **Internet**: For GitHub API access

**Note**: This skill is designed specifically for Windows + PowerShell + Claude Code. Community contributions for other platforms/models are welcome but not maintained by the project owner.

## Configuration

**GitHub Token** (Optional):

The updater works without authentication (60 requests/hour). For higher rate limits (5,000 requests/hour), set the `GITHUB_PAT` environment variable:

```powershell
$env:GITHUB_PAT = "ghp_YOUR_TOKEN_HERE"
```

See [CLAUDE.md](CLAUDE.md#using-github-tokens) for complete token setup, team collaboration, CI/CD integration, and troubleshooting.

## Installation

### Plugin Installation (Recommended)

Install via the NotMyself plugin marketplace:

```bash
# Add the marketplace
/plugin marketplace add NotMyself/claude-plugins

# Install the skill
/plugin install speckit-updater
```

The skill will be automatically available - no restart required!

### Manual Installation (Alternative)

For advanced users or development:

```powershell
# Navigate to Claude Code skills directory
cd $env:USERPROFILE\.claude\skills

# Clone this repository
git clone https://github.com/NotMyself/claude-win11-speckit-update-skill speckit-updater

# Restart VSCode to load the skill
```

**Verify installation**: The `/speckit-update` command should be available in Claude Code.

**Migration**: Already using manual installation? See [Migration Guide](docs/migration-guide-plugin.md) for upgrading to plugin-based installation (optional).

## Usage

### First-Time Installation (New in v0.4.0!)

If you run `/speckit-updater` in a project **without SpecKit installed**, the updater will automatically offer to install it for you:

```
/speckit-updater
```

**Interactive Mode (Terminal):**
```
SpecKit is not installed in this project.

This skill can install the latest SpecKit templates and create a manifest to track future updates.

Would you like to install SpecKit now? (Y/n) Y
```

**Non-Interactive Mode (Claude Code):**
Claude will ask naturally: "SpecKit is not currently installed in this project. Would you like me to install it?"

Simply reply "yes" or "install it" and Claude will handle the rest automatically.

**What Gets Installed:**
- `.specify/` directory structure (`memory/`, `backups/`)
- Latest SpecKit templates from GitHub
- All official SpecKit slash commands in `.claude/commands/`
- Manifest file to track future updates
- Welcome message with next steps

**Graceful Decline:** If you decline installation, you'll see a helpful error message explaining what SpecKit is and how to install it manually.

### Check for Updates (Dry-Run)

```
/speckit-updater --check-only
```

Shows what would change without applying any updates.

### Update to Latest Version

```
/speckit-updater
```

Two-step conversational workflow:
1. Shows summary with `[PROMPT_FOR_APPROVAL]` marker
2. You approve via chat â†’ Claude re-invokes with `-Proceed`

### Update to Specific Version

```
/speckit-updater --version v0.0.72
```

Update to a specific SpecKit release tag.

### Rollback to Previous Version

```
/speckit-updater --rollback
```

Restore from a previous backup.

### Force Update

```
/speckit-updater --force
```

Overwrite SpecKit files even if customized (preserves custom commands).

### Skip Backup (Not Recommended)

```
/speckit-updater --no-backup
```

Skip backup creation. Use only if you're absolutely sure.

## How It Works

### Customization Detection

The updater automatically detects which files you've customized by comparing file hashes:

- **Customized files** are preserved and never overwritten
- **Unchanged files** are safely updated to the latest version
- **Your custom commands** are always protected, even with `--force`

### Smart Update Process

When you run `/speckit-updater`:

1. **Safety First**: Creates a timestamped backup before making any changes
2. **Intelligent Analysis**: Compares your files with the latest SpecKit templates
3. **Conflict Detection**: Identifies files that need your attention
4. **Conversational Approval**: Shows you exactly what will change and waits for your approval
5. **Safe Application**: Updates only what's safe, preserving your customizations
6. **Automatic Rollback**: If anything goes wrong, automatically restores from backup

### Backup & Recovery

- **Automatic backups** created before every update in `.specify/backups/`
- **Timestamped folders** make it easy to find the right backup
- **Quick rollback** with `/speckit-updater --rollback`
- **Automatic cleanup** keeps your 5 most recent backups

## Error Handling

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Prerequisites not met |
| 3 | Network/API error |
| 4 | Git error |
| 5 | User cancelled |
| 6 | Rollback required (automatic) |

### Automatic Rollback

If an error occurs during update:
1. Error message is displayed
2. Automatic rollback is attempted (if backup exists)
3. Files are restored to pre-update state
4. Exit code 6 is returned

## License

MIT License - see [LICENSE](./LICENSE)
