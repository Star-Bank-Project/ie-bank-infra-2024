param location string = resourceGroup().location
param name string
param appServicePlanId string
param appSettings array = []
@allowed([
  'PYTHON|3.11'
  'NODE|18-lts'
])
param linuxFxVersion string = 'NODE|18-lts'
param appCommandLine string = ''
param logAnalyticsWorkspaceId string

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


output appServiceAppHostName string = appServiceApp.properties.defaultHostName

