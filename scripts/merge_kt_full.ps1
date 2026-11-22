[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$jsonPath = Join-Path $PSScriptRoot "..\data\crawled_subsidies_latest.json"
$ktPath = Join-Path $PSScriptRoot "..\data\kt_full_items.json"

$mainData = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$ktRaw = Get-Content $ktPath -Raw -Encoding UTF8 | ConvertFrom-Json

# If ktRaw has .value or is array
$items = if ($ktRaw.value) { $ktRaw.value } else { $ktRaw }

$mainData.kt = @($items)
$mainData.summary.ktCount = $items.Count
$mainData.summary.totalCount = $mainData.summary.sktCount + $mainData.summary.lguCount + $items.Count

$mainData | ConvertTo-Json -Depth 10 | Out-File $jsonPath -Encoding UTF8

Write-Host "Correctly merged KT array with $($items.Count) items! Total: $($mainData.summary.totalCount)"
