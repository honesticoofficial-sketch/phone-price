const KT_AFFILIATE_CARDS = [
  // ==================== [KT 라이트할부 8종] ====================
  {
    id: "kt_kb_light_plus",
    carrier: "KT",
    type: "light",
    typeLabel: "라이트할부",
    cardCompany: "KB국민카드",
    cardName: "KT 할부 Plus KB국민카드",
    theme: "theme-gold",
    highlightBadge: "최대 27,000원 할인 & 24/36개월 장기할부 지원",
    phone: "KB국민카드 고객센터 1577-9900",
    applyUrl: "https://m.kbcard.com/CRD/DVIEW/MCAMCXHIACRC0002?mainCC=b&allianceCode=01507&solicitorcode=7021507000",
    eventTarget: "직전 6개월 무실적 고객 프로모션 (24/36개월 장기할부 5.9%/7.0%)",
    cardPlateImageUrl: "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/2425de02-e741-4b82-84c1-947049d1b989",
    cardPlateOrientation: "horizontal",
    supports36Months: true,
    promo36Months: false,
    specs: {
      targetDevice: "전기종 (아이폰/갤럭시)",
      minPayment: "5만원 이상",
      autoTransfer: "장기할부 필수",
      annualFee: "국내 2만원 / 해외(Master/JCB) 2만원",
      installmentInterest: "24개월 5.9% / 36개월 7.0%",
      applyMethod: "발급 QR코드 스캔 / 공식 모바일 URL"
    },
    summary: {
      installmentSub: "※ 단말기 잔여 할부원금은 아래 매월 카드 이용 실적 청구할인 혜택으로 전액 상쇄됩니다."
    },
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인",
        condition: "신규 발급 또는 6개월 무실적 고객 (라이트할부 승인일 기준)",
        highlight: "매월 최대 27,000원",
        tiers: [
          { label: "전월 30만원 이상", amount: "월 25,000원 할인", amountNum: 25000, baseAmount: "8,000", promoAmount: "17,000", sub: "기본 8,000원 + 프로모션 17,000원", total24: "24개월 총 600,000원 할인", total24Num: 600000, total36: "36개월 총 696,000원 할인", total36Num: 696000, total36Note: "1~24회차: 월 25,000원 / 25~36회차: 기본 월 8,000원" },
          { label: "전월 70만원 이상", amount: "월 26,000원 할인", amountNum: 26000, baseAmount: "12,000", promoAmount: "14,000", sub: "기본 12,000원 + 프로모션 14,000원", total24: "24개월 총 624,000원 할인", total24Num: 624000, total36: "36개월 총 768,000원 할인", total36Num: 768000, total36Note: "1~24회차: 월 26,000원 / 25~36회차: 기본 월 12,000원" },
          { label: "전월 100만원 이상", amount: "월 27,000원 할인", amountNum: 27000, baseAmount: "14,000", promoAmount: "13,000", sub: "기본 14,000원 + 프로모션 13,000원", total24: "24개월 총 648,000원 할인", total24Num: 648000, total36: "36개월 총 816,000원 할인", total36Num: 816000, total36Note: "1~24회차: 월 27,000원 / 25~36회차: 기본 월 14,000원" }
        ]
      }
    ],
    basicBenefits: [
      "KT 라이트할부 미이용 시 기본 청구할인 제공",
      "대중교통 및 생활가맹점 포인트 적립",
      "주요 놀이공원 및 영화관 제휴 할인"
    ],
    details: [
      "신규 발급 회원은 승인 익월 전월실적 미충족 시에도 1회차 기본 및 프로모션 할인 제공",
      "전월실적 산정: 통신비 자동이체금, 장기할부 약정금액, 일반 일시불/할부 이용금액 합산",
      "출처: 세이브드림 KT 공식 정책"
    ]
  },

  {
    id: "kt_lotte_light",
    carrier: "KT",
    type: "light",
    typeLabel: "라이트할부",
    cardCompany: "롯데카드",
    cardName: "KT 할부 롯데카드",
    theme: "theme-red",
    highlightBadge: "50만 실적 3.4만 / 100만 실적 3.5만원 최대 24개월 캐시백",
    phone: "롯데카드 고객센터 1588-8100",
    applyUrl: "http://m.lottecard.co.kr/spa/card/booth?bId=106378&vtCdKndC=P15912-A15912",
    eventTarget: "직전 6개월 무실적 고객 프로모션 참여 후 장기할부 수납 완료 시",
    cardPlateImageUrl: "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/3dab1f98-3e05-4452-bc7f-54574612b7e3",
    cardPlateOrientation: "horizontal",
    supports36Months: false,
    promo36Months: false,
    specs: {
      targetDevice: "전기종",
      minPayment: "5만원 이상",
      autoTransfer: "장기할부 필수",
      annualFee: "국내 2.5만원 / 해외(MASTER/AMEX) 2.5만원",
      installmentInterest: "24개월 5.9% (36개월 미지원)",
      applyMethod: "발급 QR코드 스캔 / 공식 모바일 URL"
    },
    summary: {
      installmentSub: "※ 단말기 잔여 할부원금은 아래 매월 카드 이용 실적 청구할인 혜택으로 전액 상쇄됩니다."
    },
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 캐시백 프로모션 (24개월)",
        condition: "직전 6개월 무실적 고객 장기할부 수납 완료 시",
        highlight: "매월 최대 35,000원 결제계좌 현금 캐시백",
        tiers: [
          { label: "전월 50만원 이상", amount: "월 34,000원 할인", amountNum: 34000, baseAmount: "8,000", promoAmount: "26,000", sub: "기본 8,000원 + 프로모션 26,000원", total24: "24개월 총 816,000원 할인", total24Num: 816000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 },
          { label: "전월 100만원 이상", amount: "월 35,000원 할인", amountNum: 35000, baseAmount: "10,000", promoAmount: "25,000", sub: "기본 10,000원 + 프로모션 25,000원", total24: "24개월 총 840,000원 할인", total24Num: 840000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 }
        ]
      }
    ],
    basicBenefits: [
      "롯데백화점 5% 할인 e-쿠폰 및 무료 주차권",
      "롯데리아, 엔제리너스 등 롯데 계열 가맹점 제휴 할인"
    ],
    details: [
      "추가 캐시백은 프로모션 익월부터 최대 24개월 적용",
      "전월실적 제외: 단기/장기카드대출, 연회비, 국세, 지방세, 아파트관리비, 상품권",
      "출처: 세이브드림 KT 공식 정책"
    ]
  },

  {
    id: "kt_hyundai_m3_2",
    carrier: "KT",
    type: "light",
    typeLabel: "라이트할부",
    cardCompany: "현대카드",
    cardName: "KT 현대카드M Edition3 (통신할인형 2.0)",
    theme: "theme-red",
    highlightBadge: "최대 35,000원 청구할인 & Apple Pay 완벽 지원",
    phone: "현대카드 고객센터 02-2655-6033",
    applyUrl: "https://www.hyundaicard.com/cpc/cr/CPCCR0201_01.hc?cardwcd=MKTE3",
    eventUrl: "https://www.hyundaicard.com/cpc/cr/CPCCR0201_01.hc?cardWcd=MKTE3TP&eventCode=KTP9N",
    eventTarget: "직전 6개월 무실적 고객 프로모션 (장기할부 결제 시)",
    cardPlateImageUrl: "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/056b253d-354e-4f10-bbdd-9472ffc5c190",
    cardPlateOrientation: "horizontal",
    supports36Months: false,
    promo36Months: false,
    specs: {
      targetDevice: "전기종 (Apple Pay 지원)",
      minPayment: "5만원 이상",
      autoTransfer: "장기할부 필수",
      annualFee: "국내 2만원 / 국내외겸용(Visa, Amex) 2만원",
      installmentInterest: "24개월 5.8% (36개월 미지원)",
      applyMethod: "발급 QR코드 스캔 / 공식 모바일 URL"
    },
    summary: {
      installmentSub: "※ 단말기 잔여 할부원금은 아래 매월 카드 이용 실적 청구할인 혜택으로 전액 상쇄됩니다."
    },
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인 (24개월)",
        condition: "신규 발급 또는 6개월 무실적 고객",
        highlight: "매월 최대 35,000원",
        tiers: [
          { label: "전월 50만원 이상", amount: "월 34,000원 할인", amountNum: 34000, baseAmount: "15,000", promoAmount: "19,000", sub: "기본 15,000원 + 프로모션 19,000원", total24: "24개월 총 816,000원 할인", total24Num: 816000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 },
          { label: "전월 100만원 이상", amount: "월 35,000원 할인", amountNum: 35000, baseAmount: "25,000", promoAmount: "10,000", sub: "기본 25,000원 + 프로모션 10,000원", total24: "24개월 총 840,000원 할인", total24Num: 840000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 }
        ]
      }
    ],
    basicBenefits: [
      "M포인트 기본 적립 및 가맹점 사용",
      "Apple Pay 즉시 등록 및 오프라인 간편 결제"
    ],
    details: [
      "본 카드는 24개월 라이트할부 전용 상품입니다",
      "전월실적 제외: 상품권, 세금, 연회비 등",
      "출처: 세이브드림 KT 공식 정책"
    ]
  },

  {
    id: "kt_samsung_light_s",
    carrier: "KT",
    type: "light",
    typeLabel: "라이트할부",
    cardCompany: "삼성카드",
    cardName: "KT 할부 S 삼성카드",
    theme: "theme-blue",
    highlightBadge: "월 2.2만/2.3만/2.4만원 청구할인 (기본+프로모션)",
    phone: "삼성카드 고객센터 1588-8700",
    applyUrl: "https://www.samsungcard.com/home/card/cardinfo/PGHPPCCCardCardinfoDetails001?code=AAP1839&alncmpC=QKKTLITE&affcode=QKKTLITE",
    eventTarget: "전월 40/80/120만원 이상 이용 시 프로모션 적용",
    cardPlateImageUrl: "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/46d651ec-5640-421d-b78a-cc09054e04e6",
    cardPlateOrientation: "horizontal",
    supports36Months: true,
    promo36Months: true,
    specs: {
      targetDevice: "전기종",
      minPayment: "10만원 이상",
      autoTransfer: "장기할부 필수",
      annualFee: "국내 2만5천원 / 해외(Master) 2만5천원",
      installmentInterest: "24개월 5.9% / 36개월 7.0%",
      applyMethod: "발급 QR코드 스캔 / 공식 모바일 URL"
    },
    summary: {
      installmentSub: "※ 단말기 잔여 할부원금은 아래 매월 카드 이용 실적 청구할인 혜택으로 전액 상쇄됩니다."
    },
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인",
        condition: "신규 발급 또는 6개월 무실적 고객",
        highlight: "매월 최대 24,000원",
        tiers: [
          { label: "전월 40만원 이상", amount: "월 22,000원 할인", amountNum: 22000, baseAmount: "10,000", promoAmount: "12,000", sub: "기본 10,000원 + 프로모션 12,000원", total24: "24개월 총 528,000원 할인", total24Num: 528000, total36: "36개월 총 792,000원 할인", total36Num: 792000, total36Note: "36개월간 월 22,000원 할인" },
          { label: "전월 80만원 이상", amount: "월 23,000원 할인", amountNum: 23000, baseAmount: "15,000", promoAmount: "8,000", sub: "기본 15,000원 + 프로모션 8,000원", total24: "24개월 총 552,000원 할인", total24Num: 552000, total36: "36개월 총 828,000원 할인", total36Num: 828000, total36Note: "36개월간 월 23,000원 할인" },
          { label: "전월 120만원 이상", amount: "월 24,000원 할인", amountNum: 24000, baseAmount: "20,000", promoAmount: "4,000", sub: "기본 20,000원 + 프로모션 4,000원", total24: "24개월 총 576,000원 할인", total24Num: 576000, total36: "36개월 총 864,000원 할인", total36Num: 864000, total36Note: "36개월간 월 24,000원 할인" }
        ]
      }
    ],
    basicBenefits: [
      "삼성카드 빅포인트 적립",
      "통신비 청구할인 혜택"
    ],
    details: [
      "24개월/36개월 라이트할부 수납 시 적용",
      "출처: 세이브드림 KT 공식 정책"
    ]
  },

  {
    id: "kt_shinhan_family_light",
    carrier: "KT",
    type: "light",
    typeLabel: "라이트할부",
    cardCompany: "신한카드",
    cardName: "KT 가족만족 할부 신한카드",
    theme: "theme-blue",
    highlightBadge: "30만 실적 2.5만 / 70만 실적 2.7만원 24개월 청구할인",
    phone: "신한카드 고객센터 1544-7000",
    applyUrl: "https://www.shinhancard.com/pconts/html/card/apply/credit/1221484_2207.html?EntryLoc=3298&empSeq=501&btnApp=dp01",
    eventUrl: "https://shcard.io/tlight6m",
    eventTarget: "직전 6개월 무실적 고객 프로모션 (30만 이상 이용 시)",
    cardPlateImageUrl: "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/4cec261f-497f-4be8-941c-5759f0a48aa8",
    cardPlateOrientation: "horizontal",
    supports36Months: false,
    promo36Months: false,
    specs: {
      targetDevice: "전기종",
      minPayment: "5만원 이상",
      autoTransfer: "장기할부 필수",
      annualFee: "국내 2.2만원 / 해외(Master) 2.5만원",
      installmentInterest: "24개월 연 5.9%",
      applyMethod: "발급 QR코드 스캔 / 공식 모바일 URL"
    },
    summary: {
      installmentSub: "※ 단말기 잔여 할부원금은 아래 매월 카드 이용 실적 청구할인 혜택으로 전액 상쇄됩니다."
    },
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인 (24개월)",
        condition: "신규 발급 또는 6개월 무실적 고객",
        highlight: "매월 최대 27,000원",
        tiers: [
          { label: "전월 30만원 이상", amount: "월 25,000원 할인", amountNum: 25000, baseAmount: "10,000", promoAmount: "15,000", sub: "기본 10,000원 + 프로모션 15,000원", total24: "24개월 총 600,000원 할인", total24Num: 600000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 },
          { label: "전월 70만원 이상", amount: "월 27,000원 할인", amountNum: 27000, baseAmount: "15,000", promoAmount: "12,000", sub: "기본 15,000원 + 프로모션 12,000원", total24: "24개월 총 648,000원 할인", total24Num: 648000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 }
        ]
      }
    ],
    basicBenefits: [
      "마이신한포인트 기본 적립",
      "통신비 청구할인 혜택"
    ],
    details: [
      "승인 익월 1회차 실적유예 적용, 24회차까지 청구할인",
      "출처: 세이브드림 KT 공식 정책"
    ]
  },

  {
    id: "kt_woori_36_plus",
    carrier: "KT",
    type: "light",
    typeLabel: "라이트할부",
    cardCompany: "우리카드",
    cardName: "KT 36 Plus 우리카드",
    theme: "theme-blue",
    highlightBadge: "최대 36개월 3.1만원 청구할인 & 36개월 장기할부",
    phone: "우리카드 고객센터 1588-9955",
    applyUrl: "https://m.wooricard.com/dcmw/yh1/crd/crd01/M1CRD101S02.do?cdPrdCd=104168&canvasser=88936106",
    eventTarget: "직전 6개월 무실적 고객 (최대 36개월 청구할인)",
    cardPlateImageUrl: "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/004cc44c-9ca5-478e-87d1-7c24cb39e9eb",
    cardPlateOrientation: "horizontal",
    supports36Months: true,
    promo36Months: true,
    specs: {
      targetDevice: "전기종",
      minPayment: "10만원 이상",
      autoTransfer: "장기할부 필수",
      annualFee: "국내 2.5만원 / 해외(Visa) 2.5만원",
      installmentInterest: "36개월 연 7.0%",
      applyMethod: "발급 QR코드 스캔 / 공식 모바일 URL"
    },
    summary: {
      installmentSub: "※ 단말기 잔여 할부원금은 아래 매월 카드 이용 실적 청구할인 혜택으로 전액 상쇄됩니다."
    },
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인 (최대 36개월)",
        condition: "신규 발급 또는 6개월 무실적 고객",
        highlight: "매월 최대 31,000원",
        tiers: [
          { label: "전월 40만원 이상", amount: "월 24,000원 할인", amountNum: 24000, baseAmount: "10,000", promoAmount: "14,000", sub: "기본 10,000원 + 프로모션 14,000원", total24: "24개월 총 576,000원 할인", total24Num: 576000, total36: "36개월 총 864,000원 할인", total36Num: 864000, total36Note: "36개월간 월 24,000원 청구할인" },
          { label: "전월 80만원 이상", amount: "월 29,000원 할인", amountNum: 29000, baseAmount: "15,000", promoAmount: "14,000", sub: "기본 15,000원 + 프로모션 14,000원", total24: "24개월 총 696,000원 할인", total24Num: 696000, total36: "36개월 총 1,044,000원 할인", total36Num: 1044000, total36Note: "36개월간 월 29,000원 청구할인" },
          { label: "전월 120만원 이상", amount: "월 31,000원 할인", amountNum: 31000, baseAmount: "20,000", promoAmount: "11,000", sub: "기본 20,000원 + 프로모션 11,000원", total24: "24개월 총 744,000원 할인", total24Num: 744000, total36: "36개월 총 1,116,000원 할인", total36Num: 1116000, total36Note: "36개월간 월 31,000원 청구할인" }
        ]
      }
    ],
    basicBenefits: [
      "통신비 전월실적 인정",
      "우리포인트 기본 적립"
    ],
    details: [
      "36개월 장기할부 선택 시 36개월간 할인 유지",
      "출처: 세이브드림 KT 공식 정책"
    ]
  },

  {
    id: "kt_nh_light_plus",
    carrier: "KT",
    type: "light",
    typeLabel: "라이트할부",
    cardCompany: "NH농협카드",
    cardName: "KT 할부 Plus NH농협카드",
    theme: "theme-green",
    highlightBadge: "월 2.2만/2.4만/2.7만원 청구할인 & 40만 실적 혜택",
    phone: "NH농협카드 고객센터 1644-4000",
    applyUrl: "https://go.nhcard.com/LkMCWj6",
    eventTarget: "라이트할부 수납 고객 프로모션 (캐시백 + 청구할인)",
    cardPlateImageUrl: "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/c6389d85-e974-4857-9532-fffc5b89e0bf",
    cardPlateOrientation: "horizontal",
    supports36Months: false,
    promo36Months: false,
    specs: {
      targetDevice: "전기종",
      minPayment: "5만원 이상",
      autoTransfer: "장기할부 필수",
      annualFee: "국내 2만원 / 해외(Visa) 2.3만원",
      installmentInterest: "24개월 연 5.9%",
      applyMethod: "발급 QR코드 스캔 / 공식 모바일 URL"
    },
    summary: {
      installmentSub: "※ 단말기 잔여 할부원금은 아래 매월 카드 이용 실적 청구할인 혜택으로 전액 상쇄됩니다."
    },
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인 (24개월)",
        condition: "신규 발급 또는 6개월 무실적 고객",
        highlight: "매월 최대 27,000원",
        tiers: [
          { label: "전월 40만원 이상", amount: "월 22,000원 할인", amountNum: 22000, baseAmount: "10,000", promoAmount: "12,000", sub: "기본 10,000원 + 캐시백 12,000원", total24: "24개월 총 528,000원 할인", total24Num: 528000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 },
          { label: "전월 80만원 이상", amount: "월 24,000원 할인", amountNum: 24000, baseAmount: "12,000", promoAmount: "12,000", sub: "기본 12,000원 + 캐시백 12,000원", total24: "24개월 총 576,000원 할인", total24Num: 576000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 },
          { label: "전월 120만원 이상", amount: "월 27,000원 할인", amountNum: 27000, baseAmount: "15,000", promoAmount: "12,000", sub: "기본 15,000원 + 캐시백 12,000원", total24: "24개월 총 648,000원 할인", total24Num: 648000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 }
        ]
      }
    ],
    basicBenefits: [
      "통신비 제외, 아파트 관리비 제외, 학교납입금 제외",
      "농협 하나로클럽 및 계열 가맹점 포인트 적립"
    ],
    details: [
      "24개월 라이트할부 수납 시 최대 24개월 적용",
      "출처: 세이브드림 KT 공식 정책"
    ]
  },

  {
    id: "kt_bc_super_dc",
    carrier: "KT",
    type: "light",
    typeLabel: "라이트할부",
    cardCompany: "BC바로카드",
    cardName: "KT SUPER DC BC바로카드",
    theme: "theme-rose",
    highlightBadge: "1.3만 / 1.4만 / 1.5만원 24개월 청구할인",
    phone: "BC카드 고객센터 1588-4000",
    applyUrl: "https://web.paybooc.co.kr/web/evnt/evnt-dts?pybcUnifEvntNo=2025030014&affiCd=K001",
    cardPlateImageUrl: "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/3541547b-0d33-48f2-b5f6-571644d55899",
    cardPlateOrientation: "horizontal",
    supports36Months: false,
    promo36Months: false,
    specs: {
      targetDevice: "전기종",
      minPayment: "5만원 이상",
      autoTransfer: "장기할부 필수",
      annualFee: "국내 2.5만원 / 해외(Master) 2.5만원",
      installmentInterest: "24개월 연 5.9%",
      applyMethod: "발급 QR코드 스캔 / 페이북 앱"
    },
    summary: {
      installmentSub: "※ 단말기 잔여 할부원금은 아래 매월 카드 이용 실적 청구할인 혜택으로 전액 상쇄됩니다."
    },
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인 (24개월)",
        condition: "신규 발급 또는 6개월 무실적 고객",
        highlight: "매월 최대 15,000원",
        tiers: [
          { label: "전월 40만원 이상", amount: "월 13,000원 할인", amountNum: 13000, baseAmount: "5,000", promoAmount: "8,000", sub: "기본 5,000원 + 프로모션 8,000원", total24: "24개월 총 312,000원 할인", total24Num: 312000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 },
          { label: "전월 80만원 이상", amount: "월 14,000원 할인", amountNum: 14000, baseAmount: "7,000", promoAmount: "7,000", sub: "기본 7,000원 + 프로모션 7,000원", total24: "24개월 총 336,000원 할인", total24Num: 336000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 },
          { label: "전월 120만원 이상", amount: "월 15,000원 할인", amountNum: 15000, baseAmount: "9,000", promoAmount: "6,000", sub: "기본 9,000원 + 프로모션 6,000원", total24: "24개월 총 360,000원 할인", total24Num: 360000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 }
        ]
      }
    ],
    basicBenefits: [
      "페이북 머니 적립 및 가맹점 제휴",
      "통신비 청구할인"
    ],
    details: [
      "24개월 장기할부 필수",
      "출처: 세이브드림 KT 공식 정책"
    ]
  },

  // ==================== [KT 요금할인 7종] ====================
  {
    id: "kt_lotte_dc",
    carrier: "KT",
    type: "bill",
    typeLabel: "요금할인",
    cardCompany: "롯데카드",
    cardName: "KT DC 롯데카드",
    theme: "theme-red",
    highlightBadge: "40만 실적 2.8만 / 80만 실적 2.9만원 최대 24개월 청구할인",
    phone: "롯데카드 고객센터 1588-8100",
    applyUrl: "http://m.lottecard.co.kr/spa/card/booth?bId=107345&vtCdKndC=P15933-A15933",
    eventUrl: "https://m.site.naver.com/2gcOy",
    eventTarget: "직전 6개월 무실적 고객 프로모션",
    cardPlateImageUrl: "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/b9dd0721-6d77-446f-968f-1169fdd01cda",
    cardPlateOrientation: "horizontal",
    supports36Months: false,
    promo36Months: false,
    specs: {
      targetDevice: "통신사 전회선 (자동이체)",
      minPayment: "할부 약정 없음 (자동이체 전용)",
      autoTransfer: "자동이체 필수",
      annualFee: "국내 2.5만원 / 해외(MASTER/AMEX) 2.5만원",
      installmentInterest: "해당 없음 (할부이자 0원)",
      applyMethod: "발급 QR코드 스캔 / 공식 모바일 URL"
    },
    summary: {
      installmentSub: "※ 통신요금 자동이체 시 매월 이용실적에 따라 통신비가 청구할인됩니다."
    },
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인 (24개월)",
        condition: "신규 발급 또는 6개월 무실적 고객",
        highlight: "매월 최대 29,000원",
        tiers: [
          { label: "전월 40만원 이상", amount: "월 28,000원 할인", amountNum: 28000, baseAmount: "8,000", promoAmount: "20,000", sub: "기본 8,000원 + 프로모션 20,000원", total24: "24개월 총 672,000원 할인", total24Num: 672000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 },
          { label: "전월 80만원 이상", amount: "월 29,000원 할인", amountNum: 29000, baseAmount: "13,000", promoAmount: "16,000", sub: "기본 13,000원 + 프로모션 16,000원", total24: "24개월 총 696,000원 할인", total24Num: 696000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 }
        ]
      }
    ],
    basicBenefits: [
      "롯데백화점 5% 할인쿠폰 및 무료주차권",
      "롯데 계열사 제휴 할인"
    ],
    details: [
      "자동이체 필수 등록, 24개월 청구할인",
      "출처: 세이브드림 KT 공식 정책"
    ]
  },

  {
    id: "kt_shinhan_family_dc",
    carrier: "KT",
    type: "bill",
    typeLabel: "요금할인",
    cardCompany: "신한카드",
    cardName: "KT 가족만족 DC 신한카드",
    theme: "theme-blue",
    highlightBadge: "30만 실적 2.2만 / 70만 실적 2.7만원 36개월 청구할인",
    phone: "신한카드 고객센터 1544-7000",
    applyUrl: "https://www.shinhancard.com/pconts/html/card/apply/credit/1223352_2207.html?empSeq=501&btnApp=dp01",
    eventTarget: "직전 6개월 무실적 고객 프로모션",
    cardPlateImageUrl: "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/074b0e83-5f28-4167-b895-fea12fdef0a2",
    cardPlateOrientation: "horizontal",
    supports36Months: true,
    promo36Months: true,
    specs: {
      targetDevice: "통신사 전회선 (자동이체)",
      minPayment: "할부 약정 없음",
      autoTransfer: "자동이체 필수",
      annualFee: "국내 1.5만원 / 해외(Master) 1.8만원",
      installmentInterest: "해당 없음 (할부이자 0원)",
      applyMethod: "발급 QR코드 스캔 / 공식 모바일 URL"
    },
    summary: {
      installmentSub: "※ 통신요금 자동이체 시 매월 이용실적에 따라 통신비가 청구할인됩니다."
    },
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인 (36개월)",
        condition: "신규 발급 또는 6개월 무실적 고객",
        highlight: "매월 최대 27,000원",
        tiers: [
          { label: "전월 30만원 이상", amount: "월 22,000원 할인", amountNum: 22000, baseAmount: "8,000", promoAmount: "14,000", sub: "기본 8,000원 + 프로모션 14,000원", total24: "24개월 총 528,000원 할인", total24Num: 528000, total36: "36개월 총 792,000원 할인", total36Num: 792000, total36Note: "36개월간 월 22,000원 할인" },
          { label: "전월 70만원 이상", amount: "월 27,000원 할인", amountNum: 27000, baseAmount: "12,000", promoAmount: "15,000", sub: "기본 12,000원 + 프로모션 15,000원", total24: "24개월 총 648,000원 할인", total24Num: 648000, total36: "36개월 총 972,000원 할인", total36Num: 972000, total36Note: "36개월간 월 27,000원 할인" }
        ]
      }
    ],
    basicBenefits: [
      "마이신한포인트 기본 적립",
      "통신비 청구할인"
    ],
    details: [
      "자동이체 필수 등록, 최대 36개월간 청구할인",
      "출처: 세이브드림 KT 공식 정책"
    ]
  },

  {
    id: "kt_samsung_bill",
    carrier: "KT",
    type: "bill",
    typeLabel: "요금할인",
    cardCompany: "삼성카드",
    cardName: "KT 삼성카드",
    theme: "theme-blue",
    highlightBadge: "최대 2.5만원 청구할인 & 30만/70만/120만 실적 혜택",
    phone: "삼성카드 고객센터 1588-8700",
    applyUrl: "https://www.samsungcard.com/home/card/cardinfo/PGHPPCCCardCardinfoDetails001?code=AAP1665&alncmpC=QKKT&affcode=QKKT",
    eventTarget: "직전 6개월 무실적 고객 프로모션",
    cardPlateImageUrl: "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/c04ea319-cf93-421f-b8fa-20b9f4857c1e",
    cardPlateOrientation: "horizontal",
    supports36Months: false,
    promo36Months: false,
    specs: {
      targetDevice: "통신사 전회선",
      minPayment: "할부 약정 없음",
      autoTransfer: "자동이체 필수",
      annualFee: "국내 2만원 / 해외(Master) 2만원",
      installmentInterest: "해당 없음 (할부이자 0원)",
      applyMethod: "발급 QR코드 스캔 / 공식 모바일 URL"
    },
    summary: {
      installmentSub: "※ 통신요금 자동이체 시 매월 이용실적에 따라 통신비가 청구할인됩니다."
    },
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인 (24개월)",
        condition: "신규 발급 또는 6개월 무실적 고객",
        highlight: "매월 최대 25,000원",
        tiers: [
          { label: "전월 30만원 이상", amount: "월 23,000원 할인", amountNum: 23000, baseAmount: "10,000", promoAmount: "13,000", sub: "기본 10,000원 + 프로모션 13,000원", total24: "24개월 총 552,000원 할인", total24Num: 552000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 },
          { label: "전월 70만원 이상", amount: "월 24,000원 할인", amountNum: 24000, baseAmount: "13,000", promoAmount: "11,000", sub: "기본 13,000원 + 프로모션 11,000원", total24: "24개월 총 576,000원 할인", total24Num: 576000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 },
          { label: "전월 120만원 이상", amount: "월 25,000원 할인", amountNum: 25000, baseAmount: "16,000", promoAmount: "9,000", sub: "기본 16,000원 + 프로모션 9,000원", total24: "24개월 총 600,000원 할인", total24Num: 600000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 }
        ]
      }
    ],
    basicBenefits: [
      "삼성카드 빅포인트 적립",
      "통신비 청구할인"
    ],
    details: [
      "통신요금 자동이체 필수",
      "출처: 세이브드림 KT 공식 정책"
    ]
  },

  {
    id: "kt_bc_dc_plus",
    carrier: "KT",
    type: "bill",
    typeLabel: "요금할인",
    cardCompany: "BC바로카드",
    cardName: "KT DC Plus BC바로카드",
    theme: "theme-rose",
    highlightBadge: "30만 실적 8천원 / 70만 실적 1.5만원 36개월 할인",
    phone: "BC카드 고객센터 1588-4000",
    applyUrl: "https://web.paybooc.co.kr/web/evnt/evnt-dts?pybcUnifEvntNo=2023090043&affiCd=K001",
    cardPlateImageUrl: "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/3b366cc2-5db0-4b8e-9ab9-5ac4a28b0f0c",
    cardPlateOrientation: "horizontal",
    supports36Months: true,
    promo36Months: true,
    specs: {
      targetDevice: "통신사 전회선",
      minPayment: "할부 약정 없음",
      autoTransfer: "자동이체 필수",
      annualFee: "국내 1.2만원 / 해외(Master) 1.2만원",
      installmentInterest: "해당 없음 (할부이자 0원)",
      applyMethod: "발급 QR코드 스캔 / 페이북 앱"
    },
    summary: {
      installmentSub: "※ 통신요금 자동이체 시 매월 이용실적에 따라 통신비가 청구할인됩니다."
    },
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인 (36개월)",
        condition: "신규 발급 또는 6개월 무실적 고객",
        highlight: "매월 최대 15,000원",
        tiers: [
          { label: "전월 30만원 이상", amount: "월 8,000원 할인", amountNum: 8000, baseAmount: "4,000", promoAmount: "4,000", sub: "기본 4,000원 + 프로모션 4,000원", total24: "24개월 총 192,000원 할인", total24Num: 192000, total36: "36개월 총 288,000원 할인", total36Num: 288000, total36Note: "36개월간 월 8,000원 할인" },
          { label: "전월 70만원 이상", amount: "월 15,000원 할인", amountNum: 15000, baseAmount: "7,000", promoAmount: "8,000", sub: "기본 7,000원 + 프로모션 8,000원", total24: "24개월 총 360,000원 할인", total24Num: 360000, total36: "36개월 총 540,000원 할인", total36Num: 540000, total36Note: "36개월간 월 15,000원 할인" }
        ]
      }
    ],
    basicBenefits: [
      "페이북 마일리지 적립",
      "통신비 청구할인"
    ],
    details: [
      "자동이체 필수 등록, 36개월간 청구할인",
      "출처: 세이브드림 KT 공식 정책"
    ]
  },

  {
    id: "kt_kb_dc_plus",
    carrier: "KT",
    type: "bill",
    typeLabel: "요금할인",
    cardCompany: "KB국민카드",
    cardName: "KT DC Plus KB국민카드",
    theme: "theme-gold",
    highlightBadge: "30만 실적 7천원 / 70만 실적 1.1만원 청구할인",
    phone: "KB국민카드 고객센터 1577-9900",
    applyUrl: "https://m.kbcard.com/CRD/DVIEW/MCAMCXHIACRC0002?mainCC=b&allianceCode=04293&solicitorcode=7024293000",
    eventTarget: "직전 6개월 무실적 고객 프로모션",
    cardPlateImageUrl: "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/ff5f788d-a86d-4e6f-bf24-5c42faec81c8",
    cardPlateOrientation: "horizontal",
    supports36Months: false,
    promo36Months: false,
    specs: {
      targetDevice: "통신사 전회선",
      minPayment: "할부 약정 없음",
      autoTransfer: "자동이체 필수",
      annualFee: "국내 2만원 (모바일 1.4만) / Master 2만원",
      installmentInterest: "해당 없음 (할부이자 0원)",
      applyMethod: "발급 QR코드 스캔 / 공식 모바일 URL"
    },
    summary: {
      installmentSub: "※ 통신요금 자동이체 시 매월 이용실적에 따라 통신비가 청구할인됩니다."
    },
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인",
        condition: "신규 발급 또는 6개월 무실적 고객",
        highlight: "매월 최대 11,000원",
        tiers: [
          { label: "전월 30만원 이상", amount: "월 7,000원 할인", amountNum: 7000, baseAmount: "4,000", promoAmount: "3,000", sub: "기본 4,000원 + 프로모션 3,000원", total24: "24개월 총 168,000원 할인", total24Num: 168000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 },
          { label: "전월 70만원 이상", amount: "월 11,000원 할인", amountNum: 11000, baseAmount: "7,000", promoAmount: "4,000", sub: "기본 7,000원 + 프로모션 4,000원", total24: "24개월 총 264,000원 할인", total24Num: 264000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 }
        ]
      }
    ],
    basicBenefits: [
      "KB국민카드 포인트리 적립",
      "통신비 청구할인"
    ],
    details: [
      "자동이체 필수 등록",
      "출처: 세이브드림 KT 공식 정책"
    ]
  },

  {
    id: "kt_hana_simple",
    carrier: "KT",
    type: "bill",
    typeLabel: "요금할인",
    cardCompany: "하나카드",
    cardName: "KT DC Plus 더 심플 하나카드",
    theme: "theme-teal",
    highlightBadge: "30만 실적 1만원 / 80만 실적 1.5만원 청구할인",
    phone: "하나카드 고객센터 1800-1111",
    applyUrl: "https://m.hanacard.co.kr/MPACMM101M.web?_frame=no&CD_PD_SEQ=17454",
    eventTarget: "직전 6개월 무실적 고객 프로모션",
    cardPlateImageUrl: "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/814b8298-ea83-4b29-ae81-48b9f42f895c",
    cardPlateOrientation: "horizontal",
    supports36Months: false,
    promo36Months: false,
    specs: {
      targetDevice: "통신사 전회선",
      minPayment: "할부 약정 없음",
      autoTransfer: "자동이체 필수",
      annualFee: "국내 2.5만원 / 해외(Master) 2.5만원",
      installmentInterest: "해당 없음 (할부이자 0원)",
      applyMethod: "발급 QR코드 스캔 / 공식 모바일 URL"
    },
    summary: {
      installmentSub: "※ 통신요금 자동이체 시 매월 이용실적에 따라 통신비가 청구할인됩니다."
    },
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인",
        condition: "신규 발급 또는 6개월 무실적 고객",
        highlight: "매월 최대 15,000원",
        tiers: [
          { label: "전월 30만원 이상", amount: "월 10,000원 할인", amountNum: 10000, baseAmount: "5,000", promoAmount: "5,000", sub: "기본 5,000원 + 프로모션 5,000원", total24: "24개월 총 240,000원 할인", total24Num: 240000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 },
          { label: "전월 80만원 이상", amount: "월 15,000원 할인", amountNum: 15000, baseAmount: "10,000", promoAmount: "5,000", sub: "기본 10,000원 + 프로모션 5,000원", total24: "24개월 총 360,000원 할인", total24Num: 360000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 }
        ]
      }
    ],
    basicBenefits: [
      "하나머니 적립",
      "통신비 청구할인"
    ],
    details: [
      "통신요금 자동이체 필수 등록",
      "출처: 세이브드림 KT 공식 정책"
    ]
  },

  {
    id: "kt_shinhan_uratchacha",
    carrier: "KT",
    type: "bill",
    typeLabel: "요금할인",
    cardCompany: "신한카드",
    cardName: "KT 으랏차차 신한카드",
    theme: "theme-blue",
    highlightBadge: "50만 실적 2.8만 / 200만 실적 5.8만원 최대 60개월 혜택",
    phone: "신한카드 고객센터 1544-7000",
    applyUrl: "https://www.shinhancard.com/pconts/html/card/apply/credit/1235115_2207.html?empSeq=501&btnApp=dp01",
    eventTarget: "신한은행 결제계좌 등록 및 Master 프로모션 (최대 60개월 청구할인)",
    cardPlateImageUrl: "https://savedream.co.kr/api/v1/resources/categories/PRODUCT/item/ed7ee762-199c-4ee6-adc9-ba259a64ee98",
    cardPlateOrientation: "horizontal",
    supports36Months: true,
    promo36Months: true,
    specs: {
      targetDevice: "통신사 전회선",
      minPayment: "할부 약정 없음",
      autoTransfer: "자동이체 필수",
      annualFee: "국내 3.6만원 / 해외(Master) 3.9만원",
      installmentInterest: "해당 없음 (할부이자 0원)",
      applyMethod: "발급 QR코드 스캔 / 공식 모바일 URL"
    },
    summary: {
      installmentSub: "※ 통신요금 자동이체 시 매월 이용실적에 따라 통신비가 청구할인됩니다."
    },
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인 (최대 36~60개월)",
        condition: "신규 발급 또는 6개월 무실적 고객 (신한은행 결제계좌 등록 시)",
        highlight: "매월 최대 58,000원",
        tiers: [
          { label: "전월 50만원 이상", amount: "월 28,000원 할인", amountNum: 28000, baseAmount: "12,000", promoAmount: "16,000", sub: "기본 12,000원 + 프로모션 16,000원", total24: "24개월 총 672,000원 할인", total24Num: 672000, total36: "36개월 총 1,008,000원 할인", total36Num: 1008000, total36Note: "36개월간 월 28,000원 할인" },
          { label: "전월 200만원 이상", amount: "월 58,000원 할인", amountNum: 58000, baseAmount: "33,000", promoAmount: "25,000", sub: "기본 33,000원 + 프로모션 25,000원", total24: "24개월 총 1,392,000원 할인", total24Num: 1392000, total36: "36개월 총 2,088,000원 할인", total36Num: 2088000, total36Note: "36개월간 월 58,000원 할인 (총 208.8만원)" }
        ]
      }
    ],
    basicBenefits: [
      "마이신한포인트 적립",
      "통신요금 고액 이용 고객 특화 할인"
    ],
    details: [
      "신한은행 결제계좌 등록 시 추가 캐시백 제공",
      "출처: 세이브드림 KT 공식 정책"
    ]
  }
];
