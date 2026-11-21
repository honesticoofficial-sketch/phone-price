$ErrorActionPreference = "Stop"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) { $edgePath = "C:\Program Files\Microsoft\Edge\Application\msedge.exe" }

$port = 9296
$userDataDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\edge_verify_teconomy2"
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

        $buffer = New-Object byte[] 2097152
        while ($true) {
            $recvSeg = New-Object System.ArraySegment[byte] -ArgumentList @(,$buffer)
            $res = $ws.ReceiveAsync($recvSeg, $cts.Token).Result
            $text = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $res.Count)
            $parsed = $text | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($parsed -and $parsed.id -eq $script:reqId) {
                if ($parsed.result -and $parsed.result.result) {
                    return $parsed.result.result.value
                }
                if ($parsed.result -and $parsed.result.data) {
                    return $parsed.result.data
                }
                return $parsed.result
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
    (async function() {
        setAffiliateCarrier('SKT');
        handleSelectAffiliateCard('skt_kb_teconomy');
        renderCardPreview();

        const box = document.getElementById('cardPlateBox');
        const img = box?.querySelector('img');

        if (img && !img.complete) {
            await new Promise(resolve => {
                img.onload = resolve;
                img.onerror = resolve;
                setTimeout(resolve, 1000);
            });
        }
        await new Promise(r => setTimeout(r, 200));

        if (img) autoAdaptCardPlate(img);

        return {
            cardName: cardData.cardName,
            carrier: cardData.carrier,
            boxClass: box?.className || '',
            isHorizontal: box?.className.includes('w-36'),
            isVertical: box?.className.includes('w-[94px]'),
            imgSrcPrefix: img?.src?.substring(0, 30),
            imgNaturalW: img?.naturalWidth,
            imgNaturalH: img?.naturalHeight,
            ratio: (img?.naturalWidth && img?.naturalHeight) ? (img.naturalWidth / img.naturalHeight).toFixed(3) : 0
        };
    })()
"@

    $res = Send-Cdp -method "Runtime.evaluate" -params @{
        expression = $evalScript
        awaitPromise = $true
        returnByValue = $true
    }

    Write-Host "=================== T-economy KB국민카드 렌더링 실측 ==================="
    Write-Host "1. 카드 정보: $($res.cardName) ($($res.carrier))"
    Write-Host "2. 이미지 원본 해상도: $($res.imgNaturalW) x $($res.imgNaturalH)"
    Write-Host "3. 가로:세로 종횡비: $($res.ratio) : 1 (기존 왜곡 2.99:1 -> 정상 1.583:1)"
    Write-Host "4. 가로 플레이트 박스(w-36) 정상 장착 여부: $($res.isHorizontal)"
    Write-Host "========================================================================"

    # Capture screenshot
    $screenRes = Send-Cdp -method "Page.captureScreenshot" -params @{
        format = "png"
    }
    if ($screenRes -and $screenRes.data) {
        $screenBytes = [Convert]::FromBase64String($screenRes.data)
        [System.IO.File]::WriteAllBytes("C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\teconomy_page_screenshot.png", $screenBytes)
        Write-Host "Saved full screenshot to scratch\teconomy_page_screenshot.png"
    }

    if ($res.isHorizontal -and $res.ratio -eq "1.583" -and $res.imgNaturalW -eq 570 -and $res.imgNaturalH -eq 360) {
        Write-Host "🎉 T-economy KB국민카드 이미지 종횡비 및 렌더링 100% 정상화 PASS!" -ForegroundColor Green
    } else {
        Write-Host "❌ 불일치 발생!" -ForegroundColor Red
    }

} finally {
    if ($ws -and $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        $ws.CloseOutputAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
    }
    if ($edgeProcess -and -not $edgeProcess.HasExited) {
        Stop-Process -Id $edgeProcess.Id -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -Recurse -Force $userDataDir -ErrorAction SilentlyContinue
}