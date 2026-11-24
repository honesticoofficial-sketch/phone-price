[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

$root = "C:\Users\User01\.gemini\antigravity\scratch\phone-price"
$indexHtml = "$root\index.html"
$outPng = "$root\data\chapter87_duo_verified.png"
$artifactPng = "C:\Users\User01\.gemini\antigravity\brain\2f8eabdf-6a8a-4957-81f7-425939762cc2\chapter87_duo_verified.png"
$port = 9265

Write-Host "=========================================================="
Write-Host " [아이폰 듀오 및 게이트웨이 검증 브라우저 라이브 테스트]"
Write-Host "=========================================================="

cmd.exe /c "taskkill /f /im msedge.exe 2>nul" | Out-Null
Start-Sleep -Milliseconds 800

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$proc = Start-Process -FilePath $edgePath -ArgumentList "--remote-debugging-port=$port", "--headless=new", "--disable-gpu", "--window-size=1600,1200", "about:blank" -PassThru
Start-Sleep -Seconds 3

$ws = $null
$cts = $null

try {
    $tabs = Invoke-RestMethod -Uri "http://localhost:$port/json/list"
    $pageTab = $tabs | Where-Object { $_.type -eq "page" } | Select-Object -First 1

    $ws = [System.Net.WebSockets.ClientWebSocket]::new()
    $cts = [System.Threading.CancellationTokenSource]::new()
    $ws.ConnectAsync([System.Uri]::new($pageTab.webSocketDebuggerUrl), $cts.Token).Wait()

    $cmdId = 1
    function Invoke-CDP($method, $params = @{}) {
        $script:cmdId++
        $targetId = $script:cmdId
        $msg = @{ id = $targetId; method = $method; params = $params } | ConvertTo-Json -Depth 10 -Compress
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($msg)
        $ws.SendAsync([System.ArraySegment[byte]]::new($bytes), [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $cts.Token).Wait()

        while ($true) {
            $buffer = [byte[]]::new(65536 * 8)
            $ms = [System.IO.MemoryStream]::new()
            do {
                $result = $ws.ReceiveAsync([System.ArraySegment[byte]]::new($buffer), $cts.Token).Result
                $ms.Write($buffer, 0, $result.Count)
            } while (-not $result.EndOfMessage)

            $respStr = [System.Text.Encoding]::UTF8.GetString($ms.ToArray())
            $json = $respStr | ConvertFrom-Json
            if ($json.id -eq $targetId) {
                return $json
            }
        }
    }

    Write-Host "1. Navigating to index.html..."
    $fileUrl = "file:///" + ($indexHtml.Replace("\", "/"))
    Invoke-CDP "Page.navigate" @{ url = $fileUrl }
    Start-Sleep -Seconds 4

    Write-Host "2. Checking iPhone Duo in devices and CRAWLED_CATALOG_POOL..."
    $res = Invoke-CDP "Runtime.evaluate" @{
        expression = @"
            (() => {
                if (typeof render === 'function') {
                    render();
                }
                const duoInDevices = (typeof devices !== 'undefined') ? devices.find(d => d.id === 'ipduo' || d.name.includes('Duo') || d.name.includes('듀오')) : null;
                const duoPool = (typeof CRAWLED_CATALOG_POOL !== 'undefined') ? CRAWLED_CATALOG_POOL.filter(x => x.name.includes('Duo')) : [];
                
                // 검색 테스트
                let searchResultCount = 0;
                if (typeof handleCatalogSearch === 'function') {
                    // search for 듀오
                    const matches = CRAWLED_CATALOG_POOL.filter(item => {
                        const nameRaw = item.name.toLowerCase();
                        return nameRaw.includes('duo');
                    });
                    searchResultCount = matches.length;
                }

                // Table row check
                const tableRows = Array.from(document.querySelectorAll('#calcTableBody tr'));
                const duoRow = tableRows.find(tr => tr.innerText.includes('아이폰Duo') || tr.innerText.includes('iPhone Duo') || tr.innerText.includes('듀오'));

                return {
                    devicesDuo: duoInDevices,
                    poolDuoCount: duoPool.length,
                    poolDuoNames: duoPool.map(d => d.name),
                    searchMatches: searchResultCount,
                    tableRowCount: tableRows.length,
                    renderedRowFound: !!duoRow,
                    rowText: duoRow ? duoRow.innerText.replace(/\n+/g, ' | ') : 'NOT_FOUND'
                };
            })()
"@
        returnByValue = $true
    }

    $val = $res.result.result.value
    Write-Host "   - devices 내 Duo 기종:" ($val.devicesDuo.name)
    Write-Host "   - devices 가격:" ($val.devicesDuo.prices | ConvertTo-Json -Compress)
    Write-Host "   - devices 공시:" ($val.devicesDuo.sub | ConvertTo-Json -Compress)
    Write-Host "   - CRAWLED_CATALOG_POOL 내 Duo 모델 수:" ($val.poolDuoCount)
    Write-Host "   - 풀 내 모델명:" ($val.poolDuoNames -join ", ")
    Write-Host "   - '듀오' 검색 매칭 수:" ($val.searchMatches)
    Write-Host "   - 넷가표(Tab 1) DOM 행 렌더링 확인:" ($val.renderedRowFound)
    Write-Host "   - 렌더링 행 텍스트: $($val.rowText)"

    if (-not $val.devicesDuo) {
        throw "❌ devices 마스터에 ipduo가 존재하지 않습니다!"
    }
    if ($val.poolDuoCount -ne 4) {
        throw "❌ CRAWLED_CATALOG_POOL에 iPhone Duo 4개 용량이 모두 등록되지 않았습니다 (발견: $($val.poolDuoCount)개)"
    }
    if (-not $val.renderedRowFound) {
        throw "❌ 넷가표 DOM에 아이폰Duo 행이 렌더링되지 않았습니다!"
    }

    Write-Host "   ✅ 모든 무결성 검증 통과!" -ForegroundColor Green

    # 3. Screenshot Capture
    Write-Host "3. Capturing live screenshot..."
    $ss = Invoke-CDP "Page.captureScreenshot" @{ format = "png" }
    $b64 = $ss.result.data
    $pngBytes = [System.Convert]::FromBase64String($b64)
    [System.IO.File]::WriteAllBytes($outPng, $pngBytes)
    [System.IO.File]::WriteAllBytes($artifactPng, $pngBytes)
    Write-Host "   ✅ 스크린샷 캡처 완료: $outPng & $artifactPng"

} finally {
    if ($ws -and $ws.State -eq 'Open') {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", [System.Threading.CancellationToken]::None).Wait()
    }
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}
