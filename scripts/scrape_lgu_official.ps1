$port = 9223
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

    $buffer = New-Object byte[] 4194304
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
Send-Cdp "Page.navigate" @{ url = "https://www.lguplus.com/benefit-affiliate-card" } | Out-Null
Start-Sleep -Seconds 6

$eval = Send-Cdp "Runtime.evaluate" @{
    expression = @"
    (function() {
        const items = [];
        document.querySelectorAll('img').forEach(img => {
            const src = img.src || '';
            const alt = img.alt || '';
            if (src.includes('card') || alt.includes('카드') || alt.includes('할부') || alt.includes('U+') || alt.includes('LOCA')) {
                items.push({ alt, src });
            }
        });
        const links = [];
        document.querySelectorAll('a').forEach(a => {
            if (a.innerText.includes('카드') || (a.href && a.href.includes('card'))) {
                links.push({ text: a.innerText.trim(), href: a.href });
            }
        });
        return JSON.stringify({
            title: document.title,
            currentUrl: window.location.href,
            items: items,
            linksCount: links.length,
            linksSample: links.slice(0, 15)
        });
    })()
"@
}

$resultJson = $eval.result.value
[System.IO.File]::WriteAllText("C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\lgu_official_scraped.json", $resultJson, [System.Text.Encoding]::UTF8)
Write-Host "Scraped successfully! Saved to lgu_official_scraped.json"
Write-Host "Preview:" ($resultJson.Substring(0, [Math]::Min(500, $resultJson.Length)))

$ws.Dispose()
Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
