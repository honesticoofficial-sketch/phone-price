[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

$root = "C:\Users\User01\.gemini\antigravity\scratch\phone-price"
$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9285

Write-Host "=========================================================="
Write-Host " [통신 3사(SKT / KT / LGU+) 플래그십 전용 공시지원금 & 출고가 크롤러]"
Write-Host " - 기준 요금제: SK 109 요금제 / KT 110 요금제 / LG 105 요금제"
Write-Host " - 수집 대상: S시리즈, 아이폰, 폴더블류, FE류, 엣지류 (A시리즈 제외)"
Write-Host "=========================================================="

# 플래그십 전용 필터링 함수 (A시리즈, 워치, 태블릿, 샤오미, 모토로라 제외)
function IsTargetModel($name) {
    if (-not $name) { return $false }
    if ($name -match '워치|Watch|버즈|Buds|태블릿|Tab|패드|클래식 폴더|샤오미|레드미|홍미|모토|moto') { return $false }
    if ($name -match '갤럭시 A|Galaxy A|A\d{2}\s|A\d{2}$|SM-A\d+|퀀텀|와이드|점프|버디|키즈폰') { return $false }
    if ($name -match 'iPhone|아이폰|S\d+|갤럭시 S|Galaxy S|Fold|Flip|폴드|플립|FE|엣지|Edge|Duo|Air') { return $true }
    return $false
}

$crawledData = @{
    crawlTimestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
    summary = @{}
    skt = @()
    kt = @()
    lgu = @()
}

# -------------------------------------------------------------
# 1. SKT 크롤링 (https://shop.tworld.co.kr/notice)
# -------------------------------------------------------------
Write-Host "`n>>> [1/3] SKT 베스트 109 요금제 기준 크롤링 시작..." -ForegroundColor Cyan
try {
    $sktUrl = "https://shop.tworld.co.kr/notice"
    $sktRes = Invoke-WebRequest -Uri $sktUrl -Method Get -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" -MaximumRedirection 5
    $sktPattern = '_this\.products\s*=\s*parseObject\((\[.*?\])\);'
    if ($sktRes.Content -match $sktPattern) {
        $rawSkt = $matches[1] | ConvertFrom-Json
        foreach ($p in $rawSkt) {
            $mem = if ($p.productMem) { " " + $p.productMem } else { "" }
            $fullName = ($p.productNm + $mem).Trim()
            if (-not (IsTargetModel $fullName)) { continue }

            $crawledData.skt += @{
                carrier = "SKT"
                manufacturer = $p.companyNm
                model = $fullName
                modelCode = $p.modelCd
                factoryPrice = [int64]$p.factoryPrice
                subsidy = [int64]$p.telecomSaleAmt # 공통지원금 (추가지원금 dsnetSupmAmt 제외)
                date = $p.effStaDt
                scrbType = if ($p.scrbTypCd -eq '31') { "기기변경" } elseif ($p.scrbTypCd -eq '20') { "번호이동" } else { "신규가입" }
            }
        }
        Write-Host "  ✅ SKT 추출 성공: $($crawledData.skt.Count)개 플래그십 기종 수집 완료 (A시리즈 제외)" -ForegroundColor Green
    } else {
        Write-Host "  ❌ SKT 제품 목록 JSON 파싱 실패" -ForegroundColor Red
    }
} catch {
    Write-Host "  ❌ SKT 크롤링 에러: $($_.Exception.Message)" -ForegroundColor Red
}

# -------------------------------------------------------------
# CDP 초기화 헬퍼 함수
# -------------------------------------------------------------
function Start-EdgeCDP($targetUrl) {
    Get-Process msedge -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*--remote-debugging-port=$port*" } | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500

    $proc = Start-Process -FilePath $edgePath -ArgumentList "--remote-debugging-port=$port", "--headless=new", "--disable-gpu", "--disable-software-rasterizer", "--window-size=1600,1200", $targetUrl -PassThru
    Start-Sleep -Seconds 6

    $tabs = Invoke-RestMethod -Uri "http://localhost:$port/json/list"
    $pageTab = $tabs | Where-Object { $_.type -eq "page" } | Select-Object -First 1
    if (-not $pageTab) { throw "브라우저 탭을 열 수 없습니다." }

    $wsUrl = $pageTab.webSocketDebuggerUrl
    $ws = [System.Net.WebSockets.ClientWebSocket]::new()
    $cts = [System.Threading.CancellationTokenSource]::new()
    $ws.ConnectAsync([System.Uri]::new($wsUrl), $cts.Token).Wait()

    return @{ ws = $ws; cts = $cts; proc = $proc; cmdId = 1 }
}

function Invoke-CDPCmd($cdpSession, $method, $params = @{}) {
    $cdpSession.cmdId++
    $msg = @{ id = $cdpSession.cmdId; method = $method; params = $params } | ConvertTo-Json -Depth 10 -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($msg)
    $segment = [System.ArraySegment[byte]]::new($bytes)
    $cdpSession.ws.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $cdpSession.cts.Token).Wait()

    $buffer = [byte[]]::new(65536 * 8)
    $ms = [System.IO.MemoryStream]::new()
    do {
        $recvSegment = [System.ArraySegment[byte]]::new($buffer)
        $result = $cdpSession.ws.ReceiveAsync($recvSegment, $cdpSession.cts.Token).Result
        $ms.Write($buffer, 0, $result.Count)
    } while (-not $result.EndOfMessage)

    $respBytes = $ms.ToArray()
    $respStr = [System.Text.Encoding]::UTF8.GetString($respBytes)
    return $respStr | ConvertFrom-Json
}

function Close-EdgeCDP($cdpSession) {
    if ($cdpSession.ws -and $cdpSession.ws.State -eq 'Open') {
        $cdpSession.ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", [System.Threading.CancellationToken]::None).Wait()
    }
    if ($cdpSession.proc -and -not $cdpSession.proc.HasExited) {
        Stop-Process -Id $cdpSession.proc.Id -Force -ErrorAction SilentlyContinue
    }
}

# -------------------------------------------------------------
# 2. KT 크롤링 (https://shop.kt.com/m/smart/supportAmtList.do)
# -------------------------------------------------------------
Write-Host "`n>>> [2/3] KT 110 요금제 기준 크롤링 시작..." -ForegroundColor Cyan
$ktSession = $null
try {
    $ktUrl = "https://shop.kt.com/m/smart/supportAmtList.do"
    $ktSession = Start-EdgeCDP $ktUrl

    # 더보기(#moreView) 버튼 클릭하여 전체 단말 로드
    for ($i = 1; $i -le 10; $i++) {
        $clickRes = Invoke-CDPCmd $ktSession "Runtime.evaluate" @{
            expression = @"
                (function() {
                    const btn = document.querySelector('#moreView, .btnProdMore');
                    if (btn && btn.offsetParent !== null && !btn.disabled) {
                        btn.click();
                        return btn.innerText.trim();
                    }
                    return 'done';
                })()
"@
            returnByValue = $true
        }
        $val = $clickRes.result.result.value
        if ($val -eq 'done' -or -not $val) { break }
        Start-Sleep -Seconds 2
    }

    $evalRes = Invoke-CDPCmd $ktSession "Runtime.evaluate" @{
        expression = @"
            (function() {
                const list = [];
                document.querySelectorAll('.prodListWrap li').forEach(li => {
                    const nameEl = li.querySelector('.prodInfo .prodName');
                    if (!nameEl) return;
                    const name = nameEl.innerText.trim();
                    
                    let factoryPrice = 0;
                    let supportAmt = 0;
                    let date = '';

                    const dateEl = li.querySelector('.prodInfo .date span:last-child');
                    if (dateEl) date = dateEl.innerText.trim();

                    li.querySelectorAll('.prodPayDetailIn li').forEach(subLi => {
                        const tit = subLi.querySelector('.tit')?.innerText.trim() || '';
                        const conts = subLi.querySelector('.conts')?.innerText.trim() || '';
                        if (tit.includes('출고가')) {
                            factoryPrice = parseInt(conts.replace(/[^0-9]/g, ''), 10) || 0;
                        }
                        if (tit.includes('공통지원금')) {
                            supportAmt = parseInt(conts.replace(/[^0-9]/g, ''), 10) || 0;
                        }
                    });

                    if (name && (factoryPrice > 0 || supportAmt > 0)) {
                        list.push({
                            carrier: "KT",
                            model: name,
                            factoryPrice: factoryPrice,
                            subsidy: supportAmt,
                            date: date
                        });
                    }
                });
                return list;
            })()
"@
        returnByValue = $true
    }

    $rawKt = $evalRes.result.result.value
    foreach ($item in $rawKt) {
        if (IsTargetModel $item.model) {
            $crawledData.kt += $item
        }
    }
    Write-Host "  ✅ KT 추출 성공: $($crawledData.kt.Count)개 플래그십 기종 수집 완료 (A시리즈 제외)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ KT 크롤링 에러: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    if ($ktSession) { Close-EdgeCDP $ktSession }
}

# -------------------------------------------------------------
# 3. LGU+ 크롤링 (https://www.lguplus.com/mobile/financing-model)
# -------------------------------------------------------------
Write-Host "`n>>> [3/3] LGU+ 105 요금제 기준 크롤링 시작..." -ForegroundColor Cyan
$lguSession = $null
try {
    $lguUrl = "https://www.lguplus.com/mobile/financing-model"
    $lguSession = Start-EdgeCDP $lguUrl

    for ($page = 1; $page -le 5; $page++) {
        if ($page -gt 1) {
            $clickRes = Invoke-CDPCmd $lguSession "Runtime.evaluate" @{
                expression = @"
                    (function() {
                        const btns = Array.from(document.querySelectorAll('.pagination a, .pagination button'));
                        const target = btns.find(b => b.innerText.trim() === '$page');
                        if (target) {
                            target.click();
                            return 'clicked';
                        }
                        return 'not found';
                    })()
"@
                returnByValue = $true
            }
            if ($clickRes.result.result.value -eq 'not found') { break }
            Start-Sleep -Seconds 2
        }

        $evalRes = Invoke-CDPCmd $lguSession "Runtime.evaluate" @{
            expression = @"
                (function() {
                    const trs = document.querySelectorAll('table')[1].querySelectorAll('tbody tr');
                    const list = [];
                    trs.forEach(tr => {
                        const tds = Array.from(tr.querySelectorAll('th, td')).map(el => el.innerText.trim().replace(/\s+/g, ' '));
                        if (tds.length >= 8) {
                            list.push({
                                carrier: "LGU+",
                                model: tds[0],
                                factoryPrice: parseInt(tds[1].replace(/[^0-9]/g, ''), 10) || 0,
                                subsidy: parseInt(tds[4].replace(/[^0-9]/g, ''), 10) || 0,
                                date: tds[2]
                            });
                        }
                    });
                    return list;
                })()
"@
            returnByValue = $true
        }

        $pageDevices = $evalRes.result.result.value
        foreach ($d in $pageDevices) {
            if (IsTargetModel $d.model) {
                $crawledData.lgu += $d
            }
        }
    }
    Write-Host "  ✅ LGU+ 추출 성공: $($crawledData.lgu.Count)개 플래그십 기종 수집 완료 (A시리즈 제외)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ LGU+ 크롤링 에러: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    if ($lguSession) { Close-EdgeCDP $lguSession }
}

# -------------------------------------------------------------
# 4. 종합 요약 및 JSON 저장
# -------------------------------------------------------------
$crawledData.summary = @{
    targetScope = "S시리즈, 아이폰, 폴더블류, FE류, 엣지류 (A시리즈 및 저가형 제외)"
    plansApplied = @{
        SKT = "베스트 109 요금제 (넷가표 109,000원 6개월 기준)"
        KT = "초이스/스페셜 110 요금제 (넷가표 110,000원 6개월 기준)"
        LGU = "프리미어 105/95 요금제 (넷가표 105,000원 6개월 기준)"
    }
    sktCount = $crawledData.skt.Count
    ktCount = $crawledData.kt.Count
    lguCount = $crawledData.lgu.Count
    totalCount = ($crawledData.skt.Count + $crawledData.kt.Count + $crawledData.lgu.Count)
}

$outputJsonPath = "$root\data\crawled_subsidies_latest.json"
$jsonString = $crawledData | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($outputJsonPath, $jsonString, [System.Text.Encoding]::UTF8)

Write-Host "`n=========================================================="
Write-Host " [통합 크롤링 완료 및 데이터 저장 결과]" -ForegroundColor Yellow
Write-Host " - 대상 범위: $($crawledData.summary.targetScope)"
Write-Host " - SKT 수집: $($crawledData.summary.sktCount)개"
Write-Host " - KT 수집:  $($crawledData.summary.ktCount)개"
Write-Host " - LGU+ 수집: $($crawledData.summary.lguCount)개"
Write-Host " - 총 수집 데이터: $($crawledData.summary.totalCount)건"
Write-Host " - 저장 경로: $outputJsonPath"
Write-Host "=========================================================="
