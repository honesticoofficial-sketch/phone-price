# scripts/verify_chapter72_cdp.ps1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9238
$htmlPath = "file:///C:/Users/User01/.gemini/antigravity/scratch/phone-price/index.html"
$root = "C:\Users\User01\.gemini\antigravity\scratch\phone-price"

# Kill existing Edge on port
Get-Process msedge -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*--remote-debugging-port=$port*" } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

$proc = Start-Process -FilePath $edgePath -ArgumentList "--remote-debugging-port=$port", "--headless=new", "--disable-gpu", "--disable-software-rasterizer", "--window-size=1600,1200", $htmlPath -PassThru
Start-Sleep -Seconds 3

try {
    $tabs = Invoke-RestMethod -Uri "http://localhost:$port/json/list"
    $pageTab = $tabs | Where-Object { $_.type -eq "page" -and $_.url -like "*index.html*" } | Select-Object -First 1
    if (-not $pageTab) { throw "index.html 탭을 찾을 수 없습니다." }

    $wsUrl = $pageTab.webSocketDebuggerUrl
    $ws = [System.Net.WebSockets.ClientWebSocket]::new()
    $cts = [System.Threading.CancellationTokenSource]::new()
    $ws.ConnectAsync([System.Uri]::new($wsUrl), $cts.Token).Wait()

    $cmdId = 1
    function Invoke-CDP($method, $params = @{}) {
        $script:cmdId++
        $msg = @{ id = $script:cmdId; method = $method; params = $params } | ConvertTo-Json -Depth 10 -Compress
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($msg)
        $segment = [System.ArraySegment[byte]]::new($bytes)
        $ws.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $cts.Token).Wait()

        $buffer = [byte[]]::new(65536 * 4)
        $ms = [System.IO.MemoryStream]::new()
        do {
            $recvSegment = [System.ArraySegment[byte]]::new($buffer)
            $result = $ws.ReceiveAsync($recvSegment, $cts.Token).Result
            $ms.Write($buffer, 0, $result.Count)
        } while (-not $result.EndOfMessage)

        $respBytes = $ms.ToArray()
        $respStr = [System.Text.Encoding]::UTF8.GetString($respBytes)
        return $respStr | ConvertFrom-Json
    }

    function Eval-JS($expr) {
        $res = Invoke-CDP "Runtime.evaluate" @{
            expression = $expr
            returnByValue = $true
        }
        if ($res.result.exceptionDetails) {
            throw "JS 에러: $($res.result.exceptionDetails.exception.description)"
        }
        return $res.result.result.value
    }

    Write-Host "=================================================="
    Write-Host "[Chapter 72 실시간 브라우저 CDP 검증 시작]"
    Write-Host "=================================================="

    # 1. PIN 잠금 해제 및 카드 탭 활성화
    Eval-JS @"
        for (let i = 0; i < 4; i++) {
            if (typeof inputPin === 'function') inputPin('1');
        }
        const pinModal = document.getElementById('pinLockModal');
        if (pinModal) pinModal.style.display = 'none';

        if (typeof showTab === 'function') showTab('affiliateCard');
"@ | Out-Null
    Start-Sleep -Seconds 1

    function Test-Card-Deep($carrier, $cardId) {
        Write-Host "`n--------------------------------------------------" -ForegroundColor Cyan
        Write-Host "🔍 [$carrier] 카드 검증: $cardId" -ForegroundColor Cyan
        Write-Host "--------------------------------------------------" -ForegroundColor Cyan

        $jsonStr = Eval-JS @"
            (function() {
                setAffiliateCarrier('$carrier');
                handleSelectAffiliateCard('$cardId');

                const sheet = document.getElementById('cardA4Sheet');
                if (!sheet) return JSON.stringify({ error: "cardA4Sheet not found" });

                const isPhoneQr = sheet.innerText.includes('전화신청 QR');
                const isApplyQr = sheet.innerText.includes('발급신청 QR');
                
                // 이벤트 배너 분기 확인
                const isEventApplyReq = sheet.innerText.includes('★ 이벤트 응모 필수');
                const isEventConfirmReq = sheet.innerText.includes('★ 이벤트 확인 필수');

                // 추가 프로모션 카드
                const bonusTitles = [];
                sheet.querySelectorAll('h4').forEach(h => {
                    const txt = h.innerText.trim();
                    if (txt.includes('캐시백') || txt.includes('프로모션') || txt.includes('KB Pay') || txt.includes('아이폰')) {
                        bonusTitles.push(txt);
                    }
                });

                // 윈도우 이모지 여부
                const hasGreenEmoji = sheet.innerText.includes('🟢');
                const hasRedEmoji = sheet.innerText.includes('🔴');

                // 실적 산정 기준 고객센터 안내 문구
                const hasInquiryNotice = sheet.innerText.includes('실적 산정 기준에 대한 자세한 문의는 카드사 고객센터로 문의 부탁드립니다');

                // 실적 인정/제외 최상단 항목들
                const incList = [];
                const excList = [];
                sheet.querySelectorAll('[class*="bg-emerald"] li').forEach(li => incList.push(li.innerText.trim()));
                sheet.querySelectorAll('[class*="bg-rose"] li').forEach(li => excList.push(li.innerText.trim()));

                return JSON.stringify({
                    cardName: cardData.cardName,
                    applyUrl: cardData.applyUrl,
                    isPhoneQr: isPhoneQr,
                    isApplyQr: isApplyQr,
                    isEventApplyReq: isEventApplyReq,
                    isEventConfirmReq: isEventConfirmReq,
                    bonusCount: bonusTitles.length,
                    bonusTitles: bonusTitles,
                    hasGreenEmoji: hasGreenEmoji,
                    hasRedEmoji: hasRedEmoji,
                    hasInquiryNotice: hasInquiryNotice,
                    firstIncluded: incList.slice(0, 3),
                    firstExcluded: excList.slice(0, 3)
                });
            })()
"@
        $data = $jsonStr | ConvertFrom-Json
        Write-Host "카드명:" $data.cardName -ForegroundColor Yellow
        Write-Host "공식 발급 URL:" $data.applyUrl
        Write-Host "QR 라벨: [발급신청 QR] =" $data.isApplyQr ", [전화신청 QR (존재하면 안됨)] =" $data.isPhoneQr
        Write-Host "이벤트 배너: [응모필수] =" $data.isEventApplyReq ", [확인필수] =" $data.isEventConfirmReq
        Write-Host "추가 프로모션 개수:" $data.bonusCount "개 -> 제목:" ($data.bonusTitles -join " | ")
        Write-Host "윈도우 이모지(🟢, 🔴) 존재 여부: 초록 =" $data.hasGreenEmoji ", 빨강 =" $data.hasRedEmoji
        Write-Host "고객센터 문의 문구 표시:" $data.hasInquiryNotice
        Write-Host "실적 인정 상위 3항목:" ($data.firstIncluded -join " / ")
        Write-Host "실적 제외 상위 3항목:" ($data.firstExcluded -join " / ")

        return $data
    }

    # 1. skt_kb_tlight
    $d1 = Test-Card-Deep "SKT" "skt_kb_tlight"
    if ($d1.isPhoneQr -or -not $d1.isApplyQr) { throw "skt_kb_tlight QR 라벨 검증 실패" }
    if ($d1.bonusCount -lt 2) { throw "skt_kb_tlight 캐시백 분리 실패 (최소 2개여야 함)" }
    if ($d1.hasGreenEmoji -or $d1.hasRedEmoji) { throw "윈도우 이모지 발견" }
    if (-not $d1.hasInquiryNotice) { throw "고객센터 문의 문구 누락" }

    # 2. lgu_kb_light2
    $d2 = Test-Card-Deep "LGU" "lgu_kb_light2"
    if ($d2.isPhoneQr -or -not $d2.isApplyQr) { throw "lgu_kb_light2 발급신청 QR 복원 실패" }
    if ($d2.bonusCount -lt 2) { throw "lgu_kb_light2 캐시백 분리 실패" }
    if (-not $d2.isEventConfirmReq) { throw "lgu_kb_light2 이벤트 확인필수 배너 누락" }

    # 3. skt_hyundai_m3 (현대카드 응모 필수)
    $d3 = Test-Card-Deep "SKT" "skt_hyundai_m3"
    if (-not $d3.isEventApplyReq) { throw "skt_hyundai_m3 이벤트 응모필수 배너 누락" }

    # 4. lgu_shinhan_bora (LGU+ 발급신청 QR)
    $d4 = Test-Card-Deep "LGU" "lgu_shinhan_bora"
    if ($d4.isPhoneQr -or -not $d4.isApplyQr) { throw "lgu_shinhan_bora 발급신청 QR 복원 실패" }
    if (-not $d4.isEventConfirmReq) { throw "lgu_shinhan_bora 이벤트 확인필수 배너 누락" }

    # 5. kt_lotte_light
    $d5 = Test-Card-Deep "KT" "kt_lotte_light"
    if ($d5.isPhoneQr -or -not $d5.isApplyQr) { throw "kt_lotte_light 발급신청 QR 확인 실패" }

    # 스크린샷 캡처
    $screenshotRes = Invoke-CDP "Page.captureScreenshot" @{ format = "png" }
    $bytes = [System.Convert]::FromBase64String($screenshotRes.result.data)
    [System.IO.File]::WriteAllBytes("$root\scratch\verified_chapter72.png", $bytes)
    Write-Host "`n📸 검증 스크린샷 저장 완료: scratch\verified_chapter72.png" -ForegroundColor Green

    Write-Host "`n🎉 [ALL PASS] 5대 핵심 요구사항 100% 전수 검증 통과!" -ForegroundColor Green

} finally {
    if ($ws -and $ws.State -eq "Open") { $ws.Dispose() }
    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
}
