$c = [System.IO.File]::ReadAllText('C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html', [System.Text.Encoding]::UTF8)
Write-Host "Contains lgu_cards_data.js:" ($c.Contains("lgu_cards_data.js"))
$idx = $c.IndexOf("LGU_AFFILIATE_CARDS")
Write-Host "LGU_AFFILIATE_CARDS index:" $idx
Write-Host $c.Substring($idx, 200)
