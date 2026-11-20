# scripts/test_savedream_kt.ps1
$ErrorActionPreference = "Continue"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9241

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

    Write-Host "`n[세이브드림 cardfs 접속 및 탐색]"
    Send-CDP "Page.navigate" @{ url = "https://savedream.co.kr/cardfs" } | Out-Null
    Start-Sleep -Seconds 6

    $sdDump = Eval-JS @"
    (function() {
        const text = document.body.innerText;
        // 테이블이나 카드 리스트 추출
        const tables = Array.from(document.querySelectorAll('table')).map(t => t.innerText.substring(0, 500));
        const cards = Array.from(document.querySelectorAll('*'))
            .filter(el => el.children.length === 0 && el.innerText && el.innerText.includes('KT') && el.innerText.includes('카드'))
            .map(el => el.innerText.trim());
        const images = Array.from(document.querySelectorAll('img')).map(img => img.src).filter(src => src.includes('card') || src.includes('product') || src.includes('item'));

        return {
            title: document.title,
            textLen: text.length,
            tableCount: tables.length,
            foundCards: Array.from(new Set(cards)).slice(0, 15),
            sampleImages: images.slice(0, 5),
            sampleText: text.substring(0, 2000)
        };
    })()
"@
    Write-Host "세이브드림 탐색 결과:"
    Write-Host "Title: $($sdDump.title)"
    Write-Host "Text Length: $($sdDump.textLen)"
    Write-Host "Found Cards: $($sdDump.foundCards | ConvertTo-Json -Compress)"
    Write-Host "Sample Images: $($sdDump.sampleImages | ConvertTo-Json -Compress)"
    Set-Content -Path "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\savedream_dump.txt" -Value $sdDump.sampleText -Encoding UTF8

} finally {
    if ($ws -and $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
    }
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}
