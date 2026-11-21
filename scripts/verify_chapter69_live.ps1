$ErrorActionPreference = "Stop"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) { $edgePath = "C:\Program Files\Microsoft\Edge\Application\msedge.exe" }

$port = 9283
$userDataDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\edge_verify_ch69"
if (Test-Path $userDataDir) { Remove-Item -Recurse -Force $userDataDir -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $userDataDir -Force | Out-Null
$targetHtml = "file:///C:/Users/User01/.gemini/antigravity/scratch/phone-price/index.html"

$edgeProcess = Start-Process -FilePath $edgePath -ArgumentList @(
    "--remote-debugging-port=$port",
    "--user-data-dir=$userDataDir",
    "--headless=new",
    "--window-size=1600,1200",
    $targetHtml
) -PassThru

Start-Sleep -Seconds 3

try {
    $targets = Invoke-RestMethod -Uri ("http://127.0.0.1:" + $port + "/json")
    $target = $targets | Where-Object { $_.type -eq "page" -and $_.url -match "index.html" } | Select-Object -First 1

    $wsUrl = $target.webSocketDebuggerUrl
    $ws = New-Object System.Net.WebSockets.ClientWebSocket
    $cts = New-Object System.Threading.CancellationTokenSource
    $ws.ConnectAsync([uri]$wsUrl, $cts.Token).Wait()

    $reqId = 1
    function Send-Cdp($method, $params = @{}) {
        $script:reqId++
        $payload = @{
            id = $script:reqId
            method = $method
            params = $params
        } | ConvertTo-Json -Depth 10 -Compress
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
        $segment = New-Object System.ArraySegment[byte] -ArgumentList @(,$bytes)
        $ws.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $cts.Token).Wait()

        $buffer = New-Object byte[] 1048576
        while ($true) {
            $recvSeg = New-Object System.ArraySegment[byte] -ArgumentList @(,$buffer)
            $res = $ws.ReceiveAsync($recvSeg, $cts.Token).Result
            $text = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $res.Count)
            $parsed = $text | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($parsed -and $parsed.id -eq $script:reqId) {
                if ($parsed.result -and $parsed.result.result) {
                    return $parsed.result.result.value
                }
                return $null
            }
        }
    }

    # PIN 자동 입력
    Send-Cdp -method "Runtime.evaluate" -params @{
        expression = "for (let ch of '103105') { inputPin(ch); }"
        returnByValue = $true
    } | Out-Null
    Start-Sleep -Milliseconds 600

    $evalScript = @"
    (function() {
        const testRes = {};

        // 1. LGU+ 삼성 라이트 (lgu_samsung_light)
        setAffiliateCarrier('LGU');
        handleSelectAffiliateCard('lgu_samsung_light');
        renderCardPreview();
        let box = document.getElementById('cardPlateBox');
        let img = box?.querySelector('img');
        if (img) autoAdaptCardPlate(img);
        testRes.samsungLight = {
            cardName: cardData.cardName,
            boxClass: box?.className || '',
            isVertical: box?.className.includes('w-[94px]'),
            imgSrcPrefix: img?.src?.substring(0, 30),
            imgW: img?.naturalWidth,
            imgH: img?.naturalHeight
        };
        // 클릭 테스트
        box?.click();
        testRes.samsungLightAfterClick = {
            isVertical: box?.className.includes('w-[94px]')
        };

        // 2. KT DC Plus KB국민카드 (kt_kb_dc_plus)
        setAffiliateCarrier('KT');
        handleSelectAffiliateCard('kt_kb_dc_plus');
        renderCardPreview();
        box = document.getElementById('cardPlateBox');
        img = box?.querySelector('img');
        if (img) autoAdaptCardPlate(img);
        testRes.ktKbDcPlus = {
            cardName: cardData.cardName,
            boxClass: box?.className || '',
            isHorizontal: box?.className.includes('w-36'),
            imgW: img?.naturalWidth,
            imgH: img?.naturalHeight,
            orientation: cardData.cardPlateOrientation
        };
        // 클릭 테스트
        box?.click();
        testRes.ktKbDcPlusAfterClick = {
            isHorizontal: box?.className.includes('w-36')
        };

        // 3. KT 할부 Plus KB국민카드 (kt_kb_light_plus)
        handleSelectAffiliateCard('kt_kb_light_plus');
        renderCardPreview();
        box = document.getElementById('cardPlateBox');
        img = box?.querySelector('img');
        if (img) autoAdaptCardPlate(img);
        testRes.ktKbLightPlus = {
            cardName: cardData.cardName,
            boxClass: box?.className || '',
            isHorizontal: box?.className.includes('w-36'),
            imgW: img?.naturalWidth,
            imgH: img?.naturalHeight,
            orientation: cardData.cardPlateOrientation
        };

        // 4. KT 롯데 라이트할부 (세로형 정상 카드 확인)
        handleSelectAffiliateCard('kt_lotte_light');
        renderCardPreview();
        box = document.getElementById('cardPlateBox');
        img = box?.querySelector('img');
        if (img) autoAdaptCardPlate(img);
        testRes.ktLotteLight = {
            cardName: cardData.cardName,
            isVertical: box?.className.includes('w-[94px]'),
            orientation: cardData.cardPlateOrientation
        };

        // 5. SKT 삼성카드 T PREMIUM (가로형 정상 카드 확인)
        setAffiliateCarrier('SKT');
        handleSelectAffiliateCard('skt_samsung_premium');
        renderCardPreview();
        box = document.getElementById('cardPlateBox');
        img = box?.querySelector('img');
        if (img) autoAdaptCardPlate(img);
        testRes.sktSamsungPremium = {
            cardName: cardData.cardName,
            isHorizontal: box?.className.includes('w-36'),
            orientation: cardData.cardPlateOrientation
        };

        return testRes;
    })()
"@

    $res = Send-Cdp -method "Runtime.evaluate" -params @{
        expression = $evalScript
        returnByValue = $true
    }

    Write-Host "=================== 실시간 Edge CDP 검증 결과 ==================="
    Write-Host "1. LGU+ 삼성 라이트 카드:"
    Write-Host "   - 명칭: $($res.samsungLight.cardName)"
    Write-Host "   - 이미지 해상도: $($res.samsungLight.imgW) x $($res.samsungLight.imgH)"
    Write-Host "   - 세로 플레이트 박스(w-[94px]) 여부: $($res.samsungLight.isVertical) (기대치: True)"
    Write-Host "   - 클릭 후 세로 박스 유지 여부: $($res.samsungLightAfterClick.isVertical) (기대치: True - 수동 토글 제거됨)"
    
    Write-Host "`n2. KT DC Plus KB국민카드 (핵심 버그 수정 건):"
    Write-Host "   - 명칭: $($res.ktKbDcPlus.cardName)"
    Write-Host "   - 크롭 후 이미지 해상도: $($res.ktKbDcPlus.imgW) x $($res.ktKbDcPlus.imgH)"
    Write-Host "   - 가로 플레이트 박스(w-36) 여부: $($res.ktKbDcPlus.isHorizontal) (기대치: True)"
    Write-Host "   - 설정 orientation: $($res.ktKbDcPlus.orientation)"
    Write-Host "   - 클릭 후 가로 박스 유지 여부: $($res.ktKbDcPlusAfterClick.isHorizontal) (기대치: True - 토글 방지)"

    Write-Host "`n3. KT 할부 Plus KB국민카드:"
    Write-Host "   - 명칭: $($res.ktKbLightPlus.cardName)"
    Write-Host "   - 크롭 후 이미지 해상도: $($res.ktKbLightPlus.imgW) x $($res.ktKbLightPlus.imgH)"
    Write-Host "   - 가로 플레이트 박스(w-36) 여부: $($res.ktKbLightPlus.isHorizontal) (기대치: True)"

    Write-Host "`n4. 대조군 KT 롯데 라이트 (세로형 정상 유지):"
    Write-Host "   - 세로 플레이트 여부: $($res.ktLotteLight.isVertical) (기대치: True)"

    Write-Host "`n5. 대조군 SKT 삼성 프리미엄 (가로형 정상 유지):"
    Write-Host "   - 가로 플레이트 여부: $($res.sktSamsungPremium.isHorizontal) (기대치: True)"
    Write-Host "=================================================================="

    $allPass = $res.samsungLight.isVertical -and 
               $res.samsungLightAfterClick.isVertical -and 
               $res.ktKbDcPlus.isHorizontal -and 
               $res.ktKbDcPlusAfterClick.isHorizontal -and 
               $res.ktKbLightPlus.isHorizontal -and 
               $res.ktLotteLight.isVertical -and 
               $res.sktSamsungPremium.isHorizontal

    if ($allPass) {
        Write-Host "🎉 모든 검증 항목 100% PASS! 완벽하게 정상 동작합니다!" -ForegroundColor Green
    } else {
        Write-Host "❌ 일부 항목 불일치 발생!" -ForegroundColor Red
    }

} finally {
    if ($ws -and $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
    }
    if ($edgeProcess -and -not $edgeProcess.HasExited) {
        Stop-Process -Id $edgeProcess.Id -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -Recurse -Force $userDataDir -ErrorAction SilentlyContinue
}