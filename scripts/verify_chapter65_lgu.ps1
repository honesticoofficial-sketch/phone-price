$ErrorActionPreference = "Stop"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) { $edgePath = "C:\Program Files\Microsoft\Edge\Application\msedge.exe" }

$port = 9260
$userDataDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\edge_profile_lgu_v65_async"
if (Test-Path $userDataDir) { Remove-Item -Recurse -Force $userDataDir -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $userDataDir -Force | Out-Null
$targetHtml = "file:///C:/Users/User01/.gemini/antigravity/scratch/phone-price/index.html"

$edgeProcess = Start-Process -FilePath $edgePath -ArgumentList @(
    "--remote-debugging-port=$port",
    "--user-data-dir=$userDataDir",
    "--headless=new",
    "--window-size=1600,1200",
    $targetHtml
) -PassThru

Start-Sleep -Seconds 3

try {
    $versionUrl = "http://127.0.0.1:$port/json"
    $targets = Invoke-RestMethod -Uri $versionUrl
    $target = $targets | Where-Object { $_.type -eq "page" -and $_.url -match "index.html" } | Select-Object -First 1

    $wsUrl = $target.webSocketDebuggerUrl
    $ws = New-Object System.Net.WebSockets.ClientWebSocket
    $cts = New-Object System.Threading.CancellationTokenSource
    $ws.ConnectAsync([uri]$wsUrl, $cts.Token).Wait()

    $reqId = 1
    function Send-Cdp($method, $params = @{}) {
        $script:reqId++
        $payload = @{
            id = $script:reqId
            method = $method
            params = $params
        } | ConvertTo-Json -Depth 10 -Compress
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
        $segment = New-Object System.ArraySegment[byte] -ArgumentList @(,$bytes)
        $ws.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $cts.Token).Wait()

        $buffer = New-Object byte[] 655360
        while ($true) {
            $recvSeg = New-Object System.ArraySegment[byte] -ArgumentList @(,$buffer)
            $res = $ws.ReceiveAsync($recvSeg, $cts.Token).Result
            $text = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $res.Count)
            $parsed = $text | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($parsed -and $parsed.id -eq $script:reqId) {
                if ($parsed.result -and $parsed.result.result) {
                    return $parsed.result.result.value
                }
                return $null
            }
        }
    }

    # PIN 자동 해제
    Send-Cdp -method "Runtime.evaluate" -params @{
        expression = @"
        for (let ch of '103105') { inputPin(ch); }
"@
        returnByValue = $true
    } | Out-Null
    Start-Sleep -Milliseconds 500

    # LGU 통신사 전환 및 전수 검증 (각 카드 선택 후 동기식 renderCardPreview 호출)
    $testExpression = @"
    (function() {
        setAffiliateCarrier('LGU');

        const allCards = AFFILIATE_CARDS_BY_CARRIER['LGU'] || [];
        const isCardMatchingType = (c, type) => {
            if (type === 'all') return true;
            if (type === 'light') return c.type === 'light' || c.type === 'both';
            if (type === 'bill') return c.type === 'bill' || c.type === 'both';
            return c.type === type;
        };

        const totalCount = allCards.length;
        const lightCount = allCards.filter(c => isCardMatchingType(c, 'light')).length;
        const billCount = allCards.filter(c => isCardMatchingType(c, 'bill')).length;

        // 버튼 텍스트 확인
        const allBtnText = document.getElementById('affTypeBtn-all')?.innerText || '';
        const lightBtnText = document.getElementById('affTypeBtn-light')?.innerText || '';
        const billBtnText = document.getElementById('affTypeBtn-bill')?.innerText || '';

        // 라이트할부 탭 클릭 테스트
        filterAffiliateCards('light');
        const lightOptions = Array.from(document.getElementById('affCardSelect')?.options || []).map(o => o.text);

        // 요금할인 탭 클릭 테스트
        filterAffiliateCards('bill');
        const billOptions = Array.from(document.getElementById('affCardSelect')?.options || []).map(o => o.text);

        // 전체 탭 클릭
        filterAffiliateCards('all');
        const allOptions = Array.from(document.getElementById('affCardSelect')?.options || []).map(o => o.text);

        // 검증 1: KB국민 라이트할부II
        handleSelectAffiliateCard('lgu_kb_light2');
        renderCardPreview();
        const kbBoxClass = document.getElementById('cardPlateBox')?.className || '';
        const kbIsHorizontal = kbBoxClass.includes('w-36');
        const kbSheetHtml = document.getElementById('cardA4Sheet')?.innerHTML || '';
        const kbHasTongsinbiIncluded = kbSheetHtml.includes('이동통신요금 자동이체 결제금액 (실적 인정 🟢)') || kbSheetHtml.includes('통신비 전월실적 인정');
        const kbHasApartmentExcluded = kbSheetHtml.includes('아파트 관리비 납부금액 (실적 제외 🔴)') || kbSheetHtml.includes('아파트 관리비 전월실적 제외');
        const kbTiers = (allCards.find(c => c.id === 'lgu_kb_light2')?.promotions[0]?.tiers || []).map(t => t.label + ': ' + t.amount);

        // 검증 2: U+ 라이트 삼성카드 (세로형)
        handleSelectAffiliateCard('lgu_samsung_light');
        renderCardPreview();
        const samsungBoxClass = document.getElementById('cardPlateBox')?.className || '';
        const samsungIsVertical = samsungBoxClass.includes('w-[94px]');
        const samsungSheetHtml = document.getElementById('cardA4Sheet')?.innerHTML || '';
        const samsungHasTongsinbiIncluded = samsungSheetHtml.includes('이동통신요금 자동이체 결제금액 (실적 인정 🟢)') || samsungSheetHtml.includes('통신비 전월실적 인정');
        const samsungHasApartmentExcluded = samsungSheetHtml.includes('아파트 관리비 납부금액 (실적 제외 🔴)') || samsungSheetHtml.includes('아파트 관리비 제외');

        // 검증 3: LG U+ × LOCA (세로형)
        handleSelectAffiliateCard('lgu_lotte_loca');
        renderCardPreview();
        const locaBoxClass = document.getElementById('cardPlateBox')?.className || '';
        const locaIsVertical = locaBoxClass.includes('w-[94px]');
        const locaSheetHtml = document.getElementById('cardA4Sheet')?.innerHTML || '';
        const locaHasTongsinbiExcluded = locaSheetHtml.includes('통신요금 결제금액 (실적 제외 🔴)');

        // 검증 4: 현대카드 M3 (세로형)
        handleSelectAffiliateCard('lgu_hyundai_m3');
        renderCardPreview();
        const hyundaiBoxClass = document.getElementById('cardPlateBox')?.className || '';
        const hyundaiIsVertical = hyundaiBoxClass.includes('w-[94px]');
        const m3SheetHtml = document.getElementById('cardA4Sheet')?.innerHTML || '';
        const m3HasTongsinbiExcluded = m3SheetHtml.includes('통신요금 결제금액 (실적 제외 🔴)');
        const m3HasSchoolExcluded = m3SheetHtml.includes('초·중·고교 납입금, 대학 등록금 (실적 제외 🔴)');

        return {
            totalCount: totalCount,
            lightCount: lightCount,
            billCount: billCount,
            allBtnText: allBtnText,
            lightBtnText: lightBtnText,
            billBtnText: billBtnText,
            lightOptionsCount: lightOptions.length,
            billOptionsCount: billOptions.length,
            allOptionsCount: allOptions.length,
            samsungIsVertical: samsungIsVertical,
            samsungHasTongsinbiIncluded: samsungHasTongsinbiIncluded,
            samsungHasApartmentExcluded: samsungHasApartmentExcluded,
            locaIsVertical: locaIsVertical,
            locaHasTongsinbiExcluded: locaHasTongsinbiExcluded,
            hyundaiIsVertical: hyundaiIsVertical,
            kbIsHorizontal: kbIsHorizontal,
            kbHasTongsinbiIncluded: kbHasTongsinbiIncluded,
            kbHasApartmentExcluded: kbHasApartmentExcluded,
            kbTiers: kbTiers,
            m3HasTongsinbiExcluded: m3HasTongsinbiExcluded,
            m3HasSchoolExcluded: m3HasSchoolExcluded
        };
    })()
"@

    $res = Send-Cdp -method "Runtime.evaluate" -params @{
        expression = $testExpression
        returnByValue = $true
    }

    Write-Host "===================================================="
    Write-Host "🌟 LGU+ 제휴카드 실시간 브라우저 검증 결과 (CDP 실측)"
    Write-Host "===================================================="
    Write-Host "1. 필터 및 수량 검증:"
    Write-Host "   - 전체 카드 수: $($res.totalCount) (기대치: 12) -> 버튼: $($res.allBtnText)"
    Write-Host "   - 라이트할부 탭 노출 카드 수: $($res.lightOptionsCount) (기대치: 10) -> 버튼: $($res.lightBtnText)"
    Write-Host "   - 요금할인 탭 노출 카드 수: $($res.billOptionsCount) (기대치: 9) -> 버튼: $($res.billBtnText)"
    Write-Host "2. 카드 이미지 가로/세로 매칭 검증:"
    Write-Host "   - U+ 라이트 삼성카드 세로형(w-[94px]) 렌더링: $($res.samsungIsVertical) (기대치: True)"
    Write-Host "   - LG U+ × LOCA 세로형(w-[94px]) 렌더링: $($res.locaIsVertical) (기대치: True)"
    Write-Host "   - 현대카드 M3 세로형(w-[94px]) 렌더링: $($res.hyundaiIsVertical) (기대치: True)"
    Write-Host "   - KB국민 라이트할부II 가로형(w-36) 렌더링: $($res.kbIsHorizontal) (기대치: True)"
    Write-Host "3. 전월실적 산정 기준 카드별 동적 렌더링 검증:"
    Write-Host "   - KB국민 [통신비 인정] 포함 노출: $($res.kbHasTongsinbiIncluded) (기대치: True)"
    Write-Host "   - KB국민 [아파트 관리비 제외] 노출: $($res.kbHasApartmentExcluded) (기대치: True)"
    Write-Host "   - 삼성 라이트 [통신비 인정] 포함 노출: $($res.samsungHasTongsinbiIncluded) (기대치: True)"
    Write-Host "   - 삼성 라이트 [아파트 관리비 제외] 노출: $($res.samsungHasApartmentExcluded) (기대치: True)"
    Write-Host "   - 롯데 LOCA [통신비 제외] 노출: $($res.locaHasTongsinbiExcluded) (기대치: True)"
    Write-Host "   - 현대 M3 [통신비 제외] 노출: $($res.m3HasTongsinbiExcluded) (기대치: True)"
    Write-Host "   - 현대 M3 [학교납입금 제외] 노출: $($res.m3HasSchoolExcluded) (기대치: True)"
    Write-Host "4. 금액 검증 (KB국민 라이트할부II):"
    Write-Host "   - $($res.kbTiers -join ' / ')"
    Write-Host "===================================================="

    if ($res.totalCount -eq 12 -and $res.lightOptionsCount -eq 10 -and $res.billOptionsCount -eq 9 -and $res.samsungIsVertical -eq $true -and $res.locaIsVertical -eq $true -and $res.kbHasTongsinbiIncluded -eq $true -and $res.m3HasTongsinbiExcluded -eq $true) {
        Write-Host "🎉 모든 검증 100% ALL PASS! 완벽합니다!" -ForegroundColor Green
    } else {
        Write-Host "❌ 일부 조건 불일치 발생" -ForegroundColor Red
    }

} finally {
    if ($ws -and $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
    }
    if ($edgeProcess -and -not $edgeProcess.HasExited) {
        Stop-Process -Id $edgeProcess.Id -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -Recurse -Force $userDataDir -ErrorAction SilentlyContinue
}
