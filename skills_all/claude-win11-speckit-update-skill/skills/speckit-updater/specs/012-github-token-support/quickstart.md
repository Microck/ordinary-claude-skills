# Quickstart: GitHub Personal Access Token Setup

**Feature**: 012-github-token-support
**Phase**: 1 (Design Artifacts)
**Date**: 2025-10-23

## Overview

This guide shows you how to set up GitHub Personal Access Token authentication to increase your rate limit from **60 to 5,000 requests per hour**. This is especially useful if you:

- Develop or test the SpecKit updater frequently
- Work on a team sharing the same office network
- Run updates in CI/CD pipelines
- Hit rate limit errors during normal usage

**Time Required**: 5 minutes
**Difficulty**: Beginner

---

## Quick Start (TL;DR)

```powershell
# 1. Create token at https://github.com/settings/tokens (no scopes needed)
# 2. Set environment variable (copy your token from GitHub)
$env:GITHUB_PAT = "ghp_YOUR_TOKEN_HERE"

# 3. Verify it works
/speckit-update -CheckOnly -Verbose
# Should show: "Using authenticated request (rate limit: 5,000 req/hour)"
```

---

## Step 1: Create GitHub Personal Access Token

### 1.1 Navigate to Token Settings

1. Go to [github.com/settings/tokens](https://github.com/settings/tokens)
2. Click **"Generate new token"** dropdown
3. Select **"Generate new token (classic)"**

### 1.2 Configure Token

**Note** (token description):
```
SpecKit Updater
```
*This helps you remember what the token is for*

**Expiration**:
- **Recommended**: 90 days (good security practice)
- **Alternative**: No expiration (convenient but less secure)

**Scopes** (permissions):
- **Leave all unchecked** ✅
- No scopes are required for reading public repository releases
- This follows the principle of least privilege

### 1.3 Generate and Copy Token

1. Scroll to bottom and click **"Generate token"**
2. **⚠️ IMPORTANT**: Copy the token immediately (shown only once)
3. Token format: `ghp_` followed by 36 characters
4. Example: `ghp_1A2b3C4d5E6f7G8h9I0jK1lM2nO3pQ4rS5t`

**Security Tip**: Store the token in a password manager for future reference. GitHub won't show it again after you leave the page.

---

## Step 2: Set Environment Variable

Choose one method based on your needs:

### Method A: PowerShell Session (Temporary)

**Use case**: Testing or single session

```powershell
# Set token for current PowerShell window only
$env:GITHUB_PAT = "ghp_YOUR_TOKEN_HERE"

# Verify it's set
$env:GITHUB_PAT
# Should output: ghp_YOUR_TOKEN_HERE
```

**Lifetime**: Until you close the PowerShell window

**Pros**: Quick, no permanent changes
**Cons**: Must set again each time you open PowerShell

---

### Method B: PowerShell Profile (Persistent)

**Use case**: Daily development work

```powershell
# Open your PowerShell profile in editor
notepad $PROFILE

# If file doesn't exist, create it first:
New-Item -Path $PROFILE -ItemType File -Force
notepad $PROFILE
```

**Add this line** to your profile:
```powershell
$env:GITHUB_PAT = "ghp_YOUR_TOKEN_HERE"
```

**Save and reload** profile:
```powershell
# Save file in notepad (Ctrl+S), then reload profile
. $PROFILE

# Verify it's set
$env:GITHUB_PAT
```

**Lifetime**: Persists across all future PowerShell sessions

**Pros**: Set once, works forever
**Cons**: Token stored in plain text profile file (keep profile file secure)

**Profile Location**:
- Windows PowerShell: `$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`
- PowerShell 7+: `$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`

---

### Method C: Windows System Environment Variable (Global)

**Use case**: Organization-wide setup or multiple users

#### Option 1: GUI Method (Easiest)

1. Press **Win + R**, type `sysdm.cpl`, press Enter
2. Click **"Environment Variables"** button (bottom right)
3. Under **"User variables"**, click **"New"**
4. **Variable name**: `GITHUB_PAT`
5. **Variable value**: `ghp_YOUR_TOKEN_HERE` (paste your token)
6. Click **OK** on all dialogs
7. **Restart PowerShell** (required for variable to load)

#### Option 2: PowerShell Method

```powershell
# Set user environment variable (persists system-wide)
[System.Environment]::SetEnvironmentVariable(
    "GITHUB_PAT",
    "ghp_YOUR_TOKEN_HERE",
    [System.EnvironmentVariableTarget]::User
)

# Restart PowerShell for change to take effect
exit

# In new PowerShell window, verify:
$env:GITHUB_PAT
```

**Lifetime**: Persists across all applications and sessions

**Pros**: Works in PowerShell, VSCode, terminal, CI/CD
**Cons**: Affects all processes, harder to change temporarily

---

## Step 3: Verify Authentication

### 3.1 Check Verbose Output

```powershell
/speckit-update -CheckOnly -Verbose
```

**Expected output**:
```
VERBOSE: Using authenticated request (rate limit: 5,000 req/hour)
Checking for updates...
✓ No updates available. Current version: v0.0.72
```

**If you see**:
```
VERBOSE: Using unauthenticated request (rate limit: 60 req/hour)
```
→ Token is not set correctly. Double-check variable name and spelling.

### 3.2 Verify Token Not Exposed

**Security check**: Ensure token value never appears in output

```powershell
# Capture all output streams
$output = /speckit-update -CheckOnly -Verbose 4>&1 | Out-String

# Verify token not present (should be $false)
$output -match "ghp_"
```

**Expected result**: `False` (token should never appear in output)

---

## Step 4: Test Rate Limit Increase

### Before (Without Token)

```powershell
# Remove token temporarily
$env:GITHUB_PAT = $null

# Make multiple requests (will hit rate limit after ~60)
1..65 | ForEach-Object {
    Write-Host "Request $_"
    /speckit-update -CheckOnly
}

# After ~60 requests, you'll see:
# ERROR: GitHub API rate limit exceeded. Resets at: 3:00 PM
#
# Tip: Set GITHUB_PAT environment variable to increase rate limit...
```

### After (With Token)

```powershell
# Set token
$env:GITHUB_PAT = "ghp_YOUR_TOKEN_HERE"

# Make 100 requests (all succeed with token)
1..100 | ForEach-Object {
    Write-Host "Request $_"
    /speckit-update -CheckOnly
}

# All 100 requests complete successfully!
```

---

## CI/CD Integration

### GitHub Actions

**Zero configuration required** - GitHub automatically provides `GITHUB_PAT`

```yaml
name: Check SpecKit Updates

on: [push, pull_request]

jobs:
  check-updates:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3

      - name: Check SpecKit Updates
        env:
          GITHUB_PAT: ${{ secrets.GITHUB_PAT }}  # Automatic
        run: |
          pwsh -Command "& '.\.claude\skills\speckit-updater\scripts\update-orchestrator.ps1' -CheckOnly"
```

**Token is automatically**:
- Provided by GitHub (no manual creation)
- Scoped to your repository
- Valid for the duration of the job
- Revoked after job completes

---

### Azure Pipelines

**Manual setup required** - add token as secret variable

#### Step 1: Add Secret Variable

1. Go to your pipeline in Azure DevOps
2. Click **"Edit"** → **"Variables"**
3. Click **"New variable"**
4. **Name**: `GITHUB_PAT`
5. **Value**: Your personal access token
6. **Check**: "Keep this value secret" ✅
7. Click **"OK"** and save pipeline

#### Step 2: Use in Pipeline

```yaml
trigger:
  - main

pool:
  vmImage: 'windows-latest'

steps:
- task: PowerShell@2
  displayName: 'Check SpecKit Updates'
  env:
    GITHUB_PAT: $(GITHUB_PAT)  # From pipeline variables
  inputs:
    targetType: 'inline'
    script: |
      & '.\.claude\skills\speckit-updater\scripts\update-orchestrator.ps1' -CheckOnly
```

---

### Jenkins

**Manual setup required** - add token via Credentials Plugin

#### Step 1: Add Credential

1. Go to Jenkins → **"Credentials"** → **"System"**
2. Click **"Global credentials"** → **"Add Credentials"**
3. **Kind**: Secret text
4. **Scope**: Global
5. **Secret**: Your personal access token
6. **ID**: `github-token` (you'll reference this)
7. Click **"OK"**

#### Step 2: Use in Jenkinsfile

```groovy
pipeline {
    agent any

    environment {
        GITHUB_PAT = credentials('github-token')  // From credentials store
    }

    stages {
        stage('Check Updates') {
            steps {
                pwsh '''
                    & '.\.claude\skills\speckit-updater\scripts\update-orchestrator.ps1' -CheckOnly
                '''
            }
        }
    }
}
```

---

### CircleCI

**Manual setup required** - add token as environment variable

#### Step 1: Add Environment Variable

1. Go to your project in CircleCI
2. Click **"Project Settings"** → **"Environment Variables"**
3. Click **"Add Environment Variable"**
4. **Name**: `GITHUB_PAT`
5. **Value**: Your personal access token
6. Click **"Add Variable"**

#### Step 2: Use in Config

```yaml
version: 2.1

jobs:
  check-updates:
    docker:
      - image: mcr.microsoft.com/powershell:latest
    steps:
      - checkout
      - run:
          name: Check SpecKit Updates
          command: |
            pwsh -Command "& '.\.claude\skills\speckit-updater\scripts\update-orchestrator.ps1' -CheckOnly"
          # GITHUB_PAT automatically available from environment

workflows:
  version: 2
  check:
    jobs:
      - check-updates
```

---

## Troubleshooting

### Problem: "401 Unauthorized" Error

**Cause**: Token is invalid, expired, or revoked

**Solution**:
```powershell
# 1. Check if token is set
$env:GITHUB_PAT
# Should output your token

# 2. Verify token format (should start with ghp_)
$env:GITHUB_PAT -match "^ghp_"
# Should return True

# 3. Test token manually
$headers = @{
    "Authorization" = "Bearer $env:GITHUB_PAT"
    "User-Agent"    = "Test"
}
Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers
# Should return your GitHub user info (if token valid)

# 4. If still failing, create new token
# Go to https://github.com/settings/tokens and generate new token
```

---

### Problem: Still Getting Rate Limited

**Cause**: Token not picked up by script

**Solution**:
```powershell
# 1. Verify GITHUB_PAT is set (exact spelling)
Get-ChildItem env: | Where-Object Name -eq "GITHUB_PAT"
# Should show: Name=GITHUB_PAT, Value=ghp_...

# 2. Check for typos (case-sensitive on some platforms)
$env:GITHUB_PAT.Length
# Should be 40 characters (ghp_ + 36 chars)

# 3. Try setting in current session explicitly
$env:GITHUB_PAT = "ghp_YOUR_TOKEN_HERE"

# 4. Restart PowerShell after setting system env var
exit
# Open new PowerShell window and try again
```

---

### Problem: Token Visible in Logs

**Cause**: Bug in script (should never happen)

**Solution**:
```powershell
# 1. Report immediately as security issue
# https://github.com/NotMyself/claude-win11-speckit-update-skill/issues

# 2. Revoke compromised token
# Go to https://github.com/settings/tokens
# Find "SpecKit Updater" token
# Click "Delete" to revoke

# 3. Create new token with different value

# 4. Update environment variable with new token
```

---

### Problem: Different Rate Limit Than Expected

**Cause**: GitHub API has different endpoints with different limits

**Solution**:
```powershell
# Check your current rate limit status
$headers = @{
    "Authorization" = "Bearer $env:GITHUB_PAT"
    "User-Agent"    = "Test"
}
$rateLimit = Invoke-RestMethod -Uri "https://api.github.com/rate_limit" -Headers $headers

$rateLimit.rate | Format-List
# limit:     5000
# remaining: 4850
# reset:     1704067200
# used:      150

# Convert reset time to readable format
[DateTimeOffset]::FromUnixTimeSeconds($rateLimit.rate.reset).LocalDateTime
# Example: 1/1/2024 3:00:00 PM
```

---

### Problem: Token Not Working in New PowerShell Session

**Cause**: Token set in session only (not profile or system)

**Solution**:
```powershell
# Add token to PowerShell profile (persistent)
Add-Content $PROFILE "`n`$env:GITHUB_PAT = 'ghp_YOUR_TOKEN_HERE'"

# Reload profile
. $PROFILE

# Verify
$env:GITHUB_PAT
```

---

## Security Best Practices

### ✅ DO:

- **Use tokens with minimal scopes** (no scopes needed for public repos)
- **Set expiration dates** (90 days recommended)
- **Store in password manager** (1Password, LastPass, etc.)
- **Use different tokens for different purposes** (dev vs CI/CD)
- **Revoke immediately if compromised**
- **Rotate tokens periodically** (every 3-6 months)

### ❌ DON'T:

- **Commit tokens to Git** (check .gitignore excludes $PROFILE)
- **Share tokens between team members** (each person should create their own)
- **Store in plain text files** (except PowerShell profile with proper permissions)
- **Use tokens with unnecessary scopes** (follow least privilege)
- **Keep tokens indefinitely** (set expiration dates)
- **Screenshot or demo with real tokens** (revoke after if you do)

---

## FAQ

**Q: Do I need to create a token?**
A: No, it's optional. The updater works without a token (60 requests/hour). Only needed if you hit rate limits frequently.

**Q: What scopes does the token need?**
A: None! Leave all scopes unchecked. Reading public repositories doesn't require any permissions.

**Q: Can I use the same token for multiple projects?**
A: Yes, but it's better to create separate tokens for different purposes (easier to revoke if needed).

**Q: How do I know if my token is working?**
A: Run `/speckit-update -CheckOnly -Verbose` and look for "Using authenticated request (rate limit: 5,000 req/hour)"

**Q: Will this work on macOS/Linux?**
A: Yes! PowerShell 7+ is cross-platform. Same `$env:GITHUB_PAT` variable works everywhere.

**Q: Can I use fine-grained tokens instead of classic tokens?**
A: Yes, fine-grained tokens (format: `github_pat_...`) work identically. Our code doesn't validate format.

**Q: What if I accidentally commit my token?**
A: 1) Revoke it immediately at github.com/settings/tokens, 2) Remove from Git history, 3) Create new token

**Q: How do I remove the token?**
A: `$env:GITHUB_PAT = $null` (session), or delete line from $PROFILE (persistent), or remove from system environment variables (global)

---

## Next Steps

✅ **Token Setup Complete!**

You can now:

- Run unlimited updates without rate limiting (5,000/hour)
- Test updater changes rapidly without wait times
- Work on teams without IP address conflicts
- Integrate updater into CI/CD pipelines

**Related Documentation**:
- [GitHub Token Documentation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
- [GitHub Rate Limit Documentation](https://docs.github.com/en/rest/overview/rate-limits-for-the-rest-api)
- [SpecKit Updater Troubleshooting](../../CLAUDE.md#troubleshooting)

---

**Need Help?** Open an issue at https://github.com/NotMyself/claude-win11-speckit-update-skill/issues
