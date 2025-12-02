# Event-Driven Architecture Patterns

Comprehensive patterns for building event-driven systems on AWS with serverless technologies.

## Table of Contents

- [Core EDA Concepts](#core-eda-concepts)
- [Event Routing Patterns](#event-routing-patterns)
- [Event Processing Patterns](#event-processing-patterns)
- [Event Sourcing Patterns](#event-sourcing-patterns)
- [Saga Patterns](#saga-patterns)
- [Best Practices](#best-practices)

## Core EDA Concepts

### Event Types

**Domain Events**: Represent business facts
```json
{
  "source": "orders",
  "detailType": "OrderPlaced",
  "detail": {
    "orderId": "12345",
    "customerId": "customer-1",
    "amount": 100.00,
    "timestamp": "2025-01-15T10:30:00Z"
  }
}
```

**System Events**: Technical occurrences
```json
{
  "source": "aws.s3",
  "detailType": "Object Created",
  "detail": {
    "bucket": "my-bucket",
    "key": "data/file.json"
  }
}
```

### Event Contracts

Define clear contracts between producers and consumers:

```typescript
// schemas/order-events.ts
export interface OrderPlacedEvent {
  orderId: string;
  customerId: string;
  items: Array<{
    productId: string;
    quantity: number;
    price: number;
  }>;
  totalAmount: number;
  timestamp: string;
}

// Register schema with EventBridge
const registry = new events.EventBusSchemaRegistry(this, 'SchemaRegistry');

const schema = new events.Schema(this, 'OrderPlacedSchema', {
  schemaName: 'OrderPlaced',
  definition: events.SchemaDefinition.fromInline(/* JSON Schema */),
});
```

## Event Routing Patterns

### Pattern 1: Content-Based Routing

Route events based on content:

```typescript
// Route by order amount
new events.Rule(this, 'HighValueOrders', {
  eventPattern: {
    source: ['orders'],
    detailType: ['OrderPlaced'],
    detail: {
      totalAmount: [{ numeric: ['>', 1000] }],
    },
  },
  targets: [new targets.LambdaFunction(highValueOrderFunction)],
});

new events.Rule(this, 'StandardOrders', {
  eventPattern: {
    source: ['orders'],
    detailType: ['OrderPlaced'],
    detail: {
      totalAmount: [{ numeric: ['<=', 1000] }],
    },
  },
  targets: [new targets.LambdaFunction(standardOrderFunction)],
});
```

### Pattern 2: Event Filtering

Filter events before processing:

```typescript
// Filter by multiple criteria
new events.Rule(this, 'FilteredRule', {
  eventPattern: {
    source: ['inventory'],
    detailType: ['StockUpdate'],
    detail: {
      warehouseId: ['WH-1', 'WH-2'], // Specific warehouses
      quantity: [{ numeric: ['<', 10] }], // Low stock only
      productCategory: ['electronics'], // Specific category
    },
  },
  targets: [new targets.LambdaFunction(reorderFunction)],
});
```

### Pattern 3: Event Replay and Archive

Store events for replay and audit:

```typescript
// Archive all events
const archive = new events.Archive(this, 'EventArchive', {
  eventPattern: {
    account: [this.account],
  },
  retention: Duration.days(365),
});

// Replay events when needed
// Use AWS Console or CLI to replay from archive
```

### Pattern 4: Cross-Account Event Routing

Route events to other AWS accounts:

```typescript
// Event bus in Account A
const eventBus = new events.EventBus(this, 'SharedBus');

// Grant permission to Account B
eventBus.addToResourcePolicy(new iam.PolicyStatement({
  effect: iam.Effect.ALLOW,
  principals: [new iam.AccountPrincipal('ACCOUNT-B-ID')],
  actions: ['events:PutEvents'],
  resources: [eventBus.eventBusArn],
}));

// Rule forwards to Account B event bus
new events.Rule(this, 'ForwardToAccountB', {
  eventBus,
  eventPattern: {
    source: ['shared-service'],
  },
  targets: [new targets.EventBus(
    events.EventBus.fromEventBusArn(
      this,
      'AccountBBus',
      'arn:aws:events:us-east-1:ACCOUNT-B-ID:event-bus/default'
    )
  )],
});
```

## Event Processing Patterns

### Pattern 1: Event Transformation

Transform events before routing:

```typescript
// EventBridge input transformer
new events.Rule(this, 'TransformRule', {
  eventPattern: {
    source: ['orders'],
  },
  targets: [new targets.LambdaFunction(processFunction, {
    event: events.RuleTargetInput.fromObject({
      orderId: events.EventField.fromPath('$.detail.orderId'),
      customerEmail: events.EventField.fromPath('$.detail.customer.email'),
      amount: events.EventField.fromPath('$.detail.totalAmount'),
      // Transformed structure
    }),
  })],
});
```

### Pattern 2: Event Aggregation

Aggregate multiple events:

```typescript
// DynamoDB stores partial results
export const handler = async (event: any) => {
  const { transactionId, step, data } = event;

  // Store step result
  await dynamodb.updateItem({
    TableName: process.env.TABLE_NAME,
    Key: { transactionId },
    UpdateExpression: 'SET #step = :data',
    ExpressionAttributeNames: { '#step': step },
    ExpressionAttributeValues: { ':data': data },
  });

  // Check if all steps complete
  const item = await dynamodb.getItem({
    TableName: process.env.TABLE_NAME,
    Key: { transactionId },
  });

  if (allStepsComplete(item)) {
    // Trigger final processing
    await eventBridge.putEvents({
      Entries: [{
        Source: 'aggregator',
        DetailType: 'AllStepsComplete',
        Detail: JSON.stringify(item),
      }],
    });
  }
};
```

### Pattern 3: Event Enrichment

Enrich events with additional data:

```typescript
export const enrichEvent = async (event: any) => {
  const { customerId } = event.detail;

  // Fetch additional customer data
  const customer = await dynamodb.getItem({
    TableName: process.env.CUSTOMER_TABLE,
    Key: { customerId },
  });

  // Publish enriched event
  await eventBridge.putEvents({
    Entries: [{
      Source: 'orders',
      DetailType: 'OrderEnriched',
      Detail: JSON.stringify({
        ...event.detail,
        customerName: customer.Item?.name,
        customerTier: customer.Item?.tier,
        customerEmail: customer.Item?.email,
      }),
    }],
  });
};
```

### Pattern 4: Event Fork and Join

Process event multiple ways then aggregate:

```typescript
// Step Functions parallel + aggregation
const parallel = new stepfunctions.Parallel(this, 'ForkProcessing');

parallel.branch(new tasks.LambdaInvoke(this, 'ValidateInventory', {
  lambdaFunction: inventoryFunction,
  resultPath: '$.inventory',
}));

parallel.branch(new tasks.LambdaInvoke(this, 'CheckCredit', {
  lambdaFunction: creditFunction,
  resultPath: '$.credit',
}));

parallel.branch(new tasks.LambdaInvoke(this, 'CalculateShipping', {
  lambdaFunction: shippingFunction,
  resultPath: '$.shipping',
}));

const definition = parallel.next(
  new tasks.LambdaInvoke(this, 'AggregateResults', {
    lambdaFunction: aggregateFunction,
  })
);
```

## Event Sourcing Patterns

### Pattern: Event Store with DynamoDB

Store all events as source of truth:

```typescript
const eventStore = new dynamodb.Table(this, 'EventStore', {
  partitionKey: { name: 'aggregateId', type: dynamodb.AttributeType.STRING },
  sortKey: { name: 'version', type: dynamodb.AttributeType.NUMBER },
  stream: dynamodb.StreamViewType.NEW_IMAGE,
  pointInTimeRecovery: true, // Important for audit
});

// Append events
export const appendEvent = async (aggregateId: string, event: any) => {
  const version = await getNextVersion(aggregateId);

  await dynamodb.putItem({
    TableName: process.env.EVENT_STORE,
    Item: {
      aggregateId,
      version,
      eventType: event.type,
      eventData: event.data,
      timestamp: Date.now(),
      userId: event.userId,
    },
    ConditionExpression: 'attribute_not_exists(version)', // Optimistic locking
  });
};

// Rebuild state from events
export const rebuildState = async (aggregateId: string) => {
  const events = await dynamodb.query({
    TableName: process.env.EVENT_STORE,
    KeyConditionExpression: 'aggregateId = :id',
    ExpressionAttributeValues: { ':id': aggregateId },
    ScanIndexForward: true, // Chronological order
  });

  let state = initialState();
  for (const event of events.Items) {
    state = applyEvent(state, event);
  }

  return state;
};
```

### Pattern: Materialized Views

Create read-optimized projections:

```typescript
// Event store stream triggers projection
eventStore.grantStreamRead(projectionFunction);

new lambda.EventSourceMapping(this, 'Projection', {
  target: projectionFunction,
  eventSourceArn: eventStore.tableStreamArn,
  startingPosition: lambda.StartingPosition.LATEST,
});

// Projection function updates read model
export const updateProjection = async (event: DynamoDBStreamEvent) => {
  for (const record of event.Records) {
    if (record.eventName !== 'INSERT') continue;

    const eventData = record.dynamodb?.NewImage;
    const aggregateId = eventData?.aggregateId.S;

    // Rebuild current state
    const currentState = await rebuildState(aggregateId);

    // Update read model
    await readModelTable.putItem({
      TableName: process.env.READ_MODEL_TABLE,
      Item: currentState,
    });
  }
};
```

### Pattern: Snapshots

Optimize event replay with snapshots:

```typescript
export const createSnapshot = async (aggregateId: string) => {
  // Rebuild state from all events
  const state = await rebuildState(aggregateId);
  const version = await getLatestVersion(aggregateId);

  // Store snapshot
  await snapshotTable.putItem({
    TableName: process.env.SNAPSHOT_TABLE,
    Item: {
      aggregateId,
      version,
      state: JSON.stringify(state),
      createdAt: Date.now(),
    },
  });
};

// Rebuild from snapshot + newer events
export const rebuildFromSnapshot = async (aggregateId: string) => {
  // Get latest snapshot
  const snapshot = await getLatestSnapshot(aggregateId);

  let state = JSON.parse(snapshot.state);
  const snapshotVersion = snapshot.version;

  // Apply only events after snapshot
  const events = await getEventsSinceVersion(aggregateId, snapshotVersion);

  for (const event of events) {
    state = applyEvent(state, event);
  }

  return state;
};
```

## Saga Patterns

### Pattern: Choreography-Based Saga

Services coordinate through events:

```typescript
// Order Service publishes event
export const placeOrder = async (order: Order) => {
  await saveOrder(order);

  await eventBridge.putEvents({
    Entries: [{
      Source: 'orders',
      DetailType: 'OrderPlaced',
      Detail: JSON.stringify({ orderId: order.id }),
    }],
  });
};

// Inventory Service reacts to event
new events.Rule(this, 'ReserveInventory', {
  eventPattern: {
    source: ['orders'],
    detailType: ['OrderPlaced'],
  },
  targets: [new targets.LambdaFunction(reserveInventoryFunction)],
});

// Inventory Service publishes result
export const reserveInventory = async (event: any) => {
  const { orderId } = event.detail;

  try {
    await reserve(orderId);

    await eventBridge.putEvents({
      Entries: [{
        Source: 'inventory',
        DetailType: 'InventoryReserved',
        Detail: JSON.stringify({ orderId }),
      }],
    });
  } catch (error) {
    await eventBridge.putEvents({
      Entries: [{
        Source: 'inventory',
        DetailType: 'InventoryReservationFailed',
        Detail: JSON.stringify({ orderId, error: error.message }),
      }],
    });
  }
};

// Payment Service reacts to inventory event
new events.Rule(this, 'ProcessPayment', {
  eventPattern: {
    source: ['inventory'],
    detailType: ['InventoryReserved'],
  },
  targets: [new targets.LambdaFunction(processPaymentFunction)],
});
```

### Pattern: Orchestration-Based Saga

Central coordinator manages saga:

```typescript
// Step Functions orchestrates saga
const definition = new tasks.LambdaInvoke(this, 'ReserveInventory', {
  lambdaFunction: reserveInventoryFunction,
  resultPath: '$.inventory',
})
  .next(new tasks.LambdaInvoke(this, 'ProcessPayment', {
    lambdaFunction: processPaymentFunction,
    resultPath: '$.payment',
  }))
  .next(new tasks.LambdaInvoke(this, 'ShipOrder', {
    lambdaFunction: shipOrderFunction,
    resultPath: '$.shipment',
  }))
  .addCatch(
    // Compensation flow
    new tasks.LambdaInvoke(this, 'RefundPayment', {
      lambdaFunction: refundFunction,
    })
      .next(new tasks.LambdaInvoke(this, 'ReleaseInventory', {
        lambdaFunction: releaseFunction,
      })),
    {
      errors: ['States.TaskFailed'],
      resultPath: '$.error',
    }
  );

new stepfunctions.StateMachine(this, 'OrderSaga', {
  definition,
  tracingEnabled: true,
});
```

**Comparison**:

| Aspect | Choreography | Orchestration |
|--------|--------------|---------------|
| Coordination | Decentralized | Centralized |
| Coupling | Loose | Tighter |
| Visibility | Distributed logs | Single execution history |
| Debugging | Harder (trace across services) | Easier (single workflow) |
| Best for | Simple flows | Complex flows |

## Best Practices

### Idempotency

**Always make event handlers idempotent**:

```typescript
// Use idempotency keys
export const handler = async (event: any) => {
  const idempotencyKey = event.requestId || event.messageId;

  // Check if already processed
  try {
    const existing = await dynamodb.getItem({
      TableName: process.env.IDEMPOTENCY_TABLE,
      Key: { idempotencyKey },
    });

    if (existing.Item) {
      console.log('Already processed:', idempotencyKey);
      return existing.Item.result; // Return cached result
    }
  } catch (error) {
    // First time processing
  }

  // Process event
  const result = await processEvent(event);

  // Store result
  await dynamodb.putItem({
    TableName: process.env.IDEMPOTENCY_TABLE,
    Item: {
      idempotencyKey,
      result,
      processedAt: Date.now(),
    },
    // Optional: Set TTL for cleanup
    ExpirationTime: Math.floor(Date.now() / 1000) + 86400, // 24 hours
  });

  return result;
};
```

### Event Versioning

**Handle event schema evolution**:

```typescript
// Version events
interface OrderPlacedEventV1 {
  version: '1.0';
  orderId: string;
  amount: number;
}

interface OrderPlacedEventV2 {
  version: '2.0';
  orderId: string;
  amount: number;
  currency: string; // New field
}

// Handler supports multiple versions
export const handler = async (event: any) => {
  const eventVersion = event.detail.version || '1.0';

  switch (eventVersion) {
    case '1.0':
      return processV1(event.detail as OrderPlacedEventV1);
    case '2.0':
      return processV2(event.detail as OrderPlacedEventV2);
    default:
      throw new Error(`Unsupported event version: ${eventVersion}`);
  }
};

const processV1 = async (event: OrderPlacedEventV1) => {
  // Upgrade to V2 internally
  const v2Event: OrderPlacedEventV2 = {
    ...event,
    version: '2.0',
    currency: 'USD', // Default value
  };
  return processV2(v2Event);
};
```

### Eventual Consistency

**Design for eventual consistency**:

```typescript
// Service A writes to its database
export const createOrder = async (order: Order) => {
  // Write to Order database
  await orderTable.putItem({ Item: order });

  // Publish event
  await eventBridge.putEvents({
    Entries: [{
      Source: 'orders',
      DetailType: 'OrderCreated',
      Detail: JSON.stringify({ orderId: order.id }),
    }],
  });
};

// Service B eventually updates its database
export const onOrderCreated = async (event: any) => {
  const { orderId } = event.detail;

  // Fetch additional data
  const orderDetails = await getOrderDetails(orderId);

  // Update inventory database (eventual consistency)
  await inventoryTable.updateItem({
    Key: { productId: orderDetails.productId },
    UpdateExpression: 'SET reserved = reserved + :qty',
    ExpressionAttributeValues: { ':qty': orderDetails.quantity },
  });
};
```

### Error Handling in EDA

**Comprehensive error handling strategy**:

```typescript
// Dead Letter Queue for failed events
const dlq = new sqs.Queue(this, 'EventDLQ', {
  retentionPeriod: Duration.days(14),
});

// EventBridge rule with DLQ
new events.Rule(this, 'ProcessRule', {
  eventPattern: { /* ... */ },
  targets: [
    new targets.LambdaFunction(processFunction, {
      deadLetterQueue: dlq,
      maxEventAge: Duration.hours(2),
      retryAttempts: 2,
    }),
  ],
});

// Monitor DLQ
new cloudwatch.Alarm(this, 'DLQAlarm', {
  metric: dlq.metricApproximateNumberOfMessagesVisible(),
  threshold: 1,
  evaluationPeriods: 1,
});

// DLQ processor for manual review
new lambda.EventSourceMapping(this, 'DLQProcessor', {
  target: dlqProcessorFunction,
  eventSourceArn: dlq.queueArn,
  enabled: false, // Enable manually when reviewing
});
```

### Message Ordering

**When order matters**:

```typescript
// SQS FIFO for strict ordering
const fifoQueue = new sqs.Queue(this, 'OrderedQueue', {
  fifo: true,
  contentBasedDeduplication: true,
  deduplicationScope: sqs.DeduplicationScope.MESSAGE_GROUP,
  fifoThroughputLimit: sqs.FifoThroughputLimit.PER_MESSAGE_GROUP_ID,
});

// Publish with message group ID
await sqs.sendMessage({
  QueueUrl: process.env.QUEUE_URL,
  MessageBody: JSON.stringify(event),
  MessageGroupId: customerId, // All messages for same customer in order
  MessageDeduplicationId: eventId, // Prevent duplicates
});

// Kinesis for ordered streams
const stream = new kinesis.Stream(this, 'Stream', {
  shardCount: 1, // Single shard = strict ordering
});

// Partition key ensures same partition
await kinesis.putRecord({
  StreamName: process.env.STREAM_NAME,
  Data: Buffer.from(JSON.stringify(event)),
  PartitionKey: customerId, // Same key = same shard
});
```

### Deduplication

**Prevent duplicate event processing**:

```typescript
// Content-based deduplication with SQS FIFO
const queue = new sqs.Queue(this, 'Queue', {
  fifo: true,
  contentBasedDeduplication: true, // Hash of message body
});

// Manual deduplication with DynamoDB
export const handler = async (event: any) => {
  const eventId = event.id || event.messageId;

  try {
    // Conditional write (fails if exists)
    await dynamodb.putItem({
      TableName: process.env.DEDUP_TABLE,
      Item: {
        eventId,
        processedAt: Date.now(),
        ttl: Math.floor(Date.now() / 1000) + 86400, // 24h TTL
      },
      ConditionExpression: 'attribute_not_exists(eventId)',
    });

    // Event is unique, process it
    await processEvent(event);
  } catch (error) {
    if (error.code === 'ConditionalCheckFailedException') {
      console.log('Duplicate event ignored:', eventId);
      return; // Already processed
    }
    throw error; // Other error
  }
};
```

### Backpressure Handling

**Prevent overwhelming downstream systems**:

```typescript
// Control Lambda concurrency
const consumerFunction = new lambda.Function(this, 'Consumer', {
  reservedConcurrentExecutions: 10, // Max 10 concurrent
});

// SQS visibility timeout + retry logic
const queue = new sqs.Queue(this, 'Queue', {
  visibilityTimeout: Duration.seconds(300), // 5 minutes
  receiveMessageWaitTime: Duration.seconds(20), // Long polling
});

new lambda.EventSourceMapping(this, 'Consumer', {
  target: consumerFunction,
  eventSourceArn: queue.queueArn,
  batchSize: 10,
  maxConcurrency: 5, // Process 5 batches concurrently
  reportBatchItemFailures: true,
});

// Circuit breaker pattern
let consecutiveFailures = 0;
const FAILURE_THRESHOLD = 5;

export const handler = async (event: any) => {
  // Check circuit breaker
  if (consecutiveFailures >= FAILURE_THRESHOLD) {
    console.error('Circuit breaker open, skipping processing');
    throw new Error('Circuit breaker open');
  }

  try {
    await processEvent(event);
    consecutiveFailures = 0; // Reset on success
  } catch (error) {
    consecutiveFailures++;
    throw error;
  }
};
```

## Advanced Patterns

### Pattern: Event Replay

Replay events for recovery or testing:

```typescript
// Archive events for replay
const archive = new events.Archive(this, 'Archive', {
  sourceEventBus: eventBus,
  eventPattern: {
    account: [this.account],
  },
  retention: Duration.days(365),
});

// Replay programmatically
export const replayEvents = async (startTime: Date, endTime: Date) => {
  // Use AWS SDK to start replay
  await eventBridge.startReplay({
    ReplayName: `replay-${Date.now()}`,
    EventSourceArn: archive.archiveArn,
    EventStartTime: startTime,
    EventEndTime: endTime,
    Destination: {
      Arn: eventBus.eventBusArn,
    },
  });
};
```

### Pattern: Event Time vs Processing Time

Handle late-arriving events:

```typescript
// Include event timestamp
interface Event {
  eventId: string;
  eventTime: string; // When event occurred
  processingTime?: string; // When event processed
  data: any;
}

// Windowed aggregation
export const aggregateWindow = async (events: Event[]) => {
  // Group by event time window (not processing time)
  const windows = new Map<string, Event[]>();

  for (const event of events) {
    const window = getWindowForTime(new Date(event.eventTime), Duration.minutes(5));
    const key = window.toISOString();

    if (!windows.has(key)) {
      windows.set(key, []);
    }
    windows.get(key)!.push(event);
  }

  // Process each window
  for (const [window, eventsInWindow] of windows) {
    await processWindow(window, eventsInWindow);
  }
};
```

### Pattern: Transactional Outbox

Ensure event publishing with database writes:

```typescript
// Single DynamoDB transaction
export const createOrderWithEvent = async (order: Order) => {
  await dynamodb.transactWriteItems({
    TransactItems: [
      {
        // Write order
        Put: {
          TableName: process.env.ORDERS_TABLE,
          Item: marshall(order),
        },
      },
      {
        // Write outbox event
        Put: {
          TableName: process.env.OUTBOX_TABLE,
          Item: marshall({
            eventId: uuid(),
            eventType: 'OrderPlaced',
            eventData: order,
            status: 'PENDING',
            createdAt: Date.now(),
          }),
        },
      },
    ],
  });
};

// Separate Lambda processes outbox
new lambda.EventSourceMapping(this, 'OutboxProcessor', {
  target: outboxFunction,
  eventSourceArn: outboxTable.tableStreamArn,
  startingPosition: lambda.StartingPosition.LATEST,
});

export const processOutbox = async (event: DynamoDBStreamEvent) => {
  for (const record of event.Records) {
    if (record.eventName !== 'INSERT') continue;

    const outboxEvent = unmarshall(record.dynamodb?.NewImage);

    // Publish to EventBridge
    await eventBridge.putEvents({
      Entries: [{
        Source: 'orders',
        DetailType: outboxEvent.eventType,
        Detail: JSON.stringify(outboxEvent.eventData),
      }],
    });

    // Mark as processed
    await dynamodb.updateItem({
      TableName: process.env.OUTBOX_TABLE,
      Key: { eventId: outboxEvent.eventId },
      UpdateExpression: 'SET #status = :status',
      ExpressionAttributeNames: { '#status': 'status' },
      ExpressionAttributeValues: { ':status': 'PUBLISHED' },
    });
  }
};
```

## Testing Event-Driven Systems

### Pattern: Event Replay for Testing

```typescript
// Publish test events
export const publishTestEvents = async () => {
  const testEvents = [
    { source: 'orders', detailType: 'OrderPlaced', detail: { orderId: '1' } },
    { source: 'orders', detailType: 'OrderPlaced', detail: { orderId: '2' } },
  ];

  for (const event of testEvents) {
    await eventBridge.putEvents({ Entries: [event] });
  }
};

// Monitor processing
export const verifyProcessing = async () => {
  // Check downstream databases
  const order1 = await orderTable.getItem({ Key: { orderId: '1' } });
  const order2 = await orderTable.getItem({ Key: { orderId: '2' } });

  expect(order1.Item).toBeDefined();
  expect(order2.Item).toBeDefined();
};
```

### Pattern: Event Mocking

```typescript
// Mock EventBridge in tests
const mockEventBridge = {
  putEvents: jest.fn().mockResolvedValue({}),
};

// Test event publishing
test('publishes event on order creation', async () => {
  await createOrder(mockEventBridge, order);

  expect(mockEventBridge.putEvents).toHaveBeenCalledWith({
    Entries: [
      expect.objectContaining({
        Source: 'orders',
        DetailType: 'OrderPlaced',
      }),
    ],
  });
});
```

## Summary

- **Loose Coupling**: Services communicate via events, not direct calls
- **Async Processing**: Use queues and event buses for asynchronous workflows
- **Idempotency**: Always handle duplicate events gracefully
- **Dead Letter Queues**: Configure DLQs for error handling
- **Event Contracts**: Define clear schemas for events
- **Observability**: Enable tracing and monitoring across services
- **Eventual Consistency**: Design for it, don't fight it
- **Saga Patterns**: Use for distributed transactions
- **Event Sourcing**: Store events as source of truth when needed
