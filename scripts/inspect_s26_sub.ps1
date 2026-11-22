$resp = Invoke-RestMethod -Uri 'https://firestore.googleapis.com/v1/projects/phone-price-91c3c/databases/(default)/documents/global_config/devices_master' -Method Get
$s26 = $resp.fields.devices.arrayValue.values | Where-Object { $_.mapValue.fields.id.stringValue -eq 's26' }
$s26.mapValue.fields.sub.mapValue.fields | ConvertTo-Json -Depth 5 | Write-Host
