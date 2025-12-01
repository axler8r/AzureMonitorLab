# Azure Monitor Lab - Requirements

## Requirements
- The lab will **focus** on _Log Analytics_, and _Application Insights_.
- Participants must be able to complete the labs with 6 hours of hands-on time.
- Participants will not be required to wrtie more than a few lines of code.
- The lab will be self-contained, with all resources created and destroyed via scripts.
- The lab will be suitable for Azure Monitor beginners to intermediate users.

### REQ-001: Lab Environment
- The lab environment will be hosted on Azure.
- It will consist of the following resources:
  - Log Analytics Workspace
  - Application Insights
  - Azure Storage Account
  - Azure Logic Apps
  - Azure Functions
  - Azure Service Bus
  - Azure API Management
- There will be no networking components such as VNets or Firewalls.
- All resources will be created in a single resource group.
- The lab environment will be created with Bicep.
- There will be helper scripts in PowerShell and Azure CLI for common tasks.

### REQ-002: Data Collection & Ingestion
- Configure diagnostic settings to send logs from all services to Log Analytics.
- Enable Application Insights for Functions and web apps.
- Set up custom telemetry collection.

### REQ-003: Sample Application/Workload
- Deploy a working application that generates realistic telemetry.
- Include scenarios that produce errors, performance issues, and normal operations.
- Application should use Storage, Service Bus, and other lab resources.

### REQ-004: KQL Query Scenarios
- Provide pre-built queries for common monitoring tasks.
- Cover basic to advanced query examples.
- Include cross-service correlation queries.

### REQ-005: Application Insights Demonstrations
- Show Application Map for dependency visualization.
- Configure availability tests.
- Demonstrate Live Metrics and Smart Detection.

### REQ-006: Alerting & Notifications
- Create metric and log-based alerts.
- Set up action groups (email, Logic Apps, webhooks).
- Show automated remediation examples.

### REQ-007: Dashboards & Workbooks
- Build Azure Dashboards with key metrics.
- Create interactive Workbooks with parameters.
- Pin important queries to dashboards.

### REQ-008: Lab Exercises/Documentation
- Step-by-step instructions for participants.
- Hands-on exercises with validation steps.
- Troubleshooting scenarios to solve.

### REQ-009: Cost & Retention Management
- Configure data retention policies.
- Show cost monitoring for Azure Monitor.
- Demonstrate data export options.

### REQ-010: Integration Examples
- API Management with Application Insights.
- Logic Apps for incident response.

## Documentation

See related documentation:
- [ARCHITECTURE.md](ARCHITECTURE.md) - Project structure and design decisions
- [PROGRESS.md](PROGRESS.md) - Implementation status and remaining work


