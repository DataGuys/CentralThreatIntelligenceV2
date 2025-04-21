#!/bin/bash
# Central Threat Intelligence V2 - Full Deployment Script
# This script creates the app registration and deploys the entire solution

set -e

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

REPO_BRANCH="${REPO_BRANCH:-main}"
RAW_BASE="https://raw.githubusercontent.com/DataGuys/CentralThreatIntelligenceV2/${REPO_BRANCH}"
DEPLOY_NAME="cti-$(date +%Y%m%d%H%M%S)"
TEMP_DIR=$(mktemp -d)

echo -e "\n${BLUE}============================================================${NC}"
echo -e "${BLUE}    Central Threat Intelligence V2 - Full Deployment${NC}"
echo -e "${BLUE}============================================================${NC}"

cleanup() {
    echo -e "\n${BLUE}Cleaning up temporary files...${NC}"
    rm -rf "$TEMP_DIR"
}

trap cleanup EXIT

# Check prerequisites
echo -e "\n${BLUE}Checking prerequisites...${NC}"
command -v az >/dev/null || { echo -e "${RED}❌ Azure CLI not found${NC}"; exit 1; }
command -v jq >/dev/null || { echo -e "${RED}❌ 'jq' is required${NC}"; exit 1; }
command -v curl >/dev/null || { echo -e "${RED}❌ 'curl' is required${NC}"; exit 1; }

# Azure login
if ! az account show &>/dev/null; then
    echo -e "${YELLOW}Not logged in to Azure. Initiating login...${NC}"
    az login --only-show-errors
fi

# Subscription selection - simplified version that works better with piped input
echo -e "\n${BLUE}Getting current subscription...${NC}"
CURRENT_SUB=$(az account show --query "id" -o tsv)
CURRENT_SUB_NAME=$(az account show --query "name" -o tsv)
echo -e "${GREEN}Using subscription: ${CURRENT_SUB_NAME} (${CURRENT_SUB})${NC}"
echo -e "${YELLOW}To use a different subscription, press Ctrl+C and run 'az account set --subscription YOUR_SUB_ID' first${NC}"
sleep 3

# Parse command line arguments
LOCATION=""
PREFIX="cti"
ENVIRONMENT="prod"
TABLE_PLAN="Analytics"

usage() {
    echo -e "Usage: $0 [-l location] [-p prefix] [-e environment] [-t table_plan]"
    echo -e "  -l  Azure region                    (default: first 'Recommended' region or westus2)"
    echo -e "  -p  Resource name prefix            (default: cti)"
    echo -e "  -e  Environment tag                 (default: prod)"
    echo -e "  -t  Table plan: Analytics|Basic|Aux (default: Analytics)"
    echo -e "  -h  Help"
    exit 1
}

while getopts "l:p:e:t:h" opt; do
    case "$opt" in
        l) LOCATION="$OPTARG" ;;
        p) PREFIX="$OPTARG" ;;
        e) ENVIRONMENT="$OPTARG" ;;
        t) TABLE_PLAN="$OPTARG" ;;
        h|*) usage ;;
    esac
done

# Resolve default location if not provided
if [[ -z "$LOCATION" ]]; then
    LOCATION="$(az account list-locations \
                --query "[?metadata.regionCategory=='Recommended'].name | [0]" \
                -o tsv 2>/dev/null || echo westus2)"
fi

# Validate table plan
case "${TABLE_PLAN,,}" in
    analytics|basic|auxiliary) TABLE_PLAN="$(tr '[:lower:]' '[:upper:]' <<< "$TABLE_PLAN")" ;;
    *) echo -e "${RED}❌ Invalid table plan. Use Analytics | Basic | Auxiliary${NC}"; exit 1 ;;
esac

# Set resource group name
RG_NAME="${PREFIX}-rg-${ENVIRONMENT}"

echo -e "\n${BLUE}======================= Configuration =======================${NC}"
echo -e " Subscription : ${CURRENT_SUB_NAME}"
echo -e " Location     : ${LOCATION}"
echo -e " Prefix       : ${PREFIX}"
echo -e " Environment  : ${ENVIRONMENT}"
echo -e " Table plan   : ${TABLE_PLAN}"
echo -e " Resource Group: ${RG_NAME}"
echo -e " Deployment   : ${DEPLOY_NAME}"
echo -e "${BLUE}============================================================${NC}"

# Step 1: Create the app registration
echo -e "\n${BLUE}Step 1: Creating app registration...${NC}"
curl -sL "${RAW_BASE}/scripts/create-cti-app-registration.sh" -o "${TEMP_DIR}/create-app.sh"
chmod +x "${TEMP_DIR}/create-app.sh"
cd "${TEMP_DIR}" && ./create-app.sh

# Get app credentials from file
if [[ -f "${TEMP_DIR}/cti-app-credentials.env" ]]; then
    source "${TEMP_DIR}/cti-app-credentials.env"
    echo -e "${GREEN}✅ App registration created successfully${NC}"
    echo -e "    App ID: ${CLIENT_ID}"
else
    echo -e "${RED}❌ Failed to create app registration${NC}"
    exit 1
fi

# Step 2: Download Bicep files
echo -e "\n${BLUE}Step 2: Downloading deployment files...${NC}"
mkdir -p "${TEMP_DIR}/modules"
mkdir -p "${TEMP_DIR}/logic-apps"
mkdir -p "${TEMP_DIR}/tables"

# Main Bicep file
curl -sL "${RAW_BASE}/main.bicep" -o "${TEMP_DIR}/main.bicep"
# Modules
curl -sL "${RAW_BASE}/modules/resources.bicep" -o "${TEMP_DIR}/modules/resources.bicep"
# Tables
curl -sL "${RAW_BASE}/tables/custom-tables.json" -o "${TEMP_DIR}/tables/custom-tables.json"

echo -e "${GREEN}✅ Deployment files downloaded successfully${NC}"

# Step 3: Deploy the infrastructure
echo -e "\n${BLUE}Step 3: Deploying infrastructure...${NC}"
cd "${TEMP_DIR}"

# Step 3a: Create resource group directly first
echo -e "${YELLOW}Creating resource group ${RG_NAME}...${NC}"
az group create --name "${RG_NAME}" --location "${LOCATION}" --tags "project=CentralThreatIntelligence" "environment=${ENVIRONMENT}"

# Wait for resource group to be fully provisioned
echo -e "${YELLOW}Waiting for resource group to be fully provisioned...${NC}"
sleep 10

# Verify resource group exists
if ! az group show --name "${RG_NAME}" &>/dev/null; then
    echo -e "${RED}❌ Resource group ${RG_NAME} was not created successfully${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Resource group ${RG_NAME} created successfully${NC}"

# Step 3b: Deploy main template
echo -e "${YELLOW}Deploying base infrastructure...${NC}"
az deployment group create \
    --name "$DEPLOY_NAME" \
    --resource-group "${RG_NAME}" \
    --template-file "./modules/resources.bicep" \
    --parameters prefix="$PREFIX" environment="$ENVIRONMENT" location="$LOCATION"

# Get outputs from deployment
OUTPUTS=$(az deployment group show --name "$DEPLOY_NAME" --resource-group "${RG_NAME}" \
         --query "properties.outputs" -o json)

WORKSPACE_NAME=$(jq -r '.workspaceName.value' <<< "$OUTPUTS")

if [[ -z "$WORKSPACE_NAME" ]]; then
    echo -e "${RED}❌ Failed to retrieve workspace name from deployment${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Base infrastructure deployed successfully${NC}"
echo -e "    Resource Group: ${RG_NAME}"
echo -e "    Workspace Name: ${WORKSPACE_NAME}"

# Step 4: Create custom tables
echo -e "\n${BLUE}Step 4: Creating custom Log Analytics tables...${NC}"

# Process each table from the tables.json file
jq -c '.variables.tables[]' "${TEMP_DIR}/tables/custom-tables.json" | while read -r tbl; do
    TBL_NAME=$(jq -r '.name' <<< "$tbl")
    COLS=$(jq -c '.columns' <<< "$tbl")
    printf '  • Creating %-40s\r' "$TBL_NAME"

    # Create if missing (ignore 409 errors)
    az monitor log-analytics workspace table create \
        --resource-group "$RG_NAME" \
        --workspace-name "$WORKSPACE_NAME" \
        --name "$TBL_NAME" \
        --columns "$COLS" \
        --retention-time 30 \
        --only-show-errors >/dev/null || true

    # Ensure plan matches requested tier
    az monitor log-analytics workspace table update \
        --resource-group "$RG_NAME" \
        --workspace-name "$WORKSPACE_NAME" \
        --name "$TBL_NAME" \
        --plan "$TABLE_PLAN" \
        --only-show-errors >/dev/null
    
    echo -e "  • ${GREEN}Created${NC} $TBL_NAME (${TABLE_PLAN} tier)"
done

# Step 5: Deploy Logic Apps
echo -e "\n${BLUE}Step 5: Deploying Logic App connectors...${NC}"
# Logic app deployment will be implemented in a future update

echo -e "\n${GREEN}===========================================================${NC}"
echo -e "${GREEN}    Central Threat Intelligence V2 - Deployment Complete${NC}"
echo -e "${GREEN}===========================================================${NC}"
echo -e "\n${BLUE}Next Steps:${NC}"
echo -e "1. Grant admin consent for API permissions in Azure Portal:"
echo -e "   - Navigate to: Microsoft Entra ID > App registrations"
echo -e "   - Select your app: CTI-Solution"
echo -e "   - Go to 'API permissions'"
echo -e "   - Click 'Grant admin consent for <your-tenant>'"
echo -e "\n2. Access your deployment resources:"
echo -e "   - Resource Group: ${RG_NAME}"
echo -e "   - Log Analytics Workspace: ${WORKSPACE_NAME}"
echo -e "\n3. Review the custom tables in your workspace (${TABLE_PLAN} tier)"
echo -e "\nStore your app credentials securely. They have been saved to: ${TEMP_DIR}/cti-app-credentials.env"
