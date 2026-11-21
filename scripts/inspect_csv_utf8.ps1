$csv = Get-Content 'C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\ground_truth_skt_202611.csv' -Encoding UTF8
$csv | Select-String -Pattern "QR|이벤트|무실적|신규|신한|0JM2M|naver" -Context 1,1 | Select-Object -First 30
