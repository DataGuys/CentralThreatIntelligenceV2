targetScope = 'subscription'

@description('Prefix for resource names')
param prefix string = 'cti'

@allowed(['dev','test','prod'])
@description('Deployment environment')
param environment string = 'prod'

@description('Azure region for the resource group')
param location string = deployment().location

@description('Tags applied to every resource')
param tags object = {
  project: 'CentralThreatIntelligence'
  environment: environment
}

var rgName = '${prefix}-rg-${environment}'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgName
  location: location
  tags: tags
}

module resources './modules/resources.bicep' = {
  name: 'centralThreatIntelligence'
  scope: rg
  params: {
    prefix:       prefix
    environment:  environment
    location:     location
    tags:         tags
  }
}

// surface key outputs for downstream automation
output workspaceId        string = resources.outputs.workspaceId
output workspaceName      string = resources.outputs.workspaceName
output resourceGroupName  string = rgName
output keyVaultUri        string = resources.outputs.keyVaultUri
