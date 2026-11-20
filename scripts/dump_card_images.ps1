# scripts/dump_card_images.ps1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

$workspace = "C:\Users\User01\.gemini\antigravity\scratch\phone-price"
$indexHtml = Get-Content (Join-Path $workspace "index.html") -Encoding UTF8
$outDir = Join-Path $workspace "scratch\card_images"

# Card extractor from lines
$cards = @()
$current = $null

for ($i = 7115; $i -lt 9050; $i++) {
    $line = $indexHtml[$i]
    if ($line -match '^\s*\{\s*$') {
        if ($current -and $current.cardName) {
            $cards += $current
        }
        $current = @{
            carrier = ""
            cardCompany = ""
            cardName = ""
            id = ""
            img = ""
        }
    }
    if ($current) {
        if ($line -match 'id:\s*["''](.*?)["'']') { $current.id = $matches[1] }
        if ($line -match 'carrier:\s*["''](.*?)["'']') { $current.carrier = $matches[1] }
        if ($line -match 'cardCompany:\s*["''](.*?)["'']') { $current.cardCompany = $matches[1] }
        if ($line -match 'cardName:\s*["''](.*?)["'']') { $current.cardName = $matches[1] }
        if ($line -match 'cardPlateImageUrl:\s*["''](.*?)["'']') { $current.img = $matches[1] }
    }
}
if ($current -and $current.cardName) {
    $cards += $current
}

Write-Host "총 카드 수: $($cards.Count)"

$sha = [System.Security.Cryptography.SHA256]::Create()
$hashGroups = @{}

$results = @()

foreach ($c in $cards) {
    $safeName = "$($c.carrier)_$($c.cardCompany)_$($c.cardName)" -replace '[^a-zA-Z0-9가-힣_-]', '_'
    $imgPath = Join-Path $outDir "$safeName.png"
    
    $isBase64 = $c.img.StartsWith("data:image")
    $hashStr = ""
    $len = $c.img.Length

    if ($isBase64) {
        $base64Data = $c.img -replace '^data:image\/\w+;base64,', ''
        $bytes = [System.Convert]::FromBase64String($base64Data)
        [System.IO.File]::WriteAllBytes($imgPath, $bytes)
        $hashBytes = $sha.ComputeHash($bytes)
        $hashStr = [System.BitConverter]::ToString($hashBytes) -replace '-', ''
    } elseif ($c.img.Length -gt 0) {
        $hashStr = "URL: $($c.img)"
    } else {
        $hashStr = "EMPTY"
    }

    if (-not $hashGroups.ContainsKey($hashStr)) {
        $hashGroups[$hashStr] = @()
    }
    $hashGroups[$hashStr] += "$($c.carrier) | $($c.cardCompany) | $($c.cardName)"

    $results += [PSCustomObject]@{
        Carrier = $c.carrier
        Company = $c.cardCompany
        CardName = $c.cardName
        Id = $c.id
        ImgLen = $len
        Hash = if ($hashStr.Length -gt 16) { $hashStr.Substring(0, 16) } else { $hashStr }
    }
}

Write-Host "`n=================== 카드별 이미지 현황 ==================="
$results | Format-Table -AutoSize

Write-Host "`n=================== 동일 이미지 중복 사용 그룹 ==================="
foreach ($h in $hashGroups.Keys) {
    $group = $hashGroups[$h]
    if ($group.Count -gt 1) {
        Write-Host "`n[중복 해시: $(if ($h.Length -gt 16) { $h.Substring(0, 16) } else { $h })] - $($group.Count)개 카드가 동일 이미지 공유 중!"
        foreach ($item in $group) {
            Write-Host "   * $item"
        }
    }
}
