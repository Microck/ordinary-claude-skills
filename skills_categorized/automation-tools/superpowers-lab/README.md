# Superpowers Lab

Experimental skills for [Claude Code Superpowers](https://github.com/obra/superpowers) - new techniques and tools under active development.

## What is this?

This plugin contains experimental skills that extend Claude Code's capabilities with new techniques that are still being refined and tested. These skills are functional but may evolve based on real-world usage and feedback.

## Current Skills

### using-tmux-for-interactive-commands

Enables Claude Code to control interactive CLI tools (vim, git rebase -i, menuconfig, REPLs, etc.) through tmux sessions.

**Use cases:**
- Interactive text editors (vim, nano)
- Terminal UI tools (menuconfig, htop)
- Interactive REPLs (Python, Node, etc.)
- Interactive git operations (rebase -i, add -p)
- Any tool requiring keyboard navigation and real-time interaction

**How it works:** Creates detached tmux sessions, sends keystrokes programmatically, and captures terminal output to enable automation of traditionally manual workflows.

See [skills/using-tmux-for-interactive-commands/SKILL.md](skills/using-tmux-for-interactive-commands/SKILL.md) for full documentation.

## Installation

```bash
# Install the plugin
claude-code plugin install https://github.com/obra/superpowers-lab

# Or add to your claude.json
{
  "plugins": [
    "https://github.com/obra/superpowers-lab"
  ]
}
```

## Requirements

- tmux must be installed on your system
- Skills are tested on Linux/macOS (tmux required)

## Experimental Status

Skills in this plugin are:
- ✅ Functional and tested
- 🧪 Under active refinement
- 📝 May evolve based on usage
- 🔬 Open to feedback and improvements

## Contributing

Found a bug or have an improvement? Please open an issue or PR!

## Related Projects

- [superpowers](https://github.com/obra/superpowers) - Core skills library for Claude Code
- [superpowers-chrome](https://github.com/obra/superpowers-chrome) - Browser automation skills

## License

MIT License - see [LICENSE](LICENSE) for details
