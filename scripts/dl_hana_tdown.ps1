$url = "https://search.pstatic.net/sunny?src=https%3A%2F%2Fnews.btgtm.com%2Fwp-content%2Fuploads%2F2024%2F09%2F%25ED%2595%2598%25EB%2582%2598%25EC%25B9%25B4%25EB%2593%259C-t%25EB%258B%25A4%25EC%259A%25B4.jpg"
$dest = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\hana_tdown_downloaded.jpg"

Invoke-WebRequest -Uri $url -OutFile $dest -UserAgent "Mozilla/5.0"
Write-Host "Downloaded size: $((Get-Item $dest).Length) bytes"
