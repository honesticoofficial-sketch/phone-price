# scripts/dump_kb_tlite_detail.ps1
$ErrorActionPreference = "Continue"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9230

Get-Process msedge -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*--remote-debugging-port=$port*" } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

$proc = Start-Process -FilePath $edgePath -ArgumentList "--remote-debugging-port=$port", "--headless=new", "--disable-gpu", "--disable-software-rasterizer", "--window-size=1600,1200", "about:blank" -PassThru
Start-Sleep -Seconds 2

try {
    $tabs = Invoke-RestMethod -Uri "http://localhost:$port/json/list"
    $pageTab = $tabs | Where-Object { $_.type -eq "page" } | Select-Object -First 1

    $wsUrl = $pageTab.webSocketDebuggerUrl
    $ws = [System.Net.WebSockets.ClientWebSocket]::new()
    $cts = [System.Threading.CancellationTokenSource]::new()
    $ws.ConnectAsync([System.Uri]::new($wsUrl), $cts.Token).Wait()

    $cmdId = 1
    function Send-CDP($method, $params = @{}) {
        $script:cmdId++
        $msg = @{
            id = $script:cmdId
            method = $method
            params = $params
        } | ConvertTo-Json -Depth 10 -Compress

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

    function Eval-JS($evalJs) {
        $res = Send-CDP "Runtime.evaluate" @{
            expression = $evalJs
            returnByValue = $true
            awaitPromise = $true
        }
        if ($res.result.exceptionDetails) {
            return "ERROR: " + ($res.result.exceptionDetails.exception.description | Out-String)
        }
        return $res.result.result.value
    }

    # KB국민카드 통신 페이지 접속
    Send-CDP "Page.navigate" @{ url = "https://card.kbcard.com/cards/products/credit-cards?benefit=telecom" } | Out-Null
    Start-Sleep -Seconds 5

    # T 라이트 KB국민카드의 자세히보기 클릭 및 페이지 이동 대기
    $clickRes = Eval-JS @"
    (async function() {
        const cards = Array.from(document.querySelectorAll('*')).filter(el => el.innerText && el.innerText.trim() === 'T 라이트 KB국민카드');
        if (cards.length > 0) {
            const cardEl = cards[0];
            const parent = cardEl.closest('li, div[class*="card"], article') || cardEl.parentElement.parentElement;
            const detailBtn = Array.from(parent.querySelectorAll('a, button')).find(b => b.innerText && b.innerText.includes('자세히보기'));
            if (detailBtn) {
                detailBtn.click();
                return { clicked: true, href: detailBtn.href || 'button' };
            }
        }
        return { clicked: false };
    })()
"@
    Write-Host "클릭 결과: $($clickRes | ConvertTo-Json -Compress)"
    Start-Sleep -Seconds 5

    # 이동된 상세페이지 또는 팝업 내용 덤프
    $detailDump = Eval-JS @"
    (async function() {
        // 모든 아코디언 / 탭 클릭
        const tabs = Array.from(document.querySelectorAll('button, a, [role="tab"], dt, summary')).filter(el => {
            const t = el.innerText || '';
            return t.includes('혜택') || t.includes('상세') || t.includes('할인') || t.includes('유의사항') || t.includes('라이트할부') || t.includes('프로모션');
        });
        for (let t of tabs.slice(0, 15)) {
            try { t.click(); } catch(e) {}
        }
        await new Promise(r => setTimeout(r, 1500));

        const text = document.body.innerText;
        return {
            title: document.title,
            url: window.location.href,
            textLength: text.length,
            textSample: text.substring(0, 3000),
            hasPromo: text.includes('프로모션'),
            has17000Won: text.includes('17,000') || text.includes('17000'),
            has25000Won: text.includes('25,000') || text.includes('25000'),
            has8000Won: text.includes('8,000') || text.includes('8000')
        };
    })()
"@
    Write-Host "상세페이지 덤프 결과:"
    Write-Host ($detailDump | ConvertTo-Json -Depth 5)
    Set-Content -Path "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\kb_tlite_dump.txt" -Value $detailDump.textSample -Encoding UTF8

} finally {
    if ($ws -and $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
    }
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}
