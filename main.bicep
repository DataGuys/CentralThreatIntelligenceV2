targetScope = 'subscription'

// Parameters
@description('Location for all resources')
param location string = deployment().location

@description('Prefix for all resources')
param prefix string = 'demo'

@description('Environment name')
@allowed([
  'dev'
  'test'
  'prod'
])
param environmentName string = 'dev'

@description('Tags for all resources')
param tags object = {
  environment: environmentName
  project: 'bicep-deployment'
}

// Variables
var resourceGroupName = '${prefix}-rg-${environmentName}'
var logAnalyticsWorkspaceName = '${prefix}-law-${environmentName}'
var keyVaultName = '${prefix}-kv-${environmentName}'
var dcRuleSyslogName = '${prefix}-dcr-syslog-${environmentName}'
var queryPackName = '${prefix}-qp-${environmentName}'
var sentinelName = 'SecurityInsights(${logAnalyticsWorkspaceName})'

// Create Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Deploy resources to the Resource Group
module resources 'resources.bicep' = {
  name: 'resourcesDeployment'
  scope: resourceGroup
  params: {
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    keyVaultName: keyVaultName
    dcRuleSyslogName: dcRuleSyslogName
    queryPackName: queryPackName
    sentinelName: sentinelName
    tags: tags
  }
}

// Outputs
output resourceGroupId string = resourceGroup.id
output resourceGroupName string = resourceGroup.name
output logAnalyticsWorkspaceId string = resources.outputs.logAnalyticsWorkspaceId
output keyVaultId string = resources.outputs.keyVaultId
output dcRuleSyslogId string = resources.outputs.dcRuleSyslogId
output queryPackId string = resources.outputs.queryPackId
output sentinelId string = resources.outputs.sentinelId
