@description('Location of the resource')
param location string

@description('Name of the Application Insights resource on Azure')
param appInsightsName string

@description('Azure Log Analytics Workspace ID')
param logAnalyticsWorkspaceId string

@description('Slack Webhook URL to send alerts')
@secure()
param slackWebhookUrl string

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    WorkspaceResourceId: logAnalyticsWorkspaceId  // Links Application Insights to Log Analytics Workspace
    RetentionInDays: 90  
    IngestionMode: 'LogAnalytics'  // Ensures logs are sent to Log Analytics
    publicNetworkAccessForIngestion: 'Enabled'  
    publicNetworkAccessForQuery: 'Enabled'  // Allows querying via public endpoint
  }
}

// Login SLO Alert: Response time exceeding 5 seconds
resource loginResponseTimeAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'Login-Response-Time-Alert'
  location: 'global'
  properties: {
    description: 'Alert when login response time exceeds 5 seconds'
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
          name: 'LoginResponseTime'
          criterionType: 'StaticThresholdCriterion'
          metricName: 'requests/duration'
          operator: 'GreaterThan'
          threshold: 5000  // Threshold in milliseconds
          timeAggregation: 'Average'
        }
      ]
    }
    autoMitigate: true
    actions: [
      {
        actionGroupId: slackActionGroup.id
        webHookProperties: {
          customMessage: 'Login response time exceeded 5 seconds. Immediate attention required.'
        }
      }
    ]
  }
}

// Page Load Time Alert: Duration exceeding 2 seconds
resource pageLoadTimeAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'Page-Load-Time-Alert'
  location: 'global'
  properties: {
    description: 'Alert when page load time exceeds 2 seconds'
    severity: 4
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
          threshold: 2000  // Threshold in milliseconds
          timeAggregation: 'Average'
        }
      ]
    }
    autoMitigate: true
    actions: [
      {
        actionGroupId: slackActionGroup.id
        webHookProperties: {
          customMessage: 'Page load time exceeded 2 seconds. Please check immediately.'
        }
      }
    ]
  }
}

// Action Group for Slack Notifications
resource slackActionGroup 'Microsoft.Insights/actionGroups@2022-06-01' = {
  name: 'Slack-Notification-ActionGroup'
  location: 'global'
  properties: {
    groupShortName: 'SlackAlerts'
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

// Outputs for integration or validation
output appInsightsId string = appInsights.id
output instrumentationKey string = appInsights.properties.InstrumentationKey
output insightsConnectionString string = appInsights.properties.ConnectionString
