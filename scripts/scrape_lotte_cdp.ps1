$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9230

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
        return $res.result.result.value
    }

    Send-CDP "Page.navigate" @{ url = "https://www.lottecard.co.kr/app/LPCDADA_V100.lc?typeGubun=cco" } | Out-Null
    Start-Sleep -Seconds 8

    # Click 통신 tab or find cards
    $res = Eval-JS @"
    (function() {
        const tabs = Array.from(document.querySelectorAll('button, a, li')).filter(el => el.innerText && el.innerText.includes('통신'));
        let clicked = false;
        if (tabs.length > 0) {
            tabs[0].click();
            clicked = true;
        }
        return {
            clickedTab: clicked,
            tabText: tabs.length > 0 ? tabs[0].innerText : '',
            url: window.location.href
        };
    })()
"@
    Write-Host "Tab Click Result:" ($res | ConvertTo-Json)
    Start-Sleep -Seconds 3

    $cardImgs = Eval-JS @"
    (function() {
        const list = [];
        document.querySelectorAll('img').forEach(img => {
            if (img.src && (img.src.includes('upload') || img.src.includes('card') || img.src.includes('prod'))) {
                list.push({ alt: img.alt || '', src: img.src });
            }
        });
        return list;
    })()
"@
    Write-Host "Card Images:"
    Write-Host ($cardImgs | Format-Table -AutoSize | Out-String)

} finally {
    if ($ws -and $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
    }
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}
