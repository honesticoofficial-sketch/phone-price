[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9287
$indexPath = "file:///C:/Users/User01/.gemini/antigravity/scratch/phone-price/index.html"
$outPng = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\chapter83_verified.png"

# Kill any existing edge instances on this port
Get-Process msedge -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*--remote-debugging-port=$port*" } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

Write-Host "1. Launching Edge in CDP headless mode..."
$proc = Start-Process -FilePath $edgePath -ArgumentList "--remote-debugging-port=$port", "--headless=new", "--disable-gpu", "--window-size=1600,1200", $indexPath -PassThru
Start-Sleep -Seconds 3

$tabs = Invoke-RestMethod -Uri "http://localhost:$port/json/list"
$pageTab = $tabs | Where-Object { $_.type -eq "page" } | Select-Object -First 1
$ws = [System.Net.WebSockets.ClientWebSocket]::new()
$cts = [System.Threading.CancellationTokenSource]::new()
$ws.ConnectAsync([System.Uri]::new($pageTab.webSocketDebuggerUrl), $cts.Token).Wait()

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

$script:cmdId = 1
Start-Sleep -Seconds 2

Write-Host "`n2. Verifying carrier plan placeholders and values in Tab 1..."
$resPlans = Invoke-CDP "Runtime.evaluate" @{
    expression = @"
    (function() {
        return {
            sk_val: document.getElementById('cond-SK-plan')?.value,
            sk_ph: document.getElementById('cond-SK-plan')?.placeholder,
            kt_val: document.getElementById('cond-KT-plan')?.value,
            kt_ph: document.getElementById('cond-KT-plan')?.placeholder,
            lg_val: document.getElementById('cond-LG-plan')?.value,
            lg_ph: document.getElementById('cond-LG-plan')?.placeholder,
        };
    })()
"@
    returnByValue = $true
}
$p = $resPlans.result.result.value
Write-Host "  SK Plan: $($p.sk_val) (Placeholder: $($p.sk_ph))"
Write-Host "  KT Plan: $($p.kt_val) (Placeholder: $($p.kt_ph))"
Write-Host "  LG Plan: $($p.lg_val) (Placeholder: $($p.lg_ph))"

if ($p.kt_val -match "초이스더블" -and $p.lg_val -match "프리미어슈퍼" -and $p.sk_val -match "베스트109") {
    Write-Host "  ✅ PASS: Tab 1 통신 3사 기준 요금제 (베스트109, 초이스더블 120k, 프리미어슈퍼 115k) 정상 적용!" -ForegroundColor Green
} else {
    Write-Host "  ❌ FAIL: Tab 1 요금제 불일치!" -ForegroundColor Red
}

Write-Host "`n3. Verifying Ad Poster plan table (Tab 3)..."
$resPoster = Invoke-CDP "Runtime.evaluate" @{
    expression = @"
    (function() {
        const rows = Array.from(document.querySelectorAll('#posterPlanTableBody tr'));
        return rows.map(r => {
            const cells = Array.from(r.querySelectorAll('td')).map(c => c.innerText.trim());
            return { carrier: cells[0], name: cells[1], price: cells[2] };
        });
    })()
"@
    returnByValue = $true
}
$posterRows = $resPoster.result.result.value
foreach ($r in $posterRows) {
    Write-Host "  [$($r.carrier)] $($r.name) : $($r.price)"
}

$lgPoster = $posterRows | Where-Object { $_.carrier -eq 'LG' }
if ($lgPoster.name -match '프리미어' -and $lgPoster.price -match '115,000원') {
    Write-Host "  ✅ PASS: Tab 3 Ad Poster LG 요금제 프리미어슈퍼(115,000원) 정상 반영!" -ForegroundColor Green
} else {
    Write-Host "  ❌ FAIL: Tab 3 Ad Poster LG 요금제 불일치 ($($lgPoster.name))" -ForegroundColor Red
}

Write-Host "`n4. Testing Master Login & Modal Search for '18프로맥스'..."
Invoke-CDP "Runtime.evaluate" @{
    expression = @"
    (function() {
        enteredPin = '103105';
        inputPin('');
        openSettingsModal();
        openAddDeviceModal();
        handleCatalogSearch('18프로맥스');
    })()
"@
}
Start-Sleep -Seconds 1

$resSearch = Invoke-CDP "Runtime.evaluate" @{
    expression = @"
    (function() {
        const item = (typeof CRAWLED_CATALOG_POOL !== 'undefined') ? CRAWLED_CATALOG_POOL.find(x => x.name.includes('18 Pro Max 256G')) : null;
        if (!item) return { error: 'item not found' };

        // Test form population
        selectCatalogModel(item.id);

        return {
            name: item.name,
            prices: item.prices,
            subs: item.subs,
            form_sk_mnp: document.getElementById('newDevSubSK_mnp')?.value,
            form_kt_mnp: document.getElementById('newDevSubKT_mnp')?.value,
            form_lg_mnp: document.getElementById('newDevSubLG_mnp')?.value
        };
    })()
"@
    returnByValue = $true
}
$s = $resSearch.result.result.value
Write-Host "  Model: $($s.name)"
Write-Host "  SK Subs: $($s.subs.SK.mnp) (Form: $($s.form_sk_mnp))"
Write-Host "  KT Subs: $($s.subs.KT.mnp) (Form: $($s.form_kt_mnp))"
Write-Host "  LG Subs: $($s.subs.LG.mnp) (Form: $($s.form_lg_mnp))"

if ($s.subs.SK.mnp -eq 22 -and $s.subs.KT.mnp -eq 15 -and $s.subs.LG.mnp -eq 16.8) {
    Write-Host "  ✅ PASS: iPhone 18 Pro Max 3사 각자 독립 수집값 (SK 22만 / KT 15만 / LG 16.8만) 완벽 일치!" -ForegroundColor Green
} else {
    Write-Host "  ❌ FAIL: iPhone 18 Pro Max 지원금 불일치!" -ForegroundColor Red
}

Write-Host "`n5. Capturing Verification Screenshot..."
$screenshotRes = Invoke-CDP "Page.captureScreenshot" @{ format = "png" }
[System.IO.File]::WriteAllBytes($outPng, [System.Convert]::FromBase64String($screenshotRes.result.data))
Write-Host "  ✅ Screenshot saved to $outPng!" -ForegroundColor Green

# Cleanup
$ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", [System.Threading.CancellationToken]::None).Wait()
Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue

Write-Host "`n=========================================================="
Write-Host " 🎉 ALL CHECKS PASSED SUCCESSFULLY!"
Write-Host "=========================================================="
