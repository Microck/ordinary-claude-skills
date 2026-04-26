# Quickstart: Plugin-Based Distribution

**Feature**: Plugin-Based Distribution | **Date**: 2025-10-25
**Status**: Complete | **Plan**: [plan.md](plan.md)

## Overview

This quickstart guide provides step-by-step installation instructions for the SpecKit Safe Update Skill using both plugin-based (recommended) and manual installation methods.

## Prerequisites

Before installing, ensure you have:

- **Claude Code** installed and configured
- **PowerShell 7.0+** installed ([download](https://github.com/PowerShell/PowerShell/releases))
- **Git 2.0+** installed ([download](https://git-scm.com/downloads))
- **Internet connection** (for downloading plugin from GitHub)

**Verify Prerequisites**:
```powershell
# Check PowerShell version
$PSVersionTable.PSVersion
# Should show: 7.x.x

# Check Git version
git --version
# Should show: git version 2.x.x or higher

# Check Claude Code availability
/help
# Should display Claude Code command list
```

---

## Installation Method 1: Plugin (Recommended)

**Why plugin installation?**
- ✅ Single command installation
- ✅ Version management through Claude Code
- ✅ Easy discovery and browsing
- ✅ Automatic updates available
- ✅ No manual file system operations

### Step 1: Add the Marketplace

Add the NotMyself plugins marketplace (one-time setup):

```powershell
/plugin marketplace add NotMyself/claude-plugins
```

**Expected Output**:
```
Marketplace 'notmyself-plugins' added successfully
```

### Step 2: Browse Available Plugins (Optional)

View plugins in the marketplace:

```powershell
/plugin
```

**Expected Output**:
```
Available plugins:

notmyself-plugins marketplace:
  - speckit-updater v0.8.0
    Safe updates for GitHub SpecKit installations, preserving your customizations
```

### Step 3: Install the Plugin

Install the SpecKit updater skill:

```powershell
/plugin install speckit-updater
```

**Expected Output**:
```
Installing speckit-updater v0.8.0...
✓ speckit-updater installed successfully
```

**Installation Time**: Typically 10-30 seconds (depends on network speed)

### Step 4: Verify Installation

Confirm the skill is available:

```powershell
/help
```

**Expected Output**: Should include `/speckit-update` in the commands list

**Test the skill**:
```powershell
# Navigate to a SpecKit project
cd path/to/your-speckit-project

# Run check-only mode
/speckit-update --check-only
```

**Success**: If you see update status or "No updates available", installation is complete!

---

## Installation Method 2: Manual (Alternative)

**Why manual installation?**
- ✅ Full control over installation location
- ✅ Works in offline/air-gapped environments (after initial clone)
- ✅ Easier to contribute to the project
- ✅ Direct access to source code for inspection

### Step 1: Navigate to Skills Directory

```powershell
cd $env:USERPROFILE\.claude\skills
```

**Note**: If the `skills` directory doesn't exist, create it:
```powershell
mkdir -Force $env:USERPROFILE\.claude\skills
cd $env:USERPROFILE\.claude\skills
```

### Step 2: Clone the Repository

```powershell
git clone https://github.com/NotMyself/claude-win11-speckit-safe-update-skill speckit-updater
```

**Expected Output**:
```
Cloning into 'speckit-updater'...
remote: Enumerating objects: ...
Resolving deltas: 100% (...), done.
```

**Clone Time**: Typically 5-15 seconds (depends on network speed)

### Step 3: Verify Installation

List installed skills:

```powershell
ls $env:USERPROFILE\.claude\skills
```

**Expected Output**: Should include `speckit-updater` directory

**Test the skill**:
```powershell
# Restart Claude Code or reload skills (if needed)

# Navigate to a SpecKit project
cd path/to/your-speckit-project

# Run check-only mode
/speckit-update --check-only
```

**Success**: If you see update status or "No updates available", installation is complete!

---

## Verify Installation (Both Methods)

Regardless of installation method, verify the skill works:

### 1. Check Command Availability

```powershell
/help
```

**Look for**: `/speckit-update` in the output

### 2. Test in a SpecKit Project

Navigate to any SpecKit project (with `.specify/` directory):

```powershell
cd path/to/speckit-project
/speckit-update --check-only
```

**Expected Behaviors**:

**If updates are available**:
```
SpecKit Safe Update Skill v0.8.0
Checking for updates from GitHub...

Current version: v0.0.79
Latest version: v0.0.80

Files to update:
  - .claude/commands/speckit.specify.md
  - .claude/commands/speckit.plan.md
  [...]

Run '/speckit-update -Proceed' to apply updates.
```

**If no updates available**:
```
SpecKit Safe Update Skill v0.8.0
Checking for updates from GitHub...

Current version: v0.0.80
Latest version: v0.0.80

No updates available. Your SpecKit installation is up to date.
```

**If not in a SpecKit project**:
```
Error: Not in a SpecKit project directory.
Please navigate to a directory containing a .specify/ folder.
```

### 3. Check Version

```powershell
/speckit-update --version
```

**Expected Output**: `v0.8.0` (or later)

---

## Updating the Skill

### Plugin Installation Updates

```powershell
# Check for plugin updates
/plugin

# Update to latest version
/plugin update speckit-updater
```

**Expected Output**:
```
Updating speckit-updater...
✓ speckit-updater updated to v0.8.1
```

### Manual Installation Updates

```powershell
cd $env:USERPROFILE\.claude\skills\speckit-updater
git pull origin main
```

**Expected Output**:
```
Already up to date.
```
or
```
Updating abc1234..def5678
Fast-forward
 CHANGELOG.md | 10 +++++++
 ...
```

---

## Uninstalling the Skill

### Plugin Installation Uninstall

```powershell
/plugin uninstall speckit-updater
```

**Expected Output**:
```
✓ speckit-updater uninstalled successfully
```

### Manual Installation Uninstall

```powershell
Remove-Item -Recurse -Force "$env:USERPROFILE\.claude\skills\speckit-updater"
```

**Warning**: This permanently deletes the skill. To reinstall, follow the installation steps again.

---

## Migrating from Manual to Plugin

If you have a manual installation and want to migrate to plugin installation:

### Step 1: Remove Manual Installation

```powershell
Remove-Item -Recurse -Force "$env:USERPROFILE\.claude\skills\speckit-updater"
```

### Step 2: Install via Plugin

```powershell
/plugin marketplace add NotMyself/claude-plugins
/plugin install speckit-updater
```

### Step 3: Verify Migration

```powershell
/speckit-update --version
```

**Expected Output**: `v0.8.0` (or later)

**Note**: Your SpecKit projects are unaffected by this migration. The skill operates identically regardless of installation method.

---

## Troubleshooting

### Issue: "Marketplace not found" Error

**Symptoms**:
```
Error: Marketplace 'NotMyself/claude-plugins' not found
```

**Solutions**:
1. Check internet connection
2. Verify GitHub is accessible: `Test-NetConnection github.com -Port 443`
3. Try adding marketplace with full URL:
   ```powershell
   /plugin marketplace add https://github.com/NotMyself/claude-plugins
   ```

---

### Issue: "Plugin installation failed" Error

**Symptoms**:
```
Error: Failed to install speckit-updater
```

**Solutions**:
1. Check Git is installed: `git --version`
2. Check PowerShell version: `$PSVersionTable.PSVersion` (must be 7.0+)
3. Verify GitHub repository is accessible: `git ls-remote https://github.com/NotMyself/claude-win11-speckit-safe-update-skill.git`
4. Try manual installation method as fallback

---

### Issue: "/speckit-update command not found"

**Symptoms**:
```
Error: Command '/speckit-update' not recognized
```

**Solutions**:
1. Verify installation completed successfully:
   ```powershell
   ls $env:USERPROFILE\.claude\skills
   # Should show 'speckit-updater' directory
   ```
2. Check SKILL.md exists:
   ```powershell
   Test-Path "$env:USERPROFILE\.claude\skills\speckit-updater\SKILL.md"
   # Should return True
   ```
3. Restart Claude Code
4. Check for plugin installation: `/plugin` (should list speckit-updater if installed via plugin)

---

### Issue: Permission Denied Errors

**Symptoms**:
```
Error: Permission denied creating directory
```

**Solutions**:
1. Ensure you have write permissions to `$env:USERPROFILE\.claude\skills`
2. Run PowerShell as Administrator (if necessary)
3. Check antivirus/security software isn't blocking file operations

---

### Issue: Slow Installation

**Symptoms**: Installation takes longer than 1 minute

**Causes**:
- Slow internet connection
- Large repository size
- GitHub rate limiting

**Solutions**:
1. Wait for installation to complete (can take up to 2-3 minutes on slow connections)
2. Check GitHub status: https://www.githubstatus.com/
3. Try again later if GitHub is experiencing issues

---

## Getting Help

If you encounter issues not covered here:

1. **Check GitHub Issues**: https://github.com/NotMyself/claude-win11-speckit-safe-update-skill/issues
2. **Review Documentation**: See [README.md](../../README.md) and [CLAUDE.md](../../CLAUDE.md)
3. **Report a Bug**: Create a new issue on GitHub with:
   - Installation method used (plugin vs manual)
   - Error messages (full text)
   - PowerShell version (`$PSVersionTable.PSVersion`)
   - Git version (`git --version`)
   - Operating system

---

## Next Steps

After successful installation:

1. **Navigate to a SpecKit project** with a `.specify/` directory
2. **Check for updates**: `/speckit-update --check-only`
3. **Review available options**: Run `/speckit-update` for help
4. **Read the full documentation**: See [README.md](../../README.md) for detailed usage

---

## Additional Resources

- **Plugin Marketplace Repository**: https://github.com/NotMyself/claude-plugins
- **Skill Repository**: https://github.com/NotMyself/claude-win11-speckit-safe-update-skill
- **SpecKit Documentation**: https://github.com/github/spec-kit
- **Claude Code Documentation**: https://docs.claude.com/en/docs/claude-code/

---

**Last Updated**: 2025-10-25
**Applies to Version**: v0.8.0+
