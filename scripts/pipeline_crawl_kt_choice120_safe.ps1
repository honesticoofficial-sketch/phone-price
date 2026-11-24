[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

Write-Host "=========================================================="
Write-Host " [KT 초이스 더블 120k 안전 보장 자동 크롤러]"
Write-Host " - 90요금제 오염 원천 차단 게이트웨이 내장"
Write-Host "=========================================================="

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9355

cmd.exe /c "taskkill /f /im msedge.exe 2>nul" | Out-Null
Start-Sleep -Milliseconds 800

$proc = Start-Process -FilePath $edgePath -ArgumentList "--remote-debugging-port=$port", "--headless=new", "--disable-gpu", "--window-size=1600,1200", "https://shop.kt.com/m/smart/supportAmtList.do" -PassThru
Start-Sleep -Seconds 7

$ws = $null
$cts = $null

try {
    $tabs = Invoke-RestMethod -Uri "http://localhost:$port/json/list"
    $pageTab = $tabs | Where-Object { $_.type -eq "page" } | Select-Object -First 1

    $ws = [System.Net.WebSockets.ClientWebSocket]::new()
    $cts = [System.Threading.CancellationTokenSource]::new()
    $ws.ConnectAsync([System.Uri]::new($pageTab.webSocketDebuggerUrl), $cts.Token).Wait()

    $cmdId = 1
    function Invoke-CDPCmd($method, $params = @{}) {
        $script:cmdId++
        $msg = @{ id = $script:cmdId; method = $method; params = $params } | ConvertTo-Json -Depth 10 -Compress
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($msg)
        $segment = [System.ArraySegment[byte]]::new($bytes)
        $ws.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $cts.Token).Wait()

        $buffer = [byte[]]::new(65536 * 8)
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

    # 1. 요금제 변경 팝업 오픈
    Write-Host "1. 요금제 변경 팝업 호출..."
    Invoke-CDPCmd "Runtime.evaluate" @{ expression = "document.querySelector('#btnPayChange')?.click()" }
    Start-Sleep -Seconds 2

    # 2. 초이스 더블 120k 선택 및 적용
    Write-Host "2. '초이스 더블' (120,000원) 선택 및 적용..."
    Invoke-CDPCmd "Runtime.evaluate" @{
        expression = @"
            (() => {
                let targetId = 'pplListObj_1103';
                if (typeof pplListObj !== 'undefined' && Array.isArray(pplListObj)) {
                    const found = pplListObj.find(p => (p.pplNm && (p.pplNm.includes('초이스 더블') || p.pplNm.includes('더블'))) || (p.punoMonthUseChage && p.punoMonthUseChage.includes('120')));
                    if (found) { targetId = 'pplListObj_' + found.pplId; }
                }
                if (typeof fnPplClick === 'function') {
                    fnPplClick(targetId);
                }
                document.getElementById('btnLayerItem')?.click();
            })()
"@
    }
    Start-Sleep -Seconds 4

    # 3. [보안 게이트 1] DOM 요금제명 실시간 무결성 검증
    $planCheck = Invoke-CDPCmd "Runtime.evaluate" @{
        expression = "document.querySelector('#prodPaymentName')?.innerText.trim()"
        returnByValue = $true
    }
    $verifiedPlan = $planCheck.result.result.value
    Write-Host "   검증된 DOM 요금제: $verifiedPlan"

    if ($verifiedPlan -match '90' -or $verifiedPlan -notmatch '초이스 더블|120|더블') {
        throw "🚨 [요금제 오염 차단] 120k 초이스 더블이 아닙니다: '$verifiedPlan'. 크롤링을 즉시 중단합니다."
    }
    Write-Host "   ✅ [게이트 통과] 120k 초이스 더블 100% 확인" -ForegroundColor Green

    # 4. 전체 리스트 로딩 (더보기 클릭)
    Write-Host "`n4. 전체 단말 로딩..."
    for ($i = 1; $i -le 6; $i++) {
        Invoke-CDPCmd "Runtime.evaluate" @{
            expression = @"
                (() => {
                    const btn = document.querySelector('#moreView, .btnProdMore');
                    if (btn && btn.offsetParent !== null && !btn.disabled) { btn.click(); }
                })()
"@
        }
        Start-Sleep -Seconds 2
    }

    # 5. 전 단말 데이터 추출
    Write-Host "`n5. 단말 데이터 추출..."
    $extract = Invoke-CDPCmd "Runtime.evaluate" @{
        expression = @"
            (() => {
                const list = [];
                document.querySelectorAll('.prodListWrap li').forEach(li => {
                    const name = li.querySelector('.prodInfo .prodName')?.innerText.trim();
                    let fPrice = 0, sub = 0, date = '';
                    const dateEl = li.querySelector('.prodInfo .date span:last-child');
                    if (dateEl) date = dateEl.innerText.trim();

                    li.querySelectorAll('.prodPayDetailIn li').forEach(subLi => {
                        const tit = subLi.querySelector('.tit')?.innerText.trim() || '';
                        const conts = subLi.querySelector('.conts')?.innerText.trim() || '';
                        if (tit.includes('출고가')) fPrice = parseInt(conts.replace(/[^0-9]/g, ''), 10) || 0;
                        if (tit.includes('공통지원금')) sub = parseInt(conts.replace(/[^0-9]/g, ''), 10) || 0;
                    });
                    if (name && (fPrice > 0 || sub > 0)) {
                        list.push({ model: name, factoryPrice: fPrice, subsidy: sub, date: date });
                    }
                });
                return list;
            })()
"@
        returnByValue = $true
    }

    $crawled = $extract.result.result.value
    Write-Host "   총 수집 단말: $($crawled.Count) 개"

    # 6. [보안 게이트 2] 90요금제 시그니처 단말 공시금액 역추적 검증
    # 90요금제일 때: 18 Pro = 400,000 / 17 Pro Max = 150,000
    # 120k 초이스더블일 때: 18 Pro = 450,000 / 17 Pro Max = 221,000
    $ip18Pro = $crawled | Where-Object { $_.model -match '(?i)18\s*Pro\b' -and $_.model -notmatch 'Max' } | Select-Object -First 1
    $ip17PM = $crawled | Where-Object { $_.model -match '(?i)17\s*Pro\s*Max' } | Select-Object -First 1

    if ($ip18Pro -and $ip18Pro.subsidy -eq 400000) {
        throw "🚨 [90요금제 시그니처 감지] iPhone 18 Pro 공시지원금이 40만 원(90요금제 값)으로 추출되었습니다! 크롤링 파이프라인을 비정상 종료합니다."
    }
    if ($ip17PM -and $ip17PM.subsidy -eq 150000) {
        throw "🚨 [90요금제 시그니처 감지] iPhone 17 Pro Max 공시지원금이 15만 원(90요금제 값)으로 추출되었습니다! 크롤링 파이프라인을 비정상 종료합니다."
    }
    Write-Host "   ✅ [게이트 통과] 90요금제 시그니처 0건 (18 Pro: $($ip18Pro.subsidy)원 / 17 Pro Max: $($ip17PM.subsidy)원)" -ForegroundColor Green

    # 7. 데이터 영구 저장
    $outJson = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\kt_full_items.json"
    $crawled | ConvertTo-Json -Depth 5 | Set-Content -Path $outJson -Encoding UTF8
    Write-Host "`n저장 완료: $outJson"

} finally {
    if ($ws -and $ws.State -eq 'Open') {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", [System.Threading.CancellationToken]::None).Wait()
    }
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}
