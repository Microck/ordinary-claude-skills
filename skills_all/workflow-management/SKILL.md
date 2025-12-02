---
name: workflow-management
description: Create, debug, or modify QStash workflows for data updates and social media posting in the API service. Use when adding new automated jobs, fixing workflow errors, or updating scheduling logic.
allowed-tools: Read, Edit, Write, Bash, Grep, Glob
---

# Workflow Management Skill

This skill helps you work with QStash-based workflows in `apps/api/src/lib/workflows/`.

## When to Use This Skill

- Adding new scheduled workflows for data fetching
- Debugging workflow execution errors
- Modifying existing workflow schedules or logic
- Integrating new data sources into the update pipeline
- Adding new social media posting workflows

## Workflow Architecture

The project uses QStash workflows with the following structure:

```
apps/api/src/lib/workflows/
├── cars/                 # Car registration data workflows
│   └── update.ts        # Scheduled car data updates
├── coe/                 # COE bidding data workflows
│   └── update.ts        # Scheduled COE data updates
└── social/              # Social media posting workflows
    ├── discord.ts
    ├── linkedin.ts
    ├── telegram.ts
    └── twitter.ts
```

## Key Patterns

### 1. Workflow Definition

Workflows are defined using QStash SDK:

```typescript
import { serve } from "@upstash/workflow";

export const POST = serve(async (context) => {
  // Step 1: Fetch data
  await context.run("fetch-data", async () => {
    // Fetching logic
  });

  // Step 2: Process data
  const processed = await context.run("process-data", async () => {
    // Processing logic
  });

  // Step 3: Store results
  await context.run("store-results", async () => {
    // Storage logic
  });
});
```

### 2. Scheduling Workflows

Workflows are triggered via cron schedules configured in:
- SST infrastructure (`infra/`)
- QStash console
- Manual API calls to workflow endpoints

### 3. Error Handling

Always include comprehensive error handling:

```typescript
await context.run("step-name", async () => {
  try {
    // Logic here
  } catch (error) {
    console.error("Step failed:", error);
    // Log to monitoring service
    throw error; // Re-throw for workflow retry
  }
});
```

## Common Tasks

### Adding a New Workflow

1. Create workflow file in appropriate directory
2. Define workflow steps using `context.run()`
3. Add route handler in `apps/api/src/routes/`
4. Configure scheduling (if needed)
5. Add tests for workflow logic

### Debugging Workflow Failures

1. Check QStash dashboard for execution logs
2. Review CloudWatch logs for Lambda errors
3. Verify environment variables are set correctly
4. Test workflow locally using development server
5. Check database connectivity and Redis availability

### Modifying Existing Workflows

1. Read existing workflow implementation
2. Identify which step needs modification
3. Update step logic while maintaining error handling
4. Test changes locally
5. Deploy and monitor execution

## Environment Variables

Workflows typically need:
- `DATABASE_URL` - PostgreSQL connection
- `UPSTASH_REDIS_REST_URL` / `UPSTASH_REDIS_REST_TOKEN` - Redis
- `QSTASH_TOKEN` - QStash authentication
- Service-specific tokens (Discord webhook, Twitter API, etc.)

## Testing Workflows

Run workflow tests:
```bash
pnpm -F @sgcarstrends/api test -- src/lib/workflows
```

Test individual workflow locally:
```bash
# Start dev server
pnpm dev

# Trigger workflow via HTTP
curl -X POST http://localhost:3000/api/workflows/cars/update
```

## References

- QStash Workflows: Check Context7 for Upstash QStash documentation
- Related files:
  - `apps/api/src/routes/workflows.ts` - Workflow route handlers
  - `apps/api/src/config/qstash.ts` - QStash configuration
  - `apps/api/CLAUDE.md` - API service documentation

## Best Practices

1. **Idempotency**: Ensure workflows can safely retry without duplicating data
2. **Step Granularity**: Break workflows into small, focused steps
3. **Logging**: Add comprehensive logging for debugging
4. **Timeouts**: Configure appropriate timeouts for long-running operations
5. **Testing**: Write unit tests for workflow logic
6. **Monitoring**: Track workflow execution metrics
