# CentralThreatIntelligenceV2

A bicep template for deploying a centralized security monitoring solution with Microsoft Sentinel.

## Quick Deployment

### Option 1: One-line Deployment (Basic)

To deploy the basic solution in Azure Cloud Shell (bash), run this command:

```bash
curl -sL https://raw.githubusercontent.com/DataGuys/CentralThreatIntelligenceV2/main/main.bicep > main.bicep && curl -sL https://raw.githubusercontent.com/DataGuys/CentralThreatIntelligenceV2/main/modules/resources.bicep > resources.bicep && mkdir -p modules && mv resources.bicep modules/ && az deployment sub create --location eastus --template-file main.bicep --parameters prefix=CTI environmentName=prod
```
