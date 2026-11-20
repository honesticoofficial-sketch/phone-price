$sktPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\skt_cards_data.js"
$content = Get-Content $sktPath -Raw

# 1. skt_hyundai_m3
$target1 = @'
    highlightBadge: "SKT x 현대카드 쿠폰팩 프로모션 (투썸/다이소/CU/올리브영/포인트샵 쿠폰 월 최대 22,700원) & 최대 35,000원 할인 & 24/36개월 자유할부",
'@

$replace1 = @'
    highlightBadge: "월 최대 35,000원 청구할인 (신규/무실적 24개월) & 24/36개월 자유할부",
'@

$target1_promos = @'
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인",
        condition: "현대카드 신규 또는 행사월 기준 6개월 이상 무실적 고객 (M3 T라이트2 최초 발급)",
        highlight: "매월 최대 35,000원",
        tiers: [
          { label: "전월 50만원 이상", amount: "월 33,000원 할인", amountNum: 33000, baseAmount: "15,000", promoAmount: "18,000", sub: "기본 15,000원 + 프로모션 18,000원", total24: "24개월 총 792,000원 할인", total24Num: 792000, total36: "36개월 총 972,000원 할인", total36Num: 972000, total36Note: "1~24회차: 월 33,000원 / 25~36회차: 기본 월 15,000원" },
          { label: "전월 100만원 이상", amount: "월 35,000원 할인", amountNum: 35000, baseAmount: "25,000", promoAmount: "10,000", sub: "기본 25,000원 + 프로모션 10,000원", total24: "24개월 총 840,000원 할인", total24Num: 840000, total36: "36개월 총 1,140,000원 할인", total36Num: 1140000, total36Note: "1~24회차: 월 35,000원 / 25~36회차: 기본 월 25,000원" }
        ]
      },
      {
        badge: "추가 프로모션",
        title: "SKT x 현대카드 쿠폰팩 프로모션 (투썸/다이소/CU/올리브영/포인트샵 쿠폰 월 최대 22,700원)",
        condition: "행사 기간 내 대상 조건 충족 시",
        benefit: "SKT x 현대카드 쿠폰팩 프로모션 (투썸/다이소/CU/올리브영/포인트샵 쿠폰 월 최대 22,700원)"
      }
    ],
'@

$replace1_promos = @'
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인",
        condition: "현대카드 신규 또는 행사월 기준 6개월 이상 무실적 고객 (M3 T라이트2 최초 발급)",
        highlight: "매월 최대 35,000원",
        tiers: [
          { label: "전월 50만원 이상", amount: "월 33,000원 할인", amountNum: 33000, baseAmount: "15,000", promoAmount: "18,000", sub: "기본 15,000원 + 프로모션 18,000원", total24: "24개월 총 792,000원 할인", total24Num: 792000, total36: "36개월 총 972,000원 할인", total36Num: 972000, total36Note: "1~24회차: 월 33,000원 / 25~36회차: 기본 월 15,000원" },
          { label: "전월 100만원 이상", amount: "월 35,000원 할인", amountNum: 35000, baseAmount: "25,000", promoAmount: "10,000", sub: "기본 25,000원 + 프로모션 10,000원", total24: "24개월 총 840,000원 할인", total24Num: 840000, total36: "36개월 총 1,140,000원 할인", total36Num: 1140000, total36Note: "1~24회차: 월 35,000원 / 25~36회차: 기본 월 25,000원" }
        ]
      }
    ],
'@

# 2. skt_hyundai_m3_bill
$target2 = @'
    highlightBadge: "SKT x 현대카드 쿠폰팩 프로모션 (투썸/다이소/CU/올리브영/포인트샵 쿠폰 월 최대 22,700원) & 매월 최대 35,000원 통신요금 자동이체 할인",
'@

$replace2 = @'
    highlightBadge: "매월 최대 35,000원 통신요금 자동이체 청구할인 (신규/무실적 24개월)",
'@

$target2_promos = @'
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인",
        condition: "현대카드 신규 또는 행사월 기준 6개월 이상 무실적 고객 (M3 통신할인형2.0 최초 발급, SKT 자동이체 필수)",
        highlight: "매월 최대 35,000원",
        tiers: [
          { label: "전월 50만원 이상", amount: "월 33,000원 할인", amountNum: 33000, baseAmount: "15,000", promoAmount: "18,000", sub: "기본 15,000원 + 프로모션 18,000원", total24: "24개월 총 792,000원 할인", total24Num: 792000, total36: "36개월 총 972,000원 할인", total36Num: 972000, total36Note: "1~24회차: 월 33,000원 / 25~36회차: 기본 월 15,000원" },
          { label: "전월 100만원 이상", amount: "월 35,000원 할인", amountNum: 35000, baseAmount: "25,000", promoAmount: "10,000", sub: "기본 25,000원 + 프로모션 10,000원", total24: "24개월 총 840,000원 할인", total24Num: 840000, total36: "36개월 총 1,140,000원 할인", total36Num: 1140000, total36Note: "1~24회차: 월 35,000원 / 25~36회차: 기본 월 25,000원" }
        ]
      },
      {
        badge: "추가 프로모션",
        title: "SKT x 현대카드 쿠폰팩 프로모션 (투썸/다이소/CU/올리브영/포인트샵 쿠폰 월 최대 22,700원)",
        condition: "행사 기간 내 대상 조건 충족 시",
        benefit: "SKT x 현대카드 쿠폰팩 프로모션 (투썸/다이소/CU/올리브영/포인트샵 쿠폰 월 최대 22,700원)"
      }
    ],
'@

$replace2_promos = @'
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인",
        condition: "현대카드 신규 또는 행사월 기준 6개월 이상 무실적 고객 (M3 통신할인형2.0 최초 발급, SKT 자동이체 필수)",
        highlight: "매월 최대 35,000원",
        tiers: [
          { label: "전월 50만원 이상", amount: "월 33,000원 할인", amountNum: 33000, baseAmount: "15,000", promoAmount: "18,000", sub: "기본 15,000원 + 프로모션 18,000원", total24: "24개월 총 792,000원 할인", total24Num: 792000, total36: "36개월 총 972,000원 할인", total36Num: 972000, total36Note: "1~24회차: 월 33,000원 / 25~36회차: 기본 월 15,000원" },
          { label: "전월 100만원 이상", amount: "월 35,000원 할인", amountNum: 35000, baseAmount: "25,000", promoAmount: "10,000", sub: "기본 25,000원 + 프로모션 10,000원", total24: "24개월 총 840,000원 할인", total24Num: 840000, total36: "36개월 총 1,140,000원 할인", total36Num: 1140000, total36Note: "1~24회차: 월 35,000원 / 25~36회차: 기본 월 25,000원" }
        ]
      }
    ],
'@

$normContent = $content -replace "`r`n", "`n"
$normTarget1 = $target1 -replace "`r`n", "`n"
$normTarget1_promos = $target1_promos -replace "`r`n", "`n"
$normTarget2 = $target2 -replace "`r`n", "`n"
$normTarget2_promos = $target2_promos -replace "`r`n", "`n"

$normReplace1 = $replace1 -replace "`r`n", "`n"
$normReplace1_promos = $replace1_promos -replace "`r`n", "`n"
$normReplace2 = $replace2 -replace "`r`n", "`n"
$normReplace2_promos = $replace2_promos -replace "`r`n", "`n"

Write-Host "Target1 in content? $($normContent.Contains($normTarget1))"
Write-Host "Target1_promos in content? $($normContent.Contains($normTarget1_promos))"
Write-Host "Target2 in content? $($normContent.Contains($normTarget2))"
Write-Host "Target2_promos in content? $($normContent.Contains($normTarget2_promos))"

if ($normContent.Contains($normTarget1) -and $normContent.Contains($normTarget1_promos) -and $normContent.Contains($normTarget2) -and $normContent.Contains($normTarget2_promos)) {
    $newContent = $normContent.Replace($normTarget1, $normReplace1)
    $newContent = $newContent.Replace($normTarget1_promos, $normReplace1_promos)
    $newContent = $newContent.Replace($normTarget2, $normReplace2)
    $newContent = $newContent.Replace($normTarget2_promos, $normReplace2_promos)
    
    [System.IO.File]::WriteAllText($sktPath, ($newContent -replace "`n", "`r`n"), [System.Text.Encoding]::UTF8)
    Write-Host "SUCCESS: Updated skt_cards_data.js cleanly!"
} else {
    Write-Host "FAILED: Targets not matched!"
}
