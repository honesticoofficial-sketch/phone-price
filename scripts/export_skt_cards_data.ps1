$indexPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html"
$content = [System.IO.File]::ReadAllText($indexPath, [System.Text.Encoding]::UTF8)

$p1 = $content.IndexOf("const SKT_AFFILIATE_CARDS = [")
$endPattern = "];`r`n`r`n`r`n    // 2026년 11월 KT 제휴카드"
$p2 = $content.IndexOf("];", $p1)
# Make sure we find the end of SKT_AFFILIATE_CARDS
$ktIndex = $content.IndexOf("const KT_AFFILIATE_CARDS = [")
$sktEnd = $content.LastIndexOf("];", $ktIndex) + 2

$sktBlock = $content.Substring($p1, $sktEnd - $p1)
Write-Host "Extracted SKT block (Length: $($sktBlock.Length) chars)"

# Save raw block to skt_cards_data.js
$sktDataPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\skt_cards_data.js"
[System.IO.File]::WriteAllText($sktDataPath, $sktBlock + "`n", [System.Text.Encoding]::UTF8)
Write-Host "Created initial skt_cards_data.js"
