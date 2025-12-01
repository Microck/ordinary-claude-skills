# Migration Guide: Manual to Plugin Installation

This guide helps users with existing manual Git clone installations migrate to the plugin-based distribution system.

## Why Migrate?

**Benefits of Plugin Installation:**
- **Easier Updates**: Automatic update notifications via Claude Code's plugin system
- **Version Management**: Built-in version tracking and rollback capabilities
- **Simplified Installation**: No manual Git operations or path configuration
- **Consistent Location**: Standardized installation directory managed by Claude Code

**No Forced Migration**: Manual installations continue to work perfectly. This migration is **completely optional** - choose what works best for your workflow.

## Before You Begin

**Prerequisites:**
- Existing manual installation at `$env:USERPROFILE\.claude\skills\speckit-updater`
- The skill is currently working (verify with `/speckit-update --check-only` in a SpecKit project)
- No uncommitted changes in your local skill directory (if you've customized the skill)

**What to Expect:**
- **Zero Downtime**: The skill will be unavailable only during the brief migration process
- **Identical Behavior**: The skill functions exactly the same way after migration
- **No Configuration Changes**: Your SpecKit projects are unaffected

## Migration Steps

### Step 1: Verify Current Installation

Check your current installation location:

```powershell
# Verify manual installation exists
Test-Path "$env:USERPROFILE\.claude\skills\speckit-updater"

# Check if you have local changes
cd "$env:USERPROFILE\.claude\skills\speckit-updater"
git status
```

**If you have uncommitted changes:** Commit them or back them up before proceeding.

### Step 2: Remove Manual Installation

```powershell
# Navigate to skills directory
cd "$env:USERPROFILE\.claude\skills"

# Remove the manually cloned directory
Remove-Item -Path "speckit-updater" -Recurse -Force
```

**Note**: This only removes the skill directory, not any of your SpecKit projects or their `.specify/` directories.

### Step 3: Add Plugin Marketplace

In Claude Code, run:

```bash
/plugin marketplace add NotMyself/claude-plugins
```

**What this does:**
- Adds the NotMyself plugin marketplace to your Claude Code configuration
- Fetches the marketplace manifest from GitHub
- Makes all NotMyself plugins discoverable

### Step 4: Install via Plugin

In Claude Code, run:

```bash
/plugin install speckit-updater
```

**What this does:**
- Downloads the skill from GitHub
- Installs it to the standardized plugin location
- Makes `/speckit-update` command available automatically

**No restart required!** The skill is immediately available.

### Step 5: Verify Migration

Test that the skill works identically:

```bash
# Navigate to a SpecKit project
cd path\to\your\speckit-project

# Run a dry-run check
/speckit-update --check-only
```

**Expected output:**
- Same version detection as before
- Same file analysis
- Same update recommendations

The behavior should be **identical** to the manual installation.

## Troubleshooting

### Skill Not Found After Installation

**Symptom**: `/speckit-update` command not recognized

**Solution**:
```bash
# List installed plugins
/plugin list

# Verify speckit-updater is listed
# If not, reinstall:
/plugin install speckit-updater
```

### Different Installation Path

**Symptom**: Concerned about where the plugin is installed

**Answer**: Plugin installations go to Claude Code's managed plugin directory (varies by system). This is normal and managed automatically by Claude Code.

### Want to Revert to Manual Installation

**Solution**:
```bash
# Uninstall plugin
/plugin uninstall speckit-updater

# Reinstall manually
cd $env:USERPROFILE\.claude\skills
git clone https://github.com/NotMyself/claude-win11-speckit-update-skill speckit-updater
```

Both methods work identically - choose what you prefer!

## Frequently Asked Questions

### Will my SpecKit projects be affected?

**No.** The migration only changes where the skill is installed, not how it operates. Your `.specify/` directories, manifests, and backups remain untouched.

### Can I use both manual and plugin installations?

**Not recommended.** Claude Code may load one or the other unpredictably. Choose one installation method.

### Do I need to reconfigure GitHub tokens?

**No.** Environment variables like `$env:GITHUB_PAT` work the same way regardless of installation method.

### Will my backup history be preserved?

**Yes.** Backup history is stored in your SpecKit projects' `.specify/backups/` directories, not in the skill installation directory.

### How do I update after migrating to plugin?

Claude Code's plugin system will notify you of updates automatically. You can update via:

```bash
/plugin update speckit-updater
```

### Can I go back to manual installation later?

**Absolutely!** See "Want to Revert to Manual Installation" in the Troubleshooting section above. You can switch between installation methods anytime.

## Need Help?

- **Issues**: https://github.com/NotMyself/claude-win11-speckit-safe-update-skill/issues
- **Discussions**: https://github.com/NotMyself/claude-win11-speckit-safe-update-skill/discussions
- **Email**: bobby@notmyself.io

## Summary

**Migration is optional and reversible.** Both installation methods work identically. Choose based on your preferences:

- **Plugin Installation**: Best for most users, easier updates, managed by Claude Code
- **Manual Installation**: Best for developers, direct Git access, full control

The skill's functionality is **100% identical** regardless of installation method.
