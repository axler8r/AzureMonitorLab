# Azure Monitor Lab - Implementation Progress

> **Note**: This file tracks active development progress. It will be deleted once the project is complete.

## ✅ Completed

### Phase 1: Foundation
- [x] Created `.gitignore` with Azure/Python/IDE patterns
- [x] Established directory structure (infra/, src/, queries/, alerts/, doc/lab-guide/, doc/images/)
- [x] Created `.env.example` with configuration template including:
  - Azure subscription and tenant settings
  - Resource group configuration with optional creation flag
  - Publisher email and name for APIM
  - Log Analytics retention settings

### Phase 2: Infrastructure (REQ-001)
- [x] **Bicep Modules** - All resources with diagnostic settings → Log Analytics:
  - `loganalytics.bicep` - Workspace with configurable SKU and retention (30-730 days)
  - `appinsights.bicep` - Application Insights linked to Log Analytics workspace
  - `storage.bicep` - Storage Account with blob/queue/table/file diagnostic settings
  - `function.bicep` - Python 3.11 Function App with App Insights integration (Linux Consumption)
  - `servicebus.bicep` - Service Bus namespace with queue and topic
  - `logicapp.bicep` - Logic App for alert handling workflows
  - `apim.bicep` - API Management (Developer) with App Insights logger
- [x] **Main Template** - `main.bicep` orchestration with:
  - App Service Plan (Consumption Y1 for Functions)
  - Resource naming with environment prefix
  - Comprehensive outputs for all resource IDs and connection strings
- [x] **Parameter Files**:
  - `dev.bicepparam` - Development environment (30 day retention)
  - `prod.bicepparam` - Production environment (90 day retention)
- [x] **Deployment Scripts** (Bash & PowerShell):
  - `deploy.sh` / `deploy.ps1` - Cross-platform deployment automation
  - `cleanup.sh` / `cleanup.ps1` - Resource teardown with safety confirmations
  - .env file parsing and validation
  - Optional resource group creation
  - Deployment output persistence

### Phase 2.5: Documentation Reorganization
- [x] Split PRD into three focused documents:
  - `REQUIREMENTS.md` - Requirements only (REQ-001 through REQ-010)
  - `ARCHITECTURE.md` - Project structure, design decisions, cost estimates
  - `PROGRESS.md` - This file, implementation tracking

## 🔄 In Progress

None currently.

## 📋 Remaining Work

### Phase 3: Application (REQ-003)
**Priority**: High | **Effort**: Medium

- [x] **Logic App Telemetry Generator** (timer-triggered Service Bus message sender):
  - [x] Add `LOGIC_APP_RECURRENCE_INTERVAL` to `.env.example` (default: 30 seconds)
  - [x] Update `logicapp.bicep` - Add parameters for Service Bus connection and recurrence interval
  - [x] Replace HTTP webhook trigger with Recurrence trigger (configurable interval, default 30s)
  - [x] Add Service Bus send message action to `lab-queue`
  - [x] Create varied message payloads (event types, severity levels, timestamps)
  - [x] Include error scenarios (20% error rate with Warning/Error severities for monitoring demo)
  - [x] Update `main.bicep` - Pass Service Bus connection string, queue name, and interval to Logic App module
  - [x] Create interactive lab guide (`02-logic-app-data-collection.md`) with hands-on exercises
  - [x] Validate Bicep templates - All syntax checks pass, what-if analysis successful
  - [x] Add Service Bus API connection with connection string authentication
  - [x] Document manual authorization requirement for V1 API connections in lab guide
  - [x] Add deployment outputs for connection name and authorization instructions
  - [x] Test and validate: V2 managed identity connections not feasible (requires complex setup)
  - [x] Confirmed: V1 connections require one-time Portal authorization (Azure platform limitation)

- [ ] **Deploy and validate Logic App telemetry generation**:
  - [ ] Run deployment with updated Bicep templates
  - [ ] Perform one-time authorization of Service Bus API connection in Portal
  - [ ] Verify Logic App runs succeed every 30 seconds
  - [ ] Confirm messages appear in Service Bus queue
  - [ ] Validate workflow execution logs in Log Analytics

- [ ] **Python Function App** implementation in `src/function-app/`:
  - [ ] `function_app.py` - Main application entry point with Application Insights SDK
  - [ ] HTTP trigger function - RESTful endpoint for health checks and demo requests
  - [ ] Service Bus trigger function - Event processing with error scenarios
  - [ ] Timer trigger function - Scheduled tasks for background telemetry
  - [ ] `host.json` - Function runtime configuration
  - [ ] `requirements.txt` - Python dependencies (azure-functions, opencensus-ext-azure, etc.)
  - [ ] `local.settings.json.example` - Template for local development

- [ ] **Load Generator** in `src/load-generator/`:
  - [ ] `generate_load.py` - Traffic generation script
  - [ ] Configurable request rates and patterns
  - [ ] Intentional error scenario generation (4xx, 5xx responses)
  - [ ] `requirements.txt` - Dependencies (requests, etc.)

**Acceptance Criteria**:
- Logic App runs on schedule and sends messages to Service Bus queue
- Workflow execution logs appear in Log Analytics
- Functions deploy successfully to Azure
- Application Insights receives telemetry automatically
- Load generator creates realistic traffic patterns
- Errors and exceptions logged properly

### Phase 4: Monitoring Artifacts (REQ-004, REQ-005, REQ-006, REQ-007)
**Priority**: High | **Effort**: Medium

- [ ] **Basic KQL Queries** in `queries/basic/`:
  - [ ] `01-service-health.kql` - Availability and uptime queries
  - [ ] `02-error-rates.kql` - Exception tracking and error analysis
  - [ ] `03-performance.kql` - Latency and duration metrics

- [ ] **Advanced KQL Queries** in `queries/advanced/`:
  - [ ] `01-correlation.kql` - Cross-service request tracing
  - [ ] `02-anomaly-detection.kql` - Statistical anomaly detection
  - [ ] `03-user-analytics.kql` - User behavior and patterns

- [ ] **Workbooks** in `queries/workbooks/`:
  - [ ] `monitoring-workbook.json` - Interactive dashboard with parameters
  - [ ] Include sections for: overview, errors, performance, user analytics

- [ ] **Alerts** in `alerts/`:
  - [ ] `metric-alerts.json` - CPU, memory, request rate alerts
  - [ ] `log-alerts.json` - KQL-based alert definitions
  - [ ] `action-groups.json` - Email, webhook, Logic App notifications

**Acceptance Criteria**:
- All queries execute without errors
- Queries return meaningful results from lab data
- Workbook renders correctly in Azure Portal
- Alert definitions are syntactically valid

### Phase 5: Documentation (REQ-008, REQ-009)
**Priority**: High | **Effort**: High

- [ ] **Lab Guides** in `doc/lab-guide/`:
  - [ ] `01-setup.md` - Prerequisites, .env configuration, deployment steps
  - [ ] `02-data-collection.md` - Exploring diagnostic settings, telemetry verification (REQ-002)
  - [ ] `03-kql-queries.md` - Hands-on KQL exercises, query building (REQ-004)
  - [ ] `04-app-insights.md` - Application Map, Live Metrics, Smart Detection (REQ-005)
  - [ ] `05-alerting.md` - Creating alerts, action groups, testing (REQ-006)
  - [ ] `06-dashboards.md` - Building dashboards, workbooks, visualizations (REQ-007)
  - [ ] `07-cleanup.md` - Resource deletion, cost verification

- [ ] **Visual Assets** in `doc/images/`:
  - [ ] Architecture diagram (infrastructure overview)
  - [ ] Screenshots for each lab exercise
  - [ ] Data flow diagram

- [ ] **Repository Documentation**:
  - [ ] Update `README.md` - Quick start, overview, links to lab guides
  - [ ] Update `LICENSE` - Add current year (2025)
  - [ ] Create `CHANGELOG.md` - Initial v1.0.0 release notes

**Acceptance Criteria**:
- Lab guides are complete with step-by-step instructions
- Screenshots match current Azure Portal UI
- Participants can complete all exercises within 6 hours
- README provides clear onboarding

## Technical Debt & Known Issues

- [x] ~~Storage Account naming may fail if environment name + unique suffix > 24 chars~~ - Fixed: Limited to 18 chars total (stazmon + env + 8 unique chars)
- [x] ~~Parameter files contain placeholder email addresses~~ - Fixed: Publisher info now sourced from .env file
- [x] ~~Function App file share creation caused 403 errors~~ - Fixed: Removed WEBSITE_CONTENTAZUREFILECONNECTIONSTRING/WEBSITE_CONTENTSHARE, let Function App auto-create
- [x] ~~Logic App Service Bus API connection 401 Unauthorized errors~~ - Resolved: V1 connections require one-time manual Portal authorization (Azure platform limitation, not a bug)
- [ ] No validation script to verify Bicep before deployment
- [ ] Deployment scripts lack retry logic for transient failures
- [ ] Logic App Service Bus connection requires manual authorization step after deployment (documented in lab guide)

**Notes on Logic App Authorization**:
- V1 API connections (connection string-based) cannot be fully automated via Bicep
- V2 API connections (managed identity-based) support access policies but require more complex setup
- Workshop uses V1 for simplicity with one-time Portal authorization documented in Lab 02

## Future Enhancements (Post-v1.0)

- [ ] Managed identity integration (replace connection strings)
- [ ] Key Vault for secrets management
- [ ] Advanced module: VNet integration
- [ ] Advanced module: Private endpoints
- [ ] CI/CD pipeline examples (GitHub Actions, Azure DevOps)
- [ ] Terraform alternative to Bicep
- [ ] Additional workload examples (Node.js, .NET Functions)

## Metrics

- **Requirements Coverage**: 100% (REQ-001 through REQ-010 addressed)
- **Infrastructure Completion**: 100% (7/7 Bicep modules + deployment scripts)
- **Application Completion**: 33% (1/3 components - Logic App telemetry generator complete)
- **Queries & Alerts**: 0% (0/10 files)
- **Documentation**: 40% (4/10 files - REQUIREMENTS, ARCHITECTURE, PROGRESS, Lab 02)
- **Overall Progress**: ~55%

## Next Steps

1. ~~Implement Python Function App with three trigger types~~ **→ Deploy and validate Logic App first**
2. **Deploy updated infrastructure** with Logic App telemetry generator
3. **Authorize Service Bus API connection** in Azure Portal (one-time step)
4. **Validate Logic App operation**: Verify workflow runs every 30s and messages reach Service Bus queue
5. Create load generator for realistic traffic patterns
6. Write basic KQL queries for log analysis (Lab 03)
7. Implement Python Function App with HTTP/ServiceBus/Timer triggers
2. Create load generator for traffic simulation
3. Write basic and advanced KQL queries
4. Build workbook template and alert definitions
5. Complete lab guide documentation
6. Create architecture diagrams and screenshots
7. Test end-to-end lab flow
8. Delete this file and ship v1.0!

---
*Last Updated*: 2025-12-01
