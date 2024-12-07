param location string = resourceGroup().location
param name string
param appServicePlanId string
param dockerRegistryName string
@secure()
param dockerRegistryServerUserName string
@secure()
param dockerRegistryServerPassword string
param dockerRegistryImageName string
param dockerRegistryImageVersion string = 'latest'
param appSettings array = []
param appCommandLine string = ''
param logAnalyticsWorkspaceId string
@description('The Application Insights Instrumentation Key for monitoring and logging.')


var dockerAppSettings = [
  { name: 'DOCKER_REGISTRY_SERVER_URL', value: 'https://${dockerRegistryName}.azurecr.io' }
  { name: 'DOCKER_REGISTRY_SERVER_USERNAME', value: dockerRegistryServerUserName }
  { name: 'DOCKER_REGISTRY_SERVER_PASSWORD', value: dockerRegistryServerPassword }
  ]

  
  resource appServiceApp 'Microsoft.Web/sites@2022-03-01' = {
    name: name
    location: location
    identity: { 
      type: 'SystemAssigned' // Creates the system-assigned identity 
    }
    properties: {
      serverFarmId: appServicePlanId
      httpsOnly: true
      siteConfig: {
        linuxFxVersion: 'DOCKER|${dockerRegistryName}.azurecr.io/${dockerRegistryImageName}:${dockerRegistryImageVersion}'
        alwaysOn: false
        ftpsState: 'FtpsOnly'
        appCommandLine: appCommandLine
        appSettings: union(appSettings, dockerAppSettings)
      }
    }
  }
  
  resource appServiceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
    name: 'appServiceDiagnostics'
    scope: appServiceApp
    properties: {
      logs: [
        { category: 'AppServiceHTTPLogs', enabled: true }
        { category: 'AppServiceConsoleLogs', enabled: true }
      ]
      metrics: [
        { category: 'AllMetrics', enabled: true }
      ]
      workspaceId: logAnalyticsWorkspaceId
    }
  }  
  

output appServiceBackendHostName string = appServiceApp.properties.defaultHostName
output systemAssignedIdentityPrincipalId string = appServiceApp.identity.principalId
