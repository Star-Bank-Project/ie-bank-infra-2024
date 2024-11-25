param location string = resourceGroup().location
param name string

resource postgreSQLServer 'Microsoft.DBforPostgreSQL/flexibleServers@2022-12-01' = {
  name: name
  location: location
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: 'iebankadmin'
    administratorLoginPassword: 'IE.Bank.DB.Admin.Pa55'
    version: '15'
    highAvailability: {
      mode: 'Disabled'
      standbyAvailabilityZone: ''
    }
    storage: {
      storageSizeGB: 32
    }
    backup: {
      geoRedundantBackup: 'Disabled'
      backupRetentionDays: 7
    }
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


output id string = postgreSQLServer.id
output fullyQualifiedDomainName string = postgreSQLServer.properties.fullyQualifiedDomainName
