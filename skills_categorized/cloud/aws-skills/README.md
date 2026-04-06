# AWS Skills for Claude Code

Claude Code plugins for AWS development with specialized knowledge and MCP server integrations.

## Plugins

### 1. AWS CDK Plugin

AWS CDK development skill with integrated MCP servers for infrastructure as code.

**Features**:
- AWS CDK best practices and patterns
- Pre-deployment validation script
- Comprehensive CDK patterns reference

**Integrated MCP Servers**:
- AWS Documentation MCP (HTTP)
- AWS CDK MCP (stdio)

### 2. AWS Cost & Operations Plugin

Cost optimization, monitoring, and operational excellence with 3 integrated MCP servers.

**Features**:
- Cost estimation and optimization
- Monitoring and observability patterns
- Operational best practices

**Integrated MCP Servers**:
- AWS Pricing
- AWS Cost Explorer
- Amazon CloudWatch

### 3. AWS Serverless & Event-Driven Architecture Plugin

Serverless and event-driven architecture patterns based on Well-Architected Framework with 2 integrated MCP servers.

**Features**:
- Well-Architected serverless design principles
- Event-driven architecture patterns
- Orchestration with Step Functions
- Saga patterns for distributed transactions
- Event sourcing patterns

**Integrated MCP Servers**:
- AWS Documentation MCP (HTTP)
- AWS Serverless MCP (SAM CLI)

## Installation

Add the marketplace to Claude Code:

```bash
/plugin marketplace add zxkane/aws-skills
```

Install plugins individually:

```bash
/plugin install aws-cdk@aws-skills
/plugin install aws-cost-ops@aws-skills
/plugin install serverless-eda@aws-skills
```

## Core CDK Principles

### Resource Naming

**Do NOT explicitly specify resource names** when they are optional in CDK constructs.

```typescript
// ✅ GOOD - Let CDK generate unique names
new lambda.Function(this, 'MyFunction', {
  // No functionName specified
});

// ❌ BAD - Prevents multiple deployments
new lambda.Function(this, 'MyFunction', {
  functionName: 'my-lambda',
});
```

### Lambda Functions

Use appropriate constructs for automatic bundling:

- **TypeScript/JavaScript**: `NodejsFunction` from `aws-cdk-lib/aws-lambda-nodejs`
- **Python**: `PythonFunction` from `@aws-cdk/aws-lambda-python-alpha`

### Pre-Deployment Validation

Before committing CDK code:

```bash
npm run build
npm test
npm run lint
cdk synth
./scripts/validate-stack.sh
```

## Usage Examples

### CDK Development

Ask Claude to help with CDK:

```
Create a CDK stack with a Lambda function that processes S3 events
```

Claude will:
- Follow CDK best practices
- Use NodejsFunction for automatic bundling
- Avoid explicit resource naming
- Grant proper IAM permissions
- Use MCP servers for latest AWS information

### Cost Optimization

Estimate costs before deployment:

```
Estimate the monthly cost of running 10 Lambda functions with 1M invocations each
```

Analyze current spending:

```
Show me my AWS costs for the last 30 days broken down by service
```

### Monitoring and Observability

Set up monitoring:

```
Create CloudWatch alarms for my Lambda functions to alert on errors and high duration
```

Investigate issues:

```
Show me CloudWatch logs for my API Gateway errors in the last hour
```

### Security and Audit

Audit activity:

```
Show me all IAM changes made in the last 7 days
```

Assess security:

```
Run a Well-Architected security assessment on my infrastructure
```

### Serverless Development

Build serverless applications:

```
Create a serverless API with Lambda and API Gateway for user management
```

Implement event-driven workflow:

```
Create an event-driven order processing system with EventBridge and Step Functions
```

Orchestrate complex workflows:

```
Implement a saga pattern for booking flights, hotels, and car rentals with compensation logic
```

## Structure

```
.
├── .claude-plugin/
│   └── marketplace.json              # Plugin marketplace configuration
├── skills/
│   ├── aws-cdk-development/          # CDK development skill
│   │   ├── SKILL.md
│   │   ├── references/
│   │   │   └── cdk-patterns.md
│   │   └── scripts/
│   │       └── validate-stack.sh
│   ├── aws-cost-operations/          # Cost & operations skill
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── operations-patterns.md
│   │       └── cloudwatch-alarms.md
│   └── aws-serverless-eda/           # Serverless & EDA skill
│       ├── SKILL.md
│       └── references/
│           ├── serverless-patterns.md
│           └── eda-patterns.md
└── README.md
```

## MCP Server Names

MCP server names use short identifiers to comply with Bedrock's 64-character tool name limit. The naming pattern is: `mcp__plugin_{plugin}_{server}__{tool}`

Examples: `awsdocs` (AWS docs), `cdk` (CDK), `cw` (CloudWatch), `sfn` (Step Functions), `sam` (Serverless), etc.

## Resources

- [Claude Agent Skills](https://docs.claude.com/en/docs/claude-code/skills)
- [AWS MCP Servers](https://awslabs.github.io/mcp/)
- [AWS CDK](https://aws.amazon.com/cdk/)
- [MCP Protocol](https://modelcontextprotocol.io/)

## License

MIT License - see [LICENSE](LICENSE)
