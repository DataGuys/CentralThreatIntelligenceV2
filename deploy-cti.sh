#!/bin/bash
# deploy-cti.sh

# Set variables
PREFIX="CTI"
ENVIRONMENT="prod"
LOCATION="eastus"

echo "Deploying CentralThreatIntelligenceV2..."

# Download Bicep files
echo "Downloading Bicep files..."
curl -sL https://raw.githubusercontent.com/DataGuys/CentralThreatIntelligenceV2/main/main.bicep > main.bicep
curl -sL https://raw.githubusercontent.com/DataGuys/CentralThreatIntelligenceV2/main/modules/resources.bicep > resources.bicep

# Create proper directory structure
mkdir -p modules
mv resources.bicep modules/

# Fix the main.bicep file to use correct module path
# The error suggests there's an issue with the module referencing another module
# Let's inspect and potentially fix the resources.bicep file
sed -i 's|modules/resources.bicep|resources.bicep|g' main.bicep

# Deploy the Bicep template
echo "Deploying Bicep template..."
az deployment sub create --location $LOCATION --template-file main.bicep --parameters prefix=$PREFIX environmentName=$ENVIRONMENT

# Get resource group and workspace names
RESOURCE_GROUP="${PREFIX}-rg-${ENVIRONMENT}"
WORKSPACE_NAME="${PREFIX}-law-${ENVIRONMENT}"

# Wait for resources to be provisioned
echo "Waiting for resources to be fully provisioned..."
sleep 30

# Download the custom-tables.json file
echo "Downloading custom-tables.json..."
curl -sL "https://raw.githubusercontent.com/DataGuys/CentralThreatIntelligenceV2/refs/heads/main/custom-tables.json" > custom-tables.json

# Deploy custom tables
echo "Deploying custom tables to $WORKSPACE_NAME in $RESOURCE_GROUP..."
az deployment group create \
    --name "CTI-CustomTables-$(date +%Y%m%d%H%M%S)" \
    --resource-group "$RESOURCE_GROUP" \
    --template-file custom-tables.json \
    --parameters ctiWorkspaceName="$WORKSPACE_NAME"

echo "Deployment completed!"
