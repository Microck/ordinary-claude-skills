# Security Policy

## Supported Versions

We release security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 0.2.x   | :white_check_mark: |
| < 0.2.0 | :x:                |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability in the SpecKit Safe Update Skill, please report it responsibly.

### How to Report

**Do NOT create a public GitHub issue for security vulnerabilities.**

Instead, please report security issues via one of these methods:

1. **GitHub Security Advisories** (Preferred):
   - Go to https://github.com/NotMyself/claude-win11-speckit-update-skill/security/advisories
   - Click "Report a vulnerability"
   - Fill out the form with details

2. **Email**:
   - Send details to: bobby@notmyself.io
   - Subject: "[SECURITY] SpecKit Updater Vulnerability"
   - Include detailed description and reproduction steps

### What to Include

A good security report includes:

- **Description** of the vulnerability
- **Impact** - what can an attacker do?
- **Steps to reproduce** - how to trigger the issue
- **Affected versions** - which versions are vulnerable
- **Suggested fix** (if you have one)
- **Your contact info** - for follow-up questions

### What to Expect

- **Acknowledgment**: Within 48 hours
- **Assessment**: Within 7 days (whether it's a valid vulnerability)
- **Fix timeline**: Depends on severity
  - Critical: 1-7 days
  - High: 7-30 days
  - Medium/Low: 30-90 days
- **Credit**: You'll be credited in the security advisory (unless you prefer to remain anonymous)

## Security Considerations

### This Skill Handles

- **Local files** in `.specify/` and `.claude/commands/` directories
- **GitHub API requests** (unauthenticated, read-only)
- **Git repository state** (for prerequisite checks)
- **PowerShell execution** (running update scripts)

### Security Best Practices We Follow

✅ **No credentials stored** - GitHub API is unauthenticated
✅ **Backup before changes** - Automatic backup with rollback
✅ **Git state validation** - Checks for uncommitted changes
✅ **Write permission checks** - Validates access before writing
✅ **Fail-fast principle** - Automatic rollback on errors
✅ **Input validation** - Validates version tags, file paths
✅ **Normalized hashing** - Prevents hash collision attacks

### Known Limitations

⚠️ **This skill requires PowerShell execution** - Only run in trusted environments
⚠️ **No code signing** - Scripts are not digitally signed (PowerShell execution policy may require bypass)
⚠️ **Local file access** - Skill reads/writes files in current project
⚠️ **GitHub API rate limits** - 60 requests/hour for unauthenticated calls

### Attack Vectors to Consider

If you're reviewing the code for security issues, consider:

1. **Path Traversal**: Can an attacker use `..` in paths to write outside `.specify/`?
2. **Command Injection**: Can user input be injected into Git or PowerShell commands?
3. **Supply Chain**: Could a malicious GitHub release contain harmful templates?
4. **Manifest Tampering**: Can an attacker modify manifest to force unwanted updates?
5. **Backup Manipulation**: Can an attacker corrupt backups to prevent rollback?

## Disclosure Policy

- **Private disclosure first**: We'll work with you privately to fix the issue
- **Coordinated release**: We'll agree on a disclosure timeline
- **Public disclosure**: After fix is released, we'll publish a security advisory
- **CVE assignment**: For critical vulnerabilities, we'll request a CVE

## Security Updates

Security updates are released as:
- **Patch versions** (e.g., 0.2.1) for minor security fixes
- **Minor versions** (e.g., 0.3.0) for security fixes with breaking changes
- **GitHub Security Advisories** for all security-related releases

Subscribe to releases and security advisories:
- Watch this repository on GitHub
- Subscribe to security advisories at https://github.com/NotMyself/claude-win11-speckit-update-skill/security/advisories

## Thank You

We appreciate the security research community's efforts to keep this project safe. Responsible disclosure helps protect all users.
