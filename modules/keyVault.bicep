param name string
param location string
param roleAssignments array = []
param secrets array = []
param enableVaultForDeployment bool = false 

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


