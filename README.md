# CentralThreatIntelligenceV2

A bicep template for deploying a centralized security monitoring solution with Microsoft Sentinel.

## Quick Deployment

To deploy this solution in Azure Cloud Shell (bash), run this command:

```bash
curl -sL https://raw.githubusercontent.com/DataGuys/CentralThreatIntelligenceV2/main/main.bicep > main.bicep && curl -sL https://raw.githubusercontent.com/DataGuys/CentralThreatIntelligenceV2/main/modules/resources.bicep > resources.bicep && mkdir -p modules && mv resources.bicep modules/ && az deployment sub create --location eastus --template-file main.bicep --parameters prefix=CTI environmentName=prod
```

This command will:
1. Download the Bicep files to your Cloud Shell
2. Create the necessary directory structure
3. Deploy the template at the subscription level
4. Create a resource group and various security monitoring resources

### Resources Deployed

The deployment creates:
- Resource Group (CTI-rg-prod)
- Log Analytics Workspace (CTI-law-prod)
- Microsoft Sentinel instance
- Key Vault (CTI-kv-prod)
- Log Analytics Query Pack (CTI-qp-prod)
- Data Collection Rule for Syslog (CTI-dcr-syslog-prod)

### Customizing the Deployment

To customize the deployment with different parameters:

```bash
curl -sL https://raw.githubusercontent.com/DataGuys/CentralThreatIntelligenceV2/main/main.bicep > main.bicep && curl -sL https://raw.githubusercontent.com/DataGuys/CentralThreatIntelligenceV2/main/modules/resources.bicep > resources.bicep && mkdir -p modules && mv resources.bicep modules/ && az deployment sub create --location westus2 --template-file main.bicep --parameters prefix=YourPrefix environmentName=dev
```

## License
MIT
