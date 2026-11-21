$ErrorActionPreference = "Stop"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) { $edgePath = "C:\Program Files\Microsoft\Edge\Application\msedge.exe" }

$port = 9245
$userDataDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\edge_profile_check_dom"
New-Item -ItemType Directory -Path $userDataDir -Force | Out-Null
$targetHtml = "file:///C:/Users/User01/.gemini\antigravity/scratch/phone-price/index.html"

$edgeProcess = Start-Process -FilePath $edgePath -ArgumentList @(
    "--remote-debugging-port=$port",
    "--user-data-dir=$userDataDir",
    "--headless=new",
    "--window-size=1600,1200",
    $targetHtml
) -PassThru

Start-Sleep -Seconds 3

$versionUrl = "http://127.0.0.1:$port/json"
$targets = Invoke-RestMethod -Uri $versionUrl
$target = $targets | Where-Object { $_.type -eq "page" -and $_.url -match "index.html" } | Select-Object -First 1

$wsUrl = $target.webSocketDebuggerUrl
$ws = New-Object System.Net.WebSockets.ClientWebSocket
$cts = New-Object System.Threading.CancellationTokenSource
$ws.ConnectAsync([uri]$wsUrl, $cts.Token).Wait()

$reqId = 1
function Send-Cdp($method, $params = @{}) {
    $script:reqId++
    $payload = @{
        id = $script:reqId
        method = $method
        params = $params
    } | ConvertTo-Json -Depth 10 -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
    $segment = New-Object System.ArraySegment[byte] -ArgumentList @(,$bytes)
    $ws.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $cts.Token).Wait()

    $buffer = New-Object byte[] 65536
    while ($true) {
        $recvSeg = New-Object System.ArraySegment[byte] -ArgumentList @(,$buffer)
        $res = $ws.ReceiveAsync($recvSeg, $cts.Token).Result
        $text = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $res.Count)
        $parsed = $text | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($parsed -and $parsed.id -eq $script:reqId) {
            if ($parsed.result -and $parsed.result.result -and $parsed.result.result.value) {
                return $parsed.result.result.value
            }
            return $parsed.result
        }
    }
}

Send-Cdp "Runtime.enable" | Out-Null
Start-Sleep -Seconds 1

# 로그인 및 탭 전환
Send-Cdp "Runtime.evaluate" @{
    expression = @'
    (() => {
      localStorage.setItem('dankok_pin', '103105');
      localStorage.setItem('dankok_authed', 'true');
      if (typeof masterAuthSuccess === 'function') masterAuthSuccess('103105');
      switchTab('affiliate');
      handleSelectAffiliateCard('skt_shinhan_tlight');
    })()
'@
} | Out-Null

# QR 생성이 완료될 때까지 2초 대기
Start-Sleep -Seconds 2

$domCheck = Send-Cdp "Runtime.evaluate" @{
    expression = @'
    (() => {
      const sheet = document.getElementById('cardA4Sheet');
      const eventImg = sheet.querySelector('img[alt="이벤트 응모 QR"]');
      const applyImg = sheet.querySelector('img[alt="카드발급 공식 QR"]');
      const eventBadge = sheet.querySelector('.bg-amber-50 .text-amber-900');
      
      return {
        hasApplyQrImg: !!applyImg && applyImg.src.startsWith('data:image/png;base64,'),
        hasEventQrImg: !!eventImg && eventImg.src.startsWith('data:image/png;base64,'),
        eventLabelText: eventBadge ? eventBadge.innerText : '',
        title: sheet.querySelector('h1')?.innerText?.trim()
      };
    })()
'@
    returnByValue = $true
}

Write-Host "DOM Check Result for Shinhan T-light:" ($domCheck | ConvertTo-Json)

$ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
Stop-Process -Id $edgeProcess.Id -Force
