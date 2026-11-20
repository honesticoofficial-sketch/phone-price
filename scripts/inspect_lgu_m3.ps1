$lguData = Get-Content "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\ground_truth_lgu_202611.json" -Raw | ConvertFrom-Json
$m3Lgu = $lguData | Where-Object { $_.card_name -like "*현대*" -or $_.card_name -like "*Edition*" }
$m3Lgu | ConvertTo-Json -Depth 5
