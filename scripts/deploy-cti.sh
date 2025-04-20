#!/usr/bin/env bash
set -euo pipefail

REPO_BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/DataGuys/CentralThreatIntelligenceV2/${REPO_BRANCH}"
DEPLOY_NAME="cti-$(date +%Y%m%d%H%M%S)"

usage() {
  echo "Usage: deploy-cti.sh [-l location] [-p prefix] [-e environment]"
  exit 1
}

LOCATION=""
PREFIX="cti"
ENVIRONMENT="prod"

while getopts ":l:p:e:h" opt; do
  case $opt in
    l) LOCATION=$OPTARG ;;
    p) PREFIX=$OPTARG ;;
    e) ENVIRONMENT=$OPTARG ;;
    h|*) usage ;;
  esac
done

#--- Azure login & subscription selection ---
if ! az account show &>/dev/null; then
  echo "[+] Login to Azure CLI…"
  az login --only-show-errors
fi

echo "[+] Select Azure subscription:"
mapfile -t SUBS < <(az account list --query "[].{name:name,id:id}" -o tsv)
select SUB in "${SUBS[@]}"; do
  [[ -n "$SUB" ]] && break
done
SUB_ID="${SUB##*$'\t'}"
az account set --subscription "$SUB_ID"

# default location to the Cloud Shell region if none supplied
if [[ -z "$LOCATION" ]]; then
  LOCATION="$(az configure -l --query "[?name=='cloud'].value" -o tsv 2>/dev/null || echo westus2)"
fi

#--- Deploy core infra ---
echo "[+] Deploying Central Threat Intelligence…"
az deployment sub create \
  --name "$DEPLOY_NAME" \
  --location "$LOCATION" \
  --template-uri "$RAW_BASE/main.bicep" \
  --parameters prefix="$PREFIX" environment="$ENVIRONMENT" location="$LOCATION"

echo "[+] Fetching deployment outputs…"
OUTPUTS=$(az deployment sub show --name "$DEPLOY_NAME" --query "properties.outputs" -o json)
WORKSPACE_ID=$(echo "$OUTPUTS" | jq -r '.workspaceId.value')
WORKSPACE_NAME=$(echo "$OUTPUTS" | jq -r '.workspaceName.value')
RESOURCE_GROUP=$(echo "$OUTPUTS" | jq -r '.resourceGroupName.value')

echo "[+] Creating custom Log Analytics tables ($WORKSPACE_NAME)…"
TEMP_JSON=$(mktemp)
curl -sL "$RAW_BASE/custom-tables.json" -o "$TEMP_JSON"

jq -c '.[]' "$TEMP_JSON" | while read -r tbl; do
  TBL_NAME=$(echo "$tbl" | jq -r '.name')
  COLS=$(echo "$tbl" | jq -c '.columns')
  echo "  • $TBL_NAME"
  az monitor log-analytics workspace table create \
      --resource-group "$RESOURCE_GROUP" \
      --workspace-name  "$WORKSPACE_NAME" \
      --name            "$TBL_NAME" \
      --columns         "$COLS" \
      --retention-time  30 \
      --output none
done

rm "$TEMP_JSON"

echo "[✓] Deployment complete. custom tables are ready!"
