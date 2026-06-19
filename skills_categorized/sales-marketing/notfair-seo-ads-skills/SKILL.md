---
name: notfair-seo-ads-skills
description: Open-source Claude Code skills for SEO, GEO, Google Ads, and Meta Ads — connecting to live account data via Google Ads MCP, Meta Ads MCP, Google Search Console MCP, and Google Analytics (GA4) MCP.
---

# NotFair SEO & Ads Skills

NotFair is a collection of open-source Claude Code skills for marketing work across SEO, GEO optimization, Google Ads, and Meta Ads. Each skill connects to live data through MCP servers so Claude can read real account metrics and take action — not just generate templates.

## When to Use This Skill

- Running an SEO audit or keyword research session in Claude Code
- Analyzing Google Ads wasted spend, search terms, or bid performance
- Reviewing Meta (Facebook + Instagram) Ads ROAS, creative fatigue, or audience overlap
- Optimizing meta tags, schema markup, and GEO signals for AI-driven search
- Writing and planning content with live Search Console data

## What This Skill Does

1. **SEO**: Site analysis, keyword research, meta tags, schema markup, GEO optimization, and content writing via Google Search Console MCP and Google Analytics (GA4) MCP.
2. **Google Ads**: Account audits, wasted-spend detection, search-term cleanup, keyword and bid management via Google Ads MCP.
3. **Meta Ads**: ROAS analysis, creative fatigue detection, and audience overlap review via Meta Ads MCP.

## How to Use

### Basic Usage

```
/seo-audit — run a full SEO audit on my site using Search Console data
```

```
/google-ads-audit — find wasted spend and quick wins in my Google Ads account
```

```
/meta-ads-audit — review ROAS and flag fatigued creatives in my Meta account
```

### Advanced Usage

```
/keyword-research [topic] — research keywords with live Search Console volume data
/schema-markup-generator — generate and validate structured data for my pages
/geo-optimizer — optimize content for AI-driven (GEO) search signals
```

## Example

**User**: "Run the google-ads-audit skill and tell me where I'm wasting spend."

**Output**:
```
Connecting to Google Ads MCP...
Analyzing last 30 days of search terms and campaign spend...
Found 14 non-converting search terms spending $420/month — flagging for negatives.
Top 3 quick wins: [campaign list with projected savings]
```

**Inspired by:** nowork-studio/NotFair — open-source marketing skills for Claude Code.

## Tips

- All skills work best when the relevant MCP server is connected (Google Ads MCP, Meta Ads MCP, Google Search Console MCP, Google Analytics (GA4) MCP).
- Skills can be used individually — you do not need all MCPs connected at once.
- The SEO and GEO skills work without Ads MCPs if you only need organic optimization.

## Common Use Cases

- Weekly Google Ads performance review with automated wasted-spend detection
- Monthly Meta Ads creative refresh based on fatigue signals
- SEO content calendar built from live keyword gap analysis
- Schema markup audit across an entire site with one command

## Source

GitHub: [https://github.com/nowork-studio/NotFair](https://github.com/nowork-studio/NotFair) (~2.9k stars, MIT license)
- [seo/](https://github.com/nowork-studio/NotFair/tree/main/seo)
- [google-ads/](https://github.com/nowork-studio/NotFair/tree/main/google-ads)
- [meta-ads/](https://github.com/nowork-studio/NotFair/tree/main/meta-ads)
