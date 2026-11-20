# scripts/check_promo_redirect_urls.ps1
$ErrorActionPreference = "Continue"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9238

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
        if ($res.result.exceptionDetails) {
            return "ERROR: " + ($res.result.exceptionDetails.exception.description | Out-String)
        }
        return $res.result.result.value
    }

    $urls = @(
        @{ name = "KB카드 T라이트"; url = "http://m.site.naver.com/18fKy" },
        @{ name = "현대카드 M3 T라이트2"; url = "http://m.site.naver.com/0QwRn" },
        @{ name = "우리카드 T라이트"; url = "https://m.wooricard.com/dcmw/yh1/crd/crd01/M1CRD101S02.do?cdPrdCd=103749&canvasser=88936105" },
        @{ name = "삼성카드 T라이트"; url = "http://m.site.naver.com/0JM14" }
    )

    foreach ($item in $urls) {
        Write-Host "`n[$($item.name)] 접속 중... ($($item.url))"
        Send-CDP "Page.navigate" @{ url = $item.url } | Out-Null
        Start-Sleep -Seconds 6

        $info = Eval-JS @"
        (function() {
            const text = document.body.innerText;
            const lines = text.split('\n').map(l => l.trim()).filter(l => l.length > 0);
            const promoLines = lines.filter(l => 
                l.includes('프로모션') || l.includes('추가할인') || l.includes('캐시백') || 
                l.includes('25,000') || l.includes('33,000') || l.includes('24,000') || l.includes('22,000') ||
                l.includes('무실적') || l.includes('이벤트')
            );
            return {
                title: document.title,
                finalUrl: window.location.href,
                textLen: text.length,
                promoLines: Array.from(new Set(promoLines)).slice(0, 10),
                snippet: text.substring(0, 1000)
            };
        })()
"@
        Write-Host "Title: $($info.title)"
        Write-Host "Final URL: $($info.finalUrl)"
        Write-Host "Promo Lines:"
        Write-Host ($info.promoLines | ConvertTo-Json -Compress)
    }

} finally {
    if ($ws -and $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
    }
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}
