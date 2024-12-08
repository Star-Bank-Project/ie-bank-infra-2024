@description('The name of the Key Vault')
param name string

@description('The location of the Key Vault')
param location string

@description('Role assignments for the Key Vault')
param roleAssignments array = []

@description('Array of secrets to be added to the Key Vault')
param secrets array = []

@description('Flag to enable the Key Vault for deployment usage')
param enableVaultForDeployment bool = false

@description('The ID of the Log Analytics Workspace for monitoring')
param logAnalyticsWorkspaceId string

@description('The name of the Logic App associated with alerts')
param logicAppName string

var builtInRoleNames = {
  'Key Vault Secrets User': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
  'Key Vault Administrator': subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483')
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: name
  location: location
  properties: {
    enableRbacAuthorization: true
    enableSoftDelete: false
    enabledForTemplateDeployment: true
    enabledForDeployment: enableVaultForDeployment
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: []
  }
}

resource keyVault_roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleAssignment in roleAssignments: {
  name: guid(keyVault.id, roleAssignment.principalId, builtInRoleNames[roleAssignment.roleDefinitionIdOrName])
  properties: {
    roleDefinitionId: builtInRoleNames[roleAssignment.roleDefinitionIdOrName]
    principalId: roleAssignment.principalId
    principalType: roleAssignment.principalType
  }
  scope: keyVault
}]

resource keyVaultSecrets 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = [for secret in secrets: {
  name: secret.name
  parent: keyVault
  properties: {
    value: secret.value
  }
}]

// Diagnostic settings to send logs and metrics to Log Analytics Workspace
resource keyVaultDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'keyVaultDiagnostics'
  scope: keyVault
  properties: {
    logs: [
      {
        category: 'AuditEvent' // Logs for Key Vault activity such as secret access, policy updates
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics' // Collects all metrics, useful for tracking health and usage
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceId // Sends the logs and metrics to your Log Analytics Workspace for analysis
  }
}

// Output resources for external integrations
output keyVaultName string = keyVault.name
output keyVaultResourceId string = keyVault.id
