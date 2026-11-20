$skt = Get-Content "C:\Users\User01\.gemini\antigravity\scratch\phone-price\skt_cards_data.js" -Raw

$pos1 = $skt.IndexOf('id: "skt_hyundai_m3",')
if ($pos1 -ge 0) {
    $promoPos = $skt.IndexOf('promotions:', $pos1)
    $sub1 = $skt.Substring($promoPos, 1500)
    Write-Host $sub1
}
