#!/usr/bin/env pwsh
#
# Azure Monitor Lab - Deployment Script (PowerShell)
# This script deploys the Azure Monitor Lab infrastructure using Bicep templates
#

param(
    [switch]$WhatIf
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

# Parse .env file
Get-Content $EnvFile | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]*)\s*=\s*(.*)$') {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
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

Write-Host "=== Azure Monitor Lab Deployment ===" -ForegroundColor Green
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

# Create or verify resource group
if ($CreateResourceGroup) {
    Write-Host "Creating resource group $ResourceGroup..." -ForegroundColor Green
    az group create `
        --name $ResourceGroup `
        --location $Location `
        --tags "Environment=$EnvironmentName" "Project=AzureMonitorLab" "ManagedBy=Bicep"
} else {
    Write-Host "Verifying resource group $ResourceGroup exists..."
    $rgExists = az group show --name $ResourceGroup 2>$null
    if (-not $rgExists) {
        Write-Host "Error: Resource group $ResourceGroup does not exist" -ForegroundColor Red
        Write-Host "Set CREATE_RESOURCE_GROUP=true in .env to create it automatically"
        exit 1
    }
    Write-Host "Resource group exists" -ForegroundColor Green
}

# Determine parameter file
$ParamFile = Join-Path $ProjectRoot "infra/bicep/parameters/${EnvironmentName}.bicepparam"
if (Test-Path $ParamFile) {
    Write-Host "Using parameter file: ${EnvironmentName}.bicepparam"
} else {
    Write-Host "Warning: No parameter file found for environment '$EnvironmentName'" -ForegroundColor Yellow
    Write-Host "Using inline parameters from .env"
    $ParamFile = $null
}

# Deploy Bicep template
Write-Host "Deploying infrastructure..." -ForegroundColor Green
$DeploymentName = "monitorlab-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

$deployParams = @{
    Name = $DeploymentName
    ResourceGroupName = $ResourceGroup
    TemplateFile = Join-Path $ProjectRoot "infra/bicep/main.bicep"
}

if ($ParamFile) {
    $deployParams.TemplateParameterFile = $ParamFile
    $deployParams.TemplateParameterObject = @{
        environmentName = $EnvironmentName
    }
} else {
    $deployParams.TemplateParameterObject = @{
        environmentName = $EnvironmentName
        location = $Location
        publisherEmail = $PublisherEmail
        logAnalyticsRetentionDays = $RetentionDays
    }
}

if ($WhatIf) {
    $deployParams.WhatIf = $true
}

try {
    $deployment = az deployment group create `
        --name $DeploymentName `
        --resource-group $ResourceGroup `
        --template-file (Join-Path $ProjectRoot "infra/bicep/main.bicep") `
        $(if ($ParamFile) { "--parameters `"$ParamFile`"" }) `
        --parameters publisherEmail=$PublisherEmail `
        --parameters publisherName=$PublisherName `
        --parameters logAnalyticsRetentionDays=$RetentionDays `
        --output json | ConvertFrom-Json

    Write-Host "✓ Deployment successful!" -ForegroundColor Green
    Write-Host ""
    
    # Display outputs
    Write-Host "=== Deployment Outputs ===" -ForegroundColor Green
    $deployment.properties.outputs.PSObject.Properties | ForEach-Object {
        Write-Host "$($_.Name): $($_.Value.value)"
    }
    
    # Save outputs to file
    $OutputFile = Join-Path $ProjectRoot "deployment-outputs.json"
    $deployment.properties.outputs | ConvertTo-Json -Depth 10 | Out-File $OutputFile
    Write-Host ""
    Write-Host "Deployment outputs saved to: $OutputFile" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "=== Next Steps ===" -ForegroundColor Green
    Write-Host "1. Review the deployed resources in the Azure Portal"
    Write-Host "2. Deploy the Function App code from src/function-app/"
    Write-Host "3. Follow the lab guide in doc/lab-guide/"
    Write-Host ""
    
} catch {
    Write-Host "✗ Deployment failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
