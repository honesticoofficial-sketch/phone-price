# scripts/verify_final_cards_render.ps1
$ErrorActionPreference = "Continue"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9241

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
            [System.IO.File]::WriteAllBytes("C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\$fileName", $bytes)
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

    # 3. Switch to LGU carrier
    Eval-JS "setAffiliateCarrier('LGU');" | Out-Null
    Start-Sleep -Seconds 1

    # Select LGU NH농협 올원
    Eval-JS "handleSelectAffiliateCard('lgu_nh_allone');" | Out-Null
    Start-Sleep -Seconds 1
    Capture-Screen "verified_lgu_nh_allone.png"

    # Select LGU 롯데 LOCA
    Eval-JS "handleSelectAffiliateCard('lgu_lotte_loca');" | Out-Null
    Start-Sleep -Seconds 1
    Capture-Screen "verified_lgu_lotte_loca.png"

    # Select LGU 우리카드
    Eval-JS "handleSelectAffiliateCard('lgu_woori_36');" | Out-Null
    Start-Sleep -Seconds 1
    Capture-Screen "verified_lgu_woori_36.png"

    # 4. Switch to KT carrier & select KT 신한카드
    Eval-JS "setAffiliateCarrier('KT');" | Out-Null
    Start-Sleep -Seconds 1
    Eval-JS "handleSelectAffiliateCard('kt_shinhan_family_light');" | Out-Null
    Start-Sleep -Seconds 1
    Capture-Screen "verified_kt_shinhan.png"

    Write-Host "All verification screenshots done!"

} finally {
    if ($ws -and $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
    }
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}
