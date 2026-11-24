[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

Write-Host "=========================================================="
Write-Host " [LGU+ 실시간 검색 기반 100% 실측 자동 크롤러]"
Write-Host " - 검색 버튼: .c-ibtn-find (문자삭제 버튼 .c-btn-clear 오클릭 원천 차단)"
Write-Host " - 요금제: 115k 요금제 적용"
Write-Host "=========================================================="

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9268

cmd.exe /c "taskkill /f /im msedge.exe 2>nul" | Out-Null
Start-Sleep -Milliseconds 800

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
        $msg = @{ id = $script:cmdId; method = $method; params = $params } | ConvertTo-Json -Depth 10 -Compress
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($msg)
        $ws.SendAsync([System.ArraySegment[byte]]::new($bytes), [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $cts.Token).Wait()

        $buffer = [byte[]]::new(65536 * 8)
        $ms = [System.IO.MemoryStream]::new()
        do {
            $result = $ws.ReceiveAsync([System.ArraySegment[byte]]::new($buffer), $cts.Token).Result
            $ms.Write($buffer, 0, $result.Count)
        } while (-not $result.EndOfMessage)

        return [System.Text.Encoding]::UTF8.GetString($ms.ToArray()) | ConvertFrom-Json
    }

    Write-Host "1. LGU+ 공식 공시지원금 페이지 접속..."
    Invoke-CDP "Page.navigate" @{ url = "https://www.lguplus.com/mobile/financing-model" }
    Start-Sleep -Seconds 7

    Write-Host "2. 115k 요금제 선택 및 적용..."
    Invoke-CDP "Runtime.evaluate" @{ expression = "(() => { const b = Array.from(document.querySelectorAll('button')).find(x => x.innerText.includes('더 많은 요금제 보기')); if (b) b.click(); })()" }
    Start-Sleep -Seconds 2
    Invoke-CDP "Runtime.evaluate" @{ expression = "(() => { const t = Array.from(document.querySelectorAll('label, button')).find(x => x.innerText.includes('115,000') && x.offsetParent !== null); if (t) t.click(); })()" }
    Start-Sleep -Seconds 1
    Invoke-CDP "Runtime.evaluate" @{ expression = "(() => { const b = Array.from(document.querySelectorAll('button')).find(x => (x.innerText.includes('적용') || x.innerText.includes('확인')) && x.offsetParent !== null); if (b) b.click(); })()" }
    Start-Sleep -Seconds 3

    # 검색 대상 키워드 (플래그십 전 라인업)
    $searchKeywords = @("iPhone 18", "iPhone 17", "iPhone 16", "iPhone 15", "S26", "S25", "S24", "S23", "Fold", "Flip")

    $crawledLguMap = @{}

    # 개통유형 순회
    $scrbList = @(
        @{ code = "MNP"; name = "번호이동" },
        @{ code = "CHG"; name = "기기변경" },
        @{ code = "NEW"; name = "신규가입" }
    )

    foreach ($scrb in $scrbList) {
        $sCode = $scrb.code
        $sName = $scrb.name
        Write-Host "`n>>> [LGU+ $sName ($sCode)] 라디오 전환..."

        Invoke-CDP "Runtime.evaluate" @{
            expression = @"
                (() => {
                    const l = Array.from(document.querySelectorAll('label')).find(x => x.innerText.trim() === '$sName' && x.offsetParent !== null);
                    if (l) l.click();
                })()
"@
        }
        Start-Sleep -Seconds 2

        foreach ($kw in $searchKeywords) {
            # Search with .c-ibtn-find
            Invoke-CDP "Runtime.evaluate" @{
                expression = @"
                    (() => {
                        const inp = document.getElementById('cfrmSearch-1-1');
                        if (!inp) return;
                        inp.value = '$kw';
                        inp.dispatchEvent(new Event('input', { bubbles: true }));
                        inp.dispatchEvent(new Event('change', { bubbles: true }));
                        const findBtn = document.querySelector('.c-ibtn-find');
                        if (findBtn) findBtn.click();
                    })()
"@
            }
            Start-Sleep -Seconds 2

            # Extract rows
            $extract = Invoke-CDP "Runtime.evaluate" @{
                expression = @"
                    (() => {
                        const t = document.querySelectorAll('table')[1] || document.querySelector('table');
                        if (!t) return [];
                        return Array.from(t.querySelectorAll('tbody tr')).map(tr => {
                            return Array.from(tr.querySelectorAll('td, th')).map(c => c.innerText.trim().replace(/\s+/g, ' '));
                        }).filter(r => r.length >= 5 && !r[0].includes('검색 결과가 없습니다'));
                    })()
"@
                returnByValue = $true
            }

            $rows = $extract.result.result.value
            $matchCount = 0
            if ($rows) {
                foreach ($r in $rows) {
                    $mName = $r[0]
                    # Filter out helper rows or non-target
                    if ($mName -match '유지|선택약정') { continue }
                    if ($mName -match '갤럭시 A|Galaxy A|A[0-9]{2}|퀀텀|와이드|점프|버디|샤오미|홍미|모토|워치|Watch|탭|Tab|키즈|SM-A') { continue }

                    $fPrice = [int]($r[1] -replace '[^0-9]', '')
                    $sAmt = [int]($r[4] -replace '[^0-9]', '')
                    $dDate = $r[2]

                    $key = $mName.Trim()
                    if (-not $crawledLguMap.ContainsKey($key)) {
                        $crawledLguMap[$key] = @{
                            model = $key
                            factoryPrice = $fPrice
                            planName = "5G 프리미어 슈퍼 (115,000원)"
                            planPrice = 115000
                            subsidies = @{ NEW = 0; MNP = 0; CHG = 0 }
                            effDate = $dDate
                        }
                    }
                    $crawledLguMap[$key].subsidies[$sCode] = $sAmt
                    $matchCount++
                }
            }
            Write-Host "    - [$kw] 수집: $matchCount 개 행"
        }
    }

    Write-Host "`n=== LGU+ 공식 검색 기반 총 수집 단말 수: $($crawledLguMap.Keys.Count) 개 ==="
    $finalList = $crawledLguMap.Values | Sort-Object model

    $outJson = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\lgu_pipeline_crawled.json"
    $finalList | ConvertTo-Json -Depth 5 | Set-Content -Path $outJson -Encoding UTF8
    Write-Host "저장 완료: $outJson"

    # Display iPhone 17 & 18 rows
    Write-Host "`n=== [LGU+ 공식 실측 결과 요약] ==="
    $finalList | Where-Object { $_.model -like "*17*" -or $_.model -like "*18*" } | 
        Select-Object model, factoryPrice, @{n="신규";e={$_.subsidies.NEW}}, @{n="번이";e={$_.subsidies.MNP}}, @{n="기변";e={$_.subsidies.CHG}} | 
        Format-Table -AutoSize | Out-String | Write-Host

} finally {
    if ($ws -and $ws.State -eq 'Open') {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", [System.Threading.CancellationToken]::None).Wait()
    }
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}
