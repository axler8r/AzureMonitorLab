// Application Insights module
// Provides application performance monitoring and telemetry collection

@description('The name of the Application Insights resource')
param appInsightsName string

@description('The location for Application Insights')
param location string = resourceGroup().location

@description('The type of application being monitored')
@allowed([
  'web'
  'other'
])
param applicationType string = 'web'

@description('The resource ID of the Log Analytics Workspace')
param workspaceId string

@description('Tags to apply to the resource')
param tags object = {}

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: applicationType
    WorkspaceResourceId: workspaceId
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Outputs
@description('The resource ID of Application Insights')
output appInsightsId string = applicationInsights.id

@description('The name of Application Insights')
output appInsightsName string = applicationInsights.name

@description('The instrumentation key for Application Insights')
output instrumentationKey string = applicationInsights.properties.InstrumentationKey

@description('The connection string for Application Insights')
output connectionString string = applicationInsights.properties.ConnectionString
