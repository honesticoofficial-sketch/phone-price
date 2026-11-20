$port = 9222
$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
Get-Process msedge -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*--remote-debugging-port=$port*" } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

$proc = Start-Process -FilePath $edgePath -ArgumentList "--remote-debugging-port=$port", "--headless=new", "--disable-gpu", "--window-size=1600,1200", "about:blank" -PassThru
Start-Sleep -Seconds 2

$json = Invoke-RestMethod -Uri "http://localhost:$port/json"
$wsUrl = $json[0].webSocketDebuggerUrl

$ws = New-Object System.Net.WebSockets.ClientWebSocket
$cts = New-Object System.Threading.CancellationTokenSource
$ws.ConnectAsync([uri]$wsUrl, $cts.Token).Wait()

function Send-Cdp($method, $params) {
    $id = Get-Random
    $msg = @{ id = $id; method = $method; params = $params } | ConvertTo-Json -Depth 10 -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($msg)
    $segment = [ArraySegment[byte]]::new($bytes)
    $ws.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $cts.Token).Wait()

    $buffer = New-Object byte[] 2097152
    $ms = New-Object System.IO.MemoryStream
    do {
        $seg = [ArraySegment[byte]]::new($buffer)
        $res = $ws.ReceiveAsync($seg, $cts.Token)
        $res.Wait()
        $ms.Write($buffer, 0, $res.Result.Count)
    } while (-not $res.Result.EndOfMessage)
    $str = [System.Text.Encoding]::UTF8.GetString($ms.ToArray())
    return $str | ConvertFrom-Json
}

Send-Cdp "Page.enable" @{} | Out-Null
Send-Cdp "Page.navigate" @{ url = "https://www.lottecard.co.kr/app/LPCDADA_V100.lc?typeGubun=cco" } | Out-Null
Start-Sleep -Seconds 5

$eval = Send-Cdp "Runtime.evaluate" @{
    expression = @"
    (function() {
        const cards = [];
        document.querySelectorAll('img').forEach(img => {
            const alt = img.alt || '';
            const src = img.src || '';
            if (alt.includes('U+') || alt.includes('LG') || src.includes('card') || alt.includes('LOCA') || alt.includes('할부')) {
                cards.push({ alt, src });
            }
        });
        return JSON.stringify({
            title: document.title,
            cards: cards,
            bodyText: document.body.innerText.substring(0, 1000)
        });
    })()
"@
}

Write-Host "Lotte Card Result:"
$eval.result.value

$ws.Dispose()
Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
