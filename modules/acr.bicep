@description('The name of the Azure Container Registry')
param name string

@description('The location of the Azure Container Registry')
param location string = resourceGroup().location

@description('The name of the Key Vault where credentials will be stored')
param keyVaultName string
param keyVaultSecretAdminUsername string = 'acrAdminUsername'
param keyVaultSecretAdminPassword0 string = 'acrAdminPassword0'
param keyVaultSecretAdminPassword1 string = 'acrAdminPassword1'

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  sku: {
    name: 'Basic' // Change to 'Standard' or 'Premium' if needed
  }
  properties: {
    adminUserEnabled: true
  }
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

