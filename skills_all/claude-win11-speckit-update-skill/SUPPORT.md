# Getting Help

Need help with the SpecKit Safe Update Skill? Here's how to get support.

## Documentation

Before asking for help, check if the documentation already answers your question:

- **[README.md](README.md)** - Usage, installation, features
- **[SKILL.md](SKILL.md)** - Claude Code skill definition and workflow
- **[CLAUDE.md](CLAUDE.md)** - Development guidelines and architecture
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - How to contribute
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and breaking changes
- **[specs/001-safe-update/](specs/001-safe-update/)** - Complete specification

## Quick Links

- **Installation Issues**: See [README.md - Installation](README.md#installation)
- **Usage Questions**: See [README.md - Usage](README.md#usage)
- **Error Messages**: See [CLAUDE.md - Troubleshooting](CLAUDE.md#troubleshooting)
- **Contributing**: See [CONTRIBUTING.md](CONTRIBUTING.md)
- **Security Issues**: See [SECURITY.md](SECURITY.md)

## Common Issues

### "Prerequisites not met: Not a SpecKit project"

**Cause**: Running in a directory without `.specify/` folder.

**Solution**:
- Make sure you're in a SpecKit project
- Or install SpecKit first (see [Issue #13](https://github.com/NotMyself/claude-win11-speckit-update-skill/issues/13) for future auto-install feature)

### "GitHub API rate limit exceeded"

**Cause**: Exceeded 60 requests/hour limit for unauthenticated API calls.

**Solution**: Wait until rate limit resets (time shown in error message).

### "Git working directory has unstaged changes"

**Cause**: You have uncommitted changes in `.specify/` or `.claude/` directories.

**Solution**: Commit or stash your changes before running the update.

### Conflict markers not showing in VSCode

**Cause**: VSCode CodeLens may be disabled.

**Solution**: Check VSCode settings for CodeLens (`editor.codeLens: true`).

## Getting Help

### 1. Search Existing Issues

Check if someone else has already reported your issue:

https://github.com/NotMyself/claude-win11-speckit-update-skill/issues

Use the search box to look for keywords related to your problem.

### 2. Ask a Question (GitHub Discussions)

For general questions, use GitHub Discussions:

https://github.com/NotMyself/claude-win11-speckit-update-skill/discussions

**Good for**:
- How do I...?
- Why does...?
- What's the best way to...?
- Feature ideas (discuss before creating issue)

### 3. Report a Bug (GitHub Issues)

If you've found a bug, create an issue:

https://github.com/NotMyself/claude-win11-speckit-update-skill/issues/new

**Include**:
- What you expected to happen
- What actually happened
- Steps to reproduce
- Your environment (Windows version, PowerShell version, Claude Code version)
- Error messages (if any)
- Output with `-Verbose` flag

**Example**:
```
**Expected**: Update should preserve my customized files
**Actual**: Customized files were overwritten
**Steps**:
1. Run `/speckit-updater` in project with customized .claude/commands/speckit.plan.md
2. Approve update
3. File was overwritten
**Environment**: Windows 11, PowerShell 7.4, Claude Code 0.2.0
**Error**: None, but file content changed
**Verbose output**: [attach output]
```

### 4. Request a Feature (GitHub Issues)

For feature requests, create an issue with the `enhancement` label:

https://github.com/NotMyself/claude-win11-speckit-update-skill/issues/new

**Include**:
- What problem does this solve?
- What would the feature look like?
- How would it work?
- Why is this important?

### 5. Community Support

**This is a solo-maintained project**, so response times may vary:

- **Bug reports**: Typically 1-7 days
- **Feature requests**: Depends on priority and complexity
- **Questions**: Usually within a few days

**Want faster help?**
- Check documentation first (saves everyone time)
- Provide detailed information (easier to help)
- Search existing issues (may already be answered)

## Platform Support

**Officially Supported**:
- ✅ Windows 11
- ✅ PowerShell 7+
- ✅ Claude Code (CLI or VSCode extension)

**Community Contributions Welcome**:
- ⭕ macOS/Linux (see [Issue #15](https://github.com/NotMyself/claude-win11-speckit-update-skill/issues/15))
- ⭕ Other AI models
- ⭕ Other shells

**Note**: The maintainer only has Windows + PowerShell + Claude Code for testing. Community contributors must test on other platforms.

## Version Support

We support the latest released version and the previous minor version:

- **Current**: v0.2.x (fully supported)
- **Previous**: v0.1.x (security fixes only)
- **Older**: Not supported (please upgrade)

## Response Time

This is a **solo-maintained open-source project**. Response times vary based on:

- **Complexity** - Simple questions answered quickly
- **Impact** - Security issues prioritized
- **Documentation** - Already documented questions may be closed with link
- **Maintainer availability** - May take days to weeks

**Please be patient!** This is maintained in spare time.

## Contributing

The best way to get help is to help yourself (and others):

1. **Fix bugs** - Submit a PR with the fix
2. **Improve docs** - Submit a PR with clarifications
3. **Answer questions** - Help others in Discussions
4. **Write tests** - Increase confidence in changes

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Code of Conduct

Be respectful, constructive, and patient:

- ✅ Ask clear questions with details
- ✅ Share what you've tried
- ✅ Be patient waiting for responses
- ✅ Thank people for their help
- ❌ Don't demand immediate responses
- ❌ Don't be rude or dismissive
- ❌ Don't hijack other issues with unrelated questions

This project follows the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).

## Contact

- **Bugs/Features**: [GitHub Issues](https://github.com/NotMyself/claude-win11-speckit-update-skill/issues)
- **Questions**: [GitHub Discussions](https://github.com/NotMyself/claude-win11-speckit-update-skill/discussions)
- **Security**: See [SECURITY.md](SECURITY.md)
- **Maintainer**: Bobby Johnson ([@NotMyself](https://github.com/NotMyself))

## Thank You!

Thank you for using the SpecKit Safe Update Skill! Your feedback and contributions help make this tool better for everyone.
