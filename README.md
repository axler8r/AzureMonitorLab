# Azure Monitor Lab
A hands-on lab that demonstrates the monitoring capabilities of
**Azure Log Analytics** and **Azure Application Insights** through a simple
multi-service application scenario.

## Overview
This lab provides a practical learning environment where participants explore
Azure Monitor's telemetry collection, analysis, and alerting capabilities.
Through pre-built infrastructure and sample applications, you'll learn to:
- Collect and analyze logs from multiple Azure services using Log Analytics
- Monitor application performance and dependencies with Application Insights
- Write KQL queries for operational insights
- Create alerts and automated responses
- Build dashboards and workbooks for visualization

**Time Required:** ~6 hours of hands-on exercises

## Prerequisites
- Azure subscription with Contributor access
- Basic understanding of Azure services
- Familiarity with command-line tools (Azure CLI or PowerShell)
- No prior monitoring or KQL experience required

## What's Included

### Infrastructure
- **Log Analytics Workspace** - Centralized log collection and analysis
- **Application Insights** - Application performance monitoring
- **Azure Functions** - Sample Python application generating telemetry
- **Azure Storage Account** - Blob operations for distributed tracing
- **Azure Service Bus** - Message processing scenarios
- **Azure Logic Apps** - Automated incident response
- **Azure API Management** - API monitoring integration

### Learning Resources
- Pre-built Bicep templates for infrastructure deployment
- Sample Python Function App with instrumentation
- Collection of basic to advanced KQL queries
- Alert configurations and action groups
- Azure Workbook templates
- Step-by-step lab guide with exercises

## Getting Started

### Option 1: Dev Container (Recommended)
1. Clone this repository
2. Open in VS Code
3. Reopen in container when prompted
4. All tools (Azure CLI, Bicep, Python) are pre-installed

### Option 2: Local Setup
**Requirements:**
- Azure CLI 2.50+
- Bicep CLI
- Python 3.11+
- PowerShell 7+ (optional)

### Deploy the Lab Environment
**Using Bash:**
```bash
cd infra/scripts
./deploy.sh
```

**Using PowerShell:**
```powershell
cd infra/scripts
./deploy.ps1
```

The deployment will:
1. Create a resource group
2. Deploy all Azure services
3. Configure diagnostic settings
4. Deploy the sample Function App
5. Output connection strings and URLs

## Lab Structure
```
01-setup.md          - Deploy infrastructure and verify setup
02-data-collection   - Configure telemetry and diagnostic settings
03-kql-queries       - Learn KQL with progressively complex queries
04-app-insights      - Explore Application Map, Live Metrics, and Smart Detection
05-alerting          - Create metric and log alerts with automation
06-dashboards        - Build interactive dashboards and workbooks
07-cleanup           - Remove all resources
```

## Sample Queries
Explore pre-built KQL queries in the `queries/` directory:

- **Basic:** Service health, error rates, performance metrics
- **Advanced:** Cross-service correlation, anomaly detection, user analytics

## Key Learning Outcomes
✅ Understand Azure Monitor architecture and data flow  
✅ Configure comprehensive telemetry collection  
✅ Write effective KQL queries for troubleshooting  
✅ Use Application Insights for application observability  
✅ Set up proactive monitoring with alerts  
✅ Create meaningful visualizations for stakeholders  
✅ Implement automated incident response  
✅ Manage monitoring costs and retention policies  

## Architecture
The lab deploys a microservices-style application where:
- HTTP triggers simulate user requests
- Service Bus processes background jobs
- Storage operations demonstrate distributed tracing
- All components send telemetry to Log Analytics and Application Insights

## Cost Considerations
Estimated cost: **$5-10 per day** when resources are running.

**Cost-saving tips:**
- Complete the lab in a single session
- Run the cleanup script when finished
- Set a daily cap on Application Insights ingestion

## Cleanup
To remove all lab resources:
```bash
cd infra/scripts
./cleanup.sh
```

Or manually delete the resource group from Azure Portal.

## Support
For issues or questions:
- Review the troubleshooting section in the lab guide
- Check Azure Monitor documentation
- Open an issue in this repository

## License
This project is provided as-is for educational purposes.

## Contributing
Contributions are welcome! Please submit pull requests with:
- Additional KQL query examples
- Improved documentation
- Bug fixes or enhancements

---

**Ready to start?** Head to `doc/lab-guide/01-setup.md` to begin your Azure Monitor learning journey!
