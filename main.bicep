@allowed([
  'nonprod'
  'prod'
  'uat'
])
param environmentType string 
param userAlias string
param containerRegistryName string 
param keyVaultName string 
param roleAssignments array = []
param postgreSQLServerName string 
param postgreSQLDatabaseName string
param appServicePlanName string 
param appServiceWebsiteBEName string 
param appServiceWebsiteFEName string 
param location string = resourceGroup().location
param appServiceWebsiteBeAppSettings array

module acr './modules/acr.bicep' = {
  name: 'acr-${userAlias}'
  params: {
    name: containerRegistryName
    location: location
    keyVaultName: keyVaultName
    keyVaultSecretAdminUsername: 'acrAdminUsername' // Secret name for the admin username
    keyVaultSecretAdminPassword0: 'acrAdminPassword0' // Secret name for password 0
    keyVaultSecretAdminPassword1: 'acrAdminPassword1' // Secret name for password 1
  }
}

module keyVault './modules/keyVault.bicep' = {
  name: 'KeyVaultModule'
  params: {
    name: keyVaultName
    location: location
    enableVaultForDeployment: true
    roleAssignments: roleAssignments
    //secrets: secrets
  }
}

module postgreSQLServer './modules/postgre-sql-server.bicep' = {
  name: 'pgsqlsrv-${userAlias}'
  params: {
    name: postgreSQLServerName
    location: location
  }
}

module postgreSQLDatabase 'modules/postgre-sql-db.bicep' = {
  name: 'psqldb-${userAlias}'
  params: {
    name: postgreSQLDatabaseName
    postgresSqlServerName: postgreSQLServer.outputs.id
  }
  dependsOn: [
    postgreSQLServer
  ]
}

// Deploy App Service Plan
module appServicePlan 'modules/app-service-plan.bicep' = {
  name: 'appServicePlan-${userAlias}'
  params: {
    location: location
    appServicePlanName: appServicePlanName
    skuName: (environmentType == 'prod') ? 'B1' : 'B1'
  }
  dependsOn: [
    postgreSQLDatabase
  ]
}

module appServiceWebsiteBE './modules/app-service-container.bicep' = {
  name: 'appbe-${userAlias}'
  params: {
    name: appServiceWebsiteBEName
    location: location
    appServicePlanId: appServicePlan.outputs.id
    appSettings: appServiceWebsiteBeAppSettings
    linuxFxVersion: 'PYTHON|3.11'
  }
  dependsOn: [
    appServicePlan
    postgreSQLDatabase
  ]
}

module appServiceWebsiteFE './modules/app-service-website.bicep' = {
  name: 'appfe-${userAlias}'
  params: {
    name: appServiceWebsiteFEName
    location: location
    appServicePlanId: appServicePlan.outputs.id
    linuxFxVersion: 'NODE|18-lts'
    appCommandLine: 'pm2 serve /home/site/wwwroot --spa --no-daemon'
  }
  dependsOn: [
    appServicePlan
  ]
}

output appServiceWebsiteBEHostName string = appServiceWebsiteBE.outputs.appServiceBackendHostName
output appServiceWebsiteFEHostName string = appServiceWebsiteFE.outputs.appServiceAppHostName

