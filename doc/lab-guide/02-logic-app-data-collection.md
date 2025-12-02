# Lab 02: Logic App Telemetry Generation & Data Collection

**Estimated Time**: 45-60 minutes

## Learning Objectives

By the end of this lab, you will be able to:

- ✅ Understand how Azure Logic Apps generate diagnostic logs
- ✅ Modify a timer-triggered workflow to customize telemetry generation
- ✅ Query workflow execution data in Log Analytics using KQL
- ✅ Adjust error rates and observe the impact on monitoring data
- ✅ Create custom event types and properties for business scenarios
- ✅ Validate data flow from Logic Apps to Service Bus to Log Analytics

## Prerequisites

- Completed Lab 01: Setup and Infrastructure Deployment
- Access to the Azure Portal
- Deployed Azure Monitor Lab infrastructure
- **IMPORTANT**: Authorized the Service Bus API connection (one-time setup - see below)
- Familiarity with JSON structure (helpful but not required)

### One-Time Setup: Authorize Service Bus Connection

After deploying the infrastructure, you need to authorize the Logic App's connection to Service Bus. This is a one-time step.

**Steps**:
1. After running the deployment script, note the output message with the connection name (e.g., `logic-azmonlab-dev-servicebus-connection`)
2. Navigate to the [Azure Portal](https://portal.azure.com)
3. Go to your resource group (e.g., `rg-azmonlab`)
4. Find the API Connection resource with the name from step 1
5. Click on the connection resource
6. In the left menu, click **Edit API connection**
7. You should see the **Connection String** field is populated
8. **Important**: Even though the connection string is there, click **Save** at the bottom
   - This authorizes the connection and enables the Logic App to use it
9. Return to the Logic App and verify runs are succeeding

**Validation**: 
- Go to the Logic App → Runs history
- Recent runs should show **Succeeded** status
- If runs show **Failed** with "401 Unauthorized", repeat the authorization steps above

**Why is this needed?** Azure requires explicit authorization for API connections created via infrastructure-as-code for security reasons. This one-time step grants the Logic App permission to use the connection.

## Overview

In this lab, you'll work with a **timer-triggered Logic App** that automatically generates telemetry every 30 seconds. The Logic App creates diverse message payloads (orders, logins, health checks) and sends them to an Azure Service Bus queue. This simulates a real-world event-driven system and provides rich data for monitoring and analysis.

### Architecture

```
┌─────────────────────────────────────┐
│  Logic App: Telemetry Generator     │
│  ┌──────────────────────────────┐   │
│  │ Recurrence Trigger (30s)     │   │
│  └──────────┬───────────────────┘   │
│             ▼                       │
│  ┌──────────────────────────────┐   │
│  │ Initialize Variables         │   │
│  │ - Event Types Array          │   │
│  │ - Regions Array              │   │
│  └──────────┬───────────────────┘   │
│             ▼                       │
│  ┌──────────────────────────────┐   │
│  │ Generate Payload             │   │
│  │ - Random event type          │   │
│  │ - Random severity            │   │
│  │ - Business properties        │   │
│  └──────────┬───────────────────┘   │
│             ▼                       │
│  ┌──────────────────────────────┐   │
│  │ Send to Service Bus Queue    │   │
│  └──────────────────────────────┘   │
└─────────────┬───────────────────────┘
              │
              ▼
    ┌─────────────────────┐
    │ Service Bus Queue   │
    │ "lab-queue"         │
    └─────────┬───────────┘
              │
              ▼ (Diagnostic Logs)
    ┌─────────────────────┐
    │ Log Analytics       │
    │ Workspace           │
    └─────────────────────┘
```

## Part 1: Understanding the Logic App Workflow

### Step 1: Open the Logic App in Azure Portal

1. Navigate to the [Azure Portal](https://portal.azure.com)
2. Go to your resource group (`rg-azmonlab` or your configured name)
3. Find and click on the Logic App resource named `logic-azmonlab-dev`
4. In the left menu, click **Logic app designer**

### Step 2: Explore the Workflow Components

You should see a workflow with several steps. Let's understand each one:

#### 🔄 Recurrence Trigger
- **What it does**: Starts the workflow automatically every 30 seconds
- **Configuration**: Frequency = `Second`, Interval = `30`
- **Why it matters**: Provides continuous telemetry without manual intervention

#### 📋 Initialize Variables (Event Types)
- **What it does**: Creates an array of possible event types
- **Default values**: `order.created`, `user.login`, `system.health`, `data.sync`
- **Why it matters**: Provides variety in telemetry data

#### 🌍 Initialize Variables (Regions)
- **What it does**: Creates an array of Azure regions
- **Default values**: `australiaeast`, `eastus`, `westeurope`
- **Why it matters**: Simulates multi-region deployments

#### 🎲 Generate Payload
- **What it does**: Creates a JSON message with random values
- **Components**:
  - `eventId`: Unique identifier (GUID)
  - `eventType`: Randomly selected from eventTypes array
  - `timestamp`: Current UTC time
  - `severity`: Randomly assigned (Info/Warning/Error)
  - `properties`: Business data (orderId, amount, region)

#### 📤 Send Message to Service Bus
- **What it does**: Sends the generated payload to `lab-queue`
- **Result**: Message available for Function Apps to process
- **Logs**: Execution details sent to Log Analytics

### Step 3: View a Recent Workflow Run

1. In the Logic App overview, click **Runs history**
2. You should see runs executing every 30 seconds
3. Click on the most recent **Succeeded** run
4. Review the execution flow:
   - Green checkmarks ✅ = Successful steps
   - Each step shows inputs and outputs
5. Click **Generate_Payload** to see the created message
6. Note the random values generated

**Expected Output Example**:
```json
{
  "eventId": "a3d5e9f1-2b4c-4d8e-9f1a-3b5c7d9e1f2a",
  "eventType": "order.created",
  "timestamp": "2025-12-01T14:35:22Z",
  "severity": "Info",
  "properties": {
    "orderId": 3456,
    "amount": 287,
    "region": "australiaeast"
  }
}
```

## Part 2: Querying Logic App Telemetry in Log Analytics

### Step 4: Open Log Analytics Workspace

1. Return to your resource group
2. Click on the Log Analytics workspace (`law-azmonlab-dev`)
3. In the left menu, click **Logs**
4. Close the welcome dialog if it appears

### Step 5: Basic Workflow Queries

#### Query 1: View All Logic App Runs (Last Hour)

```kql
// Query: Recent Logic App workflow runs
AzureDiagnostics
| where ResourceType == "WORKFLOWS"
| where TimeGenerated > ago(1h)
| project TimeGenerated, resource_workflowName_s, status_s, resource_runId_s
| order by TimeGenerated desc
| take 20
```

**What to look for**:
- `status_s` should be mostly `Succeeded`
- Runs should appear every ~30 seconds
- `resource_workflowName_s` shows your Logic App name

**Click "Run"** to execute the query.

#### Query 2: Count Successful vs. Failed Runs

```kql
// Query: Workflow run status distribution
AzureDiagnostics
| where ResourceType == "WORKFLOWS"
| where TimeGenerated > ago(1h)
| summarize Count = count() by status_s
| render piechart
```

**Expected Results**:
- Mostly `Succeeded` (if everything is working correctly)
- Occasional failures are normal in production scenarios

#### Query 3: Workflow Run Frequency

```kql
// Query: Workflow runs over time (5-minute bins)
AzureDiagnostics
| where ResourceType == "WORKFLOWS"
| where TimeGenerated > ago(1h)
| summarize RunCount = count() by bin(TimeGenerated, 5m)
| render timechart
```

**What you should see**:
- Consistent pattern of runs
- ~10 runs per 5-minute window (30-second interval = 2/minute × 5 = 10)

### Step 6: Validate Service Bus Message Delivery

1. Navigate to your Service Bus namespace (`sb-azmonlab-dev`)
2. In the left menu, click **Queues**
3. Click on `lab-queue`
4. Under **Essentials**, check **Active message count**
   - If no Function App is consuming, this will grow
   - If growing, messages are being delivered ✅

5. Click **Service Bus Explorer (preview)**
6. Click **Peek from start**
7. Select a message to view its content
8. You should see the JSON payload generated by Logic App

**Validation**: If you see messages with eventId, eventType, timestamp, and severity, the Logic App is working correctly! ✅

## Part 3: Interactive Exercises - Customizing Telemetry

Now it's time to make the Logic App your own! You'll modify the workflow to generate different types of telemetry.

### Exercise 1: Add Your Own Event Type (5 minutes)

**Goal**: Add a custom event type to simulate a business scenario.

**Steps**:

1. In the Logic App designer, click **Edit** (top toolbar)
2. Expand the **Initialize variable - eventTypes** step
3. Find the `value` array with event types
4. Click **Add new item** (or edit the JSON directly)
5. Add one of these custom event types (or create your own):
   - `customer.registered`
   - `payment.failed`
   - `inventory.updated`
   - `shipment.dispatched`

6. Click **Save** (top toolbar)
7. Wait 30-60 seconds for the next runs

**Validation Query**:
```kql
// Query: Find your custom event type
AzureDiagnostics
| where ResourceType == "WORKFLOWS"
| where TimeGenerated > ago(5m)
| project TimeGenerated, resource_actionName_s, code_s
| where resource_actionName_s contains "Generate_Payload"
| take 10
```

Then check Service Bus Explorer for messages containing your new event type.

**Discussion Question**: Why might you want different event types in a real system?

<details>
<summary>Click to reveal answer</summary>

Different event types allow you to:
- Track distinct business processes (orders vs. logins)
- Create targeted alerts for critical events
- Build dashboards grouped by event category
- Analyze patterns in specific workflows
- Route events to different consumers

</details>

---

### Exercise 2: Increase Error Rate (10 minutes)

**Goal**: Simulate a degraded system by increasing error frequency.

**Current State**: ~20% of messages have `Error` severity (random threshold > 80)

**Your Task**: Increase error rate to ~50%

**Steps**:

1. In the Logic App designer, expand **Generate_Payload**
2. Find the `severity` expression:
   ```
   @{if(greater(rand(1, 100), 80), 'Error', if(greater(rand(1, 100), 60), 'Warning', 'Info'))}
   ```
3. Click **Edit** on the Compose action
4. Modify the threshold from `80` to `50`:
   ```
   @{if(greater(rand(1, 100), 50), 'Error', if(greater(rand(1, 100), 30), 'Warning', 'Info'))}
   ```
   **Explanation**: 
   - `> 50` = 50% Error
   - `> 30` = 20% Warning  
   - `≤ 30` = 30% Info

5. Click **OK**, then **Save**
6. Wait 2-3 minutes for data to accumulate

**Validation Query**:
```kql
// Query: Severity distribution in Service Bus messages
// Note: This queries the messages if they're logged, or check Service Bus directly
AzureDiagnostics
| where ResourceType == "WORKFLOWS"
| where TimeGenerated > ago(5m)
| where resource_actionName_s == "Send_Message"
| summarize Count = count() by status_s
```

**Advanced Validation**: Check Service Bus Explorer messages manually for severity distribution.

**Reflection**: 
- How would high error rates appear in a production dashboard?
- What alerts would you set up for error rate thresholds?

---

### Exercise 3: Add Custom Business Properties (15 minutes)

**Goal**: Extend the payload with additional business-relevant data.

**Current Properties**:
- `orderId`: Random number (1000-9999)
- `amount`: Random number (10-500)
- `region`: Random from regions array

**Your Task**: Add one or more of these properties:

1. **Customer ID**: Random customer identifier
   ```json
   "customerId": @{concat('CUST-', rand(10000, 99999))}
   ```

2. **Product Category**: New variable with categories
   - Add new variable initialization: `productCategories` = `["Electronics", "Clothing", "Food", "Books"]`
   - Add to payload: 
     ```json
     "productCategory": @{variables('productCategories')[rand(0, length(variables('productCategories')))]}
     ```

3. **Success Flag**: Boolean indicating successful transaction
   ```json
   "success": @{if(equals(variables('severity'), 'Error'), false, true)}
   ```

**Steps**:

1. For new variables, click **+ New step** after existing variable initializations
2. Search for **Initialize variable**
3. Configure:
   - Name: `productCategories`
   - Type: `Array`
   - Value: Add items: `Electronics`, `Clothing`, `Food`, `Books`

4. Edit the **Generate_Payload** action
5. Add your new properties to the `properties` object
6. Click **Save**

**Validation**: Check Service Bus messages for new properties.

**Challenge**: Can you add a conditional property that only appears when severity is "Error"? (Hint: Use `if()` expressions)

---

### Exercise 4: Regional Analysis (10 minutes)

**Goal**: Add more regions and analyze geographic distribution.

**Steps**:

1. Edit the **Initialize variable - regions** step
2. Add these regions:
   - `southeastasia`
   - `uksouth`
   - `canadacentral`

3. Save the workflow
4. Wait 3-5 minutes for data accumulation

**Analysis Query**:
```kql
// Note: This query assumes you can access the message payload
// In practice, you'd query the Service Bus messages or downstream Function App logs
// For now, this demonstrates the pattern:

// If messages were logged to a custom table (future lab):
// CustomTelemetry
// | where TimeGenerated > ago(10m)
// | summarize EventCount = count() by region
// | render columnchart
```

**For now, validate by**:
1. Going to Service Bus Explorer
2. Peeking at 10-20 messages
3. Manually counting region distribution
4. Confirm you see new regions appearing

**Discussion**: In a real scenario, how could you use regional data for:
- Latency analysis?
- Cost allocation?
- Disaster recovery planning?

---

## Part 4: Understanding Diagnostic Settings

### Step 7: Review Logic App Diagnostic Configuration

1. In your Logic App, click **Diagnostic settings** (left menu)
2. Click on the existing setting (e.g., `logicapp-diagnostics`)
3. Review the configuration:
   - **Logs**: `WorkflowRuntime` (captures workflow execution)
   - **Metrics**: `AllMetrics` (performance counters)
   - **Destination**: Log Analytics workspace

**Key Insight**: This configuration ensures every workflow run is logged automatically!

### Step 8: Query Workflow Performance Metrics

```kql
// Query: Workflow execution duration
AzureDiagnostics
| where ResourceType == "WORKFLOWS"
| where TimeGenerated > ago(1h)
| where operationName_s == "Microsoft.Logic/workflows/workflowRunCompleted"
| extend DurationMs = todouble(properties_duration_s)
| summarize 
    AvgDuration = avg(DurationMs),
    P95Duration = percentile(DurationMs, 95),
    MaxDuration = max(DurationMs)
    by bin(TimeGenerated, 5m)
| render timechart
```

**What to look for**:
- Consistent execution times (typically < 5 seconds for this simple workflow)
- Spikes might indicate Service Bus throttling or Logic App cold starts

## Part 5: Troubleshooting Common Issues

### Issue 1: No Workflow Runs Appearing

**Symptoms**: Runs history is empty or very old

**Troubleshooting Steps**:
1. Check if Logic App is **Enabled** (Overview page)
2. Verify the Recurrence trigger is configured correctly (30 seconds)
3. Look for errors in the Logic App **Run history**
4. Check Azure Service Health for Logic Apps outages

**Solution**: If disabled, click **Enable** in the Overview page.

---

### Issue 2: All Runs Failing with 401 Unauthorized

**Symptoms**: Runs history shows failed executions with "401 Unauthorized" error related to Service Bus

**Root Cause**: The Service Bus API connection needs to be authorized in the Portal (one-time step)

**Troubleshooting Steps**:
1. Go to your resource group in Azure Portal
2. Find the API Connection resource (e.g., `logic-azmonlab-dev-servicebus-connection`)
3. Click **Edit API connection** in the left menu
4. Verify the **Connection String** field is populated
5. Click **Save** (even if no changes were made)
6. Wait 30-60 seconds
7. Check Logic App runs history - new runs should succeed

**Solution**: This is the authorization step described in Prerequisites. If the connection string field is empty:
1. Go to your Service Bus namespace
2. Click **Shared access policies** → **RootManageSharedAccessKey**
3. Copy the **Primary Connection String**
4. Return to the API connection → **Edit API connection**
5. Paste the connection string into the **Connection String** field
6. Click **Save**

---

### Issue 3: All Runs Failing (Other Causes)

**Symptoms**: Runs history shows all failed executions

**Troubleshooting Steps**:
1. Click on a failed run
2. Identify which step failed (red X icon)
3. Common causes:
   - **Service Bus connection error**: Check connection string
   - **Payload generation error**: Review expression syntax
   - **Permission issues**: Verify Logic App has access to Service Bus

**Solution**: Review error message and validate Service Bus connection in the workflow.

---

### Issue 4: Messages Not Appearing in Service Bus Queue

**Symptoms**: Workflow runs succeed, but queue is empty

**Troubleshooting Steps**:
1. Check if a Function App is consuming messages (expected behavior later)
2. Verify the **Send Message** action in successful runs shows the message was sent
3. Check Service Bus namespace is not throttled

**Solution**: If messages are being consumed by a Function App, this is expected behavior in later labs.

---

## Part 6: Advanced Challenge (Optional)

### Challenge: Build a Business Hours Filter

**Scenario**: Your organization only wants telemetry generated during business hours (9 AM - 5 PM UTC).

**Task**: Add a condition to the workflow that only generates messages during business hours.

**Hints**:
1. Use `utcNow()` to get current time
2. Use `formatDateTime()` to extract the hour
3. Add a **Condition** action after the Recurrence trigger
4. Only proceed with payload generation if hour is between 9 and 17

**Solution Structure**:
```
Recurrence Trigger
  ↓
Condition: Is Business Hours?
  ↓ (Yes)
Initialize Variables → Generate Payload → Send Message
  ↓ (No)
Terminate (Success)
```

**Expression Example**:
```
@and(greaterOrEquals(int(formatDateTime(utcNow(), 'HH')), 9), lessOrEquals(int(formatDateTime(utcNow(), 'HH')), 17))
```

**Test**: Change the time range to include the current hour and verify messages resume.

---

## Summary

In this lab, you:

- ✅ Explored a timer-triggered Logic App workflow
- ✅ Queried workflow execution logs in Log Analytics using KQL
- ✅ Modified event types to add custom business scenarios
- ✅ Adjusted error rates to simulate system degradation
- ✅ Added custom properties to enrich telemetry data
- ✅ Validated message delivery to Service Bus queue
- ✅ Understood how diagnostic settings enable automatic logging

### Key Takeaways

1. **Logic Apps generate rich diagnostic logs** automatically when diagnostic settings are configured
2. **Variables make workflows flexible** - easy to modify without code changes
3. **Expressions enable dynamic data generation** - `rand()`, `guid()`, `utcNow()` are powerful tools
4. **KQL is essential for querying telemetry** - you'll use it extensively in monitoring
5. **Service Bus provides decoupling** - message producers and consumers operate independently

### What's Next?

In **Lab 03: KQL Queries for Log Analysis**, you'll:
- Write more complex queries to analyze telemetry
- Correlate data across multiple resources
- Build aggregations and visualizations
- Create saved queries for reuse

---

## Additional Resources

- [Azure Logic Apps Documentation](https://learn.microsoft.com/azure/logic-apps/)
- [Workflow Expression Language Reference](https://learn.microsoft.com/azure/logic-apps/workflow-definition-language-functions-reference)
- [Azure Service Bus Queues](https://learn.microsoft.com/azure/service-bus-messaging/service-bus-queues-topics-subscriptions)
- [Log Analytics KQL Reference](https://learn.microsoft.com/azure/data-explorer/kusto/query/)

---

## Feedback

As you complete this lab, consider:
- Was the difficulty level appropriate?
- Did the exercises help you understand Logic Apps monitoring?
- What additional scenarios would be interesting to explore?

**Your feedback helps improve the lab experience!**
