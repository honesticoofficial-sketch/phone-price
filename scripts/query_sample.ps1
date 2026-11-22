$json = Get-Content (Join-Path $PSScriptRoot "..\data\crawled_subsidies_latest.json") -Raw | ConvertFrom-Json

Write-Host "=== KT Samples ==="
$json.kt | ForEach-Object {
    Write-Host "$($_.model) | 출고가: $($_.factoryPrice)원 | 공시: $($_.subsidy)원"
}

Write-Host "`n=== SKT Samples (Top 10) ==="
$json.skt | Select-Object -First 10 | ForEach-Object {
    Write-Host "$($_.model) | 출고가: $($_.factoryPrice)원 | 공시: $($_.subsidy)원"
}
