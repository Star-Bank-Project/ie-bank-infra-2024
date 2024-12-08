@description('Location of the resource')
param location string = resourceGroup().location

@description('Name of the Logic App')
param logicAppName string = 'StarBankLogicApp'  // Set the Logic App name to StarBankLogicApp

@description('Slack Webhook URL to send alerts')
@secure()
param slackWebhookUrl string

// Logic App resource
resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  properties: {
    state: 'Enabled'
    definition: loadJsonContent('logicAppWorkflow.json') // Ensure 'logicAppWorkflow.json' contains valid JSON.
    parameters: {
      slackWebhookUrl: {
        value: slackWebhookUrl
      }
    }
  }
}

output logicAppId string = logicApp.id
output logicAppName string = logicApp.name
