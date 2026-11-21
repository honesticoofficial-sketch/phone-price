$ErrorActionPreference = "Stop"

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) { $edgePath = "C:\Program Files\Microsoft\Edge\Application\msedge.exe" }

$port = 9242
$userDataDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\edge_profile_decode_all"
New-Item -ItemType Directory -Path $userDataDir -Force | Out-Null
$targetHtml = "file:///C:/Users/User01/.gemini\antigravity/scratch/phone-price/index.html"

$edgeProcess = Start-Process -FilePath $edgePath -ArgumentList @(
    "--remote-debugging-port=$port",
    "--user-data-dir=$userDataDir",
    "--headless=new",
    $targetHtml
) -PassThru

Start-Sleep -Seconds 3

$versionUrl = "http://127.0.0.1:$port/json"
$targets = Invoke-RestMethod -Uri $versionUrl
$target = $targets | Where-Object { $_.type -eq "page" -and $_.url -match "index.html" } | Select-Object -First 1

$wsUrl = $target.webSocketDebuggerUrl
$ws = New-Object System.Net.WebSockets.ClientWebSocket
$cts = New-Object System.Threading.CancellationTokenSource
$ws.ConnectAsync([uri]$wsUrl, $cts.Token).Wait()

$reqId = 1
function Send-Cdp($method, $params = @{}) {
    $script:reqId++
    $payload = @{
        id = $script:reqId
        method = $method
        params = $params
    } | ConvertTo-Json -Depth 10 -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
    $segment = New-Object System.ArraySegment[byte] -ArgumentList @(,$bytes)
    $ws.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $cts.Token).Wait()

    $buffer = New-Object byte[] 65536
    while ($true) {
        $recvSeg = New-Object System.ArraySegment[byte] -ArgumentList @(,$buffer)
        $res = $ws.ReceiveAsync($recvSeg, $cts.Token).Result
        $text = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $res.Count)
        $parsed = $text | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($parsed -and $parsed.id -eq $script:reqId) {
            if ($parsed.result -and $parsed.result.result -and $parsed.result.result.value) {
                return $parsed.result.result.value
            }
            return $parsed.result
        }
    }
}

Send-Cdp "Runtime.enable" | Out-Null
Start-Sleep -Seconds 2

# Read all target images
$imgDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\skt_qr_images"
$targetImages = @(
    "image16.png", # Col 4 (E열): 현대카드
    "image35.png", # Col 6 (G열): 삼성카드
    "image33.png", # Col 8 (I열): 우리카드
    "image17.png", # Col 9 (J열): KB카드
    "image43.png", # Col 10 (K열): 롯데카드
    "image30.png", # Col 11 (L열): 신한카드 T라이트
    "image48.png", # Col 12 (M열): 신한카드 파인애플
    "image38.png", # Col 13 (N열): 신한카드 T&LIFE
    "image18.png", # Col 15 (P열): 현대카드 M3 통신
    "image36.png"  # Col 17 (R열): 삼성카드 T나는혜택
)

foreach ($imgName in $targetImages) {
    $imgPath = Join-Path $imgDir $imgName
    if (-not (Test-Path $imgPath)) {
        Write-Warning "File not found: $imgName"
        continue
    }
    $bytes = [System.IO.File]::ReadAllBytes($imgPath)
    $b64 = [System.Convert]::ToBase64String($bytes)
    
    $jsCode = @"
    new Promise(resolve => {
        const img = new Image();
        img.src = 'data:image/png;base64,$b64';
        img.onload = () => {
            const cvs = document.createElement('canvas');
            cvs.width = img.width;
            cvs.height = img.height;
            const ctx = cvs.getContext('2d');
            ctx.drawImage(img, 0, 0);
            const imgData = ctx.getImageData(0, 0, cvs.width, cvs.height);
            const qr = jsQR(imgData.data, imgData.width, imgData.height);
            resolve(qr ? qr.data : null);
        };
        img.onerror = () => resolve('load_error');
    })
"@
    $res = Send-Cdp "Runtime.evaluate" @{
        expression = $jsCode
        awaitPromise = $true
        returnByValue = $true
    }
    Write-Host "$imgName -> QR Data: $res"
}

$ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Done", $cts.Token).Wait()
Stop-Process -Id $edgeProcess.Id -Force
