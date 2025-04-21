@description('Name of the Log Analytics workspace')
param workspaceName string

@description('Table plan: Analytics, Basic, or Standard')
@allowed(['Analytics', 'Basic', 'Standard'])
param tablePlan string = 'Analytics'

var ctiTables = [
  {
    name: 'CTI_ThreatIntelIndicator_CL'
    columns: [
      { name: 'TimeGenerated', type: 'datetime' }
      { name: 'Type_s', type: 'string' }
      { name: 'Value_s', type: 'string' }
      { name: 'Pattern_s', type: 'string' }
      { name: 'PatternType_s', type: 'string' }
      { name: 'Name_s', type: 'string' }
      { name: 'Description_s', type: 'string' }
      { name: 'Action_s', type: 'string' }
      { name: 'Confidence_d', type: 'double' }
      { name: 'ValidFrom_t', type: 'datetime' }
      { name: 'ValidUntil_t', type: 'datetime' }
      { name: 'CreatedTimeUtc_t', type: 'datetime' }
      { name: 'UpdatedTimeUtc_t', type: 'datetime' }
      { name: 'Source_s', type: 'string' }
      { name: 'SourceRef_s', type: 'string' }
      { name: 'KillChainPhases_s', type: 'string' }
      { name: 'Labels_s', type: 'string' }
      { name: 'ThreatType_s', type: 'string' }
      { name: 'TLP_s', type: 'string' }
      { name: 'DistributionTargets_s', type: 'string' }
      { name: 'ThreatActorName_s', type: 'string' }
      { name: 'CampaignName_s', type: 'string' }
      { name: 'Active_b', type: 'bool' }
      { name: 'ObjectId_g', type: 'guid' }
      { name: 'IndicatorId_g', type: 'guid' }
    ]
  }
  {
    name: 'CTI_IPIndicators_CL'
    columns: [
      { name: 'TimeGenerated', type: 'datetime' }
      { name: 'IPAddress_s', type: 'string' }
      { name: 'ConfidenceScore_d', type: 'double' }
      { name: 'SourceFeed_s', type: 'string' }
      { name: 'FirstSeen_t', type: 'datetime' }
      { name: 'LastSeen_t', type: 'datetime' }
      { name: 'ExpirationDateTime_t', type: 'datetime' }
      { name: 'ThreatType_s', type: 'string' }
      { name: 'ThreatCategory_s', type: 'string' }
      { name: 'TLP_s', type: 'string' }
      { name: 'GeoLocation_s', type: 'string' }
      { name: 'ASN_s', type: 'string' }
      { name: 'Tags_s', type: 'string' }
      { name: 'Description_s', type: 'string' }
      { name: 'Action_s', type: 'string' }
      { name: 'ReportedBy_s', type: 'string' }
      { name: 'DistributionTargets_s', type: 'string' }
      { name: 'ThreatActorName_s', type: 'string' }
      { name: 'CampaignName_s', type: 'string' }
      { name: 'Active_b', type: 'bool' }
      { name: 'IndicatorId_g', type: 'guid' }
    ]
  }
  {
    name: 'CTI_DomainIndicators_CL'
    columns: [
      { name: 'TimeGenerated', type: 'datetime' }
      { name: 'Domain_s', type: 'string' }
      { name: 'ConfidenceScore_d', type: 'double' }
      { name: 'SourceFeed_s', type: 'string' }
      { name: 'FirstSeen_t', type: 'datetime' }
      { name: 'LastSeen_t', type: 'datetime' }
      { name: 'ExpirationDateTime_t', type: 'datetime' }
      { name: 'ThreatType_s', type: 'string' }
      { name: 'ThreatCategory_s', type: 'string' }
      { name: 'TLP_s', type: 'string' }
      { name: 'Tags_s', type: 'string' }
      { name: 'Description_s', type: 'string' }
      { name: 'Action_s', type: 'string' }
      { name: 'DistributionTargets_s', type: 'string' }
      { name: 'ReportedBy_s', type: 'string' }
      { name: 'ThreatActorName_s', type: 'string' }
      { name: 'CampaignName_s', type: 'string' }
      { name: 'Active_b', type: 'bool' }
      { name: 'IndicatorId_g', type: 'guid' }
    ]
  }
  {
    name: 'CTI_URLIndicators_CL'
    columns: [
      { name: 'TimeGenerated', type: 'datetime' }
      { name: 'URL_s', type: 'string' }
      { name: 'ConfidenceScore_d', type: 'double' }
      { name: 'SourceFeed_s', type: 'string' }
      { name: 'FirstSeen_t', type: 'datetime' }
      { name: 'LastSeen_t', type: 'datetime' }
      { name: 'ExpirationDateTime_t', type: 'datetime' }
      { name: 'ThreatType_s', type: 'string' }
      { name: 'ThreatCategory_s', type: 'string' }
      { name: 'TLP_s', type: 'string' }
      { name: 'Tags_s', type: 'string' }
      { name: 'Description_s', type: 'string' }
      { name: 'Action_s', type: 'string' }
      { name: 'DistributionTargets_s', type: 'string' }
      { name: 'ReportedBy_s', type: 'string' }
      { name: 'ThreatActorName_s', type: 'string' }
      { name: 'CampaignName_s', type: 'string' }
      { name: 'Active_b', type: 'bool' }
      { name: 'IndicatorId_g', type: 'guid' }
    ]
  }
  {
    name: 'CTI_FileHashIndicators_CL'
    columns: [
      { name: 'TimeGenerated', type: 'datetime' }
      { name: 'SHA256_s', type: 'string' }
      { name: 'MD5_s', type: 'string' }
      { name: 'SHA1_s', type: 'string' }
      { name: 'ConfidenceScore_d', type: 'double' }
      { name: 'SourceFeed_s', type: 'string' }
      { name: 'FirstSeen_t', type: 'datetime' }
      { name: 'LastSeen_t', type: 'datetime' }
      { name: 'ExpirationDateTime_t', type: 'datetime' }
      { name: 'MalwareFamily_s', type: 'string' }
      { name: 'ThreatType_s', type: 'string' }
      { name: 'ThreatCategory_s', type: 'string' }
      { name: 'TLP_s', type: 'string' }
      { name: 'Tags_s', type: 'string' }
      { name: 'Description_s', type: 'string' }
      { name: 'Action_s', type: 'string' }
      { name: 'DistributionTargets_s', type: 'string' }
      { name: 'ReportedBy_s', type: 'string' }
      { name: 'ThreatActorName_s', type: 'string' }
      { name: 'CampaignName_s', type: 'string' }
      { name: 'Active_b', type: 'bool' }
      { name: 'IndicatorId_g', type: 'guid' }
    ]
  }
  {
    name: 'CTI_StixData_CL'
    columns: [
      { name: 'TimeGenerated', type: 'datetime' }
      { name: 'RawSTIX', type: 'string' }
      { name: 'STIXType', type: 'string' }
      { name: 'STIXId', type: 'string' }
      { name: 'CreatedBy', type: 'string' }
      { name: 'Source', type: 'string' }
    ]
  }
]

// Create custom tables in the Log Analytics workspace
resource customTables 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = [for table in ctiTables: {
  name: '${workspaceName}/${table.name}'
  properties: {
    schema: {
      name: table.name
      columns: table.columns
    }
    retentionInDays: 30
    plan: tablePlan
  }
}]

output tableNames array = [for (table, i) in ctiTables: customTables[i].name]
