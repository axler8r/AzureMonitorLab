#!/bin/bash
#
# Azure Monitor Lab - Deployment Script (Bash)
# This script deploys the Azure Monitor Lab infrastructure using Bicep templates
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load environment variables from .env file
ENV_FILE="$PROJECT_ROOT/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Error: .env file not found at $ENV_FILE${NC}"
    echo -e "${YELLOW}Please copy .env.example to .env and configure your settings.${NC}"
    exit 1
fi

# Source the .env file
set -a
source "$ENV_FILE"
set +a

# Validate required variables
if [ -z "$AZURE_SUBSCRIPTION_ID" ] || [ -z "$AZURE_RESOURCE_GROUP" ] || [ -z "$AZURE_LOCATION" ] || [ -z "$ENVIRONMENT_NAME" ]; then
    echo -e "${RED}Error: Missing required environment variables in .env${NC}"
    echo "Required: AZURE_SUBSCRIPTION_ID, AZURE_RESOURCE_GROUP, AZURE_LOCATION, ENVIRONMENT_NAME"
    exit 1
fi

echo -e "${GREEN}=== Azure Monitor Lab Deployment ===${NC}"
echo "Subscription ID: $AZURE_SUBSCRIPTION_ID"
echo "Resource Group: $AZURE_RESOURCE_GROUP"
echo "Location: $AZURE_LOCATION"
echo "Environment: $ENVIRONMENT_NAME"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed${NC}"
    echo "Please install Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Login check
echo "Checking Azure CLI login status..."
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}Not logged in to Azure. Initiating login...${NC}"
    az login
fi

# Set subscription
echo "Setting subscription to $AZURE_SUBSCRIPTION_ID..."
az account set --subscription "$AZURE_SUBSCRIPTION_ID"

# Create or verify resource group
if [ "$CREATE_RESOURCE_GROUP" = "true" ]; then
    echo -e "${GREEN}Creating resource group $AZURE_RESOURCE_GROUP...${NC}"
    az group create \
        --name "$AZURE_RESOURCE_GROUP" \
        --location "$AZURE_LOCATION" \
        --tags "Environment=$ENVIRONMENT_NAME" "Project=AzureMonitorLab" "ManagedBy=Bicep"
else
    echo "Verifying resource group $AZURE_RESOURCE_GROUP exists..."
    if ! az group show --name "$AZURE_RESOURCE_GROUP" &> /dev/null; then
        echo -e "${RED}Error: Resource group $AZURE_RESOURCE_GROUP does not exist${NC}"
        echo "Set CREATE_RESOURCE_GROUP=true in .env to create it automatically"
        exit 1
    fi
    echo -e "${GREEN}Resource group exists${NC}"
fi

# Determine parameter file
PARAM_FILE=""
if [ -f "$PROJECT_ROOT/infra/bicep/parameters/${ENVIRONMENT_NAME}.bicepparam" ]; then
    PARAM_FILE="$PROJECT_ROOT/infra/bicep/parameters/${ENVIRONMENT_NAME}.bicepparam"
    echo "Using parameter file: ${ENVIRONMENT_NAME}.bicepparam"
else
    echo -e "${YELLOW}Warning: No parameter file found for environment '$ENVIRONMENT_NAME'${NC}"
    echo "Using inline parameters from .env"
fi

# Deploy Bicep template
echo -e "${GREEN}Deploying infrastructure...${NC}"
DEPLOYMENT_NAME="monitorlab-$(date +%Y%m%d-%H%M%S)"

# Get publisher email and name from .env or use defaults
PUBLISHER_EMAIL="${PUBLISHER_EMAIL:-admin@example.com}"
PUBLISHER_NAME="${PUBLISHER_NAME:-Azure Monitor Lab}"
RECURRENCE_INTERVAL="${LOGIC_APP_RECURRENCE_INTERVAL:-30}"

if [ -n "$PARAM_FILE" ]; then
    DEPLOYMENT_OUTPUT=$(az deployment group create \
        --name "$DEPLOYMENT_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --template-file "$PROJECT_ROOT/infra/bicep/main.bicep" \
        --parameters "$PARAM_FILE" \
        --parameters publisherEmail="$PUBLISHER_EMAIL" \
        --parameters publisherName="$PUBLISHER_NAME" \
        --parameters recurrenceIntervalSeconds="$RECURRENCE_INTERVAL" \
        --output json)
else
    
    DEPLOYMENT_OUTPUT=$(az deployment group create \
        --name "$DEPLOYMENT_NAME" \
        --resource-group "$AZURE_RESOURCE_GROUP" \
        --template-file "$PROJECT_ROOT/infra/bicep/main.bicep" \
        --parameters environmentName="$ENVIRONMENT_NAME" \
        --parameters location="$AZURE_LOCATION" \
        --parameters publisherEmail="$PUBLISHER_EMAIL" \
        --parameters publisherName="$PUBLISHER_NAME" \
        --parameters logAnalyticsRetentionDays="${LOG_ANALYTICS_RETENTION_DAYS:-30}" \
        --parameters recurrenceIntervalSeconds="$RECURRENCE_INTERVAL" \
        --output json)
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Deployment successful!${NC}"
    echo ""
    
    # Parse and display outputs
    echo -e "${GREEN}=== Deployment Outputs ===${NC}"
    echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs | to_entries[] | "\(.key): \(.value.value)"' 2>/dev/null || echo "$DEPLOYMENT_OUTPUT"
    
    # Save outputs to file
    OUTPUT_FILE="$PROJECT_ROOT/deployment-outputs.json"
    echo "$DEPLOYMENT_OUTPUT" | jq '.properties.outputs' > "$OUTPUT_FILE" 2>/dev/null
    echo ""
    echo -e "${GREEN}Deployment outputs saved to: $OUTPUT_FILE${NC}"
    
    echo ""
    echo -e "${GREEN}=== Next Steps ===${NC}"
    echo "1. Review the deployed resources in the Azure Portal"
    echo "2. Deploy the Function App code from src/function-app/"
    echo "3. Follow the lab guide in doc/lab-guide/"
    echo ""
    
else
    echo -e "${RED}✗ Deployment failed${NC}"
    exit 1
fi
