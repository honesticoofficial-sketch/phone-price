$lines = Get-Content "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html"

$currentGroup = ""
$currentCard = $null

foreach ($line in $lines) {
    if ($line -match 'const (SKT|KT|LGU)_AFFILIATE_CARDS') {
        $currentGroup = $matches[1]
        Write-Host "`n=== $currentGroup AFFILIATE CARDS ==="
    }
    if ($line -match 'id:\s*"([^"]+)"') {
        $id = $matches[1]
        $currentCard = [ordered]@{ Id = $id; Group = $currentGroup }
    }
    if ($line -match 'cardCompany:\s*"([^"]+)"' -and $currentCard) {
        $currentCard['Company'] = $matches[1]
    }
    if ($line -match 'cardName:\s*"([^"]+)"' -and $currentCard) {
        $currentCard['Name'] = $matches[1]
    }
    if ($line -match 'cardPlateImageUrl:\s*"([^"]+)"' -and $currentCard) {
        $img = $matches[1]
        $len = $img.Length
        $prefix = if ($len -gt 35) { $img.Substring(0, 30) } else { $img }
        Write-Host "  $($currentCard.Id) | $($currentCard.Company) | $($currentCard.Name) | Len: $len | $prefix"
        $currentCard = $null
    }
}
