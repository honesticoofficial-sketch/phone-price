$ktData = Get-Content "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\ground_truth_kt_202611.json" -Raw | ConvertFrom-Json
$m3 = $ktData | Where-Object { $_.card_name -like "*현대*" }
$m3 | ConvertTo-Json -Depth 5
