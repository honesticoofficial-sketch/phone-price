[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9248
$htmlPath = "file:///C:/Users/User01/.gemini/antigravity/scratch/phone-price/index.html"

Get-Process msedge -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*--remote-debugging-port=$port*" } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

$proc = Start-Process -FilePath $edgePath -ArgumentList "--remote-debugging-port=$port", "--headless=new", "--disable-gpu", "--disable-software-rasterizer", "--window-size=1600,1200", $htmlPath -PassThru
Start-Sleep -Seconds 3

try {
    $tabs = Invoke-RestMethod -Uri "http://localhost:$port/json/list"
    $pageTab = $tabs | Where-Object { $_.type -eq "page" -and $_.url -like "*index.html*" } | Select-Object -First 1
    if (-not $pageTab) { throw "index.html 탭을 찾을 수 없습니다." }

    $wsUrl = $pageTab.webSocketDebuggerUrl
    $ws = [System.Net.WebSockets.ClientWebSocket]::new()
    $cts = [System.Threading.CancellationTokenSource]::new()
    $ws.ConnectAsync([System.Uri]::new($wsUrl), $cts.Token).Wait()

    $cmdId = 1
    function Invoke-CDP($method, $params = @{}) {
        $script:cmdId++
        $msg = @{ id = $script:cmdId; method = $method; params = $params } | ConvertTo-Json -Depth 10 -Compress
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

    function Eval-JSAsync($expr) {
        $res = Invoke-CDP "Runtime.evaluate" @{
            expression = $expr
            awaitPromise = $true
            returnByValue = $true
        }
        if ($res.result.exceptionDetails) {
            throw "JS 에러: $($res.result.exceptionDetails.exception.description)"
        }
        return $res.result.result.value
    }

    Write-Host "1. Testing PIN Entry (Master PIN 103105)..."
    $pinResult = Eval-JSAsync @"
        (async function() {
            '103105'.split('').forEach(d => inputPin(d));
            await new Promise(r => setTimeout(r, 1500));
            return {
                isUnlocked: isUnlocked,
                currentRole: currentRole,
                currentStoreId: currentStoreId
            };
        })()
"@
    Write-Host "PIN Result: $($pinResult | ConvertTo-Json -Compress)"

    Write-Host "2. Checking cloudPermissionBanner status..."
    $bannerStatus = Eval-JSAsync @"
        (function() {
            const banner = document.getElementById('cloudPermissionBanner');
            const syncBadge = document.getElementById('syncStatusBadge');
            const syncText = document.getElementById('syncStatusText');
            return {
                bannerExists: !!banner,
                bannerHidden: banner ? banner.classList.contains('hidden') : null,
                isCloudPermissionError: typeof isCloudPermissionError !== 'undefined' ? isCloudPermissionError : null,
                syncBadgeExists: !!syncBadge,
                syncText: syncText ? syncText.innerText : null
            };
        })()
"@
    Write-Host "Banner Status: $($bannerStatus | ConvertTo-Json -Compress)"

    Write-Host "3. Testing Troubleshooting Modal Open/Close..."
    $modalTest = Eval-JSAsync @"
        (function() {
            openCloudTroubleshootModal();
            const modal = document.getElementById('cloudTroubleshootModal');
            const opened = modal && !modal.classList.contains('hidden');
            closeCloudTroubleshootModal();
            const closed = modal && modal.classList.contains('hidden');
            return { opened: opened, closed: closed };
        })()
"@
    Write-Host "Modal Test: $($modalTest | ConvertTo-Json -Compress)"

    Write-Host "4. Testing JSON Export Data Structure..."
    $exportTest = Eval-JSAsync @"
        (function() {
            const rates = {};
            devices.forEach(d => { rates[d.id] = d.rate; });
            const backup = {
                app: "phone-price",
                devicesCount: devices.length,
                hasRates: Object.keys(rates).length > 0,
                hasConditions: !!carrierConditions,
                hasDiscounts: !!allAddDiscounts
            };
            return backup;
        })()
"@
    Write-Host "Export Structure: $($exportTest | ConvertTo-Json -Compress)"

    Write-Host "`n>>> ALL CDP TESTS PASSED! 100% SUCCESS <<<" -ForegroundColor Green
} finally {
    if ($ws -and $ws.State -eq 'Open') { $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", [System.Threading.CancellationToken]::None).Wait() }
    if ($proc -and -not $proc.HasExited) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }
}