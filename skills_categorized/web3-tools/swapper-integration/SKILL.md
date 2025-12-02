---
name: swapper-integration
description: Integrate new DEX aggregators, swappers, or bridge protocols (like Bebop, Portals, Jupiter, 0x, 1inch, etc.) into ShapeShift Web. Activates when user wants to add, integrate, or implement support for a new swapper. Guides through research, implementation, and testing following established patterns.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash(yarn test:*), Bash(yarn lint:*), Bash(yarn type-check), Bash(yarn build:*)
---

# Swapper Integration Skill

You are helping integrate a new DEX aggregator, swapper, or bridge into ShapeShift Web. This skill guides you through the complete process from research to testing.

## When This Skill Activates

Use this skill when the user wants to:
- "Integrate [SwapperName] swapper"
- "Add support for [Protocol]"
- "Implement [DEX] integration"
- "Add [Aggregator] as a swapper"

## Overview

ShapeShift Web supports multiple swap aggregators through a unified swapper interface located in `packages/swapper/src/swappers/`. Each swapper follows consistent patterns, but has variations based on its type (EVM, Solana, cross-chain, gasless, etc.).

**Your task**: Research existing swappers to understand patterns, then adapt them for the new integration.

## Workflow

### Phase 1: Information Gathering

Before starting implementation, collect ALL required information from the user.

**Use the `AskUserQuestion` tool to interactively gather this information with structured prompts.**

**Ask the user for:**

1. **API Documentation**
   - Link to official API documentation (main docs)
   - Link to Swagger/OpenAPI specification (separate link, if available)
   - API base URL
   - Authentication method (API key? signature? none?)
   - **If API key needed**: Obtain production API key to add to `.env.base`
   - Rate limiting details

2. **Supported Networks**
   - Which blockchains (Ethereum, Polygon, Arbitrum, Solana, etc.)?
   - Any network-specific limitations?
   - Chain naming convention (e.g., "ethereum" vs "1" vs "mainnet")

3. **API Behavior**
   - **CRITICAL**: How does slippage work? (percentage like 1=1%? decimal like 0.01=1%? basis points like 100=1%?)
   - Does it require checksummed addresses?
   - How are native tokens handled? (special marker address? omit field?)
   - Minimum/maximum trade amounts?
   - Quote expiration time?

4. **Brand Assets**
   - Official swapper name (exact capitalization)
   - Logo/icon file or link (PNG preferred, 128x128 or larger)
   - Brand colors (optional)

5. **Reference Materials** (helpful but optional)
   - Example integrations on GitHub
   - Sample curl requests + responses from their dApp
   - Known quirks or gotchas
   - Community/support contact

**Action**: Stop and gather this information before proceeding. Missing details cause bugs later.

---

### Phase 2: Research & Understanding

**IMPORTANT**: Don't guess at implementation details. Research thoroughly before coding.

#### Step 0: Study the API Documentation

**Before looking at code**, understand the swapper's API:

1. **Read the official docs** (link from Phase 1)
   - How does the API work?
   - What endpoints are available?
   - What's the request/response format?
   - Any special requirements or quirks?

2. **Study the Swagger/OpenAPI spec** (if available)
   - Exact request parameters
   - Response schema
   - Error formats
   - Example requests/responses

3. **Key things to verify**:
   - How is slippage formatted in requests?
   - Are addresses checksummed in examples?
   - How are native tokens represented?
   - What does a successful quote response look like?
   - What error responses can occur?

**Try making a test curl request** if possible to see real responses.

#### Step 1: Explore Existing Swappers

Now that you understand the API, see how existing swappers work:

#### Step 1: Explore the swappers directory

```bash
# List all existing swappers
ls packages/swapper/src/swappers/
```

You'll see swappers like:
- BebopSwapper
- ZrxSwapper
- CowSwapper
- PortalsSwapper
- JupiterSwapper
- ThorchainSwapper
- And others...

#### Step 2: Identify similar swappers

Based on what you gathered in Phase 1, determine which swapper type yours is:

**EVM Single-Hop** (most common):
- Same-chain swaps only
- Standard transaction signing
- Examples: BebopSwapper, ZrxSwapper, PortalsSwapper

**Gasless / Order-Based**:
- Sign message instead of transaction
- No gas fees
- Examples: CowSwapper

**Solana-Only**:
- Solana ecosystem
- Different execution model
- Examples: JupiterSwapper

**Cross-Chain / Multi-Hop**:
- Bridge or cross-chain swaps
- May have multiple steps
- Examples: ThorchainSwapper, ChainflipSwapper

**Bridge-Specific**:
- Focus on bridging, not swapping
- Examples: ArbitrumBridgeSwapper, RelaySwapper

#### Step 3: Study similar swappers

Pick 2-3 similar swappers and read their implementations:

```
# Example: If building an EVM aggregator, study these:
@packages/swapper/src/swappers/BebopSwapper/BebopSwapper.ts
@packages/swapper/src/swappers/BebopSwapper/endpoints.ts
@packages/swapper/src/swappers/BebopSwapper/types.ts
@packages/swapper/src/swappers/BebopSwapper/INTEGRATION.md

@packages/swapper/src/swappers/ZrxSwapper/ZrxSwapper.ts
@packages/swapper/src/swappers/PortalsSwapper/PortalsSwapper.ts
```

**Pay attention to:**
- File structure
- How they call their APIs
- How they handle errors
- How they calculate rates and fees
- Special handling (checksumming, hex conversion, etc.)

#### Step 4: Read supporting documentation

Consult the skill's reference materials:
- `@reference.md` - General swapper architecture and patterns
- `@common-gotchas.md` - Critical bugs to avoid
- `@examples.md` - Code templates

---

### Phase 3: Implementation

Follow the pattern established by similar swappers. Don't reinvent the wheel.

#### Step 1: Create directory structure

Create `packages/swapper/src/swappers/[SwapperName]Swapper/`

**For most EVM swappers**, create:
```
[SwapperName]Swapper/
├── index.ts
├── [SwapperName]Swapper.ts
├── endpoints.ts
├── types.ts
├── get[SwapperName]TradeQuote/
│   └── get[SwapperName]TradeQuote.ts
├── get[SwapperName]TradeRate/
│   └── get[SwapperName]TradeRate.ts
└── utils/
    ├── constants.ts
    ├── [swapperName]Service.ts
    ├── fetchFrom[SwapperName].ts
    └── helpers/
        └── helpers.ts
```

**Check** `@examples.md` for structure templates.

#### Step 2: Implement core files

**Order** (follow this sequence):

1. **`types.ts`**: Define TypeScript interfaces based on API responses
2. **`utils/constants.ts`**: Supported chains, default slippage, native token markers
3. **`utils/helpers/helpers.ts`**: Helper functions (validation, rate calculation)
4. **`utils/[swapperName]Service.ts`**: HTTP service wrapper
5. **`utils/fetchFrom[SwapperName].ts`**: API fetch functions
6. **`get[SwapperName]TradeQuote.ts`**: Quote logic
7. **`get[SwapperName]TradeRate.ts`**: Rate logic
8. **`endpoints.ts`**: Wire up SwapperApi interface
9. **`[SwapperName]Swapper.ts`**: Main swapper class
10. **`index.ts`**: Exports

**Refer to** `@examples.md` for code templates. **Copy patterns** from similar existing swappers.

#### Step 3: Add Swapper-Specific Metadata (ONLY if needed)

**When is metadata needed?**
- Deposit-to-address swappers (Chainflip, NEAR Intents) - need deposit address, swap ID for status polling
- Order-based swappers (CowSwap) - need order ID for status tracking
- Any swapper that requires tracking state between quote → execution → status polling

**When is metadata NOT needed?**
- Direct transaction swappers (Bebop, 0x, Portals) - transaction is built from quote, no async tracking needed
- Same-chain aggregators where transaction hash is sufficient for status tracking
- Most EVM-only swappers that return transaction data directly

**If your swapper doesn't need async status polling or deposit addresses, skip this step!**

**Three places to add metadata:**

**a. Define types** (`packages/swapper/src/types.ts`):

Add to `TradeQuoteStep` type:
```typescript
export type TradeQuoteStep = {
  // ... existing fields
  [swapperName]Specific?: {
    depositAddress: string
    swapId: number
    // ... other swapper-specific fields
  }
}
```

Add to `SwapperSpecificMetadata` type (for swap storage):
```typescript
export type SwapperSpecificMetadata = {
  chainflipSwapId: number | undefined
  nearIntentsSpecific?: {
    depositAddress: string
    depositMemo?: string
    timeEstimate: number
    deadline: string
  }
  // Add your swapper's metadata here
  [swapperName]Specific?: {
    // ... fields needed for status polling
  }
  // ... other fields
}
```

**b. Populate in quote** (`packages/swapper/src/swappers/[Swapper]/swapperApi/getTradeQuote.ts`):

Store metadata in the TradeQuoteStep:
```typescript
const tradeQuote: TradeQuote = {
  // ... other fields
  steps: [{
    // ... step fields
    [swapperName]Specific: {
      depositAddress: response.depositAddress,
      swapId: response.id,
      // ... other data needed later
    }
  }]
}
```

**c. Extract into swap** (TWO places required!):

**Place 1**: `src/components/MultiHopTrade/components/TradeConfirm/hooks/useTradeButtonProps.tsx`

Add to metadata object around line 114-126:
```typescript
metadata: {
  chainflipSwapId: firstStep?.chainflipSpecific?.chainflipSwapId,
  nearIntentsSpecific: firstStep?.nearIntentsSpecific,
  // Add your swapper's metadata extraction here:
  [swapperName]Specific: firstStep?.[swapperName]Specific,
  relayTransactionMetadata: firstStep?.relayTransactionMetadata,
  stepIndex: currentHopIndex,
  quoteId: activeQuote.id,
  streamingSwapMetadata: { ... }
}
```

**Place 2**: `src/lib/tradeExecution.ts` (CRITICAL - often forgotten!)

Add to metadata object around line 156-161:
```typescript
metadata: {
  ...swap.metadata,
  chainflipSwapId: tradeQuote.steps[0]?.chainflipSpecific?.chainflipSwapId,
  nearIntentsSpecific: tradeQuote.steps[0]?.nearIntentsSpecific,
  // Add your swapper's metadata extraction here:
  [swapperName]Specific: tradeQuote.steps[0]?.[swapperName]Specific,
  relayTransactionMetadata: tradeQuote.steps[0]?.relayTransactionMetadata,
  stepIndex,
}
```

**Why both places?**
- `useTradeButtonProps` creates the initial swap (before wallet signature)
- `tradeExecution` updates the swap during execution (after wallet signature, with actual tradeQuote)
- If you only add to one place, metadata will be missing!

**d. Access in status check** (`packages/swapper/src/swappers/[Swapper]/endpoints.ts`):

```typescript
checkTradeStatus: async ({ config, swap }) => {
  const { [swapperName]Specific } = swap?.metadata ?? {}

  if (![swapperName]Specific?.swapId) {
    throw new Error('swapId is required for status check')
  }

  // Use metadata to poll API
  const status = await api.getStatus([swapperName]Specific.swapId)
  // ...
}
```

**Example: NEAR Intents metadata flow**
```
1. Quote: Store in step.nearIntentsSpecific.depositAddress
2. Swap creation: Extract to swap.metadata.nearIntentsSpecific
3. Status check: Read from swap.metadata.nearIntentsSpecific.depositAddress
```

#### Step 4: Register the swapper

Update these files to register your new swapper:

1. **`packages/swapper/src/constants.ts`**
   - Add to `SwapperName` enum
   - Add to `swappers` record
   - Add default slippage

2. **`packages/swapper/src/index.ts`**
   - Export new swapper

3. **`packages/swapper/src/types.ts`**
   - Add API config fields (if not already done in metadata step)

4. **CSP Headers** (if swapper calls external API):
   - Create `headers/csps/defi/swappers/[SwapperName].ts`:
     ```typescript
     import type { Csp } from '../../../types'

     export const csp: Csp = {
       'connect-src': ['https://api.[swapper].com'],
     }
     ```
   - Register in `headers/csps/index.ts`:
     ```typescript
     import { csp as [swapperName] } from './defi/swappers/[SwapperName]'

     export const csps = [
       // ... other csps
       [swapperName],
     ]
     ```

5. **UI Integration** (`src/`):

   **a. Add swapper icon:**
   - Place icon file at: `src/components/MultiHopTrade/components/TradeInput/components/SwapperIcon/[swapper]-icon.png`
   - Recommended: 128x128 PNG with transparent background

   **b. Update SwapperIcon component:**
   - File: `src/components/MultiHopTrade/components/TradeInput/components/SwapperIcon/SwapperIcon.tsx`
   - Import icon: `import [swapperName]Icon from './[swapper]-icon.png'`
   - Add case to switch statement:
     ```typescript
     case SwapperName.[SwapperName]:
       return <Image src={[swapperName]Icon} />
     ```

   **c. Add feature flag (REQUIRED):**
   - File: `src/state/slices/preferencesSlice/preferencesSlice.ts`
   - Add to `FeatureFlags` type:
     ```typescript
     export type FeatureFlags = {
       // ...
       [SwapperName]Swap: boolean
     }
     ```
   - Add to initial state:
     ```typescript
     const initialState: Preferences = {
       featureFlags: {
         // ...
         [SwapperName]Swap: getConfig().VITE_FEATURE_[SWAPPER]_SWAP,
       }
     }
     ```

   **d. Wire up feature flag:**
   - File: `src/state/helpers.ts`
   - Add to `isCrossAccountTradeSupported` function parameter and switch statement (if swapper supports cross-account)
   - Add to `getEnabledSwappers` function:
     ```typescript
     export const getEnabledSwappers = (
       {
         [SwapperName]Swap,  // Add to destructured parameters
         ...otherFlags
       }: FeatureFlags,
       ...
     ): Record<SwapperName, boolean> => {
       return {
         // ...
         [SwapperName.[SwapperName]]:
           [SwapperName]Swap && (!isCrossAccountTrade || isCrossAccountTradeSupported(SwapperName.[SwapperName])),
       }
     }
     ```

   **e. Update test mocks (REQUIRED):**
   - File: `src/test/mocks/store.ts`
   - Add feature flag to mock featureFlags object:
     ```typescript
     featureFlags: {
       // ... other flags
       [SwapperName]Swap: false,
     }
     ```

6. **Configuration**:

   **Environment variables** - Follow naming conventions (e.g., Bebop):

   **`.env`** (base/production - both API key and feature flag OFF):
   ```bash
   # Bebop
   VITE_BEBOP_API_KEY=
   VITE_FEATURE_BEBOP_SWAP=false
   ```

   **`.env.development`** (development - feature flag ON):
   ```bash
   # Bebop
   VITE_BEBOP_API_KEY=your-dev-api-key-here
   VITE_FEATURE_BEBOP_SWAP=true
   ```

   **Naming pattern**:
   - API key: `VITE_[SWAPPER]_API_KEY` (in both `.env` and `.env.development`)
   - Feature flag: `VITE_FEATURE_[SWAPPER]_SWAP` (`.env` = false, `.env.development` = true)
   - Other config: `VITE_[SWAPPER]_BASE_URL` (if needed, both files)
   - **Config file** (`src/config.ts`):
     ```typescript
     export const getConfig = (): Config => ({
       // ...
       VITE_[SWAPPER]_API_KEY: import.meta.env.VITE_[SWAPPER]_API_KEY || '',
       VITE_[SWAPPER]_BASE_URL: import.meta.env.VITE_[SWAPPER]_BASE_URL || '',
       VITE_FEATURE_[SWAPPER]_SWAP: parseBoolean(import.meta.env.VITE_FEATURE_[SWAPPER]_SWAP),
     })
     ```

#### Step 4: Check common gotchas

**Before testing**, review `@common-gotchas.md` to avoid known bugs:
- Slippage format issues
- Address checksumming
- Hex value conversion
- Response parsing errors
- Rate vs quote affiliate fee deltas

**Fix these proactively!**

---

### Phase 4: Testing & Validation

Run validation commands:

```bash
# Type checking
yarn type-check

# Linting
yarn lint

# Build
yarn build:swapper
```

**All must pass** before manual testing.

**Manual testing checklist**:
- [ ] Can fetch quotes successfully
- [ ] Rates display correctly
- [ ] Approval flow works (if needed)
- [ ] Transaction execution completes
- [ ] Error handling works (bad chain, insufficient liquidity, etc.)
- [ ] UI shows swapper correctly
- [ ] Feature flag toggles swapper on/off

See `@reference.md` for detailed testing strategies.

---

### Phase 5: Documentation

Create `packages/swapper/src/swappers/[SwapperName]Swapper/INTEGRATION.md`

Document:
1. API overview (URLs, auth, chains)
2. Key implementation details
3. Critical quirks or gotchas
4. Sample requests/responses
5. Testing notes

**Use BebopSwapper's INTEGRATION.md as a template.**

---

## Key Principles

1. **Research, don't guess**: Study existing swappers before coding
2. **Copy patterns**: Don't reinvent - adapt what works
3. **Read gotchas**: Avoid bugs others already fixed
4. **Test thoroughly**: Type check, lint, build, manual test
5. **Document quirks**: Help future maintainers

## Success Criteria

Integration is complete when:

✅ All validation commands pass (type-check, lint, build)
✅ Swapper appears in UI when feature flag is enabled
✅ Can successfully fetch quotes and execute trades
✅ Error cases handled gracefully
✅ Integration documentation written
✅ Code follows patterns from similar swappers

## Reference Files

- `@reference.md` - Swapper architecture and patterns
- `@examples.md` - Code templates
- `@common-gotchas.md` - Critical bugs to avoid

## Need Help?

If stuck:
1. Read similar swapper implementations
2. Check `@common-gotchas.md` for your specific issue
3. Grep for similar patterns in existing swappers
4. Ask user for clarification on API behavior
