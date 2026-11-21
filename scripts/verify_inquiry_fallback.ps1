$ErrorActionPreference = "Stop"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) { $edgePath = "C:\Program Files\Microsoft\Edge\Application\msedge.exe" }

$port = 9270
$userDataDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\edge_verify_fallback"
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

    # 검증 1: 정상 카드 (신한 Bora) - 🟢 인정 / 🔴 제외 렌더링 확인
    $evalRes = Send-Cdp -method "Runtime.evaluate" -params @{
        expression = @"
        (function() {
            setAffiliateCarrier('LGU');
            handleSelectAffiliateCard('lgu_shinhan_bora');
            renderCardPreview();
            const sheetHtml1 = document.getElementById('cardA4Sheet')?.innerHTML || '';
            const hasRealIncludes = sheetHtml1.includes('이동통신요금 자동이체 결제금액 (실적 인정 🟢)');
            const hasRealExcludes = sheetHtml1.includes('단기카드대출(현금서비스)');
            const hasFakeWarning1 = sheetHtml1.includes('전월실적 산정기준 카드사 공식 문의');

            // 검증 2: 실적 데이터가 없는 미확인 카드 시뮬레이션
            cardData.performanceIncludes = [];
            cardData.performanceExcludes = [];
            renderCardPreview();
            const sheetHtml2 = document.getElementById('cardA4Sheet')?.innerHTML || '';
            const showsInquiryBox = sheetHtml2.includes('전월실적 산정기준 카드사 공식 문의');
            const noFakeDefaults = !sheetHtml2.includes('이동통신요금 자동이체 결제금액') && !sheetHtml2.includes('과태료/벌금');

            return {
                hasRealIncludes: hasRealIncludes,
                hasRealExcludes: hasRealExcludes,
                hasFakeWarning1: hasFakeWarning1,
                showsInquiryBox: showsInquiryBox,
                noFakeDefaults: noFakeDefaults
            };
        })()
"@
        returnByValue = $true
    }

    Write-Host "===================================================="
    Write-Host "🌟 전월실적 '가짜 정보 차단 & 카드사 문의' 실시간 검증"
    Write-Host "===================================================="
    Write-Host "1. 정상 검증 카드 선택 시:"
    Write-Host "   - 🟢 진짜 실적 인정 항목 노출: $($evalRes.hasRealIncludes) (기대치: True)"
    Write-Host "   - 🔴 진짜 실적 제외 항목 노출: $($evalRes.hasRealExcludes) (기대치: True)"
    Write-Host "   - ⚠️ 카드사 문의 박스 비노출: $(-not $evalRes.hasFakeWarning1) (기대치: True)"
    Write-Host "`n2. 실적 미확인 카드 시뮬레이션 시:"
    Write-Host "   - ⚠️ '전월실적 산정기준 카드사 공식 문의' 노출: $($evalRes.showsInquiryBox) (기대치: True)"
    Write-Host "   - 🚫 가짜 하드코딩 리스트 생성 차단: $($evalRes.noFakeDefaults) (기대치: True)"
    Write-Host "===================================================="

    if ($evalRes.hasRealIncludes -and $evalRes.hasRealExcludes -and $evalRes.showsInquiryBox -and $evalRes.noFakeDefaults) {
        Write-Host "🎉 가짜 정보 완전 차단 & 카드사 공식 문의 Fallback 100% ALL PASS!" -ForegroundColor Green
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
