$ktData = Get-Content "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\ground_truth_kt_202611.json" -Raw | ConvertFrom-Json
Write-Host "=== KT GROUND TRUTH ==="
foreach ($c in $ktData) {
    Write-Host "---------------------------------"
    Write-Host "ID: $($c.id) | $($c.card_name)"
    Write-Host "  highlightBadge: $($c.highlightBadge)"
    Write-Host "  special_promo:  $($c.special_promo)"
    Write-Host "  notes:          $($c.notes)"
}

$lguData = Get-Content "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\ground_truth_lgu_202611.json" -Raw | ConvertFrom-Json
Write-Host "`n=== LGU GROUND TRUTH ==="
foreach ($c in $lguData) {
    Write-Host "---------------------------------"
    Write-Host "ID: $($c.id) | $($c.card_name)"
    Write-Host "  highlightBadge: $($c.highlightBadge)"
    Write-Host "  special_promo:  $($c.special_promo)"
    Write-Host "  notes:          $($c.notes)"
}
