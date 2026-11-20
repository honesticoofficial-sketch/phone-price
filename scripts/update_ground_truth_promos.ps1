# Update ground_truth_skt_202611.json
$sktJsonPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\ground_truth_skt_202611.json"
$sktJson = Get-Content $sktJsonPath -Raw | ConvertFrom-Json

foreach ($c in $sktJson) {
    if ($c.card_name -like "*현대카드 M3 T라이트2*") {
        $c.special_promo = "신규/6개월 무실적 고객 전월 50만 33,000원 / 100만 35,000원 청구할인 (24개월)"
    }
    elseif ($c.card_name -like "*현대카드 M3 통신할인형2.0*") {
        $c.special_promo = "신규/6개월 무실적 고객 전월 50만 33,000원 / 100만 35,000원 통신요금 청구할인 (24개월)"
    }
}
$sktJson | ConvertTo-Json -Depth 10 | Set-Content $sktJsonPath -Encoding UTF8
Write-Host "Updated ground_truth_skt_202611.json"

# Update ground_truth_kt_202611.json
$ktJsonPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\ground_truth_kt_202611.json"
$ktJson = Get-Content $ktJsonPath -Raw | ConvertFrom-Json

foreach ($c in $ktJson) {
    if ($c.card_name -like "*현대카드M Edition3*") {
        $c.special_promo = "신규/6개월 무실적 고객 전월 50만 33,000원 / 100만 35,000원 청구할인 (24개월)"
    }
}
$ktJson | ConvertTo-Json -Depth 10 | Set-Content $ktJsonPath -Encoding UTF8
Write-Host "Updated ground_truth_kt_202611.json"
