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
│   │   ├── 02-data-collection.md
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
│   │   │   ├── function.bicep
│   │   │   ├── servicebus.bicep
│   │   │   ├── logicapp.bicep
│   │   │   └── apim.bicep
│   │   └── parameters/            # Environment-specific parameters
│   │       ├── dev.bicepparam
│   │       └── prod.bicepparam
│   └── scripts/
│       ├── deploy.sh              # Bash deployment
│       ├── deploy.ps1             # PowerShell deployment
│       ├── cleanup.sh             # Bash cleanup
│       └── cleanup.ps1            # PowerShell cleanup
├── src/
│   ├── function-app/              # Python Function App
│   │   ├── function_app.py        # Function app entry point
│   │   ├── host.json              # Function app configuration
│   │   ├── local.settings.json    # Local development settings
│   │   ├── requirements.txt       # Python dependencies
│   │   └── functions/             # Function implementations
│   │       ├── http_trigger/
│   │       ├── servicebus_trigger/
│   │       └── timer_trigger/
│   └── load-generator/            # Traffic generation tool
│       ├── generate_load.py
│       └── requirements.txt
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

#### Azure Functions
- **Runtime**: Python 3.11
- **Hosting**: Linux Consumption Plan (Y1)
- **Triggers**: HTTP, Service Bus, Timer
- **Integration**: Application Insights SDK for telemetry
- **Purpose**: Generate realistic application telemetry and demonstrate monitoring

#### API Management
- **Tier**: Consumption (serverless, cost-effective)
- **Features**:
  - Integrated with Application Insights
  - Gateway logs to Log Analytics
  - API request/response logging
- **Purpose**: Demonstrate API monitoring and analytics

#### Logic Apps
- **Type**: Consumption-based workflows
- **Purpose**: Alert response automation and incident handling
- **Integration**: Triggered by Azure Monitor alerts

### Data Services

#### Storage Account
- **Type**: StorageV2 (General Purpose v2)
- **SKU**: Standard_LRS
- **Access Tier**: Hot
- **Services**: Blob, Queue, Table, File
- **Diagnostics**: All services (blob, queue, table, file) send logs to Log Analytics
- **Security**: 
  - HTTPS only
  - TLS 1.2 minimum
  - Public blob access disabled
  - Public network access enabled (required for Function App file share access)
  - Shared key access enabled (Function App uses connection strings)
- **Function App Integration**:
  - File service explicitly created for Function App content storage
  - Network ACLs allow Azure Services bypass
  - Function App accesses storage via `AzureWebJobsStorage` connection string
  - Content file share created automatically by Function App (not pre-provisioned)

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
**Decision**: Consumption tier

**Rationale**:
- Cost-effective for lab scenarios (~$0.035 per 10K calls)
- No upfront commitment or idle costs
- Sufficient features for monitoring demonstrations
- Easy to deploy and tear down

**Trade-offs**: Limited advanced features, but adequate for lab purposes

### 3. Function App Hosting
**Decision**: Linux Consumption Plan (Y1)

**Rationale**:
- Serverless pricing (pay per execution)
- Native Python support on Linux
- Fast cold start times for demos
- Scales automatically for load testing

**Configuration**: Python 3.11 runtime for latest features and security

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
- Connection strings for initial setup
- TLS 1.2 minimum enforcement
- HTTPS-only traffic

**Rationale**:
- Simplifies workshop experience
- Sufficient security for temporary lab resources
- Managed identities add complexity for beginners

**Future enhancement**: Add optional managed identity configuration

### 7. Resource Naming Convention
**Decision**: Azure naming conventions with consistent project identifier

**Pattern**:
```
{resource-type}-azmonlab-{environment}
law-azmonlab-dev          # Log Analytics Workspace
appi-azmonlab-dev         # Application Insights
func-azmonlab-dev         # Function App
sb-azmonlab-dev           # Service Bus
apim-azmonlab-dev         # API Management
logic-azmonlab-dev        # Logic App
asp-azmonlab-dev          # App Service Plan
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
┌─────────────────┐
│  Function App   │──┐
│  (Python 3.11)  │  │
└─────────────────┘  │
                     │  Telemetry
┌─────────────────┐  │  (traces, metrics,
│   API Gateway   │──┤   exceptions, deps)
│      (APIM)     │  │
└─────────────────┘  │
                     ▼
┌─────────────────┐  ┌──────────────────┐
│  Service Bus    │  │ App Insights     │
│  (Messages)     │  │ (APM data)       │
└─────────────────┘  └──────────────────┘
         │                    │
         │                    │ Linked
         ▼                    ▼
    ┌─────────────────────────────────┐
    │   Log Analytics Workspace       │
    │   (Centralized Logs & Metrics)  │
    └─────────────────────────────────┘
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
6. **Outputs**: Connection strings and resource IDs saved to `deployment-outputs.json`
7. **Next Steps**: User deploys Function App code and follows lab guide

## Cost Estimate

Estimated daily cost (East US region):

| Resource | Tier/SKU | Daily Cost |
|----------|----------|------------|
| Log Analytics | PerGB2018, ~1GB/day | $2.76 |
| Application Insights | Workspace-based | Included |
| Storage Account | Standard_LRS, minimal | $0.05 |
| Function App | Consumption, 100K executions | $0.20 |
| Service Bus | Standard | $0.35 |
| Logic Apps | Consumption, 100 runs | $0.01 |
| API Management | Consumption, 10K calls | $0.04 |
| **Total** | | **~$3.41/day** |

**Notes**:
- Costs vary based on usage and region
- Log Analytics dominates cost (ingestion + retention)
- Consumption tiers minimize idle costs
- Workshop duration: 6 hours (~$0.85 per participant)

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
