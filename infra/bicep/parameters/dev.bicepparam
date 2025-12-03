using '../main.bicep'

// Development environment parameters
param environmentName = 'devlab'
param location = 'australiaeast'
param logAnalyticsRetentionDays = 30

// Publisher info - overridden by .env values during deployment
param publisherEmail = 'placeholder@example.com'
param publisherName = 'Placeholder'

// Logic App recurrence interval (60 seconds default for both workflows)
param recurrenceIntervalSeconds = 60
