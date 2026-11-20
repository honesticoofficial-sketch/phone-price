Add-Type -AssemblyName System.Drawing

$outputDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\final_lgu_images"
if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir -Force | Out-Null }

function Process-Image($srcPath, $rotate270, $destName) {
    $bmp = [System.Drawing.Bitmap]::FromFile($srcPath)
    if ($rotate270) {
        $bmp.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone)
    }
    $destPath = Join-Path $outputDir $destName
    $bmp.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Processed $destName ($((Get-Item $destPath).Length) bytes)"
}

# 1. NH농협 올원 (가로 원본 유지)
Process-Image "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\test_download_lgu\NH_LGU_Allone.png" $false "lgu_nh_allone.png"

# 2. 롯데 LOCA (가로 원본 유지)
Process-Image "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\toss_lgu_imgs\lgu_loca.png" $false "lgu_lotte_loca.png"

# 3. 롯데 U+ DC (세로 -> 270도 회전하여 가로형으로)
Process-Image "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\test_download_lgu\LO_LGU_DC.png" $true "lgu_lotte_dc.png"

# 4. 우리 U+ x 36 (세로 -> 270도 회전하여 가로형으로)
Process-Image "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\toss_lgu_imgs\woori_u_x.png" $true "lgu_woori_36.png"

# 5. 현대 M3 통신할인형 (세로 -> 270도 회전하여 가로형으로)
Process-Image "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\toss_lgu_imgs\lgu_hyundai_m3.png" $true "lgu_hyundai_m3.png"

# 6. 하나 U+ family (가로 원본 유지)
Process-Image "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\toss_lgu_imgs\uplus_family_hana.png" $false "lgu_hana_family.png"
