# scripts/scrape_lgu_cards_proper.ps1
$ErrorActionPreference = "Continue"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9229

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

    Send-CDP "Page.navigate" @{ url = "https://www.lguplus.com/benefits-event/cprt-card" } | Out-Null
    Start-Sleep -Seconds 7

    $dumpLgu = Eval-JS @"
    (function() {
        const cards = [];
        // Look for card cards / containers
        document.querySelectorAll('img').forEach(img => {
            const src = img.src || '';
            const alt = img.alt || '';
            if (src.includes('card') || alt.includes('카드') || alt.includes('U+') || src.includes('cprt') || src.includes('benefit')) {
                // find closest card container
                let p = img.parentElement;
                let text = '';
                for (let k = 0; k < 4; k++) {
                    if (p) {
                        text = p.innerText || '';
                        if (text.length > 10) break;
                        p = p.parentElement;
                    }
                }
                cards.push({ alt, src, containerText: text.substring(0, 150) });
            }
        });
        return {
            title: document.title,
            url: window.location.href,
            cardCount: cards.length,
            cards: cards
        };
    })()
"@

    $outJson = $dumpLgu | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText("C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\lgu_official_scraped_proper.json", $outJson, [System.Text.Encoding]::UTF8)
    Write-Host "Scraped results:" ($dumpLgu.cardCount) "cards found!"
    Write-Host ($dumpLgu.cards | Format-Table alt, src -AutoSize | Out-String)

} finally {
    if ($ws -and $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
    }
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}
