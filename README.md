# Central Threat Intelligence V2

A minimal, cost‑efficient Microsoft Sentinel landing zone that provides:

* **Log Analytics Workspace** with 30‑day retention
* **Custom Threat Tables** hosted on the Analytics Tier for cost control
* **Azure Key Vault** for secret storage (RBAC‑enabled)
* **Data Collection Rules** for Syslog and STIX ingestion
* **Logic Apps** for integration with Microsoft security products
* **App Registration for Entra ID with all the correct permissions to use with Playbooks / Logic apps for inoculation automations.

## Quick Start Deployment

### One-Step Deployment (Recommended)

Download and execute the deployment script:

```bash
curl -sL https://raw.githubusercontent.com/DataGuys/CentralThreatIntelligenceV2/main/scripts/deploy-full.sh -o deploy-full.sh && chmod +x deploy-full.sh && ./deploy-full.sh
