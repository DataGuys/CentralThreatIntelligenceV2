# Central Threat Intelligence V2

A minimal, cost‑efficient Microsoft Sentinel landing zone that spins up:

* **Log Analytics Workspace** with 30‑day retention
* **Microsoft Sentinel** solution enabled
* **Azure Key Vault** for secret storage (RBAC‑enabled)
* **Data Collection Rules** for Syslog and CEF inputs

---

## Quick start: full deployment (Cloud Shell)

```bash
curl -sL https://raw.githubusercontent.com/DataGuys/CentralThreatIntelligenceV2/main/scripts/deploy-cti.sh | bash
```

## Set table tiering from go with -t Analytics is the default or Basic / Auxiliary
```bash
curl -sL https://raw.githubusercontent.com/DataGuys/CentralThreatIntelligenceV2/main/scripts/deploy-cti.sh \
  | bash -s -- -t Analytics
```

