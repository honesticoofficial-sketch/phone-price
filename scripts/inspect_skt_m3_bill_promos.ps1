$skt = Get-Content "C:\Users\User01\.gemini\antigravity\scratch\phone-price\skt_cards_data.js" -Raw

$pos2 = $skt.IndexOf('id: "skt_hyundai_m3_bill",')
if ($pos2 -ge 0) {
    $promoPos = $skt.IndexOf('promotions:', $pos2)
    $sub2 = $skt.Substring($promoPos, 1500)
    Write-Host $sub2
}
