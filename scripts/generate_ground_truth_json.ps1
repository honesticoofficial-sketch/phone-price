# scripts/generate_ground_truth_json.ps1
$ErrorActionPreference = "Stop"

$sktCards = @(
    @{
        card_company = "삼성카드"
        card_name = "삼성카드 T PREMIUM"
        card_plate_image = "https://static21.samsungcard.com/wcms/home/scard/image/personal/AAP1869_p.gif"
        target_telecom = "SKT"
        target_device = "전 단말기"
        min_installment_amount = "50만원 이상"
        autopay_required = $false
        annual_fee = @{
            domestic = "50,000원"
            overseas = "50,000원 (AMEX)"
        }
        installment_interest = @{
            "24_months" = "5.9%"
            "36_months" = "7.0%"
        }
        discount_tiers = @(
            @{ required_performance = "80만원 이상"; base_discount = 25000; promo_discount = 10000; total_monthly_discount = 35000; benefit_duration = "24개월" },
            @{ required_performance = "160만원 이상"; base_discount = 40000; promo_discount = 10000; total_monthly_discount = 50000; benefit_duration = "24개월" },
            @{ required_performance = "250만원 이상"; base_discount = 60000; promo_discount = 10000; total_monthly_discount = 70000; benefit_duration = "24개월" }
        )
        special_promo = $null
        performance_criteria = @{
            included = @("대중교통", "택시", "SKT 통신요금")
            excluded = @("무이자할부", "단기카드대출(현금서비스)", "장기카드대출(카드론)", "각종 수수료 및 이자", "연체료", "연회비", "아파트 관리비", "대학 등록금", "상품권 구매", "기프트/선불카드 충전", "국세/지방세/공과금", "4대보험")
        }
        base_card_benefits = @("해외 5% 결제일할인", "여행/항공 3% 결제일할인")
        promo_target_condition = "삼성카드 신규 또는 행사월 기준 6개월 이상 무실적 고객 (과거 해당 카드 청구할인 수혜 이력 없는 고객)"
        urls = @{
            apply_url = "https://www.samsungcard.com/home/card/cardinfo/PGHPPCCCardCardinfoDetails001?code=AAP1869"
            promo_url = $null
        }
    },
    @{
        card_company = "현대카드"
        card_name = "현대카드 M3 T라이트2"
        card_plate_image = ""
        target_telecom = "SKT"
        target_device = "전 단말기"
        min_installment_amount = "5만원 이상"
        autopay_required = $false
        annual_fee = @{
            domestic = "20,000원"
            overseas = "20,000원 (국내, VISA, AMEX)"
        }
        installment_interest = @{
            "24_months" = "5.8%"
            "36_months" = "불가"
        }
        discount_tiers = @(
            @{ required_performance = "50만원 이상"; base_discount = 15000; promo_discount = 18000; total_monthly_discount = 33000; benefit_duration = "24개월" },
            @{ required_performance = "100만원 이상"; base_discount = 25000; promo_discount = 10000; total_monthly_discount = 35000; benefit_duration = "24개월" }
        )
        special_promo = "SKT x 현대카드 쿠폰팩 프로모션 (투썸/다이소/CU/올리브영/포인트샵 쿠폰 월 최대 22,700원)"
        performance_criteria = @{
            included = @()
            excluded = @("무이자할부", "장/단기카드대출", "연회비", "제수수료", "이자", "아파트관리비", "초중고대학(원) 등록금", "고속도로 통행요금", "후불하이패스", "SKT 라이트할부", "상품권 등 현금성 유가증권", "선불카드 충전", "공과금/4대보험", "전기/도시가스요금")
        }
        base_card_benefits = @("코스트코 이용 가능", "25개월 차부터 50만원 이상 시 0.5~3% M포인트 적립")
        promo_target_condition = "현대카드 신규 또는 행사월 기준 6개월 이상 무실적 고객 (M3 T라이트2 최초 발급)"
        urls = @{
            apply_url = "http://m.site.naver.com/0QwRn"
            promo_url = "http://m.site.naver.com/0QwRn"
        }
    },
    @{
        card_company = "NH농협카드"
        card_name = "NH카드 T라이트"
        card_plate_image = ""
        target_telecom = "SKT"
        target_device = "전 단말기"
        min_installment_amount = "5만원 이상"
        autopay_required = $false
        annual_fee = @{
            domestic = "15,000원"
            overseas = "17,000원 (VISA)"
        }
        installment_interest = @{
            "24_months" = "5.9%"
            "36_months" = "7.0%"
        }
        discount_tiers = @(
            @{ required_performance = "40만원 이상"; base_discount = 11000; promo_discount = 12000; total_monthly_discount = 23000; benefit_duration = "24개월" },
            @{ required_performance = "80만원 이상"; base_discount = 17000; promo_discount = 12000; total_monthly_discount = 29000; benefit_duration = "24개월" }
        )
        special_promo = $null
        performance_criteria = @{
            included = @()
            excluded = @("모든 무이자할부", "단기카드대출", "장기카드대출", "연회비", "각종 수수료", "공공임대료", "대학등록금", "택시", "고속버스", "대중교통", "상품권", "국세/지방세", "4대보험", "도시가스/전기/수도")
        }
        base_card_benefits = @("커피 1천원 청구할인", "베이커리/아이스크림 1천원 청구할인", "영화 1천원 청구할인", "전국 주요놀이공원 50% 현장할인")
        promo_target_condition = "NH농협카드 신규 또는 행사월 기준 6개월 이상 무실적 고객"
        urls = @{
            apply_url = "http://m.site.naver.com/0JM3W"
            promo_url = "http://m.site.naver.com/0JM3W"
        }
    },
    @{
        card_company = "삼성카드"
        card_name = "삼성카드 T라이트"
        card_plate_image = ""
        target_telecom = "SKT"
        target_device = "삼성전자 갤럭시 단말 (태블릿, 키즈폰 포함)"
        min_installment_amount = "10만원 이상"
        autopay_required = $false
        annual_fee = @{
            domestic = "25,000원"
            overseas = "25,000원 (국내, VISA)"
        }
        installment_interest = @{
            "24_months" = "5.9%"
            "36_months" = "7.0%"
        }
        discount_tiers = @(
            @{ required_performance = "40만원 이상"; base_discount = 10000; promo_discount = 12000; total_monthly_discount = 22000; benefit_duration = "24개월" },
            @{ required_performance = "80만원 이상"; base_discount = 15000; promo_discount = 8000; total_monthly_discount = 23000; benefit_duration = "24개월" },
            @{ required_performance = "120만원 이상"; base_discount = 20000; promo_discount = 4000; total_monthly_discount = 24000; benefit_duration = "24개월" }
        )
        special_promo = $null
        performance_criteria = @{
            included = @("대중교통", "택시")
            excluded = @("무이자할부", "단기카드대출", "장기카드대출", "연회비", "수수료", "아파트관리비", "대학등록금", "상품권", "국세/지방세/공과금", "4대보험")
        }
        base_card_benefits = @("커피전문점 5% 결제일 청구할인", "편의점/배달앱 5% 결제일 청구할인")
        promo_target_condition = "삼성카드 신규 또는 행사월 기준 6개월 이상 무실적 고객 (삼성전자 갤럭시 단말 한정)"
        urls = @{
            apply_url = "http://m.site.naver.com/0JM14"
            promo_url = "http://m.site.naver.com/0JM14"
        }
    },
    @{
        card_company = "하나카드"
        card_name = "하나카드 T다운"
        card_plate_image = ""
        target_telecom = "SKT"
        target_device = "전 단말기"
        min_installment_amount = "5만원 이상"
        autopay_required = $false
        annual_fee = @{
            domestic = "25,000원"
            overseas = "25,000원 (국내, Master)"
        }
        installment_interest = @{
            "24_months" = "5.9%"
            "36_months" = "7.0%"
        }
        discount_tiers = @(
            @{ required_performance = "40만원 이상"; base_discount = 10000; promo_discount = 10000; total_monthly_discount = 20000; benefit_duration = "24개월" },
            @{ required_performance = "80만원 이상"; base_discount = 15000; promo_discount = 10000; total_monthly_discount = 25000; benefit_duration = "24개월" }
        )
        special_promo = $null
        performance_criteria = @{
            included = @()
            excluded = @("무이자할부", "아파트관리비", "초중고 납입금", "대학등록금", "상품권", "기프트카드", "국세/지방세/공과금", "4대보험", "수도/전기/도시가스")
        }
        base_card_benefits = @()
        promo_target_condition = "하나카드 신규 또는 행사월 기준 6개월 이상 무실적 고객"
        urls = @{
            apply_url = "http://m.site.naver.com/10gtl"
            promo_url = "http://m.site.naver.com/10gtl"
        }
    },
    @{
        card_company = "우리카드"
        card_name = "우리카드 T라이트"
        card_plate_image = ""
        target_telecom = "SKT"
        target_device = "전 단말기"
        min_installment_amount = "10만원 이상"
        autopay_required = $false
        annual_fee = @{
            domestic = "25,000원"
            overseas = "25,000원 (국내, VISA, Master)"
        }
        installment_interest = @{
            "24_months" = "5.9%"
            "36_months" = "7.0%"
        }
        discount_tiers = @(
            @{ required_performance = "40만원 이상"; base_discount = 10000; promo_discount = 14000; total_monthly_discount = 24000; benefit_duration = "24개월" },
            @{ required_performance = "80만원 이상"; base_discount = 15000; promo_discount = 14000; total_monthly_discount = 29000; benefit_duration = "24개월" },
            @{ required_performance = "120만원 이상"; base_discount = 20000; promo_discount = 11000; total_monthly_discount = 31000; benefit_duration = "24개월" }
        )
        special_promo = $null
        performance_criteria = @{
            included = @()
            excluded = @("무이자할부", "단기카드대출", "장기카드대출", "수수료", "아파트관리비", "정부지원금", "대학등록금", "교통카드충전", "상품권", "국세/지방세/공공요금")
        }
        base_card_benefits = @()
        promo_target_condition = "우리카드 신규 또는 행사월 기준 6개월 이상 무실적 고객"
        urls = @{
            apply_url = "https://m.wooricard.com/dcmw/yh1/crd/crd01/M1CRD101S02.do?cdPrdCd=103749&canvasser=88936105"
            promo_url = "https://m.wooricard.com/dcmw/yh1/crd/crd01/M1CRD101S02.do?cdPrdCd=103749&canvasser=88936105"
        }
    },
    @{
        card_company = "KB국민카드"
        card_name = "T라이트 KB국민카드"
        card_plate_image = ""
        target_telecom = "SKT"
        target_device = "전 단말기 (아이폰18/DUO 캐시백 추가)"
        min_installment_amount = "5만원 이상"
        autopay_required = $false
        annual_fee = @{
            domestic = "20,000원"
            overseas = "20,000원 (국내, JCB, Master)"
        }
        installment_interest = @{
            "24_months" = "5.9%"
            "36_months" = "7.0%"
        }
        discount_tiers = @(
            @{ required_performance = "30만원 이상"; base_discount = 8000; promo_discount = 17000; total_monthly_discount = 25000; benefit_duration = "24개월" },
            @{ required_performance = "70만원 이상"; base_discount = 12000; promo_discount = 14000; total_monthly_discount = 26000; benefit_duration = "24개월" },
            @{ required_performance = "100만원 이상"; base_discount = 14000; promo_discount = 13000; total_monthly_discount = 27000; benefit_duration = "24개월" }
        )
        special_promo = "아이폰18/DUO 개통 고객 최대 10만원 캐시백 (60만원 이상 할부 시 8만원 + KBPay 2만원 결제 시 2만원)"
        performance_criteria = @{
            included = @()
            excluded = @("무이자할부", "단기카드대출", "장기카드대출", "수수료", "연회비", "취소금액", "아파트관리비", "초중고 납입금", "정부지원금", "대학(원)등록금", "무승인전표", "상품권/선불카드 구입충전", "국세/지방세/공과금", "4대보험", "도시가스")
        }
        base_card_benefits = @("정기결제 이용건수에 따라 월 최대 3,000원 추가 할인 (아파트관리비 2천원, 4대보험/도시가스/전기 1천원)")
        promo_target_condition = "KB국민카드 신규 또는 행사월 기준 6개월 이상 무실적 고객"
        urls = @{
            apply_url = "http://m.site.naver.com/18fKy"
            promo_url = "http://m.site.naver.com/18fKy"
        }
    },
    @{
        card_company = "롯데카드"
        card_name = "롯데카드 T 라이트 (Renewal)"
        card_plate_image = ""
        target_telecom = "SKT"
        target_device = "전 단말기"
        min_installment_amount = "10만원 이상"
        autopay_required = $false
        annual_fee = @{
            domestic = "25,000원"
            overseas = "25,000원 (국내, Master, Amex)"
        }
        installment_interest = @{
            "24_months" = "5.9%"
            "36_months" = "7.0%"
        }
        discount_tiers = @(
            @{ required_performance = "50만원 이상"; base_discount = 8000; promo_discount = 26000; total_monthly_discount = 34000; benefit_duration = "24개월" },
            @{ required_performance = "100만원 이상"; base_discount = 10000; promo_discount = 25000; total_monthly_discount = 35000; benefit_duration = "24개월" }
        )
        special_promo = $null
        performance_criteria = @{
            included = @()
            excluded = @("무이자할부", "단기카드대출", "장기카드대출", "연회비", "이자/수수료", "임대료", "등록금", "택시/고속버스/대중교통", "롯데카드 타카드 이용액", "상품권", "국세/지방세/공과금/4대보험")
        }
        base_card_benefits = @("롯데백화점 5% 할인 e-쿠폰 매월 2매", "L.POINT 제휴사 적립")
        promo_target_condition = "롯데카드 신규 또는 행사월 기준 6개월 이상 무실적 고객"
        urls = @{
            apply_url = "https://m.site.naver.com/2gcGP"
            promo_url = "https://m.site.naver.com/2gcGP"
        }
    },
    @{
        card_company = "신한카드"
        card_name = "신한카드 T라이트"
        card_plate_image = ""
        target_telecom = "SKT"
        target_device = "전 단말기"
        min_installment_amount = "5만원 이상"
        autopay_required = $false
        annual_fee = @{
            domestic = "22,000원"
            overseas = "25,000원 (Master Only)"
        }
        installment_interest = @{
            "24_months" = "5.9%"
            "36_months" = "불가"
        }
        discount_tiers = @(
            @{ required_performance = "30만원 이상"; base_discount = 10000; promo_discount = 12000; total_monthly_discount = 22000; benefit_duration = "24개월" },
            @{ required_performance = "70만원 이상"; base_discount = 15000; promo_discount = 9000; total_monthly_discount = 24000; benefit_duration = "24개월" }
        )
        special_promo = $null
        performance_criteria = @{
            included = @()
            excluded = @("무이자(슬림할부 포함)", "단기카드대출", "장기카드대출", "연회비/수수료", "도시가스/전기/4대보험", "기프트/선불카드충전", "상품권구매")
        }
        base_card_benefits = @()
        promo_target_condition = "신한카드 신규 또는 행사월 기준 6개월 이상 무실적 고객 (신한 T라이트 최초발급, 해외브랜드 Master 한정)"
        urls = @{
            apply_url = "http://m.site.naver.com/0JM2M"
            promo_url = "http://m.site.naver.com/0JM2M"
        }
    },
    @{
        card_company = "신한카드"
        card_name = "신한카드 파인애플"
        card_plate_image = ""
        target_telecom = "SKT"
        target_device = "애플 단말 (아이폰 한정)"
        min_installment_amount = "5만원 이상"
        autopay_required = $false
        annual_fee = @{
            domestic = "12,000원"
            overseas = "15,000원 (Visa Only)"
        }
        installment_interest = @{
            "24_months" = "5.9%"
            "36_months" = "7.0%"
        }
        discount_tiers = @(
            @{ required_performance = "30만원 이상"; base_discount = 10000; promo_discount = 12000; total_monthly_discount = 22000; benefit_duration = "24개월" },
            @{ required_performance = "70만원 이상"; base_discount = 15000; promo_discount = 9000; total_monthly_discount = 24000; benefit_duration = "24개월" }
        )
        special_promo = $null
        performance_criteria = @{
            included = @()
            excluded = @("무이자할부", "단기카드대출", "장기카드대출", "연회비/수수료", "선불카드 충전 실적")
        }
        base_card_benefits = @()
        promo_target_condition = "신한카드 신규 또는 행사월 기준 6개월 이상 무실적 고객 (신한 파인애플 최초발급, 해외브랜드 VISA 한정, ARS 080-850-0488 전용)"
        urls = @{
            apply_url = "ARS: 080-850-0488"
            promo_url = $null
        }
    },
    @{
        card_company = "신한카드"
        card_name = "신한카드 T&LIFE"
        card_plate_image = ""
        target_telecom = "SKT"
        target_device = "전 단말기 (요금할인형)"
        min_installment_amount = "해당없음"
        autopay_required = $true
        annual_fee = @{
            domestic = "30,000원"
            overseas = "30,000원 (Master Only)"
        }
        installment_interest = @{
            "24_months" = "해당없음"
            "36_months" = "해당없음"
        }
        discount_tiers = @(
            @{ required_performance = "30만원 이상"; base_discount = 6000; promo_discount = 13000; total_monthly_discount = 19000; benefit_duration = "24개월" },
            @{ required_performance = "70만원 이상"; base_discount = 8000; promo_discount = 12000; total_monthly_discount = 20000; benefit_duration = "24개월" },
            @{ required_performance = "120만원 이상"; base_discount = 10000; promo_discount = 11000; total_monthly_discount = 21000; benefit_duration = "24개월" }
        )
        special_promo = "T라이프 추가 혜택 (올리브영/다이소/편의점/커피/T우주/넷플릭스 등 5% 할인, 실적별 최대 5천~1.2만원 추가할인)"
        performance_criteria = @{
            included = @()
            excluded = @("무이자할부", "단기카드대출", "장기카드대출", "연회비/수수료", "도시가스/전기/4대보험", "기프트/선불카드", "상품권")
        }
        base_card_benefits = @("2040 선호 가맹점 5% 할인 (월 최대 5,000~12,000원)")
        promo_target_condition = "신한카드 신규 또는 행사월 기준 6개월 이상 무실적 고객 (신한 T&LIFE 최초발급, 해외브랜드 Master 한정, SKT 통신요금 자동이체 필수)"
        urls = @{
            apply_url = "홈페이지 / 모바일 신청"
            promo_url = $null
        }
    },
    @{
        card_company = "KB국민카드"
        card_name = "T-economy KB국민카드"
        card_plate_image = ""
        target_telecom = "SKT"
        target_device = "전 단말기 (요금할인형)"
        min_installment_amount = "해당없음"
        autopay_required = $true
        annual_fee = @{
            domestic = "15,000원"
            overseas = "15,000원 (Master, JCB, 로컬)"
        }
        installment_interest = @{
            "24_months" = "해당없음"
            "36_months" = "해당없음"
        }
        discount_tiers = @(
            @{ required_performance = "20만원 이상"; base_discount = 10000; promo_discount = 0; total_monthly_discount = 10000; benefit_duration = "24개월" },
            @{ required_performance = "30만원 이상"; base_discount = 12000; promo_discount = 0; total_monthly_discount = 12000; benefit_duration = "24개월" },
            @{ required_performance = "70만원 이상"; base_discount = 17000; promo_discount = 0; total_monthly_discount = 17000; benefit_duration = "24개월" }
        )
        special_promo = $null
        performance_criteria = @{
            included = @()
            excluded = @("무이자할부", "단기카드대출", "장기카드대출", "수수료", "아파트관리비", "초중고 납입금", "정부지원금", "대학(원)등록금", "무승인전표", "상품권", "국세/지방세/공과금", "4대보험")
        }
        base_card_benefits = @()
        promo_target_condition = "KB국민카드 신규 또는 행사월 기준 6개월 이상 무실적 고객 (SKT 통신료 자동이체 연결 필수)"
        urls = @{
            apply_url = "http://m.site.naver.com/1KYxS"
            promo_url = "http://m.site.naver.com/1KYxS"
        }
    },
    @{
        card_company = "현대카드"
        card_name = "현대카드 M3 통신할인형2.0"
        card_plate_image = ""
        target_telecom = "SKT"
        target_device = "전 단말기 (요금할인형)"
        min_installment_amount = "해당없음"
        autopay_required = $true
        annual_fee = @{
            domestic = "20,000원"
            overseas = "20,000원 (국내, VISA)"
        }
        installment_interest = @{
            "24_months" = "해당없음"
            "36_months" = "해당없음"
        }
        discount_tiers = @(
            @{ required_performance = "50만원 이상"; base_discount = 15000; promo_discount = 18000; total_monthly_discount = 33000; benefit_duration = "24개월" },
            @{ required_performance = "100만원 이상"; base_discount = 25000; promo_discount = 10000; total_monthly_discount = 35000; benefit_duration = "24개월" }
        )
        special_promo = "SKT x 현대카드 쿠폰팩 프로모션 (투썸/다이소/CU/올리브영/포인트샵 쿠폰 월 최대 22,700원)"
        performance_criteria = @{
            included = @()
            excluded = @("현대카드 모든 할인서비스 및 무이자 할부 이용 금액", "장기카드대출", "단기카드대출", "연회비", "제수수료", "이자", "아파트관리비", "초중고 납입금", "대학(원)등록금", "고속도로 통행 요금", "고속버스", "할인적용된 SKT 통신요금", "상품권/선불카드", "공과금", "4대보험")
        }
        base_card_benefits = @("코스트코 이용 가능", "25개월 차부터 50만원 이상 시 0.5~3% M포인트 적립")
        promo_target_condition = "현대카드 신규 또는 행사월 기준 6개월 이상 무실적 고객 (M3 통신할인형2.0 최초 발급, SKT 자동이체 필수)"
        urls = @{
            apply_url = "https://www.hyundaicard.com/cpc/cr/CPCCR0201_01.hc?cardWcd=MSKTE3TP"
            promo_url = "https://www.hyundaicard.com/cpc/cr/CPCCR0201_01.hc?cardWcd=MSKTE3TP"
        }
    },
    @{
        card_company = "롯데카드"
        card_name = "TELLO NE 롯데카드 (Renewal)"
        card_plate_image = ""
        target_telecom = "SKT"
        target_device = "해당없음 (요금할인형)"
        min_installment_amount = "해당없음"
        autopay_required = $true
        annual_fee = @{
            domestic = "25,000원"
            overseas = "25,000원 (국내, Master, Amex)"
        }
        installment_interest = @{
            "24_months" = "해당없음"
            "36_months" = "해당없음"
        }
        discount_tiers = @(
            @{ required_performance = "40만원 이상"; base_discount = 8000; promo_discount = 20000; total_monthly_discount = 28000; benefit_duration = "24개월" },
            @{ required_performance = "80만원 이상"; base_discount = 13000; promo_discount = 16000; total_monthly_discount = 29000; benefit_duration = "24개월" }
        )
        special_promo = $null
        performance_criteria = @{
            included = @()
            excluded = @("무이자할부", "단기카드대출", "장기카드대출", "연회비", "이자/수수료", "임대료", "등록금", "대중교통", "SKT통신요금", "TELLO NE 외 타 롯데카드 이용액", "상품권", "국세/지방세/공과금/4대보험")
        }
        base_card_benefits = @("롯데백화점 5% 할인 e-쿠폰 매월 2매", "L.POINT 제휴사 적립")
        promo_target_condition = "롯데카드 신규 또는 행사월 기준 6개월 이상 무실적 고객 (SKT 통신요금 자동이체 필수)"
        urls = @{
            apply_url = "http://s.lottecard.co.kr/1vkTrqN"
            promo_url = "http://s.lottecard.co.kr/1vkTrqN"
        }
    },
    @{
        card_company = "삼성카드"
        card_name = "삼성카드 T나는혜택"
        card_plate_image = ""
        target_telecom = "SKT"
        target_device = "전 단말기 (요금할인형)"
        min_installment_amount = "해당없음"
        autopay_required = $true
        annual_fee = @{
            domestic = "20,000원"
            overseas = "20,000원 (국내, Master)"
        }
        installment_interest = @{
            "24_months" = "해당없음"
            "36_months" = "해당없음"
        }
        discount_tiers = @(
            @{ required_performance = "30만원 이상"; base_discount = 7000; promo_discount = 13000; total_monthly_discount = 20000; benefit_duration = "24개월" },
            @{ required_performance = "70만원 이상"; base_discount = 10000; promo_discount = 11000; total_monthly_discount = 21000; benefit_duration = "24개월" },
            @{ required_performance = "120만원 이상"; base_discount = 13000; promo_discount = 9000; total_monthly_discount = 22000; benefit_duration = "24개월" }
        )
        special_promo = $null
        performance_criteria = @{
            included = @("대중교통", "택시", "SKT 통신요금 (삼성카드는 SKT 통신요금도 전월실적에 포함!)")
            excluded = @("무이자할부", "단기카드대출", "장기카드대출", "연회비/수수료", "아파트관리비", "대학등록금", "상품권", "국세/지방세/공과금/4대보험")
        }
        base_card_benefits = @("전월 정기결제 이용건수에 따라 월 1,000~3,000원 추가 할인 (아파트관리비, 4대보험, 렌탈, 스트리밍 등)")
        promo_target_condition = "삼성카드 신규 또는 행사월 기준 6개월 이상 무실적 고객 (건별 1.5만원 이상 SKT 자동이체 필수)"
        urls = @{
            apply_url = "http://m.site.naver.com/0Uysh"
            promo_url = "http://m.site.naver.com/0Uysh"
        }
    }
)

$jsonOutput = $sktCards | ConvertTo-Json -Depth 10
Set-Content -Path "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\ground_truth_skt_202611.json" -Value $jsonOutput -Encoding UTF8

Write-Host "✅ SKT 11월 15종 정답지 JSON 데이터 생성 완료! (Count: $($sktCards.Count))"
