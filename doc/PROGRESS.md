# Azure Monitor Lab - Implementation Progress

> **Note**: This file tracks active development progress. It will be deleted once the project is complete.

## ✅ Completed

### Phase 1: Foundation
- [x] Created `.gitignore` with Azure/Python/IDE patterns
- [x] Established directory structure (infra/, queries/, alerts/, doc/lab-guide/, doc/images/)
- [x] Created `.env.example` with configuration template

### Phase 2: Simplified Infrastructure (REQ-001)
- [x] **Bicep Modules** - All resources with diagnostic settings → Log Analytics:
  - `loganalytics.bicep` - Workspace with configurable SKU and retention (30-730 days)
  - `appinsights.bicep` - Application Insights linked to Log Analytics workspace
  - `storage.bicep` - Storage Account with diagnostic settings for all services
  - `servicebus.bicep` - Service Bus namespace with queue and topic
  - `logicapp-sbsender.bicep` - Minimal Logic App with Recurrence trigger only
  - `logicapp-apicaller.bicep` - Minimal Logic App with Recurrence trigger only
  - `apim.bicep` - API Management (Developer tier) with App Insights logger, no pre-configured APIs
- [x] **Main Template** - `main.bicep` orchestration with:
  - Resource naming with environment prefix
  - Both Logic App deployments
  - Simplified outputs (no Function App endpoints)
- [x] **Parameter Files**:
  - `dev.bicepparam` - Development environment (30 day retention, 60s intervals)
  - `prod.bicepparam` - Production environment (90 day retention, 60s intervals)
- [x] **Deployment Scripts** (Bash & PowerShell):
  - `deploy.sh` / `deploy.ps1` - Cross-platform deployment automation
  - `cleanup.sh` / `cleanup.ps1` - Resource teardown with safety confirmations
- [x] **Documentation Updates**:
  - `REQUIREMENTS.md` - Updated REQ-001 and REQ-003 to reflect Logic Apps approach
  - `ARCHITECTURE.md` - Fully updated with simplified design
  - Removed all Function App references

## 🔄 In Progress

None currently.

## 📋 Remaining Work

### Phase 3: Lab Guides (REQ-008)
**Priority**: High | **Effort**: High

- [ ] **Lab Guides** in `doc/lab-guide/`:
  - [ ] `01-setup.md` - Prerequisites, .env configuration, deployment steps
  - [ ] `02-logic-apps.md` - Building Logic App workflows (Service Bus sender + API caller)
  - [ ] `03-apim-apis.md` - Creating and configuring APIs in APIM
  - [ ] `04-kql-queries.md` - Hands-on KQL exercises, query building (REQ-004)
  - [ ] `05-app-insights.md` - Exploring Application Insights logs and metrics (REQ-005)
  - [ ] `06-alerting.md` - Creating alerts, action groups, testing (REQ-006)
  - [ ] `07-dashboards.md` - Building dashboards, workbooks, visualizations (REQ-007)
  - [ ] `08-cleanup.md` - Resource deletion, cost verification

- [ ] **Visual Assets** in `doc/images/`:
  - [ ] Architecture diagram (simplified infrastructure overview)
  - [ ] Screenshots for each lab exercise
  - [ ] Data flow diagram

**Acceptance Criteria**:
- Lab guides are complete with step-by-step instructions
- Screenshots match current Azure Portal UI
- Participants can complete all exercises within 6 hours
- Exercises teach both Azure Monitor AND service configuration (Logic Apps, APIM)

### Phase 4: Monitoring Artifacts (REQ-004, REQ-005, REQ-006, REQ-007)
**Priority**: High | **Effort**: Medium

- [ ] **Basic KQL Queries** in `queries/basic/`:
  - [ ] `01-service-health.kql` - Logic App run status and success rates
  - [ ] `02-error-rates.kql` - Workflow failures and APIM errors
  - [ ] `03-performance.kql` - Execution duration and latency metrics

- [ ] **Advanced KQL Queries** in `queries/advanced/`:
  - [ ] `01-correlation.kql` - Cross-service activity correlation
  - [ ] `02-anomaly-detection.kql` - Statistical anomaly detection
  - [ ] `03-usage-analytics.kql` - Resource usage patterns

- [ ] **Workbooks** in `queries/workbooks/`:
  - [ ] `monitoring-workbook.json` - Interactive dashboard with parameters
  - [ ] Sections for: overview, Logic Apps metrics, APIM analytics, Service Bus monitoring

- [ ] **Alerts** in `alerts/`:
  - [ ] `metric-alerts.json` - Logic App failure rate, APIM latency alerts
  - [ ] `log-alerts.json` - KQL-based alert definitions
  - [ ] `action-groups.json` - Email and webhook notifications

**Acceptance Criteria**:
- All queries execute without errors
- Queries return meaningful results from lab infrastructure
- Workbook renders correctly in Azure Portal
- Alert definitions are syntactically valid

### Phase 5: Repository Documentation
**Priority**: Medium | **Effort**: Low

- [ ] Update `README.md` - Quick start, overview, links to lab guides
- [ ] Update `LICENSE` - Verify current year (2025)
- [ ] Create `CHANGELOG.md` - Document v2.0.0 simplification changes

**Acceptance Criteria**:
- README provides clear onboarding
- All documentation reflects simplified architecture

## Technical Debt & Known Issues

None currently - simplified design eliminates previous complexity.

## Design Changes from v1.0

**Removed**:
- ❌ Azure Functions and App Service Plan
- ❌ Python Function App code (`src/function-app/`)
- ❌ Load generator (`src/load-generator/`)
- ❌ Pre-configured APIM APIs
- ❌ Service Bus API connections (V1 authorization complexity)

**Added**:
- ✅ Two minimal Logic Apps (participants build workflows)
- ✅ Hands-on learning for Logic Apps AND APIM configuration
- ✅ System-assigned managed identities for Logic Apps
- ✅ Simplified deployment (no code deployment step)

**Rationale**: Focus on Azure Monitor demonstrations, not application development. Participants learn by building, not just observing.

## Metrics

- **Requirements Coverage**: 100% (REQ-001 through REQ-010 addressed)
- **Infrastructure Completion**: 100% (6 Bicep modules + deployment scripts)
- **Lab Guides**: 0% (0/8 files)
- **Queries & Alerts**: 0% (0/10 files)
- **Documentation**: 60% (3/5 files - README, LICENSE, CHANGELOG pending)
- **Overall Progress**: ~40%

## Next Steps

1. Write `01-setup.md` lab guide with deployment instructions
2. Write `02-logic-apps.md` with step-by-step workflow building exercises
3. Write `03-apim-apis.md` with API creation and configuration
4. Test end-to-end deployment and lab flow
5. Create basic KQL queries for common monitoring scenarios
6. Build monitoring workbook template
7. Create alert definitions for common scenarios
8. Capture screenshots for lab guides
9. Create architecture diagrams
10. Final testing and polish
11. Delete this file and ship v2.0!

---
*Last Updated*: 2025-12-03
