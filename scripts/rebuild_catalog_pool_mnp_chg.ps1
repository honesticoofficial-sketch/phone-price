[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ==============================================================================
# 통신 3사 기준 요금제 규격:
# - SKT:  109,000원 (베스트 109 / 프라임플러스 109)
# - KT:   120,000원 (5G 프리미엄 120 / 초이스 프리미엄 120)
# - LGU+: 115,000원 (5G 시그니처 115)
# ==============================================================================

$jsonPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\crawled_subsidies_latest.json"
$ktPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\kt_full_items.json"
$data = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$ktData = Get-Content $ktPath -Raw -Encoding UTF8 | ConvertFrom-Json

$catalog = @{}

function Normalize-ModelName($name) {
    $n = $name.Trim()
    $n = $n -replace "\[중고폰\]\s*", "" -replace "중고폰\s*", ""
    $n = $n -replace "\s+SM-[A-Za-z0-9]+", "" -replace "\s+UIP[A-Za-z0-9\-]+", "" -replace "\s+RU-[A-Za-z0-9\-]+", "" -replace "\s+A[0-9]{4}-[0-9]+", ""
    $n = $n -replace "Flip", "플립"
    $n = $n -replace "Fold", "폴드"
    $n = $n -replace "Ultra", "울트라"
    $n = $n -replace "Edge", "엣지"
    $n = $n -replace "GB\b", "G"
    $n = $n -replace "TB\b", "T"
    $n = $n -replace "5G\s*", ""
    $n = ($n -split "\s+") -join " "
    return $n.Trim()
}

function Get-ModelGroup($norm) {
    if ($norm -match "플립|폴드|Flip|Fold") { return "FOLD" }
    if ($norm -match "iPhone|아이폰") { return "IPHONE" }
    if ($norm -match "S2[0-9]|갤럭시 S") { return "S" }
    return "A"
}

function Generate-Tag($norm) {
    if ($norm -match "플립\s*([0-9]+)") { return "#플립$($Matches[1])" }
    if ($norm -match "폴드\s*([0-9]+).*울트라") { return "#폴드$($Matches[1])U" }
    if ($norm -match "폴드\s*([0-9]+)") { return "#폴드$($Matches[1])" }
    if ($norm -match "(iPhone|아이폰)\s*([0-9]+).*Pro\s*Max|(iPhone|아이폰)\s*([0-9]+).*프로맥스") {
        $num = if ($norm -match "[0-9]+") { $Matches[0] } else { "" }
        return "#$num프맥"
    }
    if ($norm -match "(iPhone|아이폰)\s*([0-9]+).*Pro|(iPhone|아이폰)\s*([0-9]+).*프로") {
        $num = if ($norm -match "[0-9]+") { $Matches[0] } else { "" }
        return "#$num프로"
    }
    if ($norm -match "(iPhone|아이폰)\s*Air") { return "#17에어" }
    if ($norm -match "(iPhone|아이폰)\s*([0-9]+)e") {
        $num = if ($norm -match "[0-9]+") { $Matches[0] } else { "" }
        return "#$num`e"
    }
    if ($norm -match "(iPhone|아이폰)\s*([0-9]+)") {
        $num = if ($norm -match "[0-9]+") { $Matches[0] } else { "" }
        return "#아$num"
    }
    if ($norm -match "S([0-9]+).*울트라") { return "#S$($Matches[1])U" }
    if ($norm -match "S([0-9]+).*엣지") { return "#S$($Matches[1])엣지" }
    if ($norm -match "S([0-9]+)\+") { return "#S$($Matches[1])+" }
    if ($norm -match "S([0-9]+).*FE") { return "#S$($Matches[1])FE" }
    if ($norm -match "S([0-9]+)") { return "#S$($Matches[1])" }
    return "#기종"
}

function Generate-Id($norm) {
    $id = $norm.ToLower()
    $id = $id -replace "갤럭시\s*", "" -replace "z\s*", "" -replace "iphone\s*", "ip" -replace "아이폰\s*", "ip"
    $id = $id -replace "플립", "flip" -replace "폴드", "fold" -replace "울트라", "u" -replace "엣지", "e"
    $id = $id -replace "pro\s*max", "pm" -replace "pro", "p" -replace "plus|\+", "p"
    $id = $id -replace "\s+", "" -replace "[^a-z0-9]", ""
    return $id
}

# 1. Base seeding
$sources = @(
    @{ list = $data.skt; carrier = "SK" },
    @{ list = $data.kt; carrier = "KT" },
    @{ list = $ktData; carrier = "KT" },
    @{ list = $data.lgu; carrier = "LG" }
)

foreach ($src in $sources) {
    $c = $src.carrier
    foreach ($it in $src.list) {
        $raw = $it.model.Trim()
        if ($raw -match "중고|A[0-9]|퀀텀|와이드|점프|버디|엑스커버|스타일러스|ZTE|레드미|폴더|키즈폰") { continue }
        
        $norm = Normalize-ModelName $raw
        $group = Get-ModelGroup $norm
        if ($group -eq "A") { continue }

        if (-not $catalog.ContainsKey($norm)) {
            $catalog[$norm] = @{
                id = Generate-Id $norm
                name = $norm
                group = $group
                tag = Generate-Tag $norm
                prices = @{ SK = 0; KT = 0; LG = 0 }
                subs = @{
                    SK = @{ mnp = 0; chg = 0; new = 0 }
                    KT = @{ mnp = 0; chg = 0; new = 0 }
                    LG = @{ mnp = 0; chg = 0; new = 0 }
                }
            }
        }

        $p = [math]::Round($it.factoryPrice / 10000, 2)
        $s = [math]::Round($it.subsidy / 10000, 2)

        if ($catalog[$norm].prices[$c] -eq 0 -or $p -gt 0) { $catalog[$norm].prices[$c] = $p }
        
        $scrb = $it.scrbType
        if ($scrb -eq "번호이동") {
            if ($s -gt 0) { $catalog[$norm].subs[$c].mnp = $s }
        } elseif ($scrb -eq "기기변경") {
            if ($s -gt 0) { $catalog[$norm].subs[$c].chg = $s }
        } elseif ($scrb -eq "신규가입") {
            if ($s -gt 0) { $catalog[$norm].subs[$c].new = $s }
        } else {
            if ($s -gt 0) {
                if ($catalog[$norm].subs[$c].mnp -eq 0) { $catalog[$norm].subs[$c].mnp = $s }
                if ($catalog[$norm].subs[$c].chg -eq 0) { $catalog[$norm].subs[$c].chg = $s }
                if ($catalog[$norm].subs[$c].new -eq 0) { $catalog[$norm].subs[$c].new = $s }
            }
        }
    }
}

# 2. Fill missing factory prices across carriers
foreach ($k in $catalog.Keys) {
    $entry = $catalog[$k]
    $knownPrice = 0
    foreach ($c in @("SK", "KT", "LG")) {
        if ($entry.prices[$c] -gt 0) { $knownPrice = $entry.prices[$c]; break }
    }
    foreach ($c in @("SK", "KT", "LG")) {
        if ($entry.prices[$c] -eq 0 -and $knownPrice -gt 0) { $entry.prices[$c] = $knownPrice }
    }
}

# 3. Apply Verified Truth under Standard Plans (SK 109k / KT 120k / LG 115k)
foreach ($k in $catalog.Keys) {
    $entry = $catalog[$k]
    $name = $entry.name

    # --- iPhone 18 Series (under SK 109k, KT 120k, LG 115k 최고 요금제 기준) ---
    if ($name -match "iPhone 18 Pro Max") {
        # SK: 22만, KT 120k: 22만, LG 115k: 22만
        $entry.subs.SK = @{ mnp = 22; chg = 22; new = 22 }
        $entry.subs.KT = @{ mnp = 22; chg = 22; new = 22 }
        $entry.subs.LG = @{ mnp = 22; chg = 22; new = 22 }
    } elseif ($name -match "iPhone 18 Pro") {
        # SK: 45만, KT 120k: 45만, LG 115k: 45만 (최고 요금제 기준 통신 3사 45만 통일)
        $entry.subs.SK = @{ mnp = 45; chg = 45; new = 45 }
        $entry.subs.KT = @{ mnp = 45; chg = 45; new = 45 }
        $entry.subs.LG = @{ mnp = 45; chg = 45; new = 45 }
    } elseif ($name -match "iPhone Duo") {
        $entry.subs.SK = @{ mnp = 45; chg = 45; new = 45 }
        $entry.subs.KT = @{ mnp = 45; chg = 45; new = 45 }
        $entry.subs.LG = @{ mnp = 45; chg = 45; new = 45 }
    } elseif ($name -match "iPhone Air") {
        # SK: 65만, KT: 70만, LG: 45만
        $entry.subs.SK = @{ mnp = 65; chg = 65; new = 65 }
        $entry.subs.KT = @{ mnp = 70; chg = 70; new = 70 }
        $entry.subs.LG = @{ mnp = 45; chg = 45; new = 45 }
    } elseif ($name -match "iPhone 17 Pro Max") {
        $entry.subs.SK = @{ mnp = 22; chg = 22; new = 22 }
        $entry.subs.KT = @{ mnp = 22; chg = 22; new = 22 }
        $entry.subs.LG = @{ mnp = 22; chg = 22; new = 22 }
    } elseif ($name -match "iPhone 17 Pro") {
        $entry.subs.SK = @{ mnp = 45; chg = 45; new = 45 }
        $entry.subs.KT = @{ mnp = 45; chg = 45; new = 45 }
        $entry.subs.LG = @{ mnp = 45; chg = 45; new = 45 }
    } elseif ($name -match "iPhone 17e") {
        $entry.subs.SK = @{ mnp = 12.8; chg = 12.8; new = 12.8 }
        $entry.subs.KT = @{ mnp = 45; chg = 45; new = 45 }
        $entry.subs.LG = @{ mnp = 45; chg = 45; new = 45 }
    } elseif ($name -match "iPhone 17") {
        # [대표님 확정 데이터]: LG 번호이동 55만, 기기변경 45만!
        $entry.subs.SK = @{ mnp = 45; chg = 45; new = 45 }
        $entry.subs.KT = @{ mnp = 45; chg = 45; new = 45 }
        $entry.subs.LG = @{ mnp = 55; chg = 45; new = 55 }
    } elseif ($name -match "iPhone 16 Pro Max") {
        $entry.subs.SK = @{ mnp = 22; chg = 22; new = 22 }
        $entry.subs.KT = @{ mnp = 22; chg = 22; new = 22 }
        $entry.subs.LG = @{ mnp = 45; chg = 45; new = 45 }
    } elseif ($name -match "iPhone 16 Pro") {
        $entry.subs.SK = @{ mnp = 22; chg = 22; new = 22 }
        $entry.subs.KT = @{ mnp = 22; chg = 22; new = 22 }
        $entry.subs.LG = @{ mnp = 45; chg = 45; new = 45 }
    } elseif ($name -match "iPhone 16e") {
        $entry.subs.SK = @{ mnp = 22; chg = 22; new = 22 }
        $entry.subs.KT = @{ mnp = 22; chg = 22; new = 22 }
        $entry.subs.LG = @{ mnp = 22; chg = 22; new = 22 }
    } elseif ($name -match "iPhone 16") {
        $entry.subs.SK = @{ mnp = 22; chg = 22; new = 22 }
        $entry.subs.KT = @{ mnp = 22; chg = 22; new = 22 }
        $entry.subs.LG = @{ mnp = 45; chg = 45; new = 45 }
    } elseif ($name -match "iPhone 15 Pro") {
        $entry.subs.SK = @{ mnp = 65; chg = 65; new = 65 }
        $entry.subs.KT = @{ mnp = 50; chg = 50; new = 50 }
        $entry.subs.LG = @{ mnp = 45; chg = 45; new = 45 }
    } elseif ($name -match "iPhone 15 Plus") {
        $entry.subs.SK = @{ mnp = 47; chg = 47; new = 47 }
        $entry.subs.KT = @{ mnp = 47; chg = 47; new = 47 }
        $entry.subs.LG = @{ mnp = 45; chg = 45; new = 45 }
    } elseif ($name -match "iPhone 15") {
        $entry.subs.SK = @{ mnp = 65; chg = 65; new = 65 }
        $entry.subs.KT = @{ mnp = 50; chg = 50; new = 50 }
        $entry.subs.LG = @{ mnp = 45; chg = 45; new = 45 }
    }

    # --- Galaxy S Series ---
    if ($name -match "S26 Ultra|S26\+|S26") {
        if ($entry.subs.SK.mnp -eq 0) { $entry.subs.SK = @{ mnp = 60; chg = 60; new = 60 } }
        if ($entry.subs.KT.mnp -eq 0) { $entry.subs.KT = @{ mnp = 60; chg = 60; new = 60 } }
        if ($entry.subs.LG.mnp -eq 0) { $entry.subs.LG = @{ mnp = 60; chg = 60; new = 60 } }
    } elseif ($name -match "S25 엣지") {
        $entry.subs.SK = @{ mnp = 58; chg = 58; new = 58 }
        $entry.subs.KT = @{ mnp = 60; chg = 60; new = 60 }
        $entry.subs.LG = @{ mnp = 60; chg = 60; new = 60 }
    } elseif ($name -match "S25 Ultra|S25\+|S25") {
        if ($entry.subs.SK.mnp -eq 0) { $entry.subs.SK = @{ mnp = 50; chg = 50; new = 50 } }
        if ($entry.subs.KT.mnp -eq 0) { $entry.subs.KT = @{ mnp = 50; chg = 50; new = 50 } }
        if ($entry.subs.LG.mnp -eq 0) { $entry.subs.LG = @{ mnp = 50; chg = 50; new = 50 } }
    } elseif ($name -match "S24 Ultra|S24\+|S24") {
        $entry.subs.SK = @{ mnp = 63; chg = 55; new = 63 }
        $entry.subs.KT = @{ mnp = 55; chg = 50; new = 55 }
        $entry.subs.LG = @{ mnp = 50; chg = 50; new = 50 }
    } elseif ($name -match "S25 FE|S26 FE") {
        $entry.subs.SK = @{ mnp = 50; chg = 50; new = 50 }
        $entry.subs.KT = @{ mnp = 50; chg = 50; new = 50 }
        $entry.subs.LG = @{ mnp = 50; chg = 50; new = 50 }
    }

    # --- Galaxy Foldable Series ---
    if ($name -match "플립8") {
        $entry.prices = @{ SK = 168.3; KT = 168.3; LG = 168.3 }
        $entry.subs.SK = @{ mnp = 50; chg = 50; new = 50 }
        $entry.subs.KT = @{ mnp = 50; chg = 50; new = 50 }
        $entry.subs.LG = @{ mnp = 50; chg = 50; new = 50 }
    } elseif ($name -match "폴드8 울트라") {
        $entry.prices = @{ SK = 257.73; KT = 257.73; LG = 257.73 }
        $entry.subs.SK = @{ mnp = 50; chg = 50; new = 50 }
        $entry.subs.KT = @{ mnp = 50; chg = 50; new = 50 }
        $entry.subs.LG = @{ mnp = 50; chg = 50; new = 50 }
    } elseif ($name -match "폴드8") {
        if ($entry.subs.SK.mnp -eq 0) { $entry.subs.SK = @{ mnp = 60; chg = 60; new = 60 } }
        if ($entry.subs.KT.mnp -eq 0) { $entry.subs.KT = @{ mnp = 60; chg = 60; new = 60 } }
        if ($entry.subs.LG.mnp -eq 0) { $entry.subs.LG = @{ mnp = 60; chg = 60; new = 60 } }
    } elseif ($name -match "플립7 FE") {
        $entry.subs.SK = @{ mnp = 50; chg = 50; new = 50 }
        $entry.subs.KT = @{ mnp = 50; chg = 50; new = 50 }
        $entry.subs.LG = @{ mnp = 50; chg = 50; new = 50 }
    } elseif ($name -match "플립7") {
        if ($entry.subs.SK.mnp -eq 0) { $entry.subs.SK = @{ mnp = 50; chg = 50; new = 50 } }
        if ($entry.subs.KT.mnp -eq 0) { $entry.subs.KT = @{ mnp = 50; chg = 50; new = 50 } }
        if ($entry.subs.LG.mnp -eq 0) { $entry.subs.LG = @{ mnp = 50; chg = 50; new = 50 } }
    } elseif ($name -match "폴드7") {
        if ($entry.subs.SK.mnp -eq 0) { $entry.subs.SK = @{ mnp = 50; chg = 50; new = 50 } }
        if ($entry.subs.KT.mnp -eq 0) { $entry.subs.KT = @{ mnp = 50; chg = 50; new = 50 } }
        if ($entry.subs.LG.mnp -eq 0) { $entry.subs.LG = @{ mnp = 50; chg = 50; new = 50 } }
    } elseif ($name -match "플립6") {
        $entry.subs.SK = @{ mnp = 60; chg = 60; new = 60 }
        $entry.subs.KT = @{ mnp = 50; chg = 50; new = 50 }
        $entry.subs.LG = @{ mnp = 50; chg = 50; new = 50 }
    }
}

$catalogList = @()
foreach ($k in ($catalog.Keys | Sort-Object)) {
    $catalogList += $catalog[$k]
}

$catalogJson = $catalogList | ConvertTo-Json -Depth 5
$outPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\crawled_catalog_pool.json"
[System.IO.File]::WriteAllText($outPath, $catalogJson, [System.Text.Encoding]::UTF8)

Write-Host "✅ Rebuilt crawled_catalog_pool.json with $($catalogList.Count) models under SK 109k, KT 120k, LG 115k!"
