---
name: crypto-research
description: Comprehensive cryptocurrency market research and analysis using specialized AI agents. Analyzes market data, price trends, news sentiment, technical indicators, macro correlations, and investment opportunities. Use when researching cryptocurrencies, analyzing crypto markets, evaluating digital assets, or investigating blockchain projects like Bitcoin, Ethereum, Solana, etc.
allowed-tools:
  - Task
  - Bash
  - Write
  - WebSearch
  - WebFetch
---

# Cryptocurrency Research Skill

This skill provides comprehensive cryptocurrency research by orchestrating multiple specialized AI agents that analyze different aspects of the crypto market in parallel.

## When to Use

Invoke this skill when the user:
- Mentions cryptocurrency analysis or research
- Names specific cryptocurrencies (BTC, ETH, SOL, etc.)
- Asks about crypto market conditions
- Wants investment analysis or opportunities
- Needs technical or fundamental analysis of crypto assets
- Requests macro correlation analysis
- Asks about crypto news or sentiment

## Capabilities

### Multi-Agent Research System
Coordinates 4-12 specialized agents running in parallel:
- **Market Agent**: Overall market conditions and trends
- **Coin Analyzer**: Deep dive on specific cryptocurrencies
- **Macro Correlation Scanner**: Relationships with traditional markets
- **Investment Plays Agent**: Opportunity identification
- **News Scanner**: Recent developments and sentiment
- **Price Check**: Real-time price and volume data
- **Movers Agent**: Biggest gainers and losers

### Research Modes

1. **Comprehensive Mode**: All agents (12 total) across 3 model types (haiku, sonnet, opus)
2. **Lightweight Mode**: Haiku agents only (4 agents) for quick analysis
3. **Output-Only Mode**: Silent execution with file output only

### Output Organization

Research results are saved in timestamped directories:
```
outputs/
└── YYYY-MM-DD_HH-MM-SS/
    ├── crypto_market/
    ├── crypto_analysis/
    ├── crypto_macro/
    ├── crypto_plays/
    └── crypto_news/
```

## How It Works

### 1. Mode Selection

Based on user request or context:
- **Quick question**: Use lightweight mode (4 haiku agents)
- **Comprehensive research**: Use full mode (12 agents)
- **Background analysis**: Use output-only mode

### 2. Agent Orchestration

1. Run `date` command to get timestamp
2. Create output directory structure using `scripts/setup-output-dir.sh`
3. Launch agents in parallel using Task tool
4. Each agent writes results to designated file
5. Present summary with file locations

### 3. Agent Coordination

Agents are defined in `agent-prompts/` directory:
- `coin-analyzer.md` - Receives ticker symbol parameter
- `market-agent.md` - General market analysis
- `macro-correlation-scanner.md` - Correlation analysis
- `investment-plays.md` - Investment opportunities
- `news-scanner.md` - News aggregation
- `price-check.md` - Current pricing data
- `movers.md` - Top movers analysis

Each agent prompt includes:
- Purpose and specialization
- Data gathering instructions (5+ tools)
- Output format requirements
- Timestamp and timezone handling

## Workflows

### Quick Research (Default)
See `workflows/lightweight.md` for implementation details.

**When**: User asks quick question about crypto
**Agents**: 4 haiku agents
**Duration**: ~30-60 seconds

### Comprehensive Research
See `workflows/comprehensive.md` for implementation details.

**When**: User needs deep analysis or multiple perspectives
**Agents**: 12 agents (haiku, sonnet, opus variations)
**Duration**: ~2-5 minutes

### Silent Research
See `workflows/output-only.md` for implementation details.

**When**: Background research or automated workflows
**Agents**: Configurable
**Output**: Files only, no interactive output

## Usage Examples

**Example 1: Specific Coin Analysis**
```
User: "What's happening with Bitcoin?"
Action: Launch lightweight mode with BTC as ticker
Agents: 4 haiku agents analyzing Bitcoin specifically
Output: Quick analysis in ~30 seconds
```

**Example 2: Market Overview**
```
User: "How are crypto markets doing today?"
Action: Launch market-focused agents
Agents: Market agent + movers + macro correlation
Output: Market overview with key movers
```

**Example 3: Investment Research**
```
User: "I'm looking for good crypto investment opportunities"
Action: Launch comprehensive mode
Agents: All 12 agents for multi-perspective analysis
Output: Comprehensive report with opportunities
```

## Agent Parameters

### TICKER Variable
Coin analyzer agents accept a ticker symbol:
- Default: "BTC" if not specified
- Examples: BTC, ETH, SOL, ADA, DOT, AVAX, etc.
- Used by: coin-analyzer agents (haiku, sonnet, opus)

### Model Selection
- **Haiku**: Fast, cost-effective, good for quick analysis
- **Sonnet**: Balanced, default for most research
- **Opus**: Deep analysis, best quality, slower and more expensive

## Error Handling

If agents fail or timeout:
1. Check agent output files for partial results
2. Retry failed agents individually
3. Report which agents completed successfully
4. Provide path to output directory for user inspection

## Best Practices

1. **Start with Lightweight**: Use haiku mode for initial questions
2. **Upgrade to Comprehensive**: When deeper analysis needed
3. **Specify Tickers**: Be explicit about which cryptocurrencies to analyze
4. **Check Timestamps**: Results include generation time for data freshness
5. **Review All Outputs**: Different agents may catch different insights

## Progressive Disclosure

For detailed information, see:
- `reference/agent-design.md` - How agents are structured
- `reference/usage-guide.md` - Detailed usage instructions
- `workflows/*.md` - Specific workflow implementations

## Version History

- v1.0.0 (2025-01): Initial skill creation from command refactoring
