@description('Location of the resource')
param location string

@description('Name of the Application Insights resource on Azure')
param appInsightsName string

@description('Azure Log Analytics Workspace ID')
param logAnalyticsWorkspaceId string

@description('Slack Webhook URL to send alerts')
@secure()
param slackWebhookUrl string // Default value for Slack Webhook URL

@description('Name of the Logic App')
param logicAppName string

// Logic App resource for sending notifications
resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  properties: {
    state: 'Enabled'
    definition: loadJsonContent('logicAppWorkflow.json') // Ensure 'logicAppWorkflow.json' contains valid JSON.
    parameters: {
      slackWebhookUrl: {
        value: slackWebhookUrl
      }
    }
  }
}

output logicAppId string = logicApp.id
output logicAppName string = logicApp.name

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId  // Links Application Insights to Log Analytics Workspace
    RetentionInDays: 90  
    IngestionMode: 'LogAnalytics'  // Ensures logs are sent to Log Analytics
    publicNetworkAccessForIngestion: 'Enabled'  
    publicNetworkAccessForQuery: 'Enabled'  // Allows querying via public endpoint
  }
}

// Diagnostic Settings for Application Insights
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'DiagnosticSettings-${appInsightsName}'
  scope: appInsights  // Attach to the Application Insights resource
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'Requests'
        enabled: true
      }
      {
        category: 'PageViews'
        enabled: true
      }
      {
        category: 'Exceptions'
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

// Metric Alert for API Response Time Exceeding 500ms
resource apiResponseTimeAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'APIResponseTimeAlert-${appInsightsName}'
  location: 'global'
  properties: {
    description: 'Alert when API response time exceeds 500ms'
    severity: 2
    enabled: true
    scopes: [
      appInsights.id
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
          threshold: 500  // Threshold for alert (500 ms)
          timeAggregation: 'Average'
        }
      ]
    }
    autoMitigate: true
    actions: [
      {
        actionGroupId: logicAppActionGroup.id
        webHookProperties: {
          customMessage: 'API response time exceeded the threshold of 500ms.'
        }
      }
    ]
  }
}

// Metric Alert for Page Load Time Exceeding 2 Seconds
resource pageLoadTimeAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'PageLoadTimeAlert-${appInsightsName}'
  location: 'global'
  properties: {
    description: 'Alert when page load time exceeds the threshold of 2 seconds'
    severity: 3
    enabled: true
    scopes: [
      appInsights.id
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'PageLoadTime'
          criterionType: 'StaticThresholdCriterion'
          metricName: 'browserTimings/totalDuration'
          operator: 'GreaterThan'
          threshold: 2000  // Threshold for alert (2 seconds)
          timeAggregation: 'Average'
        }
      ]
    }
    autoMitigate: true
    actions: [
      {
        actionGroupId: logicAppActionGroup.id
        webHookProperties: {
          customMessage: 'Page load time exceeded the threshold of 2 seconds.'
        }
      }
    ]
  }
}

// Action Group for Slack Notifications
resource logicAppActionGroup 'Microsoft.Insights/actionGroups@2022-06-01' = {
  name: 'Slack-Notification-ActionGroup-${appInsightsName}'
  location: 'global'
  properties: {
    groupShortName: 'SlackAlert'
    enabled: true
    webhookReceivers: [
      {
        name: 'SlackWebhook'
        serviceUri: slackWebhookUrl
        useCommonAlertSchema: true
      }
    ]
  }
}

// Outputs for integration and debugging
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output appInsightsConnectionString string = appInsights.properties.ConnectionString
