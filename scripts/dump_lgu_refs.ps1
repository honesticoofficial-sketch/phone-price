$lguFile = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\lgu_cards_data.js"
$content = [System.IO.File]::ReadAllText($lguFile, [System.Text.Encoding]::UTF8)

$lines = $content -split "`n"
$cards = @()
$curr = $null
foreach ($line in $lines) {
    if ($line -match 'id:\s*"([^"]+)"') {
        if ($curr) { $cards += $curr }
        $curr = [PSCustomObject]@{ Id = $matches[1]; Name = ""; Img = "" }
    } elseif ($curr) {
        if ($line -match 'cardName:\s*"([^"]+)"') {
            $curr.Name = $matches[1]
        } elseif ($line -match 'cardPlateImageUrl:\s*"([^"]+)"') {
            $curr.Img = $matches[1]
        }
    }
}
if ($curr) { $cards += $curr }

$lguDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\references\lgu"
if (-not (Test-Path $lguDir)) { New-Item -ItemType Directory -Path $lguDir -Force | Out-Null }

Write-Host "Found $($cards.Count) LGU+ cards in lgu_cards_data.js"
foreach ($c in $cards) {
    if ($c.Img -like "data:image/*;base64,*") {
        $b64 = $c.Img -replace "^data:image/[^;]+;base64,", ""
        $bytes = [System.Convert]::FromBase64String($b64)
        $dest = Join-Path $lguDir "$($c.Id).png"
        [System.IO.File]::WriteAllBytes($dest, $bytes)
        Write-Host "  Saved LGU: $($c.Id) ($($c.Name)) -> $dest"
    }
}
