# scripts/test_crawl_skt.ps1
$ErrorActionPreference = "Continue"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9223

# Kill any previous test edge on 9223
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

    function Navigate-And-Eval($url, $evalJs, $waitSec = 5) {
        Send-CDP "Page.navigate" @{ url = $url } | Out-Null
        Start-Sleep -Seconds $waitSec
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

    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "🔍 8대 카드사 SKT 제휴카드 크롤링 실시간 대조 테스트 시작" -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan

    $targets = @(
        @{
            name = "KB국민카드"
            url = "https://card.kbcard.com/cards/products/credit-cards?benefit=telecom"
            expectedCards = @("T라이트", "T이코노미")
            js = @"
            (function() {
                const text = document.body.innerText;
                const links = Array.from(document.querySelectorAll('a, button, [class*=\"card\"], [class*=\"tit\"]'))
                    .map(el => el.innerText.trim())
                    .filter(t => t.length > 0 && (t.includes('T') || t.includes('SK') || t.includes('라이트') || t.includes('이코노미')));
                return {
                    title: document.title,
                    foundSnippets: Array.from(new Set(links)).slice(0, 10),
                    hasTLite: text.includes('T라이트') || text.includes('T 라이트'),
                    hasTEconomy: text.includes('이코노미') || text.includes('T-economy')
                };
            })()
"@
        },
        @{
            name = "삼성카드"
            url = "https://www.samsungcard.com/home/card/cardinfo/PGHPPDCCardCardinfoRecommendPC001?webViewFirstPage=true&tabIndex=7"
            expectedCards = @("T프리미엄", "T라이트", "T나는혜택")
            js = @"
            (function() {
                const text = document.body.innerText;
                return {
                    title: document.title,
                    hasTPremium: text.includes('T 프리미엄') || text.includes('T PREMIUM') || text.includes('T프리미엄'),
                    hasTLite: text.includes('T 라이트') || text.includes('T라이트'),
                    hasTBenefit: text.includes('T나는혜택') || text.includes('T나는 혜택')
                };
            })()
"@
        },
        @{
            name = "신한카드"
            url = "https://www.shinhancard.com/pconts/html/card/coalition/CONFM70007/CONFM70007R01.html?crustMenuId=ms592"
            expectedCards = @("T라이트", "파인애플", "T&LIFE")
            js = @"
            (function() {
                const text = document.body.innerText;
                return {
                    title: document.title,
                    hasTLite: text.includes('T라이트') || text.includes('T 라이트'),
                    hasPineapple: text.includes('파인애플'),
                    hasTLife: text.includes('T&LIFE') || text.includes('T & LIFE') || text.includes('티앤라이프')
                };
            })()
"@
        },
        @{
            name = "롯데카드"
            url = "https://www.lottecard.co.kr/app/LPCDADA_V100.lc?typeGubun=cco"
            expectedCards = @("T 라이트", "TELLO NE")
            js = @"
            (function() {
                const text = document.body.innerText;
                return {
                    title: document.title,
                    hasTLite: text.includes('T 라이트') || text.includes('T라이트'),
                    hasTello: text.includes('TELLO') || text.includes('텔로')
                };
            })()
"@
        },
        @{
            name = "현대카드"
            url = "https://www.hyundaicard.com/cpc/ma/CPCMA0101_01.hc?cardflag=J"
            expectedCards = @("M3 T라이트2", "M3 통신할인형2.0")
            js = @"
            (function() {
                const text = document.body.innerText;
                return {
                    title: document.title,
                    hasM3TLite: text.includes('M3') && (text.includes('T라이트') || text.includes('T 라이트')),
                    hasM3Telecom: text.includes('M3') && text.includes('통신')
                };
            })()
"@
        },
        @{
            name = "우리카드"
            url = "https://pc.wooricard.com/dcpc/yh1/crd/crd02/H1CRD202S00.do?ctgrCd=S000017&hiPrdCtgrCd=M110020"
            expectedCards = @("T라이트")
            js = @"
            (function() {
                const text = document.body.innerText;
                return {
                    title: document.title,
                    hasTLite: text.includes('T라이트') || text.includes('T 라이트') || text.includes('SKT')
                };
            })()
"@
        }
    )

    $results = @()
    foreach ($tgt in $targets) {
        Write-Host "`n[$($tgt.name)] 접속 및 데이터 탐색 중... ($($tgt.url))"
        $eval = Navigate-And-Eval $tgt.url $tgt.js 5
        Write-Host "결과: $($eval | ConvertTo-Json -Compress)"
        $results += @{
            name = $tgt.name
            eval = $eval
        }
    }

} finally {
    if ($ws -and $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
    }
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}
