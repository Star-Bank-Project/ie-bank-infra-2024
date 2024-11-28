@description('The name of the Application Insights resource')
param appInsightsName string

@description('The Azure location where the Application Insights resource will be deployed')
param location string = resourceGroup().location

@description('The ID of the Log Analytics Workspace to integrate with Application Insights')
param logAnalyticsWorkspaceId string

resource appInsights 'Microsoft.Insights/components@2015-05-01' = {
  name: appInsightsName
  location: location
  kind: 'web' // Required property to specify the type of Application Insights instance
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

output appInsightsId string = appInsights.id
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output appInsightsConnectionString string = appInsights.properties.ConnectionString
