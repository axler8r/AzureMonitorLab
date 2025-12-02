using '../main.bicep'

// Development environment parameters
param environmentName = 'devlab'
param location = 'australiaeast'
param logAnalyticsRetentionDays = 30

// Publisher info - overridden by .env values during deployment
param publisherEmail = 'placeholder@example.com'
param publisherName = 'Placeholder'

// Logic App telemetry generation interval (30 seconds for fast demo feedback)
param recurrenceIntervalSeconds = 30
