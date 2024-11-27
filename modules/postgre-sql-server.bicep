param location string = resourceGroup().location
param name string
param postgreSQLAdminServicePrincipalObjectId string
param postgreSQLAdminServicePrincipalName string

resource postgreSQLServer 'Microsoft.DBforPostgreSQL/flexibleServers@2022-12-01' = {
  name: name
  location: location
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: 'iebankdbadmin'
    // administratorLoginPassword: 'IE.Bank.DB.Admin.Pa$$'
    createMode: 'Default'
    highAvailability: {
      mode: 'Disabled'
      standbyAvailabilityZone: ''
    }
    storage: {
      storageSizeGB: 32
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    version: '15'
    authConfig: {
      activeDirectoryAuth: 'Enabled'
      passwordAuth: 'Enabled' //this is the code that enables the postgreSQLAdministrators resource to work
    }
    //tenantId: subscription().tenantId
  }
}

resource postgreSQLServerFirewallRules 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2022-12-01' = {
  parent: postgreSQLServer
  name: 'AllowAllAzureServicesAndResourcesWithinAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

//this is the managed identity aspect
resource postgreSQLAdministrators 'Microsoft.DBforPostgreSQL/flexibleServers/administrators@2022-12-01' = {
  name: postgreSQLAdminServicePrincipalObjectId
  properties: {
    principalName: postgreSQLAdminServicePrincipalName
    principalType: 'ServicePrincipal'
    tenantId: subscription().tenantId
  }
  dependsOn: [
    postgreSQLServerFirewallRules
  ]
}

output id string = postgreSQLServer.id
output fullyQualifiedDomainName string = postgreSQLServer.properties.fullyQualifiedDomainName
