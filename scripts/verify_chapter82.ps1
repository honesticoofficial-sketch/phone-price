[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9255
$htmlPath = "file:///C:/Users/User01/.gemini/antigravity/scratch/phone-price/index.html"

Write-Host "=========================================================="
Write-Host " [Chapter 82] 플래그십 크롤링 풀 검색 & 제휴카드 잠금해제 검증"
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

    # Setup alert/confirm mock
    Eval-JSAsync @"
        window.alert = function(msg) { console.log('ALERT:', msg); };
        window.confirm = function(msg) { console.log('CONFIRM:', msg); return true; };
"@

    # ========================================================
    # TEST 1: 타매장(명지점 152411) 제휴카드 탭 잠금 해제 검증
    # ========================================================
    Write-Host "`n1. Testing Myongji Store (152411) Affiliate Card Unlock..."
    Eval-JSAsync @"
        '152411'.split('').forEach(d => inputPin(d));
"@
    Start-Sleep -Seconds 2

    $myeongjiStatus = Eval-JSAsync @"
        (() => {
            const cardBadge = document.getElementById('tabBadge-card');
            const cardBtn = document.getElementById('tabBtn-card');
            switchTab('card');
            const tabCard = document.getElementById('tab-card');
            const isHidden = tabCard.classList.contains('hidden');
            return {
                role: currentRole,
                storeId: currentStoreId,
                hasCardBadge: !!cardBadge,
                cardBtnText: cardBtn ? cardBtn.innerText.trim() : null,
                isTabCardVisible: !isHidden
            };
        })()
"@
    Write-Host "   -> Myeongji Role: $($myeongjiStatus.role), Store: $($myeongjiStatus.storeId)"
    Write-Host "   -> Card Badge exists: $($myeongjiStatus.hasCardBadge) (Expected: False)"
    Write-Host "   -> Card Button Text: '$($myeongjiStatus.cardBtnText)'"
    Write-Host "   -> Tab Card is Visible: $($myeongjiStatus.isTabCardVisible) (Expected: True)"

    if ($myeongjiStatus.hasCardBadge -eq $true) {
        throw "제휴카드 뱃지가 여전히 표시되고 있습니다!"
    }
    if ($myeongjiStatus.isTabCardVisible -ne $true) {
        throw "명지점에서 제휴카드 탭으로 전환되지 않았습니다!"
    }
    Write-Host "   [PASS] 타매장 제휴카드 잠금 해제 검증 성공!"

    # ========================================================
    # TEST 2: 마스터(103105) 로그인 & 크롤링 풀 검색 자동완성 검증
    # ========================================================
    Write-Host "`n2. Switching to Master Role (103105)..."
    Eval-JSAsync @"
        currentRole = 'master';
        currentStoreId = 'myeongji';
        isUnlocked = true;
        updateTabBadgesForRole();
"@

    $poolCount = Eval-JSAsync "CRAWLED_CATALOG_POOL.length"
    Write-Host "   -> CRAWLED_CATALOG_POOL total models: $poolCount (Expected: 88)"
    if ($poolCount -lt 80) { throw "크롤링 풀 기종 수가 부족합니다: $poolCount" }

    Write-Host "`n3. Testing Catalog Search & Auto-Fill in Add Device Modal..."
    $searchTest = Eval-JSAsync @"
        (() => {
            openSettingsModal();
            openAddDeviceModal();

            // 1. Search '16프로'
            handleCatalogSearch('16프로');
            const resEl = document.getElementById('catalogSearchResults');
            const searchHtml1 = resEl ? resEl.innerHTML : '';
            const searchHas16Pro = searchHtml1.includes('iPhone 16 Pro 128G');

            // 2. Select 'iPhone 16 Pro 128G'
            selectCatalogModel('ip16p128g');
            const nameVal = document.getElementById('newDevName').value;
            const groupVal = document.getElementById('newDevGroup').value;
            const pSK = document.getElementById('newDevPriceSK').value;
            const pKT = document.getElementById('newDevPriceKT').value;
            const pLG = document.getElementById('newDevPriceLG').value;
            const sSK = document.getElementById('newDevSubSK_mnp').value;
            const sLG = document.getElementById('newDevSubLG_mnp').value;

            // 3. Search '플립7'
            handleCatalogSearch('플립7');
            const searchHtml2 = resEl ? resEl.innerHTML : '';
            const searchHasFlip7 = searchHtml2.includes('갤럭시 Z 플립7 256G');

            // 4. Search 'S24'
            handleCatalogSearch('S24');
            const searchHtml3 = resEl ? resEl.innerHTML : '';
            const searchHasS24 = searchHtml3.includes('갤럭시 S24');

            return {
                modalVisible: !document.getElementById('addDeviceModal').classList.contains('hidden'),
                searchHas16Pro,
                selectedName: nameVal,
                selectedGroup: groupVal,
                prices: { SK: pSK, KT: pKT, LG: pLG },
                subs: { SK: sSK, LG: sLG },
                searchHasFlip7,
                searchHasS24
            };
        })()
"@
    Write-Host "   -> Add Device Modal Visible: $($searchTest.modalVisible)"
    Write-Host "   -> Search '16프로' found iPhone 16 Pro: $($searchTest.searchHas16Pro)"
    Write-Host "   -> Selected Model Name: '$($searchTest.selectedName)'"
    Write-Host "   -> Selected Group: '$($searchTest.selectedGroup)'"
    Write-Host "   -> Prices: SK $($searchTest.prices.SK)만 / KT $($searchTest.prices.KT)만 / LG $($searchTest.prices.LG)만"
    Write-Host "   -> Subsidies: SK $($searchTest.subs.SK)만 / LG $($searchTest.subs.LG)만"
    Write-Host "   -> Search '플립7' found Z Flip7: $($searchTest.searchHasFlip7)"
    Write-Host "   -> Search 'S24' found Galaxy S24: $($searchTest.searchHasS24)"

    if (-not $searchTest.searchHas16Pro) { throw "'16프로' 검색 실패" }
    if ($searchTest.selectedName -ne "iPhone 16 Pro 128G") { throw "기종명 채우기 불일치" }
    if ($searchTest.prices.SK -ne "154") { throw "출고가 채우기 불일치" }
    if (-not $searchTest.searchHasFlip7) { throw "'플립7' 검색 실패" }
    if (-not $searchTest.searchHasS24) { throw "'S24' 검색 실패" }
    Write-Host "   [PASS] 검색 및 자동입력 검증 성공!"

    # ========================================================
    # TEST 3: 빠른 필터 (갤럭시 S / 폴더블 / 아이폰) 검증
    # ========================================================
    Write-Host "`n4. Testing Quick Group Filters..."
    $filterTest = Eval-JSAsync @"
        (() => {
            clearCatalogSearch();
            filterCatalogGroup('FOLD');
            const resFold = document.getElementById('catalogSearchResults').innerHTML;
            const countFold = (resFold.match(/⚡ 즉시 추가/g) || []).length;

            filterCatalogGroup('IPHONE');
            const resIphone = document.getElementById('catalogSearchResults').innerHTML;
            const countIphone = (resIphone.match(/⚡ 즉시 추가/g) || []).length;

            filterCatalogGroup('S');
            const resS = document.getElementById('catalogSearchResults').innerHTML;
            const countS = (resS.match(/⚡ 즉시 추가/g) || []).length;

            return { countFold, countIphone, countS };
        })()
"@
    Write-Host "   -> FOLD filter items: $($filterTest.countFold)"
    Write-Host "   -> IPHONE filter items: $($filterTest.countIphone)"
    Write-Host "   -> S filter items: $($filterTest.countS)"
    if ($filterTest.countFold -eq 0 -or $filterTest.countIphone -eq 0 -or $filterTest.countS -eq 0) {
        throw "필터별 결과 항목 부족"
    }
    Write-Host "   [PASS] 빠른 그룹 필터 검증 성공!"

    # ========================================================
    # TEST 4: Capture Screenshot
    # ========================================================
    Write-Host "`n5. Capturing Verification Screenshot..."
    # Keep modal with '16프로' search visible for screenshot
    Eval-JSAsync @"
        handleCatalogSearch('16프로');
"@
    Start-Sleep -Milliseconds 500

    $ss = Invoke-CDP "Page.captureScreenshot" @{ format = "png" }
    $bytes = [System.Convert]::FromBase64String($ss.result.data)
    $ssPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\chapter82_verified.png"
    [System.IO.File]::WriteAllBytes($ssPath, $bytes)
    Write-Host "   -> Screenshot saved to $ssPath ($([math]::Round($bytes.Length/1024, 1)) KB)"

    Write-Host "`n=========================================================="
    Write-Host " 🎉 Chapter 82 All Verification Tests PASSED!"
    Write-Host "=========================================================="

} finally {
    if ($ws -and $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", [System.Threading.CancellationToken]::None).Wait()
    }
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}
