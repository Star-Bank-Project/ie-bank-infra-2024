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
param logAnalyticsWorkspaceName string
param appInsightsName string

var acrUsernameSecretName = 'acrAdminUsername'
var acrPassword0SecretName = 'acrAdminPassword0'

/* Log Analytics Workspace Module */
module logAnalytics './modules/infrastructure/log-analytics.bicep' = {
  name: 'logAnalytics-${userAlias}'
  params: {
    location: location
    name: logAnalyticsWorkspaceName
  }
}

/* Application Insights Module */
module appInsights './modules/infrastructure/app-insights.bicep' = {
  name: 'appInsights-${userAlias}'
  params: {
    location: location
    appInsightsName: appInsightsName
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
  dependsOn: [
    logAnalytics
  ]
}

/* Azure Container Registry Module */
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

/* Key Vault Module */
module keyVault './modules/keyVault.bicep' = {
  name: 'keyVaultModule-${userAlias}'
  params: {
    name: keyVaultName
    location: location
    enableVaultForDeployment: true
    roleAssignments: roleAssignments
  }
}

/* PostgreSQL Server Module */
module postgresSQLServer './modules/postgre-sql-server.bicep' = {
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

/* PostgreSQL Database Module */
module postgreSQLDatabase './modules/postgre-sql-db.bicep' = {
  name: 'psqldb-${userAlias}'
  params: {
    name: postgreSQLDatabaseName 
    postgresSqlServerName: postgreSQLServerName 
  }
  dependsOn: [
    postgresSQLServer
  ]
}

/* App Service Plan */
module appServicePlan './modules/app-service-plan.bicep' = {
  name: 'appServicePlan-${userAlias}'
  params: {
    location: location
    appServicePlanName: appServicePlanName
    skuName: (environmentType == 'prod') ? 'B1' : 'B1'
  }
}

/* Key Vault Resource Reference */
resource keyVaultReference 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

/* App Service Backend Module */
module appServiceWebsiteBE './modules/app-service-container.bicep' = {
  name: 'appbe-${userAlias}'
  params: {
    name: appServiceWebsiteBEName
    location: location
    appServicePlanId: appServicePlan.outputs.id
    appCommandLine: ''
    appSettings: appServiceWebsiteBeAppSettings // Use Key Vault secrets for app settings
    dockerRegistryName: containerRegistryName
    dockerRegistryServerUserName: keyVaultReference.getSecret(acrUsernameSecretName)
    dockerRegistryServerPassword: keyVaultReference.getSecret(acrPassword0SecretName)
    dockerRegistryImageName: dockerRegistryImageName
    dockerRegistryImageVersion: dockerRegistryImageVersion
    appInsightsInstrumentationKey: appInsights.outputs.appInsightsInstrumentationKey
  }
  dependsOn: [
    appServicePlan
    acr
    keyVault
    appInsights
  ]
}

/* App Service Frontend Module */
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
output logAnalyticsWorkspaceId string = logAnalytics.outputs.logAnalyticsWorkspaceId
output appInsightsInstrumentationKey string = appInsights.outputs.appInsightsInstrumentationKey
