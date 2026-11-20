$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9444
$userDataDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\edge_verify_skt"
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
    Send-Cdp "Page.navigate" @{ url = "file:///C:/Users/User01/.gemini/antigravity/scratch/phone-price/index.html" } | Out-Null
    Start-Sleep -Seconds 3

    # Pass PIN 152411 and switch to card tab
    Send-Cdp "Runtime.evaluate" @{ expression = @"
(() => {
    ['1','5','2','4','1','1'].forEach(d => { if (typeof inputPin === 'function') inputPin(d); });
    if (typeof switchTab === 'function') switchTab('card');
    if (typeof setCardCarrier === 'function') setCardCarrier('SKT');
})()
"@ } | Out-Null
    Start-Sleep -Seconds 1

    # Function to select card and take screenshot
    function Capture-Card($cardId, $filename) {
        Send-Cdp "Runtime.evaluate" @{ expression = @"
(() => {
    const sel = document.getElementById('affiliateCardSelect');
    if (sel) {
        sel.value = '$cardId';
        sel.dispatchEvent(new Event('change'));
    }
})()
"@ } | Out-Null
        Start-Sleep -Seconds 1

        $shotRes = Send-Cdp "Page.captureScreenshot" @{ format = "png" }
        $bytes = [System.Convert]::FromBase64String($shotRes.result.data)
        $savePath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\$filename"
        [System.IO.File]::WriteAllBytes($savePath, $bytes)
        Write-Host "Captured: $cardId -> $savePath"
    }

    Capture-Card "skt_lotte_tlight" "verified_skt_lotte_tlight.png"
    Capture-Card "skt_hana_tdown" "verified_skt_hana_tdown.png"
    Capture-Card "skt_woori_tlight" "verified_skt_woori_tlight.png"
    Capture-Card "skt_hyundai_m3" "verified_skt_hyundai_m3.png"
    Capture-Card "skt_lotte_tello" "verified_skt_lotte_tello.png"

    $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "done", $ct).Wait()
} finally {
    if ($proc -and -not $proc.HasExited) { Stop-Process -Id $proc.Id -Force }
}
