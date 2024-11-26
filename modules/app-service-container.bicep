param location string = resourceGroup().location
param name string
param appServicePlanId string
param appSettings array = []
@allowed([
  'PYTHON|3.11'
  'NODE|18-lts'
])
param linuxFxVersion string = 'PYTHON|3.11'
param appCommandLine string = ''

resource appServiceBackend 'Microsoft.Web/sites@2022-03-01' = {
  name: name
  location: location
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      alwaysOn: true
      ftpsState: 'FtpsOnly'
      appCommandLine: appCommandLine
      appSettings: appSettings
    }
  }
}

output appServiceBackendHostName string = appServiceBackend.properties.defaultHostName

