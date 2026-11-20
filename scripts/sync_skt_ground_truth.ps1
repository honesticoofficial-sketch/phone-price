$gtPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\ground_truth_skt_202611.json"
$gtCards = Get-Content $gtPath -Raw -Encoding UTF8 | ConvertFrom-Json

$refDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\references\skt"

# Map ground truth card to reference file
$mapping = @{
    "삼성카드 T PREMIUM" = "skt_samsung_premium.png"
    "현대카드 M3 T라이트2" = "skt_hyundai_m3.png"
    "NH카드 T라이트" = "skt_nh_tlight.png"
    "삼성카드 T라이트" = "skt_samsung_tlight.png"
    "하나카드 T-Zero" = "skt_hana_tdown.png"
    "하나카드 T다운" = "skt_hana_tdown.png"
    "우리카드 T라이트" = "skt_woori_tlight.png"
    "T라이트 KB국민카드" = "skt_kb_tlight.png"
    "롯데카드 T 라이트" = "skt_lotte_tlight.png"
    "롯데카드 T 라이트 (Renewal)" = "skt_lotte_tlight.png"
    "신한카드 T라이트" = "skt_shinhan_tlight.png"
    "신한카드 파인애플" = "skt_shinhan_pineapple.png"
    "신한카드 T&LIFE" = "skt_shinhan_tlife.png"
    "T-economy KB국민카드" = "skt_kb_teconomy.png"
    "현대카드 M3 통신할인형2.0" = "skt_hyundai_m3_bill.png"
    "TELLO NE 롯데카드" = "skt_lotte_tello.png"
    "TELLO NE 롯데카드 (Renewal)" = "skt_lotte_tello.png"
    "삼성카드 T나는혜택" = "skt_samsung_tnana.png"
}

Write-Host "Syncing ground_truth_skt_202611.json..."
foreach ($c in $gtCards) {
    $refFile = $mapping[$c.card_name]
    if ($refFile) {
        $p = Join-Path $refDir $refFile
        if (Test-Path $p) {
            $bytes = [System.IO.File]::ReadAllBytes($p)
            $b64 = [System.Convert]::ToBase64String($bytes)
            $c.card_plate_image = "data:image/png;base64,$b64"
            Write-Host "  Synced $($c.card_name) -> $refFile"
        }
    } else {
        Write-Warning "  No mapping for $($c.card_name)"
    }
}

$jsonOut = $gtCards | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($gtPath, $jsonOut, [System.Text.Encoding]::UTF8)
Write-Host "ground_truth_skt_202611.json synchronized!"
