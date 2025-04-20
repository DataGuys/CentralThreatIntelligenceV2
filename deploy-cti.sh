#!/usr/bin/env bash
set -euo pipefail

REPO_BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/DataGuys/CentralThreatIntelligenceV2/${REPO_BRANCH}"

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

# Ensure Azure CLI is logged in
if ! az account show &>/dev/null; then
  echo "[+] Login to Azure CLI..."
  az login
fi

echo "[+] Select Azure subscription:"
mapfile -t SUBS < <(az account list --query "[].{name:name, id:id}" -o tsv)
select SUB in "${SUBS[@]}"; do
  [[ -n "$SUB" ]] && break
done
SUB_ID="${SUB##*$'\t'}"
az account set --subscription "$SUB_ID"

# Pick a location if none supplied
if [[ -z "$LOCATION" ]]; then
  LOCATION="$(az account list-locations --query "[?name=='westus2'].name" -o tsv)"
fi

echo "[+] Deploying Central Threat Intelligence (branch: $REPO_BRANCH) ..."
az deployment sub create \
  --name "cti-$(date +%Y%m%d%H%M%S)" \
  --location "$LOCATION" \
  --template-uri "$RAW_BASE/main.bicep" \
  --parameters prefix="$PREFIX" environment="$ENVIRONMENT" location="$LOCATION"

echo "[✓] Deployment request submitted. Check the Azure Portal for progress."
