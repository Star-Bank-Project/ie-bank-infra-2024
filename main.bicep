@allowed([
  'nonprod'
  'prod'
  'uat'
])
param environmentType string
@description('User alias for naming resources')
param userAlias string

@description('Azure Container Registry name')
param containerRegistryName string

@description('Key Vault name')
param keyVaultName string

@description('Role assignments for Key Vault')
param roleAssignments array = []

@description('PostgreSQL Server name')
param postgreSQLServerName string

@description('PostgreSQL Database name')
param postgreSQLDatabaseName string

@description('App Service Plan name')
param appServicePlanName string

@description('Backend App Service name')
param appServiceWebsiteBEName string

@description('Frontend App Service name')
param appServiceWebsiteFEName string

@description('Azure region for deployment')
param location string = resourceGroup().location

@description('App settings for the Backend App Service')
param appServiceWebsiteBeAppSettings array

@description('Docker image name')
param dockerRegistryImageName string

@description('Docker image version (tag)')
param dockerRegistryImageVersion string = 'latest'

@description('Azure Container Registry admin username')
param acrAdminUsername string

@description('Azure Container Registry admin password 0')
@secure()
param acrAdminPassword0 string

@description('Azure Container Registry admin password 1')
@secure()
param acrAdminPassword1 string

@description('Log Analytics Workspace name')
param logAnalyticsWorkspaceName string

@description('Application Insights resource name')
param appInsightsName string

/* Variables for Key Vault Secrets */
var acrUsernameSecretName = 'acrAdminUsername'
var acrPassword0SecretName = 'acrAdminPassword0'

/* Log Analytics Workspace Module */
module logAnalytics './modules/log-analytics.bicep' = {
  name: 'logAnalytics-${userAlias}'
  params: {
    location: location
    name: logAnalyticsWorkspaceName
  }
}

/* Application Insights Module */
module appInsights './modules/app-insights.bicep' = {
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
    keyVaultSecretAdminUsername: acrAdminUsername
    keyVaultSecretAdminPassword0: acrAdminPassword0
    keyVaultSecretAdminPassword1: acrAdminPassword1
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
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
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
}

/* PostgreSQL Server Module */
module postgresSQLServer './modules/postgre-sql-server.bicep' = {
  name: 'psqlsrv-${userAlias}'
  params: {
    name: postgreSQLServerName
    postgreSQLAdminServicePrincipalObjectId: appServiceWebsiteBE.outputs.systemAssignedIdentityPrincipalId
    postgreSQLAdminServicePrincipalName: appServiceWebsiteBEName
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
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

/* App Service Plan Module */
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

/* BE */
module appServiceWebsiteBE './modules/app-service-container.bicep' = {
  name: 'appbe-${userAlias}'
  params: {
    name: appServiceWebsiteBEName
    location: location
    appServicePlanId: appServicePlan.outputs.id
    appCommandLine: ''
    appSettings: appServiceWebsiteBeAppSettings
    dockerRegistryName: containerRegistryName
    dockerRegistryServerUserName: keyVaultReference.getSecret(acrUsernameSecretName)
    dockerRegistryServerPassword: keyVaultReference.getSecret(acrPassword0SecretName)
    dockerRegistryImageName: dockerRegistryImageName
    dockerRegistryImageVersion: dockerRegistryImageVersion
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
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
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
  dependsOn: [
    appServicePlan
  ]
}

/* Outputs */
output appServiceWebsiteBEHostName string = appServiceWebsiteBE.outputs.appServiceBackendHostName
output appServiceWebsiteFEHostName string = appServiceWebsiteFE.outputs.appServiceAppHostName
output logAnalyticsWorkspaceId string = logAnalytics.outputs.logAnalyticsWorkspaceId
output appInsightsInstrumentationKey string = appInsights.outputs.instrumentationKey 
