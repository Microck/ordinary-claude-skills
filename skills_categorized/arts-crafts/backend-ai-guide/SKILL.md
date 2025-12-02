---
name: backend-ai-guide
description: |
  Expert guide for Backend.AI distributed computing platform. Automatically
  activates when users ask about:
  - Backend.AI architecture, components (Manager, Agent, Storage Proxy, Webserver, App Proxy)
  - Features (session scheduling, Sokovan orchestrator, multi-tenancy, resource allocation)
  - APIs (REST, GraphQL), authentication, RBAC authorization
  - Container runtime (kernels, jail sandbox, hook library, virtual folders)
  - Accelerator support (CUDA, ROCm, TPU, NPU, Graphcore IPU)
  - Client SDKs (Python, Java, JavaScript, PHP)
  - Setup, requirements (Python 3.13+, Docker, PostgreSQL, Redis, etcd)
  - How WebUI connects to/interacts with Backend.AI backend
  - Plugin interfaces, development setup, infrastructure
  Use when user mentions "Backend.AI", "backend.ai", "Sokovan", component names,
  or asks about the backend platform this WebUI connects to.
 allowed-tools: WebFetch, Read
---

# Backend.AI Guide Skill

## Purpose

This skill provides expert-level information about the Backend.AI platform by:

- Fetching official documentation from the Backend.AI GitHub repository
- Recursively exploring Major Components documentation links
- Following relevant links to gather comprehensive technical details
- Providing accurate, source-backed answers about Backend.AI architecture and features

## When to Use

Activate this skill when the user asks about:

- Backend.AI platform overview or architecture
- Backend.AI components (Manager, Agent, Storage Proxy, Webserver, App Proxy)
- Backend.AI setup, requirements, or infrastructure
- Backend.AI APIs (REST, GraphQL)
- Backend.AI features (session scheduling, resource allocation, multi-tenancy)
- Backend.AI kernels, containers, or runtime elements
- How the WebUI connects to or interacts with Backend.AI backend
- Differences between Backend.AI components

## Primary Documentation Sources

1. **Main README**: https://github.com/lablup/backend.ai/blob/main/README.md

   - Overview and architecture
   - Major Components section with component links
   - Requirements and setup information

2. **Major Component READMEs**: Follow links from the Major Components section

   - Manager component details
   - Agent component details
   - Storage Proxy details
   - Webserver details
   - App Proxy details
   - And other components

3. **Recursive Link Following**: When a component README references additional documentation, follow those links to gather comprehensive information

## Instructions

### Step 1: Identify the Question Scope

- Determine what aspect of Backend.AI the user is asking about
- Identify which components or features are relevant

### Step 2: Fetch the Main README

- Always start by fetching: https://github.com/lablup/backend.ai/blob/main/README.md
- Extract key information relevant to the question
- Identify links to Major Components that need to be explored

### Step 3: Recursively Fetch Component Documentation

- For questions about specific components, fetch their individual READMEs
- Component README links are found in the "Major Components" section
- Example component paths (adjust based on actual links):
  - Manager: `src/ai/backend/manager/README.md`
  - Agent: `src/ai/backend/agent/README.md`
  - Storage Proxy: `src/ai/backend/storage/README.md`
  - Webserver: `src/ai/backend/web/README.md`
  - App Proxy: `src/ai/backend/appproxy/README.md`

### Step 4: Follow Additional Links

- If component READMEs reference additional documentation, follow those links
- Common additional documentation types:
  - Architecture diagrams
  - API documentation
  - Configuration guides
  - Development guides
- **Important**: Only follow links that are relevant to answering the user's question

### Step 5: Synthesize and Present Information

- Combine information from all fetched sources
- Structure the answer logically:
  1. Direct answer to the user's question
  2. Supporting details from official documentation
  3. Related component interactions (if applicable)
  4. Links to source documentation for further reading
- Use clear headings and formatting
- Include code examples or configuration snippets when relevant

## Best Practices

1. **Always Cite Sources**

   - Reference the specific documentation URLs you fetched
   - Help users find more detailed information

2. **Stay Current**

   - Fetch documentation fresh each time (don't rely on cached knowledge)
   - Note version requirements (Python, Docker, PostgreSQL, etc.)

3. **Explain Component Interactions**

   - Backend.AI is a distributed system - explain how components work together
   - Clarify the relationship between WebUI (this project) and Backend.AI backend

4. **Be Precise with Technical Details**

   - Include version numbers, requirements, and configuration details
   - Distinguish between different API types (REST vs GraphQL)

5. **Limit Recursion Depth**
   - Fetch main README + relevant component READMEs
   - Only follow 1-2 additional link levels unless user needs deep details
   - Balance thoroughness with response time

## Example Question Types

**Architecture Questions**

- "How does Backend.AI work?"
- "What is the architecture of Backend.AI?"
- "What are the main components of Backend.AI?"

**Component Questions**

- "What does the Backend.AI Manager do?"
- "How does the Agent component work?"
- "What is the Storage Proxy?"

**Integration Questions**

- "How does this WebUI connect to Backend.AI?"
- "What APIs does Backend.AI expose?"
- "How do I authenticate with Backend.AI?"

**Setup Questions**

- "What are the requirements for Backend.AI?"
- "How do I set up Backend.AI?"
- "What infrastructure does Backend.AI need?"

## Response Format

Structure answers as follows:

```markdown
## [Direct Answer to Question]

[Concise, direct answer based on official documentation]

## Details

[Supporting information from fetched documentation]

### Component Interactions (if applicable)

[How different components work together]

## Technical Specifications (if applicable)

- Requirements: [versions, dependencies]
- Configuration: [relevant settings]
- APIs: [REST/GraphQL endpoints]

## Source Documentation

- Main: [URL to main README]
- Component: [URLs to component READMEs]
- Additional: [URLs to other relevant docs]
```

## Notes

- Backend.AI is the **backend platform** that this WebUI project connects to
- This WebUI (backend.ai-webui) is a **client application** that uses Backend.AI's APIs
- When users ask about "the backend" in this project context, they likely mean Backend.AI
- Distinguish between WebUI code (this project) and Backend.AI platform code (separate repo)

## Limitations

- This skill only fetches publicly available GitHub documentation
- For questions requiring internal documentation or specific deployment details, direct users to Backend.AI team
- Cannot access private repositories or non-public documentation
