# scripts/deep_crawl_test_part2.ps1
$ErrorActionPreference = "Continue"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9225

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
            return "ERROR: " + $res.result.exceptionDetails.exception.description
        }
        return $res.result.result.value
    }

    function Navigate-Page($url, $waitSec = 6) {
        Send-CDP "Page.navigate" @{ url = $url } | Out-Null
        Start-Sleep -Seconds $waitSec
    }

    # 1. 우리카드 탭 클릭
    Write-Host "`n--- [우리카드] 통신·금융 탭 클릭 테스트 ---"
    Navigate-Page "https://pc.wooricard.com/dcpc/yh1/crd/crd02/H1CRD202S00.do?ctgrCd=S000017&hiPrdCtgrCd=M110020" 5
    $wooriJs = @"
    (async function() {
        // 통신·금융 버튼 찾아서 클릭
        const allBtns = Array.from(document.querySelectorAll('a, button, li'));
        const targetBtn = allBtns.find(el => el.innerText && el.innerText.trim() === '통신·금융');
        if (targetBtn) {
            targetBtn.click();
            await new Promise(r => setTimeout(r, 2000));
        }
        const text = document.body.innerText;
        const cardTitles = Array.from(document.querySelectorAll('h3, h4, strong, [class*=\"tit\"], [class*=\"name\"]'))
            .map(el => el.innerText.trim())
            .filter(t => t.includes('SK') || t.includes('T라이트') || t.includes('KT') || t.includes('LG'));
        return {
            targetBtnFound: !!targetBtn,
            foundTitles: Array.from(new Set(cardTitles)),
            hasTLite: text.includes('T라이트') || text.includes('T 라이트')
        };
    })()
"@
    $wooriRes = Eval-JS $wooriJs
    Write-Host "우리카드 결과: $($wooriRes | ConvertTo-Json -Compress)"

    # 2. 롯데카드 탭 클릭
    Write-Host "`n--- [롯데카드] 통신/렌탈 탭 클릭 및 카드 목록 테스트 ---"
    Navigate-Page "https://www.lottecard.co.kr/app/LPCDADA_V100.lc?typeGubun=cco" 5
    $lotteJs = @"
    (async function() {
        const telecomTab = Array.from(document.querySelectorAll('a, button, li')).find(el => el.innerText && el.innerText.includes('통신'));
        if (telecomTab) {
            telecomTab.click();
            await new Promise(r => setTimeout(r, 2000));
        }
        const cardElements = Array.from(document.querySelectorAll('[class*=\"card\"], [class*=\"tit\"], [class*=\"name\"], h3, h4'))
            .map(el => el.innerText.trim())
            .filter(t => t.includes('TELLO') || t.includes('T 라이트') || t.includes('SKT') || t.includes('텔로'));
        return {
            telecomTabFound: !!telecomTab,
            foundCards: Array.from(new Set(cardElements)).slice(0, 10),
            hasTLite: document.body.innerText.includes('T 라이트') || document.body.innerText.includes('T라이트'),
            hasTello: document.body.innerText.includes('TELLO') || document.body.innerText.includes('텔로')
        };
    })()
"@
    $lotteRes = Eval-JS $lotteJs
    Write-Host "롯데카드 결과: $($lotteRes | ConvertTo-Json -Compress)"

    # 3. 농협카드 검색 상세
    Write-Host "`n--- [농협카드] 상세 검색 테스트 ---"
    Navigate-Page "https://nhpay.nonghyup.com/cd/CD101000F" 6
    $nhJs = @"
    (async function() {
        // NH 페이지 내부 input 요소들 분석
        const inputs = Array.from(document.querySelectorAll('input')).map(i => ({ id: i.id, name: i.name, placeholder: i.placeholder, class: i.className }));
        // 검색 필드 찾기
        const searchInput = document.querySelector('#searchKeyword, input[type="search"], input[placeholder*="카드명"], input[placeholder*="검색"]');
        let cardList = [];
        if (searchInput) {
            searchInput.value = 'SKT';
            searchInput.dispatchEvent(new Event('input', { bubbles: true }));
            const btn = document.querySelector('button[class*="search"], .btn_search, [onclick*="search"]');
            if (btn) btn.click();
            await new Promise(r => setTimeout(r, 2500));
            cardList = Array.from(document.querySelectorAll('*'))
                .filter(el => el.children.length === 0 && el.innerText && (el.innerText.includes('SKT') || el.innerText.includes('T라이트')))
                .map(el => el.innerText.trim());
        }
        return {
            inputs: inputs,
            searchInputFound: !!searchInput,
            foundCards: Array.from(new Set(cardList))
        };
    })()
"@
    $nhRes = Eval-JS $nhJs
    Write-Host "농협카드 결과: $($nhRes | ConvertTo-Json -Compress)"

    # 4. 하나카드 URL 및 통신/교통 탐색
    Write-Host "`n--- [하나카드] 통신 카드 탐색 ---"
    Navigate-Page "https://www.hanacard.co.kr/OPIP10000000N.web" 6
    $hanaJs = @"
    (async function() {
        return {
            title: document.title,
            bodySnippet: document.body.innerText.substring(0, 300),
            hasTDown: document.body.innerText.includes('T다운') || document.body.innerText.includes('T-Down') || document.body.innerText.includes('SKT')
        };
    })()
"@
    $hanaRes = Eval-JS $hanaJs
    Write-Host "하나카드 결과: $($hanaRes | ConvertTo-Json -Compress)"

} finally {
    if ($ws -and $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
    }
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}
