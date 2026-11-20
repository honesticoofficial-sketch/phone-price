# scripts/deep_crawl_test.ps1
$ErrorActionPreference = "Continue"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9224

# Kill previous edge on 9224
Get-Process msedge -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*--remote-debugging-port=$port*" } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

$proc = Start-Process -FilePath $edgePath -ArgumentList "--remote-debugging-port=$port", "--headless=new", "--disable-gpu", "--disable-software-rasterizer", "--window-size=1600,1200", "about:blank" -PassThru
Start-Sleep -Seconds 2

try {
    $tabs = Invoke-RestMethod -Uri "http://localhost:$port/json/list"
    $pageTab = $tabs | Where-Object { $_.type -eq "page" } | Select-Object -First 1

    if (-not $pageTab) {
        throw "Could not find Edge page tab!"
    }

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

    function Navigate-Page($url, $waitSec = 5) {
        Send-CDP "Page.navigate" @{ url = $url } | Out-Null
        Start-Sleep -Seconds $waitSec
    }

    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "🔍 카드사별 상세 탐색 시작" -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan

    # 1. 신한카드 상세 분석
    Write-Host "`n--- [1. 신한카드] 더보기 버튼 반복 클릭 후 카드 검색 ---"
    Navigate-Page "https://www.shinhancard.com/pconts/html/card/coalition/CONFM70007/CONFM70007R01.html?crustMenuId=ms592" 6
    
    $shMoreJs = @"
    (async function() {
        let clicks = 0;
        // 더보기 버튼 찾기
        for(let i=0; i<10; i++) {
            const btns = Array.from(document.querySelectorAll('button, a')).filter(el => el.innerText && el.innerText.includes('더보기'));
            if(btns.length > 0) {
                btns[0].click();
                clicks++;
                await new Promise(r => setTimeout(r, 1000));
            } else {
                break;
            }
        }
        const text = document.body.innerText;
        const skCards = Array.from(document.querySelectorAll('*'))
            .filter(el => el.children.length === 0 && el.innerText && (el.innerText.includes('SK') || el.innerText.includes('T라이트') || el.innerText.includes('파인애플') || el.innerText.includes('T&LIFE')))
            .map(el => el.innerText.trim());
        return {
            title: document.title,
            clicks: clicks,
            foundSKCards: Array.from(new Set(skCards))
        };
    })()
"@
    $shRes = Eval-JS $shMoreJs
    Write-Host "신한카드 결과: $($shRes | ConvertTo-Json -Compress)"

    # 2. 롯데카드 상세 분석
    Write-Host "`n--- [2. 롯데카드] 통신 탭/필터 클릭 후 카드 검색 ---"
    Navigate-Page "https://www.lottecard.co.kr/app/LPCDADA_V100.lc?typeGubun=cco" 6
    $lotteJs = @"
    (async function() {
        // 탭 버튼 찾기 (통신 또는 통신/렌탈)
        const tabs = Array.from(document.querySelectorAll('button, a, [role="tab"]')).map(el => el.innerText.trim());
        const telecomBtn = Array.from(document.querySelectorAll('button, a, [role="tab"]')).find(el => el.innerText && (el.innerText.includes('통신') || el.innerText.includes('렌탈')));
        if (telecomBtn) {
            telecomBtn.click();
            await new Promise(r => setTimeout(r, 2000));
        }
        const text = document.body.innerText;
        const cards = Array.from(document.querySelectorAll('*'))
            .filter(el => el.children.length === 0 && el.innerText && (el.innerText.includes('TELLO') || el.innerText.includes('T 라이트') || el.innerText.includes('SK')))
            .map(el => el.innerText.trim());
        return {
            title: document.title,
            allTabs: tabs.filter(t => t.length > 0).slice(0, 15),
            telecomBtnFound: !!telecomBtn,
            foundCards: Array.from(new Set(cards))
        };
    })()
"@
    $lotteRes = Eval-JS $lotteJs
    Write-Host "롯데카드 결과: $($lotteRes | ConvertTo-Json -Compress)"

    # 3. 현대카드 상세 분석
    Write-Host "`n--- [3. 현대카드] 제휴 통신 탭 클릭 후 카드 검색 ---"
    Navigate-Page "https://www.hyundaicard.com/cpc/ma/CPCMA0101_01.hc?cardflag=J" 6
    $hyundaiJs = @"
    (async function() {
        const tabs = Array.from(document.querySelectorAll('button, a, li, span')).filter(el => el.innerText && el.innerText.includes('통신')).map(el => ({ text: el.innerText.trim(), tag: el.tagName }));
        const telecomTab = Array.from(document.querySelectorAll('a, button')).find(el => el.innerText && el.innerText.trim() === '통신');
        if (telecomTab) {
            telecomTab.click();
            await new Promise(r => setTimeout(r, 2000));
        }
        const cards = Array.from(document.querySelectorAll('*'))
            .filter(el => el.children.length === 0 && el.innerText && (el.innerText.includes('SKT') || el.innerText.includes('T라이트') || el.innerText.includes('M3')))
            .map(el => el.innerText.trim());
        return {
            title: document.title,
            telecomTabFound: !!telecomTab,
            foundCards: Array.from(new Set(cards)).slice(0, 15)
        };
    })()
"@
    $hyundaiRes = Eval-JS $hyundaiJs
    Write-Host "현대카드 결과: $($hyundaiRes | ConvertTo-Json -Compress)"

    # 4. 우리카드 상세 분석
    Write-Host "`n--- [4. 우리카드] 통신금융 상세 검색 ---"
    Navigate-Page "https://pc.wooricard.com/dcpc/yh1/crd/crd02/H1CRD202S00.do?ctgrCd=S000017&hiPrdCtgrCd=M110020" 6
    $wooriJs = @"
    (function() {
        const text = document.body.innerText;
        const cards = Array.from(document.querySelectorAll('*'))
            .filter(el => el.children.length === 0 && el.innerText && (el.innerText.includes('T라이트') || el.innerText.includes('SK') || el.innerText.includes('SKT')))
            .map(el => el.innerText.trim());
        return {
            title: document.title,
            bodySnippet: text.substring(0, 300),
            foundCards: Array.from(new Set(cards))
        };
    })()
"@
    $wooriRes = Eval-JS $wooriJs
    Write-Host "우리카드 결과: $($wooriRes | ConvertTo-Json -Compress)"

    # 5. 농협카드 검색 테스트
    Write-Host "`n--- [5. 농협카드] SKT 검색 테스트 ---"
    Navigate-Page "https://nhpay.nonghyup.com/cd/CD101000F" 6
    $nhJs = @"
    (async function() {
        // 검색창 찾기
        const inputs = Array.from(document.querySelectorAll('input[type="text"], input[type="search"]'));
        let searched = false;
        if(inputs.length > 0) {
            inputs[0].value = 'SKT';
            inputs[0].dispatchEvent(new Event('input', { bubbles: true }));
            inputs[0].dispatchEvent(new Event('change', { bubbles: true }));
            // 검색 버튼 또는 Enter
            const searchBtn = Array.from(document.querySelectorAll('button, a')).find(el => el.innerText && el.innerText.includes('검색'));
            if(searchBtn) {
                searchBtn.click();
            } else {
                inputs[0].dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', code: 'Enter', bubbles: true }));
            }
            searched = true;
            await new Promise(r => setTimeout(r, 2000));
        }
        const text = document.body.innerText;
        const cards = Array.from(document.querySelectorAll('*'))
            .filter(el => el.children.length === 0 && el.innerText && (el.innerText.includes('T라이트') || el.innerText.includes('SKT') || el.innerText.includes('SK')))
            .map(el => el.innerText.trim());
        return {
            title: document.title,
            searched: searched,
            foundCards: Array.from(new Set(cards)).slice(0, 10)
        };
    })()
"@
    $nhRes = Eval-JS $nhJs
    Write-Host "농협카드 결과: $($nhRes | ConvertTo-Json -Compress)"

    # 6. 하나카드 통신/교통 테스트
    Write-Host "`n--- [6. 하나카드] 통신/교통 카테고리 ---"
    Navigate-Page "https://www.hanacard.co.kr/" 6
    $hanaJs = @"
    (async function() {
        const text = document.body.innerText;
        return {
            title: document.title,
            hasTelecom: text.includes('통신'),
            bodySnippet: text.substring(0, 300)
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
