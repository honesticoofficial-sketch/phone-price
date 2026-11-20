$html = Get-Content "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html" -Raw

$ktTargetPromos = @'
      {
        badge: "추가 프로모션",
        title: "월 최대 35,000원 청구할인 & 현대카드 쿠폰팩",
        condition: "행사 기간 내 대상 조건 충족 시",
        benefit: "월 최대 35,000원 청구할인 & 현대카드 쿠폰팩"
      }
'@

$normHtml = $html -replace "`r`n", "`n"
$normTarget = $ktTargetPromos -replace "`r`n", "`n"

Write-Host "KT coupon promo found? $($normHtml.Contains($normTarget))"
