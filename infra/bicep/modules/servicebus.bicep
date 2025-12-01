// Service Bus module
// Provides messaging infrastructure for event-driven scenarios

@description('The name of the Service Bus namespace')
param serviceBusNamespaceName string

@description('The location for the Service Bus')
param location string = resourceGroup().location

@description('The SKU for the Service Bus namespace')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Standard'

@description('The resource ID of the Log Analytics Workspace for diagnostics')
param logAnalyticsWorkspaceId string

@description('Tags to apply to the resource')
param tags object = {}

// Service Bus Namespace
resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  tags: tags
  sku: {
    name: sku
    tier: sku
  }
  properties: {
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

// Service Bus Queue for lab scenarios
resource serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = {
  parent: serviceBusNamespace
  name: 'lab-queue'
  properties: {
    lockDuration: 'PT1M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: true
    maxDeliveryCount: 10
    enablePartitioning: false
    enableExpress: false
  }
}

// Service Bus Topic for pub/sub scenarios
resource serviceBusTopic 'Microsoft.ServiceBus/namespaces/topics@2022-10-01-preview' = {
  parent: serviceBusNamespace
  name: 'lab-topic'
  properties: {
    maxSizeInMegabytes: 1024
    defaultMessageTimeToLive: 'P14D'
    requiresDuplicateDetection: false
    enablePartitioning: false
    enableExpress: false
  }
}

// Topic Subscription
resource serviceBusSubscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2022-10-01-preview' = {
  parent: serviceBusTopic
  name: 'lab-subscription'
  properties: {
    lockDuration: 'PT1M'
    requiresSession: false
    defaultMessageTimeToLive: 'P14D'
    deadLetteringOnMessageExpiration: true
    maxDeliveryCount: 10
  }
}

// Authorization Rule for connection string
resource serviceBusAuthRule 'Microsoft.ServiceBus/namespaces/authorizationRules@2022-10-01-preview' = {
  parent: serviceBusNamespace
  name: 'RootManageSharedAccessKey'
  properties: {
    rights: [
      'Listen'
      'Send'
      'Manage'
    ]
  }
}

// Diagnostic Settings for Service Bus
resource serviceBusDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: serviceBusNamespace
  name: 'servicebus-diagnostics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'OperationalLogs'
        enabled: true
      }
      {
        category: 'RuntimeAuditLogs'
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
@description('The resource ID of the Service Bus namespace')
output serviceBusId string = serviceBusNamespace.id

@description('The name of the Service Bus namespace')
output serviceBusName string = serviceBusNamespace.name

@description('The Service Bus connection string')
output serviceBusConnectionString string = serviceBusAuthRule.listKeys().primaryConnectionString

@description('The Service Bus namespace endpoint')
output serviceBusEndpoint string = serviceBusNamespace.properties.serviceBusEndpoint

@description('The name of the Service Bus queue')
output queueName string = serviceBusQueue.name

@description('The name of the Service Bus topic')
output topicName string = serviceBusTopic.name
