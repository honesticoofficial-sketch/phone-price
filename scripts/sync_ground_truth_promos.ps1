$ErrorActionPreference = "Stop"

$eventMap = @{
    # SKT
    "삼성카드 T PREMIUM"           = "https://m.site.naver.com/282hO"
    "현대카드 M3 T라이트2"           = "https://card.hyundaicard.com/EVENT?id=SKT7K&agentCode=L600100000000&eventCode=KTT02&pmotDtlCn=SKT7K&pmotClasCd=C0&tmYn=N&seprStagcd=X2"
    "삼성카드 T라이트"               = "https://m.site.naver.com/282hO"
    "우리카드 T라이트"               = "https://m.site.naver.com/1gafU"
    "T라이트 KB국민카드"             = "https://m.site.naver.com/1it3e"
    "롯데카드 T 라이트 (Renewal)"    = "https://m.site.naver.com/2gcOy"
    "신한카드 T라이트"               = "https://shcard.io/tlight6m"
    "신한카드 파인애플"               = "https://shcard.io/pineapple6m"
    "신한카드 T&LIFE"             = "https://shcard.io/tandlife6m"
    "T-economy KB국민카드"        = "https://m.site.naver.com/1it3e"
    "현대카드 M3 통신할인형2.0"        = "https://card.hyundaicard.com/EVENT?id=SKT7K&agentCode=L600100000000&eventCode=KTT02&pmotDtlCn=SKT7K&pmotClasCd=C0&tmYn=N&seprStagcd=X2"
    "TELLO NE 롯데카드 (Renewal)" = "https://m.site.naver.com/2gcOy"
    "삼성카드 T나는혜택"              = "https://m.site.naver.com/282ih"

    # LGU+
    "신한카드 U+ Bora"            = "https://shcard.io/tlight6m"
    "신한카드 스마트플랜 Plus"         = "https://shcard.io/tlight6m"
    "LGU+ 라이트할부Ⅱ KB국민카드"      = "https://m.site.naver.com/1it3e"
    "M Edition 3 (통신할인형 2.0)" = "https://card.hyundaicard.com/EVENT?id=LGUAPGG&agentCode=L600100000000&eventCode=KTT6S&pmotDtlCn=LGUAPGG&pmotClasCd=C0&tmYn=N&seprStagCd=X2"
    "U+ x 36우리카드"             = "https://m.site.naver.com/1gafU"
    "U+ 라이트 삼성카드"             = "https://m.site.naver.com/282hO"
    "U+ x LOCA 라이트할부"         = "https://m.site.naver.com/2gcOy"
    "LG U+ 삼성카드"              = "https://m.site.naver.com/282hO"
    "U+ DC 롯데카드 (New)"        = "https://m.site.naver.com/2gcOy"
    "LG U+ x LOCA"            = "https://m.site.naver.com/2gcOy"

    # KT
    "KT 현대카드M Edition3 (통신할인형 2.0)" = "https://www.hyundaicard.com/cpc/cr/CPCCR0201_01.hc?cardWcd=MKTE3TP&eventCode=KTP9N"
    "KT KB 할부 Plus 카드"                  = "https://m.site.naver.com/1it3e"
    "KT 가족만족 신한카드 (라이트할부)"         = "https://shcard.io/tlight6m"
    "KT 우리카드 Super DC"                  = "https://m.site.naver.com/1gafU"
    "KT 삼성카드 S"                         = "https://m.site.naver.com/282hO"
    "KT DC 롯데카드"                        = "https://m.site.naver.com/2gcOy"
    "KT Super DC 롯데카드"                  = "https://m.site.naver.com/2gcOy"
}

function Sync-GroundTruth($jsonPath) {
    if (-not (Test-Path $jsonPath)) { return }
    $items = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($item in $items) {
        $cName = $item.card_name
        if ($eventMap.ContainsKey($cName)) {
            $item.urls.promo_url = $eventMap[$cName]
        }
    }
    $newJson = $items | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($jsonPath, $newJson, [System.Text.Encoding]::UTF8)
    Write-Host "Synced $jsonPath"
}

Sync-GroundTruth "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\ground_truth_skt_202611.json"
Sync-GroundTruth "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\ground_truth_lgu_202611.json"
Sync-GroundTruth "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\ground_truth_kt_202611.json"
