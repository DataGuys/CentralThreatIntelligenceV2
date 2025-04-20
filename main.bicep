targetScope = 'subscription'

@description('Prefix for resource names')
param prefix string = 'cti'

@allowed([
  'dev'
  'test'
  'prod'
])
@description('Deployment environment')
param environment string = 'prod'

@description('Azure location for the resource group')
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
    prefix: prefix
    location: location
    environment: environment
    tags: tags
  }
}
