Add-Type -AssemblyName System.Drawing

$refDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\references\skt"
$srcDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\skt_excel_images"

function Save-Rotated($srcPath, $destPath, $rotateType) {
    $img = [System.Drawing.Image]::FromFile($srcPath)
    if ($rotateType -eq "Rotate90FlipNone") {
        $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone)
    }
    $img.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $img.Dispose()
}

Save-Rotated (Join-Path $srcDir "image19.png") (Join-Path $refDir "skt_hyundai_m3.png") "Rotate90FlipNone"
Save-Rotated (Join-Path $srcDir "image23.png") (Join-Path $refDir "skt_hyundai_m3_bill.png") "Rotate90FlipNone"
Save-Rotated (Join-Path $srcDir "image24.png") (Join-Path $refDir "skt_samsung_tnana.png") "Rotate90FlipNone"

Write-Host "Rotation fixed to 90 degrees."
