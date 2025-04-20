targetScope = 'resourceGroup'

param prefix       string
param environment  string
param location     string = resourceGroup().location
param tags         object

var workspaceName = '${prefix}-law-${environment}'
var kvName        = toLower(replace('${prefix}-kv-${environment}', '-', ''))

// ---------- Core resources ----------
resource law 'Microsoft.OperationalInsights/workspaces@2023-10-01' = {
  name: workspaceName
  location: location
  sku: {
    name: 'PerGB2018'
  }
  retentionInDays: 30
  tags: tags
}


// Key Vault (RBAC‑mode)
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

// ---------- Data Collection Rules ----------
// Syslog
resource dcrSyslog 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: '${prefix}-dcr-syslog-${environment}'
  location: location
  properties: {
    description: 'Syslog collection for CTI'
    dataSources: {
      syslog: [
        {
          facilityNames: [ 'auth' 'authpriv' 'daemon' 'local0' ]
          logLevels: [ 'Informational','Notice','Warning','Error','Critical','Alert','Emergency' ]
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

// Placeholder CEF rule – add parsers later
resource dcrCef 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: '${prefix}-dcr-cef-${environment}'
  location: location
  properties: {
    description: 'CEF collection for CTI'
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

// ---------- TAXII / STIX ingestion via AMA HTTP Push ----------
// Data Collection Endpoint exposes an HTTP endpoint your Logic App / Function will POST STIX JSON to.
resource dce 'Microsoft.Insights/dataCollectionEndpoints@2021-09-01-preview' = {
  name: '${prefix}-dce-${environment}'
  location: location
  kind: 'AzureMonitor'
  properties: {
    description: 'Endpoint for TAXII / STIX push ingestion'
    networkAcls: {
      publicNetworkAccess: 'Enabled' // lock down to VNet/IPs later in prod
    }
  }
}

resource dcrStix 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: '${prefix}-dcr-stix-${environment}'
  location: location
  properties: {
    dataCollectionEndpointId: dce.id
    description: 'Custom log ingestion for TAXII / STIX feeds (JSON)'
    dataSources: {
      logs: [
        {
          name: 'stixLogSource'
          stream: 'Custom-CTIStix_CL'  // table will appear as CTIStix_CL
          format: 'json'
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
        streams: [ 'Custom-CTIStix_CL' ]
        destinations: [ 'lawDest' ]
      }
    ]
  }
}

// ---------- Outputs ----------
output workspaceId              string = law.id
output workspaceName            string = workspaceName
output keyVaultUri              string = kv.properties.vaultUri
output stixIngestionEndpointUri string = dce.properties.logsIngestionEndpoint
```bicep
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


// Key Vault (RBAC‑mode)
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

// --- Data Collection Rules ---
resource dcrSyslog 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: '${prefix}-dcr-syslog-${environment}'
  location: location
  properties: {
    description: 'Syslog collection for CTI'
    dataSources: {
      syslog: [
        {
          facilityNames: [ 'auth' 'authpriv' 'daemon' 'local0' ]
          logLevels: [ 'Informational','Notice','Warning','Error','Critical','Alert','Emergency' ]
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

// placeholder CEF rule – add parsers later
resource dcrCef 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: '${prefix}-dcr-cef-${environment}'
  location: location
  properties: {
    description: 'CEF collection for CTI'
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

// outputs for automation
output workspaceId       string = law.id
output workspaceName     string = workspaceName
output keyVaultUri       string = kv.properties.vaultUri
