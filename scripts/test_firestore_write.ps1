try {
    $body = @{
        fields = @{
            testField = @{ stringValue = "hello_world" }
        }
    } | ConvertTo-Json

    $resp = Invoke-RestMethod -Uri 'https://firestore.googleapis.com/v1/projects/phone-price-91c3c/databases/(default)/documents/test_collection/test_doc' -Method Patch -Body $body -ContentType "application/json"
    Write-Host "Firestore write success! Doc name: $($resp.name)"
} catch {
    Write-Host "Write failed: $_"
}
