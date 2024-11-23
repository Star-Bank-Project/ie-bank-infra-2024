using '../main.bicep'

param appServiceAPIDBHostDBUSER = az.getSecret(
  'e0b9cada-61bc-4b5a-bd7a-52c606726b3b', // Subscription ID
  'BCSAI2024-DEVOPS-STUDENTS-B-UAT',      // Resource Group Name for UAT
  'makenna-keyvault-uat',                         // Key Vault Name
  'dbUser',                               // Secret Name
  'latest'                                // Secret Version
)

param appServiceAPIEnvVarDBPASS = az.getSecret(
  'e0b9cada-61bc-4b5a-bd7a-52c606726b3b', // Subscription ID
  'BCSAI2024-DEVOPS-STUDENTS-B-UAT',      // Resource Group Name for UAT
  'makenna-keyvault-uat',                         // Key Vault Name
  'dbPassword',                           // Secret Name
  'latest'                                // Secret Version
)

param appServiceAPIDBHostFLASK_APP = az.getSecret(
  'e0b9cada-61bc-4b5a-bd7a-52c606726b3b', // Subscription ID
  'BCSAI2024-DEVOPS-STUDENTS-B-UAT',      // Resource Group Name for UAT
  'makenna-keyvault-uat',                         // Key Vault Name
  'flaskApp',                             // Secret Name
  'latest'                                // Secret Version
)

param appServiceAPIDBHostFLASK_DEBUG = '0' // Hardcoded for UAT

param appServiceAPIEnvVarDBHOST = 'makenna-dbsrv-uat.postgres.database.azure.com' 
param appServiceAPIEnvVarDBNAME = 'makenna-db-uat' 
param appServiceAPIEnvVarENV = 'uat' 
