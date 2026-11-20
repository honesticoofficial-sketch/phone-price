# scripts/apply_correct_card_images.ps1
$ErrorActionPreference = "Stop"

Write-Host "=== LGU+/KT 카드 이미지 및 명칭 전면 교정 시작 ==="

# 1. Base64 맵 준비
$imgFiles = @{
    "lgu_nh_allone"   = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\test_download_lgu\NH_LGU_Allone.png"
    "lgu_lotte_loca"  = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\toss_lgu_imgs\lgu_loca.png"
    "lgu_lotte_light" = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\toss_lgu_imgs\lgu_loca.png"
    "lgu_lotte_dc"    = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\test_download_lgu\LO_LGU_DC_opt.png"
    "lgu_woori_36"    = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\toss_lgu_imgs\woori_u_x.png"
    "lgu_hyundai_m3"  = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\toss_lgu_imgs\lgu_hyundai_m3.png"
    "lgu_hana_family" = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\toss_lgu_imgs\uplus_family_hana.png"
}

$orientationMap = @{
    "lgu_nh_allone"   = "horizontal"
    "lgu_lotte_loca"  = "horizontal"
    "lgu_lotte_light" = "horizontal"
    "lgu_lotte_dc"    = "vertical"
    "lgu_woori_36"    = "vertical"
    "lgu_hyundai_m3"  = "vertical"
    "lgu_hana_family" = "horizontal"
}

$base64Map = @{}
foreach ($cardId in $imgFiles.Keys) {
    $filePath = $imgFiles[$cardId]
    $bytes = [System.IO.File]::ReadAllBytes($filePath)
    $b64 = "data:image/png;base64," + [Convert]::ToBase64String($bytes)
    $base64Map[$cardId] = $b64
    Write-Host "Loaded Base64 for $cardId ($($bytes.Length) bytes, $($b64.Length) chars)"
}

# 2. index.html 수정
$indexPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html"
$indexLines = [System.IO.File]::ReadAllLines($indexPath, [System.Text.Encoding]::UTF8)
$newIndexLines = [System.Collections.Generic.List[string]]::new()

$currentCardId = ""
$inLguGroup = $false
$inKtGroup = $false

for ($i = 0; $i -lt $indexLines.Length; $i++) {
    $line = $indexLines[$i]

    if ($line -match 'const LGU_AFFILIATE_CARDS') {
        $inLguGroup = $true
        $inKtGroup = $false
    } elseif ($line -match 'const KT_AFFILIATE_CARDS') {
        $inKtGroup = $true
        $inLguGroup = $false
    } elseif ($line -match 'const [A-Z_]+ = \[') {
        $inLguGroup = $false
        $inKtGroup = $false
    }

    if ($line -match 'id:\s*"([^"]+)"') {
        $currentCardId = $matches[1]
    }

    # KT 신한카드 이름 정정
    if ($inKtGroup -and $currentCardId -eq "kt_shinhan_family_light" -and $line -match 'cardName:\s*"KT 신한카드 T라이트"') {
        $line = $line -replace '"KT 신한카드 T라이트"', '"KT 가족만족 신한카드 (라이트할부)"'
        Write-Host "Fixed KT Card Name: KT 신한카드 T라이트 -> KT 가족만족 신한카드 (라이트할부)"
    }

    # LGU 카드 이미지 및 Orientation 교체
    if ($inLguGroup -and $base64Map.ContainsKey($currentCardId)) {
        if ($line -match 'cardPlateImageUrl:\s*"(?:[^"]*)"') {
            $newB64 = $base64Map[$currentCardId]
            $line = "    cardPlateImageUrl: ""$newB64"","
            Write-Host "Replaced Image for $currentCardId in index.html"
        }
        if ($line -match 'cardPlateOrientation:\s*"(?:[^"]*)"') {
            $ori = $orientationMap[$currentCardId]
            $line = "    cardPlateOrientation: ""$ori"","
            Write-Host "Set Orientation $ori for $currentCardId in index.html"
        }
    }

    $newIndexLines.Add($line)
}

[System.IO.File]::WriteAllLines($indexPath, $newIndexLines, [System.Text.Encoding]::UTF8)
Write-Host "Successfully updated index.html!"

# 3. lgu_cards_data.js 수정
$lguJsPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\lgu_cards_data.js"
if (Test-Path $lguJsPath) {
    $lguJsLines = [System.IO.File]::ReadAllLines($lguJsPath, [System.Text.Encoding]::UTF8)
    $newLguJsLines = [System.Collections.Generic.List[string]]::new()
    $curId = ""

    foreach ($line in $lguJsLines) {
        if ($line -match 'id:\s*"([^"]+)"') {
            $curId = $matches[1]
        }
        if ($base64Map.ContainsKey($curId)) {
            if ($line -match 'cardPlateImageUrl:\s*"(?:[^"]*)"') {
                $newB64 = $base64Map[$curId]
                $line = "    cardPlateImageUrl: ""$newB64"","
            }
            if ($line -match 'cardPlateOrientation:\s*"(?:[^"]*)"') {
                $ori = $orientationMap[$curId]
                $line = "    cardPlateOrientation: ""$ori"","
            }
        }
        $newLguJsLines.Add($line)
    }
    [System.IO.File]::WriteAllLines($lguJsPath, $newLguJsLines, [System.Text.Encoding]::UTF8)
    Write-Host "Successfully updated lgu_cards_data.js!"
}

# 4. data/ground_truth_lgu_202611.json 수정
$lguGtPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\ground_truth_lgu_202611.json"
if (Test-Path $lguGtPath) {
    $gtJson = Get-Content $lguGtPath -Raw | ConvertFrom-Json
    foreach ($c in $gtJson) {
        # 매칭: 회사 및 카드명
        if ($c.card_company -eq "NH농협카드" -or $c.card_name -like "*올원*") {
            $c.card_plate_image = $base64Map["lgu_nh_allone"]
        } elseif ($c.card_name -like "*U+ x LOCA 라이트할부*") {
            $c.card_plate_image = $base64Map["lgu_lotte_light"]
        } elseif ($c.card_name -like "*U+ DC 롯데카드*") {
            $c.card_plate_image = $base64Map["lgu_lotte_dc"]
        } elseif ($c.card_name -like "*LG U+ x LOCA*") {
            $c.card_plate_image = $base64Map["lgu_lotte_loca"]
        } elseif ($c.card_company -eq "우리카드" -or $c.card_name -like "*36우리카드*") {
            $c.card_plate_image = $base64Map["lgu_woori_36"]
        } elseif ($c.card_company -eq "현대카드" -or $c.card_name -like "*M Edition 3*") {
            $c.card_plate_image = $base64Map["lgu_hyundai_m3"]
        } elseif ($c.card_company -eq "하나카드" -or $c.card_name -like "*family*") {
            $c.card_plate_image = $base64Map["lgu_hana_family"]
        }
    }
    $gtJson | ConvertTo-Json -Depth 10 | Set-Content $lguGtPath -Encoding UTF8
    Write-Host "Successfully updated ground_truth_lgu_202611.json!"
}

# 5. data/ground_truth_kt_202611.json 수정
$ktGtPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\ground_truth_kt_202611.json"
if (Test-Path $ktGtPath) {
    $ktGtJson = Get-Content $ktGtPath -Raw | ConvertFrom-Json
    foreach ($c in $ktGtJson) {
        if ($c.card_name -eq "KT 신한카드 T라이트") {
            $c.card_name = "KT 가족만족 신한카드 (라이트할부)"
            Write-Host "Fixed KT ground truth card_name: KT 가족만족 신한카드 (라이트할부)"
        }
    }
    $ktGtJson | ConvertTo-Json -Depth 10 | Set-Content $ktGtPath -Encoding UTF8
    Write-Host "Successfully updated ground_truth_kt_202611.json!"
}

Write-Host "=== 모든 데이터 교정 완료! ==="
