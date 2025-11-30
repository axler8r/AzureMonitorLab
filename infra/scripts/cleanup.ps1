#!/usr/bin/env pwsh
#
# Azure Monitor Lab - Cleanup Script (PowerShell)
# This script removes all Azure Monitor Lab resources
#

$ErrorActionPreference = "Stop"

# Script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)

# Load environment variables from .env file
$EnvFile = Join-Path $ProjectRoot ".env"
if (-not (Test-Path $EnvFile)) {
    Write-Host "Error: .env file not found at $EnvFile" -ForegroundColor Red
    Write-Host "Please ensure .env file exists with your configuration." -ForegroundColor Yellow
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

# Validate required variables
if (-not $SubscriptionId -or -not $ResourceGroup) {
    Write-Host "Error: Missing required environment variables in .env" -ForegroundColor Red
    Write-Host "Required: AZURE_SUBSCRIPTION_ID, AZURE_RESOURCE_GROUP"
    exit 1
}

Write-Host "=== Azure Monitor Lab Cleanup ===" -ForegroundColor Yellow
Write-Host "Subscription ID: $SubscriptionId"
Write-Host "Resource Group: $ResourceGroup"
Write-Host ""

# Check if Azure CLI is installed
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Azure CLI is not installed" -ForegroundColor Red
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
$rgExists = az group show --name $ResourceGroup 2>$null
if (-not $rgExists) {
    Write-Host "Resource group $ResourceGroup does not exist. Nothing to clean up." -ForegroundColor Yellow
    exit 0
}

# Confirm deletion
Write-Host ""
Write-Host "WARNING: This will DELETE the resource group and ALL resources within it!" -ForegroundColor Red
Write-Host "Resource Group: $ResourceGroup"
Write-Host ""

$confirmation = Read-Host "Are you sure you want to continue? (yes/no)"
if ($confirmation -ne "yes") {
    Write-Host "Cleanup cancelled." -ForegroundColor Yellow
    exit 0
}

# Final confirmation
Write-Host ""
$rgConfirm = Read-Host "Type the resource group name to confirm deletion"
if ($rgConfirm -ne $ResourceGroup) {
    Write-Host "Resource group name does not match. Cleanup cancelled." -ForegroundColor Red
    exit 1
}

# Delete resource group
Write-Host ""
Write-Host "Deleting resource group $ResourceGroup..." -ForegroundColor Green
Write-Host "This may take several minutes..."

az group delete `
    --name $ResourceGroup `
    --yes `
    --no-wait

Write-Host ""
Write-Host "✓ Resource group deletion initiated" -ForegroundColor Green
Write-Host "The deletion is running in the background. You can check the status with:"
Write-Host "  az group show --name $ResourceGroup"
Write-Host ""
Write-Host "To monitor the deletion progress:"
Write-Host "  az group wait --name $ResourceGroup --deleted"
Write-Host ""

# Clean up local output files
$OutputFile = Join-Path $ProjectRoot "deployment-outputs.json"
if (Test-Path $OutputFile) {
    Write-Host "Removing local deployment outputs..."
    Remove-Item $OutputFile
}

Write-Host "Cleanup complete!" -ForegroundColor Green
