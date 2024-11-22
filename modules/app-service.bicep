param location string = resourceGroup().location
param appServicePlanName string
param appServiceAppName string
param appServiceAPIAppName string
param appServiceAPIEnvVarENV string //API environment configuration (parameters = nonprod, prod)
param appServiceAPIEnvVarDBHOST string //database environment variables
param appServiceAPIEnvVarDBNAME string //db
@secure()
param appServiceAPIEnvVarDBPASS string //db 
param appServiceAPIDBHostDBUSER string // db
param appServiceAPIDBHostFLASK_APP string //specifies the Flask application to run
param appServiceAPIDBHostFLASK_DEBUG string //configures the Flask debug mode
@allowed([ 
  'nonprod'
  'prod'
  'uat'
])
param environmentType string

var appServicePlanSkuName = (environmentType == 'prod') ? 'B1' : 'B1' //sets the SKU for the ASP (both B1)

resource appServicePlan 'Microsoft.Web/serverFarms@2022-03-01' = { //creates an ASP, which provides the compute infra for hosting App services
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanSkuName
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource appServiceAPIApp 'Microsoft.Web/sites@2022-03-01' = {  //deploys a Python-based App Service for the API, running on the ASP
  name: appServiceAPIAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: { //secure configuration
      linuxFxVersion: 'PYTHON|3.11'
      alwaysOn: false
      ftpsState: 'FtpsOnly'
      appSettings: [
        {
          name: 'ENV'
          value: appServiceAPIEnvVarENV
        }
        {
          name: 'DBHOST'
          value: appServiceAPIEnvVarDBHOST
        }
        {
          name: 'DBNAME'
          value: appServiceAPIEnvVarDBNAME
        }
        {
          name: 'DBPASS'
          value: appServiceAPIEnvVarDBPASS
        }
        {
          name: 'DBUSER'
          value: appServiceAPIDBHostDBUSER
        }
        {
          name: 'FLASK_APP'
          value: appServiceAPIDBHostFLASK_APP
        }
        {
          name: 'FLASK_DEBUG'
          value: appServiceAPIDBHostFLASK_DEBUG
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
      ]
    }
  }
}

resource appServiceApp 'Microsoft.Web/sites@2022-03-01' = {  //deploys a Node.js-based App Service for the frontend application
  name: appServiceAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|18-lts'
      alwaysOn: false
      ftpsState: 'FtpsOnly'
      appCommandLine: 'pm2 serve /home/site/wwwroot --spa --no-daemon'
      appSettings: []
    }
  }
}

output appServiceAppHostName string = appServiceApp.properties.defaultHostName 
