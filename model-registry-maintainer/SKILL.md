---
name: model-registry-maintainer
description: Guide for maintaining the MassGen model and backend registry. This skill should be used when adding new models, updating model information (release dates, pricing, context windows), or ensuring the registry stays current with provider releases. Covers both the capabilities registry and the pricing/token manager.
---

# Model Registry Maintainer

This skill provides guidance for maintaining MassGen's model registry across two key files:

1. **`massgen/backend/capabilities.py`** - Models, capabilities, release dates
2. **`massgen/token_manager/token_manager.py`** - Pricing, context windows

## When to Use This Skill

- New model released by a provider
- Model pricing changes
- Context window limits updated
- Model capabilities changed
- New provider/backend added

## Two Files to Maintain

### File 1: capabilities.py (Models & Features)

**What it contains:**
- List of available models per provider
- Model capabilities (web search, code execution, vision, etc.)
- Release dates
- Default models

**Used by:**
- Config builder (`--quickstart`, `--generate-config`)
- Documentation generation
- Backend validation

**Always update this file** for new models.

### File 2: token_manager.py (Pricing & Limits)

**What it contains:**
- Hardcoded pricing/context windows for models NOT in LiteLLM database
- On-demand loading from LiteLLM database (500+ models)

**Used by:**
- Cost estimation
- Token counting
- Context management

**Pricing resolution order:**
1. LiteLLM database (fetched on-demand, cached 1 hour)
2. Hardcoded PROVIDER_PRICING (fallback only)
3. Pattern matching heuristics

**Only update PROVIDER_PRICING if:**
- Model is NOT in LiteLLM database
- LiteLLM pricing is incorrect/outdated
- Model is custom/internal to your organization

## Information to Gather for New Models

### 1. Release Date
- Format: `"YYYY-MM"`
- Sources:
  - OpenAI: https://openai.com/index
  - Anthropic: https://www.anthropic.com/news
  - Google DeepMind: https://blog.google/technology/google-deepmind/
  - xAI: https://x.ai/news

### 2. Context Window
- Input context size (tokens)
- Max output tokens
- Look for: "context window", "max tokens", "input/output limits"

### 3. Pricing
- Input cost per 1K tokens (USD)
- Output cost per 1K tokens (USD)
- Cached input cost (if applicable)
- Sources:
  - OpenAI: https://openai.com/api/pricing/
  - Anthropic: https://www.anthropic.com/pricing
  - Google: https://ai.google.dev/pricing
  - xAI: https://x.ai/api/pricing

### 4. Capabilities
- Web search, code execution, vision, reasoning, etc.
- Check official API documentation

### 5. Model Name
- Exact API identifier (case-sensitive)
- Check provider's model documentation

## Adding a New Model - Complete Workflow

### Step 1: Add to capabilities.py

Add model to the `models` list and `model_release_dates`:

```python
# massgen/backend/capabilities.py

"openai": BackendCapabilities(
    # ... existing fields ...
    models=[
        "new-model-name",  # Add here (newest first)
        "gpt-5.1",
        # ... existing models ...
    ],
    model_release_dates={
        "new-model-name": "2025-12",  # Add here
        "gpt-5.1": "2025-11",
        # ... existing dates ...
    },
)
```

### Step 2: Check if pricing is in LiteLLM (Usually Skip)

**First, check if the model is already in LiteLLM database:**

```python
import requests

url = "https://raw.githubusercontent.com/BerriAI/litellm/main/model_prices_and_context_window.json"
pricing_db = requests.get(url).json()

if "new-model-name" in pricing_db:
    print("✅ Model found in LiteLLM - no need to update token_manager.py")
    print(f"Pricing: ${pricing_db['new-model-name']['input_cost_per_token']*1000}/1K input")
else:
    print("❌ Model NOT in LiteLLM - need to add to PROVIDER_PRICING")
```

**Only if NOT in LiteLLM**, add to `PROVIDER_PRICING`:

```python
# massgen/token_manager/token_manager.py

PROVIDER_PRICING: Dict[str, Dict[str, ModelPricing]] = {
    "OpenAI": {
        # Format: ModelPricing(input_per_1k, output_per_1k, context_window, max_output)
        "new-model-name": ModelPricing(0.00125, 0.01, 300000, 150000),
        # ... existing models ...
    },
}
```

**Provider name mapping**:
- `"OpenAI"` (not "openai")
- `"Anthropic"` (not "claude")
- `"Google"` (not "gemini")
- `"xAI"` (not "grok")

### Step 3: Update Capabilities (if new features)

If the model introduces new capabilities:

```python
supported_capabilities={
    "web_search",
    "code_execution",
    "new_capability",  # Add here
}
```

### Step 4: Update Default Model (if appropriate)

Only change if the new model should be the recommended default:

```python
default_model="new-model-name"
```

### Step 5: Validate and Test

```bash
# Run capabilities tests
uv run pytest massgen/tests/test_backend_capabilities.py -v

# Test config generation with new model
massgen --generate-config ./test.yaml --config-backend openai --config-model new-model-name

# Verify the config was created successfully
cat ./test.yaml
```

### Step 6: Regenerate Documentation

```bash
uv run python docs/scripts/generate_backend_tables.py
cd docs && make html
```

## Current Model Data

### OpenAI Models (as of Nov 2025)

In capabilities.py:
```python
models=[
    "gpt-5.1",        # 2025-11
    "gpt-5-codex",    # 2025-09
    "gpt-5",          # 2025-08
    "gpt-5-mini",     # 2025-08
    "gpt-5-nano",     # 2025-08
    "gpt-4.1",        # 2025-04
    "gpt-4.1-mini",   # 2025-04
    "gpt-4.1-nano",   # 2025-04
    "gpt-4o",         # 2024-05
    "gpt-4o-mini",    # 2024-07
    "o4-mini",        # 2025-04
]
```

In token_manager.py (add missing models):
```python
"OpenAI": {
    "gpt-5": ModelPricing(0.00125, 0.01, 400000, 128000),
    "gpt-5-mini": ModelPricing(0.00025, 0.002, 400000, 128000),
    "gpt-5-nano": ModelPricing(0.00005, 0.0004, 400000, 128000),
    "gpt-4o": ModelPricing(0.0025, 0.01, 128000, 16384),
    "gpt-4o-mini": ModelPricing(0.00015, 0.0006, 128000, 16384),
    # Missing: gpt-5.1, gpt-5-codex, gpt-4.1 family, o4-mini
}
```

### Claude Models (as of Nov 2025)

In capabilities.py:
```python
models=[
    "claude-haiku-4-5-20251001",    # 2025-10
    "claude-sonnet-4-5-20250929",   # 2025-09
    "claude-opus-4-1-20250805",     # 2025-08
    "claude-sonnet-4-20250514",     # 2025-05
]
```

In token_manager.py:
```python
"Anthropic": {
    "claude-haiku-4-5": ModelPricing(0.001, 0.005, 200000, 65536),
    "claude-sonnet-4-5": ModelPricing(0.003, 0.015, 200000, 65536),
    "claude-opus-4.1": ModelPricing(0.015, 0.075, 200000, 32768),
    "claude-sonnet-4": ModelPricing(0.003, 0.015, 200000, 8192),
}
```

### Gemini Models (as of Nov 2025)

In capabilities.py:
```python
models=[
    "gemini-3-pro-preview",  # 2025-11
    "gemini-2.5-flash",      # 2025-06
    "gemini-2.5-pro",        # 2025-06
]
```

In token_manager.py (missing gemini-2.5 and gemini-3):
```python
"Google": {
    "gemini-1.5-pro": ModelPricing(0.00125, 0.005, 2097152, 8192),
    "gemini-1.5-flash": ModelPricing(0.000075, 0.0003, 1048576, 8192),
    # Missing: gemini-2.5-pro, gemini-2.5-flash, gemini-3-pro-preview
}
```

### Grok Models (as of Nov 2025)

In capabilities.py:
```python
models=[
    "grok-4-1-fast-reasoning",      # 2025-11
    "grok-4-1-fast-non-reasoning",  # 2025-11
    "grok-code-fast-1",             # 2025-08
    "grok-4",                       # 2025-07
    "grok-4-fast",                  # 2025-09
    "grok-3",                       # 2025-02
    "grok-3-mini",                  # 2025-05
]
```

In token_manager.py (missing grok-3, grok-4 families):
```python
"xAI": {
    "grok-2-latest": ModelPricing(0.005, 0.015, 131072, 131072),
    "grok-2": ModelPricing(0.005, 0.015, 131072, 131072),
    "grok-2-mini": ModelPricing(0.001, 0.003, 131072, 65536),
    # Missing: grok-3, grok-4, grok-4-1 families
}
```

## Model Name Matching

**Important:** The names in `PROVIDER_PRICING` use simplified patterns:

- `"gpt-5"` matches `gpt-5`, `gpt-5-preview`, `gpt-5-*`
- `"claude-sonnet-4-5"` matches `claude-sonnet-4-5-*` (any date suffix)
- `"gemini-2.5-pro"` is exact match

The token manager uses prefix matching for flexibility.

## Common Tasks

### Task: Add brand new GPT-5.2 model

1. Research: Release date, pricing, context window, capabilities
2. Add to `capabilities.py` models list and release_dates
3. Add to `token_manager.py` PROVIDER_PRICING["OpenAI"]
4. Run tests
5. Regenerate docs

### Task: Update pricing for existing model

1. Verify new pricing from official source
2. Update only `token_manager.py` PROVIDER_PRICING
3. No need to touch capabilities.py
4. Document change in notes if significant

### Task: Add new capability to model

1. Update `supported_capabilities` in capabilities.py
2. Add to `notes` explaining when/how capability works
3. Update backend implementation if needed
4. Run tests

## Validation Commands

```bash
# Test capabilities registry
uv run pytest massgen/tests/test_backend_capabilities.py -v

# Test token manager
uv run pytest massgen/tests/test_token_manager.py -v

# Generate config with new model
massgen --generate-config ./test.yaml --config-backend openai --config-model new-model

# Build docs to verify tables
cd docs && make html
```

## Programmatic Model Updates

### LiteLLM Pricing Database (RECOMMENDED)

The easiest way to get comprehensive model pricing and context window data:

**URL**: https://raw.githubusercontent.com/BerriAI/litellm/main/model_prices_and_context_window.json

**Coverage**: 500+ models across 30+ providers including:
- OpenAI, Anthropic, Google, xAI
- Together AI, Groq, Cerebras, Fireworks
- AWS Bedrock, Azure, Cohere, and more

**Data Available**:
```json
{
  "gpt-4o": {
    "input_cost_per_token": 0.0000025,
    "output_cost_per_token": 0.00001,
    "max_input_tokens": 128000,
    "max_output_tokens": 16384,
    "supports_vision": true,
    "supports_function_calling": true,
    "supports_prompt_caching": true
  }
}
```

**Usage**:
```python
import requests

# Fetch latest pricing
url = "https://raw.githubusercontent.com/BerriAI/litellm/main/model_prices_and_context_window.json"
pricing_db = requests.get(url).json()

# Get info for a model
model_info = pricing_db.get("gpt-4o")
input_per_1k = model_info["input_cost_per_token"] * 1000
output_per_1k = model_info["output_cost_per_token"] * 1000
```

**Update token_manager.py from LiteLLM**:
- Convert per-token costs to per-1K costs
- Extract context window and max output tokens
- Keep models in reverse chronological order

### OpenRouter API (Real-Time)

For the most up-to-date model list with live pricing:

**Endpoint**: `https://openrouter.ai/api/v1/models`

**Data Available**:
- Real-time pricing (prompt, completion, reasoning, caching)
- Context windows and max completion tokens
- Model capabilities and modalities
- 200+ models from multiple providers

**Usage**:
```python
import requests
import os

headers = {"Authorization": f"Bearer {os.environ['OPENROUTER_API_KEY']}"}
response = requests.get("https://openrouter.ai/api/v1/models", headers=headers)
models = response.json()["data"]

for model in models:
    print(f"{model['id']}: ${model['pricing']['prompt']} input, ${model['pricing']['completion']} output")
```

### Provider-Specific APIs

| Provider | Models API | Pricing in API? | Recommendation |
|----------|------------|-----------------|----------------|
| OpenAI | `https://api.openai.com/v1/models` | ❌ No | Use LiteLLM |
| Claude | No public API | ❌ No | Use LiteLLM |
| Gemini | `https://generativelanguage.googleapis.com/v1beta/models` | ❌ No | API + LiteLLM |
| Grok (xAI) | `https://api.x.ai/v1/models` | ❌ No | Use LiteLLM |
| Together AI | `https://api.together.xyz/v1/models` | ✅ Yes | API directly |
| Groq | `https://api.groq.com/openai/v1/models` | ❌ No | Use LiteLLM |
| Cerebras | `https://api.cerebras.ai/v1/models` | ❌ No | Use LiteLLM |
| Fireworks | `https://api.fireworks.ai/v1/accounts/{id}/models` | ❌ No | Use LiteLLM |
| Azure OpenAI | Azure Management API | ❌ Complex | Manual |
| Claude Code | No API | ❌ No | Manual |

## Automation Script

Create `scripts/update_model_pricing.py` to automate updates:

```python
#!/usr/bin/env python3
"""Update token_manager.py pricing from LiteLLM database."""

import requests

# Fetch LiteLLM database
url = "https://raw.githubusercontent.com/BerriAI/litellm/main/model_prices_and_context_window.json"
pricing_db = requests.get(url).json()

# Filter by provider
openai_models = {k: v for k, v in pricing_db.items()
                 if v.get("litellm_provider") == "openai"}
anthropic_models = {k: v for k, v in pricing_db.items()
                    if v.get("litellm_provider") == "anthropic"}

# Generate ModelPricing entries
for model_name, info in openai_models.items():
    input_per_1k = info["input_cost_per_token"] * 1000
    output_per_1k = info["output_cost_per_token"] * 1000
    context = info.get("max_input_tokens", 0)
    max_output = info.get("max_output_tokens", 0)

    print(f'    "{model_name}": ModelPricing({input_per_1k}, {output_per_1k}, {context}, {max_output}),')
```

Run weekly to keep pricing current:
```bash
uv run python scripts/update_model_pricing.py
```

## Reference Files

- **Capabilities registry**: `massgen/backend/capabilities.py`
- **Token/pricing manager**: `massgen/token_manager/token_manager.py`
- **Capabilities tests**: `massgen/tests/test_backend_capabilities.py`
- **Config builder**: `massgen/config_builder.py`
- **Doc generator**: `docs/scripts/generate_backend_tables.py`
- **LiteLLM database**: https://raw.githubusercontent.com/BerriAI/litellm/main/model_prices_and_context_window.json
- **OpenRouter API**: https://openrouter.ai/docs/overview/models

## Important Maintenance Notes

- **Keep models in reverse chronological order** - Newest first
- **Use exact API names** - Match provider documentation exactly
- **Verify pricing units** - Always per 1K tokens in token_manager.py
- **Document uncertainties** - If info is estimated/unofficial, note it
- **Update both files** - Don't forget token_manager.py when adding models
- **Use LiteLLM for pricing** - Comprehensive and frequently updated
- **Test after updates** - Run pytest to verify no breaking changes
