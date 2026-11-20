$html = Get-Content "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html" -Raw

function Extract-Cards($varName) {
    Write-Host "=== $varName ==="
    $pattern = "(?s)const $varName = \[(.*?)\n\s*\];"
    if ($html -match $pattern) {
        $block = $matches[1]
        $cards = [regex]::Matches($block, '\{\s*id:\s*"([^"]+)".*?cardCompany:\s*"([^"]+)".*?cardName:\s*"([^"]+)".*?cardPlateImageUrl:\s*"([^"]+)"')
        Write-Host "Found $($cards.Count) cards"
        foreach ($c in $cards) {
            $img = $c.Groups[4].Value
            $imgShort = if ($img.Length -gt 40) { $img.Substring(0, 30) + "... (Len: $($img.Length))" } else { $img }
            Write-Host "  $($c.Groups[1].Value) | $($c.Groups[2].Value) | $($c.Groups[3].Value) | $imgShort"
        }
    }
}

Extract-Cards "KT_AFFILIATE_CARDS"
Extract-Cards "LGU_AFFILIATE_CARDS"
