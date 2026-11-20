# scripts/build_kt_and_lgu_datasets.ps1
$ErrorActionPreference = "Stop"

# 1. LGU+ 12종 데이터셋 (사용자 제공 11월 공식 PDF 기반 정밀 파싱)
$lguCards = @(
    @{
        card_company = "신한카드"
        card_name = "신한카드 스마트플랜 Plus"
        card_plate_image = "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/f112e452-f67f-4c8d-8d99-52e8d35fbf63"
        target_telecom = "LGU+"
        target_device = "전 단말기"
        min_installment_amount = "5만원 이상"
        autopay_required = $true
        annual_fee = @{ domestic = "22,000원"; overseas = "Master 25,000원" }
        installment_interest = @{ "24_months" = "5.9%"; "36_months" = "미지원" }
        discount_tiers = @(
            @{ required_performance = "30만원 이상"; base_discount = 10000; promo_discount = 12000; total_monthly_discount = 22000; benefit_duration = "24개월" },
            @{ required_performance = "70만원 이상"; base_discount = 15000; promo_discount = 9000; total_monthly_discount = 24000; benefit_duration = "24개월" }
        )
        special_promo = "최대 57.6만원 할인 (Master 브랜드 발급 한정)"
        performance_criteria = @{
            included = @("통신비 인정", "아파트 관리비 인정")
            excluded = @("각종 수수료/이자", "연회비", "4대보험")
        }
        base_card_benefits = @()
        promo_target_condition = "행사월 기준 6개월 이상 당사 무실적 고객 (Master 브랜드 한정)"
        urls = @{
            apply_url = "tel:080-700-3103"
            promo_url = "http://m.site.naver.com/0JM2M"
        }
    },
    @{
        card_company = "신한카드"
        card_name = "신한카드 U+ Bora"
        card_plate_image = "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/8977114b-2dfd-4a11-827c-9b578c94625b"
        target_telecom = "LGU+"
        target_device = "전 단말기"
        min_installment_amount = "5만원 이상"
        autopay_required = $true
        annual_fee = @{ domestic = "22,000원"; overseas = "Master 25,000원" }
        installment_interest = @{ "24_months" = "5.9%"; "36_months" = "미지원" }
        discount_tiers = @(
            @{ required_performance = "40만원 이상"; base_discount = 10000; promo_discount = 12000; total_monthly_discount = 22000; benefit_duration = "24개월" },
            @{ required_performance = "80만원 이상"; base_discount = 15000; promo_discount = 9000; total_monthly_discount = 24000; benefit_duration = "24개월" }
        )
        special_promo = "최대 57.6만원 할인 (Master 브랜드 한정)"
        performance_criteria = @{
            included = @("통신비 인정", "아파트 관리비 인정")
            excluded = @("각종 수수료/이자", "연회비", "4대보험")
        }
        base_card_benefits = @()
        promo_target_condition = "행사월 기준 6개월 이상 당사 무실적 고객 (Master 브랜드 한정)"
        urls = @{
            apply_url = "tel:080-850-8853"
            promo_url = "http://m.site.naver.com/0JM2M"
        }
    },
    @{
        card_company = "KB국민카드"
        card_name = "LGU+ 라이트할부Ⅱ KB국민카드"
        card_plate_image = "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/2425de02-e741-4b82-84c1-947049d1b989"
        target_telecom = "LGU+"
        target_device = "전 단말기 (아이폰18/DUO 최대 10만 캐시백)"
        min_installment_amount = "5만원 이상"
        autopay_required = $false
        annual_fee = @{ domestic = "20,000원"; overseas = "20,000원" }
        installment_interest = @{ "24_months" = "5.9%"; "36_months" = "7.0%" }
        discount_tiers = @(
            @{ required_performance = "30만원 이상"; base_discount = 4000; promo_discount = 21000; total_monthly_discount = 25000; benefit_duration = "24개월" },
            @{ required_performance = "70만원 이상"; base_discount = 4000; promo_discount = 22000; total_monthly_discount = 26000; benefit_duration = "24개월" },
            @{ required_performance = "100만원 이상"; base_discount = 4000; promo_discount = 23000; total_monthly_discount = 27000; benefit_duration = "24개월" }
        )
        special_promo = "아이폰18/아이폰DUO 구매 시 최대 10만원 추가 캐시백 (총 최대 64.8만원 할인)"
        performance_criteria = @{
            included = @("통신비 인정")
            excluded = @("아파트 관리비 제외", "무이자할부", "단기/장기카드대출", "연회비", "제수수료")
        }
        base_card_benefits = @()
        promo_target_condition = "행사월 기준 6개월 이상 당사 무실적 고객 (장기할부 5만원 이상 필수)"
        urls = @{
            apply_url = "https://card.kbcard.com/cards/products/credit-cards?benefit=telecom"
            promo_url = "http://m.site.naver.com/18fKy"
        }
    },
    @{
        card_company = "현대카드"
        card_name = "M Edition 3 (통신할인형 2.0)"
        card_plate_image = "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/46d651ec-5640-421d-b78a-cc09054e04e6"
        target_telecom = "LGU+"
        target_device = "전 단말기"
        min_installment_amount = "5만원 이상"
        autopay_required = $true
        annual_fee = @{ domestic = "20,000원"; overseas = "20,000원" }
        installment_interest = @{ "24_months" = "5.8%"; "36_months" = "미지원" }
        discount_tiers = @(
            @{ required_performance = "50만원 이상"; base_discount = 15000; promo_discount = 19000; total_monthly_discount = 34000; benefit_duration = "24개월" },
            @{ required_performance = "100만원 이상"; base_discount = 25000; promo_discount = 10000; total_monthly_discount = 35000; benefit_duration = "24개월" }
        )
        special_promo = "최대 84만원 할인 (이벤트 응모 필수)"
        performance_criteria = @{
            included = @()
            excluded = @("통신비 제외", "아파트 관리비 제외", "학교납입금 제외", "무이자할부")
        }
        base_card_benefits = @("Apple Pay 지원", "M포인트 기본 적립")
        promo_target_condition = "행사월 기준 6개월 이상 당사 무실적 고객 (자동이체 필수, 이벤트 응모 필수)"
        urls = @{
            apply_url = "https://www.hyundaicard.com/cpc/ma/CPCMA0101_01.hc?cardflag=J"
            promo_url = "http://m.site.naver.com/0QwRn"
        }
    },
    @{
        card_company = "우리카드"
        card_name = "U+ x 36우리카드"
        card_plate_image = "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/8e4587ba-ef34-451d-b8da-75bdfd27806a"
        target_telecom = "LGU+"
        target_device = "전 단말기"
        min_installment_amount = "10만원 이상"
        autopay_required = $true
        annual_fee = @{ domestic = "25,000원"; overseas = "25,000원" }
        installment_interest = @{ "24_months" = "5.9%"; "36_months" = "7.0%" }
        discount_tiers = @(
            @{ required_performance = "40만원 이상"; base_discount = 5000; promo_discount = 19000; total_monthly_discount = 24000; benefit_duration = "36개월" },
            @{ required_performance = "80만원 이상"; base_discount = 5000; promo_discount = 24000; total_monthly_discount = 29000; benefit_duration = "36개월" },
            @{ required_performance = "120만원 이상"; base_discount = 5000; promo_discount = 26000; total_monthly_discount = 31000; benefit_duration = "36개월" }
        )
        special_promo = "최대 111.6만원 할인 (36개월 기준, 동일카드 탈회 1년 미경과 시 제외)"
        performance_criteria = @{
            included = @("통신비 인정")
            excluded = @("아파트 관리비 제외", "무이자할부")
        }
        base_card_benefits = @()
        promo_target_condition = "행사월 기준 6개월 이상 당사 무실적 고객 (동일카드 탈회 1년 이상 경과 회원)"
        urls = @{
            apply_url = "https://pc.wooricard.com"
            promo_url = "https://m.wooricard.com"
        }
    },
    @{
        card_company = "삼성카드"
        card_name = "LG U+ 삼성카드"
        card_plate_image = "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/3541547b-0d33-48f2-b5f6-571644d55899"
        target_telecom = "LGU+"
        target_device = "전 단말기"
        min_installment_amount = "10만원 이상"
        autopay_required = $true
        annual_fee = @{ domestic = "20,000원"; overseas = "20,000원" }
        installment_interest = @{ "24_months" = "5.9%"; "36_months" = "미지원" }
        discount_tiers = @(
            @{ required_performance = "30만원 이상"; base_discount = 7000; promo_discount = 13000; total_monthly_discount = 20000; benefit_duration = "24개월" },
            @{ required_performance = "70만원 이상"; base_discount = 10000; promo_discount = 11000; total_monthly_discount = 21000; benefit_duration = "24개월" },
            @{ required_performance = "120만원 이상"; base_discount = 13000; promo_discount = 9000; total_monthly_discount = 22000; benefit_duration = "24개월" }
        )
        special_promo = "최대 52.8만원 할인 (가족카드 발급 불가)"
        performance_criteria = @{
            included = @("통신비 인정")
            excluded = @("아파트 관리비 제외", "학교납입금&교통비 제외", "무이자할부")
        }
        base_card_benefits = @()
        promo_target_condition = "행사월 기준 6개월 이상 당사 무실적 고객"
        urls = @{
            apply_url = "tel:1800-1068"
            promo_url = "http://m.site.naver.com/0JM14"
        }
    },
    @{
        card_company = "삼성카드"
        card_name = "U+ 라이트 삼성카드"
        card_plate_image = "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/3541547b-0d33-48f2-b5f6-571644d55899"
        target_telecom = "LGU+"
        target_device = "전 단말기"
        min_installment_amount = "10만원 이상"
        autopay_required = $false
        annual_fee = @{ domestic = "25,000원"; overseas = "25,000원" }
        installment_interest = @{ "24_months" = "5.9%"; "36_months" = "7.0%" }
        discount_tiers = @(
            @{ required_performance = "40만원 이상"; base_discount = 3000; promo_discount = 19000; total_monthly_discount = 22000; benefit_duration = "36개월" },
            @{ required_performance = "80만원 이상"; base_discount = 5000; promo_discount = 18000; total_monthly_discount = 23000; benefit_duration = "36개월" },
            @{ required_performance = "120만원 이상"; base_discount = 8000; promo_discount = 16000; total_monthly_discount = 24000; benefit_duration = "36개월" }
        )
        special_promo = "최대 86.4만원 할인 (JCB 브랜드 발급 시 2.5만원 캐시백 추가)"
        performance_criteria = @{
            included = @("통신비 인정")
            excluded = @("아파트 관리비 제외", "학교납입금&교통비 제외", "무이자할부")
        }
        base_card_benefits = @()
        promo_target_condition = "행사월 기준 6개월 이상 당사 무실적 고객 (라이트할부 필수)"
        urls = @{
            apply_url = "https://www.samsungcard.com"
            promo_url = "http://m.site.naver.com/0JM14"
        }
    },
    @{
        card_company = "롯데카드"
        card_name = "U+ x LOCA 라이트할부"
        card_plate_image = "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/3dab1f98-3e05-4452-bc7f-54574612b7e3"
        target_telecom = "LGU+"
        target_device = "전 단말기"
        min_installment_amount = "10만원 이상"
        autopay_required = $false
        annual_fee = @{ domestic = "25,000원"; overseas = "25,000원" }
        installment_interest = @{ "24_months" = "5.9%"; "36_months" = "미지원" }
        discount_tiers = @(
            @{ required_performance = "50만원 이상"; base_discount = 10000; promo_discount = 24000; total_monthly_discount = 34000; benefit_duration = "24개월" },
            @{ required_performance = "100만원 이상"; base_discount = 15000; promo_discount = 20000; total_monthly_discount = 35000; benefit_duration = "24개월" }
        )
        special_promo = "최대 84만원 할인 (가족카드 발급 불가)"
        performance_criteria = @{
            included = @("통신비 인정")
            excluded = @("아파트 관리비 제외", "무이자할부")
        }
        base_card_benefits = @("롯데백화점 5% 할인 e-쿠폰")
        promo_target_condition = "행사월 기준 6개월 이상 당사 무실적 고객 (라이트할부 필수)"
        urls = @{
            apply_url = "https://www.lottecard.co.kr"
            promo_url = "http://s.lottecard.co.kr/1vkTrqN"
        }
    },
    @{
        card_company = "롯데카드"
        card_name = "U+ DC 롯데카드 (New)"
        card_plate_image = "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/3dab1f98-3e05-4452-bc7f-54574612b7e3"
        target_telecom = "LGU+"
        target_device = "전 단말기 (요금할인형)"
        min_installment_amount = "해당없음 (장기할부 불가)"
        autopay_required = $true
        annual_fee = @{ domestic = "25,000원"; overseas = "25,000원" }
        installment_interest = @{ "24_months" = "해당없음"; "36_months" = "해당없음" }
        discount_tiers = @(
            @{ required_performance = "40만원 이상"; base_discount = 5000; promo_discount = 23000; total_monthly_discount = 28000; benefit_duration = "24개월" },
            @{ required_performance = "80만원 이상"; base_discount = 8000; promo_discount = 21000; total_monthly_discount = 29000; benefit_duration = "24개월" }
        )
        special_promo = "신규 출시 (New) 최대 69.6만원 할인"
        performance_criteria = @{
            included = @()
            excluded = @("통신비 제외", "아파트 관리비 제외", "학교납입금&교통비 제외", "무이자할부")
        }
        base_card_benefits = @()
        promo_target_condition = "행사월 기준 6개월 이상 당사 무실적 고객 (자동이체 필수)"
        urls = @{
            apply_url = "https://www.lottecard.co.kr"
            promo_url = "http://s.lottecard.co.kr/1vkTrqN"
        }
    },
    @{
        card_company = "롯데카드"
        card_name = "LG U+ x LOCA"
        card_plate_image = "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/3dab1f98-3e05-4452-bc7f-54574612b7e3"
        target_telecom = "LGU+"
        target_device = "전 단말기"
        min_installment_amount = "5만원 이상"
        autopay_required = $true
        annual_fee = @{ domestic = "20,000원"; overseas = "20,000원" }
        installment_interest = @{ "24_months" = "7.0%"; "36_months" = "7.0%" }
        discount_tiers = @(
            @{ required_performance = "30만원 이상"; base_discount = 6000; promo_discount = 14000; total_monthly_discount = 20000; benefit_duration = "36개월" },
            @{ required_performance = "70만원 이상"; base_discount = 8000; promo_discount = 13000; total_monthly_discount = 21000; benefit_duration = "36개월" },
            @{ required_performance = "120만원 이상"; base_discount = 10000; promo_discount = 12000; total_monthly_discount = 22000; benefit_duration = "36개월" }
        )
        special_promo = "최대 79.2만원 할인 (36개월 기준)"
        performance_criteria = @{
            included = @()
            excluded = @("통신비 제외", "아파트 관리비 제외", "학교납입금&교통비 제외", "무이자할부")
        }
        base_card_benefits = @()
        promo_target_condition = "행사월 기준 6개월 이상 당사 무실적 고객 (자동이체 필수)"
        urls = @{
            apply_url = "https://www.lottecard.co.kr"
            promo_url = "http://s.lottecard.co.kr/1vkTrqN"
        }
    },
    @{
        card_company = "하나카드"
        card_name = "LG U+ family 카드"
        card_plate_image = "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/180a373b-eb63-4fe6-a947-66a9baef4db7"
        target_telecom = "LGU+"
        target_device = "전 단말기"
        min_installment_amount = "10만원 이상"
        autopay_required = $true
        annual_fee = @{ domestic = "Master/UPI 25,000원"; overseas = "AMEX 30,000원" }
        installment_interest = @{ "24_months" = "5.9%"; "36_months" = "미지원" }
        discount_tiers = @(
            @{ required_performance = "30만원 이상"; base_discount = 17000; promo_discount = 7000; total_monthly_discount = 24000; benefit_duration = "24개월" },
            @{ required_performance = "70만원 이상"; base_discount = 25000; promo_discount = 0; total_monthly_discount = 25000; benefit_duration = "24개월" }
        )
        special_promo = "최대 60만원 할인 (1~24개월차 통신요금 25% 할인, 25개월차부터 15% 할인)"
        performance_criteria = @{
            included = @()
            excluded = @("통신비 제외", "아파트 관리비 제외", "학교납입금 제외", "무이자할부")
        }
        base_card_benefits = @()
        promo_target_condition = "행사월 기준 6개월 이상 당사 무실적 고객 (자동이체 필수)"
        urls = @{
            apply_url = "tel:1800-4701"
            promo_url = "http://m.site.naver.com/10gtl"
        }
    },
    @{
        card_company = "NH농협카드"
        card_name = "올원"
        card_plate_image = "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/4cd89ee3-7ee6-4e5a-a43b-31d7e2e8e925"
        target_telecom = "LGU+"
        target_device = "전 단말기"
        min_installment_amount = "해당없음"
        autopay_required = $true
        annual_fee = @{ domestic = "15,000원 (W)"; overseas = "Master 17,000원" }
        installment_interest = @{ "24_months" = "해당없음"; "36_months" = "해당없음" }
        discount_tiers = @(
            @{ required_performance = "30만원 이상"; base_discount = 9000; promo_discount = 12000; total_monthly_discount = 21000; benefit_duration = "24개월" },
            @{ required_performance = "70만원 이상"; base_discount = 15000; promo_discount = 12000; total_monthly_discount = 27000; benefit_duration = "24개월" }
        )
        special_promo = "최대 64.8만원 할인"
        performance_criteria = @{
            included = @()
            excluded = @("통신비 제외", "아파트 관리비 제외", "학교납입금 제외", "무이자할부")
        }
        base_card_benefits = @()
        promo_target_condition = "행사월 기준 6개월 이상 당사 무실적 고객 (자동이체 필수)"
        urls = @{
            apply_url = "https://nhpay.nonghyup.com"
            promo_url = "http://m.site.naver.com/0JM3W"
        }
    }
)

$lguJson = $lguCards | ConvertTo-Json -Depth 10
Set-Content -Path "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\ground_truth_lgu_202611.json" -Value $lguJson -Encoding UTF8
Write-Host "✅ LG U+ 11월 공식 12종 제휴카드 데이터셋 생성 완료! (Count: $($lguCards.Count))"
