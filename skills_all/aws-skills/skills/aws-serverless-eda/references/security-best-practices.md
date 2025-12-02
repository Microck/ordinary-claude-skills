# Serverless Security Best Practices

Security best practices for serverless applications based on AWS Well-Architected Framework.

## Table of Contents

- [Shared Responsibility Model](#shared-responsibility-model)
- [Identity and Access Management](#identity-and-access-management)
- [Function Security](#function-security)
- [API Security](#api-security)
- [Data Protection](#data-protection)
- [Network Security](#network-security)

## Shared Responsibility Model

### Serverless Shifts Responsibility to AWS

With serverless, AWS takes on more security responsibilities:

**AWS Responsibilities**:
- Compute infrastructure
- Execution environment
- Runtime language and patches
- Networking infrastructure
- Server software and OS
- Physical hardware and facilities
- Automatic security patches (like Log4Shell mitigation)

**Customer Responsibilities**:
- Function code and dependencies
- Resource configuration
- Identity and Access Management (IAM)
- Data encryption (at rest and in transit)
- Application-level security
- Secure coding practices

### Benefits of Shifted Responsibility

- **Automatic Patching**: AWS applies security patches automatically (e.g., Log4Shell fixed within 3 days)
- **Infrastructure Security**: No OS patching, server hardening, or vulnerability scanning
- **Operational Agility**: Quick security response at scale
- **Focus on Code**: Spend time on business logic, not infrastructure security

## Identity and Access Management

### Least Privilege Principle

**Always use least privilege IAM policies**:

```typescript
// ✅ GOOD - Specific grant
const table = new dynamodb.Table(this, 'Table', {});
const function = new lambda.Function(this, 'Function', {});

table.grantReadData(function); // Only read access

// ❌ BAD - Overly broad
function.addToRolePolicy(new iam.PolicyStatement({
  actions: ['dynamodb:*'],
  resources: ['*'],
}));
```

### Function Execution Role

**Separate roles per function**:

```typescript
// ✅ GOOD - Each function has its own role
const readFunction = new NodejsFunction(this, 'ReadFunction', {
  entry: 'src/read.ts',
  // Gets its own execution role
});

const writeFunction = new NodejsFunction(this, 'WriteFunction', {
  entry: 'src/write.ts',
  // Gets its own execution role
});

table.grantReadData(readFunction);
table.grantReadWriteData(writeFunction);

// ❌ BAD - Shared role with excessive permissions
const sharedRole = new iam.Role(this, 'SharedRole', {
  assumedBy: new iam.ServicePrincipal('lambda.amazonaws.com'),
  managedPolicies: [
    iam.ManagedPolicy.fromAwsManagedPolicyName('AdministratorAccess'), // Too broad!
  ],
});
```

### Resource-Based Policies

Control who can invoke functions:

```typescript
// Allow API Gateway to invoke function
myFunction.grantInvoke(new iam.ServicePrincipal('apigateway.amazonaws.com'));

// Allow specific account
myFunction.addPermission('AllowAccountInvoke', {
  principal: new iam.AccountPrincipal('123456789012'),
  action: 'lambda:InvokeFunction',
});

// Conditional invoke (only from specific VPC endpoint)
myFunction.addPermission('AllowVPCInvoke', {
  principal: new iam.ServicePrincipal('lambda.amazonaws.com'),
  action: 'lambda:InvokeFunction',
  sourceArn: vpcEndpoint.vpcEndpointId,
});
```

### IAM Policies Best Practices

1. **Use grant methods**: Prefer `.grantXxx()` over manual policies
2. **Condition keys**: Use IAM conditions for fine-grained control
3. **Resource ARNs**: Always specify resource ARNs, avoid wildcards
4. **Session policies**: Use for temporary elevated permissions
5. **Service Control Policies (SCPs)**: Enforce organization-wide guardrails

## Function Security

### Lambda Isolation Model

**Each function runs in isolated sandbox**:
- Built on Firecracker microVMs
- Dedicated execution environment per function
- No shared memory between functions
- Isolated file system and network namespace
- Strong workload isolation

**Execution Environment Security**:
- One concurrent invocation per environment
- Environment may be reused (warm starts)
- `/tmp` storage persists between invocations
- Sensitive data in memory may persist

### Secure Coding Practices

**Handle sensitive data securely**:

```typescript
// ✅ GOOD - Clean up sensitive data
export const handler = async (event: any) => {
  const apiKey = process.env.API_KEY;

  try {
    const result = await callApi(apiKey);
    return result;
  } finally {
    // Clear sensitive data from memory
    delete process.env.API_KEY;
  }
};

// ✅ GOOD - Use Secrets Manager
import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';

const secretsClient = new SecretsManagerClient({});

export const handler = async (event: any) => {
  const secret = await secretsClient.send(
    new GetSecretValueCommand({ SecretId: process.env.SECRET_ARN })
  );

  const apiKey = secret.SecretString;
  // Use apiKey
};
```

### Dependency Management

**Scan dependencies for vulnerabilities**:

```json
// package.json
{
  "scripts": {
    "audit": "npm audit",
    "audit:fix": "npm audit fix"
  },
  "devDependencies": {
    "snyk": "^1.0.0"
  }
}
```

**Keep dependencies updated**:
- Run `npm audit` or `pip-audit` regularly
- Use Dependabot or Snyk for automated scanning
- Update dependencies promptly when vulnerabilities found
- Use minimal dependency sets

### Environment Variable Security

**Never store secrets in environment variables**:

```typescript
// ❌ BAD - Secret in environment variable
new NodejsFunction(this, 'Function', {
  environment: {
    API_KEY: 'sk-1234567890abcdef', // Never do this!
  },
});

// ✅ GOOD - Reference to secret
new NodejsFunction(this, 'Function', {
  environment: {
    SECRET_ARN: secret.secretArn,
  },
});

secret.grantRead(myFunction);
```

## API Security

### API Gateway Security

**Authentication and Authorization**:

```typescript
// Cognito User Pool authorizer
const authorizer = new apigateway.CognitoUserPoolsAuthorizer(this, 'Authorizer', {
  cognitoUserPools: [userPool],
});

api.root.addMethod('GET', integration, {
  authorizer,
  authorizationType: apigateway.AuthorizationType.COGNITO,
});

// Lambda authorizer for custom auth
const customAuthorizer = new apigateway.TokenAuthorizer(this, 'CustomAuth', {
  handler: authorizerFunction,
  resultsCacheTtl: Duration.minutes(5),
});

// IAM authorization for service-to-service
api.root.addMethod('POST', integration, {
  authorizationType: apigateway.AuthorizationType.IAM,
});
```

### Request Validation

**Validate requests at API Gateway**:

```typescript
const validator = new apigateway.RequestValidator(this, 'Validator', {
  api,
  validateRequestBody: true,
  validateRequestParameters: true,
});

const model = api.addModel('Model', {
  schema: {
    type: apigateway.JsonSchemaType.OBJECT,
    required: ['email', 'name'],
    properties: {
      email: {
        type: apigateway.JsonSchemaType.STRING,
        format: 'email',
      },
      name: {
        type: apigateway.JsonSchemaType.STRING,
        minLength: 1,
        maxLength: 100,
      },
    },
  },
});

resource.addMethod('POST', integration, {
  requestValidator: validator,
  requestModels: {
    'application/json': model,
  },
});
```

### Rate Limiting and Throttling

```typescript
const api = new apigateway.RestApi(this, 'Api', {
  deployOptions: {
    throttlingRateLimit: 1000, // requests per second
    throttlingBurstLimit: 2000, // burst capacity
  },
});

// Per-method throttling
resource.addMethod('POST', integration, {
  methodResponses: [{ statusCode: '200' }],
  requestParameters: {
    'method.request.header.Authorization': true,
  },
  throttling: {
    rateLimit: 100,
    burstLimit: 200,
  },
});
```

### API Keys and Usage Plans

```typescript
const apiKey = api.addApiKey('ApiKey', {
  apiKeyName: 'customer-key',
});

const plan = api.addUsagePlan('UsagePlan', {
  name: 'Standard',
  throttle: {
    rateLimit: 100,
    burstLimit: 200,
  },
  quota: {
    limit: 10000,
    period: apigateway.Period.MONTH,
  },
});

plan.addApiKey(apiKey);
plan.addApiStage({
  stage: api.deploymentStage,
});
```

## Data Protection

### Encryption at Rest

**DynamoDB encryption**:

```typescript
// Default: AWS-owned CMK (no additional cost)
const table = new dynamodb.Table(this, 'Table', {
  encryption: dynamodb.TableEncryption.AWS_MANAGED, // AWS managed CMK
});

// Customer-managed CMK (for compliance)
const kmsKey = new kms.Key(this, 'Key', {
  enableKeyRotation: true,
});

const table = new dynamodb.Table(this, 'Table', {
  encryption: dynamodb.TableEncryption.CUSTOMER_MANAGED,
  encryptionKey: kmsKey,
});
```

**S3 encryption**:

```typescript
// SSE-S3 (default, no additional cost)
const bucket = new s3.Bucket(this, 'Bucket', {
  encryption: s3.BucketEncryption.S3_MANAGED,
});

// SSE-KMS (for fine-grained access control)
const bucket = new s3.Bucket(this, 'Bucket', {
  encryption: s3.BucketEncryption.KMS,
  encryptionKey: kmsKey,
});
```

**SQS/SNS encryption**:

```typescript
const queue = new sqs.Queue(this, 'Queue', {
  encryption: sqs.QueueEncryption.KMS,
  encryptionMasterKey: kmsKey,
});

const topic = new sns.Topic(this, 'Topic', {
  masterKey: kmsKey,
});
```

### Encryption in Transit

**All AWS service APIs use TLS**:
- API Gateway endpoints use HTTPS by default
- Lambda to AWS service communication encrypted
- EventBridge, SQS, SNS use TLS
- Custom domains can use ACM certificates

```typescript
// API Gateway with custom domain
const certificate = new acm.Certificate(this, 'Certificate', {
  domainName: 'api.example.com',
  validation: acm.CertificateValidation.fromDns(hostedZone),
});

const api = new apigateway.RestApi(this, 'Api', {
  domainName: {
    domainName: 'api.example.com',
    certificate,
  },
});
```

### Data Sanitization

**Validate and sanitize inputs**:

```typescript
import DOMPurify from 'isomorphic-dompurify';
import { z } from 'zod';

// Schema validation
const OrderSchema = z.object({
  orderId: z.string().uuid(),
  amount: z.number().positive(),
  email: z.string().email(),
});

export const handler = async (event: any) => {
  const body = JSON.parse(event.body);

  // Validate schema
  const result = OrderSchema.safeParse(body);
  if (!result.success) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: result.error }),
    };
  }

  // Sanitize HTML inputs
  const sanitized = {
    ...result.data,
    description: DOMPurify.sanitize(result.data.description),
  };

  await processOrder(sanitized);
};
```

## Network Security

### VPC Configuration

**Lambda in VPC for private resources**:

```typescript
const vpc = new ec2.Vpc(this, 'Vpc', {
  maxAzs: 2,
  natGateways: 1,
});

// Lambda in private subnet
const vpcFunction = new NodejsFunction(this, 'VpcFunction', {
  entry: 'src/handler.ts',
  vpc,
  vpcSubnets: {
    subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
  },
  securityGroups: [securityGroup],
});

// Security group for Lambda
const securityGroup = new ec2.SecurityGroup(this, 'LambdaSG', {
  vpc,
  description: 'Security group for Lambda function',
  allowAllOutbound: false, // Restrict outbound
});

// Only allow access to RDS
securityGroup.addEgressRule(
  ec2.Peer.securityGroupId(rdsSecurityGroup.securityGroupId),
  ec2.Port.tcp(3306),
  'Allow MySQL access'
);
```

### VPC Endpoints

**Use VPC endpoints for AWS services**:

```typescript
// S3 VPC endpoint (gateway endpoint, no cost)
vpc.addGatewayEndpoint('S3Endpoint', {
  service: ec2.GatewayVpcEndpointAwsService.S3,
});

// DynamoDB VPC endpoint (gateway endpoint, no cost)
vpc.addGatewayEndpoint('DynamoDBEndpoint', {
  service: ec2.GatewayVpcEndpointAwsService.DYNAMODB,
});

// Secrets Manager VPC endpoint (interface endpoint, cost applies)
vpc.addInterfaceEndpoint('SecretsManagerEndpoint', {
  service: ec2.InterfaceVpcEndpointAwsService.SECRETS_MANAGER,
  privateDnsEnabled: true,
});
```

### Security Groups

**Principle of least privilege for network access**:

```typescript
// Lambda security group
const lambdaSG = new ec2.SecurityGroup(this, 'LambdaSG', {
  vpc,
  allowAllOutbound: false,
});

// RDS security group
const rdsSG = new ec2.SecurityGroup(this, 'RDSSG', {
  vpc,
  allowAllOutbound: false,
});

// Allow Lambda to access RDS only
rdsSG.addIngressRule(
  ec2.Peer.securityGroupId(lambdaSG.securityGroupId),
  ec2.Port.tcp(3306),
  'Allow Lambda access'
);

lambdaSG.addEgressRule(
  ec2.Peer.securityGroupId(rdsSG.securityGroupId),
  ec2.Port.tcp(3306),
  'Allow RDS access'
);
```

## Security Monitoring

### CloudWatch Logs

**Enable and encrypt logs**:

```typescript
new NodejsFunction(this, 'Function', {
  entry: 'src/handler.ts',
  logRetention: logs.RetentionDays.ONE_WEEK,
  logGroup: new logs.LogGroup(this, 'LogGroup', {
    encryptionKey: kmsKey, // Encrypt logs
    retention: logs.RetentionDays.ONE_WEEK,
  }),
});
```

### CloudTrail

**Enable CloudTrail for audit**:

```typescript
const trail = new cloudtrail.Trail(this, 'Trail', {
  isMultiRegionTrail: true,
  includeGlobalServiceEvents: true,
  managementEvents: cloudtrail.ReadWriteType.ALL,
});

// Log Lambda invocations
trail.addLambdaEventSelector([{
  includeManagementEvents: true,
  readWriteType: cloudtrail.ReadWriteType.ALL,
}]);
```

### GuardDuty

**Enable GuardDuty for threat detection**:
- Analyzes VPC Flow Logs, DNS logs, CloudTrail events
- Detects unusual API activity
- Identifies compromised credentials
- Monitors for cryptocurrency mining

## Security Best Practices Checklist

### Development

- [ ] Validate and sanitize all inputs
- [ ] Scan dependencies for vulnerabilities
- [ ] Use least privilege IAM permissions
- [ ] Store secrets in Secrets Manager or Parameter Store
- [ ] Never log sensitive data
- [ ] Enable encryption for all data stores
- [ ] Use environment variables for configuration, not secrets

### Deployment

- [ ] Enable CloudTrail in all regions
- [ ] Configure VPC for sensitive workloads
- [ ] Use VPC endpoints for AWS service access
- [ ] Enable GuardDuty for threat detection
- [ ] Implement resource-based policies
- [ ] Use AWS WAF for API protection
- [ ] Enable access logging for API Gateway

### Operations

- [ ] Monitor CloudTrail for unusual activity
- [ ] Set up alarms for security events
- [ ] Rotate secrets regularly
- [ ] Review IAM policies periodically
- [ ] Audit function permissions
- [ ] Monitor GuardDuty findings
- [ ] Implement automated security responses

### Testing

- [ ] Test with least privilege policies
- [ ] Validate error handling for security failures
- [ ] Test input validation and sanitization
- [ ] Verify encryption configurations
- [ ] Test with malicious payloads
- [ ] Audit logs for security events

## Summary

- **Shared Responsibility**: AWS handles infrastructure, you handle application security
- **Least Privilege**: Use IAM grant methods, avoid wildcards
- **Encryption**: Enable encryption at rest and in transit
- **Input Validation**: Validate and sanitize all inputs
- **Dependency Security**: Scan and update dependencies regularly
- **Monitoring**: Enable CloudTrail, GuardDuty, and CloudWatch
- **Secrets Management**: Use Secrets Manager, never environment variables
- **Network Security**: Use VPC, security groups, and VPC endpoints appropriately
