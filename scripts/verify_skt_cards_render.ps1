# scripts/verify_skt_cards_render.ps1
$ErrorActionPreference = "Continue"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9243

Get-Process msedge -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*--remote-debugging-port=$port*" } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

$proc = Start-Process -FilePath $edgePath -ArgumentList "--remote-debugging-port=$port", "--headless=new", "--disable-gpu", "--disable-software-rasterizer", "--window-size=1600,1400", "about:blank" -PassThru
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

    function Capture-Screen($fileName) {
        $ss = Send-CDP "Page.captureScreenshot" @{ format = "png" }
        if ($ss.result.data) {
            $bytes = [Convert]::FromBase64String($ss.result.data)
            $savePath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\$fileName"
            [System.IO.File]::WriteAllBytes($savePath, $bytes)
            Write-Host "Captured $fileName ($($bytes.Length) bytes)"
        }
    }

    $indexUri = "file:///C:/Users/User01/.gemini/antigravity/scratch/phone-price/index.html"
    Send-CDP "Page.navigate" @{ url = $indexUri } | Out-Null
    Start-Sleep -Seconds 4

    # 1. Unlock PIN
    Eval-JS "['1','5','2','4','1','1'].forEach(d => inputPin(d));" | Out-Null
    Start-Sleep -Seconds 1

    # 2. Switch to 'card' tab (제휴카드안내서)
    Eval-JS "switchTab('card');" | Out-Null
    Start-Sleep -Seconds 2

    # 3. Switch to SKT carrier
    Eval-JS "setAffiliateCarrier('SKT');" | Out-Null
    Start-Sleep -Seconds 1

    # 1) 롯데카드 T 라이트 (기존 TELLO 대신 정품 로즈골드 메탈 T라이트)
    Eval-JS "handleSelectAffiliateCard('skt_lotte_tlight');" | Out-Null
    Start-Sleep -Seconds 1
    Capture-Screen "render_skt_lotte_tlight.png"

    # 2) 하나카드 T다운 (기존 트래블로그 여행 스티커 대신 정품 T-Zero)
    Eval-JS "handleSelectAffiliateCard('skt_hana_tdown');" | Out-Null
    Start-Sleep -Seconds 1
    Capture-Screen "render_skt_hana_tdown.png"

    # 3) 우리카드 T라이트 (정품 세로형 WOORI CARD)
    Eval-JS "handleSelectAffiliateCard('skt_woori_tlight');" | Out-Null
    Start-Sleep -Seconds 1
    Capture-Screen "render_skt_woori_tlight.png"

    # 4) 현대카드 M3 T라이트2 (정방향 똑바로 선 민트색 M edition3)
    Eval-JS "handleSelectAffiliateCard('skt_hyundai_m3');" | Out-Null
    Start-Sleep -Seconds 1
    Capture-Screen "render_skt_hyundai_m3.png"

    # 5) 롯데카드 TELLO NE (정품 챠콜 블랙 세로형 TELLO NE)
    Eval-JS "handleSelectAffiliateCard('skt_lotte_tello');" | Out-Null
    Start-Sleep -Seconds 1
    Capture-Screen "render_skt_lotte_tello.png"

    Write-Host "All SKT verification screenshots completed successfully!"

} finally {
    if ($ws -and $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
    }
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}
