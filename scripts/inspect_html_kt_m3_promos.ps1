$html = Get-Content "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html" -Raw
$ktPos = $html.IndexOf("kt_hyundai_m3_2")
if ($ktPos -gt -1) {
    $promoPos = $html.IndexOf("promotions:", $ktPos)
    $sub = $html.Substring($promoPos, 1500)
    Write-Host $sub
}
