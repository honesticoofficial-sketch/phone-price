Add-Type -AssemblyName System.Drawing

$refDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\references\skt"
if (-not (Test-Path $refDir)) { New-Item -ItemType Directory -Path $refDir -Force | Out-Null }

$srcDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\skt_excel_images"

function Save-Rotated($srcPath, $destPath, $rotateType) {
    $img = [System.Drawing.Image]::FromFile($srcPath)
    if ($rotateType -eq "Rotate270FlipNone") {
        $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone)
    } elseif ($rotateType -eq "Rotate90FlipNone") {
        $img.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone)
    }
    $img.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $img.Dispose()
}

function Save-Cropped($srcPath, $destPath, $x, $y, $w, $h) {
    $img = [System.Drawing.Image]::FromFile($srcPath)
    $rect = New-Object System.Drawing.Rectangle($x, $y, $w, $h)
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.DrawImage($img, (New-Object System.Drawing.Rectangle(0, 0, $w, $h)), $rect, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()
    $bmp.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    $img.Dispose()
}

# 1. 삼성 T PREMIUM
Copy-Item (Join-Path $srcDir "image28.png") (Join-Path $refDir "skt_samsung_premium.png") -Force

# 2. 현대 M3 T라이트2 (image19.png - rotate 270)
Save-Rotated (Join-Path $srcDir "image19.png") (Join-Path $refDir "skt_hyundai_m3.png") "Rotate270FlipNone"

# 3. NH카드 T라이트 (image20.png)
Copy-Item (Join-Path $srcDir "image20.png") (Join-Path $refDir "skt_nh_tlight.png") -Force

# 4. 삼성카드 T라이트 (image21.png)
Copy-Item (Join-Path $srcDir "image21.png") (Join-Path $refDir "skt_samsung_tlight.png") -Force

# 5. 하나카드 T다운 / T-Zero
Copy-Item "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\hana_skt_tzero.png" (Join-Path $refDir "skt_hana_tdown.png") -Force

# 6. 우리카드 T라이트 (image31.png is 448x341 - left half is front: 0, 0, 224, 341)
# But wait, image31 is 448 wide, 341 high. Left card is roughly 220px wide, 340px high. Wait, let's check image31 orientation!
$wImg = [System.Drawing.Image]::FromFile((Join-Path $srcDir "image31.png"))
Write-Host "image31 size: $($wImg.Width) x $($wImg.Height)"
# In image31, let's crop the left half: 0 to 224
$wLeft = [int]($wImg.Width * 0.49)
Save-Cropped (Join-Path $srcDir "image31.png") (Join-Path $refDir "skt_woori_tlight.png") 0 0 $wLeft $wImg.Height
$wImg.Dispose()

# 7. KB국민카드 T라이트 (image22.png)
Copy-Item (Join-Path $srcDir "image22.png") (Join-Path $refDir "skt_kb_tlight.png") -Force

# 8. 롯데카드 T 라이트 (image42.png)
Copy-Item (Join-Path $srcDir "image42.png") (Join-Path $refDir "skt_lotte_tlight.png") -Force

# 9. 신한카드 T라이트 (image25.png)
Copy-Item (Join-Path $srcDir "image25.png") (Join-Path $refDir "skt_shinhan_tlight.png") -Force

# 10. 신한카드 파인애플 (image41.png)
Copy-Item (Join-Path $srcDir "image41.png") (Join-Path $refDir "skt_shinhan_pineapple.png") -Force

# 11. 신한카드 T&LIFE (image37.png)
Copy-Item (Join-Path $srcDir "image37.png") (Join-Path $refDir "skt_shinhan_tlife.png") -Force

# 12. KB국민카드 T이코노미 (image26.png)
Copy-Item (Join-Path $srcDir "image26.png") (Join-Path $refDir "skt_kb_teconomy.png") -Force

# 13. 현대카드 M3 통신할인형2.0 (image23.png - rotate 270)
Save-Rotated (Join-Path $srcDir "image23.png") (Join-Path $refDir "skt_hyundai_m3_bill.png") "Rotate270FlipNone"

# 14. 롯데카드 TELLO NE (image45.png)
Copy-Item (Join-Path $srcDir "image45.png") (Join-Path $refDir "skt_lotte_tello.png") -Force

# 15. 삼성카드 T나는혜택 (image24.png - rotate 270)
Save-Rotated (Join-Path $srcDir "image24.png") (Join-Path $refDir "skt_samsung_tnana.png") "Rotate270FlipNone"

Write-Host "All 15 SKT reference cards built successfully in $refDir"
