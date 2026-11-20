$queries = @(
    "U%2B+DC+%EB%A1%AF%EB%8D%B0%EC%B9%B4%EB%93%9C",
    "LG+U%2B+%EB%A1%AF%EB%8D%B0%EC%B9%B4%EB%93%9C",
    "%EC%98%AC%EC%9B%90+LG+U%2B",
    "NH%EB%84%88%ED%95%A9+%EC%98%AC%EC%9B%90+U%2B",
    "U%2B+36+%EC%9A%B0%EB%A6%AC%EC%B9%B4%EB%93%9C",
    "LG+U%2B+%EC%9A%B0%EB%A6%AC%EC%B9%B4%EB%93%9C"
)

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9234

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
        return $res.result.result.value
    }

    $allFound = @()
    foreach ($q in $queries) {
        $url = "https://search.naver.com/search.naver?query=$q"
        Send-CDP "Page.navigate" @{ url = $url } | Out-Null
        Start-Sleep -Seconds 4

        $imgs = Eval-JS @"
        (function() {
            const list = [];
            document.querySelectorAll('img').forEach(img => {
                if (img.src && (img.src.includes('vertical-cardad') || img.src.includes('card-search') || img.src.includes('searchad-phinf'))) {
                    list.push({ query: '$q', alt: img.alt || '', src: img.src });
                }
            });
            return list;
        })()
"@
        if ($imgs) {
            $allFound += $imgs
        }
    }

    $allFound | ConvertTo-Json -Depth 5 | Set-Content "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\naver_card_imgs.json" -Encoding UTF8
    Write-Host "Total images found: $($allFound.Count)"
    $allFound | Select-Object -Unique src | ForEach-Object { Write-Host $_.src }

} finally {
    if ($ws -and $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
    }
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}
