$skt = Get-Content 'C:\Users\User01\.gemini\antigravity\scratch\phone-price\skt_cards_data.js' -Raw
$matches = [regex]::Matches($skt, 'id:\s*"([^"]+)"[\s\S]*?cardName:\s*"([^"]+)"[\s\S]*?applyUrl:\s*"([^"]+)"')
foreach ($m in $matches) {
    $block = $m.Value
    $eventUrl = ""
    if ($block -match 'eventUrl:\s*"([^"]*)"') {
        $eventUrl = $matches[1]
    }
    Write-Host "$($m.Groups[1].Value) | $($m.Groups[2].Value) | Apply: $($m.Groups[3].Value) | Event: $eventUrl"
}
