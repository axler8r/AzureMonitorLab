// Logic App module
// Provides workflow automation for alerting and incident response

@description('The name of the Logic App')
param logicAppName string

@description('The location for the Logic App')
param location string = resourceGroup().location

@description('The resource ID of the Log Analytics Workspace for diagnostics')
param logAnalyticsWorkspaceId string

@description('Email address for alert notifications')
param alertEmailAddress string = ''

@description('Tags to apply to the resource')
param tags object = {}

// Logic App (Consumption)
resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: tags
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        alertEmail: {
          type: 'string'
          defaultValue: alertEmailAddress
        }
      }
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              type: 'object'
              properties: {
                alertName: {
                  type: 'string'
                }
                severity: {
                  type: 'string'
                }
                description: {
                  type: 'string'
                }
                timestamp: {
                  type: 'string'
                }
              }
            }
          }
        }
      }
      actions: {
        Response: {
          type: 'Response'
          kind: 'Http'
          inputs: {
            statusCode: 200
            body: {
              message: 'Alert received and processed'
              alertName: '@{triggerBody()?[\'alertName\']}'
              receivedAt: '@{utcNow()}'
              notificationEmail: '@{parameters(\'alertEmail\')}'
            }
          }
          runAfter: {}
        }
      }
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

@description('The callback URL for the Logic App trigger')
output logicAppCallbackUrl string = listCallbackUrl('${logicApp.id}/triggers/manual', '2019-05-01').value
