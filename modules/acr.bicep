@description('The name of the Azure Container Registry')
param name string

@description('The location of the Azure Container Registry')
param location string = resourceGroup().location

@description('The name of the Key Vault where credentials will be stored')
param keyVaultName string

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true // Enables admin credentials
  }
  dependsOn: [
    adminCredentialsKeyVault
  ]
}

// Define the Key Vault as a direct resource
resource adminCredentialsKeyVault 'Microsoft.KeyVault/vaults@2021-10-01' existing = {
  name: keyVaultName
  scope: resourceGroup()
}

// Store the ACR admin username as `dockerRegistryServerUserName`
resource secretAdminUserName 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: 'dockerRegistryServerUserName'
  parent: adminCredentialsKeyVault
  properties: {
    value: containerRegistry.listCredentials().username
  }
}

// Store the first ACR admin password as `dockerRegistryServerPassword`
resource secretAdminUserPassword0 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: 'dockerRegistryServerPassword'
  parent: adminCredentialsKeyVault
  properties: {
    value: containerRegistry.listCredentials().passwords[0].value
  }
}

// Output the ACR name
output containerRegistryName string = containerRegistry.name
