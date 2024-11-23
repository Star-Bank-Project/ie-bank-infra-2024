@description('The name of the Azure Container Registry')
param name string

@description('The location of the Azure Container Registry')
param location string = resourceGroup().location

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

//output containerRegistryUserName string = containerRegistry.listCredentials().username
//output containerRegistryPassword0 string = containerRegistry.listCredentials().passwords[0].value
//output containerRegistryPassword1 string = containerRegistry.listCredentials().passwords[1].value

/*commented out to avoid: Error: WARNING: /home/runner/work/ie-bank-infra/ie-bank-infra/modules/acr.bicep(18,43) : 
Warning outputs-should-not-contain-secrets: Outputs should not contain secrets. Found possible secret: function 
'listCredentials' [https://aka.ms/bicep/linter/outputs-should-not-contain-secrets]*/

/*will be added later with key-vault*/
