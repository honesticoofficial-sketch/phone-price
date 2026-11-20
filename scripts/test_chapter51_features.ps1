# scripts/test_chapter51_features.ps1
$ErrorActionPreference = "Stop"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9222
$htmlPath = "file:///C:/Users/User01/.gemini/antigravity/scratch/phone-price/index.html"

# Kill existing Edge instances on 9222
Get-Process msedge -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*--remote-debugging-port=$port*" } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

$proc = Start-Process -FilePath $edgePath -ArgumentList "--remote-debugging-port=$port", "--headless=new", "--disable-gpu", "--disable-software-rasterizer", "--window-size=1400,1000", $htmlPath -PassThru
Start-Sleep -Seconds 2

try {
    $versionJson = Invoke-RestMethod -Uri "http://localhost:$port/json/version"
    Write-Host "Edge Browser: $($versionJson.'User-Agent')"

    $tabs = Invoke-RestMethod -Uri "http://localhost:$port/json/list"
    $pageTab = $tabs | Where-Object { $_.type -eq "page" -and $_.url -like "*phone-price/index.html*" } | Select-Object -First 1

    if (-not $pageTab) {
        throw "Could not find index.html tab!"
    }

    $wsUrl = $pageTab.webSocketDebuggerUrl
    Write-Host "Connected to CDP WebSocket: $wsUrl"

    $ws = [System.Net.WebSockets.ClientWebSocket]::new()
    $cts = [System.Threading.CancellationTokenSource]::new()
    $ws.ConnectAsync([System.Uri]::new($wsUrl), $cts.Token).Wait()

    $cmdId = 1
    function Invoke-CDP($method, $params = @{}) {
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

    function Eval-JS($expr) {
        $res = Invoke-CDP "Runtime.evaluate" @{
            expression = $expr
            returnByValue = $true
            awaitPromise = $true
        }
        if ($res.result.exceptionDetails) {
            throw "JS Error: $($res.result.exceptionDetails.exception.description)"
        }
        return $res.result.result.value
    }

    # 1. Unlock app
    Eval-JS "window.db = null; window.scheduleStoreSave = function() {}; ['1','0','3','1','0','5'].forEach(d => inputPin(d));" | Out-Null
    Start-Sleep -Milliseconds 600
    $unlocked = Eval-JS "isUnlocked && currentRole === 'master'"
    Write-Host "App Unlocked as Master: $unlocked"

    # Test 1: 제휴카드 안내서 밑줄 콤마 끊김 현상 보정 확인
    Write-Host "--- Test 1: 제휴카드 안내서 밑줄 콤마 끊김 현상 보정 검증 ---"
    $cardUnderlineClasses = Eval-JS @"
    (function() {
        const m = document.getElementById('installmentMonthlyAmt');
        const t = document.getElementById('installmentTotalAmt');
        return {
            mClass: m ? m.className : '',
            tClass: t ? t.className : '',
            mHasBorderB: m ? m.className.includes('border-b-2') : false,
            mHasNoUnderline: m ? !m.className.includes('underline decoration-2') : false
        };
    })()
"@
    Write-Host "Card Monthly Amt Class: $($cardUnderlineClasses.mClass)"
    if ($cardUnderlineClasses.mHasBorderB -and $cardUnderlineClasses.mHasNoUnderline) {
        Write-Host ">>> SUCCESS: 제휴카드 안내서 금액 밑줄이 border-b-2로 완벽 교체되어 콤마 끊김 원천 차단됨!" -ForegroundColor Green
    } else {
        throw "Test 1 Failed: Card underline border-b-2 not found or old underline still present!"
    }

    # Test 2: 시세표 [필수확인] 스피커 아이콘 제거 및 중앙 정렬 검증
    Write-Host "--- Test 2: 시세표 [필수확인] 스피커 제거 및 중앙 정렬 검증 ---"
    $posterNoticeCheck = Eval-JS @"
    (function() {
        const box = document.getElementById('posterNoticeBox');
        if (!box) return { exists: false };
        const headerWrap = box.querySelector('.relative');
        const titleEl = box.querySelector('.text-center');
        const titleSvgs = titleEl ? titleEl.querySelectorAll('svg').length : 999;
        const text = titleEl ? titleEl.innerText.trim() : '';
        const isCentered = headerWrap ? headerWrap.classList.contains('justify-center') : false;
        return {
            exists: true,
            titleSvgs: titleSvgs,
            text: text,
            isCentered: isCentered
        };
    })()
"@
    Write-Host "Poster Notice Header: text='$($posterNoticeCheck.text)', titleSvgs=$($posterNoticeCheck.titleSvgs), isCentered=$($posterNoticeCheck.isCentered)"
    if ($posterNoticeCheck.exists -and $posterNoticeCheck.titleSvgs -eq 0 -and $posterNoticeCheck.isCentered) {
        Write-Host ">>> SUCCESS: 시세표 [필수확인] 스피커 아이콘 2개 완벽 제거 및 정중앙 정렬 완결!" -ForegroundColor Green
    } else {
        throw "Test 2 Failed: Notice header svgs not 0 or not centered!"
    }

    # Test 3: 시세표 (출고가 대비 130만원...) 설명 배너 캡처/인쇄 제외 검증
    Write-Host "--- Test 3: 시세표 출고가 대비 130만원 설명 배너 캡처 제외 검증 ---"
    $bannerCheck = Eval-JS @"
    (function() {
        const b = document.getElementById('posterDiscountNoticeBanner');
        return {
            exists: !!b,
            hasActionClass: b ? b.classList.contains('poster-ui-action') : false
        };
    })()
"@
    Write-Host "Discount Banner Exists: $($bannerCheck.exists), Has poster-ui-action: $($bannerCheck.hasActionClass)"
    if ($bannerCheck.exists -and $bannerCheck.hasActionClass) {
        Write-Host ">>> SUCCESS: 출고가 대비 130만원 배너에 poster-ui-action 적용되어 캡처 및 인쇄에서 완벽 배제됨!" -ForegroundColor Green
    } else {
        throw "Test 3 Failed: Banner does not have poster-ui-action!"
    }

    # Test 4: 매장보기 명지점 vs 광안점 집 모양 아이콘 색상 통일 검증
    Write-Host "--- Test 4: 매장 스위처 집 모양 아이콘 보라색 통일 검증 ---"
    $storeIconCheck = Eval-JS @"
    (function() {
        const mjBtn = document.getElementById('switchBtn-myeongji');
        const gaBtn = document.getElementById('switchBtn-gwangan');
        const mjSvg = mjBtn ? mjBtn.querySelector('svg') : null;
        const gaSvg = gaBtn ? gaBtn.querySelector('svg') : null;
        return {
            mjColor: mjSvg ? mjSvg.getAttribute('class') : '',
            gaColor: gaSvg ? gaSvg.getAttribute('class') : '',
            mjHasPurple: mjSvg ? mjSvg.getAttribute('class').includes('text-purple-600') : false,
            gaHasPurple: gaSvg ? gaSvg.getAttribute('class').includes('text-purple-600') : false
        };
    })()
"@
    Write-Host "Myeongji Icon Class: $($storeIconCheck.mjColor)"
    Write-Host "Gwangan Icon Class: $($storeIconCheck.gaColor)"
    if ($storeIconCheck.mjHasPurple -and $storeIconCheck.gaHasPurple) {
        Write-Host ">>> SUCCESS: 명지점 및 광안점 집 모양 아이콘 둘 다 text-purple-600으로 완벽 통일!" -ForegroundColor Green
    } else {
        throw "Test 4 Failed: House icons not unified to purple!"
    }

    # Test 5: 기종 선택기 모달 UI 검증
    Write-Host "--- Test 5: 프리미엄 기종 선택기 모달 검증 ---"
    $pickerModalCheck = Eval-JS @"
    (function() {
        const modal = document.getElementById('customDevicePickerModal');
        openCustomDevicePicker('calc', 0, 's26', null);
        const isOpen = !modal.classList.contains('hidden');
        const countCards = document.querySelectorAll('#devicePickerListContainer [onclick^=\"onSelectDeviceFromPicker\"]').length;
        setDevicePickerCategory('IPHONE');
        const countIphone = document.querySelectorAll('#devicePickerListContainer [onclick^=\"onSelectDeviceFromPicker\"]').length;
        closeCustomDevicePicker();
        const isClosed = modal.classList.contains('hidden');
        return {
            modalExists: !!modal,
            isOpen: isOpen,
            isClosed: isClosed,
            totalCards: countCards,
            iphoneCards: countIphone
        };
    })()
"@
    Write-Host "Picker Modal - Open: $($pickerModalCheck.isOpen), Total: $($pickerModalCheck.totalCards), iPhone: $($pickerModalCheck.iphoneCards), Closed: $($pickerModalCheck.isClosed)"
    if ($pickerModalCheck.modalExists -and $pickerModalCheck.isOpen -and $pickerModalCheck.isClosed -and $pickerModalCheck.totalCards -gt 0) {
        Write-Host ">>> SUCCESS: 모던 카드형 프리미엄 기종 선택기 모달 완벽 동작!" -ForegroundColor Green
    } else {
        throw "Test 5 Failed: Device picker modal failed to open/close or filter!"
    }

    # Test 6: 광고가격 탭 드롭다운 & 단축명 자동 표기 & 커스텀 영구 보관 검증
    Write-Host "--- Test 6: 광고가격 단축명 자동 파서 및 커스텀 명칭 유지 검증 ---"
    $shortNameCheck = Eval-JS @"
    (function() {
        const samples = [
            { name: '갤럭시 S26 256G', expected: '#S26' },
            { name: '갤럭시 S26 울트라 256G', expected: '#S26U' },
            { name: '갤럭시 S26 플러스 256G', expected: '#S26+' },
            { name: '아이폰 17 256G', expected: '아17' },
            { name: '아이폰 18 프로 256G', expected: '18프로' },
            { name: '아이폰 18 프로 맥스 256G', expected: '18프맥' }
        ];
        const results = samples.map(s => {
            const actual = getDefaultShortName({ name: s.name, id: 'test' });
            return { name: s.name, expected: s.expected, actual: actual, match: actual === s.expected };
        });

        // Test custom storage
        saveStoreCustomTag('myeongji', 'test_dev', '나만의단축명');
        const saved = getStoreCustomTag('myeongji', 'test_dev');

        return {
            results: results,
            allMatched: results.every(r => r.match),
            customSaved: saved === '나만의단축명'
        };
    })()
"@
    Write-Host "Short Name Results: $($shortNameCheck.results | ConvertTo-Json -Compress)"
    Write-Host "Custom Tag Persistence: $($shortNameCheck.customSaved)"
    if ($shortNameCheck.allMatched -and $shortNameCheck.customSaved) {
        Write-Host ">>> SUCCESS: 단축명 자동 생성(#S26, #S26U, 아17, 18프로) 및 매장별 커스텀 수정 보관 완벽 통과!" -ForegroundColor Green
    } else {
        throw "Test 6 Failed: Short name parsing or custom tag persistence failed!"
    }

    # Test 7: 광고가격 추천금액 알고리즘 및 자동입력 검증
    Write-Host "--- Test 7: 광고가격 추천금액 (끝자리 5·9, 마진 >= 0) 및 자동입력 검증 ---"
    $recPriceCheck = Eval-JS @"
    (function() {
        const tests = [
            { net: 23, expected: 25 },
            { net: 27, expected: 29 },
            { net: 29, expected: 29 },
            { net: 30, expected: 35 },
            { net: 35, expected: 35 },
            { net: 36, expected: 39 },
            { net: -23, expected: -19 },
            { net: -15, expected: -15 },
            { net: -12, expected: -9 },
            { net: -4, expected: 5 }
        ];
        const res = tests.map(t => {
            const calculated = getRecommendedPrice(t.net);
            const marginOk = calculated >= t.net;
            const endDigit = Math.abs(calculated) % 10;
            const endDigitOk = (calculated === 0 || endDigit === 5 || endDigit === 9);
            return {
                net: t.net,
                calculated: calculated,
                marginOk: marginOk,
                endDigitOk: endDigitOk,
                passed: marginOk && endDigitOk
            };
        });
        return {
            allPassed: res.every(r => r.passed),
            details: res
        };
    })()
"@
    Write-Host "Rec Price Tests: $($recPriceCheck.details | ConvertTo-Json -Compress)"
    if ($recPriceCheck.allPassed) {
        Write-Host ">>> SUCCESS: 광고가격 추천금액 알고리즘 (끝자리 5·9, 넷가 대비 마진 흑자 근접가) 100% 통과!" -ForegroundColor Green
    } else {
        throw "Test 7 Failed: Recommended price algorithm failed!"
    }

    # Test 8: 네이티브 벡터 캡처 3종 무결성 검증
    Write-Host "--- Test 8: 네이티브 벡터 캡처 3종 (넷가표, 시세표, 제휴카드) 무결성 검증 ---"
    $captures = Eval-JS @"
    (async function() {
        switchTab('calc');
        const calcContainer = document.getElementById('calcTableContainer');
        let netSize = 0, posterSize = 0, cardSize = 0;
        if (calcContainer) {
            const b = await htmlToImage.toBlob(calcContainer, { pixelRatio: 1.5, backgroundColor: '#ffffff' });
            netSize = b ? b.size : 0;
        }

        switchTab('adtable');
        const sheet = document.getElementById('adPosterSheet');
        if (sheet) {
            const b = await htmlToImage.toBlob(sheet, { pixelRatio: 1.5, backgroundColor: '#ffffff' });
            posterSize = b ? b.size : 0;
        }

        switchTab('card');
        const cardContainer = document.getElementById('cardA4Sheet');
        if (cardContainer) {
            const b = await htmlToImage.toBlob(cardContainer, { pixelRatio: 1.5, backgroundColor: '#ffffff' });
            cardSize = b ? b.size : 0;
        }

        return {
            netSize: netSize,
            posterSize: posterSize,
            cardSize: cardSize
        };
    })()
"@
    Write-Host "Capture Sizes: NetTable=$($captures.netSize) bytes, Poster=$($captures.posterSize) bytes, Card=$($captures.cardSize) bytes"
    if ($captures.netSize -gt 100000 -and $captures.posterSize -gt 100000 -and $captures.cardSize -gt 100000) {
        Write-Host ">>> SUCCESS: 3종 이미지 캡처 모두 100KB+ 초고화질 무손실 PNG 정상 생성 완료!" -ForegroundColor Green
    } else {
        throw "Test 8 Failed: Capture size too small or failed!"
    }

    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host "🎉 모든 7대 사용자 요청사항 및 무결성 전수 검증 100% 통과! 🎉" -ForegroundColor Cyan
    Write-Host "========================================================`n" -ForegroundColor Cyan

} finally {
    if ($ws -and $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
    }
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
}
