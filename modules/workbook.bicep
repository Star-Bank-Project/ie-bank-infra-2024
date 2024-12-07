@description('The Azure region where the workbook will be deployed.')
param location string

@description('The resource ID of the Application Insights to link with this workbook.')
param sourceId string

@description('The display name for the workbook.')
param displayName string = 'Star Bank Workbook'

resource workbook 'Microsoft.Insights/workbooks@2022-04-01' = {
  name: guid(displayName, resourceGroup().id)
  location: location
  kind: 'shared'
  properties: {
    category: 'workbook'
    displayName: displayName
    serializedData: loadTextContent('../workbooks/main.workbook.json') 
    sourceId: sourceId
  }
}
