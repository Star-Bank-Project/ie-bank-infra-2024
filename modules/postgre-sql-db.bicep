param name string
param postgresSqlServerName string

resource postgresSQLDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2022-12-01' = {
  name: '${postgresSqlServerName}/${name}'
  properties: {
    charset: 'UTF8'
    collation: 'en_US.UTF8'
  }
}
