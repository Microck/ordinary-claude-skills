# Ordinary Claude Skills

A comprehensive local repository of Claude Skills—reusable modules that extend Claude's capabilities for specialized tasks.

## Overview

This repository contains 40+ official and community-built Claude Skills organized by category. Skills are self-contained folders with instructions, scripts, and resources for specific tasks.

## What Are Skills?

Skills teach Claude to perform specialized tasks. They load only when needed and can work together for complex workflows like document creation, code testing, and data analysis.

[Learn more about Claude Skills](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/quickstart)

## Quick Start

1. Load a skill into Claude:
   - Go to claude.ai
   - Add custom skills in your profile
   - Upload the skill folder

2. Use it in conversation:
   - Claude will load skills as needed
   - Reference specific tasks covered by each skill

## Skills by Category

### Document Creation

| Skill | Purpose | Source |
|-------|---------|--------|
| **docx** | Create, edit, and analyze Word documents | [anthropics/skills](https://github.com/anthropics/skills/tree/main/document-skills/docx) |
| **pptx** | Create, edit, and analyze PowerPoint presentations | [anthropics/skills](https://github.com/anthropics/skills/tree/main/document-skills/pptx) |
| **xlsx** | Create, edit, and analyze Excel spreadsheets | [anthropics/skills](https://github.com/anthropics/skills/tree/main/document-skills/xlsx) |
| **pdf** | Extract text, create PDFs, and handle forms | [anthropics/skills](https://github.com/anthropics/skills/tree/main/document-skills/pdf) |

### Creative & Design

| Skill | Purpose | Source |
|-------|---------|--------|
| **algorithmic-art** | Generate art using p5.js with seeded randomness | [anthropics/skills](https://github.com/anthropics/skills/tree/main/algorithmic-art) |
| **canvas-design** | Design visual art in PNG and PDF formats | [anthropics/skills](https://github.com/anthropics/skills/tree/main/canvas-design) |
| **slack-gif-creator** | Create animated GIFs optimized for Slack | [anthropics/skills](https://github.com/anthropics/skills/tree/main/slack-gif-creator) |
| **theme-factory** | Apply professional themes or generate custom ones | [anthropics/skills](https://github.com/anthropics/skills/tree/main/theme-factory) |

### Development & Testing

| Skill | Purpose | Source |
|-------|---------|--------|
| **artifacts-builder** | Build complex HTML artifacts with React and Tailwind | [anthropics/skills](https://github.com/anthropics/skills/tree/main/artifacts-builder) |
| **mcp-builder** | Create MCP servers to integrate external APIs | [anthropics/skills](https://github.com/anthropics/skills/tree/main/mcp-builder) |
| **webapp-testing** | Test local web applications using Playwright | [anthropics/skills](https://github.com/anthropics/skills/tree/main/webapp-testing) |
| **aws-skills** | AWS development with infrastructure automation | [zxkane/aws-skills](https://github.com/zxkane/aws-skills) |
| **ios-simulator-skill** | Control iOS Simulator | [conorluddy/ios-simulator-skill](https://github.com/conorluddy/ios-simulator-skill) |
| **ffuf-claude-skill** | Web fuzzing with ffuf | [jthack/ffuf_claude_skill](https://github.com/jthack/ffuf_claude_skill) |
| **playwright-skill** | Browser automation with Playwright | [lackeyjb/playwright-skill](https://github.com/lackeyjb/playwright-skill) |
| **changelog-generator** | Transform git commits into release notes | [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills/tree/master/changelog-generator) |
| **systematic-debugging** | Methodical problem-solving in code | [obra/superpowers](https://github.com/obra/superpowers/blob/main/skills/systematic-debugging/SKILL.md) |
| **root-cause-tracing** | Investigate and identify fundamental problems | [obra/superpowers](https://github.com/obra/superpowers/blob/main/skills/root-cause-tracing/SKILL.md) |
| **test-driven-development** | Write tests before implementing code | [obra/superpowers](https://github.com/obra/superpowers/blob/main/skills/test-driven-development/SKILL.md) |

### Productivity & Collaboration

| Skill | Purpose | Source |
|-------|---------|--------|
| **notebooklm-skill** | Interact with NotebookLM for document conversations | [PleasePrompto/notebooklm-skill](https://github.com/PleasePrompto/notebooklm-skill) |
| **superpowers-lab** | Lab environment for Claude superpowers | [obra/superpowers-lab](https://github.com/obra/superpowers-lab) |
| **content-research-writer** | Enhance writing with research | [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills/tree/master/content-research-writer) |
| **meeting-insights-analyzer** | Analyze meeting communication patterns | [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills/tree/master/meeting-insights-analyzer) |
| **competitive-ads-extractor** | Analyze competitor advertising | [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills/tree/master/competitive-ads-extractor) |
| **image-enhancer** | Improve image quality | [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills/tree/master/image-enhancer) |
| **brainstorming** | Generate and explore ideas | [obra/superpowers](https://github.com/obra/superpowers/blob/main/skills/brainstorming/SKILL.md) |
| **writing-plans** | Create strategic documentation | [obra/superpowers](https://github.com/obra/superpowers/blob/main/skills/writing-plans/SKILL.md) |
| **executing-plans** | Implement and run strategic plans | [obra/superpowers](https://github.com/obra/superpowers/blob/main/skills/executing-plans/SKILL.md) |
| **dispatching-parallel-agents** | Coordinate multiple simultaneous agents | [obra/superpowers](https://github.com/obra/superpowers/blob/main/skills/dispatching-parallel-agents/SKILL.md) |

### Specialized Domains

| Skill | Purpose | Source |
|-------|---------|--------|
| **claude-scientific-skills** | Scientific research and analysis | [K-Dense-AI/claude-scientific-skills](https://github.com/K-Dense-AI/claude-scientific-skills) |
| **claude-win11-speckit-update-skill** | Windows 11 system management | [NotMyself/claude-win11-speckit-update-skill](https://github.com/NotMyself/claude-win11-speckit-update-skill) |
| **claudisms** | SMS messaging integration | [jeffersonwarrior/claudisms](https://github.com/jeffersonwarrior/claudisms) |
| **defense-in-depth** | Multi-layered security approaches | [obra/superpowers](https://github.com/obra/superpowers/blob/main/skills/defense-in-depth/SKILL.md) |

## Using Skills with Claude

### In Claude.ai

1. Go to Settings → Skills (or Custom Skills)
2. Click "Add Skill"
3. Upload the skill folder
4. Describe when to use it

### With Claude API

Include skills in your system prompt or use Claude's [Agent Skills](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/quickstart) feature.


## Resources

- [Claude Skills Documentation](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/quickstart)
- [Skills Best Practices](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices)
- [Original Awesome List](https://github.com/VoltAgent/awesome-claude-skills)
- [Skills Cookbook](https://github.com/anthropics/claude-cookbooks/blob/main/skills/README.md)

## Credits

Skills sourced from:
- [Anthropic Official Skills](https://github.com/anthropics/skills)
- [Obra's Superpowers](https://github.com/obra/superpowers)
- [ComposioHQ](https://github.com/ComposioHQ/awesome-claude-skills)
- Community contributors

## License

Skills are maintained by their respective owners. See individual skill folders for license information.
