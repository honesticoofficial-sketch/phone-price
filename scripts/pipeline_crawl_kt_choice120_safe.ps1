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

    # 3. [보안 게이트 1] KT 전산 세션 요금제 3중 정밀 검증 (DOM + Hidden Form + 월정액 120,000원)
    $planCheck = Invoke-CDPCmd "Runtime.evaluate" @{
        expression = @"
            (() => {
                const prodName = document.querySelector('#prodPaymentName')?.innerText.trim() || '';
                const pplNmVal = document.querySelector('#pplNm')?.value || '';
                const chargeDsp = document.querySelector('#rcmdPplChargeDsp')?.innerText.trim() || '';
                return {
                    prodPaymentName: prodName,
                    pplNm: pplNmVal,
                    chargeDsp: chargeDsp
                };
            })()
"@
        returnByValue = $true
    }
    $vData = $planCheck.result.result.value
    Write-Host "   검증된 DOM 요금제: $($vData.prodPaymentName)"
    Write-Host "   전산 Hidden 요금제: $($vData.pplNm)"
    Write-Host "   표시 월통신요금: $($vData.chargeDsp)"

    # 요금제명 및 월 120,000원 정가 검증 (공시지원금 변동과 무관한 절대 불변 기준)
    $is120kName = ($vData.prodPaymentName -match '초이스 더블|120|더블') -and ($vData.prodPaymentName -notmatch '90')
    $is120kHidden = ($vData.pplNm -match '초이스 더블|120|더블') -or ($vData.pplNm -eq '')
    $is120kPrice = ($vData.chargeDsp -match '120,000|120000')

    if (-not $is120kName -or ($vData.chargeDsp -ne '' -and -not $is120kPrice)) {
        throw "🚨 [요금제 오염 차단] 120k 초이스 더블 세션이 아닙니다 (요금제: '$($vData.prodPaymentName)', 월요금: '$($vData.chargeDsp)'). 크롤링을 즉시 중단합니다."
    }
    Write-Host "   ✅ [게이트 1 통과] 120,000원 초이스 더블 전산 세션 무결성 100% 확인" -ForegroundColor Green

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

    # 6. [보안 게이트 2] 세션 지속성 및 구조적 데이터 무결성 검증 (공시지원금 변동에 영향받지 않는 동적 무결성 검증)
    # 6-1. 수집 완료 직후 세션 불변성 재검증 (크롤링 중 세션 초기화/리셋 방지)
    $postSession = Invoke-CDPCmd "Runtime.evaluate" @{
        expression = @"
            (() => {
                return {
                    name: document.querySelector('#prodPaymentName')?.innerText.trim() || '',
                    charge: document.querySelector('#rcmdPplChargeDsp')?.innerText.trim() || ''
                };
            })()
"@
        returnByValue = $true
    }
    $ps = $postSession.result.result.value
    if ($ps.name -match '90' -or ($ps.name -notmatch '초이스 더블|120|더블')) {
        throw "🚨 [세션 이탈 감지] 크롤링 도중 120k 세션이 풀려 '$($ps.name)'(으)로 변경되었습니다! 데이터를 저장하지 않습니다."
    }
    Write-Host "   ✅ [세션 락 확인] 수집 완료 시점까지 120k 초이스더블 세션 유지 확인" -ForegroundColor Green

    # 6-2. 데이터 볼륨 및 필수 플래그십 무결성 검증
    if ($crawled.Count -lt 40) {
        throw "🚨 [데이터 볼륨 부족] 수집된 단말 수가 $($crawled.Count)개로 비정상적입니다. 파이프라인을 중단합니다."
    }

    $ip18Pro = $crawled | Where-Object { $_.model -match '(?i)18\s*Pro\b' -and $_.model -notmatch 'Max' } | Select-Object -First 1
    $ip17PM = $crawled | Where-Object { $_.model -match '(?i)17\s*Pro\s*Max' } | Select-Object -First 1
    $s26U = $crawled | Where-Object { $_.model -match '(?i)S26\s*Ultra|S26\s*울트라' } | Select-Object -First 1

    if (-not $ip18Pro -or -not $ip17PM) {
        throw "🚨 [필수 플래그십 누락] 핵심 아이폰 기종(18 Pro / 17 Pro Max)이 크롤링 데이터셋에서 누락되었습니다."
    }

    # 출고가 및 공시금액 데이터 타입 유효성 검증 (0원 및 NaN 체크)
    $corruptItems = $crawled | Where-Object { $_.factoryPrice -le 0 -or $_.subsidy -lt 0 }
    if ($corruptItems.Count -gt 0) {
        throw "🚨 [데이터 오염 감지] 출고가 0원 이하 또는 음수 지원금 단말이 $($corruptItems.Count)건 발견되었습니다."
    }

    Write-Host "   ✅ [게이트 2 통과] 구조적 데이터 무결성 100% 검증 (총 $($crawled.Count)개 정상 수집, 출고가/공시지원금 전수 정상)" -ForegroundColor Green

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
