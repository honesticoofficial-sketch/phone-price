$url = "https://static.toss.im/assets/credit-card/2053.png"
$dest = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\hana_skt_tzero.png"

Invoke-WebRequest -Uri $url -OutFile $dest -UserAgent "Mozilla/5.0"
Write-Host "Downloaded size: $((Get-Item $dest).Length) bytes"
