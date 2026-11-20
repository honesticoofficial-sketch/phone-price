$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9333
$userDataDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\edge_hana"
if (Test-Path $userDataDir) { Remove-Item $userDataDir -Recurse -Force }

$proc = Start-Process -FilePath $edgePath -ArgumentList "--remote-debugging-port=$port", "--headless=new", "--disable-gpu", "--no-first-run", "--user-data-dir=$userDataDir", "about:blank" -PassThru
Start-Sleep -Seconds 2

try {
    $versionUrl = "http://localhost:$port/json/version"
    $wsUrl = (Invoke-RestMethod -Uri $versionUrl).webSocketDebuggerUrl

    $ws = New-Object System.Net.WebSockets.ClientWebSocket
    $ct = New-Object System.Threading.CancellationToken
    $ws.ConnectAsync([System.Uri]$wsUrl, $ct).Wait()

    $msgId = 1
    function Send-Cdp($method, $params) {
        $script:msgId++
        $cmd = @{ id = $script:msgId; method = $method; params = $params } | ConvertTo-Json -Depth 10 -Compress
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($cmd)
        $segment = New-Object System.ArraySegment[byte] -ArgumentList @(,$bytes)
        $ws.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $ct).Wait()

        $buf = New-Object byte[] 65536
        $stream = New-Object System.IO.MemoryStream
        do {
            $recvSegment = New-Object System.ArraySegment[byte] -ArgumentList @(,$buf)
            $res = $ws.ReceiveAsync($recvSegment, $ct).Result
            $stream.Write($buf, 0, $res.Count)
        } while (-not $res.EndOfMessage)

        $jsonStr = [System.Text.Encoding]::UTF8.GetString($stream.ToArray())
        return $jsonStr | ConvertFrom-Json
    }

    Send-Cdp "Page.enable" @{} | Out-Null
    Send-Cdp "Page.navigate" @{ url = "https://m.hanacard.co.kr/MKCDCM1010M.web?CD_PD_SEQ=15369" } | Out-Null
    Start-Sleep -Seconds 4

    # Evaluate images on page
    $evalRes = Send-Cdp "Runtime.evaluate" @{ expression = @"
(() => {
    const imgs = Array.from(document.querySelectorAll('img')).map(i => ({ src: i.src, w: i.naturalWidth, h: i.naturalHeight, alt: i.alt }));
    const title = document.title;
    const bodyText = document.body.innerText.substring(0, 300);
    return JSON.stringify({ title, bodyText, imgs });
})()
"@ }
    Write-Host "Eval Result: $($evalRes.result.value)"

    # Screenshot
    $shotRes = Send-Cdp "Page.captureScreenshot" @{ format = "png" }
    $shotBytes = [System.Convert]::FromBase64String($shotRes.result.data)
    $saveShot = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\hana_cdp_shot.png"
    [System.IO.File]::WriteAllBytes($saveShot, $shotBytes)
    Write-Host "Screenshot saved to $saveShot"

    $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "done", $ct).Wait()
} finally {
    if ($proc -and -not $proc.HasExited) { Stop-Process -Id $proc.Id -Force }
}
