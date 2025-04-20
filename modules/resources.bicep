targetScope = 'resourceGroup'

param prefix       string
param environment  string
param location     string = resourceGroup().location
param tags         object

var workspaceName = '${prefix}-law-${environment}'
var kvName        = toLower(replace('${prefix}-kv-${environment}', '-', ''))

resource law 'Microsoft.OperationalInsights/workspaces@2023-10-01' = {
  name: workspaceName
  location: location
  sku: {
    name: 'PerGB2018'
  }
  retentionInDays: 30
  tags: tags
}

// Enable Microsoft Sentinel on the workspace
resource sentinel 'Microsoft.OperationalInsights/workspaces/providers@2022-10-01-preview' = {
  name: '${law.name}/Microsoft.SecurityInsights'
  kind: 'SecurityInsights'
}

resource kv 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: kvName
  location: location
  properties: {
    enableRbacAuthorization: true
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
  }
  tags: tags
}

// Syslog DCR
resource dcrSyslog 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: '${prefix}-dcr-syslog-${environment}'
  location: location
  properties: {
    description: 'Syslog DCR for Central Threat Intelligence'
    dataSources: {
      syslog: [
        {
          facilityNames: [ 'auth' 'authpriv' 'daemon' 'local0' ]
          logLevels: [
            'Informational'
            'Notice'
            'Warning'
            'Error'
            'Critical'
            'Alert'
            'Emergency'
          ]
          name: 'syslogSource'
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          name: 'lawDest'
          workspaceResourceId: law.id
        }
      ]
    }
    dataFlows: [
      {
        streams: [ 'Microsoft-Syslog' ]
        destinations: [ 'lawDest' ]
      }
    ]
  }
}

// CEF DCR (placeholder – extend as needed)
resource dcrCef 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: '${prefix}-dcr-cef-${environment}'
  location: location
  properties: {
    description: 'CEF DCR for Central Threat Intelligence'
    dataSources: {
      linuxPerformanceCounter: []
    }
    destinations: {
      logAnalytics: [
        {
          name: 'lawDest'
          workspaceResourceId: law.id
        }
      ]
    }
    dataFlows: [
      {
        streams: [ 'Microsoft-CustomLogs' ]
        destinations: [ 'lawDest' ]
      }
    ]
  }
}

output workspaceId string   = law.id
output keyVaultUri string   = kv.properties.vaultUri
