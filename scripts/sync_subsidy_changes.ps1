[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$snapshotPath = Join-Path $root "data\subsidy_snapshot_3carrier.json"
$fsDocUrl = "https://firestore.googleapis.com/v1/projects/phone-price-91c3c/databases/(default)/documents/global_config/subsidy_changes"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " [통신 3사 공시지원금 변동내역 자동 수집 & Firestore 동기화]" -ForegroundColor Cyan
Write-Host " - 대상 범위: 갤럭시 S시리즈, FE시리즈, 아이폰, 폴더블류" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

function Test-TargetFlagship($name) {
    if (-not $name) { return $false }
    if ($name -match '워치|Watch|버즈|Buds|태블릿|Tab|패드|Pad|키즈|Kids|산리오|시나모롤|포켓몬|캐치티니핑|갤럭시\s*A|Galaxy\s*A|SM-A\d+|퀀텀|와이드|점프|버디|샤오미|홍미|Redmi|모토|Moto|ZTE|시니어|스타일|클래식\s*폴더|폴더2') {
        return $false
    }
    return ($name -match '(?i)(iPhone|아이폰|갤럭시\s*S|Galaxy\s*S|\bS2[0-9]|폴드|Fold|플립|Flip|듀오|Duo|\bFE\b|S\d+\s*FE|엣지|Edge)')
}

function ConvertTo-FsVal($val) {
    if ($null -eq $val) { return @{ nullValue = $null } }
    if ($val -is [string]) { return @{ stringValue = $val } }
    if ($val -is [bool]) { return @{ booleanValue = $val } }
    if ($val -is [int] -or $val -is [long]) { return @{ integerValue = [string]$val } }
    if ($val -is [double] -or $val -is [decimal]) { return @{ doubleValue = [double]$val } }
    if ($val -is [System.Collections.IEnumerable] -and -not ($val -is [System.Collections.IDictionary])) {
        $arr = @()
        foreach ($x in $val) { $arr += ,(ConvertTo-FsVal $x) }
        return @{ arrayValue = @{ values = $arr } }
    }
    $fields = @{}
    if ($val -is [System.Collections.IDictionary]) {
        foreach ($k in $val.Keys) { $fields[$k] = ConvertTo-FsVal $val[$k] }
    } else {
        foreach ($p in $val.PSObject.Properties) { $fields[$p.Name] = ConvertTo-FsVal $p.Value }
    }
    return @{ mapValue = @{ fields = $fields } }
}

function ConvertFrom-FsVal($v) {
    if (-not $v) { return $null }
    if ($v.PSObject.Properties["stringValue"]) { return $v.stringValue }
    if ($v.PSObject.Properties["integerValue"]) { return [int64]$v.integerValue }
    if ($v.PSObject.Properties["doubleValue"]) { return [double]$v.doubleValue }
    if ($v.PSObject.Properties["booleanValue"]) { return [bool]$v.booleanValue }
    if ($v.PSObject.Properties["nullValue"]) { return $null }
    if ($v.PSObject.Properties["arrayValue"]) {
        $res = @()
        if ($v.arrayValue.values) {
            foreach ($x in $v.arrayValue.values) { $res += ,(ConvertFrom-FsVal $x) }
        }
        return $res
    }
    if ($v.PSObject.Properties["mapValue"]) {
        $out = @{}
        if ($v.mapValue.fields) {
            foreach ($p in $v.mapValue.fields.PSObject.Properties) {
                $out[$p.Name] = ConvertFrom-FsVal $p.Value
            }
        }
        return $out
    }
    return $null
}

# 1. SKT + KT + LGU+ 현재 데이터 수집 (기존 크롤러 실행 후 crawled_subsidies_latest.json 활용 가능)
$crawlScript = Join-Path $root "scripts\crawl_carrier_subsidies.ps1"
if (Test-Path $crawlScript) {
    Write-Host ">>> 3사 공식 크롤링 실행 중..." -ForegroundColor Yellow
    & $crawlScript
}

$latestPath = Join-Path $root "data\crawled_subsidies_latest.json"
if (-not (Test-Path $latestPath)) { throw "crawled_subsidies_latest.json 없음" }
$latest = Get-Content $latestPath -Raw -Encoding UTF8 | ConvertFrom-Json

$todayStr = (Get-Date).ToString("yyyy-MM-dd")
$currentSnap = @{}

foreach ($entry in @(@{ key="skt"; code="SK"; plan="베스트 109" }, @{ key="kt"; code="KT"; plan="초이스 110" }, @{ key="lgu"; code="LG"; plan="프리미어 105" })) {
    $items = $latest.($entry.key)
    if (-not $items) { continue }
    foreach ($it in $items) {
        if (-not (Test-TargetFlagship $it.model)) { continue }
        $snapKey = "$($entry.code)|$($it.model)"
        $currentSnap[$snapKey] = @{
            carrier = $entry.code
            modelName = $it.model
            modelCode = if ($it.modelCode) { $it.modelCode } else { "" }
            factoryPriceWon = [int64]$it.factoryPrice
            subsidyWon = [int64]$it.subsidy
            planName = $entry.plan
            effDate = if ($it.date) { ($it.date -replace '[^0-9]', '') } else { "" }
        }
    }
}

$prevSnap = @{}
if (Test-Path $snapshotPath) {
    $prevObj = Get-Content $snapshotPath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($p in $prevObj.PSObject.Properties) { $prevSnap[$p.Name] = $p.Value }
}

$newChanges = @()
if ($prevSnap.Count -gt 0) {
    foreach ($k in $currentSnap.Keys) {
        $cur = $currentSnap[$k]
        if (-not $prevSnap.ContainsKey($k)) {
            $newChanges += @{
                id = "${todayStr}_$($cur.carrier)_$($cur.modelName)_new"
                date = $todayStr
                carrier = $cur.carrier
                modelName = $cur.modelName
                modelCode = $cur.modelCode
                changeType = "신규"
                factoryPriceWon = $cur.factoryPriceWon
                planName = $cur.planName
                oldAmountWon = 0
                newAmountWon = $cur.subsidyWon
                scrbType = "신규 출시"
                source = "3사자동크롤링"
            }
            continue
        }
        $prev = $prevSnap[$k]
        if ([int64]$cur.subsidyWon -ne [int64]$prev.subsidyWon) {
            $cType = if ([int64]$cur.subsidyWon -gt [int64]$prev.subsidyWon) { "상승" } else { "하락" }
            $newChanges += @{
                id = "${todayStr}_$($cur.carrier)_$($cur.modelName)_sub_$($cur.subsidyWon)"
                date = $todayStr
                carrier = $cur.carrier
                modelName = $cur.modelName
                modelCode = $cur.modelCode
                changeType = $cType
                factoryPriceWon = $cur.factoryPriceWon
                planName = $cur.planName
                oldAmountWon = [int64]$prev.subsidyWon
                newAmountWon = [int64]$cur.subsidyWon
                scrbType = "공통"
                source = "3사자동크롤링"
            }
        } elseif ([int64]$cur.factoryPriceWon -ne [int64]$prev.factoryPriceWon) {
            $newChanges += @{
                id = "${todayStr}_$($cur.carrier)_$($cur.modelName)_price_$($cur.factoryPriceWon)"
                date = $todayStr
                carrier = $cur.carrier
                modelName = $cur.modelName
                modelCode = $cur.modelCode
                changeType = "출고가변동"
                factoryPriceWon = $cur.factoryPriceWon
                planName = $cur.planName
                oldAmountWon = [int64]$prev.factoryPriceWon
                newAmountWon = [int64]$cur.factoryPriceWon
                scrbType = "출고가"
                source = "3사자동크롤링"
            }
        }
    }
}

# 스냅샷 저장
$currentSnap | ConvertTo-Json -Depth 6 | Set-Content -Path $snapshotPath -Encoding UTF8

# Firestore 기존 변동내역과 병합 후 저장
$existingChanges = @()
try {
    $fsDoc = Invoke-RestMethod -Uri $fsDocUrl -Method Get
    if ($fsDoc.fields.changes) {
        $existingChanges = ConvertFrom-FsVal $fsDoc.fields.changes
    }
} catch {}

$mergedMap = @{}
foreach ($item in ($newChanges + $existingChanges)) {
    if (-not $item -or -not (Test-TargetFlagship $item.modelName)) { continue }
    $id = if ($item.id) { $item.id } else { "$($item.date)_$($item.carrier)_$($item.modelName)_$($item.newAmountWon)" }
    if (-not $mergedMap.ContainsKey($id)) { $mergedMap[$id] = $item }
}
$mergedList = $mergedMap.Values | Sort-Object { $_.date } -Descending | Select-Object -First 120

$patchBody = @{
    fields = @{
        changes = (ConvertTo-FsVal @($mergedList))
        lastSyncedAt = (ConvertTo-FsVal (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz"))
        updatedBy = (ConvertTo-FsVal "3사 크롤링 스크립트")
    }
} | ConvertTo-Json -Depth 20 -Compress

$utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($patchBody)
Invoke-RestMethod -Uri $fsDocUrl -Method Patch -ContentType "application/json; charset=utf-8" -Body $utf8Bytes | Out-Null

Write-Host "✅ 완료! 신규 감지: $($newChanges.Count)건 / 전체 보관: $($mergedList.Count)건" -ForegroundColor Green
