$c = [System.IO.File]::ReadAllText('C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html', [System.Text.Encoding]::UTF8)

# Find where card plate is rendered in DOM
$matches = [regex]::Matches($c, '(?s)<div[^>]*class="[^"]*card-plate[^"]*"[^>]*>.*?</div>')
Write-Host "Found card-plate divs: $($matches.Count)"

# Also search for cardPlateImageUrl in render functions
$renderMatch = [regex]::Matches($c, '(?s)function renderAffiliateCard[^{]*\{.*?^\}')
Write-Host "Found renderAffiliateCard functions: $($renderMatch.Count)"

# Search for cardPlateOrientation usage
$orientMatches = [regex]::Matches($c, 'cardPlateOrientation')
Write-Host "cardPlateOrientation occurrences: $($orientMatches.Count)"

# Print lines where cardPlateOrientation is used
$lines = $c -split "`n"
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match "cardPlateOrientation") {
        Write-Host "Line $($i+1): $($lines[$i].Trim())"
    }
}
