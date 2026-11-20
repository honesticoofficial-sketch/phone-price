# scripts/explore_kt_lgu_web.ps1
$ErrorActionPreference = "Continue"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9240

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

    # 1. KT 공식 제휴카드 페이지 탐색
    Write-Host "`n[1. KT 공식 제휴카드 페이지 접속]"
    Send-CDP "Page.navigate" @{ url = "https://product.kt.com/benefit/membership/web/card_info.html" } | Out-Null
    Start-Sleep -Seconds 6

    $ktInfo = Eval-JS @"
    (async function() {
        const text = document.body.innerText;
        const promoLines = text.split('\n').map(l => l.trim()).filter(l => 
            l.includes('프로모션') || l.includes('추가할인') || l.includes('캐시백') || l.includes('슈퍼할부') || l.includes('DC')
        );
        const cardNames = Array.from(document.querySelectorAll('h3, h4, strong, [class*="card"], [class*="tit"]'))
            .map(el => el.innerText.trim())
            .filter(t => t.includes('카드') && t.length < 30);
        return {
            title: document.title,
            textLen: text.length,
            cardNames: Array.from(new Set(cardNames)).slice(0, 15),
            promoLines: Array.from(new Set(promoLines)).slice(0, 10),
            sample: text.substring(0, 1500)
        };
    })()
"@
    Write-Host "KT 공식 페이지 결과:"
    Write-Host "Title: $($ktInfo.title)"
    Write-Host "Card Names: $($ktInfo.cardNames | ConvertTo-Json -Compress)"
    Write-Host "Promo Lines: $($ktInfo.promoLines | ConvertTo-Json -Compress)"

    # 2. LGU+ 공식 제휴카드 페이지 탐색
    Write-Host "`n[2. LGU+ 공식 제휴카드 페이지 접속]"
    Send-CDP "Page.navigate" @{ url = "https://www.lguplus.com/benefit-affiliate/card" } | Out-Null
    Start-Sleep -Seconds 6

    $lguInfo = Eval-JS @"
    (async function() {
        const text = document.body.innerText;
        const promoLines = text.split('\n').map(l => l.trim()).filter(l => 
            l.includes('프로모션') || l.includes('추가할인') || l.includes('캐시백') || l.includes('라이트할부') || l.includes('통신료')
        );
        const cardNames = Array.from(document.querySelectorAll('h3, h4, strong, [class*="card"], [class*="tit"]'))
            .map(el => el.innerText.trim())
            .filter(t => t.includes('카드') && t.length < 30);
        return {
            title: document.title,
            textLen: text.length,
            cardNames: Array.from(new Set(cardNames)).slice(0, 15),
            promoLines: Array.from(new Set(promoLines)).slice(0, 10),
            sample: text.substring(0, 1500)
        };
    })()
"@
    Write-Host "`nLGU+ 공식 페이지 결과:"
    Write-Host "Title: $($lguInfo.title)"
    Write-Host "Card Names: $($lguInfo.cardNames | ConvertTo-Json -Compress)"
    Write-Host "Promo Lines: $($lguInfo.promoLines | ConvertTo-Json -Compress)"

} finally {
    if ($ws -and $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
    }
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}
