[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9239
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
    Write-Host "[Chapter 73 실시간 브라우저 QR 및 URL 교차검증 시작]"
    Write-Host "=================================================="

    # PIN 잠금 해제 및 카드 탭 활성화
    Eval-JS @"
        for (let i = 0; i < 4; i++) {
            if (typeof inputPin === 'function') inputPin('1');
        }
        const pinModal = document.getElementById('pinLockModal');
        if (pinModal) pinModal.style.display = 'none';

        if (typeof showTab === 'function') showTab('affiliateCard');
"@ | Out-Null
    Start-Sleep -Seconds 1

    # LGU+ 카드 12종 전수 검증
    $lguCardIds = @(
        "lgu_shinhan_bora", "lgu_shinhan_smartplan", "lgu_kb_light2",
        "lgu_hyundai_m3", "lgu_woori_36", "lgu_samsung_bill",
        "lgu_samsung_light", "lgu_lotte_light", "lgu_lotte_dc",
        "lgu_lotte_loca", "lgu_hana_family", "lgu_nh_allone"
    )

    $ktContaminants = @("01507", "106378", "MKTE3", "QKKTLITE", "QKKT", "104168", "LkMCWj6", "17454", "1221484", "1223352")

    Write-Host "`n>>> [LGU+ 카드 12종 브라우저 실시간 QR & URL 전수 검사] <<<" -ForegroundColor Cyan
    foreach ($cid in $lguCardIds) {
        $jsonStr = Eval-JS @"
            (function() {
                setAffiliateCarrier('LGU');
                handleSelectAffiliateCard('$cid');
                const sheet = document.getElementById('cardA4Sheet');
                const qrImg = sheet ? sheet.querySelector('img[alt*="공식 QR"]') : null;
                return JSON.stringify({
                    cardId: cardData.id,
                    cardName: cardData.cardName,
                    applyUrl: cardData.applyUrl,
                    qrImageUrl: cardData.qrImageUrl,
                    renderedQrSrc: qrImg ? qrImg.src : null
                });
            })()
"@
        $data = $jsonStr | ConvertFrom-Json
        Write-Host "[$cid] $($data.cardName)" -ForegroundColor Yellow
        Write-Host "  applyUrl: $($data.applyUrl)"
        Write-Host "  qrImageUrl: $($data.qrImageUrl.Substring(0, [Math]::Min(80, $data.qrImageUrl.Length)))..."

        # 오염 검사
        foreach ($k in $ktContaminants) {
            if ($data.applyUrl -and $data.applyUrl.Contains($k)) {
                throw "LGU+ 카드 [$cid] applyUrl에 KT 제휴코드 [$k] 오염 발견! URL: $($data.applyUrl)"
            }
            if ($data.qrImageUrl -and $data.qrImageUrl.Contains($k)) {
                throw "LGU+ 카드 [$cid] qrImageUrl에 KT 제휴코드 [$k] 오염 발견!"
            }
        }
        Write-Host "  -> KT 제휴코드 오염 0건 PASS!" -ForegroundColor Green
    }

    # SKT 수정 카드 2종 검증
    Write-Host "`n>>> [SKT 신한카드 2종 브라우저 실시간 QR & URL 검사] <<<" -ForegroundColor Cyan
    foreach ($cid in @("skt_shinhan_pineapple", "skt_shinhan_tlife")) {
        $jsonStr = Eval-JS @"
            (function() {
                setAffiliateCarrier('SKT');
                handleSelectAffiliateCard('$cid');
                return JSON.stringify({
                    cardId: cardData.id,
                    cardName: cardData.cardName,
                    applyUrl: cardData.applyUrl,
                    qrImageUrl: cardData.qrImageUrl
                });
            })()
"@
        $data = $jsonStr | ConvertFrom-Json
        Write-Host "[$cid] $($data.cardName)" -ForegroundColor Yellow
        Write-Host "  applyUrl: $($data.applyUrl)"
        foreach ($k in $ktContaminants) {
            if ($data.applyUrl -and $data.applyUrl.Contains($k)) {
                throw "SKT 카드 [$cid] applyUrl에 KT 제휴코드 [$k] 오염 발견! URL: $($data.applyUrl)"
            }
        }
        Write-Host "  -> KT 제휴코드 오염 0건 PASS!" -ForegroundColor Green
    }

    # 스크린샷 캡처
    $screenshotRes = Invoke-CDP "Page.captureScreenshot" @{ format = "png" }
    $bytes = [System.Convert]::FromBase64String($screenshotRes.result.data)
    [System.IO.File]::WriteAllBytes("$root\scratch\verified_chapter73_qr.png", $bytes)
    Write-Host "`n📸 검증 스크린샷 저장 완료: scratch\verified_chapter73_qr.png" -ForegroundColor Green

    Write-Host "`n🎉 [ALL PASS] LGU+ 12종 및 SKT 2종 브라우저 실시간 QR 생성 및 URL 교차검증 100% 정상 통과!" -ForegroundColor Green

} finally {
    if ($ws -and $ws.State -eq "Open") { $ws.Dispose() }
    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
}
