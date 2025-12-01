#!/bin/bash
#
# Azure Monitor Lab - Cleanup Script (Bash)
# This script removes all Azure Monitor Lab resources
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
    echo -e "${YELLOW}Please ensure .env file exists with your configuration.${NC}"
    exit 1
fi

# Source the .env file
set -a
source "$ENV_FILE"
set +a

# Validate required variables
if [ -z "$AZURE_SUBSCRIPTION_ID" ] || [ -z "$AZURE_RESOURCE_GROUP" ]; then
    echo -e "${RED}Error: Missing required environment variables in .env${NC}"
    echo "Required: AZURE_SUBSCRIPTION_ID, AZURE_RESOURCE_GROUP"
    exit 1
fi

echo -e "${YELLOW}=== Azure Monitor Lab Cleanup ===${NC}"
echo "Subscription ID: $AZURE_SUBSCRIPTION_ID"
echo "Resource Group: $AZURE_RESOURCE_GROUP"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed${NC}"
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

# Check if resource group exists
if ! az group show --name "$AZURE_RESOURCE_GROUP" &> /dev/null; then
    echo -e "${YELLOW}Resource group $AZURE_RESOURCE_GROUP does not exist. Nothing to clean up.${NC}"
    exit 0
fi

# Confirm deletion
echo -e "${RED}WARNING: This will DELETE the resource group and ALL resources within it!${NC}"
echo "Resource Group: $AZURE_RESOURCE_GROUP"
echo ""
read -p "Are you sure you want to continue? (yes/no): " CONFIRMATION

if [ "$CONFIRMATION" != "yes" ]; then
    echo -e "${YELLOW}Cleanup cancelled.${NC}"
    exit 0
fi

# Final confirmation
echo ""
read -p "Type the resource group name to confirm deletion: " RG_CONFIRM

if [ "$RG_CONFIRM" != "$AZURE_RESOURCE_GROUP" ]; then
    echo -e "${RED}Resource group name does not match. Cleanup cancelled.${NC}"
    exit 1
fi

# Delete resource group
echo ""
echo -e "${GREEN}Deleting resource group $AZURE_RESOURCE_GROUP...${NC}"
echo "This may take several minutes..."

az group delete \
    --name "$AZURE_RESOURCE_GROUP" \
    --yes \
    --no-wait

echo ""
echo -e "${GREEN}✓ Resource group deletion initiated${NC}"
echo "The deletion is running in the background. You can check the status with:"
echo "  az group show --name $AZURE_RESOURCE_GROUP"
echo ""
echo "To monitor the deletion progress:"
echo "  az group wait --name $AZURE_RESOURCE_GROUP --deleted"
echo ""

# Clean up local output files
if [ -f "$PROJECT_ROOT/deployment-outputs.json" ]; then
    echo "Removing local deployment outputs..."
    rm "$PROJECT_ROOT/deployment-outputs.json"
fi

echo -e "${GREEN}Cleanup complete!${NC}"
