[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$jsonPath = Join-Path $PSScriptRoot "..\data\crawled_subsidies_latest.json"
$ktPath = Join-Path $PSScriptRoot "..\data\kt_full_items.json"

$data = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$ktFull = Get-Content $ktPath -Raw -Encoding UTF8 | ConvertFrom-Json

function IsTargetModel($name) {
    # 1. 제외 대상: 워치, 버즈, 태블릿, 피처폰/폴더폰, 타사(샤오미/모토로라)
    if ($name -match '워치|Watch|버즈|Buds|태블릿|Tab|패드|클래식 폴더|샤오미|레드미|홍미|모토|moto') { return $false }
    # 2. 제외 대상: 갤럭시 A 시리즈 및 보급형(퀀텀, 와이드, 점프, 버디, 키즈폰)
    if ($name -match '갤럭시 A|Galaxy A|A\d{2}\s|A\d{2}$|SM-A\d+|퀀텀|와이드|점프|버디|키즈폰') { return $false }

    # 3. 수집 대상: 아이폰, S시리즈, 폴더블(폴드/플립), FE류, 엣지류
    if ($name -match 'iPhone|아이폰') { return $true }
    if ($name -match 'S\d+|갤럭시 S|Galaxy S') { return $true }
    if ($name -match 'Fold|Flip|폴드|플립') { return $true }
    if ($name -match 'FE') { return $true }
    if ($name -match '엣지|Edge') { return $true }
    if ($name -match 'Duo|Air') { return $true }
    return $false
}

$sktFiltered = @($data.skt | Where-Object { IsTargetModel $_.model })
$ktFiltered = @($ktFull | Where-Object { IsTargetModel $_.model })
$lguFiltered = @($data.lgu | Where-Object { IsTargetModel $_.model })

$filteredData = [PSCustomObject]@{
    summary = [PSCustomObject]@{
        targetFilter = "S시리즈, 아이폰, 폴더블, FE류, 엣지류 전용 (A시리즈 및 보급형 제외)"
        totalCount = ($sktFiltered.Count + $ktFiltered.Count + $lguFiltered.Count)
        sktCount = $sktFiltered.Count
        ktCount = $ktFiltered.Count
        lguCount = $lguFiltered.Count
        plansApplied = [PSCustomObject]@{
            SKT = "베스트 109 요금제 (넷가표 109,000원 기준)"
            KT = "초이스/스페셜 110 요금제 (넷가표 110,000원 기준)"
            LGU = "프리미어 105/95 요금제 (넷가표 105,000원 기준)"
        }
    }
    skt = $sktFiltered
    kt = $ktFiltered
    lgu = $lguFiltered
}

$filteredData | ConvertTo-Json -Depth 10 | Out-File $jsonPath -Encoding UTF8

Write-Host "Filtered dataset saved successfully!"
Write-Host "Total: $($filteredData.summary.totalCount) (SKT: $($sktFiltered.Count), KT: $($ktFiltered.Count), LGU+: $($lguFiltered.Count))"
