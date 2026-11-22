[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$port = 9222

# Kill old processes
Get-Process msedge -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*--remote-debugging-port=$port*" } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

$proc = Start-Process -FilePath $edgePath -ArgumentList "--remote-debugging-port=$port", "--headless=new", "--disable-gpu", "--window-size=1600,1200", "https://shop.kt.com/m/smart/supportAmtList.do" -PassThru
Start-Sleep -Seconds 6

$ws = $null
$cts = $null
try {
    $tabs = Invoke-RestMethod -Uri "http://localhost:$port/json/list"
    $pageTab = $tabs | Where-Object { $_.type -eq "page" } | Select-Object -First 1
    $wsUrl = $pageTab.webSocketDebuggerUrl

    $ws = [System.Net.WebSockets.ClientWebSocket]::new()
    $cts = [System.Threading.CancellationTokenSource]::new()
    $ws.ConnectAsync([System.Uri]::new($wsUrl), $cts.Token).Wait()

    function Invoke-CDP($method, $params = @{}) {
        $msg = @{ id = (Get-Random); method = $method; params = $params } | ConvertTo-Json -Depth 10 -Compress
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

    Write-Host "Clicking #moreView button..."
    for ($i = 1; $i -le 10; $i++) {
        $clickRes = Invoke-CDP "Runtime.evaluate" @{
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
        Write-Host "Loop $($i): $val"
        if ($val -eq 'done' -or -not $val) { break }
        Start-Sleep -Seconds 2
    }

    # Now extract all items
    $extractRes = Invoke-CDP "Runtime.evaluate" @{
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
                        if (tit.includes('출고가')) factoryPrice = parseInt(conts.replace(/[^0-9]/g, ''), 10) || 0;
                        if (tit.includes('공통지원금')) supportAmt = parseInt(conts.replace(/[^0-9]/g, ''), 10) || 0;
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

    $items = $extractRes.result.result.value
    Write-Host "Total KT items collected: $($items.Count)"
    $items | Where-Object { $_.model -like "*A1*" -or $_.model -like "*17*" -or $_.model -like "*175*" } | Format-Table -AutoSize | Out-String | Write-Host

    # Return items
    $items | ConvertTo-Json -Depth 5 | Out-File (Join-Path $PSScriptRoot "..\data\kt_full_items.json") -Encoding UTF8
} finally {
    if ($ws -and $ws.State -eq 'Open') { $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "done", [System.Threading.CancellationToken]::None).Wait() }
    if ($proc -and -not $proc.HasExited) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }
}
