$html = Get-Content "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html" -Raw

# Find KT cards range
$ktStart = $html.IndexOf('id: "kt_kb_light_plus"')
$lguStart = $html.IndexOf('id: "lgu_shinhan_smartplan"')

$ktSection = $html.Substring($ktStart, $lguStart - $ktStart)

# Match cards in KT section
$cardBlocks = [regex]::Matches($ktSection, '(?s)id:\s*"([^"]+)",.*?cardName:\s*"([^"]+)",.*?highlightBadge:\s*"([^"]+)",.*?promotions:\s*(\[.*?\]),\s*basicBenefits')

foreach ($m in $cardBlocks) {
    $cid = $m.Groups[1].Value
    $cname = $m.Groups[2].Value
    $badge = $m.Groups[3].Value
    $promos = $m.Groups[4].Value
    
    Write-Host "===================================="
    Write-Host "KT: $cid ($cname)"
    Write-Host "Badge: $badge"
    Write-Host "Promotions snippet: $($promos.Substring(0, [Math]::Min(200, $promos.Length))) ... Length=$($promos.Length)"
}
