<p align="center">
  <a href="https://github.com/Microck/ordinary-claude-skills">
    <img src="https://i.ibb.co/Q3kYxbBt/claudeskills.png" alt="i drew this with my left hand. as you can deduce, im indeed right-handed" width="600">
  </a>
</p>

<p align="center">a massive local repository of official and community-built claude skills, organized by category.</p>

<p align="center">
  <a href="https://github.com/Microck/ordinary-claude-skills/blob/main/LICENSE"><img alt="license" src="https://img.shields.io/badge/license-MIT-greene" /></a>
  <a href="https://github.com/Microck/ordinary-claude-skills"><img alt="maintenance" src="https://img.shields.io/badge/maintenance-passive-yellow" /></a>
  <a href="https://github.com/Microck/ordinary-claude-skills"><img alt="claude" src="https://img.shields.io/badge/AI-claude-purple" /></a>
</p>

---

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
    *   [science & academia](#science--academia)
    *   [software engineering](#software-engineering)
    *   [infrastructure & security](#infrastructure--security)
    *   [data & ai](#data--ai)
    *   [business & operations](#business--operations)
    *   [creative & humanities](#creative--humanities)
    *   [web3 & blockchain](#web3--blockchain)
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

here is the massive list of tools included. i have filtered out duplicates where possible because some of these skills apply to nineteen different categories.

### science & academia

tools for the researchers, biologists, and people who understand what protein folding is.

| skill | purpose | source |
| :--- | :--- | :--- |
| **alphafold-database** | access 200m+ ai-predicted protein structures | [k-dense-ai](https://github.com/K-Dense-AI/claude-scientific-skills) |
| **arxiv-search** | search arxiv repository for physics and cs papers | [langchain-ai](https://github.com/langchain-ai/deepagents) |
| **benchling-integration** | r&d platform integration for dna and proteins | [k-dense-ai](https://github.com/K-Dense-AI/claude-scientific-skills) |
| **biomni** | autonomous biomedical ai agent for complex research | [k-dense-ai](https://github.com/K-Dense-AI/claude-scientific-skills) |
| **biopython** | primary python toolkit for molecular biology | [k-dense-ai](https://github.com/K-Dense-AI/claude-scientific-skills) |
| **chembl-database** | query bioactive molecules and drug discovery data | [k-dense-ai](https://github.com/K-Dense-AI/claude-scientific-skills) |
| **clinicaltrials-database** | query clinicaltrials.gov api for patient matching | [k-dense-ai](https://github.com/K-Dense-AI/claude-scientific-skills) |
| **cosmic-database** | access cancer mutation database and signatures | [k-dense-ai](https://github.com/K-Dense-AI/claude-scientific-skills) |
| **datamol** | simplified molecular manipulation wrapper for rdkit | [k-dense-ai](https://github.com/K-Dense-AI/claude-scientific-skills) |
| **drugbank-database** | comprehensive drug properties and interactions | [k-dense-ai](https://github.com/K-Dense-AI/claude-scientific-skills) |
| **exploratory-data-analysis** | analyze scientific data files across 200+ formats | [k-dense-ai](https://github.com/K-Dense-AI/claude-scientific-skills) |
| **geo-database** | access ncbi geo for gene expression data | [k-dense-ai](https://github.com/K-Dense-AI/claude-scientific-skills) |
| **histolab** | digital pathology image processing for wsi | [k-dense-ai](https://github.com/K-Dense-AI/claude-scientific-skills) |
| **hypogenic** | automated hypothesis generation and testing | [k-dense-ai](https://github.com/K-Dense-AI/claude-scientific-skills) |
| **neurokit2** | biosignal processing for ecg, eeg, and eda | [k-dense-ai](https://github.com/K-Dense-AI/claude-scientific-skills) |
| **openalex-database** | query and analyze 240m+ scholarly works | [k-dense-ai](https://github.com/K-Dense-AI/claude-scientific-skills) |
| **pylabrobot** | automation toolkit for liquid handling robots | [k-dense-ai](https://github.com/K-Dense-AI/claude-scientific-skills) |
| **rdkit** | cheminformatics for fine-grained molecular control | [k-dense-ai](https://github.com/K-Dense-AI/claude-scientific-skills) |

### software engineering

utilities to help you write code that sucks less.

| skill | purpose | source |
| :--- | :--- | :--- |
| **api-design-principles** | master rest and graphql api design patterns | [wshobson](https://github.com/wshobson/agents) |
| **bash-defensive-patterns** | robust shell scripting for production | [wshobson](https://github.com/wshobson/agents) |
| **code-review-excellence** | practices for constructive pr feedback | [wshobson](https://github.com/wshobson/agents) |
| **codex** | execute codex cli for refactoring | [cexll](https://github.com/cexll/myclaude) |
| **command-development** | guidance for creating claude code slash commands | [anthropics](https://github.com/anthropics/claude-code) |
| **debugging-strategies** | systematic root cause analysis techniques | [wshobson](https://github.com/wshobson/agents) |
| **fastapi-templates** | production-ready fastapi scaffolding | [wshobson](https://github.com/wshobson/agents) |
| **frontend-design** | create distinctive, non-generic web interfaces | [anthropics](https://github.com/anthropics/claude-code) |
| **git-advanced-workflows** | master rebasing, bisect, and worktrees | [wshobson](https://github.com/wshobson/agents) |
| **hook-development** | create pre/post tool hooks for claude | [anthropics](https://github.com/anthropics/claude-code) |
| **modern-javascript-patterns** | master es6+ features and async patterns | [wshobson](https://github.com/wshobson/agents) |
| **monorepo-management** | manage turborepo and nx workspaces | [wshobson](https://github.com/wshobson/agents) |
| **python-packaging** | create and publish distributable python packages | [wshobson](https://github.com/wshobson/agents) |
| **react-modernization** | migrate class components to hooks | [wshobson](https://github.com/wshobson/agents) |
| **shellcheck-configuration** | static analysis for shell script quality | [wshobson](https://github.com/wshobson/agents) |
| **typescript-advanced-types** | master generics and conditional types | [wshobson](https://github.com/wshobson/agents) |
| **uv-package-manager** | fast python dependency management | [wshobson](https://github.com/wshobson/agents) |

### infrastructure & security

plumbing for the internet. keeping the servers from catching fire.

| skill | purpose | source |
| :--- | :--- | :--- |
| **auth-implementation** | implement jwt, oauth2, and rbac patterns | [wshobson](https://github.com/wshobson/agents) |
| **better-auth** | typescript auth framework implementation | [mrgoonie](https://github.com/mrgoonie/claudekit-skills) |
| **ci-cd-patterns** | pipelines for gitlab and github actions | [wshobson](https://github.com/wshobson/agents) |
| **cloudbase-database** | use document database web sdk | [tencentcloudbase](https://github.com/TencentCloudBase/awesome-cloudbase-examples) |
| **cloudflare-manager** | manage workers, kv, and dns records | [qdhenry](https://github.com/qdhenry/Claude-Command-Suite) |
| **cost-optimization** | optimize cloud spend and resources | [wshobson](https://github.com/wshobson/agents) |
| **database-migration** | zero-downtime schema changes | [wshobson](https://github.com/wshobson/agents) |
| **defense-in-depth** | validate data at every system layer | [obra](https://github.com/obra/superpowers) |
| **docker-kubernetes** | k8s manifests and security policies | [wshobson](https://github.com/wshobson/agents) |
| **error-tracking** | add sentry v8 monitoring to projects | [diet103](https://github.com/diet103/claude-code-infrastructure-showcase) |
| **gitops-workflow** | implement argocd and flux deployments | [wshobson](https://github.com/wshobson/agents) |
| **grafana-dashboards** | create visualization for system metrics | [wshobson](https://github.com/wshobson/agents) |
| **microservices-patterns** | distributed architecture design | [wshobson](https://github.com/wshobson/agents) |
| **postgres-migrations** | guide for safe postgres schema changes | [pr-pm](https://github.com/pr-pm/prpm) |
| **sast-configuration** | static application security testing | [wshobson](https://github.com/wshobson/agents) |
| **secrets-management** | secure vault and pipeline secrets | [wshobson](https://github.com/wshobson/agents) |
| **sql-optimization** | master indexing and query performance | [wshobson](https://github.com/wshobson/agents) |
| **terraform-modules** | build reusable iac components | [wshobson](https://github.com/wshobson/agents) |

### data & ai

crunching numbers and hallucinating answers.

| skill | purpose | source |
| :--- | :--- | :--- |
| **agentdb-vector-search** | semantic search with agentdb | [ruvnet](https://github.com/ruvnet/claude-flow) |
| **analyzing-agentscope** | retrieve info from agentscope library | [agentscope-ai](https://github.com/agentscope-ai/agentscope) |
| **chroma** | open-source embedding database | [zechenzhangagi](https://github.com/zechenzhangAGI/AI-research-SKILLs) |
| **claude-opus-migration** | migrate prompts from sonnet to opus | [anthropics](https://github.com/anthropics/claude-code) |
| **flow-nexus-neural** | train neural networks in e2b sandboxes | [ruvnet](https://github.com/ruvnet/claude-flow) |
| **langchain-architecture** | design agents and tool integration | [wshobson](https://github.com/wshobson/agents) |
| **llm-evaluation** | metrics and benchmarking for ai apps | [wshobson](https://github.com/wshobson/agents) |
| **mcp-builder** | create model context protocol servers | [davila7](https://github.com/davila7/claude-code-templates) |
| **ml-pipeline-workflow** | end-to-end mlops from training to deploy | [wshobson](https://github.com/wshobson/agents) |
| **pinecone** | managed vector database for production | [zechenzhangagi](https://github.com/zechenzhangAGI/AI-research-SKILLs) |
| **prompt-engineering** | maximize llm performance and reliability | [wshobson](https://github.com/wshobson/agents) |
| **rag-implementation** | build retrieval-augmented generation | [wshobson](https://github.com/wshobson/agents) |
| **zapier-workflows** | trigger automations and mcp orchestration | [davila7](https://github.com/davila7/claude-code-templates) |

### business & operations

boring but necessary stuff for capitalism.

| skill | purpose | source |
| :--- | :--- | :--- |
| **agile-product-owner** | backlog management and user stories | [alirezarezvani](https://github.com/alirezarezvani/claude-skills) |
| **alex-hormozi-pitch** | create offers using $100m methodology | [danielmiessler](https://github.com/danielmiessler/Personal_AI_Infrastructure) |
| **billing-automation** | subscription lifecycle and invoicing | [wshobson](https://github.com/wshobson/agents) |
| **competitive-analysis** | extract and analyze competitor ads | [composiohq](https://github.com/ComposioHQ/awesome-claude-skills) |
| **create-plan** | generate detailed implementation strategies | [antinomyhq](https://github.com/antinomyhq/forge) |
| **financial-models** | dcf analysis and monte carlo simulations | [anthropics](https://github.com/anthropics/claude-cookbooks) |
| **ga4-compliance** | privacy, gdpr, and consent mode setup | [henkisdabro](https://github.com/henkisdabro/wookstar-claude-code-plugins) |
| **lead-researcher** | identify high-quality sales leads | [composiohq](https://github.com/ComposioHQ/awesome-claude-skills) |
| **linear-todo-sync** | fetch and organize tasks from linear | [qdhenry](https://github.com/qdhenry/Claude-Command-Suite) |
| **paypal-integration** | implement checkout and subscriptions | [wshobson](https://github.com/wshobson/agents) |
| **product-strategist** | okrs and market analysis for heads of product | [alirezarezvani](https://github.com/alirezarezvani/claude-skills) |
| **shopify-dev** | build apps, themes, and extensions | [mrgoonie](https://github.com/mrgoonie/claudekit-skills) |
| **stripe-integration** | robust payment processing flows | [wshobson](https://github.com/wshobson/agents) |

### creative & humanities

making things look pretty, writing novels, and ancient wisdom.

| skill | purpose | source |
| :--- | :--- | :--- |
| **all-traditions-speaking** | universal wisdom from all traditions | [nikhilvallishayee](https://github.com/nikhilvallishayee/universal-pattern-space) |
| **blog-post-writer** | transform brain dumps into polished posts | [nicknisi](https://github.com/nicknisi/dotfiles) |
| **card-news-generator** | create instagram-style news series | [bear2u](https://github.com/bear2u/my-skills) |
| **content-researcher** | research, cite, and outline content | [composiohq](https://github.com/ComposioHQ/awesome-claude-skills) |
| **dnd5e-srd** | rag skill for d&d rules and spells | [datapizza-labs](https://github.com/datapizza-labs/rag-dataset-builder) |
| **fantasy-building** | genre conventions for magic and worlds | [wordflowlab](https://github.com/wordflowlab/novel-writer-skills) |
| **gemini-imagegen** | generate images using gemini api | [everyinc](https://github.com/EveryInc/compounding-engineering-plugin) |
| **markitdown** | convert any file format to markdown | [k-dense-ai](https://github.com/K-Dense-AI/claude-scientific-skills) |
| **meeting-insights** | analyze transcripts for behavioral patterns | [composiohq](https://github.com/ComposioHQ/awesome-claude-skills) |
| **mystery-conventions** | writing guide for crime and suspense | [wordflowlab](https://github.com/wordflowlab/novel-writer-skills) |
| **novelweave-workflow** | complete novel creation methodology | [wordflowlab](https://github.com/wordflowlab/novelweave) |
| **siberian-shamanism** | navigate original shamanic technology | [nikhilvallishayee](https://github.com/nikhilvallishayee/universal-pattern-space) |
| **slack-gif-creator** | create optimized gifs for slack | [davila7](https://github.com/davila7/claude-code-templates) |
| **story-explanation** | create compelling narrative summaries | [danielmiessler](https://github.com/danielmiessler/Personal_AI_Infrastructure) |
| **video-downloader** | download videos for offline archival | [composiohq](https://github.com/ComposioHQ/awesome-claude-skills) |

### web3 & blockchain

magic internet money tools.

| skill | purpose | source |
| :--- | :--- | :--- |
| **blockchain-developer** | smart contract and dapp architecture | [zenobi-us](https://github.com/zenobi-us/dotfiles) |
| **btc-connect** | bitcoin wallet integration for react/vue | [icehugh](https://github.com/IceHugh/btc-connect) |
| **crypto-research** | market analysis and price trends | [stevengonsalvez](https://github.com/stevengonsalvez/claudecode-bootstrap) |
| **defi-templates** | protocols for staking and amms | [wshobson](https://github.com/wshobson/agents) |
| **nft-standards** | erc-721 and erc-1155 implementation | [wshobson](https://github.com/wshobson/agents) |
| **smart-contract-gen** | generate secure solidity contracts | [dexploarer](https://github.com/Dexploarer/claudius-skills) |
| **solidity-security** | prevent vulnerabilities in contracts | [wshobson](https://github.com/wshobson/agents) |
| **web3-testing** | hardhat and foundry test suites | [wshobson](https://github.com/wshobson/agents) |

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
