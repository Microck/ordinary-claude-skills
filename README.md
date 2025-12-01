# ordinary claude skills

![banner that took a lot of effort to make](https://i.imgur.com/7RECQZj.jpeg)

> **note**
> this is a collection of reusable modules to make claude less hallucinate-y and more useful. use at your own risk.

a massive local repository of official and community-built claude skills organized by category. i put this together mostly for my own sanity so i could use the repository url through cc switch without hunting down forty different github tabs.

## badges

![license](https://img.shields.io/badge/license-MIT-green)
![maintenance](https://img.shields.io/badge/maintenance-passive-yellow)
![claude](https://img.shields.io/badge/AI-claude-purple)

## quickstart

1.  **clone the repo**
    ```bash
    git clone https://github.com/Microck/ordinary-claude-skills.git
    cd ordinary-claude-skills
    ```

2.  **choose your weapon**
    *   **for claude.ai:** go to your profile, hit `custom skills`, and upload the specific folder for the skill you want.
    *   **for api/devs:** point your mcp client or system prompt config to the relevant skill directory.

3.  **verify**
    ask claude `can you use the [skill name] skill now?` if it says yes, you are gucci.

## table of contents

*   [overview](#overview)
*   [features](#features)
*   [skill catalog](#skill-catalog)
    *   [document creation](#document-creation)
    *   [creative & design](#creative--design)
    *   [development & testing](#development--testing)
    *   [productivity & collaboration](#productivity--collaboration)
    *   [specialized domains](#specialized-domains)
*   [configuration](#configuration)
*   [how-to examples](#how-to-examples)
*   [troubleshooting](#troubleshooting)
*   [dependencies](#dependencies)
*   [license & credits](#license--credits)

## overview

skills are basically fancy prompt packages and scripts that teach claude how to do specific things without you having to explain the context every single time. they load lazily (only when needed), which saves context window space and keeps claude from getting confused by instructions it doesn't need yet.

this repo aggregates about 40+ skills from anthropic, obra, composiohq, and some random smart people on the internet.

## features

*   **non-curated selection:** if it doesnt work i probably havent noticed, just let me know and i may or may not fix it.
*   **categorized:** everything is sorted so you don't have to doomscroll to find the python tools.
*   **standardized:** i tried to keep the folder structures somewhat consistent.
*   **local first:** designed to be cloned locally so you aren't dependent on a third party url staying up forever.

## skill catalog

here is the list of tools included. i have broken them down by what they actually do.

### document creation

handling office files programmatically because manual formatting is for chumps.

| skill | purpose | source |
| :--- | :--- | :--- |
| **docx** | create and edit word docs without opening word | [anthropics](https://github.com/anthropics/skills/tree/main/document-skills/docx) |
| **pptx** | generate powerpoints because nobody likes making slides | [anthropics](https://github.com/anthropics/skills/tree/main/document-skills/pptx) |
| **xlsx** | crunch numbers in excel files | [anthropics](https://github.com/anthropics/skills/tree/main/document-skills/xlsx) |
| **pdf** | rip text out of pdfs or make new ones | [anthropics](https://github.com/anthropics/skills/tree/main/document-skills/pdf) |

### creative & design

stuff for when you need to feel artistic or make things look pretty.

| skill | purpose | source |
| :--- | :--- | :--- |
| **algorithmic-art** | make p5.js art with seeded randomness | [anthropics](https://github.com/anthropics/skills/tree/main/algorithmic-art) |
| **canvas-design** | design visuals in png/pdf formats | [anthropics](https://github.com/anthropics/skills/tree/main/canvas-design) |
| **slack-gif-creator** | make gifs specifically for slack reactions | [anthropics](https://github.com/anthropics/skills/tree/main/slack-gif-creator) |
| **theme-factory** | generate color themes that don't clash | [anthropics](https://github.com/anthropics/skills/tree/main/theme-factory) |

### development & testing

this is the heavy hitter section. use these to write better code or test the garbage code you already wrote.

| skill | purpose | source |
| :--- | :--- | :--- |
| **artifacts-builder** | build react/tailwind html artifacts | [anthropics](https://github.com/anthropics/skills/tree/main/artifacts-builder) |
| **mcp-builder** | create mcp servers for external apis | [anthropics](https://github.com/anthropics/skills/tree/main/mcp-builder) |
| **webapp-testing** | test local apps with playwright | [anthropics](https://github.com/anthropics/skills/tree/main/webapp-testing) |
| **aws-skills** | infrastructure automation for aws | [zxkane](https://github.com/zxkane/aws-skills) |
| **ios-simulator** | control the ios sim directly | [conorluddy](https://github.com/conorluddy/ios-simulator-skill) |
| **ffuf-skill** | web fuzzing integration | [jthack](https://github.com/jthack/ffuf_claude_skill) |
| **playwright** | browser automation | [lackeyjb](https://github.com/lackeyjb/playwright-skill) |
| **changelog-gen** | turn git commits into readable notes | [composiohq](https://github.com/ComposioHQ/awesome-claude-skills) |
| **debugging** | methodical problem solving steps | [obra](https://github.com/obra/superpowers) |
| **tdd** | test driven development enforcement | [obra](https://github.com/obra/superpowers) |

### productivity & collaboration

tools to make you look like you are working harder than you actually are.

| skill | purpose | source |
| :--- | :--- | :--- |
| **notebooklm** | talk to notebooklm docs | [pleaseprompto](https://github.com/PleasePrompto/notebooklm-skill) |
| **superpowers-lab** | general purpose claude enhancement | [obra](https://github.com/obra/superpowers-lab) |
| **research-writer** | adds research capabilities to writing | [composiohq](https://github.com/ComposioHQ/awesome-claude-skills) |
| **meeting-insights** | analyzes who talked too much in the meeting | [composiohq](https://github.com/ComposioHQ/awesome-claude-skills) |
| **brainstorming** | structured idea generation | [obra](https://github.com/obra/superpowers) |
| **writing-plans** | creates strategic docs | [obra](https://github.com/obra/superpowers) |

### specialized domains

stuff that you might never use but looks cool on the readme.

| skill | purpose | source |
| :--- | :--- | :--- |
| **scientific** | research and data analysis | [k-dense-ai](https://github.com/K-Dense-AI/claude-scientific-skills) |
| **win11-update** | windows 11 system management | [notmyself](https://github.com/NotMyself/claude-win11-speckit-update-skill) |
| **claudisms** | sms integration | [jeffersonwarrior](https://github.com/jeffersonwarrior/claudisms) |
| **defense-in-depth** | security layering strategies | [obra](https://github.com/obra/superpowers) |

## configuration

getting this to work depends on your environment. here is the recommended way to set things up if you are using mcp or a local client.

### file structure

keep your directory clean or you will regret it later.

```text
ordinary-claude-skills/
├── development/
│   ├── artifacts-builder/
│   └── webapp-testing/
├── documents/
│   └── pdf/
└── README.md
```

### config.json example

if you are using a tool that requires a config file to point to skills, it usually looks something like this.

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/path/to/ordinary-claude-skills"
      ]
    }
  }
}
```

> **warning**
> do not upload the entire repository to a single chat session context unless you want claude to burn through your token limit in about four seconds. pick and choose what you need.

## how-to examples

here is how you actually talk to claude once the skills are loaded.

### scenario 1: debugging a react app

load the `systematic-debugging` and `artifacts-builder` skills.

**you:**
> i have a react component that is not rendering the list items correctly. please use the systematic debugging skill to analyze the code i paste next, and then use the artifacts builder to propose a fix.

**claude:**
> acknowledged. i will apply the systematic debugging protocol. please paste the code.

### scenario 2: analyzing a competitor

load the `competitive-ads-extractor` skill.

**you:**
> here is a url to a landing page. run the ads extractor and tell me what their primary value proposition is.

**claude:**
> running extraction...

## troubleshooting

sometimes computers are hard.

*   **claude refuses to use the skill:**
    make sure you explicitly told claude the skill exists in the system prompt or that the file was successfully attached to the project context. usually it just doesn't know it's there.

*   **"file too large" error:**
    some of these skills have massive dependency folders. ignore the `node_modules` inside skill folders. you only need the source scripts and the instructions.

*   **skills contradicting each other:**
    don't load `creative-writing` and `technical-documentation` at the same time. claude will get confused about whether it should be shakespeare or a robot.

## dependencies

technically none for the repo itself, but individual skills have requirements.

*   **mandatory:** an active internet connection and a claude account (or api key).
*   **optional:**
    *   `python 3.x` (for data analysis skills)
    *   `node.js` (for mcp builder and testing skills)
    *   `playwright` (if you want to do browser automation)

## license & credits

i did not write most of these. i just collected them.

*   **anthropic skills:** mit license (mostly)
*   **community skills:** check the `LICENSE` file in each specific folder.

credits go to [anthropic](https://github.com/anthropics), [obra](https://github.com/obra), [composiohq](https://github.com/ComposioHQ), and the other legends listed in the source tables. if you own one of these and want me to take it down, just open an issue and i will nuke it.
