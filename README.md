<p align="center">
  <a href="https://github.com/Microck/ordinary-claude-skills">
    <img src="https://i.ibb.co/Q3kYxbBt/claudeskills.png" alt="i drew this with my left hand. as you can deduce, im indeed right-handed" width="600">
  </a>
</p>

<p align="center">a massive local repository of official and community-built claude skills, organized by category.</p>

<p align="center">
  <a href="https://microck.github.io/ordinary-claude-skills/#/"><img alt="docs" src="https://img.shields.io/badge/view-documentation-orange" /></a>
  <a href="https://github.com/Microck/ordinary-claude-skills/blob/main/LICENSE"><img alt="license" src="https://img.shields.io/badge/license-MIT-greene" /></a>
  <a href="https://github.com/Microck/ordinary-claude-skills"><img alt="maintenance" src="https://img.shields.io/badge/maintenance-passive-yellow" /></a>
  <a href="https://github.com/Microck/ordinary-claude-skills"><img alt="claude" src="https://img.shields.io/badge/AI-claude-purple" /></a>
</p>

---

## quickstart

there are two ways to consume this library.

### 1. the civilized way (search & browse)
go to the **[static site](https://microck.github.io/ordinary-claude-skills/#/)**.
i have indexed everything with search and categories. it is much easier than digging through folders.

### 2. the developer way (raw files)
clone the repo to map these skills into your own mcp servers or agents.

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
*   [configuration](#configuration)
*   [how-to examples](#how-to-examples)
*   [troubleshooting](#troubleshooting)
*   [dependencies](#dependencies)
*   [license & credits](#license--credits)

## overview

skills are basically fancy prompt packages and scripts that teach claude how to do specific things without you having to explain the context every single time. they load lazily (only when needed), which saves context window space and keeps claude from getting confused by instructions it doesn't need yet.

this repo aggregates hundreds of skills from anthropic, composiohq, k-dense-ai, and random internet geniuses.

## features

*   **non-curated selection:** i dumped everything in here. if it doesnt work i probably havent noticed. just let me know and i may or may not fix it.
*   **categorized:** everything is sorted so you don't have to doomscroll to find the python tools.
*   **standardized:** i tried to keep the folder structures somewhat consistent.
*   **local first:** designed to be cloned locally so you aren't dependent on a third party url staying up forever.

## skill catalog

i used to list all 600+ skills here, but it made the readme scroll for eternity.

**[view the full inventory on the documentation site →](https://microck.github.io/ordinary-claude-skills/#/)**

categories include:
*   **science & academia** (protein folding, astronomy, lab automation)
*   **software engineering** (api design, debugging, testing)
*   **infrastructure** (kubernetes, docker, terraform)
*   **data & ai** (vector dbs, llm evaluation, rag)
*   **business** (marketing, finance, legal)
*   **creative** (writing, art, philosophy)
*   **web3** (solidity, smart contracts, defi)

<img width="1920" height="914" alt="page" src="https://github.com/user-attachments/assets/1fa2d35e-5c58-46a3-ac21-e6548853559b" />

## configuration

getting this to work depends on your environment. here is the recommended way to set things up if you are using mcp or a local client.

### file structure

```text
ordinary-claude-skills/
├── docs/                  # the static website files
├── skills_all/    		   # everything
├── skills_categorized/    # everything in its right place
│   ├── backend/
│   │   └── api-design-principles/
│   └── web3-tools/
│       └── solidity-security/
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
        "/path/to/ordinary-claude-skills/skills_all"
      ]
    }
  }
}
```

or map only the category or specific skill you need.

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/path/to/ordinary-claude-skills/skills_categorized/[category]"
      ]
    }
  }
}
```

## how-to examples

here is how you actually talk to claude once the skills are loaded.

### scenario 1: debugging a react app

load the `debugging-strategies` and `frontend-design` skills.

**you:**
> i have a react component that is not rendering the list items correctly. please use the systematic debugging skill to analyze the code i paste next, and then use the frontend design skill to propose a fix.

**claude:**
> acknowledged. i will apply the systematic debugging protocol. please paste the code.

### scenario 2: analyzing a competitor

load the `competitive-ads-extractor` skill.

**you:**
> here is a url to a landing page. run the ads extractor and tell me what their primary value proposition is.

**claude:**
> running extraction...

### scenario 3: pdf extracting
load the `pdf` skill.

**you:**
> a client just sent me a scanned image of a spreadsheet pasted into a word doc and then exported as a pdf. i am losing my will to live. please use the pdf skill to extract the text so i don't walk the plank.

**claude:**
> extracting text now. please drink some water while i handle this crime against data structures.

### scenario 4: deploy roulette
load the `webapp-testing` skill.

**you:**
> i am about to push to prod on a friday afternoon. run the webapp testing skill on `localhost:3000` and tell me if i am going to get fired.

**claude:**
> starting playwright tests. i suggest you keep your resume updated just in case the login modal is broken again.


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

credits go to [anthropic](https://github.com/anthropics), [composiohq](https://github.com/ComposioHQ), [k-dense-ai](https://github.com/K-Dense-AI), and the other legends listed in the source tables. if you own one of these and want me to take it down, just open an issue and i will nuke it.
