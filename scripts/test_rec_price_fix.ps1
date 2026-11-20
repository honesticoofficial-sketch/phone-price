# scripts/test_rec_price_fix.ps1
$ErrorActionPreference = "Stop"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9222
$htmlPath = "file:///C:/Users/User01/.gemini/antigravity/scratch/phone-price/index.html"

# Kill existing Edge instances on 9222
Get-Process msedge -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*--remote-debugging-port=$port*" } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

$proc = Start-Process -FilePath $edgePath -ArgumentList "--remote-debugging-port=$port", "--headless=new", "--disable-gpu", "--disable-software-rasterizer", "--window-size=1400,1000", $htmlPath -PassThru
Start-Sleep -Seconds 2

try {
    $tabs = Invoke-RestMethod -Uri "http://localhost:$port/json/list"
    $pageTab = $tabs | Where-Object { $_.type -eq "page" -and $_.url -like "*phone-price/index.html*" } | Select-Object -First 1

    if (-not $pageTab) {
        throw "Could not find index.html tab!"
    }

    $wsUrl = $pageTab.webSocketDebuggerUrl
    Write-Host "Connected to CDP WebSocket: $wsUrl"

    $ws = [System.Net.WebSockets.ClientWebSocket]::new()
    $cts = [System.Threading.CancellationTokenSource]::new()
    $ws.ConnectAsync([System.Uri]::new($wsUrl), $cts.Token).Wait()

    $cmdId = 1
    function Invoke-CDP($method, $params = @{}) {
        $script:cmdId++
        $msg = @{
            id = $script:cmdId
            method = $method
            params = $params
        } | ConvertTo-Json -Depth 10 -Compress

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
            awaitPromise = $true
        }
        if ($res.result.exceptionDetails) {
            throw "JS Error: $($res.result.exceptionDetails.exception.description)"
        }
        return $res.result.result.value
    }

    # 1. Unlock app
    Eval-JS "window.db = null; window.scheduleStoreSave = function() {}; ['1','0','3','1','0','5'].forEach(d => inputPin(d));" | Out-Null
    Start-Sleep -Milliseconds 600

    Write-Host "--- Test A: 추천금액 알고리즘 (0원 포함 & -5/0원 후보 검증) ---"
    $algoTest = Eval-JS @"
    (function() {
        const testMinus5 = getRecommendedPriceList(-5);
        const testZero = getRecommendedPriceList(0);
        const testMinus15 = getRecommendedPriceList(-15);
        const test23 = getRecommendedPriceList(23);

        const m5Ok = testMinus5[0].price === -5 && testMinus5[1].price === 0;
        const zeroOk = testZero[0].price === 0 && testZero[1].price === 5;
        const m15HasZero = testMinus15.some(c => c.price === 0);
        const p23NoZero = !test23.some(c => c.price === 0) && test23[0].price === 25;

        return {
            minus5: testMinus5,
            zero: testZero,
            minus15: testMinus15,
            p23: test23,
            allPassed: m5Ok && zeroOk && m15HasZero && p23NoZero
        };
    })()
"@
    Write-Host "Minus 5 Candidates: $($algoTest.minus5 | ConvertTo-Json -Compress)"
    Write-Host "Zero Candidates: $($algoTest.zero | ConvertTo-Json -Compress)"
    Write-Host "Minus 15 Candidates: $($algoTest.minus15 | ConvertTo-Json -Compress)"
    Write-Host "23 Candidates: $($algoTest.p23 | ConvertTo-Json -Compress)"

    if ($algoTest.allPassed) {
        Write-Host ">>> SUCCESS: -5원에 대해 -5와 0원이 1·2순위 추천으로 완벽 도출됨!" -ForegroundColor Green
    } else {
        throw "Algorithm Test Failed!"
    }

    Write-Host "`n--- Test B: 대화형 브라우저 클릭 후 팝업 유지 & 연속 클릭 검증 ---"
    # Switch to Ad tab
    Eval-JS "switchTab('ad'); renderAdSection();" | Out-Null
    Start-Sleep -Milliseconds 300

    $interactiveTest = Eval-JS @"
    (function() {
        const inputs = document.querySelectorAll('.ad-price-input');
        if (inputs.length < 2) return { error: 'Inputs not found' };

        const input1 = inputs[0];
        const input2 = inputs[1];

        // 1. Focus input1
        input1.focus();
        const tooltip = document.getElementById('adPriceRecTooltip');
        const isVisible1 = !tooltip.classList.contains('hidden');
        const buttons1 = tooltip.querySelectorAll('button[onmousedown^=\"applyAdRecommendedPrice\"]');

        if (buttons1.length === 0) return { error: 'No recommendation buttons' };

        // 2. Click button 1 (첫번째 추천금액 클릭)
        buttons1[0].dispatchEvent(new MouseEvent('mousedown', { bubbles: true, cancelable: true }));
        const isVisibleAfterClick1 = !tooltip.classList.contains('hidden');
        const valAfterClick1 = input1.value;

        // 3. Click button 2 (다시 한번 다른 추천금액 클릭 - 예: 0원 등)
        const buttons2 = tooltip.querySelectorAll('button[onmousedown^=\"applyAdRecommendedPrice\"]');
        let valAfterClick2 = null;
        let isVisibleAfterClick2 = false;
        if (buttons2.length > 1) {
            buttons2[1].dispatchEvent(new MouseEvent('mousedown', { bubbles: true, cancelable: true }));
            isVisibleAfterClick2 = !tooltip.classList.contains('hidden');
            valAfterClick2 = input1.value;
        }

        return {
            isVisible1: isVisible1,
            buttonsCount: buttons1.length,
            isVisibleAfterClick1: isVisibleAfterClick1,
            valAfterClick1: valAfterClick1,
            isVisibleAfterClick2: isVisibleAfterClick2,
            valAfterClick2: valAfterClick2
        };
    })()
"@
    Write-Host "Interactive Click Test: $($interactiveTest | ConvertTo-Json -Compress)"
    if ($interactiveTest.isVisibleAfterClick1 -and $interactiveTest.isVisibleAfterClick2) {
        Write-Host ">>> SUCCESS: 추천금액을 클릭해도 팝업이 바로 꺼지지 않고 유지되며, 다른 추천금액도 즉시 연속 클릭 가능!" -ForegroundColor Green
    } else {
        throw "Interactive Test Failed: Tooltip was prematurely closed on click!"
    }

    Write-Host "`n--- Test C: 다른 입력칸으로 이동 시 팝업 즉시 꺼짐 방지(Blur 레이스 컨디션 해결) 검증 ---"
    $switchInputTest = Eval-JS @"
    (function() {
        const inputs = document.querySelectorAll('.ad-price-input');
        const input1 = inputs[0];
        const input2 = inputs[1];

        // Blur input1 and focus input2
        input1.blur();
        input2.focus();

        const tooltip = document.getElementById('adPriceRecTooltip');
        return {
            isVisibleImmediately: !tooltip.classList.contains('hidden')
        };
    })()
"@
    # Wait 350ms to exceed the 250ms blur timer
    Start-Sleep -Milliseconds 350
    $stillVisibleAfterTimer = Eval-JS "!document.getElementById('adPriceRecTooltip').classList.contains('hidden')"
    Write-Host "Visible immediately after focus: $($switchInputTest.isVisibleImmediately)"
    Write-Host "Still visible after 350ms (timer expired): $stillVisibleAfterTimer"

    if ($switchInputTest.isVisibleImmediately -and $stillVisibleAfterTimer) {
        Write-Host ">>> SUCCESS: 다른 칸을 클릭해도 이전 칸의 blur 타이머로 인해 팝업이 꺼지지 않고 안정적으로 유지됨!" -ForegroundColor Green
    } else {
        throw "Switch Input Test Failed: Tooltip was closed by blur timer!"
    }

    Write-Host "`n--- Test D: 바깥 영역 클릭 시 정상 닫힘 검증 ---"
    Eval-JS "document.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }));" | Out-Null
    $isClosedOutside = Eval-JS "document.getElementById('adPriceRecTooltip').classList.contains('hidden')"
    Write-Host "Closed on outside click: $isClosedOutside"
    if ($isClosedOutside) {
        Write-Host ">>> SUCCESS: 바깥 영역 클릭 시에는 팝업이 깔끔하게 정상 닫힘!" -ForegroundColor Green
    } else {
        throw "Outside click failed to close tooltip!"
    }

    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host "🎉 추천금액 팝업 유지 & 0원 지원 버그픽스 전수 검증 100% 통과! 🎉" -ForegroundColor Cyan
    Write-Host "========================================================`n" -ForegroundColor Cyan

} finally {
    if ($ws -and $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
    }
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}
