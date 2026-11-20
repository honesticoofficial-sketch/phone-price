$indexPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html"
$content = [System.IO.File]::ReadAllText($indexPath, [System.Text.Encoding]::UTF8)

# Check all cards in index.html and their cardPlateOrientation
$matches = [regex]::Matches($content, '\{\s*id:\s*"([^"]+)"[\s\S]*?cardName:\s*"([^"]+)"[\s\S]*?cardPlateOrientation:\s*"([^"]+)"')
Write-Host "Found $($matches.Count) cards with cardPlateOrientation in index.html:"
foreach ($m in $matches) {
    Write-Host "  [$($m.Groups[1].Value)] $($m.Groups[2].Value) -> $($m.Groups[3].Value)"
}
