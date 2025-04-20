# CentralThreatIntelligenceV2

A bicep template for deploying a centralized security monitoring solution with Microsoft Sentinel.

## Quick Deployment

### Option 1: One-line Deployment (Basic)

To deploy the basic solution in Azure Cloud Shell (bash), run this command:

```bash
curl -sL https://raw.githubusercontent.com/DataGuys/CentralThreatIntelligenceV2/main/main.bicep > main.bicep && curl -sL https://raw.githubusercontent.com/DataGuys/CentralThreatIntelligenceV2/main/modules/resources.bicep > resources.bicep && mkdir -p modules && mv resources.bicep modules/ && az deployment sub create --location eastus --template-file main.bicep --parameters prefix=CTI environmentName=prod
```

Option 2: Complete Deployment with Custom Tables
For a complete deployment including custom threat intelligence tables, use this command:

```bash
curl -sL https://raw.githubusercontent.com/DataGuys/CentralThreatIntelligenceV2/main/deploy-cti.sh > deploy-cti.sh && chmod +x deploy-cti.sh && ./deploy-cti.sh
```

This command will:

Download the deployment script
Make it executable
Run it to deploy both the Bicep resources and the custom tables

Resources Deployed
The deployment creates:

Resource Group (CTI-rg-prod)
Log Analytics Workspace (CTI-law-prod)
Microsoft Sentinel instance
Key Vault (CTI-kv-prod)
Log Analytics Query Pack (CTI-qp-prod)
Data Collection Rule for Syslog (CTI-dcr-syslog-prod)
Custom Threat Intelligence Tables
