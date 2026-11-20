# scripts/dump_kb_direct_detail.ps1
$ErrorActionPreference = "Continue"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9235

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

    # T 라이트 KB국민카드 상세 URL 직접 접속
    Send-CDP "Page.navigate" @{ url = "https://card.kbcard.com/CRD/DVIEW/HCAMCXPRICAC0076?mainCC=a&cooperationcode=01506" } | Out-Null
    Start-Sleep -Seconds 6

    $dump = Eval-JS @"
    (async function() {
        // 모든 아코디언 / 탭 클릭하여 열기
        const tabs = Array.from(document.querySelectorAll('button, a, [role="tab"], dt, summary, [class*="tab"]')).filter(el => {
            const t = el.innerText || '';
            return t.includes('혜택') || t.includes('상세') || t.includes('할인') || t.includes('유의사항') || t.includes('라이트할부') || t.includes('프로모션');
        });
        for (let t of tabs.slice(0, 20)) {
            try { t.click(); } catch(e) {}
        }
        await new Promise(r => setTimeout(r, 2000));

        const text = document.body.innerText;
        return {
            title: document.title,
            textLen: text.length,
            hasPromo: text.includes('프로모션'),
            has17000: text.includes('17,000') || text.includes('17000'),
            has25000: text.includes('25,000') || text.includes('25000'),
            has8000: text.includes('8,000') || text.includes('8000'),
            hasIphone: text.includes('아이폰'),
            textSnippet: text.substring(0, 4000)
        };
    })()
"@
    Write-Host "KB T라이트 상세 수집 결과:"
    Write-Host "Title: $($dump.title)"
    Write-Host "Text Length: $($dump.textLen)"
    Write-Host "Has Promo: $($dump.hasPromo)"
    Write-Host "Has 17,000 (추가할인): $($dump.has17000)"
    Write-Host "Has 25,000 (프로모션 총할인): $($dump.has25000)"
    Write-Host "Has 8,000 (기본할인): $($dump.has8000)"
    Write-Host "Has iPhone: $($dump.hasIphone)"
    Set-Content -Path "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\kb_tlite_dump.txt" -Value $dump.textSnippet -Encoding UTF8

} finally {
    if ($ws -and $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
    }
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}
