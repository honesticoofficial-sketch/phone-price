Add-Type -AssemblyName System.Drawing

$baseDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\references"
$ktDir = Join-Path $baseDir "kt"
$lguDir = Join-Path $baseDir "lgu"

if (-not (Test-Path $ktDir)) { New-Item -ItemType Directory -Path $ktDir -Force | Out-Null }
if (-not (Test-Path $lguDir)) { New-Item -ItemType Directory -Path $lguDir -Force | Out-Null }

# Extract KT cards from data/ground_truth_kt_202611.json
$ktJsonPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\ground_truth_kt_202611.json"
$ktCards = Get-Content $ktJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json

Write-Host "Extracting $($ktCards.Count) KT reference cards..."
foreach ($c in $ktCards) {
    if ($c.card_plate_image -like "data:image/*;base64,*") {
        $b64 = $c.card_plate_image -replace "^data:image/[^;]+;base64,", ""
        $bytes = [System.Convert]::FromBase64String($b64)
        $outPath = Join-Path $ktDir "$($c.id).png"
        [System.IO.File]::WriteAllBytes($outPath, $bytes)
        Write-Host "  Saved KT: $($c.id) -> $outPath"
    }
}

# Extract LGU cards from data/ground_truth_lgu_202611.json
$lguJsonPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\ground_truth_lgu_202611.json"
$lguCards = Get-Content $lguJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json

Write-Host "`nExtracting $($lguCards.Count) LGU+ reference cards..."
foreach ($c in $lguCards) {
    if ($c.card_plate_image -like "data:image/*;base64,*") {
        $b64 = $c.card_plate_image -replace "^data:image/[^;]+;base64,", ""
        $bytes = [System.Convert]::FromBase64String($b64)
        $outPath = Join-Path $lguDir "$($c.id).png"
        [System.IO.File]::WriteAllBytes($outPath, $bytes)
        Write-Host "  Saved LGU: $($c.id) -> $outPath"
    }
}

Write-Host "`nAll Reference Vaults (SKT, KT, LGU) initialized."
