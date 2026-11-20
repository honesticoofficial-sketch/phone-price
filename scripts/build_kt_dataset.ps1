# scripts/build_kt_dataset.ps1
$ErrorActionPreference = "Stop"

$ktCards = @(
    @{
        card_company = "롯데카드"
        card_name = "KT 할부 롯데카드"
        card_plate_image = "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/3dab1f98-3e05-4452-bc7f-54574612b7e3"
        target_telecom = "KT"
        target_device = "전 단말기"
        min_installment_amount = "5만원 이상"
        autopay_required = $false
        annual_fee = @{ domestic = "25,000원"; overseas = "Master/Amex 25,000원" }
        installment_interest = @{ "24_months" = "5.9%"; "36_months" = "미지원" }
        discount_tiers = @(
            @{ required_performance = "50만원 이상"; base_discount = 8000; promo_discount = 26000; total_monthly_discount = 34000; benefit_duration = "24개월" },
            @{ required_performance = "100만원 이상"; base_discount = 10000; promo_discount = 25000; total_monthly_discount = 35000; benefit_duration = "24개월" }
        )
        special_promo = "최대 3.4만 / 3.5만원 24개월 캐시백"
        performance_criteria = @{
            included = @("통신비 인정")
            excluded = @("아파트 관리비 제외", "무이자할부")
        }
        base_card_benefits = @("롯데백화점 5% 할인 e-쿠폰")
        promo_target_condition = "직전 6개월(26.5.1~26.10.31) 무실적 고객 (장기할부 수납 완료 시)"
        urls = @{
            apply_url = "http://m.lottecard.co.kr/spa/card/booth?bId=106378&vtCdKndC=P15912-A15912"
            promo_url = "http://s.lottecard.co.kr/1vkTrqN"
        }
    },
    @{
        card_company = "BC바로카드"
        card_name = "KT SUPER DC BC바로카드"
        card_plate_image = "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/3541547b-0d33-48f2-b5f6-571644d55899"
        target_telecom = "KT"
        target_device = "전 단말기"
        min_installment_amount = "10만원 이상"
        autopay_required = $true
        annual_fee = @{ domestic = "25,000원"; overseas = "Master 25,000원" }
        installment_interest = @{ "24_months" = "5.9%"; "36_months" = "7.0%" }
        discount_tiers = @(
            @{ required_performance = "40만원 이상"; base_discount = 5000; promo_discount = 8000; total_monthly_discount = 13000; benefit_duration = "24개월" },
            @{ required_performance = "80만원 이상"; base_discount = 5000; promo_discount = 9000; total_monthly_discount = 14000; benefit_duration = "24개월" },
            @{ required_performance = "120만원 이상"; base_discount = 5000; promo_discount = 10000; total_monthly_discount = 15000; benefit_duration = "24개월" }
        )
        special_promo = "자동납부 통신비 1.5만원 이상 시 추가할인"
        performance_criteria = @{
            included = @("통신비 인정")
            excluded = @("아파트 관리비 제외", "무이자할부")
        }
        base_card_benefits = @()
        promo_target_condition = "직전 6개월 무실적 고객 (통신비 자동납부 필수)"
        urls = @{
            apply_url = "https://www.bccard.com"
            promo_url = "http://m.site.naver.com/0JM3W"
        }
    },
    @{
        card_company = "삼성카드"
        card_name = "KT 할부 S 삼성카드"
        card_plate_image = "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/3541547b-0d33-48f2-b5f6-571644d55899"
        target_telecom = "KT"
        target_device = "전 단말기"
        min_installment_amount = "10만원 이상"
        autopay_required = $false
        annual_fee = @{ domestic = "25,000원"; overseas = "Master 25,000원" }
        installment_interest = @{ "24_months" = "5.9%"; "36_months" = "7.0%" }
        discount_tiers = @(
            @{ required_performance = "40만원 이상"; base_discount = 10000; promo_discount = 12000; total_monthly_discount = 22000; benefit_duration = "24개월" },
            @{ required_performance = "80만원 이상"; base_discount = 15000; promo_discount = 8000; total_monthly_discount = 23000; benefit_duration = "24개월" },
            @{ required_performance = "120만원 이상"; base_discount = 20000; promo_discount = 4000; total_monthly_discount = 24000; benefit_duration = "24개월" }
        )
        special_promo = "최대 2.2만/2.3만/2.4만원 할인"
        performance_criteria = @{
            included = @("대중교통", "택시")
            excluded = @("무이자할부", "단기/장기카드대출", "연회비")
        }
        base_card_benefits = @("커피전문점 5% 할인", "배달앱 5% 할인")
        promo_target_condition = "직전 6개월 동안 삼성개인신용카드 결제이력 없는 회원 (라이트할부 10만원 이상)"
        urls = @{
            apply_url = "https://www.samsungcard.com"
            promo_url = "http://m.site.naver.com/0JM14"
        }
    },
    @{
        card_company = "KB국민카드"
        card_name = "KT 할부 Plus KB국민카드"
        card_plate_image = "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/2425de02-e741-4b82-84c1-947049d1b989"
        target_telecom = "KT"
        target_device = "전 단말기"
        min_installment_amount = "5만원 이상"
        autopay_required = $false
        annual_fee = @{ domestic = "20,000원"; overseas = "Master/JCB 20,000원" }
        installment_interest = @{ "24_months" = "5.9%"; "36_months" = "7.0%" }
        discount_tiers = @(
            @{ required_performance = "30만원 이상"; base_discount = 8000; promo_discount = 17000; total_monthly_discount = 25000; benefit_duration = "24개월" },
            @{ required_performance = "70만원 이상"; base_discount = 12000; promo_discount = 14000; total_monthly_discount = 26000; benefit_duration = "24개월" },
            @{ required_performance = "100만원 이상"; base_discount = 14000; promo_discount = 13000; total_monthly_discount = 27000; benefit_duration = "24개월" }
        )
        special_promo = "최대 2.5만/2.6만/2.7만원 24개월 할인"
        performance_criteria = @{
            included = @("통신비 인정")
            excluded = @("아파트 관리비 제외", "무이자할부")
        }
        base_card_benefits = @()
        promo_target_condition = "직전 6개월 무실적 고객 (단말기 약정 결제 완료 시)"
        urls = @{
            apply_url = "https://m.kbcard.com/CRD/DVIEW/MCAMCXHIACRC0002?mainCC=b&allianceCode=01507&solicitorcode=7021507000"
            promo_url = "http://m.site.naver.com/18fKy"
        }
    },
    @{
        card_company = "롯데카드"
        card_name = "KT DC 롯데카드"
        card_plate_image = "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/3dab1f98-3e05-4452-bc7f-54574612b7e3"
        target_telecom = "KT"
        target_device = "전 단말기 (요금할인형)"
        min_installment_amount = "해당없음"
        autopay_required = $true
        annual_fee = @{ domestic = "25,000원"; overseas = "Master/Amex 25,000원" }
        installment_interest = @{ "24_months" = "해당없음"; "36_months" = "해당없음" }
        discount_tiers = @(
            @{ required_performance = "40만원 이상"; base_discount = 5000; promo_discount = 23000; total_monthly_discount = 28000; benefit_duration = "24개월" },
            @{ required_performance = "80만원 이상"; base_discount = 8000; promo_discount = 21000; total_monthly_discount = 29000; benefit_duration = "24개월" }
        )
        special_promo = "요금할인형 최대 2.9만원 할인"
        performance_criteria = @{
            included = @()
            excluded = @("통신비 제외", "아파트 관리비 제외", "학교납입금&교통비 제외", "무이자할부")
        }
        base_card_benefits = @()
        promo_target_condition = "직전 6개월 무실적 고객 (자동이체 필수)"
        urls = @{
            apply_url = "https://www.lottecard.co.kr"
            promo_url = "http://s.lottecard.co.kr/1vkTrqN"
        }
    }
)

$ktJson = $ktCards | ConvertTo-Json -Depth 10
Set-Content -Path "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\ground_truth_kt_202611.json" -Value $ktJson -Encoding UTF8
Write-Host "✅ KT 11월 세이브드림 기반 제휴카드 데이터셋 생성 완료! (Count: $($ktCards.Count))"
