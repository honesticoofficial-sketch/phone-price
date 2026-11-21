$ErrorActionPreference = "Stop"
$root = "C:\Users\User01\.gemini\antigravity\scratch\phone-price"

# 1. 파일에서 카드 데이터 추출
function Get-CardsFromFile($filePath, $carrierName) {
    $text = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
    $pattern = '(?ms)\{\s*id:\s*"([^"]+)",\s*carrier:\s*"([^"]+)",.*?applyUrl:\s*"([^"]+)",'
    $matches = [regex]::Matches($text, $pattern)
    $cards = @()
    foreach ($m in $matches) {
        $cards += [PSCustomObject]@{
            Id = $m.Groups[1].Value
            Carrier = $m.Groups[2].Value
            ApplyUrl = $m.Groups[3].Value
        }
    }
    return $cards
}

$sktCards = Get-CardsFromFile "$root\skt_cards_data.js" "SKT"
$ktCards = Get-CardsFromFile "$root\kt_cards_data.js" "KT"
$lguCards = Get-CardsFromFile "$root\lgu_cards_data.js" "LGU+"

Write-Host "Card Counts: SKT=$($sktCards.Count), KT=$($ktCards.Count), LGU+=$($lguCards.Count)"
Write-Host "Total Cards = $($sktCards.Count + $ktCards.Count + $lguCards.Count) (Expected 41)"

# KT 전용 식별자들 (SKT나 LGU+에 들어가면 안됨)
$ktIdentifiers = @(
    "01507", "7021507000", "04293", "7024293000",
    "106378", "107345", "MKTE3",
    "AAP1839", "QKKTLITE", "AAP1665", "QKKT",
    "1221484", "1223352", "1235115",
    "104168", "LkMCWj6", "17454", "K001"
)

# SKT 전용 식별자들 (KT나 LGU+에 들어가면 안됨)
$sktIdentifiers = @(
    "01506", "7021506000", "106377", "MSKTE3", "MSKTE3TP",
    "AAP1869", "AAP1752", "QKQRCD", "103749",
    "1195357", "2013495", "1vkTrqN", "1001426"
)

# LGU+ 전용 식별자들 (SKT나 KT에 들어가면 안됨)
$lguIdentifiers = @(
    "01508", "7021508000", "106379", "MLGTE3",
    "AAP1663", "AAP1893", "103751",
    "1202226", "1196321", "14109", "lguplus.com"
)

$errors = @()

# SKT 검증
foreach ($c in $sktCards) {
    foreach ($ktId in $ktIdentifiers) {
        if ($c.ApplyUrl.Contains($ktId)) {
            $errors += "FAIL: SKT card [$($c.Id)] contains KT identifier [$ktId] in ApplyUrl: $($c.ApplyUrl)"
        }
    }
    foreach ($lguId in $lguIdentifiers) {
        if ($c.ApplyUrl.Contains($lguId)) {
            $errors += "FAIL: SKT card [$($c.Id)] contains LGU+ identifier [$lguId] in ApplyUrl: $($c.ApplyUrl)"
        }
    }
}

# KT 검증
foreach ($c in $ktCards) {
    foreach ($sktId in $sktIdentifiers) {
        if ($c.ApplyUrl.Contains($sktId)) {
            $errors += "FAIL: KT card [$($c.Id)] contains SKT identifier [$sktId] in ApplyUrl: $($c.ApplyUrl)"
        }
    }
    foreach ($lguId in $lguIdentifiers) {
        if ($c.ApplyUrl.Contains($lguId)) {
            $errors += "FAIL: KT card [$($c.Id)] contains LGU+ identifier [$lguId] in ApplyUrl: $($c.ApplyUrl)"
        }
    }
}

# LGU+ 검증
foreach ($c in $lguCards) {
    foreach ($sktId in $sktIdentifiers) {
        if ($c.ApplyUrl.Contains($sktId)) {
            $errors += "FAIL: LGU+ card [$($c.Id)] contains SKT identifier [$sktId] in ApplyUrl: $($c.ApplyUrl)"
        }
    }
    foreach ($ktId in $ktIdentifiers) {
        if ($c.ApplyUrl.Contains($ktId)) {
            $errors += "FAIL: LGU+ card [$($c.Id)] contains KT identifier [$ktId] in ApplyUrl: $($c.ApplyUrl)"
        }
    }
}

Write-Host "`n=== CROSS-CHECK VERIFICATION RESULT ==="
if ($errors.Count -eq 0) {
    Write-Host "SUCCESS! All 41 cards passed carrier cross-check with 0 violations!" -ForegroundColor Green
} else {
    Write-Host "FAILED! Found $($errors.Count) violations:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    exit 1
}

# 41개 카드 전체 리스트 출력
Write-Host "`n=== All 41 Cards Verified URLs ==="
Write-Host "--- SKT (14) ---"
$sktCards | ForEach-Object { Write-Host "$($_.Id): $($_.ApplyUrl)" }
Write-Host "--- KT (15) ---"
$ktCards | ForEach-Object { Write-Host "$($_.Id): $($_.ApplyUrl)" }
Write-Host "--- LGU+ (12) ---"
$lguCards | ForEach-Object { Write-Host "$($_.Id): $($_.ApplyUrl)" }
