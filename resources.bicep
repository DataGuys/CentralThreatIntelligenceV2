// Parameters
param location string
param logAnalyticsWorkspaceName string
param keyVaultName string
param dcRuleSyslogName string
param queryPackName string
param sentinelName string
param tags object

// Variables
var tenantId = subscription().tenantId
var defaultKQLQuery = 'AzureDiagnostics | where Category == "AzureFirewallNetworkRule" | take 10'

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
  }
}

// Microsoft Sentinel
resource sentinel 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: sentinelName
  location: location
  tags: tags
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
  plan: {
    name: sentinelName
    publisher: 'Microsoft'
    product: 'OMSGallery/SecurityInsights'
    promotionCode: ''
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    tenantId: tenantId
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: []
  }
}

// Data Collection Rule for Syslog
resource dcRuleSyslog 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: dcRuleSyslogName
  location: location
  tags: tags
  properties: {
    dataSources: {
      syslog: [
        {
          name: 'syslogBase'
          streams: [
            'Microsoft-Syslog'
          ]
          facilityNames: [
            'auth'
            'authpriv'
            'cron'
            'daemon'
            'mark'
            'kern'
            'local0'
            'local1'
            'local2'
            'local3'
            'local4'
            'local5'
            'local6'
            'local7'
            'lpr'
            'mail'
            'news'
            'syslog'
            'user'
            'uucp'
          ]
          logLevels: [
            'Debug'
            'Info'
            'Notice'
            'Warning'
            'Error'
            'Critical'
            'Alert'
            'Emergency'
          ]
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          name: 'la-destination'
          workspaceResourceId: logAnalyticsWorkspace.id
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-Syslog'
        ]
        destinations: [
          'la-destination'
        ]
      }
    ]
  }
}

// Log Analytics Query Pack
resource queryPack 'Microsoft.OperationalInsights/queryPacks@2019-09-01' = {
  name: queryPackName
  location: location
  tags: tags
  properties: {}
}

// Sample Query in the Query Pack
resource sampleQuery 'Microsoft.OperationalInsights/queryPacks/queries@2019-09-01' = {
  parent: queryPack
  name: guid('sampleQuery', queryPackName)
  properties: {
    displayName: 'Sample Azure Firewall Network Rule Query'
    description: 'Sample query to view Azure Firewall Network Rules'
    body: defaultKQLQuery
    related: {
      categories: [
        'security'
        'audit'
      ]
      resourceTypes: [
        'microsoft.network/azurefirewalls'
      ]
    }
  }
}

// Outputs
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
output keyVaultId string = keyVault.id
output dcRuleSyslogId string = dcRuleSyslog.id
output queryPackId string = queryPack.id
output sentinelId string = sentinel.id
