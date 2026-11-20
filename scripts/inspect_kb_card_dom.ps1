# scripts/inspect_kb_card_dom.ps1
$ErrorActionPreference = "Continue"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9231

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

    Send-CDP "Page.navigate" @{ url = "https://card.kbcard.com/cards/products/credit-cards?benefit=telecom" } | Out-Null
    Start-Sleep -Seconds 5

    $inspect = Eval-JS @"
    (function() {
        const detailBtns = Array.from(document.querySelectorAll('a, button'))
            .filter(el => el.innerText && el.innerText.includes('자세히보기'))
            .map(el => ({
                tag: el.tagName,
                href: el.href || el.getAttribute('href'),
                onclick: el.getAttribute('onclick'),
                parentText: el.parentElement.innerText.substring(0, 100)
            }));
        return detailBtns.slice(0, 15);
    })()
"@
    Write-Host "자세히보기 버튼 목록:"
    Write-Host ($inspect | ConvertTo-Json -Depth 5)

} finally {
    if ($ws -and $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
    }
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}
