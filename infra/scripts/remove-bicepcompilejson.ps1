# Clean compiled Bicep artifacts (JSON files)
# Removes all generated ARM template JSON files while preserving bicepconfig.json

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BicepDir = Join-Path (Split-Path -Parent $ScriptDir) "bicep"

Write-Host "=== Cleaning Bicep Compiled Artifacts ===" -ForegroundColor Cyan
Write-Host "Bicep directory: $BicepDir"
Write-Host ""

# Find and delete all .json files except bicepconfig.json
$JsonFiles = Get-ChildItem -Path $BicepDir -Filter "*.json" -Recurse -File | 
    Where-Object { $_.Name -ne "bicepconfig.json" }

$DeletedCount = 0

foreach ($file in $JsonFiles) {
    $relativePath = $file.FullName.Substring($BicepDir.Length + 1)
    Write-Host "Deleting: $relativePath"
    Remove-Item -Path $file.FullName -Force
    $DeletedCount++
}

Write-Host ""
if ($DeletedCount -eq 0) {
    Write-Host "No compiled artifacts found. Already clean!" -ForegroundColor Green
} else {
    Write-Host "✓ Deleted $DeletedCount compiled artifact(s)" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Cleanup Complete ===" -ForegroundColor Cyan
