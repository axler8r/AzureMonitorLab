using '../main.bicep'

// Production environment parameters
param environmentName = 'prodlab'
param location = 'australiaeast'
param logAnalyticsRetentionDays = 90

// Publisher info - overridden by .env values during deployment
param publisherEmail = 'placeholder@example.com'
param publisherName = 'Placeholder'

// Logic App recurrence interval (60 seconds for both workflows)
param recurrenceIntervalSeconds = 60
