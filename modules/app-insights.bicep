@description('Location of the resource')
param location string

@description('Name of the Application Insights resource on Azure')
param appInsightsName string

@description('Azure Log Analytics Workspace ID')
param logAnalyticsWorkspaceId string

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    WorkspaceResourceId: logAnalyticsWorkspaceId  // Links Application Insights to Log Analytics Workspace
    RetentionInDays: 90  
    IngestionMode: 'LogAnalytics'  // Ensures logs are sent to Log Analytics
    publicNetworkAccessForIngestion: 'Enabled'  
    publicNetworkAccessForQuery: 'Enabled'  // Allows querying via public endpoint
  }
}

// Outputs to integrate with other modules or validate deployment
output id string = appInsights.id
output instrumentationKey string = appInsights.properties.InstrumentationKey
output insightsConnectionString string = appInsights.properties.ConnectionString
