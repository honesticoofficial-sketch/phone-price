$ErrorActionPreference = "Stop"

$eventMap = @{
    # SKT
    "skt_samsung_premium"   = "https://m.site.naver.com/282hO"
    "skt_hyundai_m3"         = "https://card.hyundaicard.com/EVENT?id=SKT7K&agentCode=L600100000000&eventCode=KTT02&pmotDtlCn=SKT7K&pmotClasCd=C0&tmYn=N&seprStagcd=X2"
    "skt_samsung_tlight"     = "https://m.site.naver.com/282hO"
    "skt_woori_tlight"       = "https://m.site.naver.com/1gafU"
    "skt_kb_tlight"          = "https://m.site.naver.com/1it3e"
    "skt_lotte_tlight"       = "https://m.site.naver.com/2gcOy"
    "skt_shinhan_tlight"     = "https://shcard.io/tlight6m"
    "skt_shinhan_pineapple"  = "https://shcard.io/pineapple6m"
    "skt_shinhan_tlife"      = "https://shcard.io/tandlife6m"
    "skt_kb_teconomy"        = "https://m.site.naver.com/1it3e"
    "skt_hyundai_m3_bill"    = "https://card.hyundaicard.com/EVENT?id=SKT7K&agentCode=L600100000000&eventCode=KTT02&pmotDtlCn=SKT7K&pmotClasCd=C0&tmYn=N&seprStagcd=X2"
    "skt_lotte_tello"        = "https://m.site.naver.com/2gcOy"
    "skt_samsung_tnana"      = "https://m.site.naver.com/282ih"

    # LGU+
    "lgu_shinhan_bora"       = "https://shcard.io/tlight6m"
    "lgu_shinhan_smartplan"  = "https://shcard.io/tlight6m"
    "lgu_kb_light2"          = "https://m.site.naver.com/1it3e"
    "lgu_hyundai_m3"         = "https://card.hyundaicard.com/EVENT?id=LGUAPGG&agentCode=L600100000000&eventCode=KTT6S&pmotDtlCn=LGUAPGG&pmotClasCd=C0&tmYn=N&seprStagCd=X2"
    "lgu_woori_36"           = "https://m.site.naver.com/1gafU"
    "lgu_samsung_light"      = "https://m.site.naver.com/282hO"
    "lgu_lotte_light"        = "https://m.site.naver.com/2gcOy"
    "lgu_samsung_bill"       = "https://m.site.naver.com/282hO"
    "lgu_lotte_dc"           = "https://m.site.naver.com/2gcOy"
    "lgu_lotte_loca"         = "https://m.site.naver.com/2gcOy"

    # KT
    "kt_hyundai_m3_2"        = "https://www.hyundaicard.com/cpc/cr/CPCCR0201_01.hc?cardWcd=MKTE3TP&eventCode=KTP9N"
    "kt_kb_plus"             = "https://m.site.naver.com/1it3e"
    "kt_shinhan_family_light"= "https://shcard.io/tlight6m"
    "kt_woori_super_dc"      = "https://m.site.naver.com/1gafU"
    "kt_samsung_s"           = "https://m.site.naver.com/282hO"
    "kt_lotte_dc"            = "https://m.site.naver.com/2gcOy"
    "kt_lotte_super_dc"      = "https://m.site.naver.com/2gcOy"
}

function Inject-EventUrls($filePath) {
    Write-Host "Processing $filePath..."
    $lines = Get-Content $filePath -Encoding UTF8
    $newLines = @()
    $currentCardId = $null
    $inCard = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        # Check card start
        if ($line -match 'id:\s*"([^"]+)"') {
            $currentCardId = $matches[1]
            $inCard = $true
        }

        # Check existing eventUrl
        if ($inCard -and $line -match '^\s*eventUrl:') {
            # Skip existing eventUrl line, we will insert updated one after applyUrl
            continue
        }

        $newLines += $line

        # Check applyUrl line
        if ($inCard -and $line -match '^\s*applyUrl:') {
            if ($eventMap.ContainsKey($currentCardId)) {
                $evtUrl = $eventMap[$currentCardId]
                $newLines += "    eventUrl: `"$evtUrl`","
                Write-Host "   Injected eventUrl for $currentCardId -> $evtUrl"
            }
        }

        if ($line -match '^\s*\},?\s*$') {
            $inCard = $false
            $currentCardId = $null
        }
    }

    [System.IO.File]::WriteAllLines($filePath, $newLines, [System.Text.Encoding]::UTF8)
    Write-Host "Saved $filePath"
}

Inject-EventUrls "C:\Users\User01\.gemini\antigravity\scratch\phone-price\skt_cards_data.js"
Inject-EventUrls "C:\Users\User01\.gemini\antigravity\scratch\phone-price\kt_cards_data.js"
Inject-EventUrls "C:\Users\User01\.gemini\antigravity\scratch\phone-price\lgu_cards_data.js"

Write-Host "Event URLs injection completed successfully!"
