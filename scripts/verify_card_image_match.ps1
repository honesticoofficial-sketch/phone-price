Add-Type -AssemblyName System.Drawing

function Compute-ImageSimilarity {
    param(
        [string]$PathA,
        [string]$PathB
    )

    if (-not (Test-Path $PathA) -or -not (Test-Path $PathB)) {
        return @{ Success = $false; MatchRate = 0; Reason = "File not found" }
    }

    $imgA = $null
    $imgB = $null
    try {
        $imgA = [System.Drawing.Image]::FromFile($PathA)
        $imgB = [System.Drawing.Image]::FromFile($PathB)

        $ratioA = $imgA.Width / [double]$imgA.Height
        $ratioB = $imgB.Width / [double]$imgB.Height

        # Both must have similar orientation (both horizontal or both vertical)
        $isHorizA = ($ratioA -ge 1.0)
        $isHorizB = ($ratioB -ge 1.0)

        if ($isHorizA -ne $isHorizB) {
            return @{
                Success = $true
                MatchRate = 0.0
                Reason = "Orientation mismatch (Horizontal vs Vertical)"
                RatioA = [Math]::Round($ratioA, 2)
                RatioB = [Math]::Round($ratioB, 2)
            }
        }

        # Normalize to 32x32 grayscale
        $size = 32
        $bmpA = New-Object System.Drawing.Bitmap($size, $size)
        $gA = [System.Drawing.Graphics]::FromImage($bmpA)
        $gA.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBilinear
        $gA.DrawImage($imgA, 0, 0, $size, $size)
        $gA.Dispose()

        $bmpB = New-Object System.Drawing.Bitmap($size, $size)
        $gB = [System.Drawing.Graphics]::FromImage($bmpB)
        $gB.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBilinear
        $gB.DrawImage($imgB, 0, 0, $size, $size)
        $gB.Dispose()

        # Compute Pixel Difference and Correlation
        $diffSum = 0.0
        $totalPixels = $size * $size

        $pixelsA = New-Object double[] $totalPixels
        $pixelsB = New-Object double[] $totalPixels

        $idx = 0
        for ($y = 0; $y -lt $size; $y++) {
            for ($x = 0; $x -lt $size; $x++) {
                $cA = $bmpA.GetPixel($x, $y)
                $cB = $bmpB.GetPixel($x, $y)

                # Luminance formula: 0.299*R + 0.587*G + 0.114*B
                $lumA = (0.299 * $cA.R + 0.587 * $cA.G + 0.114 * $cA.B) / 255.0
                $lumB = (0.299 * $cB.R + 0.587 * $cB.G + 0.114 * $cB.B) / 255.0

                $pixelsA[$idx] = $lumA
                $pixelsB[$idx] = $lumB

                $diffSum += [Math]::Abs($lumA - $lumB)
                $idx++
            }
        }

        $bmpA.Dispose()
        $bmpB.Dispose()

        # Normalized mean absolute error
        $mae = $diffSum / $totalPixels
        $similarity = [Math]::Max(0.0, (1.0 - $mae))

        # Also calculate Pearson correlation coefficient
        $meanA = 0.0; $meanB = 0.0
        foreach ($p in $pixelsA) { $meanA += $p }
        foreach ($p in $pixelsB) { $meanB += $p }
        $meanA /= $totalPixels; $meanB /= $totalPixels

        $num = 0.0; $denA = 0.0; $denB = 0.0
        for ($i = 0; $i -lt $totalPixels; $i++) {
            $dA = $pixelsA[$i] - $meanA
            $dB = $pixelsB[$i] - $meanB
            $num += $dA * $dB
            $denA += $dA * $dA
            $denB += $dB * $dB
        }

        $corr = 0.0
        if ($denA -gt 0 -and $denB -gt 0) {
            $corr = $num / ([Math]::Sqrt($denA) * [Math]::Sqrt($denB))
        }

        # Combined Match Score: 50% Similarity + 50% Positive Correlation
        $normCorr = [Math]::Max(0.0, $corr)
        $finalScore = ($similarity * 0.5 + $normCorr * 0.5) * 100.0

        return @{
            Success = $true
            MatchRate = [Math]::Round($finalScore, 1)
            Similarity = [Math]::Round($similarity * 100, 1)
            Correlation = [Math]::Round($normCorr * 100, 1)
            RatioA = [Math]::Round($ratioA, 2)
            RatioB = [Math]::Round($ratioB, 2)
        }
    } finally {
        if ($imgA) { $imgA.Dispose() }
        if ($imgB) { $imgB.Dispose() }
    }
}

# Self-test on reference vs current
Write-Host "=== Image Match Verification Engine Initialized ==="

# Test 1: Identical image
$sameTest = Compute-ImageSimilarity "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\references\skt\skt_samsung_premium.png" "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\references\skt\skt_samsung_premium.png"
Write-Host "Self Match Test: MatchRate = $($sameTest.MatchRate)%"

# Test 2: Different cards (Samsung vs Hyundai)
$diffTest = Compute-ImageSimilarity "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\references\skt\skt_samsung_premium.png" "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\references\skt\skt_hyundai_m3.png"
Write-Host "Different Card Test: MatchRate = $($diffTest.MatchRate)%"
