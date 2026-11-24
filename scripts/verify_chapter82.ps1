[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9275
$htmlPath = "file:///C:/Users/User01/.gemini/antigravity/scratch/phone-price/index.html"

Write-Host "=========================================================="
Write-Host " [Chapter 82-B] 18프로 공시지원금 & 개통방식별(번이/기변) 전수 검증"
Write-Host "=========================================================="

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
            returnByValue = $true
            awaitPromise = $true
        }
        if ($res.result.exceptionDetails) {
            throw "JS 에러: $($res.result.exceptionDetails.exception.description)"
        }
        return $res.result.result.value
    }

    Eval-JSAsync @"
        window.alert = function(msg) { console.log('ALERT:', msg); };
        window.confirm = function(msg) { console.log('CONFIRM:', msg); return true; };
"@

    # 1. Master Login
    Write-Host "1. Master Login (103105)..."
    Eval-JSAsync @"
        currentRole = 'master';
        currentStoreId = 'myeongji';
        isUnlocked = true;
        updateTabBadgesForRole();
"@

    # 2. Check 18 Pro
    Write-Host "`n2. Verifying iPhone 18 Pro Search and Auto-Fill..."
    $check18 = Eval-JSAsync @"
        (() => {
            openSettingsModal();
            openAddDeviceModal();
            handleCatalogSearch('18프로');

            const resEl = document.getElementById('catalogSearchResults');
            const searchHtml = resEl ? resEl.innerHTML : '';

            // Select iPhone 18 Pro 256G
            selectCatalogModel('ip18p256g');

            const name = document.getElementById('newDevName').value;
            const priceSK = document.getElementById('newDevPriceSK').value;
            const priceKT = document.getElementById('newDevPriceKT').value;
            const priceLG = document.getElementById('newDevPriceLG').value;

            const subSK_mnp = document.getElementById('newDevSubSK_mnp').value;
            const subSK_chg = document.getElementById('newDevSubSK_chg').value;
            const subKT_mnp = document.getElementById('newDevSubKT_mnp').value;
            const subKT_chg = document.getElementById('newDevSubKT_chg').value;
            const subLG_mnp = document.getElementById('newDevSubLG_mnp').value;
            const subLG_chg = document.getElementById('newDevSubLG_chg').value;

            return {
                searchHas18Pro: searchHtml.includes('iPhone 18 Pro 256G'),
                name,
                prices: { SK: priceSK, KT: priceKT, LG: priceLG },
                subs: {
                    SK: { mnp: subSK_mnp, chg: subSK_chg },
                    KT: { mnp: subKT_mnp, chg: subKT_chg },
                    LG: { mnp: subLG_mnp, chg: subLG_chg }
                }
            };
        })()
"@
    Write-Host "   -> Search found 18 Pro: $($check18.searchHas18Pro)"
    Write-Host "   -> Selected Model: $($check18.name)"
    Write-Host "   -> Prices: SK $($check18.prices.SK)만 / KT $($check18.prices.KT)만 / LG $($check18.prices.LG)만"
    Write-Host "   -> SK 공시: 번이 $($check18.subs.SK.mnp)만 / 기변 $($check18.subs.SK.chg)만"
    Write-Host "   -> KT 공시: 번이 $($check18.subs.KT.mnp)만 / 기변 $($check18.subs.KT.chg)만"
    Write-Host "   -> LG 공시: 번이 $($check18.subs.LG.mnp)만 / 기변 $($check18.subs.LG.chg)만"

    if (-not $check18.searchHas18Pro) { throw "18프로 검색 실패" }
    if ($check18.subs.LG.mnp -eq "0" -or [string]::IsNullOrEmpty($check18.subs.LG.mnp)) {
        throw "LG 18프로 공시지원금이 여전히 0원입니다!"
    }
    if ($check18.subs.KT.mnp -eq "0" -or [string]::IsNullOrEmpty($check18.subs.KT.mnp)) {
        throw "KT 18프로 공시지원금이 여전히 0원입니다!"
    }
    Write-Host "   [PASS] iPhone 18 Pro 통신 3사 공시지원금 정상화 완료!"

    # 3. Check S24 (which has different MNP vs CHG: SK 63 vs 55)
    Write-Host "`n3. Verifying Model with Different MNP vs CHG (S24 Ultra)..."
    $checkS24 = Eval-JSAsync @"
        (() => {
            handleCatalogSearch('S24');
            selectCatalogModel('s24u256g');
            return {
                name: document.getElementById('newDevName').value,
                subSK: {
                    mnp: document.getElementById('newDevSubSK_mnp').value,
                    chg: document.getElementById('newDevSubSK_chg').value
                },
                subKT: {
                    mnp: document.getElementById('newDevSubKT_mnp').value,
                    chg: document.getElementById('newDevSubKT_chg').value
                }
            };
        })()
"@
    Write-Host "   -> Model: $($checkS24.name)"
    Write-Host "   -> SK 공시: 번이 $($checkS24.subSK.mnp)만 / 기변 $($checkS24.subSK.chg)만"
    Write-Host "   -> KT 공시: 번이 $($checkS24.subKT.mnp)만 / 기변 $($checkS24.subKT.chg)만"
    if ($checkS24.subSK.mnp -ne "63" -or $checkS24.subSK.chg -ne "55") {
        throw "S24 울트라 번이/기변 공시 분리 실패!"
    }
    Write-Host "   [PASS] 번호이동 vs 기기변경 차등 공시지원금 분리 반영 성공!"

    # 4. Check Affiliate Card Unlock for Myeongji Store
    Write-Host "`n4. Re-verifying Affiliate Card Unlock for Store Role..."
    $cardCheck = Eval-JSAsync @"
        (() => {
            currentRole = 'worker';
            currentStoreId = 'myeongji';
            updateTabBadgesForRole();
            const badge = document.getElementById('tabBadge-card');
            return { hasBadge: !!badge };
        })()
"@
    Write-Host "   -> Card Lock Badge exists: $($cardCheck.hasBadge) (Expected: False)"
    if ($cardCheck.hasBadge) { throw "제휴카드 잠금 뱃지 잔존" }
    Write-Host "   [PASS] 제휴카드 잠금 해제 유지 확인!"

    # 5. Capture verification screenshot
    Write-Host "`n5. Capturing Screenshot..."
    Eval-JSAsync @"
        currentRole = 'master';
        openSettingsModal();
        openAddDeviceModal();
        handleCatalogSearch('18프로');
"@
    Start-Sleep -Milliseconds 500

    $ss = Invoke-CDP "Page.captureScreenshot" @{ format = "png" }
    $bytes = [System.Convert]::FromBase64String($ss.result.data)
    $ssPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\chapter82_verified.png"
    [System.IO.File]::WriteAllBytes($ssPath, $bytes)
    Write-Host "   -> Screenshot saved: $ssPath"

    Write-Host "`n=========================================================="
    Write-Host " 🎉 ALL 18 Pro & MNP/CHG RE-VERIFICATION TESTS PASSED!"
    Write-Host "=========================================================="

} finally {
    if ($ws -and $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", [System.Threading.CancellationToken]::None).Wait()
    }
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}
