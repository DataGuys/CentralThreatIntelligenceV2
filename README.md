# Central Threat Intelligence V2

A minimal, cost‑efficient Microsoft Sentinel landing zone that spins up:

* **Log Analytics Workspace** with 30‑day retention
* **Microsoft Sentinel** solution enabled
* **Azure Key Vault** for secret storage (RBAC‑enabled)
* **Data Collection Rules** for Syslog and CEF inputs

---

## Quick start: full deployment (Cloud Shell)

### 1. Create the app registration

#### 1 App Registration Deployment

```bash
curl -sL https://raw.githubusercontent.com/DataGuys/CentralThreatIntelligence/main/create-cti-app.sh | tr -d '\r' | bash -s
```

### 2. Deploy the solution

```bash
SUB_ID=\"\"; PS3='Select subscription: '; mapfile -t SUBS < <(az account list --query \"[].{name:name,id:id}\" -o tsv); select SUB in \"\${SUBS[@]}\"; do [[ -n \$SUB ]] && az account set --subscription \"\${SUB##*$'\t'}\" && echo \"Switched to subscription: \${SUB%%$'\t'*}\" && CHOSEN_SUB_ID=\"\${SUB##*$'\t'}\" && break; done"
curl -sL https://raw.githubusercontent.com/DataGuys/CentralThreatIntelligenceV2/main/scripts/deploy-cti.sh | bash
```

## Set table tiering from go with -t Analytics is the default or Basic / Auxiliary
```bash
curl -sL https://raw.githubusercontent.com/DataGuys/CentralThreatIntelligenceV2/main/scripts/deploy-cti.sh \
  | bash -s -- -t Analytics
```

