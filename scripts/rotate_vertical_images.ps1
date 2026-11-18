Add-Type -AssemblyName System.Drawing

function RotateVerticalImagesInFile($filePath) {
    Write-Output "Processing $filePath..."
    $content = Get-Content $filePath -Raw -Encoding UTF8
    
    # Match cardPlateImageUrl
    $pattern = 'cardPlateImageUrl:\s*[\x22\x27](data:image/[^;]+;base64,[^\x22\x27]+)[\x22\x27]'
    $matches = [regex]::Matches($content, $pattern)
    Write-Output "Found $($matches.Count) images."
    
    $rotatedCount = 0
    $replacements = @{}
    
    foreach ($m in $matches) {
        $oldDataUrl = $m.Groups[1].Value
        $base64 = $oldDataUrl.Substring($oldDataUrl.IndexOf(",") + 1)
        try {
            $bytes = [Convert]::FromBase64String($base64)
            $ms = New-Object System.IO.MemoryStream($bytes, 0, $bytes.Length)
            $bmp = [System.Drawing.Bitmap]::FromStream($ms)
            
            if ($bmp.Height -gt $bmp.Width) {
                # Vertical! Rotate 90 degrees clockwise
                $oldW = $bmp.Width
                $oldH = $bmp.Height
                $bmp.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone)
                $newW = $bmp.Width
                $newH = $bmp.Height
                
                $outMs = New-Object System.IO.MemoryStream
                $bmp.Save($outMs, [System.Drawing.Imaging.ImageFormat]::Png)
                $newBytes = $outMs.ToArray()
                $newBase64 = [Convert]::ToBase64String($newBytes)
                $newDataUrl = "data:image/png;base64," + $newBase64
                
                $replacements[$oldDataUrl] = $newDataUrl
                $rotatedCount++
                Write-Output "Rotated: ${oldW}x${oldH} -> ${newW}x${newH}"
                
                $outMs.Dispose()
            }
            $bmp.Dispose()
            $ms.Dispose()
        } catch {
            Write-Output "Error: $_"
        }
    }
    
    Write-Output "Total rotated in this file: $rotatedCount"
    if ($rotatedCount -gt 0) {
        foreach ($key in $replacements.Keys) {
            $content = $content.Replace($key, $replacements[$key])
        }
        
        # Also ensure cardPlateOrientation: "horizontal" everywhere
        $content = [regex]::Replace($content, 'cardPlateOrientation:\s*[\x22\x27]vertical[\x22\x27]', 'cardPlateOrientation: "horizontal"')
        
        [System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::UTF8)
        Write-Output "Successfully updated $filePath"
    }
}

RotateVerticalImagesInFile 'C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html'
RotateVerticalImagesInFile 'C:\Users\User01\.gemini\antigravity\scratch\phone-price\lgu_cards_data.js'
