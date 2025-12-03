# Azure Monitor Lab

A hands-on lab demonstrating **Azure Log Analytics** and **Application
Insights** through a multi-service application. Learn to collect telemetry,
write KQL queries, create alerts, and build dashboards in a realistic Azure
environment.

**Duration**: ~6 hours | **Level**: Beginner to Intermediate

## Quick Start

### Prerequisites
- Azure subscription with Contributor access
- Azure CLI or PowerShell
- Basic familiarity with Azure services
- No prior monitoring or KQL experience required

### Deploy
```bash
# 1. Configure your environment
cp .env.example .env
# Edit .env with your Azure subscription ID

# 2. Deploy infrastructure
cd infra/scripts
./deploy.sh  # or deploy.ps1 for PowerShell

# 3. Start the lab
# Open doc/lab-guide/01-setup.md
```

**Using VS Code Dev Container?** All tools are pre-installed. Just reopen in
*container and run the deploy script.

## What You'll Learn
- Collect and analyze logs from Azure services
- Monitor application performance with Application Insights
- Write KQL queries for operational insights
- Create alerts and automated incident response
- Build dashboards and workbooks

## Lab Exercises
1. **Setup** - Deploy infrastructure and verify configuration
2. **Data Collection** - Configure diagnostic settings and telemetry
3. **KQL Queries** - Learn query language from basic to advanced
4. **Application Insights** - Explore Application Map and Live Metrics
5. **Alerting** - Create metric and log alerts with automation
6. **Dashboards** - Build interactive workbooks and visualizations
7. **Cleanup** - Remove all resources

**→ Start here**: [`doc/lab-guide/01-setup.md`](doc/lab-guide/01-setup.md)

## Documentation
- [`doc/REQUIREMENTS.md`](doc/REQUIREMENTS.md) - Lab objectives and requirements
- [`doc/ARCHITECTURE.md`](doc/ARCHITECTURE.md) - Infrastructure design and cost details
- [`doc/PROGRESS.md`](doc/PROGRESS.md) - Implementation status

## Cost & Cleanup
- **Estimated cost**: ~$3.50/day (~$0.85 for 6-hour session)
- **Cleanup**: Run `./infra/scripts/cleanup.sh` when finished

See [`doc/ARCHITECTURE.md`](doc/ARCHITECTURE.md) for detailed cost breakdown.

## License
MIT License - Provided as-is for educational purposes.

---

**Questions?** Check the troubleshooting section in the lab guide or open an
*issue.
