#!/usr/bin/env pwsh
#
# Azure Monitor Lab - Dry Run Script (PowerShell)
# This script validates and previews infrastructure changes without deploying
#

param(
    [switch]$Detailed
)

$ErrorActionPreference = "Stop"

# Script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)

# Load environment variables from .env file
$EnvFile = Join-Path $ProjectRoot ".env"
if (-not (Test-Path $EnvFile)) {
    Write-Host "Error: .env file not found at $EnvFile" -ForegroundColor Red
    Write-Host "Please copy .env.example to .env and configure your settings." -ForegroundColor Yellow
    exit 1
}

# Parse .env file (strip inline comments)
Get-Content $EnvFile | ForEach-Object {
    # Skip empty lines and comment-only lines
    if ($_ -match '^\s*$' -or $_ -match '^\s*#') { return }
    
    # Parse line and strip inline comments
    if ($_ -match '^\s*([^#][^=]*)\s*=\s*(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        
        # Remove inline comments (everything after #)
        if ($value -match '^([^#]*)#.*$') {
            $value = $matches[1].Trim()
        }
        
        # Remove surrounding quotes if present
        $value = $value.Trim('"', "'")
        
        [Environment]::SetEnvironmentVariable($name, $value, "Process")
    }
}

# Get environment variables
$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID
$ResourceGroup = $env:AZURE_RESOURCE_GROUP
$Location = $env:AZURE_LOCATION
$EnvironmentName = $env:ENVIRONMENT_NAME
$CreateResourceGroup = $env:CREATE_RESOURCE_GROUP -eq "true"
$PublisherEmail = if ($env:PUBLISHER_EMAIL) { $env:PUBLISHER_EMAIL } else { "admin@example.com" }
$RetentionDays = if ($env:LOG_ANALYTICS_RETENTION_DAYS) { [int]$env:LOG_ANALYTICS_RETENTION_DAYS } else { 30 }

# Validate required variables
if (-not $SubscriptionId -or -not $ResourceGroup -or -not $Location -or -not $EnvironmentName) {
    Write-Host "Error: Missing required environment variables in .env" -ForegroundColor Red
    Write-Host "Required: AZURE_SUBSCRIPTION_ID, AZURE_RESOURCE_GROUP, AZURE_LOCATION, ENVIRONMENT_NAME"
    exit 1
}

Write-Host "=== Azure Monitor Lab - Dry Run ===" -ForegroundColor Blue
Write-Host "Subscription ID: $SubscriptionId"
Write-Host "Resource Group: $ResourceGroup"
Write-Host "Location: $Location"
Write-Host "Environment: $EnvironmentName"
Write-Host ""

# Check if Azure CLI is installed
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Azure CLI is not installed" -ForegroundColor Red
    Write-Host "Please install Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
}

# Login check
Write-Host "Checking Azure CLI login status..."
$accountInfo = az account show 2>$null | ConvertFrom-Json
if (-not $accountInfo) {
    Write-Host "Not logged in to Azure. Initiating login..." -ForegroundColor Yellow
    az login
}

# Set subscription
Write-Host "Setting subscription to $SubscriptionId..."
az account set --subscription $SubscriptionId

# Check if resource group exists
if ($CreateResourceGroup) {
    Write-Host "Note: CREATE_RESOURCE_GROUP=true - Resource group will be created during actual deployment" -ForegroundColor Yellow
} else {
    Write-Host "Verifying resource group $ResourceGroup exists..."
    $rgExists = az group show --name $ResourceGroup 2>$null
    if (-not $rgExists) {
        Write-Host "Error: Resource group $ResourceGroup does not exist" -ForegroundColor Red
        Write-Host "Set CREATE_RESOURCE_GROUP=true in .env or create the resource group manually"
        exit 1
    }
    Write-Host "Resource group exists" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Step 1: Bicep Syntax Validation ===" -ForegroundColor Blue
Write-Host "Building Bicep template..."

try {
    az bicep build --file (Join-Path $ProjectRoot "infra/bicep/main.bicep") 2>&1 | Out-Null
    Write-Host "✓ Bicep syntax is valid" -ForegroundColor Green
} catch {
    Write-Host "✗ Bicep build failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Step 2: Template Validation ===" -ForegroundColor Blue
Write-Host "Validating template against Azure APIs..."

# Create resource group if it doesn't exist (for validation only)
$TempRgCreated = $false
$rgExists = az group show --name $ResourceGroup 2>$null
if (-not $rgExists) {
    Write-Host "Creating temporary resource group for validation..." -ForegroundColor Yellow
    az group create --name $ResourceGroup --location $Location --tags "Temporary=true" "Purpose=Validation" | Out-Null
    $TempRgCreated = $true
}

try {
    $validation = az deployment group validate `
        --resource-group $ResourceGroup `
        --template-file (Join-Path $ProjectRoot "infra/bicep/main.bicep") `
        --parameters environmentName=$EnvironmentName `
        --parameters location=$Location `
        --parameters publisherEmail=$PublisherEmail `
        --parameters logAnalyticsRetentionDays=$RetentionDays `
        --output json 2>&1 | ConvertFrom-Json

    Write-Host "✓ Template validation passed" -ForegroundColor Green
} catch {
    Write-Host "✗ Template validation failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    
    if ($TempRgCreated) {
        Write-Host "Cleaning up temporary resource group..."
        az group delete --name $ResourceGroup --yes --no-wait
    }
    exit 1
}

Write-Host ""
Write-Host "=== Step 3: What-If Analysis ===" -ForegroundColor Blue
Write-Host "Analyzing deployment changes (this may take 1-2 minutes)..."
Write-Host ""

$resultFormat = if ($Detailed) { "FullResourcePayloads" } else { "ResourceIdOnly" }

az deployment group what-if `
    --resource-group $ResourceGroup `
    --template-file (Join-Path $ProjectRoot "infra/bicep/main.bicep") `
    --parameters environmentName=$EnvironmentName `
    --parameters location=$Location `
    --parameters publisherEmail=$PublisherEmail `
    --parameters logAnalyticsRetentionDays=$RetentionDays `
    --result-format $resultFormat

# Clean up temporary resource group if created
if ($TempRgCreated) {
    Write-Host ""
    Write-Host "Cleaning up temporary validation resource group..." -ForegroundColor Yellow
    az group delete --name $ResourceGroup --yes --no-wait
    Write-Host "Note: The resource group will be created during actual deployment" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Dry Run Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Blue
Write-Host "  ✓ Bicep syntax validated"
Write-Host "  ✓ Template validated against Azure APIs"
Write-Host "  ✓ What-If analysis completed"
Write-Host ""
Write-Host "To proceed with deployment, run:" -ForegroundColor Green
Write-Host "  .\infra\scripts\deploy.ps1"
Write-Host ""

if (-not $Detailed) {
    Write-Host "Tip: Run with -Detailed flag for full resource payloads in What-If analysis" -ForegroundColor Cyan
}
