$htmlPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html"
$content = Get-Content $htmlPath -Raw

$normContent = $content -replace "`r`n", "`n"

# 1. SKT M3
$sktTarget1_badge = 'highlightBadge: "SKT x 현대카드 쿠폰팩 프로모션 (투썸/다이소/CU/올리브영/포인트샵 쿠폰 월 최대 22,700원) & 최대 35,000원 할인 & 24/36개월 자유할부",'
$sktReplace1_badge = 'highlightBadge: "월 최대 35,000원 청구할인 (신규/무실적 24개월) & 24/36개월 자유할부",'

$sktTarget1_promos = @'
      {
        badge: "추가 프로모션",
        title: "SKT x 현대카드 쿠폰팩 프로모션 (투썸/다이소/CU/올리브영/포인트샵 쿠폰 월 최대 22,700원)",
        condition: "행사 기간 내 대상 조건 충족 시",
        benefit: "SKT x 현대카드 쿠폰팩 프로모션 (투썸/다이소/CU/올리브영/포인트샵 쿠폰 월 최대 22,700원)"
      }
'@ -replace "`r`n", "`n"

# 2. SKT M3 Bill
$sktTarget2_badge = 'highlightBadge: "SKT x 현대카드 쿠폰팩 프로모션 (투썸/다이소/CU/올리브영/포인트샵 쿠폰 월 최대 22,700원) & 매월 최대 35,000원 통신요금 자동이체 할인",'
$sktReplace2_badge = 'highlightBadge: "매월 최대 35,000원 통신요금 자동이체 청구할인 (신규/무실적 24개월)",'

# 3. KT M3
$ktTarget_badge = 'highlightBadge: "월 최대 35,000원 청구할인 & 현대카드 쿠폰팩 & 최대 35,000원 할인 & 24/36개월 자유할부",'
$ktReplace_badge = 'highlightBadge: "월 최대 35,000원 청구할인 (신규/무실적 24개월) & 24/36개월 라이트할부",'

$ktTarget_promos = @'
      {
        badge: "추가 프로모션",
        title: "월 최대 35,000원 청구할인 & 현대카드 쿠폰팩",
        condition: "행사 기간 내 대상 조건 충족 시",
        benefit: "월 최대 35,000원 청구할인 & 현대카드 쿠폰팩"
      }
'@ -replace "`r`n", "`n"

# Execute replacements for SKT & KT M3
Write-Host "SKT M3 badge present? $($normContent.Contains($sktTarget1_badge))"
Write-Host "SKT M3 bill badge present? $($normContent.Contains($sktTarget2_badge))"
Write-Host "KT M3 badge present? $($normContent.Contains($ktTarget_badge))"

$normContent = $normContent.Replace($sktTarget1_badge, $sktReplace1_badge)
$normContent = $normContent.Replace($sktTarget2_badge, $sktReplace2_badge)
$normContent = $normContent.Replace($ktTarget_badge, $ktReplace_badge)

# For promotions with comma before it: `,\n      {\n        badge: "추가 프로모션"...`
$sktTarget1_promos_full = ",`n" + $sktTarget1_promos
if ($normContent.Contains($sktTarget1_promos_full)) {
    Write-Host "Found SKT M3 promo block (with comma) - replacing"
    # Note: Replace both occurrences (light + bill)
    $normContent = $normContent.Replace($sktTarget1_promos_full, "")
} else {
    Write-Host "SKT M3 promo block full not found"
}

$ktTarget_promos_full = ",`n" + $ktTarget_promos
if ($normContent.Contains($ktTarget_promos_full)) {
    Write-Host "Found KT M3 promo block (with comma) - replacing"
    $normContent = $normContent.Replace($ktTarget_promos_full, "")
} else {
    Write-Host "KT M3 promo block full not found"
}

# 4. Refine KT redundant badges
$ktBadges = @{
    'highlightBadge: "최대 2.7만원 할인 & 24/36개월 장기할부 지원 & 최대 27,000원 할인 & 24/36개월 자유할부",' = 'highlightBadge: "최대 27,000원 할인 & 24/36개월 장기할부 지원",';
    'highlightBadge: "50만 실적 3.4만 / 100만 실적 3.5만원 최대 24개월 캐시백 & 최대 35,000원 할인 & 24/36개월 자유할부",' = 'highlightBadge: "최대 35,000원 캐시백 & 24/36개월 장기할부 지원",';
    'highlightBadge: "자동납부 통신비 1.5만원 이상 시 24개월 추가할인 & 최대 15,000원 할인 & 24/36개월 자유할부",' = 'highlightBadge: "자동납부 시 최대 15,000원 청구할인 & 24/36개월 자유할부",';
    'highlightBadge: "최대 2.4만원 할인 & 24/36개월 라이트할부 지원 & 최대 24,000원 할인 & 24/36개월 자유할부",' = 'highlightBadge: "최대 24,000원 청구할인 & 24/36개월 라이트할부 지원",';
    'highlightBadge: "최대 57.6만원 할인 (Master 브랜드 한정) & 최대 24,000원 할인 & 24/36개월 자유할부",' = 'highlightBadge: "최대 24,000원 청구할인 (총 최대 57.6만원, Master 한정) & 24/36개월 자유할부",';
    'highlightBadge: "최대 74.4만원 할인 (24/36개월 지원) & 최대 31,000원 할인 & 24/36개월 자유할부",' = 'highlightBadge: "최대 31,000원 청구할인 (총 최대 74.4만원) & 24/36개월 자유할부",';
    'highlightBadge: "요금할인형 최대 2.9만원 할인 & 매월 최대 29,000원 통신요금 자동이체 할인",' = 'highlightBadge: "매월 최대 29,000원 통신요금 자동이체 청구할인",';
}

foreach ($k in $ktBadges.Keys) {
    if ($normContent.Contains($k)) {
        $normContent = $normContent.Replace($k, $ktBadges[$k])
        Write-Host "Updated KT badge: $k"
    } else {
        Write-Host "KT badge key not found: $k"
    }
}

# 5. Refine LGU+ redundant badges
$lguBadges = @{
    'highlightBadge: "최대 57.6만원 할인 (Master 브랜드 발급 한정) & 최대 24,000원 할인 & 24/36개월 자유할부",' = 'highlightBadge: "최대 57.6만원 할인 (Master 한정) & 24/36개월 자유할부",';
    'highlightBadge: "최대 57.6만원 할인 (Master 브랜드 한정) & 최대 24,000원 할인 & 24/36개월 자유할부",' = 'highlightBadge: "최대 57.6만원 할인 (Master 한정) & 24/36개월 자유할부",';
    'highlightBadge: "아이폰18/아이폰DUO 구매 시 최대 10만원 추가 캐시백 (총 최대 64.8만원 할인) & 최대 27,000원 할인 & 24/36개월 자유할부",' = 'highlightBadge: "아이폰18/DUO 최대 10만원 캐시백 (총 최대 64.8만원 할인) & 24/36개월 자유할부",';
    'highlightBadge: "최대 84만원 할인 (이벤트 응모 필수) & 최대 35,000원 할인 & 24/36개월 자유할부",' = 'highlightBadge: "최대 84만원 할인 (이벤트 응모 필수) & 24/36개월 자유할부",';
    'highlightBadge: "최대 111.6만원 할인 (36개월 기준, 동일카드 탈회 1년 미경과 시 제외) & 최대 31,000원 할인 & 24/36개월 자유할부",' = 'highlightBadge: "최대 111.6만원 할인 (36개월 기준) & 24/36개월 자유할부",';
    'highlightBadge: "최대 52.8만원 할인 (가족카드 발급 불가) & 최대 22,000원 할인 & 24/36개월 자유할부",' = 'highlightBadge: "최대 52.8만원 할인 (가족카드 발급 불가) & 24/36개월 자유할부",';
    'highlightBadge: "최대 86.4만원 할인 (JCB 브랜드 발급 시 2.5만원 캐시백 추가) & 최대 24,000원 할인 & 24/36개월 자유할부",' = 'highlightBadge: "최대 86.4만원 할인 (JCB 2.5만 캐시백 추가) & 24/36개월 자유할부",';
    'highlightBadge: "최대 84만원 할인 (가족카드 발급 불가) & 최대 35,000원 할인 & 24/36개월 자유할부",' = 'highlightBadge: "최대 84만원 할인 (가족카드 발급 불가) & 24/36개월 자유할부",';
    'highlightBadge: "신규 출시 (New) 최대 69.6만원 할인 & 최대 29,000원 할인 & 24/36개월 자유할부",' = 'highlightBadge: "신규 출시 (New) 최대 69.6만원 할인 & 24/36개월 자유할부",';
    'highlightBadge: "최대 79.2만원 할인 (36개월 기준) & 최대 22,000원 할인 & 24/36개월 자유할부",' = 'highlightBadge: "최대 79.2만원 할인 (36개월 기준) & 24/36개월 자유할부",';
    'highlightBadge: "최대 60만원 할인 (1~24개월차 통신요금 25% 할인, 25개월차부터 15% 할인) & 최대 25,000원 할인 & 24/36개월 자유할부",' = 'highlightBadge: "최대 60만원 할인 (1~24개월 25% / 25개월~ 15% 할인) & 24/36개월 자유할부",';
    'highlightBadge: "최대 64.8만원 할인 & 매월 최대 27,000원 통신요금 자동이체 할인",' = 'highlightBadge: "매월 최대 27,000원 통신요금 자동이체 할인 (총 최대 64.8만원)",';
}

foreach ($k in $lguBadges.Keys) {
    if ($normContent.Contains($k)) {
        $normContent = $normContent.Replace($k, $lguBadges[$k])
        Write-Host "Updated LGU badge: $k"
    } else {
        Write-Host "LGU badge key not found: $k"
    }
}

[System.IO.File]::WriteAllText($htmlPath, ($normContent -replace "`n", "`r`n"), [System.Text.Encoding]::UTF8)
Write-Host "Saved updated index.html successfully!"
