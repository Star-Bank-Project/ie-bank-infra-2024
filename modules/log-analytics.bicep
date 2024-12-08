@description('Deployment location for the resource group')
param location string = resourceGroup().location

@description('The name of the Log Analytics workspace to be created')
param name string

@description('Retention period for Log Analytics workspace in days')
@minValue(7)
@maxValue(730)
param retentionInDays int = 30

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: name
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
  }
}

output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name
