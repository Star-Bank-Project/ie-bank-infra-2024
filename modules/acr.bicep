@description('The name of the Azure Container Registry')
param name string

@description('The location of the Azure Container Registry')
param location string = resourceGroup().location

@description('The name of the Key Vault where credentials will be stored')
param keyVaultName string
@secure()
param keyVaultSecretAdminUsername string
@secure()
param keyVaultSecretAdminPassword0 string
@secure()
param keyVaultSecretAdminPassword1 string
param logAnalyticsWorkspaceId string

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true // this line allows the ACR to generate a username and password (admin credentials) for authentication.
  }
  dependsOn: [
    adminCredentialsKeyVault
  ]
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: ContainerRegistryDiagnostics
  scope: containerRegistry // Attach to the Container Registry
  properties: {
    workspaceId: logAnalyticsWorkspaceId // Log Analytics Workspace ID
    logs: [
      {
        category: 'ContainerRegistryLoginEvents' // Tracks login events
        enabled: true
      }
      {
        category: 'ContainerRegistryRepositoryEvents' // Tracks repository events (push, pull, delete)
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics' // Tracks metrics for ACR
        enabled: true
      }
    ]
  }



// Define the Key Vault as a direct resource
resource adminCredentialsKeyVault 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  name: keyVaultName
  scope: resourceGroup()
}

// Store the ACR admin username in the Key Vault
resource secretAdminUserName 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: keyVaultSecretAdminUsername
  parent: adminCredentialsKeyVault
  properties: {
    value: containerRegistry.listCredentials().username
  }
}

// Store the first ACR admin password in the Key Vault
resource secretAdminUserPassword0 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: keyVaultSecretAdminPassword0
  parent: adminCredentialsKeyVault
  properties: {
    value: containerRegistry.listCredentials().passwords[0].value
  }
}

// Store the second ACR admin password in the Key Vault
resource secretAdminUserPassword1 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: keyVaultSecretAdminPassword1
  parent: adminCredentialsKeyVault
  properties: {
    value: containerRegistry.listCredentials().passwords[1].value
  }
}

// Output the ACR name
output containerRegistryName string = containerRegistry.name
