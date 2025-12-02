---
name: ai-llm-engineering
description: |
 Operational skill hub for LLM system architecture, evaluation, deployment, and optimization (modern production standards). Links to specialized skills for prompts, RAG, agents, and safety. Integrates recent advances: PEFT/LoRA fine-tuning, hybrid RAG handoff (see dedicated skill), vLLM 24x throughput, multi-layered security (90%+ bypass for single-layer), automated drift detection (18-second response), and CI/CD-aligned evaluation.
---

# LLM Engineering – Operational Skill Hub

A single resource for executing, validating, and scaling LLM systems with **modern production standards**, while delegating domain depth to specialized skills.

This skill provides quick reference, decision frameworks, and navigation to detailed operational patterns for:

- Data, training, fine-tuning (PEFT/LoRA standard)
- Evaluation (automated testing, metrics, rollout gates)
- Deployment (vLLM 24x throughput, FP8/FP4 quantization)
- LLMOps (automated drift detection, retraining)
- Safety (multi-layered defenses, AI-powered guardrails)

**For detailed patterns:** See [Resources](#resources-best-practices--operational-patterns) and [Templates](#templates-copy-paste-ready) sections below.

---

## Quick Reference

| Task | Tool/Framework | Command/Pattern | When to Use |
|------|----------------|-----------------|-------------|
| RAG Pipeline | LlamaIndex, LangChain | Page-level chunking + hybrid retrieval | Dynamic knowledge, 0.648 accuracy |
| Agentic Workflow | LangGraph, AutoGen, CrewAI | ReAct, multi-agent orchestration | Complex tasks, tool use required |
| Prompt Design | Anthropic, OpenAI guides | CoT, few-shot, structured | Task-specific behavior control |
| Evaluation | LangSmith, W&B, RAGAS | Multi-metric (hallucination, bias, cost) | Quality validation, A/B testing |
| Production Deploy | vLLM, TensorRT-LLM | FP8/FP4 quantization, 24x throughput | High-throughput serving, cost optimization |
| Monitoring | Arize Phoenix, LangFuse | Drift detection, 18-second response | Production LLM systems |

---

## Decision Tree: LLM System Architecture

```text
Building LLM application: [Architecture Selection]
    ├─ Need current knowledge?
    │   ├─ Simple Q&A? → Basic RAG (page-level chunking + hybrid retrieval)
    │   └─ Complex retrieval? → Advanced RAG (reranking + contextual retrieval)
    │
    ├─ Need tool use / actions?
    │   ├─ Single task? → Simple agent (ReAct pattern)
    │   └─ Multi-step workflow? → Multi-agent (LangGraph, CrewAI)
    │
    ├─ Static behavior sufficient?
    │   ├─ Quick MVP? → Prompt engineering (CI/CD integrated)
    │   └─ Production quality? → Fine-tuning (PEFT/LoRA)
    │
    └─ Best results?
        └─ Hybrid (RAG + Fine-tuning + Agents) → Comprehensive solution
```

**See [Decision Matrices](resources/decision-matrices.md) for detailed selection criteria.**

---

## When to Use This Skill

Claude should invoke this skill when the user asks about:

- LLM preflight/project checklists, production best practices, or data pipelines
- Building or deploying RAG, agentic, or prompt-based LLM apps
- Prompt design, chain-of-thought (CoT), ReAct, or template patterns
- Troubleshooting LLM hallucination, bias, retrieval issues, or production failures
- Evaluating LLMs: benchmarks, multi-metric eval, or rollout/monitoring
- LLMOps: deployment, rollback, scaling, resource optimization
- Technology stack selection (models, vector DBs, frameworks)
- Production deployment strategies and operational patterns

---

## Scope Boundaries (Use These Skills for Depth)

- **Prompt design & CI/CD** → [ai-prompt-engineering](../ai-prompt-engineering/SKILL.md)
- **RAG pipelines & chunking** → [ai-llm-rag-engineering](../ai-llm-rag-engineering/SKILL.md)
- **Search tuning (BM25, HNSW, hybrid)** → [ai-llm-search-retrieval](../ai-llm-search-retrieval/SKILL.md)
- **Agent architectures & tools** → [ai-agents-development](../ai-agents-development/SKILL.md)
- **Serving optimization/quantization** → [ai-llm-ops-inference](../ai-llm-ops-inference/SKILL.md)
- **Production deployment/monitoring** → [ai-ml-ops-production](../ai-ml-ops-production/SKILL.md)
- **Security/guardrails** → [ai-ml-ops-security](../ai-ml-ops-security/SKILL.md)

---

## Resources (Best Practices & Operational Patterns)

Comprehensive operational guides with checklists, patterns, and decision frameworks:

### Core Operational Patterns

- **[Project Planning Patterns](resources/project-planning-patterns.md)** - Stack selection, FTI pipeline, performance budgeting
  - AI engineering stack selection matrix
  - Feature/Training/Inference (FTI) pipeline blueprint
  - Performance budgeting and goodput gates
  - Progressive complexity (prompt → RAG → fine-tune → hybrid)

- **[Production Checklists](resources/production-checklists.md)** - Pre-deployment validation and operational checklists
  - LLM lifecycle checklist (modern production standards)
  - Data & training, RAG pipeline, deployment & serving
  - Safety/guardrails, evaluation, agentic systems
  - Reliability & data infrastructure (DDIA-grade)
  - Weekly production tasks

- **[Common Design Patterns](resources/common-design-patterns.md)** - Copy-paste ready implementation examples
  - Chain-of-Thought (CoT) prompting
  - ReAct (Reason + Act) pattern
  - RAG pipeline (minimal to advanced)
  - Agentic planning loop
  - Self-reflection and multi-agent collaboration

- **[Decision Matrices](resources/decision-matrices.md)** - Quick reference tables for selection
  - RAG type decision matrix (naive → advanced → modular)
  - Production evaluation table with targets and actions
  - Model selection matrix (GPT-4, Claude, Gemini, self-hosted)
  - Vector database, embedding model, framework selection
  - Deployment strategy matrix

- **[Anti-Patterns](resources/anti-patterns.md)** - Common mistakes and prevention strategies
  - Data leakage, prompt dilution, RAG context overload
  - Agentic runaway, over-engineering, ignoring evaluation
  - Hard-coded prompts, missing observability
  - Detection methods and prevention code examples

### Domain-Specific Patterns

- **[LLMOps Best Practices](resources/llmops-best-practices.md)** - Operational lifecycle and deployment patterns
- **[Evaluation Patterns](resources/eval-patterns.md)** - Testing, metrics, and quality validation
- **[Prompt Engineering Patterns](resources/prompt-engineering-patterns.md)** - Quick reference (canonical skill: [ai-prompt-engineering](../ai-prompt-engineering/SKILL.md))
- **[Agentic Patterns](resources/agentic-patterns.md)** - Quick reference (canonical skill: [ai-agents-development](../ai-agents-development/SKILL.md))
- **[RAG Best Practices](resources/rag-best-practices.md)** - Quick reference (canonical skill: [ai-llm-rag-engineering](../ai-llm-rag-engineering/SKILL.md))

**Note:** Each resource file includes preflight/validation checklists, copy-paste reference tables, inline templates, anti-patterns, and decision matrices.

---

## Templates (Copy-Paste Ready)

Production templates by use case and technology:

### RAG Pipelines

- **[Basic RAG](templates/rag-pipelines/template-basic-rag.md)** - Simple retrieval-augmented generation
- **[Advanced RAG](templates/rag-pipelines/template-advanced-rag.md)** - Hybrid retrieval, reranking, contextual embeddings

### Prompt Engineering

- **[Chain-of-Thought](templates/prompt-engineering/template-cot.md)** - Step-by-step reasoning pattern
- **[ReAct](templates/prompt-engineering/template-react.md)** - Reason + Act for tool use

### Agentic Workflows

- **[Reflection Agent](templates/agentic-workflows/template-reflection.md)** - Self-critique and improvement
- **[Multi-Agent](templates/agentic-workflows/template-multi-agent.md)** - Manager-worker orchestration

### Data Pipelines

- **[Data Quality](templates/data-pipelines/template-data-quality.md)** - Validation, deduplication, PII detection

### Deployment

- **[LLM Deployment](templates/deployment/template-llm-deployment.md)** - Production deployment with monitoring

### Evaluation

- **[Multi-Metric Evaluation](templates/evaluation/template-multi-metric.md)** - Comprehensive testing suite

---

## Related Skills

This skill integrates with complementary Claude Code skills:

### Core Dependencies

- **[ai-llm-rag-engineering](../ai-llm-rag-engineering/SKILL.md)** - Advanced RAG patterns, chunking strategies, hybrid retrieval, reranking
- **[ai-llm-search-retrieval](../ai-llm-search-retrieval/SKILL.md)** - Search optimization, BM25 tuning, vector search, ranking pipelines
- **[ai-prompt-engineering](../ai-prompt-engineering/SKILL.md)** - Systematic prompt design, evaluation, testing, and optimization
- **[ai-agents-development](../ai-agents-development/SKILL.md)** - Agent architectures, tool use, multi-agent systems, autonomous workflows

### Production & Operations

- **[ai-llm-development](../ai-llm-development/SKILL.md)** - Model training, fine-tuning, dataset creation, instruction tuning
- **[ai-llm-ops-inference](../ai-llm-ops-inference/SKILL.md)** - Production serving, quantization, batching, GPU optimization
- **[ai-ml-ops-production](../ai-ml-ops-production/SKILL.md)** - Deployment patterns, monitoring, drift detection, API design
- **[ai-ml-ops-security](../ai-ml-ops-security/SKILL.md)** - Security guardrails, prompt injection defense, privacy protection

---

## External Resources

See **[data/sources.json](data/sources.json)** for 50+ curated authoritative sources:

- **Official LLM platform docs** - OpenAI, Anthropic, Gemini, Mistral, Azure OpenAI, AWS Bedrock
- **Open-source models and frameworks** - HuggingFace Transformers, LLaMA, vLLM, PEFT/LoRA, DeepSpeed
- **RAG frameworks and vector DBs** - LlamaIndex, LangChain, LangGraph, Haystack, Pinecone, Qdrant, Chroma
- **2025 Agentic frameworks** - Anthropic Agent SDK, AutoGen, CrewAI, LangGraph Multi-Agent, Semantic Kernel
- **2025 RAG innovations** - Microsoft GraphRAG (knowledge graphs), Pathway (real-time), hybrid retrieval
- **Prompt engineering** - Anthropic Prompt Library, Prompt Engineering Guide, CoT/ReAct patterns
- **Evaluation and monitoring** - OpenAI Evals, HELM, Anthropic Evals, LangSmith, W&B, Arize Phoenix
- **Production deployment** - LiteLLM, Ollama, RunPod, Together AI, vLLM serving

---

## Usage

### For New Projects

1. Start with **[Production Checklists](resources/production-checklists.md)** - Validate all pre-deployment requirements
2. Use **[Decision Matrices](resources/decision-matrices.md)** - Select technology stack
3. Reference **[Project Planning Patterns](resources/project-planning-patterns.md)** - Design FTI pipeline
4. Implement with **[Common Design Patterns](resources/common-design-patterns.md)** - Copy-paste code examples
5. Avoid **[Anti-Patterns](resources/anti-patterns.md)** - Learn from common mistakes

### For Troubleshooting

1. Check **[Anti-Patterns](resources/anti-patterns.md)** - Identify failure modes and mitigations
2. Use **[Decision Matrices](resources/decision-matrices.md)** - Evaluate if architecture fits use case
3. Reference **[Common Design Patterns](resources/common-design-patterns.md)** - Verify implementation correctness

### For Ongoing Operations

1. Follow **[Production Checklists](resources/production-checklists.md)** - Weekly operational tasks
2. Integrate **[Evaluation Patterns](resources/eval-patterns.md)** - Continuous quality monitoring
3. Apply **[LLMOps Best Practices](resources/llmops-best-practices.md)** - Deployment and rollback procedures

---

## Navigation Summary

**Quick Decisions:** [Decision Matrices](resources/decision-matrices.md)
**Pre-Deployment:** [Production Checklists](resources/production-checklists.md)
**Planning:** [Project Planning Patterns](resources/project-planning-patterns.md)
**Implementation:** [Common Design Patterns](resources/common-design-patterns.md)
**Troubleshooting:** [Anti-Patterns](resources/anti-patterns.md)

**Domain Depth:** [LLMOps](resources/llmops-best-practices.md) | [Evaluation](resources/eval-patterns.md) | [Prompts](resources/prompt-engineering-patterns.md) | [Agents](resources/agentic-patterns.md) | [RAG](resources/rag-best-practices.md)

**Templates:** [templates/](templates/) - Copy-paste ready production code

**Sources:** [data/sources.json](data/sources.json) - Authoritative documentation links

---
