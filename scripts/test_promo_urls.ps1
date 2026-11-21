$ErrorActionPreference = "Continue"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) { $edgePath = "C:\Program Files\Microsoft\Edge\Application\msedge.exe" }

$port = 9243
$userDataDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\edge_profile_check_links"
New-Item -ItemType Directory -Path $userDataDir -Force | Out-Null
$targetHtml = "about:blank"

$edgeProcess = Start-Process -FilePath $edgePath -ArgumentList @(
    "--remote-debugging-port=$port",
    "--user-data-dir=$userDataDir",
    "--headless=new",
    $targetHtml
) -PassThru

Start-Sleep -Seconds 3

$versionUrl = "http://127.0.0.1:$port/json"
$targets = Invoke-RestMethod -Uri $versionUrl
$target = $targets | Where-Object { $_.type -eq "page" } | Select-Object -First 1

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

Send-Cdp "Page.enable" | Out-Null
Send-Cdp "Runtime.enable" | Out-Null

$testUrls = @(
    @{ name = "신한 T라이트 6개월"; url = "https://shcard.io/tlight6m" },
    @{ name = "KB국민 대상확인"; url = "https://m.site.naver.com/1it3e" },
    @{ name = "삼성 T라이트 대상확인"; url = "https://m.site.naver.com/282hO" }
)

foreach ($item in $testUrls) {
    Write-Host "Navigating to $($item.name): $($item.url)"
    Send-Cdp "Page.navigate" @{ url = $item.url } | Out-Null
    Start-Sleep -Seconds 4
    
    $res = Send-Cdp "Runtime.evaluate" @{
        expression = "({ title: document.title, url: window.location.href })"
        returnByValue = $true
    }
    Write-Host "   Title: $($res.title), Final URL: $($res.url)"
}

$ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
Stop-Process -Id $edgeProcess.Id -Force
