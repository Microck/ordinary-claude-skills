# AWS Cost & Operations Patterns

Comprehensive patterns and best practices for AWS cost optimization, monitoring, and operational excellence.

## Table of Contents

- [Cost Optimization Patterns](#cost-optimization-patterns)
- [Monitoring Patterns](#monitoring-patterns)
- [Observability Patterns](#observability-patterns)
- [Security and Audit Patterns](#security-and-audit-patterns)
- [Troubleshooting Workflows](#troubleshooting-workflows)

## Cost Optimization Patterns

### Pattern 1: Cost Estimation Before Deployment

**When**: Before deploying any new infrastructure

**MCP Server**: AWS Pricing MCP

**Steps**:
1. List all resources to be deployed
2. Query pricing for each resource type
3. Calculate monthly costs based on expected usage
4. Compare pricing across regions
5. Document cost estimates in architecture docs

**Example**:
```
Resource: Lambda Function
- Invocations: 1,000,000/month
- Duration: 3 seconds avg
- Memory: 512 MB
- Region: us-east-1
Estimated cost: $X/month
```

### Pattern 2: Monthly Cost Review

**When**: First week of every month

**MCP Servers**: Cost Explorer MCP, Billing and Cost Management MCP

**Steps**:
1. Review total spending vs. budget
2. Analyze cost by service (top 5 services)
3. Identify cost anomalies (>20% increase)
4. Review cost by environment (dev/staging/prod)
5. Check cost allocation tag coverage
6. Generate cost optimization recommendations

**Key Metrics**:
- Month-over-month cost change
- Cost per environment
- Cost per application/project
- Untagged resource costs

### Pattern 3: Right-Sizing Resources

**When**: Quarterly or when utilization alerts trigger

**MCP Servers**: CloudWatch MCP, Cost Explorer MCP

**Steps**:
1. Query CloudWatch for resource utilization metrics
2. Identify over-provisioned resources (< 40% utilization)
3. Identify under-provisioned resources (> 80% utilization)
4. Calculate potential savings from right-sizing
5. Plan and execute right-sizing changes
6. Monitor post-change performance

**Common Right-Sizing Scenarios**:
- EC2 instances with low CPU utilization
- RDS instances with excess capacity
- DynamoDB tables with low read/write usage
- Lambda functions with excessive memory allocation

### Pattern 4: Unused Resource Cleanup

**When**: Monthly or triggered by cost anomalies

**MCP Servers**: Cost Explorer MCP, CloudTrail MCP

**Steps**:
1. Identify resources with zero usage
2. Query CloudTrail for last access time
3. Tag resources for deletion review
4. Notify resource owners
5. Delete confirmed unused resources
6. Track cost savings

**Common Unused Resources**:
- Unattached EBS volumes
- Old EBS snapshots
- Idle Load Balancers
- Unused Elastic IPs
- Old AMIs and snapshots
- Stopped EC2 instances (long-term)

## Monitoring Patterns

### Pattern 1: Critical Service Monitoring

**When**: All production services

**MCP Server**: CloudWatch MCP

**Metrics to Monitor**:
- **Availability**: Service uptime, health checks
- **Performance**: Latency, response time
- **Errors**: Error rate, failed requests
- **Saturation**: CPU, memory, disk, network utilization

**Alarm Thresholds** (adjust based on SLAs):
- Error rate: > 1% for 2 consecutive periods
- Latency: p99 > 1 second for 5 minutes
- CPU: > 80% for 10 minutes
- Memory: > 85% for 5 minutes

### Pattern 2: Lambda Function Monitoring

**MCP Server**: CloudWatch MCP

**Key Metrics**:
```
- Invocations (Count)
- Errors (Count, %)
- Duration (Average, p99)
- Throttles (Count)
- ConcurrentExecutions (Max)
- IteratorAge (for stream processing)
```

**Recommended Alarms**:
- Error rate > 1%
- Duration > 80% of timeout
- Throttles > 0
- ConcurrentExecutions > 80% of reserved

### Pattern 3: API Gateway Monitoring

**MCP Server**: CloudWatch MCP

**Key Metrics**:
```
- Count (Total requests)
- 4XXError, 5XXError
- Latency (p50, p95, p99)
- IntegrationLatency
- CacheHitCount, CacheMissCount
```

**Recommended Alarms**:
- 5XX error rate > 0.5%
- 4XX error rate > 5%
- Latency p99 > 2 seconds
- Integration latency spike

### Pattern 4: Database Monitoring

**MCP Server**: CloudWatch MCP

**RDS Metrics**:
```
- CPUUtilization
- DatabaseConnections
- FreeableMemory
- ReadLatency, WriteLatency
- ReadIOPS, WriteIOPS
- FreeStorageSpace
```

**DynamoDB Metrics**:
```
- ConsumedReadCapacityUnits
- ConsumedWriteCapacityUnits
- UserErrors
- SystemErrors
- ThrottledRequests
```

**Recommended Alarms**:
- RDS CPU > 80% for 10 minutes
- RDS connections > 80% of max
- RDS free storage < 10 GB
- DynamoDB throttled requests > 0
- DynamoDB user errors spike

## Observability Patterns

### Pattern 1: Distributed Tracing Setup

**MCP Server**: CloudWatch Application Signals MCP

**Components**:
1. **Service Map**: Visualize service dependencies
2. **Traces**: Track requests across services
3. **Metrics**: Monitor latency and errors per service
4. **SLOs**: Define and track service level objectives

**Implementation**:
- Enable X-Ray tracing on Lambda functions
- Add X-Ray SDK to application code
- Configure sampling rules
- Create service lens dashboards

### Pattern 2: Log Aggregation and Analysis

**MCP Server**: CloudWatch MCP

**Log Strategy**:
1. **Centralize Logs**: Send all application logs to CloudWatch Logs
2. **Structure Logs**: Use JSON format for structured logging
3. **Log Insights**: Use CloudWatch Logs Insights for queries
4. **Retention**: Set appropriate retention periods

**Example Log Insights Queries**:
```
# Find errors in last hour
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100

# Count errors by type
stats count() by error_type
| sort count desc

# Calculate p99 latency
stats percentile(duration, 99) by service_name
```

### Pattern 3: Custom Metrics

**MCP Server**: CloudWatch MCP

**When to Use Custom Metrics**:
- Business-specific KPIs (orders/minute, revenue/hour)
- Application-specific metrics (cache hit rate, queue depth)
- Performance metrics not provided by AWS

**Best Practices**:
- Use consistent namespace: `CompanyName/ApplicationName`
- Include relevant dimensions (environment, region, version)
- Publish metrics at appropriate intervals
- Use metric filters for log-derived metrics

## Security and Audit Patterns

### Pattern 1: API Activity Auditing

**MCP Server**: CloudTrail MCP

**Regular Audit Queries**:
```
# Find all IAM changes
eventName: CreateUser, DeleteUser, AttachUserPolicy, etc.
Time: Last 24 hours

# Track S3 bucket deletions
eventName: DeleteBucket
Time: Last 7 days

# Find failed login attempts
eventName: ConsoleLogin
errorCode: Failure

# Monitor privileged actions
userIdentity.arn: *admin* OR *root*
```

**Audit Schedule**:
- Daily: Review privileged user actions
- Weekly: Audit IAM changes and security group modifications
- Monthly: Comprehensive security review

### Pattern 2: Security Posture Assessment

**MCP Server**: Well-Architected Security Assessment Tool MCP

**Assessment Areas**:
1. **Identity and Access Management**
   - Least privilege implementation
   - MFA enforcement
   - Role-based access control
   - Service control policies

2. **Detective Controls**
   - CloudTrail enabled in all regions
   - GuardDuty findings review
   - Config rule compliance
   - Security Hub findings

3. **Infrastructure Protection**
   - VPC security groups review
   - Network ACLs configuration
   - AWS WAF rules
   - Security group ingress rules

4. **Data Protection**
   - Encryption at rest (S3, EBS, RDS)
   - Encryption in transit (TLS/SSL)
   - KMS key usage and rotation
   - Secrets Manager utilization

5. **Incident Response**
   - IR playbooks documented
   - Automated response procedures
   - Contact information current
   - Regular IR drills

**Assessment Frequency**:
- Quarterly: Full Well-Architected review
- Monthly: High-priority findings review
- Weekly: Critical security findings

### Pattern 3: Compliance Monitoring

**MCP Servers**: CloudTrail MCP, CloudWatch MCP

**Compliance Requirements**:
- Data residency (ensure data stays in approved regions)
- Access logging (all access logged and retained)
- Encryption requirements (data encrypted at rest and in transit)
- Change management (all changes tracked in CloudTrail)

**Compliance Dashboards**:
- Encryption coverage by service
- CloudTrail logging status
- Failed login attempts
- Privileged access usage
- Non-compliant resources

## Troubleshooting Workflows

### Workflow 1: High Lambda Error Rate

**MCP Servers**: CloudWatch MCP, CloudWatch Application Signals MCP

**Steps**:
1. Query CloudWatch for Lambda error metrics
2. Check error logs in CloudWatch Logs
3. Identify error patterns (timeout, memory, permission)
4. Check Lambda configuration (memory, timeout, permissions)
5. Review recent code deployments
6. Check downstream service health
7. Implement fix and monitor

### Workflow 2: Increased Latency

**MCP Servers**: CloudWatch MCP, CloudWatch Application Signals MCP

**Steps**:
1. Identify latency spike in CloudWatch metrics
2. Check service map for slow dependencies
3. Query distributed traces for slow requests
4. Check database query performance
5. Review API Gateway integration latency
6. Check Lambda cold starts
7. Identify bottleneck and optimize

### Workflow 3: Cost Spike Investigation

**MCP Servers**: Cost Explorer MCP, CloudWatch MCP, CloudTrail MCP

**Steps**:
1. Use Cost Explorer to identify service causing spike
2. Check CloudWatch metrics for usage increase
3. Review CloudTrail for recent resource creation
4. Identify root cause (misconfiguration, runaway process, attack)
5. Implement cost controls (budgets, alarms, service quotas)
6. Clean up unnecessary resources

### Workflow 4: Security Incident Response

**MCP Servers**: CloudTrail MCP, GuardDuty (via CloudWatch), Well-Architected Assessment MCP

**Steps**:
1. Identify security event in GuardDuty or CloudWatch
2. Query CloudTrail for related API activity
3. Determine scope and impact
4. Isolate affected resources
5. Revoke compromised credentials
6. Implement remediation
7. Conduct post-incident review
8. Update security controls

## Summary

- **Cost Optimization**: Use Pricing, Cost Explorer, and Billing MCPs for proactive cost management
- **Monitoring**: Set up comprehensive CloudWatch alarms for all critical services
- **Observability**: Implement distributed tracing and structured logging
- **Security**: Regular CloudTrail audits and Well-Architected assessments
- **Proactive**: Don't wait for incidents - monitor and optimize continuously
