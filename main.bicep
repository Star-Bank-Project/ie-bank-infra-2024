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

param logicAppName string

/* Variables for Key Vault Secrets */
var acrUsernameSecretName = 'acrAdminUsername'
var acrPassword0SecretName = 'acrAdminPassword0'

/* Log Analytics Workspace Module */
module logAnalytics './modules/log-analytics.bicep' = {
  name: 'logAnalytics-${userAlias}'
  params: {
    logicAppName: logicAppName
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
    logicAppName: logicAppName
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
    logicAppName: logicAppName
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
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
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

/* Application Insights Diagnostic Settings */
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'DiagnosticSettings-${userAlias}'
  scope: resourceGroup() // Attach to the resource group
  properties: {
    workspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
    logs: [
      {
        category: 'ApplicationGatewayAccessLogs'
        enabled: true
      }
      {
        category: 'ApplicationGatewayPerformanceLogs'
        enabled: true
      }
      {
        category: 'Requests'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

/* Metric Alert for API Response Time */
resource apiResponseTimeAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'APIResponseTimeAlert-${userAlias}'
  location: 'global'
  properties: {
    description: 'Alert when API response time exceeds the threshold'
    severity: 2
    enabled: true
    scopes: [
      appInsights.outputs.appInsightsInstrumentationKey
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'APIResponseTime'
          criterionType: 'StaticThresholdCriterion'
          metricName: 'requests/duration'
          operator: 'GreaterThan'
          threshold: 5000 // Threshold for alert (e.g., 5000 ms or 5 seconds)
          timeAggregation: 'Average'
        }
      ]
    }
    autoMitigate: true
    actions: [
      {
        actionGroupId: logicAppActionGroup.id
        webHookProperties: {
          customMessage: 'API response time exceeded threshold.'
        }
      }
    ]
  }
}

/* Action Group for Alert Notification (Slack) */
resource logicAppActionGroup 'Microsoft.Insights/actionGroups@2022-06-01' = {
  name: 'Slack-Notification-ActionGroup'
  location: 'global'
  properties: {
    groupShortName: 'SlackAlert'
    enabled: true
    webhookReceivers: [
      {
        name: 'SlackWebhook'
        serviceUri: 'https://hooks.slack.com/services/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'  // Your Slack Webhook URL
        useCommonAlertSchema: true
      }
    ]
  }
}

/* Outputs */
output appServiceWebsiteBEHostName string = appServiceWebsiteBE.outputs.appServiceBackendHostName
output appServiceWebsiteFEHostName string = appServiceWebsiteFE.outputs.appServiceAppHostName
output logAnalyticsWorkspaceId string = logAnalytics.outputs.logAnalyticsWorkspaceId
output appInsightsInstrumentationKey string = appInsights.outputs.appInsightsInstrumentationKey
