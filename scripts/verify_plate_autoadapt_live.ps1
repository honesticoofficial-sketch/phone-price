$ErrorActionPreference = "Stop"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) { $edgePath = "C:\Program Files\Microsoft\Edge\Application\msedge.exe" }

$port = 9272
$userDataDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\edge_verify_plates"
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

        $buffer = New-Object byte[] 655360
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

    # PIN 자동 해제
    Send-Cdp -method "Runtime.evaluate" -params @{
        expression = "for (let ch of '103105') { inputPin(ch); }"
        returnByValue = $true
    } | Out-Null
    Start-Sleep -Milliseconds 500

    # 4대 대표 카드 실시간 렌더링 및 자동 맞춤 검증
    $testExpression = @"
    (function() {
        const results = {};

        // 1. LGU+ 삼성 라이트 (90도 회전되어 똑바로 선 세로형 카드)
        setAffiliateCarrier('LGU');
        handleSelectAffiliateCard('lgu_samsung_light');
        renderCardPreview();
        const samsungBox = document.getElementById('cardPlateBox');
        const samsungImg = samsungBox?.querySelector('img');
        if (samsungImg) autoAdaptCardPlate(samsungImg);
        results.samsungClass = samsungBox?.className || '';
        results.samsungIsVertical = results.samsungClass.includes('w-[94px]');

        // 2. LGU+ 롯데 LOCA (반듯한 가로형 카드)
        handleSelectAffiliateCard('lgu_lotte_loca');
        renderCardPreview();
        const locaBox = document.getElementById('cardPlateBox');
        const locaImg = locaBox?.querySelector('img');
        if (locaImg) autoAdaptCardPlate(locaImg);
        results.locaClass = locaBox?.className || '';
        results.locaIsHorizontal = results.locaClass.includes('w-36');

        // 3. KT KB국민카드 할부 Plus (세로형 원격 카드)
        setAffiliateCarrier('KT');
        handleSelectAffiliateCard('kt_kb_light_plus');
        renderCardPreview();
        const ktBox = document.getElementById('cardPlateBox');
        results.ktClass = ktBox?.className || '';
        results.ktIsVertical = results.ktClass.includes('w-[94px]');

        // 4. SKT 삼성카드 T PREMIUM (가로형 카드)
        setAffiliateCarrier('SKT');
        handleSelectAffiliateCard('skt_samsung_premium');
        renderCardPreview();
        const sktBox = document.getElementById('cardPlateBox');
        const sktImg = sktBox?.querySelector('img');
        if (sktImg) autoAdaptCardPlate(sktImg);
        results.sktClass = sktBox?.className || '';
        results.sktIsHorizontal = results.sktClass.includes('w-36');

        return results;
    })()
"@

    $res = Send-Cdp -method "Runtime.evaluate" -params @{
        expression = $testExpression
        returnByValue = $true
    }

    Write-Host "===================================================="
    Write-Host "🌟 카드 이미지 '배경 크롭 & 길이 자동 맞춤' 브라우저 실측"
    Write-Host "===================================================="
    Write-Host "1. LGU+ 삼성 라이트 (회전 완료된 세로형 카드):"
    Write-Host "   - 세로형 규격(w-[94px]) 자동 일치: $($res.samsungIsVertical) (기대치: True)"
    Write-Host "`n2. LGU+ 롯데 LOCA (가로형 실물 카드):"
    Write-Host "   - 가로형 규격(w-36) 자동 일치: $($res.locaIsHorizontal) (기대치: True)"
    Write-Host "`n3. KT KB 할부 Plus (KT 세로형 카드):"
    Write-Host "   - 세로형 규격(w-[94px]) 자동 일치: $($res.ktIsVertical) (기대치: True)"
    Write-Host "`n4. SKT 삼성 T PREMIUM (SKT 가로형 카드):"
    Write-Host "   - 가로형 규격(w-36) 자동 일치: $($res.sktIsHorizontal) (기대치: True)"
    Write-Host "===================================================="

    if ($res.samsungIsVertical -and $res.locaIsHorizontal -and $res.ktIsVertical -and $res.sktIsHorizontal) {
        Write-Host "🎉 카드 플레이트 규격 100% 자동 맞춤 ALL PASS! 완벽합니다!" -ForegroundColor Green
    } else {
        Write-Host "❌ 일부 조건 불일치 발생" -ForegroundColor Red
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
