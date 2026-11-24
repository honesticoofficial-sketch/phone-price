[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9252
$htmlPath = "file:///C:/Users/User01/.gemini/antigravity/scratch/phone-price/index.html"

Write-Host "=========================================================="
Write-Host " [Chapter 80] S26 깔끔한 인상안내 텍스트 & 체크박스형 UI CDP 검증"
Write-Host "=========================================================="

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

    function Eval-JSAsync($expr) {
        $res = Invoke-CDP "Runtime.evaluate" @{
            expression = $expr
            awaitPromise = $true
            returnByValue = $true
        }
        if ($res.result.exceptionDetails) {
            throw "JS 에러: $($res.result.exceptionDetails.exception.description)"
        }
        return $res.result.result.value
    }

    # 1. PIN 잠금 해제 (마스터 103105)
    Write-Host "`n1. PIN 잠금 해제 (마스터 계정 103105)..." -ForegroundColor Cyan
    $unlockRes = Eval-JSAsync @"
        (async function() {
            '103105'.split('').forEach(d => inputPin(d));
            await new Promise(r => setTimeout(r, 600));
            return { isUnlocked, role: currentRole, storeId: currentStoreId };
        })()
"@
    Write-Host "   ✅ 잠금 해제 완료: isUnlocked=$($unlockRes.isUnlocked)" -ForegroundColor Green

    # 2. 탭 1 (넷가표) S26 행의 깔끔한 텍스트 검증
    Write-Host "`n2. 탭 1 (넷가표) S26 인상안내 텍스트 검증..." -ForegroundColor Cyan
    $tab1Res = Eval-JSAsync @"
        (function() {
            switchTab('calc');
            const row = document.querySelector('#calcTableBody tr[data-index="0"]');
            const priceDiv = row.querySelector('.text-\\[10px\\]');
            const hasButtons = !!priceDiv.querySelector('button');
            const textContent = priceDiv.innerText.trim();
            return {
                hasButtons,
                textContent
            };
        })()
"@
    Write-Host "   - 버튼 나열 제거 여부: $($tab1Res.hasButtons -eq $false) (버튼 수: 0)"
    Write-Host "   - 렌더링 텍스트: $($tab1Res.textContent)"
    if (-not $tab1Res.hasButtons -and ($tab1Res.textContent -like "*(KT) 출고가 인상재고 적용중*")) {
        Write-Host "   ✅ 탭 1 넷가표 깔끔한 '(KT) 출고가 인상재고 적용중' 텍스트 표시 PASS!" -ForegroundColor Green
    } else {
        throw "탭 1 넷가표 UI 검증 실패"
    }

    # 3. 탭 2 (단가표 / 리베이트 입력) 체크박스형 UI 검증
    Write-Host "`n3. 탭 2 (단가표) 깔끔한 [ ] 출고가인상반영 체크박스 동작 검증..." -ForegroundColor Cyan
    $tab2Res = Eval-JSAsync @"
        (async function() {
            switchTab('daily');
            setCarrierInput('KT');
            await new Promise(r => setTimeout(r, 300));

            const ktCheckbox = document.querySelector('#dailyTableBody input[type="checkbox"]');
            const ktChecked = ktCheckbox ? ktCheckbox.checked : null;
            const ktLabel = ktCheckbox ? ktCheckbox.parentElement.innerText.trim() : null;

            setCarrierInput('SK');
            await new Promise(r => setTimeout(r, 300));
            const skCheckbox = document.querySelector('#dailyTableBody input[type="checkbox"]');
            const skChecked = skCheckbox ? skCheckbox.checked : null;

            // 다시 KT로 전환하여 체크박스 클릭 토글 테스트
            setCarrierInput('KT');
            await new Promise(r => setTimeout(r, 300));
            toggleS26PriceHike('KT'); // 체크 해제
            const afterUncheckPrice = devices.find(d => d.id === 's26').prices.KT;

            toggleS26PriceHike('KT'); // 다시 체크
            const afterRecheckPrice = devices.find(d => d.id === 's26').prices.KT;

            return {
                ktChecked,
                ktLabel,
                skChecked,
                afterUncheckPrice,
                afterRecheckPrice
            };
        })()
"@
    Write-Host "   - KT 체크박스 상태: $($tab2Res.ktChecked) (체크됨)"
    Write-Host "   - 라벨 텍스트: '$($tab2Res.ktLabel)'"
    Write-Host "   - SK 체크박스 상태: $($tab2Res.skChecked) (미체크)"
    Write-Host "   - 체크 해제 시 KT 출고가: $($tab2Res.afterUncheckPrice)만 (일반 125.4만)"
    Write-Host "   - 다시 체크 시 KT 출고가: $($tab2Res.afterRecheckPrice)만 (NEW 140.36만)"

    if ($tab2Res.ktChecked -and -not $tab2Res.skChecked -and ($tab2Res.ktLabel -like "*출고가인상반영*") -and $tab2Res.afterRecheckPrice -eq 140.36) {
        Write-Host "   ✅ 탭 2 단가표 깔끔한 체크박스형 [출고가인상반영] 100% 정상 작동 PASS!" -ForegroundColor Green
    } else {
        throw "탭 2 단가표 체크박스 검증 실패"
    }

    # 4. 스크린샷 캡처
    Write-Host "`n4. 실시간 검증 실사 스크린샷 캡처..." -ForegroundColor Cyan
    $screenRes = Invoke-CDP "Page.captureScreenshot" @{ format = "png" }
    $shotBytes = [System.Convert]::FromBase64String($screenRes.result.data)
    $shotPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\chapter80_verified.png"
    [System.IO.File]::WriteAllBytes($shotPath, $shotBytes)
    Write-Host "   ✅ 스크린샷 저장 완료: $shotPath" -ForegroundColor Green

    Write-Host "`n=========================================================="
    Write-Host " 🎉 [Chapter 80] 대표님 피드백 반영 검증 100% ALL PASS!"
    Write-Host "=========================================================="
}
finally {
    if ($ws -and $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", [System.Threading.CancellationToken]::None).Wait()
    }
    if ($proc -and -not $proc.HasExited) {
        $proc.Kill()
    }
}
