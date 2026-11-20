$kt = Get-Content "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\ground_truth_kt_202611.json" -Raw -Encoding UTF8 | ConvertFrom-Json
Write-Host "KT Props:" ($kt[0] | Get-Member -MemberType NoteProperty).Name
Write-Host "KT[0]: $($kt[0].card_company) / $($kt[0].card_name)"

$lgu = Get-Content "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\ground_truth_lgu_202611.json" -Raw -Encoding UTF8 | ConvertFrom-Json
Write-Host "LGU Props:" ($lgu[0] | Get-Member -MemberType NoteProperty).Name
Write-Host "LGU[0]: $($lgu[0].card_company) / $($lgu[0].card_name)"
