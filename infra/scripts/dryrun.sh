#!/bin/bash
#
# Azure Monitor Lab - Dry Run Script (Bash)
# This script validates and previews infrastructure changes without deploying
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Source the .env file (strip inline comments)
set -a
while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    # Remove inline comments and export
    line=$(echo "$line" | sed 's/#.*$//' | xargs)
    [[ -n "$line" ]] && export "$line"
done < "$ENV_FILE"
set +a

# Validate required variables
if [ -z "$AZURE_SUBSCRIPTION_ID" ] || [ -z "$AZURE_RESOURCE_GROUP" ] || [ -z "$AZURE_LOCATION" ] || [ -z "$ENVIRONMENT_NAME" ]; then
    echo -e "${RED}Error: Missing required environment variables in .env${NC}"
    echo "Required: AZURE_SUBSCRIPTION_ID, AZURE_RESOURCE_GROUP, AZURE_LOCATION, ENVIRONMENT_NAME"
    exit 1
fi

echo -e "${BLUE}=== Azure Monitor Lab - Dry Run ===${NC}"
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

# Check if resource group exists
if [ "$CREATE_RESOURCE_GROUP" = "true" ]; then
    echo -e "${YELLOW}Note: CREATE_RESOURCE_GROUP=true - Resource group will be created during actual deployment${NC}"
else
    echo "Verifying resource group $AZURE_RESOURCE_GROUP exists..."
    if ! az group show --name "$AZURE_RESOURCE_GROUP" &> /dev/null; then
        echo -e "${RED}Error: Resource group $AZURE_RESOURCE_GROUP does not exist${NC}"
        echo "Set CREATE_RESOURCE_GROUP=true in .env or create the resource group manually"
        exit 1
    fi
    echo -e "${GREEN}Resource group exists${NC}"
fi

# Get publisher email from .env or use default
PUBLISHER_EMAIL="${PUBLISHER_EMAIL:-admin@example.com}"

echo ""
echo -e "${BLUE}=== Step 1: Bicep Syntax Validation ===${NC}"
echo "Building Bicep template..."
if az bicep build --file "$PROJECT_ROOT/infra/bicep/main.bicep"; then
    echo -e "${GREEN}✓ Bicep syntax is valid${NC}"
else
    echo -e "${RED}✗ Bicep build failed${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}=== Step 2: Template Validation ===${NC}"
echo "Validating template against Azure APIs..."

# Create resource group if it doesn't exist (for validation only)
TEMP_RG_CREATED=false
if ! az group show --name "$AZURE_RESOURCE_GROUP" &> /dev/null; then
    echo -e "${YELLOW}Creating temporary resource group for validation...${NC}"
    az group create --name "$AZURE_RESOURCE_GROUP" --location "$AZURE_LOCATION" --tags "Temporary=true" "Purpose=Validation"
    TEMP_RG_CREATED=true
fi

if az deployment group validate \
    --resource-group "$AZURE_RESOURCE_GROUP" \
    --template-file "$PROJECT_ROOT/infra/bicep/main.bicep" \
    --parameters environmentName="$ENVIRONMENT_NAME" \
    --parameters location="$AZURE_LOCATION" \
    --parameters publisherEmail="$PUBLISHER_EMAIL" \
    --parameters logAnalyticsRetentionDays="${LOG_ANALYTICS_RETENTION_DAYS:-30}" \
    --output json 2>&1; then
    echo -e "${GREEN}✓ Template validation passed${NC}"
else
    echo -e "${RED}✗ Template validation failed${NC}"
    echo -e "${YELLOW}Check the error message above for details${NC}"
    
    # Clean up temporary resource group if created
    if [ "$TEMP_RG_CREATED" = true ]; then
        echo "Cleaning up temporary resource group..."
        az group delete --name "$AZURE_RESOURCE_GROUP" --yes --no-wait
    fi
    exit 1
fi

echo ""
echo -e "${BLUE}=== Step 3: What-If Analysis ===${NC}"
echo "Analyzing deployment changes (this may take 1-2 minutes)..."
echo ""

az deployment group what-if \
    --resource-group "$AZURE_RESOURCE_GROUP" \
    --template-file "$PROJECT_ROOT/infra/bicep/main.bicep" \
    --parameters environmentName="$ENVIRONMENT_NAME" \
    --parameters location="$AZURE_LOCATION" \
    --parameters publisherEmail="$PUBLISHER_EMAIL" \
    --parameters logAnalyticsRetentionDays="${LOG_ANALYTICS_RETENTION_DAYS:-30}" \
    --result-format FullResourcePayloads

# Clean up temporary resource group if created
if [ "$TEMP_RG_CREATED" = true ]; then
    echo ""
    echo -e "${YELLOW}Cleaning up temporary validation resource group...${NC}"
    az group delete --name "$AZURE_RESOURCE_GROUP" --yes --no-wait
    echo -e "${YELLOW}Note: The resource group will be created during actual deployment${NC}"
fi

echo ""
echo -e "${GREEN}=== Dry Run Complete ===${NC}"
echo ""
echo -e "${BLUE}Summary:${NC}"
echo "  ✓ Bicep syntax validated"
echo "  ✓ Template validated against Azure APIs"
echo "  ✓ What-If analysis completed"
echo ""
echo -e "${GREEN}To proceed with deployment, run:${NC}"
echo "  ./infra/scripts/deploy.sh"
echo ""
