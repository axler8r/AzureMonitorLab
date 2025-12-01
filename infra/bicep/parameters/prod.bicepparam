using '../main.bicep'

// Production environment parameters
param environmentName = 'prodlab'
param location = 'eastus'
param logAnalyticsRetentionDays = 90
param publisherEmail = 'your-email@example.com'
param publisherName = 'Azure Monitor Lab - Production'
