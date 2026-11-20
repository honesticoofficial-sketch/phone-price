$indexPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html"
$content = [System.IO.File]::ReadAllText($indexPath, [System.Text.Encoding]::UTF8)

$p1 = $content.IndexOf("const SKT_AFFILIATE_CARDS = [")
Write-Host "Length after p1:" ($content.Length - $p1)
Write-Host $content.Substring($p1, 600)
