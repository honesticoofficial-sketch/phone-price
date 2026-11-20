# scripts/check_card_detail_promo.ps1
$ErrorActionPreference = "Continue"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9226

# Kill previous edge on 9226
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

    function Navigate-Page($url, $waitSec = 6) {
        Send-CDP "Page.navigate" @{ url = $url } | Out-Null
        Start-Sleep -Seconds $waitSec
    }

    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "🔍 카드사 공식 상세페이지 내 프로모션 할인 표기 여부 정밀 전수 확인" -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan

    # 1. 삼성카드 T PREMIUM 상세페이지
    Write-Host "`n[1. 삼성카드 T PREMIUM 상세페이지 분석]"
    Navigate-Page "https://www.samsungcard.com/home/card/cardinfo/PGHPPCCCardCardinfoDetails001?code=AAP1869" 6
    $samsungDetailJs = @"
    (async function() {
        // 모든 아코디언 / 상세보기 / 탭 버튼 클릭하여 전체 펼치기
        const expandBtns = Array.from(document.querySelectorAll('button, a')).filter(el => {
            const t = el.innerText || '';
            return t.includes('상세') || t.includes('더보기') || t.includes('펼치기') || t.includes('유의사항') || t.includes('프로모션') || t.includes('이벤트');
        });
        for (let b of expandBtns.slice(0, 10)) {
            try { b.click(); } catch(e) {}
        }
        await new Promise(r => setTimeout(r, 1000));

        const bodyText = document.body.innerText;
        // 프로모션 관련 문장 추출
        const lines = bodyText.split('\n').map(l => l.trim()).filter(l => l.length > 0);
        const promoLines = lines.filter(l => 
            l.includes('프로모션') || l.includes('추가할인') || l.includes('추가 할인') || 
            l.includes('35,000') || l.includes('35000') || l.includes('10,000') || l.includes('10000') ||
            l.includes('캐시백') || l.includes('무실적') || l.includes('행사')
        );

        return {
            title: document.title,
            hasPromoWord: bodyText.includes('프로모션'),
            has35000Won: bodyText.includes('35,000') || bodyText.includes('35000'),
            has25000Won: bodyText.includes('25,000') || bodyText.includes('25000'),
            promoLines: Array.from(new Set(promoLines)).slice(0, 15)
        };
    })()
"@
    $samsungRes = Eval-JS $samsungDetailJs
    Write-Host "삼성카드 상세 결과: $($samsungRes | ConvertTo-Json -Depth 5)"

    # 2. 현대카드 통신할인형2.0 상세페이지
    Write-Host "`n[2. 현대카드 M3 통신할인형2.0 상세페이지 분석]"
    Navigate-Page "https://www.hyundaicard.com/cpc/cr/CPCCR0201_01.hc?cardWcd=MSKTE3TP" 6
    $hyundaiDetailJs = @"
    (async function() {
        const expandBtns = Array.from(document.querySelectorAll('button, a')).filter(el => {
            const t = el.innerText || '';
            return t.includes('상세') || t.includes('더보기') || t.includes('펼치기') || t.includes('유의사항') || t.includes('프로모션') || t.includes('이벤트');
        });
        for (let b of expandBtns.slice(0, 10)) {
            try { b.click(); } catch(e) {}
        }
        await new Promise(r => setTimeout(r, 1000));

        const bodyText = document.body.innerText;
        const lines = bodyText.split('\n').map(l => l.trim()).filter(l => l.length > 0);
        const promoLines = lines.filter(l => 
            l.includes('프로모션') || l.includes('추가할인') || l.includes('추가 할인') || 
            l.includes('33,000') || l.includes('33000') || l.includes('18,000') || l.includes('18000') ||
            l.includes('쿠폰팩') || l.includes('무실적')
        );

        return {
            title: document.title,
            hasPromoWord: bodyText.includes('프로모션'),
            has33000Won: bodyText.includes('33,000') || bodyText.includes('33000'),
            has15000Won: bodyText.includes('15,000') || bodyText.includes('15000'),
            promoLines: Array.from(new Set(promoLines)).slice(0, 15)
        };
    })()
"@
    $hyundaiRes = Eval-JS $hyundaiDetailJs
    Write-Host "현대카드 상세 결과: $($hyundaiRes | ConvertTo-Json -Depth 5)"

    # 3. KB국민카드 통신 카드 상세 진입 및 확인
    Write-Host "`n[3. KB국민카드 T-economy / T라이트 상세 진입 및 분석]"
    Navigate-Page "https://card.kbcard.com/cards/products/credit-cards?benefit=telecom" 6
    $kbDetailJs = @"
    (async function() {
        // T-economy 또는 T라이트의 '자세히보기' 또는 카드 링크 클릭
        const allLinks = Array.from(document.querySelectorAll('a, button'));
        const tecoCard = allLinks.find(el => el.innerText && el.innerText.includes('T-economy'));
        let clicked = false;
        if (tecoCard) {
            // 그 근처의 자세히보기 찾기
            const container = tecoCard.closest('li, div, [class*=\"card\"]') || tecoCard;
            const detailBtn = container.querySelector('a[href*=\"detail\"], button, a');
            if (detailBtn) {
                detailBtn.click();
                clicked = true;
                await new Promise(r => setTimeout(r, 3000));
            }
        }

        const bodyText = document.body.innerText;
        const lines = bodyText.split('\n').map(l => l.trim()).filter(l => l.length > 0);
        const promoLines = lines.filter(l => 
            l.includes('프로모션') || l.includes('추가할인') || l.includes('추가 할인') || 
            l.includes('25,000') || l.includes('17,000') || l.includes('캐시백') || l.includes('무실적') || l.includes('아이폰')
        );

        return {
            title: document.title,
            clicked: clicked,
            hasPromoWord: bodyText.includes('프로모션'),
            promoLines: Array.from(new Set(promoLines)).slice(0, 15)
        };
    })()
"@
    $kbRes = Eval-JS $kbDetailJs
    Write-Host "KB국민카드 상세 결과: $($kbRes | ConvertTo-Json -Depth 5)"

    # 4. 신한카드 T라이트 상세페이지
    Write-Host "`n[4. 신한카드 T라이트 상세 분석]"
    Navigate-Page "https://www.shinhancard.com/pconts/html/card/coalition/CONFM70007/CONFM70007R01.html?crustMenuId=ms592" 6
    $shinhanDetailJs = @"
    (async function() {
        // 더보기 10회
        for(let i=0; i<10; i++) {
            const btns = Array.from(document.querySelectorAll('button, a')).filter(el => el.innerText && el.innerText.includes('더보기'));
            if(btns.length > 0) {
                btns[0].click();
                await new Promise(r => setTimeout(r, 600));
            } else { break; }
        }
        // SKT T라이트 카드 클릭
        const allElements = Array.from(document.querySelectorAll('a, strong, span, button'));
        const sktCard = allElements.find(el => el.innerText && el.innerText.includes('SKT T라이트'));
        let clicked = false;
        if (sktCard) {
            const clickTarget = sktCard.closest('a') || sktCard;
            clickTarget.click();
            clicked = true;
            await new Promise(r => setTimeout(r, 3000));
        }

        const bodyText = document.body.innerText;
        const lines = bodyText.split('\n').map(l => l.trim()).filter(l => l.length > 0);
        const promoLines = lines.filter(l => 
            l.includes('프로모션') || l.includes('추가할인') || l.includes('추가 할인') || 
            l.includes('22,000') || l.includes('12,000') || l.includes('캐시백') || l.includes('무실적')
        );

        return {
            title: document.title,
            clicked: clicked,
            hasPromoWord: bodyText.includes('프로모션'),
            promoLines: Array.from(new Set(promoLines)).slice(0, 15)
        };
    })()
"@
    $shinhanRes = Eval-JS $shinhanDetailJs
    Write-Host "신한카드 상세 결과: $($shinhanRes | ConvertTo-Json -Depth 5)"

} finally {
    if ($ws -and $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
    }
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}
