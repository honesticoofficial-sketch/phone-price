$resp = Invoke-RestMethod -Uri 'https://firestore.googleapis.com/v1/projects/phone-price-91c3c/databases/(default)/documents/global_config/devices_master' -Method Get
$devices = $resp.fields.devices.arrayValue.values
foreach ($d in $devices) {
    $id = $d.mapValue.fields.id.stringValue
    $name = $d.mapValue.fields.name.stringValue
    $skPrice = $d.mapValue.fields.prices.mapValue.fields.SK.doubleValue
    if (-not $skPrice) { $skPrice = $d.mapValue.fields.prices.mapValue.fields.SK.integerValue }
    Write-Host "$id : $name (SK 출고가: $skPrice 만원)"
}
