$port = 9228
$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
Get-Process msedge -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*--remote-debugging-port=$port*" } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

$proc = Start-Process -FilePath $edgePath -ArgumentList "--remote-debugging-port=$port", "--headless=new", "--disable-gpu", "--window-size=1600,2200", "about:blank" -PassThru
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
$pdfUrl = "file:///C:/Users/User01/.gemini/antigravity/brain/af18e558-85da-49ae-9eb0-4c9b6d7b02ae/.user_uploaded/media_1795153661234_0b7c7c83.pdf"
Send-Cdp "Page.navigate" @{ url = $pdfUrl } | Out-Null
Start-Sleep -Seconds 3

$ss = Send-Cdp "Page.captureScreenshot" @{ format = "png" }
if ($ss.result.data) {
    $bytes = [Convert]::FromBase64String($ss.result.data)
    [System.IO.File]::WriteAllBytes("C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\edge_pdf_ss.png", $bytes)
    Write-Host "Screenshot saved! Size: $($bytes.Length) bytes"
} else {
    Write-Host "Screenshot failed"
}

$ws.Dispose()
Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
