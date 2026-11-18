$edgePath = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
$htmlPath = 'C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html'
$fileUrl = 'file:///' + $htmlPath.Replace('\', '/')
$port = 9222

Write-Output "Starting Edge with remote debugging on port $port..."
$edgeProc = Start-Process -FilePath $edgePath -ArgumentList "--headless=new", "--remote-debugging-port=$port", "--disable-gpu", $fileUrl -PassThru
Start-Sleep -Seconds 2

try {
    # Check if debugging port is active
    $version = Invoke-RestMethod -Uri "http://localhost:$port/json/version"
    Write-Output "Edge Browser: $($version.Browser)"
    
    $list = Invoke-RestMethod -Uri "http://localhost:$port/json/list"
    $page = $list | Where-Object { $_.type -eq 'page' } | Select-Object -First 1
    Write-Output "Page title: $($page.title)"
    Write-Output "WS URL: $($page.webSocketDebuggerUrl)"
    
    # Connect via WebSocket
    $ws = New-Object System.Net.WebSockets.ClientWebSocket
    $uri = New-Object System.Uri($page.webSocketDebuggerUrl)
    $cts = New-Object System.Threading.CancellationTokenSource
    $ws.ConnectAsync($uri, $cts.Token).Wait()
    Write-Output "Connected to CDP WebSocket!"
    
    $msgId = 1
    function SendCdp([string]$method, [hashtable]$params) {
        $script:msgId++
        $cmd = @{ id = $script:msgId; method = $method; params = $params } | ConvertTo-Json -Compress
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($cmd)
        $segment = New-Object System.ArraySegment[byte] -ArgumentList @(,$bytes)
        $ws.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $cts.Token).Wait()
        
        # Read response
        $buffer = New-Object byte[] 65536
        $resSegment = New-Object System.ArraySegment[byte] -ArgumentList @(,$buffer)
        $res = $ws.ReceiveAsync($resSegment, $cts.Token).Result
        $resStr = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $res.Count)
        return ($resStr | ConvertFrom-Json)
    }
    
    function EvalJs([string]$expression) {
        $res = SendCdp "Runtime.evaluate" @{ expression = $expression; returnByValue = $true }
        return $res.result.result.value
    }
    
    # 1. Unlock with PIN 152411 (명지점)
    Write-Output "Unlocking app with PIN 152411..."
    EvalJs "['1','5','2','4','1','1'].forEach(d => inputPin(d));"
    Start-Sleep -Milliseconds 500

    # ★ 테스트 중 실서버 Firebase Firestore 데이터 오염 및 리베이트 덮어쓰기 원천 차단!
    EvalJs "window.db = null; window.scheduleStoreSave = function() {};"

    $unlocked = EvalJs "isUnlocked"
    $role = EvalJs "currentRole"
    $store = EvalJs "currentStoreName"
    Write-Output "App Unlocked: $unlocked, Role: $role, Store: $store (Cloud Save Disabled for Sandbox Test)"
    
    # 2. Test typing in daily rate
    Write-Output "Testing daily rate input..."
    EvalJs "setCarrierInput('SK');"
    $firstDevId = EvalJs "devices[0].id"
    $firstDevName = EvalJs "devices[0].name"
    Write-Output "First device: $firstDevName ($firstDevId)"
    
    # Type live
    EvalJs "updateRateLive('$firstDevId', 'mnp', '888');"
    $inMemRate = EvalJs "devices[0].rate.SK.mnp"
    Write-Output "In-memory rate after updateRateLive: $inMemRate"
    
    # Click another carrier button
    Write-Output "Clicking KT carrier button..."
    EvalJs "setCarrierInput('KT');"
    Start-Sleep -Milliseconds 200
    EvalJs "setCarrierInput('SK');"
    $rateAfterClick = EvalJs "devices[0].rate.SK.mnp"
    Write-Output "Rate after switching carriers and back: $rateAfterClick"
    
    if ($rateAfterClick -eq "888") {
        Write-Output ">>> SUCCESS: Daily rate never reverted! (Value: $rateAfterClick)"
    } else {
        Write-Output ">>> FAILURE: Daily rate reverted! Expected 888, got: $rateAfterClick"
    }
    
    # Reset back to realistic number
    EvalJs "updateRateLive('$firstDevId', 'mnp', '35');"
    
    # 3. Test Card Tab and clicking Tier box on screen
    Write-Output "Switching to Card tab..."
    EvalJs "switchTab('card');"
    Start-Sleep -Milliseconds 400
    
    $curCarrier = EvalJs "currentAffiliateCarrier"
    $curCard = EvalJs "cardData.cardName"
    $curTier = EvalJs "currentAffiliateTierIndex"
    Write-Output "Current card: $curCard ($curCarrier), Tier: $curTier"
    
    # Simulate clicking tier 1 on the screen
    Write-Output "Clicking Tier index 1 on the preview screen..."
    EvalJs "setAffiliateTargetTier(1);"
    Start-Sleep -Milliseconds 300
    $newTier = EvalJs "currentAffiliateTierIndex"
    $totalAmt = EvalJs "document.getElementById('installmentTotalAmt').innerText"
    $monthlyAmt = EvalJs "document.getElementById('installmentMonthlyAmt').innerText"
    Write-Output "Tier after click: $newTier, Monthly: $monthlyAmt, Total: $totalAmt"
    
    if ($newTier -eq 1) {
        Write-Output ">>> SUCCESS: Screen click changed tier to 1!"
    } else {
        Write-Output ">>> FAILURE: Tier index is $newTier"
    }
    
    # Simulate clicking tier 2 on the screen
    Write-Output "Clicking Tier index 2 on the preview screen..."
    EvalJs "setAffiliateTargetTier(2);"
    Start-Sleep -Milliseconds 300
    $tier2 = EvalJs "currentAffiliateTierIndex"
    $totalAmt2 = EvalJs "document.getElementById('installmentTotalAmt').innerText"
    $monthlyAmt2 = EvalJs "document.getElementById('installmentMonthlyAmt').innerText"
    Write-Output "Tier after click 2: $tier2, Monthly: $monthlyAmt2, Total: $totalAmt2"
    
    if ($tier2 -eq 2) {
        Write-Output ">>> SUCCESS: Screen click changed tier to 2!"
    } else {
        Write-Output ">>> FAILURE: Tier index is $tier2"
    }
    
    # 4. Check card counts across carriers
    Write-Output "Checking card counts across SKT, KT, LGU..."
    $sktCount = EvalJs "AFFILIATE_CARDS_BY_CARRIER['SKT'].length"
    $ktCount = EvalJs "AFFILIATE_CARDS_BY_CARRIER['KT'].length"
    $lguCount = EvalJs "AFFILIATE_CARDS_BY_CARRIER['LGU'].length"
    Write-Output "Cards count: SKT=$sktCount, KT=$ktCount, LGU=$lguCount"
    
    # 5. Check if all 42 card images are horizontal
    $vertCount = EvalJs "
      let bad = 0;
      ['SKT', 'KT', 'LGU'].forEach(c => {
        (AFFILIATE_CARDS_BY_CARRIER[c] || []).forEach(card => {
          if (card.cardPlateOrientation !== 'horizontal') bad++;
        });
      });
      bad;
    "
    Write-Output "Cards with non-horizontal orientation flag: $vertCount"

    # 6. Test Master Admin Login (103105) & Test Store Sandbox Switcher
    Write-Output "Testing Master Login (103105) and Test Store..."
    EvalJs "lockApp();"
    Start-Sleep -Milliseconds 300
    EvalJs "['1','0','3','1','0','5'].forEach(d => inputPin(d));"
    Start-Sleep -Milliseconds 400

    $masterUnlocked = EvalJs "isUnlocked"
    $masterRole = EvalJs "currentRole"
    $switcherVisible = EvalJs "!document.getElementById('masterStoreSwitcher').classList.contains('hidden')"
    $testBtnExists = EvalJs "!!document.getElementById('switchBtn-test_store')"
    Write-Output "Master Logged In: $masterUnlocked, Role: $masterRole, Switcher Visible: $switcherVisible, TestBtn Exists: $testBtnExists"

    if ($masterRole -eq "master" -and $switcherVisible -and $testBtnExists) {
        Write-Output ">>> SUCCESS: Master login reveals store switcher with Test Store button!"
    } else {
        Write-Output ">>> FAILURE: Master store switcher not properly visible!"
    }

    # Switch to test_store
    Write-Output "Switching to test_store..."
    EvalJs "masterSwitchStore('test_store');"
    Start-Sleep -Milliseconds 300

    $curStoreAfterSwitch = EvalJs "currentStoreId"
    $badgeText = EvalJs "document.getElementById('userBadgeText').innerText"
    Write-Output "Store after switch: $curStoreAfterSwitch, Header Badge: $badgeText"

    if ($curStoreAfterSwitch -eq "test_store" -and $badgeText -like "*테스트매장*") {
        Write-Output ">>> SUCCESS: Switched to test_store with proper amber header badge!"
    } else {
        Write-Output ">>> FAILURE: Failed to switch to test_store ($curStoreAfterSwitch)"
    }

    # 7. Test General Store Isolation (152411 - 명지점 & 152422 - 광안점)
    Write-Output "Testing General Store Isolation (PIN 152411)..."
    EvalJs "lockApp();"
    Start-Sleep -Milliseconds 300
    EvalJs "['1','5','2','4','1','1'].forEach(d => inputPin(d));"
    Start-Sleep -Milliseconds 400

    $storeRole = EvalJs "currentRole"
    $storeSwitcherHidden = EvalJs "document.getElementById('masterStoreSwitcher').classList.contains('hidden')"
    $cardTestBtnHidden = EvalJs "document.getElementById('cardStoreBtn-test_store').classList.contains('hidden')"
    $compTestBtnHidden = EvalJs "document.getElementById('compStoreBtn-test_store').classList.contains('hidden')"
    $histTestBtnHidden = EvalJs "document.getElementById('histFilter-test_store').classList.contains('hidden')"

    Write-Output "Store Role: $storeRole, Switcher Hidden: $storeSwitcherHidden, Card Test Hidden: $cardTestBtnHidden, Comp Test Hidden: $compTestBtnHidden, Hist Test Hidden: $histTestBtnHidden"

    if ($storeSwitcherHidden -and $cardTestBtnHidden -and $compTestBtnHidden -and $histTestBtnHidden) {
        Write-Output ">>> SUCCESS: test_store is 100% hidden and isolated from general store accounts!"
    } else {
        Write-Output ">>> FAILURE: test_store was not properly hidden from general store!"
    }

    $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
} finally {
    if ($edgeProc -and !$edgeProc.HasExited) {
        $edgeProc.Kill()
    }
}
