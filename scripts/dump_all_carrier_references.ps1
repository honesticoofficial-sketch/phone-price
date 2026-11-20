Add-Type -AssemblyName System.Drawing

$indexPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html"
$content = [System.IO.File]::ReadAllText($indexPath, [System.Text.Encoding]::UTF8)

function Extract-CarrierCards($blockName, $nextBlockName, $destDir) {
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    
    $p1 = $content.IndexOf($blockName)
    $p2 = if ($nextBlockName) { $content.IndexOf($nextBlockName, $p1) } else { $content.IndexOf("</script>", $p1) }
    $block = $content.Substring($p1, $p2 - $p1)
    
    $lines = $block -split "`n"
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
    
    Write-Host "Extracting $($cards.Count) cards for $destDir..."
    foreach ($c in $cards) {
        if ($c.Img -like "data:image/*;base64,*") {
            $b64 = $c.Img -replace "^data:image/[^;]+;base64,", ""
            $bytes = [System.Convert]::FromBase64String($b64)
            $dest = Join-Path $destDir "$($c.Id).png"
            [System.IO.File]::WriteAllBytes($dest, $bytes)
            Write-Host "  Saved: $($c.Id) ($($c.Name)) -> $dest"
        }
    }
}

Extract-CarrierCards "const KT_AFFILIATE_CARDS = [" "const LGU_AFFILIATE_CARDS = [" "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\references\kt"
Extract-CarrierCards "const LGU_AFFILIATE_CARDS = [" "let currentCardCarrier = 'SKT';" "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\references\lgu"

Write-Host "KT and LGU references dumped successfully."
