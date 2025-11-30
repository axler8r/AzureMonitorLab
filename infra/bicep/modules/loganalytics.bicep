// Log Analytics Workspace module
// Provides centralized log collection and analysis for all Azure resources

@description('The name of the Log Analytics Workspace')
param workspaceName string

@description('The location for the Log Analytics Workspace')
param location string = resourceGroup().location

@description('The SKU for the Log Analytics Workspace')
@allowed([
  'PerGB2018'
  'Free'
  'Standalone'
  'PerNode'
  'Standard'
  'Premium'
])
param sku string = 'PerGB2018'

@description('The number of days to retain data in the workspace')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

@description('Tags to apply to the resource')
param tags object = {}

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Outputs
@description('The resource ID of the Log Analytics Workspace')
output workspaceId string = logAnalyticsWorkspace.id

@description('The customer ID (workspace ID) of the Log Analytics Workspace')
output workspaceCustomerId string = logAnalyticsWorkspace.properties.customerId

@description('The name of the Log Analytics Workspace')
output workspaceName string = logAnalyticsWorkspace.name
