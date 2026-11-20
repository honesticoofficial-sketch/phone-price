$html = Get-Content "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html" -Raw

function Extract-Cards($varName) {
    $pattern = "(?s)const $varName = \[(.*?)\n    \];"
    if ($html -match $pattern) {
        $block = $matches[1]
        Write-Host "=== $varName ==="
        $cardMatches = [regex]::Matches($block, "(?s)\{\s*id:\s*""([^""]+)"".*?name:\s*""([^""]+)"".*?company:\s*""([^""]+)""(.*?)cardPlateOrientation:\s*""([^""]+)""")
        Write-Host "Found $($cardMatches.Count) cards"
        foreach ($m in $cardMatches) {
            Write-Host "  ID: $($m.Groups[1].Value) | $($m.Groups[3].Value) | $($m.Groups[2].Value) | Ori: $($m.Groups[5].Value)"
        }
    } else {
        Write-Host "Could not find $varName"
    }
}

Extract-Cards "SKT_AFFILIATE_CARDS"
Extract-Cards "KT_AFFILIATE_CARDS"
Extract-Cards "LGU_AFFILIATE_CARDS"
