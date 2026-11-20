$html = Get-Content "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html" -Raw
# Find kt_hyundai_m3_2
$ktPos = $html.IndexOf("kt_hyundai_m3_2")
if ($ktPos -gt -1) {
    $sub = $html.Substring($ktPos - 50, 1500)
    Write-Host $sub
}
