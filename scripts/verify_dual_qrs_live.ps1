$ErrorActionPreference = "Stop"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) { $edgePath = "C:\Program Files\Microsoft\Edge\Application\msedge.exe" }

$port = 9244
$userDataDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\edge_profile_dual_qrs"
New-Item -ItemType Directory -Path $userDataDir -Force | Out-Null
$targetHtml = "file:///C:/Users/User01/.gemini\antigravity/scratch/phone-price/index.html"

$edgeProcess = Start-Process -FilePath $edgePath -ArgumentList @(
    "--remote-debugging-port=$port",
    "--user-data-dir=$userDataDir",
    "--headless=new",
    "--window-size=1600,1200",
    $targetHtml
) -PassThru

Start-Sleep -Seconds 3

$versionUrl = "http://127.0.0.1:$port/json"
$targets = Invoke-RestMethod -Uri $versionUrl
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

    $buffer = New-Object byte[] 65536
    while ($true) {
        $recvSeg = New-Object System.ArraySegment[byte] -ArgumentList @(,$buffer)
        $res = $ws.ReceiveAsync($recvSeg, $cts.Token).Result
        $text = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $res.Count)
        $parsed = $text | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($parsed -and $parsed.id -eq $script:reqId) {
            if ($parsed.result -and $parsed.result.result -and $parsed.result.result.value) {
                return $parsed.result.result.value
            }
            return $parsed.result
        }
    }
}

Send-Cdp "Runtime.enable" | Out-Null
Send-Cdp "Page.enable" | Out-Null
Start-Sleep -Seconds 1

# 로그인
Send-Cdp "Runtime.evaluate" @{
    expression = @'
    (() => {
      localStorage.setItem('dankok_pin', '103105');
      localStorage.setItem('dankok_authed', 'true');
      if (typeof masterAuthSuccess === 'function') masterAuthSuccess('103105');
      switchTab('affiliate');
    })()
'@
} | Out-Null
Start-Sleep -Seconds 1

# 검증 스크립트 실행
$verifyScript = @'
(() => {
  const carriers = ['SKT', 'KT', 'LGU'];
  const cardResults = [];
  
  carriers.forEach(c => {
    (AFFILIATE_CARDS_BY_CARRIER[c] || []).forEach(card => {
      const hasDistinctEventUrl = card.eventUrl && card.eventUrl.trim() !== '' && card.eventUrl.trim() !== (card.applyUrl || '').trim();
      cardResults.push({
        id: card.id,
        name: card.cardName,
        company: card.cardCompany,
        carrier: c,
        applyUrl: card.applyUrl || card.phone,
        eventUrl: card.eventUrl || '',
        isDualQr: hasDistinctEventUrl,
        isIdenticalUrlBug: (card.eventUrl && card.applyUrl && card.eventUrl === card.applyUrl)
      });
    });
  });

  // Test live render for Shinhan T-light
  handleSelectAffiliateCard('skt_shinhan_tlight');
  const sheet = document.getElementById('cardA4Sheet');
  const hasEventQrInDom = !!sheet.querySelector('img[alt="이벤트 응모 QR"]');
  const eventLabelText = sheet.querySelector('.bg-amber-50 .text-amber-900')?.innerText || '';

  return {
    totalCards: cardResults.length,
    dualQrCount: cardResults.filter(r => r.isDualQr).length,
    singleQrCount: cardResults.filter(r => !r.isDualQr).length,
    identicalUrlBugCount: cardResults.filter(r => r.isIdenticalUrlBug).length,
    sampleShinhanTlight: cardResults.find(r => r.id === 'skt_shinhan_tlight'),
    sampleKbTlight: cardResults.find(r => r.id === 'skt_kb_tlight'),
    sampleSamsungTlight: cardResults.find(r => r.id === 'skt_samsung_tlight'),
    sampleWooriTlight: cardResults.find(r => r.id === 'skt_woori_tlight'),
    liveShinhanDomHasEventQr: hasEventQrInDom,
    liveShinhanEventLabel: eventLabelText
  };
})()
'@

$res = Send-Cdp "Runtime.evaluate" @{ expression = $verifyScript; returnByValue = $true }

Write-Host "=== 제휴카드 이벤트 QR 실증 검증 결과 ==="
Write-Host "총 카드 수: $($res.totalCards) (기대치: 41)"
Write-Host "듀얼 QR 탑재 카드 수: $($res.dualQrCount)"
Write-Host "단독 QR 카드 수: $($res.singleQrCount)"
Write-Host "동일 URL 중복 버그 카드 수: $($res.identicalUrlBugCount) (기대치: 0)"
Write-Host "`n[신한카드 T라이트 검증]"
Write-Host "   신청 URL: $($res.sampleShinhanTlight.applyUrl)"
Write-Host "   이벤트확인 URL: $($res.sampleShinhanTlight.eventUrl)"
Write-Host "   듀얼 QR 여부: $($res.sampleShinhanTlight.isDualQr)"
Write-Host "   실제 DOM 이벤트 QR 렌더링 확인: $($res.liveShinhanDomHasEventQr)"
Write-Host "   실제 DOM 이벤트 라벨: $($res.liveShinhanEventLabel)"

Write-Host "`n[KB국민카드 T라이트 검증]"
Write-Host "   신청 URL: $($res.sampleKbTlight.applyUrl)"
Write-Host "   이벤트확인 URL: $($res.sampleKbTlight.eventUrl)"
Write-Host "   듀얼 QR 여부: $($res.sampleKbTlight.isDualQr)"

Write-Host "`n[삼성카드 T라이트 검증]"
Write-Host "   신청 URL: $($res.sampleSamsungTlight.applyUrl)"
Write-Host "   이벤트확인 URL: $($res.sampleSamsungTlight.eventUrl)"
Write-Host "   듀얼 QR 여부: $($res.sampleSamsungTlight.isDualQr)"

Write-Host "`n[우리카드 T라이트 검증]"
Write-Host "   신청 URL: $($res.sampleWooriTlight.applyUrl)"
Write-Host "   이벤트확인 URL: $($res.sampleWooriTlight.eventUrl)"
Write-Host "   듀얼 QR 여부: $($res.sampleWooriTlight.isDualQr)"

$ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
Stop-Process -Id $edgeProcess.Id -Force
Write-Host "`n검증 완료!"
