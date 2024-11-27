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
param dockerRegistryImageName string
param dockerRegistryImageVersion string = 'latest'
param acrAdminUsername string
@secure()
param acrAdminPassword0 string
@secure()
param acrAdminPassword1 string

var acrUsernameSecretName = 'acrAdminUsername'
var acrPassword0SecretName = 'acrAdminPassword0'

module acr './modules/acr.bicep' = {
  name: 'acr-${userAlias}'
  params: {
    name: containerRegistryName
    location: location
    keyVaultName: keyVaultName
    keyVaultSecretAdminUsername: acrAdminUsername // Secret name for the admin username
    keyVaultSecretAdminPassword0: acrAdminPassword0 // Secret name for password 0
    keyVaultSecretAdminPassword1: acrAdminPassword1 // Secret name for password 1
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

module postgresSQLServer 'modules/postgre-sql-server.bicep' = {
  name: 'psqlsrv-${userAlias}'
  params: {
  name: postgreSQLServerName
  postgreSQLAdminServicePrincipalObjectId: appServiceWebsiteBE.outputs.systemAssignedIdentityPrincipalId
  postgreSQLAdminServicePrincipalName: appServiceWebsiteBEName
  }
  dependsOn: [
  appServiceWebsiteBE
  ]
  }

module postgreSQLDatabase 'modules/postgre-sql-db.bicep' = {
  name: 'psqldb-${userAlias}'
  params: {
    name: postgreSQLDatabaseName
    postgresSqlServerName: postgreSQLServerName
  }
  dependsOn: [
    postgresSQLServer
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
}

resource keyVaultReference 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

module appServiceWebsiteBE 'modules/app-service-container.bicep' = {
  name: 'appbe-${userAlias}'
  params: {
  name: appServiceWebsiteBEName
  location: location
  appServicePlanId: appServicePlan.outputs.id
  appCommandLine: ''
  appSettings: appServiceWebsiteBeAppSettings //change: "keyvault please, get the value from getSecret"
  dockerRegistryName: containerRegistryName
  dockerRegistryServerUserName: keyVaultReference.getSecret(acrUsernameSecretName)
  dockerRegistryServerPassword: keyVaultReference.getSecret(acrPassword0SecretName)
  dockerRegistryImageName: dockerRegistryImageName
  dockerRegistryImageVersion: dockerRegistryImageVersion
  }
  dependsOn: [
  appServicePlan
  acr
  keyVault
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
