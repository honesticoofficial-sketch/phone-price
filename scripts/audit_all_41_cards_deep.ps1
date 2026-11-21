$ErrorActionPreference = "Stop"

function Parse-CardFile($filePath, $carrierName) {
    $content = Get-Content $filePath -Raw -Encoding UTF8
    $cardMatches = [regex]::Matches($content, '(?s)\{\s*id:\s*"([^"]+)",[\s\S]*?(?=\n  \{|\n\];|\Z)')
    $cards = @()
    foreach ($m in $cardMatches) {
        $block = $m.Value
        $id = if ($block -match 'id:\s*"([^"]+)"') { $matches[1] } else { "" }
        $company = if ($block -match 'cardCompany:\s*"([^"]+)"') { $matches[1] } else { "" }
        $name = if ($block -match 'cardName:\s*"([^"]+)"') { $matches[1] } else { "" }
        $type = if ($block -match 'type:\s*"([^"]+)"') { $matches[1] } else { "" }
        $orientation = if ($block -match 'cardPlateOrientation:\s*"([^"]+)"') { $matches[1] } else { "" }
        $applyUrl = if ($block -match 'applyUrl:\s*"([^"]*)"') { $matches[1] } else { "" }
        $eventUrl = if ($block -match 'eventUrl:\s*"([^"]*)"') { $matches[1] } else { "" }
        $hasPerfInc = $block -match 'performanceIncludes:\s*\['
        $hasPerfExc = $block -match 'performanceExcludes:\s*\['
        
        $tierMatches = [regex]::Matches($block, '(?s)\{\s*label:\s*"([^"]+)",\s*amount:\s*"([^"]+)",\s*amountNum:\s*(\d+)(?:,\s*baseAmount:\s*"([^"]*)")?(?:,\s*promoAmount:\s*"([^"]*)")?[\s\S]*?total24Num:\s*(\d+)[\s\S]*?total36Num:\s*(\d+)')
        $tiers = @()
        foreach ($tm in $tierMatches) {
            $label = $tm.Groups[1].Value
            $amountStr = $tm.Groups[2].Value
            $amountNum = [int]$tm.Groups[3].Value
            $baseAmount = if ($tm.Groups[4].Success) { $tm.Groups[4].Value } else { "" }
            $promoAmount = if ($tm.Groups[5].Success) { $tm.Groups[5].Value } else { "" }
            $total24 = [int]$tm.Groups[6].Value
            $total36 = [int]$tm.Groups[7].Value
            
            $baseNum = 0
            $promoNum = 0
            if ($baseAmount -match '[\d,]+') { $baseNum = [int]($baseAmount -replace '[^\d]', '') }
            if ($promoAmount -match '[\d,]+') { $promoNum = [int]($promoAmount -replace '[^\d]', '') }
            $sumCheck = ($baseNum + $promoNum) -eq $amountNum
            $mult24Check = ($amountNum * 24) -eq $total24
            
            $tiers += [PSCustomObject]@{
                Label = $label
                Amount = $amountNum
                Base = $baseNum
                Promo = $promoNum
                SumCheck = $sumCheck
                Total24 = $total24
                Mult24Check = $mult24Check
                Total36 = $total36
            }
        }
        
        $cards += [PSCustomObject]@{
            Carrier = $carrierName
            Id = $id
            Company = $company
            Name = $name
            Type = $type
            Orientation = $orientation
            ApplyUrl = $applyUrl
            EventUrl = $eventUrl
            HasPerfInc = $hasPerfInc
            HasPerfExc = $hasPerfExc
            TiersCount = $tiers.Count
            Tiers = $tiers
        }
    }
    return $cards
}

$skt = Parse-CardFile "skt_cards_data.js" "SKT"
$kt = Parse-CardFile "kt_cards_data.js" "KT"
$lgu = Parse-CardFile "lgu_cards_data.js" "LGU"

$all = $skt + $kt + $lgu
Write-Host "=================================================================="
Write-Host "총 분석 카드 수: $($all.Count) (SKT: $($skt.Count), KT: $($kt.Count), LGU: $($lgu.Count))"
Write-Host "=================================================================="

Write-Host "`n[1. 실적 인정/제외(performanceIncludes/Excludes) 누락 카드 검사]"
$missingPerf = $all | Where-Object { -not $_.HasPerfInc -or -not $_.HasPerfExc }
Write-Host "누락 카드 수: $($missingPerf.Count)"
foreach ($c in $missingPerf) {
    Write-Host " - [$($c.Carrier)] $($c.Id) ($($c.Company) $($c.Name))"
}

Write-Host "`n[2. 동일 URL 중복 생성 버그 (applyUrl == eventUrl) 검사]"
$dupUrls = $all | Where-Object { $_.EventUrl -and $_.EventUrl.Trim() -ne "" -and $_.EventUrl.Trim() -eq $_.ApplyUrl.Trim() }
Write-Host "중복 URL 카드 수: $($dupUrls.Count)"
foreach ($c in $dupUrls) {
    Write-Host " - [$($c.Carrier)] $($c.Id) : URL $($c.ApplyUrl)"
}

Write-Host "`n[3. 카드사 불일치 eventUrl 의심 건 검사]"
foreach ($c in $all) {
    if (-not $c.EventUrl -or $c.EventUrl.Trim() -eq "") { continue }
    $suspicious = $false
    if ($c.Company -match "KB" -and $c.EventUrl -notmatch "1it3e|kbcard") { $suspicious = $true }
    if ($c.Company -match "삼성" -and $c.EventUrl -notmatch "282hO|282ih|samsungcard") { $suspicious = $true }
    if ($c.Company -match "신한" -and $c.EventUrl -notmatch "shcard|shinhancard") { $suspicious = $true }
    if ($c.Company -match "우리" -and $c.EventUrl -notmatch "1gafU|wooricard") { $suspicious = $true }
    if ($c.Company -match "롯데" -and $c.EventUrl -notmatch "2gcOy|lottecard") { $suspicious = $true }
    if ($c.Company -match "현대" -and $c.EventUrl -notmatch "hyundaicard") { $suspicious = $true }
    if ($c.Company -match "NH|농협" -and $c.EventUrl -match "282hO|shcard|1it3e") { $suspicious = $true }
    
    if ($suspicious) {
        Write-Host " ⚠️ 불일치/의심: [$($c.Carrier)] $($c.Id) ($($c.Company)) -> eventUrl: $($c.EventUrl)"
    }
}

Write-Host "`n[4. 수학적 계산 (기본+프로모션=월할인, 24개월 곱셈) 검사]"
$mathErrors = @()
foreach ($c in $all) {
    foreach ($t in $c.Tiers) {
        if (-not $t.Mult24Check) {
            $mathErrors += "[$($c.Carrier)] $($c.Id) $($t.Label): 월 $($t.Amount) * 24 != $($t.Total24)"
        }
    }
}
Write-Host "24개월 곱셈 오류 수: $($mathErrors.Count)"
foreach ($e in $mathErrors) {
    Write-Host " ❌ $e"
}

Write-Host "`n[5. 카드 플레이트 방향 (Orientation) 검사]"
$noOrient = $all | Where-Object { $_.Orientation -notmatch "horizontal|vertical" }
Write-Host "방향 미지정 카드 수: $($noOrient.Count)"
foreach ($c in $noOrient) {
    Write-Host " ❌ [$($c.Carrier)] $($c.Id)"
}
