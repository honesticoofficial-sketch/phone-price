$dir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\skt_qr_images"
$files = Get-ChildItem $dir -Include image2.png, image3.png, image4.png, image5.png, image6.png, image7.png, image8.png, image9.png

$imgObjects = @()
foreach ($f in $files) {
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $b64 = [System.Convert]::ToBase64String($bytes)
    $imgObjects += @{
        name = $f.Name
        src = "data:image/png;base64,$b64"
    }
}

$json = $imgObjects | ConvertTo-Json -Depth 3 -Compress

$html = @"
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>QR Decoder Inline</title>
  <script src="https://cdn.jsdelivr.net/npm/jsqr@1.4.0/dist/jsQR.min.js"></script>
</head>
<body>
  <h1>Decoding...</h1>
  <div id="res"></div>
  <script>
    const images = $json;
    window.results = [];

    async function run() {
      for (const item of images) {
        const decoded = await decodeImg(item.src);
        window.results.push({ name: item.name, data: decoded });
      }
      document.getElementById('res').innerText = JSON.stringify(window.results, null, 2);
    }

    function decodeImg(src) {
      return new Promise(resolve => {
        const img = new Image();
        img.src = src;
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
        img.onerror = () => resolve('error');
      });
    }

    window.onload = run;
  </script>
</body>
</html>
"@

[System.IO.File]::WriteAllText("C:\Users\User01\.gemini\antigravity\scratch\phone-price\decode_inline.html", $html, [System.Text.Encoding]::UTF8)
Write-Host "Created decode_inline.html"
