$indexPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html"
$content = [System.IO.File]::ReadAllText($indexPath, [System.Text.Encoding]::UTF8)

$sktDataPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\skt_cards_data.js"
$newSktBlock = [System.IO.File]::ReadAllText($sktDataPath, [System.Text.Encoding]::UTF8).Trim()

$p1 = $content.IndexOf("const SKT_AFFILIATE_CARDS = [")
$ktIndex = $content.IndexOf("const KT_AFFILIATE_CARDS = [")
$sktEnd = $content.LastIndexOf("];", $ktIndex) + 2

Write-Host "Old SKT block from $p1 to $sktEnd (Length: $($sktEnd - $p1))"
Write-Host "New SKT block Length: $($newSktBlock.Length)"

$newContent = $content.Substring(0, $p1) + $newSktBlock + $content.Substring($sktEnd)

[System.IO.File]::WriteAllText($indexPath, $newContent, [System.Text.Encoding]::UTF8)
Write-Host "index.html successfully updated with new SKT block!"
