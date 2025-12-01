// Azure Monitor Lab - Main Infrastructure Template
// Deploys Log Analytics and monitoring infrastructure for hands-on learning

targetScope = 'resourceGroup'

@description('Environment name used as prefix for all resources')
@minLength(3)
@maxLength(10)
param environmentName string

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Log Analytics retention period in days')
@minValue(30)
@maxValue(730)
param logAnalyticsRetentionDays int = 30

@description('Email address for API Management publisher and alert notifications')
param publisherEmail string

@description('Publisher organization name for API Management')
param publisherName string = 'Azure Monitor Lab'

@description('Tags to apply to all resources')
param tags object = {
  Environment: environmentName
  Project: 'AzureMonitorLab'
  ManagedBy: 'Bicep'
}

// Variables
// Extract environment suffix (dev/prod) from environmentName (devlab/prodlab)
var envSuffix = endsWith(environmentName, 'lab') ? substring(environmentName, 0, length(environmentName) - 3) : environmentName
var workspaceName = 'law-azmonlab-${envSuffix}'
var appInsightsName = 'appi-azmonlab-${envSuffix}'
#disable-next-line BCP335
var storageAccountName = 'stazmon${envSuffix}${substring(uniqueString(resourceGroup().id), 0, 8)}'
var appServicePlanName = 'asp-azmonlab-${envSuffix}'
var functionAppName = 'func-azmonlab-${envSuffix}'
var serviceBusNamespaceName = 'sb-azmonlab-${envSuffix}'
var logicAppName = 'logic-azmonlab-${envSuffix}'
var apimName = 'apim-azmonlab-${envSuffix}'

// Log Analytics Workspace Module
module logAnalytics 'modules/loganalytics.bicep' = {
  name: 'logAnalyticsDeployment'
  params: {
    workspaceName: workspaceName
    location: location
    sku: 'PerGB2018'
    retentionInDays: logAnalyticsRetentionDays
    tags: tags
  }
}

// Application Insights Module
module appInsights 'modules/appinsights.bicep' = {
  name: 'appInsightsDeployment'
  params: {
    appInsightsName: appInsightsName
    location: location
    applicationType: 'web'
    workspaceId: logAnalytics.outputs.workspaceId
    tags: tags
  }
}

// Storage Account Module
module storage 'modules/storage.bicep' = {
  name: 'storageDeployment'
  params: {
    #disable-next-line BCP335
    storageAccountName: storageAccountName
    location: location
    sku: 'Standard_LRS'
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    tags: tags
  }
}

// Service Bus Module
module serviceBus 'modules/servicebus.bicep' = {
  name: 'serviceBusDeployment'
  params: {
    serviceBusNamespaceName: serviceBusNamespaceName
    location: location
    sku: 'Standard'
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    tags: tags
  }
}

// App Service Plan for Function App
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// Function App Module
module functionApp 'modules/function.bicep' = {
  name: 'functionAppDeployment'
  params: {
    functionAppName: functionAppName
    location: location
    appServicePlanId: appServicePlan.id
    storageAccountId: storage.outputs.storageAccountId
    appInsightsConnectionString: appInsights.outputs.connectionString
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    serviceBusConnectionString: serviceBus.outputs.serviceBusConnectionString
    tags: tags
  }
}

// Logic App Module
module logicApp 'modules/logicapp.bicep' = {
  name: 'logicAppDeployment'
  params: {
    logicAppName: logicAppName
    location: location
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    alertEmailAddress: publisherEmail
    tags: tags
  }
}

// API Management Module
module apiManagement 'modules/apim.bicep' = {
  name: 'apimDeployment'
  params: {
    apimName: apimName
    location: location
    sku: 'Developer'
    publisherEmail: publisherEmail
    publisherName: publisherName
    appInsightsId: appInsights.outputs.appInsightsId
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    tags: tags
  }
}

// Outputs
@description('Log Analytics Workspace Resource ID')
output logAnalyticsWorkspaceId string = logAnalytics.outputs.workspaceId

@description('Log Analytics Workspace Customer ID')
output logAnalyticsWorkspaceCustomerId string = logAnalytics.outputs.workspaceCustomerId

@description('Log Analytics Workspace Name')
output logAnalyticsWorkspaceName string = logAnalytics.outputs.workspaceName

@description('Application Insights Resource ID')
output appInsightsId string = appInsights.outputs.appInsightsId

@description('Application Insights Name')
output appInsightsName string = appInsights.outputs.appInsightsName

@description('Application Insights Instrumentation Key')
output appInsightsInstrumentationKey string = appInsights.outputs.instrumentationKey

@description('Application Insights Connection String')
output appInsightsConnectionString string = appInsights.outputs.connectionString

@description('Storage Account Resource ID')
output storageAccountId string = storage.outputs.storageAccountId

@description('Storage Account Name')
output storageAccountName string = storage.outputs.storageAccountName

@description('Storage Account Connection String')
output storageConnectionString string = storage.outputs.storageConnectionString

@description('Function App Resource ID')
output functionAppId string = functionApp.outputs.functionAppId

@description('Function App Name')
output functionAppName string = functionApp.outputs.functionAppName

@description('Function App Hostname')
output functionAppHostName string = functionApp.outputs.functionAppHostName

@description('Service Bus Namespace ID')
output serviceBusId string = serviceBus.outputs.serviceBusId

@description('Service Bus Namespace Name')
output serviceBusName string = serviceBus.outputs.serviceBusName

@description('Service Bus Connection String')
output serviceBusConnectionString string = serviceBus.outputs.serviceBusConnectionString

@description('Service Bus Queue Name')
output serviceBusQueueName string = serviceBus.outputs.queueName

@description('Logic App Resource ID')
output logicAppId string = logicApp.outputs.logicAppId

@description('Logic App Name')
output logicAppName string = logicApp.outputs.logicAppName

@description('Logic App Callback URL')
output logicAppCallbackUrl string = logicApp.outputs.logicAppCallbackUrl

@description('API Management Resource ID')
output apimId string = apiManagement.outputs.apimId

@description('API Management Name')
output apimName string = apiManagement.outputs.apimName

@description('API Management Gateway URL')
output apimGatewayUrl string = apiManagement.outputs.apimGatewayUrl

@description('Resource Group Name')
output resourceGroupName string = resourceGroup().name

@description('Resource Group Location')
output resourceGroupLocation string = resourceGroup().location
