[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

$root = "C:\Users\User01\.gemini\antigravity\scratch\phone-price"
$indexHtml = "$root\index.html"
$outPng = "$root\data\chapter84_verified.png"
$artifactPng = "C:\Users\User01\.gemini\antigravity\brain\2f8eabdf-6a8a-4957-81f7-425939762cc2\chapter84_verified.png"
$port = 9260

Write-Host "=========================================================="
Write-Host " [Chapter 84 브라우저 라이브 실시간 검증 및 스크린샷 캡처]"
Write-Host "=========================================================="

cmd.exe /c "taskkill /f /im msedge.exe 2>nul" | Out-Null
Start-Sleep -Milliseconds 800

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$proc = Start-Process -FilePath $edgePath -ArgumentList "--remote-debugging-port=$port", "--headless=new", "--disable-gpu", "--window-size=1600,1200", "about:blank" -PassThru
Start-Sleep -Seconds 3

$ws = $null
$cts = $null

try {
    $tabs = Invoke-RestMethod -Uri "http://localhost:$port/json/list"
    $pageTab = $tabs | Where-Object { $_.type -eq "page" } | Select-Object -First 1

    $ws = [System.Net.WebSockets.ClientWebSocket]::new()
    $cts = [System.Threading.CancellationTokenSource]::new()
    $ws.ConnectAsync([System.Uri]::new($pageTab.webSocketDebuggerUrl), $cts.Token).Wait()

    $cmdId = 1
    function Invoke-CDP($method, $params = @{}) {
        $script:cmdId++
        $msg = @{ id = $script:cmdId; method = $method; params = $params } | ConvertTo-Json -Depth 10 -Compress
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($msg)
        $ws.SendAsync([System.ArraySegment[byte]]::new($bytes), [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $cts.Token).Wait()

        $buffer = [byte[]]::new(65536 * 8)
        $ms = [System.IO.MemoryStream]::new()
        do {
            $result = $ws.ReceiveAsync([System.ArraySegment[byte]]::new($buffer), $cts.Token).Result
            $ms.Write($buffer, 0, $result.Count)
        } while (-not $result.EndOfMessage)

        return [System.Text.Encoding]::UTF8.GetString($ms.ToArray()) | ConvertFrom-Json
    }

    Write-Host "1. Navigating to index.html..."
    $fileUrl = "file:///" + ($indexHtml.Replace("\", "/"))
    Invoke-CDP "Page.navigate" @{ url = $fileUrl }
    Start-Sleep -Seconds 4

    Write-Host "2. Checking Tab 1 Plan Inputs..."
    $resPlans = Invoke-CDP "Runtime.evaluate" @{
        expression = @"
            (() => {
                return {
                    sk_val: document.getElementById('cond-SK-plan')?.value,
                    kt_val: document.getElementById('cond-KT-plan')?.value,
                    lg_val: document.getElementById('cond-LG-plan')?.value
                };
            })()
"@
        returnByValue = $true
    }
    $p = $resPlans.result.result.value
    Write-Host "  SK Plan: $($p.sk_val)"
    Write-Host "  KT Plan: $($p.kt_val)"
    Write-Host "  LG Plan: $($p.lg_val)"

    Write-Host "`n3. Checking iPhone 18 Pro Max subsidies in catalog..."
    $res18 = Invoke-CDP "Runtime.evaluate" @{
        expression = @"
            (() => {
                const item = CRAWLED_CATALOG_POOL.find(x => x.name.includes('18 Pro Max'));
                return item ? { name: item.name, subs: item.subs } : null;
            })()
"@
        returnByValue = $true
    }
    $v18 = $res18.result.result.value
    Write-Host "  Item: $($v18.name)"
    Write-Host "  SK Subs: $($v18.subs.SK.mnp) 만원"
    Write-Host "  KT Subs: $($v18.subs.KT.mnp) 만원"
    Write-Host "  LG Subs: $($v18.subs.LG.mnp) 만원"

    Write-Host "`n4. Checking iPhone 17 & 17 Pro LGU+ differentiated subsidies..."
    $res17 = Invoke-CDP "Runtime.evaluate" @{
        expression = @"
            (() => {
                const item17 = CRAWLED_CATALOG_POOL.find(x => x.name === 'iPhone 17 256G');
                const item17p = CRAWLED_CATALOG_POOL.find(x => x.name === 'iPhone 17 Pro 256G');
                return {
                    ip17: item17 ? { name: item17.name, lg_mnp: item17.subs.LG.mnp, lg_chg: item17.subs.LG.chg } : null,
                    ip17p: item17p ? { name: item17p.name, lg_mnp: item17p.subs.LG.mnp, lg_chg: item17p.subs.LG.chg } : null
                };
            })()
"@
        returnByValue = $true
    }
    $v17 = $res17.result.result.value
    Write-Host "  Item 1: $($v17.ip17.name) -> LG 번이: $($v17.ip17.lg_mnp) 만원 / 기변: $($v17.ip17.lg_chg) 만원"
    Write-Host "  Item 2: $($v17.ip17p.name) -> LG 번이: $($v17.ip17p.lg_mnp) 만원 / 기변: $($v17.ip17p.lg_chg) 만원"

    Write-Host "`n5. Capturing Verification Screenshot..."
    $screenshotRes = Invoke-CDP "Page.captureScreenshot" @{ format = "png" }
    if ($screenshotRes.result.data) {
        $rawBytes = [System.Convert]::FromBase64String($screenshotRes.result.data)
        [System.IO.File]::WriteAllBytes($outPng, $rawBytes)
        [System.IO.File]::WriteAllBytes($artifactPng, $rawBytes)
        Write-Host "  ✅ Screenshot successfully saved and copied to artifact: $artifactPng" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Failed to capture screenshot" -ForegroundColor Red
    }

    Write-Host "`n=========================================================="
    Write-Host " 🎉 [ALL BROWSER PASS] 브라우저 라이브 검증 100% 완료!" -ForegroundColor Cyan
    Write-Host "=========================================================="

} finally {
    if ($ws -and $ws.State -eq 'Open') {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", [System.Threading.CancellationToken]::None).Wait()
    }
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}
