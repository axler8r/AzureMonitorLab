// Logic App module
// Timer-triggered telemetry generator for Azure Monitor Lab
// Sends varied message payloads to Service Bus queue for monitoring demonstrations

@description('The name of the Logic App')
param logicAppName string

@description('The location for the Logic App')
param location string = resourceGroup().location

@description('The resource ID of the Log Analytics Workspace for diagnostics')
param logAnalyticsWorkspaceId string

@description('The connection string for the Service Bus namespace')
@secure()
param serviceBusConnectionString string

@description('The name of the Service Bus queue to send messages to')
param serviceBusQueueName string

@description('The recurrence interval in seconds for the Logic App trigger')
@minValue(10)
@maxValue(3600)
param recurrenceIntervalSeconds int = 30

@description('Tags to apply to the resource')
param tags object = {}

// Logic App (Consumption) - Timer-triggered telemetry generator
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
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        Recurrence: {
          type: 'Recurrence'
          recurrence: {
            frequency: 'Second'
            interval: recurrenceIntervalSeconds
          }
        }
      }
      actions: {
        Initialize_EventTypes: {
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'eventTypes'
                type: 'array'
                value: [
                  'order.created'
                  'user.login'
                  'system.health'
                  'data.sync'
                ]
              }
            ]
          }
          runAfter: {}
        }
        Initialize_Regions: {
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'regions'
                type: 'array'
                value: [
                  'australiaeast'
                  'eastus'
                  'westeurope'
                ]
              }
            ]
          }
          runAfter: {
            Initialize_EventTypes: [
              'Succeeded'
            ]
          }
        }
        Generate_Payload: {
          type: 'Compose'
          inputs: {
            eventId: '@{guid()}'
            eventType: '@{variables(\'eventTypes\')[rand(0, length(variables(\'eventTypes\')))]}'
            timestamp: '@{utcNow()}'
            severity: '@{if(greater(rand(1, 100), 80), \'Error\', if(greater(rand(1, 100), 60), \'Warning\', \'Info\'))}'
            properties: {
              orderId: '@{rand(1000, 9999)}'
              amount: '@{rand(10, 500)}'
              region: '@{variables(\'regions\')[rand(0, length(variables(\'regions\')))]}'
            }
          }
          runAfter: {
            Initialize_Regions: [
              'Succeeded'
            ]
          }
        }
          Send_Message: {
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'servicebus\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/@{encodeURIComponent(encodeURIComponent(\'${serviceBusQueueName}\'))}/messages'
            body: {
              ContentData: '@{base64(string(outputs(\'Generate_Payload\')))}'
            }
          }
          runAfter: {
            Generate_Payload: [
              'Succeeded'
            ]
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          servicebus: {
            connectionId: serviceBusConnection.id
            connectionName: 'servicebus'
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'servicebus')
          }
        }
      }
    }
  }
}

// Service Bus API Connection for Logic App
// Note: This uses V1 connection (connection string auth) which requires
// a one-time manual authorization in the Azure Portal after deployment.
// V2 connections (managed identity) would be fully automated but more complex.
resource serviceBusConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: '${logicAppName}-servicebus-connection'
  location: location
  tags: tags
  properties: {
    displayName: 'Service Bus Connection'
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'servicebus')
    }
    parameterValues: {
      connectionString: serviceBusConnectionString
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

@description('The resource ID of the Service Bus API Connection')
output serviceBusConnectionId string = serviceBusConnection.id

@description('Instructions for one-time authorization step')
output authorizationNote string = 'After deployment, authorize the Service Bus connection in Azure Portal: Go to the API connection resource → Edit API connection → Save (no changes needed, just click Save to authorize)'

@description('Service Bus connection name for reference')
output serviceBusConnectionName string = serviceBusConnection.name
