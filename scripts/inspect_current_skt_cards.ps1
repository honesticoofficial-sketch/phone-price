$indexPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html"
$content = [System.IO.File]::ReadAllText($indexPath, [System.Text.Encoding]::UTF8)

# Extract SKT_AFFILIATE_CARDS array
$sktMatch = [regex]::Match($content, "const SKT_AFFILIATE_CARDS = (\[[\s\S]*?\n\]);")
if ($sktMatch.Success) {
    $sktJson = $sktMatch.Groups[1].Value
    # Replace comments if any
    $sktJsonClean = $sktJson -replace "//[^\n]*", ""
    # Parse as json
    $cards = ConvertFrom-Json $sktJsonClean
    Write-Host "Found $($cards.Count) SKT cards in index.html:"
    
    $outDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\current_skt_images"
    if (Test-Path $outDir) { Remove-Item $outDir -Recurse -Force }
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    
    $index = 0
    foreach ($c in $cards) {
        $index++
        $imgLen = if ($c.cardPlateImageUrl) { $c.cardPlateImageUrl.Length } else { 0 }
        $imgStart = if ($c.cardPlateImageUrl) { $c.cardPlateImageUrl.Substring(0, [Math]::Min(30, $c.cardPlateImageUrl.Length)) } else { "none" }
        Write-Host "$index. [$($c.id)] $($c.cardName) ($($c.cardCompany)) - Type: $($c.type), ImgLen: $imgLen, Start: $imgStart"
        
        # Save base64 image if valid
        if ($c.cardPlateImageUrl -like "data:image/*;base64,*") {
            $base64 = $c.cardPlateImageUrl -replace "^data:image/[^;]+;base64,", ""
            $bytes = [System.Convert]::FromBase64String($base64)
            $imgPath = Join-Path $outDir "$($c.id).png"
            [System.IO.File]::WriteAllBytes($imgPath, $bytes)
        }
    }
} else {
    Write-Host "Could not find SKT_AFFILIATE_CARDS"
}
