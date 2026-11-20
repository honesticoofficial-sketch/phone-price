$kt = Get-Content "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\ground_truth_kt_202611.json" -Raw | ConvertFrom-Json
foreach ($c in $kt) {
    Write-Host "$($c.card_company) | $($c.card_name) | $($c.card_plate_image)"
}
