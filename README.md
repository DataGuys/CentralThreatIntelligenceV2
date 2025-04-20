# Central Threat Intelligence V2

A minimal, cost‑efficient Microsoft Sentinel landing zone that provides:

* **Log Analytics Workspace** with 30‑day retention
* **Custom Threat Tables** hosted on the Analytics Tier for cost control
* **Azure Key Vault** for secret storage (RBAC‑enabled)
* **Data Collection Rules** for Syslog and STIX ingestion
* **Logic Apps** for integration with Microsoft security products

## Quick Start Deployment

### Option 1: One-Line Deployment (With App Registration)

Execute this single command in Azure Cloud Shell to create the app registration and deploy the entire solution:

```bash
curl -sL https://raw.githubusercontent.com/DataGuys/CentralThreatIntelligenceV2/main/scripts/deploy-full.sh | bash
```

### Option 2: Step-by-Step Deployment

#### 1. Create the App Registration

```bash
curl -sL https://raw.githubusercontent.com/DataGuys/CentralThreatIntelligenceV2/main/scripts/create-cti-app-registration.sh | tr -d '\r' | bash
```

#### 2. Deploy the Infrastructure

```bash
curl -sL https://raw.githubusercontent.com/DataGuys/CentralThreatIntelligenceV2/main/scripts/deploy-cti.sh | bash
```

## Customization Options

### Set Table Tiering

You can set all tables to a specific tier during deployment:

```bash
curl -sL https://raw.githubusercontent.com/DataGuys/CentralThreatIntelligenceV2/main/scripts/deploy-cti.sh | bash -s -- -t Analytics
```

Valid options:
- **Analytics**: Default tier, for critical threat data with full query capabilities
- **Basic**: Reduced cost with limited query capabilities
- **Auxiliary**: Minimal cost for low-value indicators, backup or archive data

### Additional Parameters

```bash
curl -sL https://raw.githubusercontent.com/DataGuys/CentralThreatIntelligenceV2/main/scripts/deploy-cti.sh | bash -s -- -p myprefix -e dev -t Analytics -l eastus
```

- `-p`: Resource name prefix (default: cti)
- `-e`: Environment tag (default: prod)
- `-t`: Table plan (Analytics, Basic, or Auxiliary)
- `-l`: Azure region (default: first recommended region)
- `-s`: Specify subscription ID

## Post-Deployment

After deployment:

1. **Grant admin consent** for the app registration in Azure Portal
2. **Configure connectors** through the Logic Apps
3. **Add data sources** via the workbook interface

## Contributing

This project is licensed under the MIT License - see the LICENSE file for details.
