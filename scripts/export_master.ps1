$resp = Invoke-RestMethod -Uri 'https://firestore.googleapis.com/v1/projects/phone-price-91c3c/databases/(default)/documents/global_config/devices_master' -Method Get
$resp | ConvertTo-Json -Depth 10 | Out-File (Join-Path $PSScriptRoot "..\data\current_firestore_devices_master.json") -Encoding UTF8
Write-Host "Exported current firestore devices_master!"
