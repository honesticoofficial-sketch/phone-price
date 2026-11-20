# scripts/inspect_old_carrier_files.ps1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

$workspace = "C:\Users\User01\.gemini\antigravity\scratch\phone-price"

function Extract-FileCards($fileName) {
    Write-Host "`n=================== $fileName ==================="
    $filePath = Join-Path $workspace $fileName
    if (-not (Test-Path $filePath)) {
        Write-Host "파일 없음: $filePath"
        return
    }
    $lines = Get-Content $filePath -Encoding UTF8
    $cards = @()
    $cur = $null
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^\s*\{\s*$') {
            if ($cur -and $cur.cardName) { $cards += $cur }
            $cur = @{ id = ""; cardCompany = ""; cardName = ""; imgLen = 0; isBase64 = $false }
        }
        if ($cur) {
            if ($line -match 'id:\s*["''](.*?)["'']') { $cur.id = $matches[1] }
            if ($line -match 'cardCompany:\s*["''](.*?)["'']') { $cur.cardCompany = $matches[1] }
            if ($line -match 'cardName:\s*["''](.*?)["'']') { $cur.cardName = $matches[1] }
            if ($line -match 'cardPlateImageUrl:\s*["''](.*?)["'']') {
                $cur.imgLen = $matches[1].Length
                $cur.isBase64 = $matches[1].StartsWith("data:image")
            }
        }
    }
    if ($cur -and $cur.cardName) { $cards += $cur }
    Write-Host "총 $($cards.Count)개 카드 발견:"
    foreach ($c in $cards) {
        Write-Host "   ID: $($c.id) | $($c.cardCompany) | $($c.cardName) | ImgLen: $($c.imgLen)"
    }
}

Extract-FileCards "lgu_cards_data.js"
Extract-FileCards "kt_cards_data.js"
