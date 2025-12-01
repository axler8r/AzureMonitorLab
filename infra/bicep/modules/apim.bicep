// API Management module
// Provides API gateway with Application Insights integration

@description('The name of the API Management instance')
param apimName string

@description('The location for API Management')
param location string = resourceGroup().location

@description('The SKU for API Management')
@allowed([
  'Consumption'
  'Developer'
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Consumption'

@description('The email address of the publisher')
param publisherEmail string

@description('The name of the publisher organization')
param publisherName string

@description('The resource ID of Application Insights')
param appInsightsId string

@description('The Application Insights instrumentation key')
param appInsightsInstrumentationKey string

@description('The resource ID of the Log Analytics Workspace for diagnostics')
param logAnalyticsWorkspaceId string

@description('Tags to apply to the resource')
param tags object = {}

// API Management Service
resource apiManagement 'Microsoft.ApiManagement/service@2023-03-01-preview' = {
  name: apimName
  location: location
  tags: tags
  sku: {
    name: sku
    capacity: sku == 'Consumption' ? 0 : 1
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'False'
    }
  }
}

// Application Insights Logger for APIM
resource apimLogger 'Microsoft.ApiManagement/service/loggers@2023-03-01-preview' = {
  parent: apiManagement
  name: 'appinsights-logger'
  properties: {
    loggerType: 'applicationInsights'
    resourceId: appInsightsId
    credentials: {
      instrumentationKey: appInsightsInstrumentationKey
    }
  }
}

// Diagnostic Settings for API Management
resource apimDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: apiManagement
  name: 'apim-diagnostics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'GatewayLogs'
        enabled: true
      }
      {
        category: 'WebSocketConnectionLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Outputs
@description('The resource ID of the API Management service')
output apimId string = apiManagement.id

@description('The name of the API Management service')
output apimName string = apiManagement.name

@description('The gateway URL of the API Management service')
output apimGatewayUrl string = apiManagement.properties.gatewayUrl

@description('The portal URL of the API Management service')
output apimPortalUrl string = (sku == 'Consumption' || apiManagement.properties.portalUrl == null) ? '' : apiManagement.properties.portalUrl
