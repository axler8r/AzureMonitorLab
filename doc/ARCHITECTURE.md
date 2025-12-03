# Azure Monitor Lab - Architecture

## Project Structure

```
AzureMonitorLab/
├── .devcontainer/
│   └── devcontainer.json          # Dev container configuration
├── .vscode/
│   └── settings.json              # VS Code workspace settings
├── doc/
│   ├── REQUIREMENTS.md            # Product requirements
│   ├── ARCHITECTURE.md            # This file
│   ├── PROGRESS.md                # Implementation tracking
│   ├── lab-guide/                 # Step-by-step exercises
│   │   ├── 01-setup.md
│   │   ├── 02-logic-apps.md
│   │   ├── 03-kql-queries.md
│   │   ├── 04-app-insights.md
│   │   ├── 05-alerting.md
│   │   ├── 06-dashboards.md
│   │   └── 07-cleanup.md
│   └── images/                    # Screenshots and diagrams
├── infra/
│   ├── bicep/
│   │   ├── main.bicep             # Main orchestration template
│   │   ├── modules/               # Resource-specific modules
│   │   │   ├── loganalytics.bicep
│   │   │   ├── appinsights.bicep
│   │   │   ├── storage.bicep
│   │   │   ├── servicebus.bicep
│   │   │   ├── logicapp-sbsender.bicep
│   │   │   ├── logicapp-apicaller.bicep
│   │   │   └── apim.bicep
│   │   └── parameters/            # Environment-specific parameters
│   │       ├── dev.bicepparam
│   │       └── prod.bicepparam
│   └── scripts/
│       ├── deploy.sh              # Bash deployment
│       ├── deploy.ps1             # PowerShell deployment
│       ├── cleanup.sh             # Bash cleanup
│       └── cleanup.ps1            # PowerShell cleanup
├── queries/
│   ├── basic/                     # Basic KQL queries
│   │   ├── 01-service-health.kql
│   │   ├── 02-error-rates.kql
│   │   └── 03-performance.kql
│   ├── advanced/                  # Advanced KQL queries
│   │   ├── 01-correlation.kql
│   │   ├── 02-anomaly-detection.kql
│   │   └── 03-user-analytics.kql
│   └── workbooks/
│       └── monitoring-workbook.json
├── alerts/
│   ├── metric-alerts.json         # Metric-based alerts
│   ├── log-alerts.json            # Log query alerts
│   └── action-groups.json         # Notification configurations
├── .env.example                   # Environment configuration template
├── .gitignore
├── CHANGELOG.md
├── LICENSE
└── README.md
```

## Azure Resources

### Core Monitoring Infrastructure

#### Log Analytics Workspace
- **Purpose**: Centralized log collection and analysis
- **SKU**: PerGB2018 (pay-as-you-go)
- **Retention**: Configurable (30 days dev, 90 days prod)
- **Features**: 
  - Resource-based permissions enabled
  - Public network access for ingestion and query
  - Receives diagnostic logs from all Azure resources

#### Application Insights
- **Purpose**: Application performance monitoring
- **Type**: Workspace-based (linked to Log Analytics)
- **Features**:
  - Application Map for dependency visualization
  - Live Metrics streaming
  - Smart Detection for anomalies
  - Custom telemetry collection

### Compute & Application Services

#### Logic Apps (2 workflows)
**Type**: Consumption-based workflows
**Purpose**: 
- `logic-azmonlab-sbsender`: Participants build workflow to send messages to Service Bus
- `logic-azmonlab-apicaller`: Participants build workflow to call APIM APIs
**Pre-configured**: Empty Recurrence triggers with configurable intervals (60s default)
**Integration**: Diagnostic logs sent to Log Analytics
**Learning outcomes**: 
- Build Logic App workflows from scratch
- Configure Service Bus and HTTP connectors
- Monitor workflow execution and performance

#### API Management
**Tier**: Developer
**Features**:
  - Base APIM instance with Application Insights logger
  - Gateway logs to Log Analytics
  - No pre-configured APIs (participants create them)
**Purpose**: Demonstrate API monitoring, logging, and analytics
**Learning outcomes**:
- Create and configure APIs in APIM
- Understand API request/response logging
- Monitor API performance and usage

### Data Services

#### Storage Account
- **Type**: StorageV2 (General Purpose v2)
- **SKU**: Standard_LRS
- **Access Tier**: Hot
- **Services**: Blob, Queue, Table, File
- **Diagnostics**: All services send logs to Log Analytics
- **Security**: 
  - HTTPS only
  - TLS 1.2 minimum
  - Public blob access disabled
  - Public network access enabled
- **Purpose**: Demonstrate storage monitoring and diagnostic logs

#### Service Bus
- **Tier**: Standard
- **Components**:
  - Queue: `lab-queue` for point-to-point messaging
  - Topic: `lab-topic` with subscription for pub/sub
- **Features**:
  - Dead letter queues enabled
  - Operational and audit logs to Log Analytics

## Design Decisions

### 1. Resource Group Strategy
**Decision**: Optional creation via `.env` configuration flag

**Rationale**: 
- Supports both workshop scenarios (restricted permissions) and personal environments
- Participants may not have subscription-level Contributor access
- Allows use of pre-created resource groups in enterprise environments

**Implementation**: `CREATE_RESOURCE_GROUP=true/false` in `.env`

### 2. API Management Tier
**Decision**: Developer tier

**Rationale**:
- Full feature set for learning and demonstrations
- Developer portal access for API documentation
- Advanced logging and diagnostics capabilities
- Suitable for non-production lab environments

**Trade-offs**: Higher cost (~$50/month) vs Consumption, but better learning experience

### 3. Logic Apps Approach
**Decision**: Two separate Logic Apps with minimal pre-configuration

**Rationale**:
- Participants build workflows from scratch (hands-on learning)
- No code deployment required
- Visual workflow designer accessible to beginners
- Automatic integration with Azure services

**Configuration**: Empty Recurrence triggers, participants add actions

### 4. Service Bus Tier
**Decision**: Standard tier

**Rationale**:
- Supports topics and subscriptions (required for REQ-003)
- Queue partitioning for scalability demos
- Advanced messaging features for realistic scenarios
- Cost: ~$10/month base + usage

**Alternative considered**: Basic tier lacks topics/subscriptions

### 5. Networking Approach
**Decision**: Public network access enabled, no VNets/firewalls

**Rationale**:
- Simplifies lab setup (per REQ-001)
- Reduces deployment time
- Avoids networking complexity for beginners
- Focus remains on monitoring, not network security

**Security measures**:
- TLS 1.2 minimum across all services
- Azure Services bypass for storage
- Managed identities where applicable (future enhancement)

### 6. Authentication & Security
**Decision**: 
- Managed identities for Logic Apps (system-assigned)
- TLS 1.2 minimum enforcement
- HTTPS-only traffic

**Rationale**:
- Simplifies workshop experience
- Demonstrates Azure security best practices
- No credential management required

**Security measures**:
- Logic Apps use system-assigned managed identities
- Participants configure connectors via Portal (guided experience)
- All traffic encrypted in transit

### 7. Resource Naming Convention
**Decision**: Azure naming conventions with consistent project identifier

**Pattern**:
```
{resource-type}-azmonlab-{environment}
law-azmonlab-dev          # Log Analytics Workspace
appi-azmonlab-dev         # Application Insights
logic-azmonlab-sbsender   # Logic App - Service Bus Sender
logic-azmonlab-apicaller  # Logic App - API Caller
sb-azmonlab-dev           # Service Bus
apim-azmonlab-dev         # API Management
stazmon{env}{unique8}     # Storage (18 chars total, no hyphens)
```

**Rationale**:
- Clear resource identification
- Environment separation (dev/prod)
- Follows Azure best practices
- Unique suffixes prevent naming conflicts

### 8. Diagnostic Settings Strategy
**Decision**: All resources send logs and metrics to Log Analytics

**Implementation**:
- Configured in Bicep modules
- Deployed atomically with resources
- Enables immediate log collection

**Rationale**:
- Demonstrates REQ-002 out of the box
- Provides immediate telemetry for exercises
- Shows proper Azure monitoring setup

## Data Flow

```
┌─────────────────┐      ┌─────────────────┐
│  Logic App      │      │  Logic App      │
│  (SB Sender)    │      │  (API Caller)   │
└─────────────────┘      └─────────────────┘
         │                        │
         │ Messages               │ HTTP Requests
         ▼                        ▼
┌─────────────────┐      ┌─────────────────┐
│  Service Bus    │      │   API Gateway   │
│  (Queue/Topic)  │      │      (APIM)     │
└─────────────────┘      └─────────────────┘
         │                        │
         │                        │
         │  Diagnostic Logs       │
         └────────┬───────────────┘
                  ▼
    ┌─────────────────────────────────┐
    │   Log Analytics Workspace       │
    │   (Centralized Logs & Metrics)  │
    └─────────────────────────────────┘
                  │         ▲
                  │         │
                  ▼         │ Linked
         ┌────────────────────┐
         │  App Insights      │
         │  (APIM logging)    │
         └────────────────────┘
                  │
                  ▼
         ┌───────────────────────┐
         │  KQL Queries          │
         │  Alerts               │
         │  Workbooks            │
         │  Dashboards           │
         └───────────────────────┘
```

## Deployment Flow

1. **Prerequisites**: User copies `.env.example` to `.env` and configures
2. **Execution**: Run `deploy.sh` or `deploy.ps1`
3. **Validation**: Script validates environment variables
4. **Resource Group**: Created (if `CREATE_RESOURCE_GROUP=true`) or verified
5. **Infrastructure**: Bicep deployment to resource group
6. **Outputs**: Resource IDs and connection details saved to `deployment-outputs.json`
7. **Next Steps**: User follows lab guide to configure Logic App workflows and APIM APIs

## Cost Estimate

Estimated daily cost (East US region):

| Resource | Tier/SKU | Daily Cost |
|----------|----------|------------|
| Log Analytics | PerGB2018, ~1GB/day | $2.76 |
| Application Insights | Workspace-based | Included |
| Storage Account | Standard_LRS, minimal | $0.05 |
| Service Bus | Standard | $0.35 |
| Logic Apps (2x) | Consumption, 100 runs each | $0.02 |
| API Management | Developer | $1.65 |
| **Total** | | **~$4.83/day** |

**Notes**:
- Costs vary based on usage and region
- Log Analytics dominates cost (ingestion + retention)
- Developer tier APIM has fixed daily cost
- Workshop duration: 6 hours (~$1.21 per participant)

## Security Considerations

### Current Implementation
- ✅ TLS 1.2 minimum enforced
- ✅ HTTPS-only traffic
- ✅ Public blob access disabled
- ✅ Connection strings stored in app settings (not code)
- ✅ Resource-based RBAC for Log Analytics

### Future Enhancements
- 🔄 Managed identities for service-to-service authentication
- 🔄 Key Vault integration for secrets
- 🔄 Private endpoints (optional advanced module)
- 🔄 Azure Policy compliance checks

## Extensibility

The architecture supports optional extensions:

1. **Advanced Networking**: Add VNet integration module for enterprise scenarios
2. **Additional Services**: Cosmos DB, Redis Cache, Event Hubs modules
3. **CI/CD Integration**: GitHub Actions / Azure DevOps pipeline examples
4. **Advanced Monitoring**: Custom metrics, distributed tracing examples
5. **Cost Optimization**: Budget alerts, cost analysis workbooks
