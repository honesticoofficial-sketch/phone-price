[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$jsonPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\crawled_subsidies_latest.json"
$data = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json

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

foreach ($carrier in @("skt", "kt", "lgu")) {
    $items = $data.$carrier
    foreach ($it in $items) {
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
                subs = @{ SK = 0; KT = 0; LG = 0 }
            }
        }

        $cUpper = $carrier.ToUpper()
        if ($cUpper -eq "SKT") { $cUpper = "SK" }
        if ($cUpper -eq "KT") { $cUpper = "KT" }
        if ($cUpper -eq "LGU") { $cUpper = "LG" }

        $p = [math]::Round($it.factoryPrice / 10000, 2)
        $s = [math]::Round($it.subsidy / 10000, 2)

        if ($catalog[$norm].prices[$cUpper] -eq 0 -or $p -gt 0) { $catalog[$norm].prices[$cUpper] = $p }
        if ($catalog[$norm].subs[$cUpper] -eq 0 -or $s -gt 0) { $catalog[$norm].subs[$cUpper] = $s }
    }
}

# Fill missing prices or subsidies across carriers if one carrier has it (e.g. standard factory price)
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

# Specific official overrides
if ($catalog.ContainsKey("갤럭시 Z 플립8 256G")) {
    $catalog["갤럭시 Z 플립8 256G"].prices = @{ SK = 168.3; KT = 168.3; LG = 168.3 }
    $catalog["갤럭시 Z 플립8 256G"].subs = @{ SK = 50; KT = 50; LG = 50 }
}
if ($catalog.ContainsKey("갤럭시 Z 폴드8 울트라 256G")) {
    $catalog["갤럭시 Z 폴드8 울트라 256G"].prices = @{ SK = 257.73; KT = 257.73; LG = 257.73 }
    $catalog["갤럭시 Z 폴드8 울트라 256G"].subs = @{ SK = 50; KT = 50; LG = 50 }
}

$catalogList = @()
foreach ($k in ($catalog.Keys | Sort-Object)) {
    $catalogList += $catalog[$k]
}

$catalogJson = $catalogList | ConvertTo-Json -Depth 5
Set-Content "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\crawled_catalog_pool.json" -Value $catalogJson -Encoding UTF8
Write-Host "Generated crawled_catalog_pool.json with $($catalogList.Count) models!"
