# Serverless Deployment Best Practices

Deployment best practices for serverless applications including CI/CD, testing, and deployment strategies.

## Table of Contents

- [Software Release Process](#software-release-process)
- [Infrastructure as Code](#infrastructure-as-code)
- [CI/CD Pipeline Design](#cicd-pipeline-design)
- [Testing Strategies](#testing-strategies)
- [Deployment Strategies](#deployment-strategies)
- [Rollback and Safety](#rollback-and-safety)

## Software Release Process

### Four Stages of Release

**1. Source Phase**:
- Developers commit code changes
- Code review (peer review)
- Version control (Git)

**2. Build Phase**:
- Compile code
- Run unit tests
- Style checking and linting
- Create deployment packages
- Build container images

**3. Test Phase**:
- Integration tests with other systems
- Load testing
- UI testing
- Security testing (penetration testing)
- Acceptance testing

**4. Production Phase**:
- Deploy to production environment
- Monitor for errors
- Validate deployment success
- Rollback if needed

### CI/CD Maturity Levels

**Continuous Integration (CI)**:
- Automated build on code commit
- Automated unit testing
- Manual deployment to test/production

**Continuous Delivery (CD)**:
- Automated deployment to test environments
- Manual approval for production
- Automated testing in non-prod

**Continuous Deployment**:
- Fully automated pipeline
- Automated deployment to production
- No manual intervention after code commit

## Infrastructure as Code

### Framework Selection

**AWS SAM (Serverless Application Model)**:

```yaml
# template.yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31

Resources:
  OrderFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: app.handler
      Runtime: nodejs20.x
      CodeUri: src/
      Events:
        Api:
          Type: Api
          Properties:
            Path: /orders
            Method: post
```

**Benefits**:
- Simple, serverless-focused syntax
- Built-in best practices
- SAM CLI for local testing
- Integrates with CodeDeploy

**AWS CDK**:

```typescript
new NodejsFunction(this, 'OrderFunction', {
  entry: 'src/orders/handler.ts',
  environment: {
    TABLE_NAME: ordersTable.tableName,
  },
});

ordersTable.grantReadWriteData(orderFunction);
```

**Benefits**:
- Type-safe, programmatic
- Reusable constructs
- Rich AWS service support
- Better for complex infrastructure

**When to use**:
- **SAM**: Serverless-only applications, simpler projects
- **CDK**: Complex infrastructure, multiple services, reusable patterns

### Environment Management

**Separate environments**:

```typescript
// CDK App
const app = new cdk.App();

new ServerlessStack(app, 'DevStack', {
  env: { account: '111111111111', region: 'us-east-1' },
  environment: 'dev',
  logLevel: 'DEBUG',
});

new ServerlessStack(app, 'ProdStack', {
  env: { account: '222222222222', region: 'us-east-1' },
  environment: 'prod',
  logLevel: 'INFO',
});
```

**SAM with parameters**:

```yaml
Parameters:
  Environment:
    Type: String
    Default: dev
    AllowedValues:
      - dev
      - staging
      - prod

Resources:
  Function:
    Type: AWS::Serverless::Function
    Properties:
      Environment:
        Variables:
          ENVIRONMENT: !Ref Environment
          LOG_LEVEL: !If [IsProd, INFO, DEBUG]
```

## CI/CD Pipeline Design

### AWS CodePipeline

**Comprehensive pipeline**:

```typescript
import * as codepipeline from 'aws-cdk-lib/aws-codepipeline';
import * as codepipeline_actions from 'aws-cdk-lib/aws-codepipeline-actions';

const sourceOutput = new codepipeline.Artifact();
const buildOutput = new codepipeline.Artifact();

const pipeline = new codepipeline.Pipeline(this, 'Pipeline', {
  pipelineName: 'serverless-pipeline',
});

// Source stage
pipeline.addStage({
  stageName: 'Source',
  actions: [
    new codepipeline_actions.CodeStarConnectionsSourceAction({
      actionName: 'GitHub_Source',
      owner: 'myorg',
      repo: 'myrepo',
      branch: 'main',
      output: sourceOutput,
      connectionArn: githubConnection.connectionArn,
    }),
  ],
});

// Build stage
pipeline.addStage({
  stageName: 'Build',
  actions: [
    new codepipeline_actions.CodeBuildAction({
      actionName: 'Build',
      project: buildProject,
      input: sourceOutput,
      outputs: [buildOutput],
    }),
  ],
});

// Test stage
pipeline.addStage({
  stageName: 'Test',
  actions: [
    new codepipeline_actions.CloudFormationCreateUpdateStackAction({
      actionName: 'Deploy_Test',
      templatePath: buildOutput.atPath('packaged.yaml'),
      stackName: 'test-stack',
      adminPermissions: true,
    }),
    new codepipeline_actions.CodeBuildAction({
      actionName: 'Integration_Tests',
      project: testProject,
      input: buildOutput,
      runOrder: 2,
    }),
  ],
});

// Production stage (with manual approval)
pipeline.addStage({
  stageName: 'Production',
  actions: [
    new codepipeline_actions.ManualApprovalAction({
      actionName: 'Approve',
    }),
    new codepipeline_actions.CloudFormationCreateUpdateStackAction({
      actionName: 'Deploy_Prod',
      templatePath: buildOutput.atPath('packaged.yaml'),
      stackName: 'prod-stack',
      adminPermissions: true,
      runOrder: 2,
    }),
  ],
});
```

### GitHub Actions

**Serverless deployment workflow**:

```yaml
# .github/workflows/deploy.yml
name: Deploy Serverless Application

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test

      - name: Setup SAM CLI
        uses: aws-actions/setup-sam@v2

      - name: Build SAM application
        run: sam build

      - name: Deploy to Dev
        if: github.ref != 'refs/heads/main'
        run: |
          sam deploy \
            --no-confirm-changeset \
            --no-fail-on-empty-changeset \
            --stack-name dev-stack \
            --parameter-overrides Environment=dev

      - name: Run integration tests
        run: npm run test:integration

      - name: Deploy to Prod
        if: github.ref == 'refs/heads/main'
        run: |
          sam deploy \
            --no-confirm-changeset \
            --no-fail-on-empty-changeset \
            --stack-name prod-stack \
            --parameter-overrides Environment=prod
```

## Testing Strategies

### Unit Testing

**Test business logic independently**:

```typescript
// handler.ts
export const processOrder = (order: Order): ProcessedOrder => {
  // Pure business logic (easily testable)
  validateOrder(order);
  calculateTotal(order);
  return transformOrder(order);
};

export const handler = async (event: any) => {
  const order = parseEvent(event);
  const processed = processOrder(order); // Testable function
  await saveToDatabase(processed);
  return formatResponse(processed);
};

// handler.test.ts
import { processOrder } from './handler';

describe('processOrder', () => {
  it('calculates total correctly', () => {
    const order = {
      items: [
        { price: 10, quantity: 2 },
        { price: 5, quantity: 3 },
      ],
    };

    const result = processOrder(order);

    expect(result.total).toBe(35);
  });

  it('throws on invalid order', () => {
    const invalid = { items: [] };
    expect(() => processOrder(invalid)).toThrow();
  });
});
```

### Integration Testing

**Test in actual AWS environment**:

```typescript
// integration.test.ts
import { LambdaClient, InvokeCommand } from '@aws-sdk/client-lambda';
import { DynamoDBClient, GetItemCommand } from '@aws-sdk/client-dynamodb';

describe('Order Processing Integration', () => {
  const lambda = new LambdaClient({});
  const dynamodb = new DynamoDBClient({});

  it('processes order end-to-end', async () => {
    // Invoke Lambda
    const response = await lambda.send(new InvokeCommand({
      FunctionName: process.env.FUNCTION_NAME,
      Payload: JSON.stringify({
        orderId: 'test-123',
        items: [{ productId: 'prod-1', quantity: 2 }],
      }),
    }));

    const result = JSON.parse(Buffer.from(response.Payload!).toString());

    expect(result.statusCode).toBe(200);

    // Verify database write
    const dbResult = await dynamodb.send(new GetItemCommand({
      TableName: process.env.TABLE_NAME,
      Key: { orderId: { S: 'test-123' } },
    }));

    expect(dbResult.Item).toBeDefined();
    expect(dbResult.Item?.status.S).toBe('PROCESSED');
  });
});
```

### Local Testing with SAM

**Test locally before deployment**:

```bash
# Start local API
sam local start-api

# Invoke function locally
sam local invoke OrderFunction -e events/create-order.json

# Generate sample events
sam local generate-event apigateway aws-proxy > event.json

# Debug locally
sam local invoke OrderFunction -d 5858

# Test with Docker
sam local start-api --docker-network my-network
```

### Load Testing

**Test under production load**:

```bash
# Install Artillery
npm install -g artillery

# Create load test
cat > load-test.yml <<EOF
config:
  target: https://api.example.com
  phases:
    - duration: 300 # 5 minutes
      arrivalRate: 50 # 50 requests/second
      rampTo: 200 # Ramp to 200 req/sec
scenarios:
  - flow:
      - post:
          url: /orders
          json:
            orderId: "{{ $randomString() }}"
EOF

# Run load test
artillery run load-test.yml --output report.json

# Generate HTML report
artillery report report.json
```

## Deployment Strategies

### All-at-Once Deployment

**Simple, fast, risky**:

```yaml
# SAM template
Resources:
  OrderFunction:
    Type: AWS::Serverless::Function
    Properties:
      DeploymentPreference:
        Type: AllAtOnce # Deploy immediately
```

**Use for**:
- Development environments
- Non-critical applications
- Quick hotfixes (with caution)

### Blue/Green Deployment

**Zero-downtime deployment**:

```yaml
Resources:
  OrderFunction:
    Type: AWS::Serverless::Function
    Properties:
      AutoPublishAlias: live
      DeploymentPreference:
        Type: Linear10PercentEvery1Minute
        Alarms:
          - !Ref ErrorAlarm
          - !Ref LatencyAlarm
```

**Deployment types**:
- **Linear10PercentEvery1Minute**: 10% traffic shift every minute
- **Linear10PercentEvery2Minutes**: Slower, more conservative
- **Linear10PercentEvery3Minutes**: Even slower
- **Linear10PercentEvery10Minutes**: Very gradual
- **Canary10Percent5Minutes**: 10% for 5 min, then 100%
- **Canary10Percent10Minutes**: 10% for 10 min, then 100%
- **Canary10Percent30Minutes**: 10% for 30 min, then 100%

### Canary Deployment

**Test with subset of traffic**:

```yaml
Resources:
  OrderFunction:
    Type: AWS::Serverless::Function
    Properties:
      AutoPublishAlias: live
      DeploymentPreference:
        Type: Canary10Percent10Minutes
        Alarms:
          - !Ref ErrorAlarm
          - !Ref LatencyAlarm
        Hooks:
          PreTraffic: !Ref PreTrafficHook
          PostTraffic: !Ref PostTrafficHook

  PreTrafficHook:
    Type: AWS::Serverless::Function
    Properties:
      Handler: hooks.pre_traffic
      Runtime: python3.12
      # Runs before traffic shift
      # Validates new version

  PostTrafficHook:
    Type: AWS::Serverless::Function
    Properties:
      Handler: hooks.post_traffic
      Runtime: python3.12
      # Runs after traffic shift
      # Validates deployment success
```

**CDK with CodeDeploy**:

```typescript
import * as codedeploy from 'aws-cdk-lib/aws-codedeploy';

const alias = fn.currentVersion.addAlias('live');

new codedeploy.LambdaDeploymentGroup(this, 'DeploymentGroup', {
  alias,
  deploymentConfig: codedeploy.LambdaDeploymentConfig.CANARY_10PERCENT_10MINUTES,
  alarms: [errorAlarm, latencyAlarm],
  autoRollback: {
    failedDeployment: true,
    stoppedDeployment: true,
    deploymentInAlarm: true,
  },
});
```

### Deployment Hooks

**Pre-traffic hook (validation)**:

```python
# hooks.py
import boto3

lambda_client = boto3.client('lambda')
codedeploy = boto3.client('codedeploy')

def pre_traffic(event, context):
    """
    Validate new version before traffic shift
    """
    function_name = event['DeploymentId']
    version = event['NewVersion']

    try:
        # Invoke new version with test payload
        response = lambda_client.invoke(
            FunctionName=f"{function_name}:{version}",
            InvocationType='RequestResponse',
            Payload=json.dumps({'test': True})
        )

        # Validate response
        if response['StatusCode'] == 200:
            codedeploy.put_lifecycle_event_hook_execution_status(
                deploymentId=event['DeploymentId'],
                lifecycleEventHookExecutionId=event['LifecycleEventHookExecutionId'],
                status='Succeeded'
            )
        else:
            raise Exception('Validation failed')

    except Exception as e:
        print(f'Pre-traffic validation failed: {e}')
        codedeploy.put_lifecycle_event_hook_execution_status(
            deploymentId=event['DeploymentId'],
            lifecycleEventHookExecutionId=event['LifecycleEventHookExecutionId'],
            status='Failed'
        )
```

**Post-traffic hook (verification)**:

```python
def post_traffic(event, context):
    """
    Verify deployment success after traffic shift
    """
    try:
        # Check CloudWatch metrics
        cloudwatch = boto3.client('cloudwatch')

        metrics = cloudwatch.get_metric_statistics(
            Namespace='AWS/Lambda',
            MetricName='Errors',
            Dimensions=[{'Name': 'FunctionName', 'Value': function_name}],
            StartTime=deployment_start_time,
            EndTime=datetime.utcnow(),
            Period=300,
            Statistics=['Sum']
        )

        # Validate no errors
        total_errors = sum(point['Sum'] for point in metrics['Datapoints'])

        if total_errors == 0:
            codedeploy.put_lifecycle_event_hook_execution_status(
                deploymentId=event['DeploymentId'],
                lifecycleEventHookExecutionId=event['LifecycleEventHookExecutionId'],
                status='Succeeded'
            )
        else:
            raise Exception(f'{total_errors} errors detected')

    except Exception as e:
        print(f'Post-traffic verification failed: {e}')
        codedeploy.put_lifecycle_event_hook_execution_status(
            deploymentId=event['DeploymentId'],
            lifecycleEventHookExecutionId=event['LifecycleEventHookExecutionId'],
            status='Failed'
        )
```

## Rollback and Safety

### Automatic Rollback

**Configure rollback triggers**:

```yaml
DeploymentPreference:
  Type: Canary10Percent10Minutes
  Alarms:
    - !Ref ErrorAlarm
    - !Ref LatencyAlarm
  # Automatically rolls back if alarms trigger
```

**Rollback scenarios**:
- CloudWatch alarm triggers during deployment
- Pre-traffic hook fails
- Post-traffic hook fails
- Deployment manually stopped

### CloudWatch Alarms for Deployment

**Critical alarms during deployment**:

```typescript
// Error rate alarm
const errorAlarm = new cloudwatch.Alarm(this, 'ErrorAlarm', {
  metric: fn.metricErrors({
    statistic: 'Sum',
    period: Duration.minutes(1),
  }),
  threshold: 5,
  evaluationPeriods: 2,
  treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
});

// Duration alarm (regression)
const durationAlarm = new cloudwatch.Alarm(this, 'DurationAlarm', {
  metric: fn.metricDuration({
    statistic: 'Average',
    period: Duration.minutes(1),
  }),
  threshold: previousAvgDuration * 1.2, // 20% increase
  evaluationPeriods: 2,
  comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
});

// Throttle alarm
const throttleAlarm = new cloudwatch.Alarm(this, 'ThrottleAlarm', {
  metric: fn.metricThrottles({
    statistic: 'Sum',
    period: Duration.minutes(1),
  }),
  threshold: 1,
  evaluationPeriods: 1,
});
```

### Version Management

**Use Lambda versions and aliases**:

```typescript
const version = fn.currentVersion;

const prodAlias = version.addAlias('prod');
const devAlias = version.addAlias('dev');

// Gradual rollout with weighted aliases
new lambda.Alias(this, 'LiveAlias', {
  aliasName: 'live',
  version: newVersion,
  additionalVersions: [
    { version: oldVersion, weight: 0.9 }, // 90% old
    // 10% automatically goes to main version (new)
  ],
});
```

## Best Practices Checklist

### Pre-Deployment

- [ ] Code review completed
- [ ] Unit tests passing
- [ ] Integration tests passing
- [ ] Security scan completed
- [ ] Dependencies updated
- [ ] Infrastructure validated (CDK synth, SAM validate)
- [ ] Environment variables configured

### Deployment

- [ ] Use IaC (SAM, CDK, Terraform)
- [ ] Separate environments (dev, staging, prod)
- [ ] Automate deployments via CI/CD
- [ ] Use gradual deployment (canary or linear)
- [ ] Configure CloudWatch alarms
- [ ] Enable automatic rollback
- [ ] Use deployment hooks for validation

### Post-Deployment

- [ ] Monitor CloudWatch metrics
- [ ] Check CloudWatch Logs for errors
- [ ] Verify X-Ray traces
- [ ] Validate business metrics
- [ ] Check alarm status
- [ ] Review deployment logs
- [ ] Document any issues

### Rollback Preparation

- [ ] Keep previous version available
- [ ] Document rollback procedure
- [ ] Test rollback in non-prod
- [ ] Configure automatic rollback
- [ ] Monitor during rollback
- [ ] Communication plan for rollback

## Deployment Patterns

### Multi-Region Deployment

**Active-Passive**:

```typescript
// Primary region
new ServerlessStack(app, 'PrimaryStack', {
  env: { region: 'us-east-1' },
  isPrimary: true,
});

// Secondary region (standby)
new ServerlessStack(app, 'SecondaryStack', {
  env: { region: 'us-west-2' },
  isPrimary: false,
});

// Route 53 health check and failover
const healthCheck = new route53.CfnHealthCheck(this, 'HealthCheck', {
  type: 'HTTPS',
  resourcePath: '/health',
  fullyQualifiedDomainName: 'api.example.com',
});
```

**Active-Active**:

```typescript
// Deploy to multiple regions
const regions = ['us-east-1', 'us-west-2', 'eu-west-1'];

for (const region of regions) {
  new ServerlessStack(app, `Stack-${region}`, {
    env: { region },
  });
}

// Route 53 geolocation routing
new route53.ARecord(this, 'GeoRecord', {
  zone: hostedZone,
  recordName: 'api',
  target: route53.RecordTarget.fromAlias(
    new targets.ApiGatewayDomain(domain)
  ),
  geoLocation: route53.GeoLocation.country('US'),
});
```

### Feature Flags with AppConfig

**Safe feature rollout**:

```typescript
import { AppConfigData } from '@aws-sdk/client-appconfigdata';

const appconfig = new AppConfigData({});

export const handler = async (event: any) => {
  // Fetch feature flags
  const config = await appconfig.getLatestConfiguration({
    ConfigurationToken: token,
  });

  const features = JSON.parse(config.Configuration.toString());

  if (features.newFeatureEnabled) {
    return newFeatureHandler(event);
  }

  return legacyHandler(event);
};
```

## Summary

- **IaC**: Use SAM or CDK for all deployments
- **Environments**: Separate dev, staging, production
- **CI/CD**: Automate build, test, and deployment
- **Testing**: Unit, integration, and load testing
- **Gradual Deployment**: Use canary or linear for production
- **Alarms**: Configure and monitor during deployment
- **Rollback**: Enable automatic rollback on failures
- **Hooks**: Validate before and after traffic shifts
- **Versioning**: Use Lambda versions and aliases
- **Multi-Region**: Plan for disaster recovery
