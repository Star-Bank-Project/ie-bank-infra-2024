@description('Log Analytics workspace name')
param name string

@description('Azure location for the resources to deploy')
param location string = resourceGroup().location



// Create the Log Analytics workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: name
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'  // Default pricing tier; adjust if needed
    }
    retentionInDays: 30  
  }
}


// Outputs for integration with other resources
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name
