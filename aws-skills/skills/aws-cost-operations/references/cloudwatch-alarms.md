# CloudWatch Alarms Reference

Common CloudWatch alarm configurations for AWS services.

## Lambda Functions

### Error Rate Alarm
```typescript
new cloudwatch.Alarm(this, 'LambdaErrorAlarm', {
  metric: lambdaFunction.metricErrors({
    statistic: 'Sum',
    period: Duration.minutes(5),
  }),
  threshold: 10,
  evaluationPeriods: 1,
  treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
  alarmDescription: 'Lambda error count exceeded threshold',
});
```

### Duration Alarm (Approaching Timeout)
```typescript
new cloudwatch.Alarm(this, 'LambdaDurationAlarm', {
  metric: lambdaFunction.metricDuration({
    statistic: 'Maximum',
    period: Duration.minutes(5),
  }),
  threshold: lambdaFunction.timeout.toMilliseconds() * 0.8, // 80% of timeout
  evaluationPeriods: 2,
  alarmDescription: 'Lambda duration approaching timeout',
});
```

### Throttle Alarm
```typescript
new cloudwatch.Alarm(this, 'LambdaThrottleAlarm', {
  metric: lambdaFunction.metricThrottles({
    statistic: 'Sum',
    period: Duration.minutes(5),
  }),
  threshold: 5,
  evaluationPeriods: 1,
  alarmDescription: 'Lambda function is being throttled',
});
```

### Concurrent Executions Alarm
```typescript
new cloudwatch.Alarm(this, 'LambdaConcurrencyAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'AWS/Lambda',
    metricName: 'ConcurrentExecutions',
    dimensionsMap: {
      FunctionName: lambdaFunction.functionName,
    },
    statistic: 'Maximum',
    period: Duration.minutes(1),
  }),
  threshold: 100, // Adjust based on reserved concurrency
  evaluationPeriods: 2,
  alarmDescription: 'Lambda concurrent executions high',
});
```

## API Gateway

### 5XX Error Rate Alarm
```typescript
new cloudwatch.Alarm(this, 'Api5xxAlarm', {
  metric: api.metricServerError({
    statistic: 'Sum',
    period: Duration.minutes(5),
  }),
  threshold: 10,
  evaluationPeriods: 1,
  alarmDescription: 'API Gateway 5XX errors exceeded threshold',
});
```

### 4XX Error Rate Alarm
```typescript
new cloudwatch.Alarm(this, 'Api4xxAlarm', {
  metric: api.metricClientError({
    statistic: 'Sum',
    period: Duration.minutes(5),
  }),
  threshold: 50,
  evaluationPeriods: 2,
  alarmDescription: 'API Gateway 4XX errors exceeded threshold',
});
```

### Latency Alarm
```typescript
new cloudwatch.Alarm(this, 'ApiLatencyAlarm', {
  metric: api.metricLatency({
    statistic: 'p99',
    period: Duration.minutes(5),
  }),
  threshold: 2000, // 2 seconds
  evaluationPeriods: 2,
  alarmDescription: 'API Gateway p99 latency exceeded threshold',
});
```

## DynamoDB

### Read Throttle Alarm
```typescript
new cloudwatch.Alarm(this, 'DynamoDBReadThrottleAlarm', {
  metric: table.metricUserErrors({
    dimensions: {
      Operation: 'GetItem',
    },
    statistic: 'Sum',
    period: Duration.minutes(5),
  }),
  threshold: 5,
  evaluationPeriods: 1,
  alarmDescription: 'DynamoDB read operations being throttled',
});
```

### Write Throttle Alarm
```typescript
new cloudwatch.Alarm(this, 'DynamoDBWriteThrottleAlarm', {
  metric: table.metricUserErrors({
    dimensions: {
      Operation: 'PutItem',
    },
    statistic: 'Sum',
    period: Duration.minutes(5),
  }),
  threshold: 5,
  evaluationPeriods: 1,
  alarmDescription: 'DynamoDB write operations being throttled',
});
```

### Consumed Capacity Alarm
```typescript
new cloudwatch.Alarm(this, 'DynamoDBCapacityAlarm', {
  metric: table.metricConsumedReadCapacityUnits({
    statistic: 'Sum',
    period: Duration.minutes(5),
  }),
  threshold: provisionedCapacity * 0.8, // 80% of provisioned
  evaluationPeriods: 2,
  alarmDescription: 'DynamoDB consumed capacity approaching limit',
});
```

## EC2 Instances

### CPU Utilization Alarm
```typescript
new cloudwatch.Alarm(this, 'EC2CpuAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'AWS/EC2',
    metricName: 'CPUUtilization',
    dimensionsMap: {
      InstanceId: instance.instanceId,
    },
    statistic: 'Average',
    period: Duration.minutes(5),
  }),
  threshold: 80,
  evaluationPeriods: 3,
  alarmDescription: 'EC2 CPU utilization high',
});
```

### Status Check Failed Alarm
```typescript
new cloudwatch.Alarm(this, 'EC2StatusCheckAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'AWS/EC2',
    metricName: 'StatusCheckFailed',
    dimensionsMap: {
      InstanceId: instance.instanceId,
    },
    statistic: 'Maximum',
    period: Duration.minutes(1),
  }),
  threshold: 1,
  evaluationPeriods: 2,
  alarmDescription: 'EC2 status check failed',
});
```

### Disk Space Alarm (Requires CloudWatch Agent)
```typescript
new cloudwatch.Alarm(this, 'EC2DiskAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'CWAgent',
    metricName: 'disk_used_percent',
    dimensionsMap: {
      InstanceId: instance.instanceId,
      path: '/',
    },
    statistic: 'Average',
    period: Duration.minutes(5),
  }),
  threshold: 85,
  evaluationPeriods: 2,
  alarmDescription: 'EC2 disk space usage high',
});
```

## RDS Databases

### CPU Alarm
```typescript
new cloudwatch.Alarm(this, 'RDSCpuAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'AWS/RDS',
    metricName: 'CPUUtilization',
    dimensionsMap: {
      DBInstanceIdentifier: dbInstance.instanceIdentifier,
    },
    statistic: 'Average',
    period: Duration.minutes(5),
  }),
  threshold: 80,
  evaluationPeriods: 3,
  alarmDescription: 'RDS CPU utilization high',
});
```

### Connection Count Alarm
```typescript
new cloudwatch.Alarm(this, 'RDSConnectionAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'AWS/RDS',
    metricName: 'DatabaseConnections',
    dimensionsMap: {
      DBInstanceIdentifier: dbInstance.instanceIdentifier,
    },
    statistic: 'Average',
    period: Duration.minutes(5),
  }),
  threshold: maxConnections * 0.8, // 80% of max connections
  evaluationPeriods: 2,
  alarmDescription: 'RDS connection count approaching limit',
});
```

### Free Storage Space Alarm
```typescript
new cloudwatch.Alarm(this, 'RDSStorageAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'AWS/RDS',
    metricName: 'FreeStorageSpace',
    dimensionsMap: {
      DBInstanceIdentifier: dbInstance.instanceIdentifier,
    },
    statistic: 'Average',
    period: Duration.minutes(5),
  }),
  threshold: 10 * 1024 * 1024 * 1024, // 10 GB in bytes
  comparisonOperator: cloudwatch.ComparisonOperator.LESS_THAN_THRESHOLD,
  evaluationPeriods: 1,
  alarmDescription: 'RDS free storage space low',
});
```

## ECS Services

### Task Count Alarm
```typescript
new cloudwatch.Alarm(this, 'ECSTaskCountAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'ECS/ContainerInsights',
    metricName: 'RunningTaskCount',
    dimensionsMap: {
      ServiceName: service.serviceName,
      ClusterName: cluster.clusterName,
    },
    statistic: 'Average',
    period: Duration.minutes(5),
  }),
  threshold: 1,
  comparisonOperator: cloudwatch.ComparisonOperator.LESS_THAN_THRESHOLD,
  evaluationPeriods: 2,
  alarmDescription: 'ECS service has no running tasks',
});
```

### CPU Utilization Alarm
```typescript
new cloudwatch.Alarm(this, 'ECSCpuAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'AWS/ECS',
    metricName: 'CPUUtilization',
    dimensionsMap: {
      ServiceName: service.serviceName,
      ClusterName: cluster.clusterName,
    },
    statistic: 'Average',
    period: Duration.minutes(5),
  }),
  threshold: 80,
  evaluationPeriods: 3,
  alarmDescription: 'ECS service CPU utilization high',
});
```

### Memory Utilization Alarm
```typescript
new cloudwatch.Alarm(this, 'ECSMemoryAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'AWS/ECS',
    metricName: 'MemoryUtilization',
    dimensionsMap: {
      ServiceName: service.serviceName,
      ClusterName: cluster.clusterName,
    },
    statistic: 'Average',
    period: Duration.minutes(5),
  }),
  threshold: 85,
  evaluationPeriods: 2,
  alarmDescription: 'ECS service memory utilization high',
});
```

## SQS Queues

### Queue Depth Alarm
```typescript
new cloudwatch.Alarm(this, 'SQSDepthAlarm', {
  metric: queue.metricApproximateNumberOfMessagesVisible({
    statistic: 'Maximum',
    period: Duration.minutes(5),
  }),
  threshold: 1000,
  evaluationPeriods: 2,
  alarmDescription: 'SQS queue depth exceeded threshold',
});
```

### Age of Oldest Message Alarm
```typescript
new cloudwatch.Alarm(this, 'SQSAgeAlarm', {
  metric: queue.metricApproximateAgeOfOldestMessage({
    statistic: 'Maximum',
    period: Duration.minutes(5),
  }),
  threshold: 300, // 5 minutes in seconds
  evaluationPeriods: 1,
  alarmDescription: 'SQS messages not being processed timely',
});
```

## Application Load Balancer

### Target Health Alarm
```typescript
new cloudwatch.Alarm(this, 'ALBUnhealthyTargetAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'AWS/ApplicationELB',
    metricName: 'UnHealthyHostCount',
    dimensionsMap: {
      LoadBalancer: loadBalancer.loadBalancerFullName,
      TargetGroup: targetGroup.targetGroupFullName,
    },
    statistic: 'Average',
    period: Duration.minutes(5),
  }),
  threshold: 1,
  evaluationPeriods: 2,
  alarmDescription: 'ALB has unhealthy targets',
});
```

### HTTP 5XX Alarm
```typescript
new cloudwatch.Alarm(this, 'ALB5xxAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'AWS/ApplicationELB',
    metricName: 'HTTPCode_Target_5XX_Count',
    dimensionsMap: {
      LoadBalancer: loadBalancer.loadBalancerFullName,
    },
    statistic: 'Sum',
    period: Duration.minutes(5),
  }),
  threshold: 10,
  evaluationPeriods: 1,
  alarmDescription: 'ALB target 5XX errors exceeded threshold',
});
```

### Response Time Alarm
```typescript
new cloudwatch.Alarm(this, 'ALBLatencyAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'AWS/ApplicationELB',
    metricName: 'TargetResponseTime',
    dimensionsMap: {
      LoadBalancer: loadBalancer.loadBalancerFullName,
    },
    statistic: 'p99',
    period: Duration.minutes(5),
  }),
  threshold: 1, // 1 second
  evaluationPeriods: 2,
  alarmDescription: 'ALB p99 response time exceeded threshold',
});
```

## Composite Alarms

### Service Health Composite Alarm
```typescript
const errorAlarm = new cloudwatch.Alarm(this, 'ErrorAlarm', { /* ... */ });
const latencyAlarm = new cloudwatch.Alarm(this, 'LatencyAlarm', { /* ... */ });
const throttleAlarm = new cloudwatch.Alarm(this, 'ThrottleAlarm', { /* ... */ });

new cloudwatch.CompositeAlarm(this, 'ServiceHealthAlarm', {
  compositeAlarmName: 'service-health',
  alarmRule: cloudwatch.AlarmRule.anyOf(
    errorAlarm,
    latencyAlarm,
    throttleAlarm
  ),
  alarmDescription: 'Overall service health degraded',
});
```

## Alarm Actions

### SNS Topic Integration
```typescript
const topic = new sns.Topic(this, 'AlarmTopic', {
  displayName: 'CloudWatch Alarms',
});

// Email subscription
topic.addSubscription(new subscriptions.EmailSubscription('ops@example.com'));

// Add action to alarm
alarm.addAlarmAction(new actions.SnsAction(topic));
alarm.addOkAction(new actions.SnsAction(topic));
```

### Auto Scaling Action
```typescript
const scalingAction = targetGroup.scaleOnMetric('ScaleUp', {
  metric: targetGroup.metricTargetResponseTime(),
  scalingSteps: [
    { upper: 1, change: 0 },
    { lower: 1, change: +1 },
    { lower: 2, change: +2 },
  ],
});
```

## Alarm Best Practices

### Threshold Selection

**CPU/Memory Alarms**:
- Warning: 70-80%
- Critical: 80-90%
- Consider burst patterns and normal usage

**Error Rate Alarms**:
- Threshold based on SLA (e.g., 99.9% = 0.1% error rate)
- Account for normal error rates
- Different thresholds for different error types

**Latency Alarms**:
- p99 latency for user-facing APIs
- Warning: 80% of SLA target
- Critical: 100% of SLA target

### Evaluation Periods

**Fast-changing metrics** (1-2 periods):
- Error counts
- Failed health checks
- Critical application errors

**Slow-changing metrics** (3-5 periods):
- CPU utilization
- Memory usage
- Disk usage

**Cost-related metrics** (longer periods):
- Daily spending
- Resource count changes
- Usage patterns

### Missing Data Handling

```typescript
// For intermittent workloads
alarm.treatMissingData(cloudwatch.TreatMissingData.NOT_BREACHING);

// For always-on services
alarm.treatMissingData(cloudwatch.TreatMissingData.BREACHING);

// To distinguish from data issues
alarm.treatMissingData(cloudwatch.TreatMissingData.MISSING);
```

### Alarm Naming Conventions

```typescript
// Pattern: <service>-<metric>-<severity>
'lambda-errors-critical'
'api-latency-warning'
'rds-cpu-warning'
'ecs-tasks-critical'
```

### Alarm Actions Best Practices

1. **Separate topics by severity**:
   - Critical alarms → PagerDuty/on-call
   - Warning alarms → Slack/email
   - Info alarms → Metrics dashboard

2. **Include context in alarm description**:
   - Service name
   - Expected threshold
   - Troubleshooting runbook link

3. **Auto-remediation where possible**:
   - Lambda errors → automatic retry
   - CPU high → auto-scaling trigger
   - Disk full → automated cleanup

4. **Alarm fatigue prevention**:
   - Tune thresholds based on actual patterns
   - Use composite alarms to reduce noise
   - Implement proper evaluation periods
   - Regularly review and adjust alarms

## Monitoring Dashboard

### Recommended Dashboard Layout

**Service Overview**:
- Request count and rate
- Error count and percentage
- Latency (p50, p95, p99)
- Availability percentage

**Resource Utilization**:
- CPU utilization by service
- Memory utilization by service
- Network throughput
- Disk I/O

**Cost Metrics**:
- Daily spending by service
- Month-to-date costs
- Budget utilization
- Cost anomalies

**Security Metrics**:
- Failed login attempts
- IAM policy changes
- Security group modifications
- GuardDuty findings
