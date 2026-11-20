$pdfPath = "C:\Users\User01\.gemini\antigravity\brain\af18e558-85da-49ae-9eb0-4c9b6d7b02ae\.user_uploaded\media_1795153661234_0b7c7c83.pdf"
$bytes = [System.IO.File]::ReadAllBytes($pdfPath)
Write-Host "Total Bytes: $($bytes.Length)"

$outDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\pdf_extracted_imgs"
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

$jpgOffsets = [System.Collections.Generic.List[int]]::new()
for ($i = 0; $i -lt $bytes.Length - 3; $i++) {
    if ($bytes[$i] -eq 0xFF -and $bytes[$i+1] -eq 0xD8 -and $bytes[$i+2] -eq 0xFF) {
        $jpgOffsets.Add($i)
    }
}
Write-Host "Found JPEG markers: $($jpgOffsets.Count)"

for ($k = 0; $k -lt $jpgOffsets.Count; $k++) {
    $start = $jpgOffsets[$k]
    # find FF D9
    $end = -1
    for ($j = $start + 3; $j -lt $bytes.Length - 1; $j++) {
        if ($bytes[$j] -eq 0xFF -and $bytes[$j+1] -eq 0xD9) {
            $end = $j + 2
            break
        }
    }
    if ($end -gt $start) {
        $len = $end - $start
        if ($len -gt 1000) { # filter tiny icons
            $imgBytes = New-Object byte[] $len
            [System.Array]::Copy($bytes, $start, $imgBytes, 0, $len)
            $outPath = Join-Path $outDir "img_$($k)_len_$($len).jpg"
            [System.IO.File]::WriteAllBytes($outPath, $imgBytes)
            Write-Host "Saved JPEG $outPath ($len bytes)"
        }
    }
}
