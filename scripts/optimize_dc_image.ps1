Add-Type -AssemblyName System.Drawing

function Optimize-Png($srcPath, $destPath, $maxWidth) {
    $src = [System.Drawing.Bitmap]::FromFile($srcPath)
    if ($src.Width -gt $maxWidth) {
        $scale = $maxWidth / $src.Width
        $newW = [int]($src.Width * $scale)
        $newH = [int]($src.Height * $scale)
        $dest = New-Object System.Drawing.Bitmap $newW, $newH
        $g = [System.Drawing.Graphics]::FromImage($dest)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $g.DrawImage($src, 0, 0, $newW, $newH)
        $g.Dispose()
        $dest.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $dest.Dispose()
    } else {
        $src.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    $src.Dispose()
    Write-Host "Optimized $([System.IO.Path]::GetFileName($destPath)): $((Get-Item $destPath).Length) bytes"
}

$optPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\test_download_lgu\LO_LGU_DC_opt.png"
Optimize-Png "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\test_download_lgu\LO_LGU_DC.png" $optPath 400
