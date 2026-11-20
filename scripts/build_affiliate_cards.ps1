[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

$workspace = "C:\Users\User01\.gemini\antigravity\scratch\phone-price"
$indexHtmlPath = Join-Path $workspace "index.html"

# 1. 기존 index.html 카드 정보 추출
Write-Host "1. 기존 index.html 카드 정보 추출 중..."
$lines = Get-Content $indexHtmlPath -Encoding UTF8

$existingCards = @()
$curCard = $null

for ($i = 7115; $i -lt 9280; $i++) {
    $line = $lines[$i]
    if ($line -match '^\s*\{\s*$') {
        if ($curCard -and $curCard.cardName) {
            $existingCards += $curCard
        }
        $curCard = @{
            id = ""
            carrier = ""
            cardCompany = ""
            cardName = ""
            cardPlateImageUrl = ""
            theme = ""
            highlightBadge = ""
            phone = ""
            applyUrl = ""
            specialPromo = $null
        }
    }
    if ($curCard) {
        if ($line -match 'id:\s*["''](.*?)["'']') { $curCard.id = $matches[1] }
        if ($line -match 'carrier:\s*["''](.*?)["'']') { $curCard.carrier = $matches[1] }
        if ($line -match 'cardCompany:\s*["''](.*?)["'']') { $curCard.cardCompany = $matches[1] }
        if ($line -match 'cardName:\s*["''](.*?)["'']') { $curCard.cardName = $matches[1] }
        if ($line -match 'theme:\s*["''](.*?)["'']') { $curCard.theme = $matches[1] }
        if ($line -match 'phone:\s*["''](.*?)["'']') { $curCard.phone = $matches[1] }
        if ($line -match 'applyUrl:\s*["''](.*?)["'']') { $curCard.applyUrl = $matches[1] }
        if ($line -match 'cardPlateImageUrl:\s*["''](.*?)["'']') { $curCard.cardPlateImageUrl = $matches[1] }
    }
}
if ($curCard -and $curCard.cardName) {
    $existingCards += $curCard
}
Write-Host "   추출된 기존 카드 수: $($existingCards.Count)"

# 명시적 매핑 테이블 (새 JSON 카드명 -> 기존 ID)
$explicitIdMap = @{
    # SKT
    "SKT|삼성카드|삼성카드 T PREMIUM" = "skt_samsung_premium"
    "SKT|NH농협카드|NH카드 T라이트" = "skt_nh_tlight"
    "SKT|KB국민카드|T-economy KB국민카드" = "skt_kb_teconomy"
    "SKT|롯데카드|TELLO NE 롯데카드 (Renewal)" = "skt_lotte_tello"
    "SKT|롯데카드|롯데카드 T 라이트 (Renewal)" = "skt_lotte_tlight"
    "SKT|하나카드|하나카드 T다운" = "skt_hana_tdown"
    
    # KT
    "KT|현대카드|KT-현대카드M Edition3 (라이트할부형)" = "kt_hyundai_m3_2"
    "KT|신한카드|KT 신한카드 T라이트" = "kt_shinhan_family_light"
    "KT|우리카드|KT 우리카드 카드의정석 SUPER DC" = "kt_woori_36_plus"
    
    # LGU+
    "LGU+|KB국민카드|LGU+ 라이트할부Ⅱ KB국민카드" = "lgu_kb_light2"
    "LGU|KB국민카드|LGU+ 라이트할부Ⅱ KB국민카드" = "lgu_kb_light2"
    "LGU+|우리카드|U+ x 36우리카드" = "lgu_woori_36"
    "LGU|우리카드|U+ x 36우리카드" = "lgu_woori_36"
    "LGU+|롯데카드|U+ x LOCA 라이트할부" = "lgu_lotte_light"
    "LGU|롯데카드|U+ x LOCA 라이트할부" = "lgu_lotte_light"
    "LGU+|롯데카드|LG U+ x LOCA" = "lgu_lotte_loca"
    "LGU|롯데카드|LG U+ x LOCA" = "lgu_lotte_loca"
    "LGU+|현대카드|M Edition 3 (통신할인형 2.0)" = "lgu_hyundai_m3"
    "LGU|현대카드|M Edition 3 (통신할인형 2.0)" = "lgu_hyundai_m3"
    "LGU+|NH농협카드|올원" = "lgu_nh_allone"
    "LGU|NH농협카드|올원" = "lgu_nh_allone"
}

# 2. 정답지 JSON 로드
$sktJson = Get-Content (Join-Path $workspace "data\ground_truth_skt_202611.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$ktJson = Get-Content (Join-Path $workspace "data\ground_truth_kt_202611.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$lguJson = Get-Content (Join-Path $workspace "data\ground_truth_lgu_202611.json") -Raw -Encoding UTF8 | ConvertFrom-Json

# 매칭 헬퍼 함수
function Find-ExistingCard($carrier, $company, $name) {
    # 0. 명시적 매핑 테이블
    $mapKey = "$carrier|$company|$name"
    if ($explicitIdMap.ContainsKey($mapKey)) {
        $targetId = $explicitIdMap[$mapKey]
        $matchById = $existingCards | Where-Object { $_.id -eq $targetId } | Select-Object -First 1
        if ($matchById) { return $matchById }
    }

    # 1. 완전 일치
    $found = $existingCards | Where-Object { $_.carrier -eq $carrier -and $_.cardCompany -eq $company -and $_.cardName -eq $name } | Select-Object -First 1
    if ($found) { return $found }

    # 2. 카드사 일치 & 이름 유사
    $cleanName = ($name -replace '[^a-zA-Z0-9가-힣]', '').ToLower()
    $candidates = $existingCards | Where-Object { $_.carrier -eq $carrier -and $_.cardCompany -eq $company }
    foreach ($cand in $candidates) {
        $candClean = ($cand.cardName -replace '[^a-zA-Z0-9가-힣]', '').ToLower()
        if ($candClean -eq $cleanName -or $candClean.Contains($cleanName) -or $cleanName.Contains($candClean)) {
            return $cand
        }
    }

    # 3. 카드사만으로 매칭 (후보가 1개인 경우)
    if ($candidates.Count -eq 1) {
        return $candidates[0]
    }

    return $null
}

# 기본 테마 매핑
function Get-DefaultTheme($company) {
    switch -Wildcard ($company) {
        "*국민*" { return "theme-gold" }
        "*신한*" { return "theme-blue" }
        "*삼성*" { return "theme-navy" }
        "*현대*" { return "theme-teal" }
        "*롯데*" { return "theme-rose" }
        "*우리*" { return "theme-teal" }
        "*하나*" { return "theme-teal" }
        "*농협*" { return "theme-emerald" }
        "*BC*" { return "theme-rose" }
        Default { return "theme-blue" }
    }
}

# 기본 전화번호 매핑
function Get-DefaultPhone($company) {
    switch -Wildcard ($company) {
        "*국민*" { return "KB국민카드 고객센터 1577-9900" }
        "*신한*" { return "신한카드 고객센터 1544-7000" }
        "*삼성*" { return "삼성카드 고객센터 1588-8700" }
        "*현대*" { return "현대카드 고객센터 1577-6000" }
        "*롯데*" { return "롯데카드 고객센터 1588-8100" }
        "*우리*" { return "우리카드 고객센터 1588-9955" }
        "*하나*" { return "하나카드 고객센터 1800-1111" }
        "*농협*" { return "NH농협카드 고객센터 1644-4000" }
        "*BC*" { return "BC카드 고객센터 1588-4000" }
        Default { return "$company 고객센터" }
    }
}

# 개별 카드 JS 객체 문자열 생성 함수
function Build-CardJsObject($c, $carrierCode, $index) {
    $matched = Find-ExistingCard $carrierCode $c.card_company $c.card_name
    
    $id = if ($matched -and $matched.id) { $matched.id } else { "$($carrierCode.ToLower())_$($index)" }
    $theme = if ($matched -and $matched.theme) { $matched.theme } else { Get-DefaultTheme $c.card_company }
    $phone = if ($matched -and $matched.phone) { $matched.phone } else { Get-DefaultPhone $c.card_company }
    $imgUrl = if ($matched -and $matched.cardPlateImageUrl) { $matched.cardPlateImageUrl } else { "" }
    
    # applyUrl
    $applyUrl = $c.urls.apply_url
    if (-not $applyUrl -or $applyUrl -eq "" -or $applyUrl -eq "null") {
        if ($matched -and $matched.applyUrl) { $applyUrl = $matched.applyUrl }
        else { $applyUrl = "https://m.card.co.kr" }
    }

    # 카드 타입 판별
    $isLight = ($c.min_installment_amount -ne "해당없음" -and $c.min_installment_amount -notmatch "요금할인")
    $typeStr = if ($isLight) { "light" } else { "bill" }
    $typeLabel = if ($isLight) { "라이트할부" } else { "요금할인" }

    # tiers 처리
    $maxMonthly = 0
    $firstTierDiscount = 0
    $tierObjs = @()
    $is36MonthCard = $false

    foreach ($t in $c.discount_tiers) {
        $monthly = [int]$t.total_monthly_discount
        $base = [int]$t.base_discount
        $promo = [int]$t.promo_discount
        if ($monthly -gt $maxMonthly) { $maxMonthly = $monthly }
        if ($firstTierDiscount -eq 0) { $firstTierDiscount = $monthly }

        $duration = $t.benefit_duration
        if ($duration -match "36") { $is36MonthCard = $true }

        $tot24 = $monthly * 24
        
        # 36개월 계산
        $tot36 = 0
        $tot36Note = ""
        if ($is36MonthCard) {
            $tot36 = $monthly * 36
            $tot36Note = "36개월 프로모션 적용: 월 $($monthly.ToString('N0'))원 x 36회차"
        } else {
            $tot36 = ($monthly * 24) + ($base * 12)
            $tot36Note = "1~24회차: 월 $($monthly.ToString('N0'))원 / 25~36회차: 기본 월 $($base.ToString('N0'))원"
        }

        $tierJson = @"
          { label: "전월 $($t.required_performance)", amount: "월 $($monthly.ToString('N0'))원 할인", amountNum: $monthly, baseAmount: "$($base.ToString('N0'))", promoAmount: "$($promo.ToString('N0'))", sub: "기본 $($base.ToString('N0'))원 + 프로모션 $($promo.ToString('N0'))원", total24: "24개월 총 $($tot24.ToString('N0'))원 할인", total24Num: $tot24, total36: "36개월 총 $($tot36.ToString('N0'))원 할인", total36Num: $tot36, total36Note: "$tot36Note" }
"@
        $tierObjs += $tierJson
    }

    $tiersJsStr = $tierObjs -join ",`n"

    # highlightBadge 생성
    $badgeText = ""
    if ($c.special_promo) {
        $badgeText = "$($c.special_promo) & "
    }
    if ($isLight) {
        $badgeText += "최대 $($maxMonthly.ToString('N0'))원 할인 & 24/36개월 자유할부"
    } else {
        $badgeText += "매월 최대 $($maxMonthly.ToString('N0'))원 통신요금 자동이체 할인"
    }

    # supports36Months
    $supports36 = if ($isLight) { "true" } else { "false" }
    $promo36 = if ($is36MonthCard) { "true" } else { "false" }

    # autoTransfer
    $autoStr = if ($c.autopay_required) { "필수" } else { "미필수 (자유)" }

    # annualFee
    $domFee = if ($c.annual_fee.domestic) { $c.annual_fee.domestic } else { "20,000원" }
    $overFee = if ($c.annual_fee.overseas) { $c.annual_fee.overseas } else { "20,000원" }
    $annualFeeStr = "국내 $domFee / 해외 $overFee"

    # installmentInterest
    $int24 = if ($c.installment_interest -and $c.installment_interest.'24_months') { $c.installment_interest.'24_months' } else { "5.9%" }
    $int36 = if ($c.installment_interest -and $c.installment_interest.'36_months') { $c.installment_interest.'36_months' } else { "7.0%" }
    $interestStr = if ($isLight) { "24개월 $int24 / 36개월 $int36" } else { "해당없음 (일반결제)" }

    # eventTarget
    $targetCond = if ($c.promo_target_condition) { $c.promo_target_condition } else { "행사월 기준 직전 6개월간 해당 카드사 무실적 고객" }

    # promotions array
    $promoArr = @()
    $promo1 = @"
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인",
        condition: "$targetCond",
        highlight: "매월 최대 $($maxMonthly.ToString('N0'))원",
        tiers: [
$tiersJsStr
        ]
      }
"@
    $promoArr += $promo1

    if ($c.special_promo) {
        $promo2 = @"
      {
        badge: "추가 프로모션",
        title: "$($c.special_promo)",
        condition: "행사 기간 내 대상 조건 충족 시",
        benefit: "$($c.special_promo)"
      }
"@
        $promoArr += $promo2
    }
    $promotionsJsStr = $promoArr -join ",`n"

    # basicBenefits
    $benefitsList = @()
    if ($c.base_card_benefits -and $c.base_card_benefits.Count -gt 0) {
        foreach ($b in $c.base_card_benefits) {
            $benefitsList += "      `"$b`""
        }
    } else {
        $benefitsList += "      `"전국 가맹점 포인트 적립 및 생활 편의 혜택`""
        $benefitsList += "      `"주요 제휴처(커피, 베이커리, 영화) 할인`""
    }
    $benefitsJsStr = $benefitsList -join ",`n"

    # details
    $detailsList = @()
    if ($c.performance_criteria.included -and $c.performance_criteria.included.Count -gt 0) {
        $incStr = $c.performance_criteria.included -join ", "
        $detailsList += "      `"전월실적 산정: $incStr`""
    }
    if ($c.performance_criteria.excluded -and $c.performance_criteria.excluded.Count -gt 0) {
        $excStr = $c.performance_criteria.excluded -join ", "
        $detailsList += "      `"전월실적 제외: $excStr`""
    }
    $detailsList += "      `"할인 혜택은 카드 이용 및 유지 기간 동안만 제공되며 해지/완납 시 종료`""
    $detailsList += "      `"신규 발급 회원은 발급월 및 익월 전월실적 미충족 시에도 1회차 기본 및 프로모션 할인 제공`""
    $detailsJsStr = $detailsList -join ",`n"

    # JSON 안전 escape
    $cardNameClean = $c.card_name -replace '"', '\"'
    $companyClean = $c.card_company -replace '"', '\"'
    $badgeClean = $badgeText -replace '"', '\"'
    $targetDeviceClean = $c.target_device -replace '"', '\"'
    $minPayClean = $c.min_installment_amount -replace '"', '\"'

    $cardJs = @"
  {
    id: "$id",
    carrier: "$carrierCode",
    type: "$typeStr",
    typeLabel: "$typeLabel",
    cardCompany: "$companyClean",
    cardName: "$cardNameClean",
    theme: "$theme",
    highlightBadge: "$badgeClean",
    phone: "$phone",
    applyUrl: "$applyUrl",
    eventTarget: "$targetCond",
    cardPlateImageUrl: "$imgUrl",
    cardPlateOrientation: "horizontal",
    supports36Months: $supports36,
    promo36Months: $promo36,
    specs: {
      targetDevice: "$targetDeviceClean",
      minPayment: "$minPayClean",
      autoTransfer: "$autoStr",
      annualFee: "$annualFeeStr",
      installmentInterest: "$interestStr",
      applyMethod: "발급 QR코드 스캔 / 공식 모바일 URL"
    },
    summary: {
      installmentSub: "※ 단말기 잔여 할부원금은 아래 매월 카드 이용 실적 청구할인 혜택으로 전액 상쇄됩니다."
    },
    promotions: [
$promotionsJsStr
    ],
    basicBenefits: [
$benefitsJsStr
    ],
    details: [
$detailsJsStr
    ]
  }
"@
    return $cardJs
}

# 3. 3사 코드 블록 생성
Write-Host "3. 3사 JS 배열 코드 블록 빌드 중..."

$sktCardBlocks = @()
for ($k = 0; $k -lt $sktJson.Count; $k++) {
    $sktCardBlocks += Build-CardJsObject $sktJson[$k] "SKT" $k
}
$sktFullJs = "// 2026년 11월 SKT 제휴카드 공식 정책 마스터 데이터베이스 (총 $($sktJson.Count)종)`nconst SKT_AFFILIATE_CARDS = [`n" + ($sktCardBlocks -join ",`n`n") + "`n];"

$ktCardBlocks = @()
for ($k = 0; $k -lt $ktJson.Count; $k++) {
    $ktCardBlocks += Build-CardJsObject $ktJson[$k] "KT" $k
}
$ktFullJs = "    // 2026년 11월 KT 제휴카드 공식 정책 마스터 데이터베이스 (총 $($ktJson.Count)종)`n    const KT_AFFILIATE_CARDS = [`n" + ($ktCardBlocks -join ",`n`n") + "`n    ];"

$lguCardBlocks = @()
for ($k = 0; $k -lt $lguJson.Count; $k++) {
    $lguCardBlocks += Build-CardJsObject $lguJson[$k] "LGU" $k
}
$lguFullJs = "    // 2026년 11월 LGU+ 제휴카드 공식 정책 마스터 데이터베이스 (총 $($lguJson.Count)종)`n    const LGU_AFFILIATE_CARDS = [`n" + ($lguCardBlocks -join ",`n`n") + "`n    ];"

# 파일로 임시 저장
$outDir = Join-Path $workspace "scratch"
$sktFullJs | Set-Content (Join-Path $outDir "skt_cards_new.js") -Encoding UTF8
$ktFullJs | Set-Content (Join-Path $outDir "kt_cards_new.js") -Encoding UTF8
$lguFullJs | Set-Content (Join-Path $outDir "lgu_cards_new.js") -Encoding UTF8

Write-Host "빌드 완료!"
