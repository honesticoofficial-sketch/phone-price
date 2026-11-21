$csv = Get-Content 'C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\ground_truth_skt_202611.csv' -Encoding UTF8
for ($i = 0; $i -lt $csv.Count; $i++) {
    if ($csv[$i] -match "http|naver|www|site|QR|인증") {
        Write-Host "Line $i`: $($csv[$i])"
    }
}
