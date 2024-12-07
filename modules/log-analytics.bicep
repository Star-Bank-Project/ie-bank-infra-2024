@description('Log Analytics workspace name')
param name string 

@description('Azure location for the resources to deploy')
param location string = resourceGroup().location

@description('Retention period for Log Analytics workspace in days')
@minValue(7)
@maxValue(730)
param retentionInDays int = 30

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: name
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'  // Default pricing tier; adjust if needed
    }
    retentionInDays: retentionInDays  // Customizable retention period
  }
}

// Outputs for integration with other resources
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name
output logAnalyticsWorkspaceResourceGroup string = resourceGroup().name
output logAnalyticsWorkspaceLocation string = logAnalyticsWorkspace.location
