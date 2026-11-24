[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9285
$htmlPath = "file:///C:/Users/User01/.gemini/antigravity/scratch/phone-price/index.html"

Write-Host "=========================================================="
Write-Host " [Chapter 82-C] SK 109k, KT 120k, LG 115k 기준 공시 전수 검증"
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

    # 2. Check active devices array for ip17
    Write-Host "`n2. Verifying active devices array for ip17 (아이폰17)..."
    $ip17Dev = Eval-JSAsync @"
        (() => {
            const d = devices.find(x => x.id === 'ip17');
            return {
                name: d ? d.name : null,
                prices: d ? d.prices : null,
                subSK: d ? d.sub.SK : null,
                subKT: d ? d.sub.KT : null,
                subLG: d ? d.sub.LG : null
            };
        })()
"@
    Write-Host "   -> Model: $($ip17Dev.name)"
    Write-Host "   -> SK: 번이 $($ip17Dev.subSK.mnp)만 / 기변 $($ip17Dev.subSK.chg)만"
    Write-Host "   -> KT: 번이 $($ip17Dev.subKT.mnp)만 / 기변 $($ip17Dev.subKT.chg)만"
    Write-Host "   -> LG: 번이 $($ip17Dev.subLG.mnp)만 / 기변 $($ip17Dev.subLG.chg)만"

    if ($ip17Dev.subLG.mnp -ne 55 -or $ip17Dev.subLG.chg -ne 45) {
        throw "기본 테이블 아이폰17 LG 번이 55 / 기변 45 불일치! (현재: $($ip17Dev.subLG.mnp) / $($ip17Dev.subLG.chg))"
    }
    Write-Host "   [PASS] 기본 테이블 아이폰17 LG 번이 55 / 기변 45 정상 확인!"

    # 3. Check Add Device Modal: Search '아이폰17'
    Write-Host "`n3. Verifying Add Device Modal search for '아이폰17'..."
    $ip17Catalog = Eval-JSAsync @"
        (() => {
            openSettingsModal();
            openAddDeviceModal();
            handleCatalogSearch('아이폰17');
            selectCatalogModel('ip17256g');

            return {
                name: document.getElementById('newDevName').value,
                subSK_mnp: document.getElementById('newDevSubSK_mnp').value,
                subSK_chg: document.getElementById('newDevSubSK_chg').value,
                subKT_mnp: document.getElementById('newDevSubKT_mnp').value,
                subKT_chg: document.getElementById('newDevSubKT_chg').value,
                subLG_mnp: document.getElementById('newDevSubLG_mnp').value,
                subLG_chg: document.getElementById('newDevSubLG_chg').value
            };
        })()
"@
    Write-Host "   -> Form Filled Model: $($ip17Catalog.name)"
    Write-Host "   -> SK Filled: 번이 $($ip17Catalog.subSK_mnp)만 / 기변 $($ip17Catalog.subSK_chg)만"
    Write-Host "   -> KT Filled: 번이 $($ip17Catalog.subKT_mnp)만 / 기변 $($ip17Catalog.subKT_chg)만"
    Write-Host "   -> LG Filled: 번이 $($ip17Catalog.subLG_mnp)만 / 기변 $($ip17Catalog.subLG_chg)만"

    if ($ip17Catalog.subLG_mnp -ne "55" -or $ip17Catalog.subLG_chg -ne "45") {
        throw "카탈로그 아이폰17 자동입력 실패! LG 번이 $($ip17Catalog.subLG_mnp) / 기변 $($ip17Catalog.subLG_chg)"
    }
    Write-Host "   [PASS] 카탈로그 아이폰17 LG 번이 55 / 기변 45 자동채우기 완벽 검증!"

    # 4. Check Add Device Modal: Search '18프로'
    Write-Host "`n4. Verifying Add Device Modal search for '18프로' (SK 109k / KT 120k / LG 115k)..."
    $ip18Catalog = Eval-JSAsync @"
        (() => {
            handleCatalogSearch('18프로');
            selectCatalogModel('ip18p256g');

            return {
                name: document.getElementById('newDevName').value,
                subSK_mnp: document.getElementById('newDevSubSK_mnp').value,
                subSK_chg: document.getElementById('newDevSubSK_chg').value,
                subKT_mnp: document.getElementById('newDevSubKT_mnp').value,
                subKT_chg: document.getElementById('newDevSubKT_chg').value,
                subLG_mnp: document.getElementById('newDevSubLG_mnp').value,
                subLG_chg: document.getElementById('newDevSubLG_chg').value
            };
        })()
"@
    Write-Host "   -> Form Filled Model: $($ip18Catalog.name)"
    Write-Host "   -> SK Filled: 번이 $($ip18Catalog.subSK_mnp)만 / 기변 $($ip18Catalog.subSK_chg)만"
    Write-Host "   -> KT Filled: 번이 $($ip18Catalog.subKT_mnp)만 / 기변 $($ip18Catalog.subKT_chg)만"
    Write-Host "   -> LG Filled: 번이 $($ip18Catalog.subLG_mnp)만 / 기변 $($ip18Catalog.subLG_chg)만"

    if ($ip18Catalog.subSK_mnp -ne "45" -or $ip18Catalog.subKT_mnp -ne "45" -or $ip18Catalog.subLG_mnp -ne "45") {
        throw "18프로 최고 요금제(SK 109k, KT 120k, LG 115k) 45만 불일치!"
    }
    Write-Host "   [PASS] iPhone 18 Pro 최고 요금제 45만 통일 완벽 검증!"

    # 5. Capture Screenshot
    $ss = Invoke-CDP "Page.captureScreenshot" @{ format = "png" }
    $bytes = [System.Convert]::FromBase64String($ss.result.data)
    $ssPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\chapter82_verified.png"
    [System.IO.File]::WriteAllBytes($ssPath, $bytes)
    Write-Host "`n   -> Screenshot captured: $ssPath"

    Write-Host "`n=========================================================="
    Write-Host " 🎉 ALL Chapter 82-C VERIFICATION TESTS PASSED!"
    Write-Host "=========================================================="

} finally {
    if ($ws -and $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", [System.Threading.CancellationToken]::None).Wait()
    }
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}
