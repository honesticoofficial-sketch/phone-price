# scripts/check_event_and_tworld.ps1
$ErrorActionPreference = "Continue"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9237

Get-Process msedge -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*--remote-debugging-port=$port*" } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

$proc = Start-Process -FilePath $edgePath -ArgumentList "--remote-debugging-port=$port", "--headless=new", "--disable-gpu", "--disable-software-rasterizer", "--window-size=1600,1200", "about:blank" -PassThru
Start-Sleep -Seconds 2

try {
    $tabs = Invoke-RestMethod -Uri "http://localhost:$port/json/list"
    $pageTab = $tabs | Where-Object { $_.type -eq "page" } | Select-Object -First 1

    $wsUrl = $pageTab.webSocketDebuggerUrl
    $ws = [System.Net.WebSockets.ClientWebSocket]::new()
    $cts = [System.Threading.CancellationTokenSource]::new()
    $ws.ConnectAsync([System.Uri]::new($wsUrl), $cts.Token).Wait()

    $cmdId = 1
    function Send-CDP($method, $params = @{}) {
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

    function Eval-JS($evalJs) {
        $res = Send-CDP "Runtime.evaluate" @{
            expression = $evalJs
            returnByValue = $true
            awaitPromise = $true
        }
        if ($res.result.exceptionDetails) {
            return "ERROR: " + ($res.result.exceptionDetails.exception.description | Out-String)
        }
        return $res.result.result.value
    }

    # 1. Tworld 공식 제휴카드 페이지 확인
    Write-Host "`n[1. T world 공식 제휴카드 소개 페이지 탐색]"
    Send-CDP "Page.navigate" @{ url = "https://www.tworld.co.kr/poc/html/product/TS3.3.3T.html" } | Out-Null
    Start-Sleep -Seconds 6

    $tworldDump = Eval-JS @"
    (function() {
        const text = document.body.innerText;
        return {
            title: document.title,
            textLen: text.length,
            has33000: text.includes('33,000') || text.includes('33000'),
            has35000: text.includes('35,000') || text.includes('35000'),
            has25000: text.includes('25,000') || text.includes('25000'),
            hasPromo: text.includes('프로모션') || text.includes('추가할인') || text.includes('캐시백'),
            sample: text.substring(0, 2000)
        };
    })()
"@
    Write-Host "T world 결과:"
    Write-Host ($tworldDump | ConvertTo-Json -Depth 5)

    # 2. KB국민카드 이벤트 페이지에서 'SKT' 또는 '통신' 검색
    Write-Host "`n[2. KB국민카드 이벤트 페이지 탐색]"
    Send-CDP "Page.navigate" @{ url = "https://card.kbcard.com/promotions/events" } | Out-Null
    Start-Sleep -Seconds 6

    $kbEventDump = Eval-JS @"
    (function() {
        const text = document.body.innerText;
        const matches = Array.from(document.querySelectorAll('*'))
            .filter(el => el.children.length === 0 && el.innerText && (el.innerText.includes('SKT') || el.innerText.includes('T라이트') || el.innerText.includes('통신요금')))
            .map(el => el.innerText.trim());
        return {
            title: document.title,
            textLen: text.length,
            matches: Array.from(new Set(matches)).slice(0, 15)
        };
    })()
"@
    Write-Host "KB국민카드 이벤트 결과:"
    Write-Host ($kbEventDump | ConvertTo-Json -Depth 5)

    # 3. 현대카드 이벤트 페이지에서 'SKT' 검색
    Write-Host "`n[3. 현대카드 이벤트 페이지 탐색]"
    Send-CDP "Page.navigate" @{ url = "https://www.hyundaicard.com/cpc/ma/CPCMA0101_01.hc" } | Out-Null
    Start-Sleep -Seconds 5

} finally {
    if ($ws -and $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
    }
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}
