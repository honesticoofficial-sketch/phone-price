# scripts/capture_card_a4.ps1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9240
$htmlPath = "file:///C:/Users/User01/.gemini/antigravity/scratch/phone-price/index.html"
$root = "C:\Users\User01\.gemini\antigravity\scratch\phone-price"

Get-Process msedge -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*--remote-debugging-port=$port*" } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

$proc = Start-Process -FilePath $edgePath -ArgumentList "--remote-debugging-port=$port", "--headless=new", "--disable-gpu", "--disable-software-rasterizer", "--window-size=1600,1600", $htmlPath -PassThru
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

    # PIN 모달 완전 제거 및 제휴카드 탭 활성화
    Eval-JS @"
        (function() {
            const pinModal = document.getElementById('pinModal');
            if (pinModal) pinModal.remove();

            if (typeof showTab === 'function') showTab('affiliateCard');

            // skt_kb_tlight 선택
            setAffiliateCarrier('SKT');
            handleSelectAffiliateCard('skt_kb_tlight');

            const sheet = document.getElementById('cardA4Sheet');
            if (sheet) {
                sheet.scrollIntoView({ behavior: 'instant', block: 'start' });
            }
        })()
"@ | Out-Null
    Start-Sleep -Seconds 2

    # cardA4Sheet 엘리먼트의 정확한 위치/크기 측정
    $rect = Eval-JS @"
        (function() {
            const sheet = document.getElementById('cardA4Sheet');
            if (!sheet) return null;
            const r = sheet.getBoundingClientRect();
            return {
                x: r.x,
                y: r.y,
                width: r.width,
                height: r.height,
                scale: 1
            };
        })()
"@

    # 클립 영역 스크린샷 캡처
    $clipParams = @{
        clip = @{
            x = [double]$rect.x
            y = [double]$rect.y
            width = [double]$rect.width
            height = [double]$rect.height
            scale = 1
        }
        format = "png"
    }
    $screenshotRes = Invoke-CDP "Page.captureScreenshot" $clipParams
    $bytes = [System.Convert]::FromBase64String($screenshotRes.result.data)
    [System.IO.File]::WriteAllBytes("$root\scratch\verified_card_a4_clean.png", $bytes)
    Write-Host "📸 서식지 맞춤 스크린샷 저장 완료: scratch\verified_card_a4_clean.png" -ForegroundColor Green

} finally {
    if ($ws -and $ws.State -eq "Open") { $ws.Dispose() }
    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
}
