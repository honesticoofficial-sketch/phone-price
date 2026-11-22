try {
    $resp = Invoke-RestMethod -Uri 'https://firestore.googleapis.com/v1/projects/phone-price-91c3c/databases/(default)/documents/global_config/devices_master' -Method Get
    Write-Host "devices_master exists in phone-price-91c3c!"
    Write-Host "Count: $($resp.fields.devices.arrayValue.values.Count)"
} catch {
    Write-Host "Error or not found: $_"
}
