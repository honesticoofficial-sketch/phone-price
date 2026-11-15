const LGU_AFFILIATE_CARDS = [
  // ==================== [LGU+ 라이트할부 7종] ====================
  {
    id: "lgu_shinhan_bora",
    carrier: "LGU",
    type: "light",
    typeLabel: "라이트할부",
    cardCompany: "신한카드",
    cardName: "신한카드 U+ Bora",
    theme: "theme-blue",
    highlightBadge: "최대 57.6만원 할인 & 아파트 관리비 실적 인정",
    phone: "신한카드 고객센터 080-850-8853",
    applyUrl: "tel:0808508853",
    eventTarget: "Master 브랜드 발급 고객 프로모션 (직전 6개월 무실적 고객 / 6개월 무실적 프로모션 혜택)",
    cardPlateImageUrl: "",
    cardPlateOrientation: "horizontal",
    supports36Months: false,
    promo36Months: false,
    specs: {
      targetDevice: "전기종",
      minPayment: "최소결제금액 5만원 이상",
      autoTransfer: "자동이체 필수 [장기할부 선택]",
      annualFee: "국내 2.2만 / Master 2.5만",
      installmentInterest: "24개월 연 5.9%",
      applyMethod: "ARS 직통 080-850-8853"
    },
    summary: {
      installmentSub: "※ 단말기 잔여 할부원금은 아래 매월 카드 이용 실적 청구할인 혜택으로 전액 상쇄됩니다."
    },
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인 (최대 24개월)",
        condition: "신규 발급 또는 6개월 무실적 고객 (Master 브랜드)",
        highlight: "매월 최대 24,000원",
        tiers: [
          { label: "전월 40만원 이상", amount: "월 22,000원 할인", amountNum: 22000, baseAmount: "10,000", promoAmount: "12,000", sub: "기본 10,000원 + 프로모션 12,000원 (이후 1.0만)", total24: "24개월 총 528,000원 할인", total24Num: 528000, total36: "36개월 할부 미지원 (24개월 전용)", total36Num: 0 },
          { label: "전월 80만원 이상", amount: "월 24,000원 할인", amountNum: 24000, baseAmount: "15,000", promoAmount: "9,000", sub: "기본 15,000원 + 프로모션 9,000원 (이후 1.5만)", total24: "24개월 총 576,000원 할인", total24Num: 576000, total36: "36개월 할부 미지원 (24개월 전용)", total36Num: 0 }
        ]
      }
    ],
    basicBenefits: [
      "통신비 전월실적 인정",
      "아파트 관리비 전월실적 인정",
      "Master 브랜드에 한해 프로모션 할인 적용"
    ],
    details: [
      "최소결제금액 5만원 이상 & 24개월 (할부이자 연 5.9%)",
      "동일 카드 재발급 시 청구 할인 및 캐시백 프로모션 혜택 적용 불가"
    ]
  },

  {
    id: "lgu_shinhan_smartplan",
    carrier: "LGU",
    type: "light",
    typeLabel: "라이트할부",
    cardCompany: "신한카드",
    cardName: "신한카드 스마트플랜 Plus",
    theme: "theme-blue",
    highlightBadge: "30만 실적 2.2만 할인 & 관리비 실적 인정",
    phone: "신한카드 고객센터 080-700-3103",
    applyUrl: "tel:0807003103",
    eventTarget: "Master 브랜드 발급 고객 프로모션 (직전 6개월 무실적 고객 / 6개월 무실적 프로모션 혜택)",
    cardPlateImageUrl: "",
    cardPlateOrientation: "horizontal",
    supports36Months: false,
    promo36Months: false,
    specs: {
      targetDevice: "전기종",
      minPayment: "최소결제금액 5만원 이상",
      autoTransfer: "자동이체 필수 [장기할부 선택]",
      annualFee: "국내 2.2만 / Master 2.5만",
      installmentInterest: "24개월 연 5.9%",
      applyMethod: "ARS 직통 080-700-3103"
    },
    summary: {
      installmentSub: "※ 단말기 잔여 할부원금은 아래 매월 카드 이용 실적 청구할인 혜택으로 전액 상쇄됩니다."
    },
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인 (최대 24개월)",
        condition: "신규 발급 또는 6개월 무실적 고객 (Master 브랜드)",
        highlight: "매월 최대 24,000원",
        tiers: [
          { label: "전월 30만원 이상", amount: "월 22,000원 할인", amountNum: 22000, baseAmount: "10,000", promoAmount: "12,000", sub: "기본 10,000원 + 프로모션 12,000원 (이후 1.0만)", total24: "24개월 총 528,000원 할인", total24Num: 528000, total36: "36개월 할부 미지원 (24개월 전용)", total36Num: 0 },
          { label: "전월 70만원 이상", amount: "월 24,000원 할인", amountNum: 24000, baseAmount: "15,000", promoAmount: "9,000", sub: "기본 15,000원 + 프로모션 9,000원 (이후 1.5만)", total24: "24개월 총 576,000원 할인", total24Num: 576000, total36: "36개월 할부 미지원 (24개월 전용)", total36Num: 0 }
        ]
      }
    ],
    basicBenefits: [
      "통신비 전월실적 인정",
      "아파트 관리비 전월실적 인정",
      "Master 브랜드에 한해 프로모션 할인 적용"
    ],
    details: [
      "최소결제금액 5만원 이상 & 24개월 (할부이자 연 5.9%)",
      "동일 카드 재발급 시 청구 할인 및 캐시백 프로모션 혜택 적용 불가"
    ]
  },

  {
    id: "lgu_kb_light2",
    carrier: "LGU",
    type: "light",
    typeLabel: "라이트할부",
    cardCompany: "KB국민카드",
    cardName: "KB국민 U+ 라이트할부II",
    theme: "theme-gold",
    highlightBadge: "최대 64.8만 할인 & 아이폰 구매시 최대 10만 캐시백",
    phone: "KB국민카드 고객센터 1577-9900",
    applyUrl: "https://m.kbcard.com",
    eventTarget: "아이폰18 / 아이폰듀오 구매 시 최대 10만원 추가 캐시백 (직전 6개월 무실적 고객)",
    cardPlateImageUrl: "",
    cardPlateOrientation: "horizontal",
    supports36Months: false,
    promo36Months: false,
    specs: {
      targetDevice: "전기종 (아이폰18/듀오 특화)",
      minPayment: "최소결제금액 5만원 이상",
      autoTransfer: "장기할부 필수",
      annualFee: "2만원",
      installmentInterest: "24개월 연 5.9%",
      applyMethod: "발급 QR코드 스캔 / 고객센터 1577-9900"
    },
    summary: {
      installmentSub: "※ 단말기 잔여 할부원금은 아래 매월 카드 이용 실적 청구할인 혜택으로 전액 상쇄됩니다."
    },
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인 (최대 24개월)",
        condition: "신규 발급 또는 6개월 무실적 고객",
        highlight: "매월 최대 27,000원",
        tiers: [
          { label: "전월 30만원 이상", amount: "월 25,000원 할인", amountNum: 25000, baseAmount: "4,000", promoAmount: "21,000", sub: "기본 4,000원 + 프로모션 21,000원 (이후 0.4만)", total24: "24개월 총 600,000원 할인", total24Num: 600000, total36: "36개월 할부 미지원 (24개월 전용)", total36Num: 0 },
          { label: "전월 70만원 이상", amount: "월 26,000원 할인", amountNum: 26000, baseAmount: "4,000", promoAmount: "22,000", sub: "기본 4,000원 + 프로모션 22,000원 (이후 0.4만)", total24: "24개월 총 624,000원 할인", total24Num: 624000, total36: "36개월 할부 미지원 (24개월 전용)", total36Num: 0 },
          { label: "전월 100만원 이상", amount: "월 27,000원 할인", amountNum: 27000, baseAmount: "4,000", promoAmount: "23,000", sub: "기본 4,000원 + 프로모션 23,000원 (이후 0.4만)", total24: "24개월 총 648,000원 할인", total24Num: 648000, total36: "36개월 할부 미지원 (24개월 전용)", total36Num: 0 }
        ]
      },
      {
        badge: "추가 프로모션",
        title: "아이폰18 / 아이폰듀오 구매고객 최대 10만원 추가 캐시백",
        condition: "행사 기간 내 대상 단말기 라이트할부 승인 시",
        benefit: "최대 100,000원 추가 캐시백"
      }
    ],
    basicBenefits: [
      "통신비 전월실적 인정",
      "아파트 관리비 전월실적 제외",
      "전국 대중교통 및 생활가맹점 포인트 적립"
    ],
    details: [
      "장기할부 필수: 최소결제금액 5만원 이상 & 24개월 (할부이자 연 5.9%)",
      "동일 카드 재발급 시 청구 할인 및 캐시백 프로모션 혜택 적용 불가"
    ]
  },

  {
    id: "lgu_hyundai_m3",
    carrier: "LGU",
    type: "light",
    typeLabel: "라이트할부",
    cardCompany: "현대카드",
    cardName: "현대카드 M Edition 3 (통신할인형 2.0)",
    theme: "theme-red",
    highlightBadge: "최대 84만원 할인 & 월 최대 3.5만원 청구할인",
    phone: "현대카드 고객센터 02-2655-6033",
    applyUrl: "https://www.hyundaicard.com",
    eventTarget: "현대카드 홈페이지/앱 이벤트 응모 필수 (직전 6개월 무실적 고객)",
    cardPlateImageUrl: "",
    cardPlateOrientation: "horizontal",
    supports36Months: false,
    promo36Months: false,
    specs: {
      targetDevice: "전기종",
      minPayment: "최소결제금액 5만원 이상",
      autoTransfer: "자동이체 필수 (장기할부 선택)",
      annualFee: "2만원",
      installmentInterest: "24개월 연 5.8%",
      applyMethod: "발급 QR코드 스캔 (이벤트 응모 필수)"
    },
    summary: {
      installmentSub: "※ 단말기 잔여 할부원금은 아래 매월 카드 이용 실적 청구할인 혜택으로 전액 상쇄됩니다."
    },
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인 (최대 24개월)",
        condition: "신규 발급 또는 6개월 무실적 고객 (이벤트 응모 필수)",
        highlight: "매월 최대 35,000원",
        tiers: [
          { label: "전월 50만원 이상", amount: "월 34,000원 할인", amountNum: 34000, baseAmount: "8,000", promoAmount: "26,000", sub: "프로모션 적용 월 34,000원 할인", total24: "24개월 총 816,000원 할인", total24Num: 816000, total36: "36개월 할부 미지원 (24개월 전용)", total36Num: 0 },
          { label: "전월 100만원 이상", amount: "월 35,000원 할인", amountNum: 35000, baseAmount: "10,000", promoAmount: "25,000", sub: "프로모션 적용 월 35,000원 할인", total24: "24개월 총 840,000원 할인", total24Num: 840000, total36: "36개월 할부 미지원 (24개월 전용)", total36Num: 0 }
        ]
      }
    ],
    basicBenefits: [
      "M포인트 기본 적립 및 가맹점 사용",
      "통신비 제외, 아파트 관리비 제외, 학교납입금 제외"
    ],
    details: [
      "최소결제금액 5만원 이상 & 24개월 (할부이자 연 5.8%)",
      "현대카드 홈페이지/앱 이벤트 응모 필수"
    ]
  },

  {
    id: "lgu_woori_36",
    carrier: "LGU",
    type: "light",
    typeLabel: "라이트할부",
    cardCompany: "우리카드",
    cardName: "U+ × 36우리카드",
    theme: "theme-blue",
    highlightBadge: "36개월 최대 111.6만원 압도적 장기할부 할인",
    phone: "우리카드 고객센터 1588-9955",
    applyUrl: "https://m.wooricard.com",
    eventTarget: "직전 6개월 무실적 프로모션 혜택 (동일카드 탈회 1년 미경과 시 미적용)",
    cardPlateImageUrl: "",
    cardPlateOrientation: "horizontal",
    supports36Months: true,
    promo36Months: true,
    specs: {
      targetDevice: "전기종",
      minPayment: "최소결제금액 10만원 이상",
      autoTransfer: "자동이체 필수 (장기할부 선택)",
      annualFee: "2.5만원",
      installmentInterest: "36개월 연 7.0%",
      applyMethod: "발급 QR코드 스캔 / 고객센터 1588-9955"
    },
    summary: {
      installmentSub: "※ 단말기 잔여 할부원금은 아래 매월 카드 이용 실적 청구할인 혜택으로 전액 상쇄됩니다."
    },
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인 (최대 36개월)",
        condition: "신규 발급 또는 6개월 무실적 고객",
        highlight: "매월 최대 31,000원 (36개월 기준)",
        tiers: [
          { label: "전월 40만원 이상", amount: "월 24,000원 할인", amountNum: 24000, baseAmount: "5,000", promoAmount: "19,000", sub: "기본 5,000원 + 프로모션 19,000원 (이후 0.5만)", total24: "24개월 총 576,000원 할인", total24Num: 576000, total36: "36개월 총 864,000원 할인", total36Num: 864000, total36Note: "36개월간 월 24,000원 청구할인" },
          { label: "전월 80만원 이상", amount: "월 29,000원 할인", amountNum: 29000, baseAmount: "5,000", promoAmount: "24,000", sub: "기본 5,000원 + 프로모션 24,000원 (이후 0.5만)", total24: "24개월 총 696,000원 할인", total24Num: 696000, total36: "36개월 총 1,044,000원 할인", total36Num: 1044000, total36Note: "36개월간 월 29,000원 청구할인" },
          { label: "전월 120만원 이상", amount: "월 31,000원 할인", amountNum: 31000, baseAmount: "5,000", promoAmount: "26,000", sub: "기본 5,000원 + 프로모션 26,000원 (이후 0.5만)", total24: "24개월 총 744,000원 할인", total24Num: 744000, total36: "36개월 총 1,116,000원 할인", total36Num: 1116000, total36Note: "36개월간 월 31,000원 청구할인 (총 111.6만원)" }
        ]
      }
    ],
    basicBenefits: [
      "통신비 전월실적 인정",
      "아파트 관리비 전월실적 제외",
      "우리카드 모아포인트 기본 적립"
    ],
    details: [
      "최소결제금액 10만원 이상 & 36개월 (할부이자 연 7.0%)",
      "우리카드의 경우 동일카드 탈회 1년 미경과 시 프로모션 할인 혜택 미적용"
    ]
  },

  {
    id: "lgu_samsung_light",
    carrier: "LGU",
    type: "light",
    typeLabel: "라이트할부",
    cardCompany: "삼성카드",
    cardName: "U+ 라이트 삼성카드",
    theme: "theme-blue",
    highlightBadge: "36개월 최대 86.4만 할인 & JCB 2.5만 추가 캐시백",
    phone: "삼성카드 고객센터 1588-8700",
    applyUrl: "https://www.samsungcard.com",
    eventTarget: "JCB브랜드 발급 시 2.5만원 캐시백 (직전 6개월 무실적 고객)",
    cardPlateImageUrl: "",
    cardPlateOrientation: "horizontal",
    supports36Months: true,
    promo36Months: true,
    specs: {
      targetDevice: "전기종",
      minPayment: "최소결제금액 10만원 이상",
      autoTransfer: "장기할부 필수",
      annualFee: "2.5만원",
      installmentInterest: "24개월 연 5.9% / 36개월 연 5.9%",
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
        highlight: "매월 최대 24,000원 (36개월 기준)",
        tiers: [
          { label: "전월 40만원 이상", amount: "월 22,000원 할인", amountNum: 22000, baseAmount: "3,000", promoAmount: "19,000", sub: "기본 3,000원 + 프로모션 19,000원 (이후 0.3만)", total24: "24개월 총 528,000원 할인", total24Num: 528000, total36: "36개월 총 792,000원 할인", total36Num: 792000, total36Note: "36개월간 월 22,000원 청구할인" },
          { label: "전월 80만원 이상", amount: "월 23,000원 할인", amountNum: 23000, baseAmount: "5,000", promoAmount: "18,000", sub: "기본 5,000원 + 프로모션 18,000원 (이후 0.5만)", total24: "24개월 총 552,000원 할인", total24Num: 552000, total36: "36개월 총 828,000원 할인", total36Num: 828000, total36Note: "36개월간 월 23,000원 청구할인" },
          { label: "전월 120만원 이상", amount: "월 24,000원 할인", amountNum: 24000, baseAmount: "8,000", promoAmount: "16,000", sub: "기본 8,000원 + 프로모션 16,000원 (이후 0.8만)", total24: "24개월 총 576,000원 할인", total24Num: 576000, total36: "36개월 총 864,000원 할인", total36Num: 864000, total36Note: "36개월간 월 24,000원 청구할인 (총 86.4만원)" }
        ]
      },
      {
        badge: "추가 프로모션",
        title: "JCB브랜드 발급 특별 캐시백",
        condition: "JCB브랜드 발급 후 장기할부 승인 시",
        benefit: "25,000원 캐시백"
      }
    ],
    basicBenefits: [
      "통신비 전월실적 인정",
      "아파트 관리비 제외, 학교납입금 & 교통비 제외"
    ],
    details: [
      "최소결제금액 10만원 이상 & 장기할부 필수 (할부이자 연 5.9%)",
      "LG U+ 삼성카드는 가족카드 발급 불가"
    ]
  },

  {
    id: "lgu_lotte_light",
    carrier: "LGU",
    type: "light",
    typeLabel: "라이트할부",
    cardCompany: "롯데카드",
    cardName: "U+ × LOCA 라이트할부",
    theme: "theme-red",
    highlightBadge: "최대 84만원 할인 & 50만 실적 3.4만 할인",
    phone: "롯데카드 고객센터 1588-8100",
    applyUrl: "http://m.lottecard.co.kr",
    eventTarget: "직전 6개월 무실적 고객 프로모션 (롯데카드는 가족카드 발급 불가)",
    cardPlateImageUrl: "",
    cardPlateOrientation: "horizontal",
    supports36Months: false,
    promo36Months: false,
    specs: {
      targetDevice: "전기종",
      minPayment: "최소결제금액 10만원 이상",
      autoTransfer: "장기할부 필수",
      annualFee: "2.5만원",
      installmentInterest: "24개월 연 5.9%",
      applyMethod: "발급 QR코드 스캔 / 고객센터 1588-8100"
    },
    summary: {
      installmentSub: "※ 단말기 잔여 할부원금은 아래 매월 카드 이용 실적 청구할인 혜택으로 전액 상쇄됩니다."
    },
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인 (최대 24개월)",
        condition: "신규 발급 또는 6개월 무실적 고객",
        highlight: "매월 최대 35,000원",
        tiers: [
          { label: "전월 50만원 이상", amount: "월 34,000원 할인", amountNum: 34000, baseAmount: "10,000", promoAmount: "24,000", sub: "기본 10,000원 + 프로모션 24,000원 (이후 1.0만)", total24: "24개월 총 816,000원 할인", total24Num: 816000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 },
          { label: "전월 100만원 이상", amount: "월 35,000원 할인", amountNum: 35000, baseAmount: "15,000", promoAmount: "20,000", sub: "기본 15,000원 + 프로모션 20,000원 (이후 1.5만)", total24: "24개월 총 840,000원 할인", total24Num: 840000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 }
        ]
      }
    ],
    basicBenefits: [
      "통신비 전월실적 인정",
      "아파트 관리비 전월실적 제외",
      "롯데백화점 5% 할인쿠폰 및 무료주차권"
    ],
    details: [
      "최소결제금액 10만원 이상 & 24개월 (할부이자 연 5.9%)",
      "롯데카드는 가족카드 발급 불가"
    ]
  },

  // ==================== [LGU+ 요금할인 5종] ====================
  {
    id: "lgu_samsung_bill",
    carrier: "LGU",
    type: "bill",
    typeLabel: "요금할인",
    cardCompany: "삼성카드",
    cardName: "LG U+ 삼성카드",
    theme: "theme-blue",
    highlightBadge: "최대 52.8만원 요금할인 & 30만 실적 2만 할인",
    phone: "삼성카드 고객센터 1800-1068",
    applyUrl: "tel:18001068",
    eventTarget: "직전 6개월 무실적 프로모션 혜택 (가족카드 발급 불가)",
    cardPlateImageUrl: "",
    cardPlateOrientation: "horizontal",
    supports36Months: false,
    promo36Months: false,
    specs: {
      targetDevice: "통신사 전회선 (자동이체)",
      minPayment: "최소 10만원 이상 (장기할부 선택 시)",
      autoTransfer: "자동이체 필수 (장기할부 선택)",
      annualFee: "2만원",
      installmentInterest: "24개월 연 5.9%",
      applyMethod: "전화 신청 1800-1068"
    },
    summary: {
      installmentSub: "※ 통신요금 자동이체 시 매월 이용실적에 따라 통신비가 청구할인됩니다."
    },
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인 (최대 24개월)",
        condition: "신규 발급 또는 6개월 무실적 고객",
        highlight: "매월 최대 22,000원",
        tiers: [
          { label: "전월 30만원 이상", amount: "월 20,000원 할인", amountNum: 20000, baseAmount: "7,000", promoAmount: "13,000", sub: "기본 7,000원 + 프로모션 13,000원 (이후 0.7만)", total24: "24개월 총 480,000원 할인", total24Num: 480000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 },
          { label: "전월 70만원 이상", amount: "월 21,000원 할인", amountNum: 21000, baseAmount: "10,000", promoAmount: "11,000", sub: "기본 10,000원 + 프로모션 11,000원 (이후 1.0만)", total24: "24개월 총 504,000원 할인", total24Num: 504000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 },
          { label: "전월 120만원 이상", amount: "월 22,000원 할인", amountNum: 22000, baseAmount: "13,000", promoAmount: "9,000", sub: "기본 13,000원 + 프로모션 9,000원 (이후 1.3만)", total24: "24개월 총 528,000원 할인", total24Num: 528000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 }
        ]
      }
    ],
    basicBenefits: [
      "통신비 전월실적 인정",
      "아파트 관리비 제외, 학교납입금 & 교통비 제외"
    ],
    details: [
      "자동이체 필수 등록",
      "LG U+ 삼성카드는 가족카드 발급 불가"
    ]
  },

  {
    id: "lgu_lotte_dc",
    carrier: "LGU",
    type: "bill",
    typeLabel: "요금할인",
    cardCompany: "롯데카드",
    cardName: "U+ DC 롯데카드 (New)",
    theme: "theme-red",
    highlightBadge: "신규 출시 요금할인 & 40만 실적 2.8만 청구할인",
    phone: "롯데카드 고객센터 1588-8100",
    applyUrl: "http://m.lottecard.co.kr",
    eventTarget: "직전 6개월 무실적 고객 프로모션 (장기할부 불가 상품)",
    cardPlateImageUrl: "",
    cardPlateOrientation: "horizontal",
    supports36Months: false,
    promo36Months: false,
    specs: {
      targetDevice: "통신사 전회선 (자동이체)",
      minPayment: "장기할부 불가 (요금할인 전용)",
      autoTransfer: "자동이체 필수",
      annualFee: "2.5만원",
      installmentInterest: "해당 없음 (할부이자 0원)",
      applyMethod: "발급 QR코드 스캔 / 고객센터"
    },
    summary: {
      installmentSub: "※ 통신요금 자동이체 시 매월 이용실적에 따라 통신비가 청구할인됩니다."
    },
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인 (최대 24개월)",
        condition: "신규 발급 또는 6개월 무실적 고객",
        highlight: "매월 최대 29,000원",
        tiers: [
          { label: "전월 40만원 이상", amount: "월 28,000원 할인", amountNum: 28000, baseAmount: "5,000", promoAmount: "23,000", sub: "기본 5,000원 + 프로모션 23,000원 (이후 0.5만)", total24: "24개월 총 672,000원 할인", total24Num: 672000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 },
          { label: "전월 80만원 이상", amount: "월 29,000원 할인", amountNum: 29000, baseAmount: "8,000", promoAmount: "21,000", sub: "기본 8,000원 + 프로모션 21,000원 (이후 0.8만)", total24: "24개월 총 696,000원 할인", total24Num: 696000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 }
        ]
      }
    ],
    basicBenefits: [
      "통신비 제외, 아파트 관리비 제외, 학교납입금 & 교통비 제외",
      "롯데백화점 5% 할인쿠폰 및 무료주차권"
    ],
    details: [
      "본 카드는 장기할부 불가 상품입니다 (자동이체 전용 요금할인)",
      "롯데카드는 가족카드 발급 불가"
    ]
  },

  {
    id: "lgu_lotte_loca",
    carrier: "LGU",
    type: "bill",
    typeLabel: "요금할인",
    cardCompany: "롯데카드",
    cardName: "LG U+ × LOCA",
    theme: "theme-red",
    highlightBadge: "36개월 최대 79.2만원 요금할인 & 30만 실적 2만 할인",
    phone: "롯데카드 고객센터 1588-8100",
    applyUrl: "http://m.lottecard.co.kr",
    eventTarget: "직전 6개월 무실적 고객 프로모션 (가족카드 발급 불가)",
    cardPlateImageUrl: "",
    cardPlateOrientation: "horizontal",
    supports36Months: true,
    promo36Months: true,
    specs: {
      targetDevice: "통신사 전회선 (자동이체)",
      minPayment: "최소결제금액 5만원 이상",
      autoTransfer: "자동이체 필수 (장기할부 선택)",
      annualFee: "2만원",
      installmentInterest: "24개월 연 7.0%",
      applyMethod: "발급 QR코드 스캔 / 고객센터"
    },
    summary: {
      installmentSub: "※ 통신요금 자동이체 시 매월 이용실적에 따라 통신비가 청구할인됩니다."
    },
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인 (최대 36개월)",
        condition: "신규 발급 또는 6개월 무실적 고객",
        highlight: "매월 최대 22,000원 (36개월 기준)",
        tiers: [
          { label: "전월 30만원 이상", amount: "월 20,000원 할인", amountNum: 20000, baseAmount: "6,000", promoAmount: "14,000", sub: "기본 6,000원 + 프로모션 14,000원 (이후 0.6만)", total24: "24개월 총 480,000원 할인", total24Num: 480000, total36: "36개월 총 720,000원 할인", total36Num: 720000, total36Note: "36개월간 월 20,000원 청구할인" },
          { label: "전월 70만원 이상", amount: "월 21,000원 할인", amountNum: 21000, baseAmount: "8,000", promoAmount: "13,000", sub: "기본 8,000원 + 프로모션 13,000원 (이후 0.8만)", total24: "24개월 총 504,000원 할인", total24Num: 504000, total36: "36개월 총 756,000원 할인", total36Num: 756000, total36Note: "36개월간 월 21,000원 청구할인" },
          { label: "전월 120만원 이상", amount: "월 22,000원 할인", amountNum: 22000, baseAmount: "10,000", promoAmount: "12,000", sub: "기본 10,000원 + 프로모션 12,000원 (이후 1.0만)", total24: "24개월 총 528,000원 할인", total24Num: 528000, total36: "36개월 총 792,000원 할인", total36Num: 792000, total36Note: "36개월간 월 22,000원 청구할인 (총 79.2만원)" }
        ]
      }
    ],
    basicBenefits: [
      "통신비 제외, 아파트 관리비 제외, 학교납입금 & 교통비 제외"
    ],
    details: [
      "자동이체 필수 등록 (장기할부 선택 시 5만원 이상 & 연 7.0%)",
      "롯데카드는 가족카드 발급 불가"
    ]
  },

  {
    id: "lgu_hana_family",
    carrier: "LGU",
    type: "bill",
    typeLabel: "요금할인",
    cardCompany: "하나카드",
    cardName: "LG U+ family 카드",
    theme: "theme-teal",
    highlightBadge: "통신요금 납부액 25% 청구할인 & 최대 60만원 할인",
    phone: "하나카드 고객센터 1800-4701",
    applyUrl: "tel:18004701",
    eventTarget: "1~24개월차 통신요금 25% 할인, 25개월차부터 15% 할인 (6개월 무실적 고객)",
    cardPlateImageUrl: "",
    cardPlateOrientation: "horizontal",
    supports36Months: false,
    promo36Months: false,
    specs: {
      targetDevice: "통신사 전회선 (자동이체)",
      minPayment: "최소결제금액 10만원 이상",
      autoTransfer: "자동이체 필수 (장기할부 선택)",
      annualFee: "Master/UPI 2.5만 / AMEX 3.0만",
      installmentInterest: "24개월 연 5.9%",
      applyMethod: "전화 신청 1800-4701"
    },
    summary: {
      installmentSub: "※ 통신요금 자동이체 시 매월 이용실적에 따라 통신비가 청구할인됩니다."
    },
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 25% 프로모션할인 (최대 24개월)",
        condition: "신규 발급 또는 6개월 무실적 고객 (1~24회차 25% 할인)",
        highlight: "매월 최대 25,000원",
        tiers: [
          { label: "전월 30만원 이상", amount: "월 24,000원 할인", amountNum: 24000, baseAmount: "17,000", promoAmount: "7,000", sub: "통신요금 납부액 25% 할인 (25회차부터 1.7만)", total24: "24개월 총 576,000원 할인", total24Num: 576000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 },
          { label: "전월 70만원 이상", amount: "월 25,000원 할인", amountNum: 25000, baseAmount: "25,000", promoAmount: "0", sub: "통신요금 납부액 25% 할인 (25회차부터 2.5만)", total24: "24개월 총 600,000원 할인", total24Num: 600000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 }
        ]
      }
    ],
    basicBenefits: [
      "통신비 제외, 아파트 관리비 제외, 학교납입금 제외",
      "하나머니 기본 적립 및 가맹점 제휴 혜택"
    ],
    details: [
      "최소결제금액 10만원 이상 & 24개월 (할부이자 연 5.9%)",
      "자동이체 필수 등록"
    ]
  },

  {
    id: "lgu_nh_allone",
    carrier: "LGU",
    type: "bill",
    typeLabel: "요금할인",
    cardCompany: "NH농협카드",
    cardName: "NH농협 올원 U+",
    theme: "theme-green",
    highlightBadge: "최대 64.8만 할인 & 70만 실적 2.7만 청구할인",
    phone: "NH농협카드 고객센터 1644-4000",
    applyUrl: "https://card.nonghyup.com",
    eventTarget: "직전 6개월 무실적 프로모션 혜택 (자동이체 전용 상품)",
    cardPlateImageUrl: "",
    cardPlateOrientation: "horizontal",
    supports36Months: false,
    promo36Months: false,
    specs: {
      targetDevice: "통신사 전회선 (자동이체)",
      minPayment: "장기할부 없음 (자동이체 전용)",
      autoTransfer: "자동이체 필수",
      annualFee: "W 1.5만원 / Master 1.7만원",
      installmentInterest: "해당 없음 (할부이자 0원)",
      applyMethod: "발급 QR코드 스캔 / 고객센터"
    },
    summary: {
      installmentSub: "※ 통신요금 자동이체 시 매월 이용실적에 따라 통신비가 청구할인됩니다."
    },
    promotions: [
      {
        badge: "프로모션할인",
        title: "매월 통신요금 프로모션할인 (최대 24개월)",
        condition: "신규 발급 또는 6개월 무실적 고객",
        highlight: "매월 최대 27,000원",
        tiers: [
          { label: "전월 30만원 이상", amount: "월 21,000원 할인", amountNum: 21000, baseAmount: "9,000", promoAmount: "12,000", sub: "기본 9,000원 + 프로모션 12,000원 (이후 0.9만)", total24: "24개월 총 504,000원 할인", total24Num: 504000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 },
          { label: "전월 70만원 이상", amount: "월 27,000원 할인", amountNum: 27000, baseAmount: "15,000", promoAmount: "12,000", sub: "기본 15,000원 + 프로모션 12,000원 (이후 1.5만)", total24: "24개월 총 648,000원 할인", total24Num: 648000, total36: "36개월 미지원 (24개월 전용)", total36Num: 0 }
        ]
      }
    ],
    basicBenefits: [
      "통신비 제외, 아파트 관리비 제외, 학교납입금 제외",
      "농협 하나로클럽 및 농협 계열사 할인 혜택"
    ],
    details: [
      "자동이체 필수 등록 (장기할부 없음)",
      "전월실적 제외: 상품권, 세금, 공과금 등"
    ]
  }
];
