$indexPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html"
$content = [System.IO.File]::ReadAllText($indexPath, [System.Text.Encoding]::UTF8)

# Find all cards and their highlightBadge
$pattern = '(?s)\{\s*id:\s*"([^"]+)"[\s\S]*?carrier:\s*"([^"]+)"[\s\S]*?cardName:\s*"([^"]+)"[\s\S]*?highlightBadge:\s*"([^"]*)"'
$matches = [regex]::Matches($content, $pattern)

Write-Host "Found $($matches.Count) cards with highlightBadge in index.html:"
$results = @()
foreach ($m in $matches) {
    $results += [PSCustomObject]@{
        Id = $m.Groups[1].Value
        Carrier = $m.Groups[2].Value
        CardName = $m.Groups[3].Value
        HighlightBadge = $m.Groups[4].Value
    }
}

$results | Format-Table -AutoSize
