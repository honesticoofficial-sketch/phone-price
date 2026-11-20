Add-Type -AssemblyName System.Drawing

$imgDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\skt_excel_images"

# Check image2.png to image9.png (the large slide images in Sheet 1)
for ($i = 2; $i -le 9; $i++) {
    $f = Join-Path $imgDir "image$i.png"
    if (Test-Path $f) {
        $img = [System.Drawing.Image]::FromFile($f)
        Write-Host "image$i.png: $($img.Width) x $($img.Height), Length: $((Get-Item $f).Length)"
        $img.Dispose()
    }
}
