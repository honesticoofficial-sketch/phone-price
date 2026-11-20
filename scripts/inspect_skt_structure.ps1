$indexPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html"
$content = [System.IO.File]::ReadAllText($indexPath, [System.Text.Encoding]::UTF8)

$p1 = $content.IndexOf("const SKT_AFFILIATE_CARDS = [")
$p2 = $content.IndexOf("const KT_AFFILIATE_CARDS = [")
Write-Host "SKT block start: $p1, end: $p2 (Length: $($p2 - $p1))"
Write-Host "First 300 chars:"
Write-Host $content.Substring($p1, 300)
Write-Host "`nLast 300 chars:"
Write-Host $content.Substring($p2 - 300, 300)
