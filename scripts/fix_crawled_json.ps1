[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$jsonPath = Join-Path $PSScriptRoot "..\data\crawled_subsidies_latest.json"
$ktPath = Join-Path $PSScriptRoot "..\data\kt_full_items.json"

$old = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$ktArray = Get-Content $ktPath -Raw -Encoding UTF8 | ConvertFrom-Json

$newData = [PSCustomObject]@{
    summary = [PSCustomObject]@{
        totalCount = ($old.skt.Count + $old.lgu.Count + $ktArray.Count)
        sktCount = $old.skt.Count
        lguCount = $old.lgu.Count
        ktCount = $ktArray.Count
    }
    skt = $old.skt
    lgu = $old.lgu
    kt = $ktArray
}

$newData | ConvertTo-Json -Depth 10 | Out-File $jsonPath -Encoding UTF8
Write-Host "Fixed! Total: $($newData.summary.totalCount), KT: $($newData.summary.ktCount)"
