param location string = resourceGroup().location
param name string
param appServicePlanId string
param appSettings array = []
param logAnalyticsWorkspaceId string

@allowed([
  'PYTHON|3.11'
  'NODE|18-lts'
])
param linuxFxVersion string = 'NODE|18-lts'
param appCommandLine string = ''

resource appServiceApp 'Microsoft.Web/sites@2022-03-01' = {
  name: name
  location: location
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      alwaysOn: false
      ftpsState: 'FtpsOnly'
      appCommandLine: appCommandLine
      appSettings: appSettings
    }
  }
}
resource appServiceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'appServiceDiagnostics'
  scope: appServiceApp
  properties: {
    logs: [
      { category: 'AppServiceHTTPLogs', enabled: true, retentionPolicy: { enabled: false, days: 0 } }
      { category: 'AppServiceConsoleLogs', enabled: true, retentionPolicy: { enabled: false, days: 0 } }
    ]
    metrics: [
      { category: 'AllMetrics', enabled: true, retentionPolicy: { enabled: false, days: 0 } }
    ]
    workspaceId: logAnalyticsWorkspaceId
  }
}

output appServiceAppHostName string = appServiceApp.properties.defaultHostName

