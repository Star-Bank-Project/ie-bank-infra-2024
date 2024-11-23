using '../main.bicep'

param appServiceAPIDBHostDBUSER = az.getSecret(
  'e0b9cada-61bc-4b5a-bd7a-52c606726b3b', // Subscription ID
  'BCSAI2024-DEVOPS-STUDENTS-B-DEV',      // Resource Group Name for DEV
  'makenna-keyvault-dev',                         // Key Vault Name
  'dbUser',                               // Secret Name
  'latest'                                // Secret Version
)

param appServiceAPIEnvVarDBPASS = az.getSecret(
  'e0b9cada-61bc-4b5a-bd7a-52c606726b3b', // Subscription ID
  'BCSAI2024-DEVOPS-STUDENTS-B-DEV',      // Resource Group Name for DEV
  'makenna-keyvault-dev',                         // Key Vault Name
  'dbPassword',                           // Secret Name
  'latest'                                // Secret Version
)

param appServiceAPIDBHostFLASK_APP = az.getSecret(
  'e0b9cada-61bc-4b5a-bd7a-52c606726b3b', // Subscription ID
  'BCSAI2024-DEVOPS-STUDENTS-B-DEV',      // Resource Group Name for DEV
  'makenna-keyvault-dev',                         // Key Vault Name
  'flaskApp',                             // Secret Name
  'latest'                                // Secret Version
)

param appServiceAPIDBHostFLASK_DEBUG = '0' // Hardcoded for DEV

param appServiceAPIEnvVarDBHOST = 'makenna-dbsrv-dev.postgres.database.azure.com' 
param appServiceAPIEnvVarDBNAME = 'makenna-db-dev' 
param appServiceAPIEnvVarENV = 'dev' 

