// Logic App module - Service Bus Sender
// Minimal Logic App with Recurrence trigger for Azure Monitor Lab
// Participants will build workflow to send messages to Service Bus queue

@description('The name of the Logic App')
param logicAppName string

@description('The location for the Logic App')
param location string = resourceGroup().location

@description('The resource ID of the Log Analytics Workspace for diagnostics')
param logAnalyticsWorkspaceId string

@description('The recurrence interval in seconds for the Logic App trigger')
@minValue(10)
@maxValue(3600)
param recurrenceIntervalSeconds int = 60

@description('Tags to apply to the resource')
param tags object = {}

// Logic App (Consumption) - Minimal workflow with Recurrence trigger only
resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      triggers: {
        Recurrence: {
          type: 'Recurrence'
          recurrence: {
            frequency: 'Second'
            interval: recurrenceIntervalSeconds
          }
        }
      }
      actions: {}
      outputs: {}
    }
  }
}


// Diagnostic Settings for Logic App
resource logicAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: logicApp
  name: 'logicapp-diagnostics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'WorkflowRuntime'
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
@description('The resource ID of the Logic App')
output logicAppId string = logicApp.id

@description('The name of the Logic App')
output logicAppName string = logicApp.name
