$ErrorActionPreference = "Stop"
$gitExe = "C:\Program Files\Git\bin\git.exe"

$repoDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price"
Set-Location $repoDir

Write-Host "=== Git Status ==="
& $gitExe status

Write-Host "=== Adding files ==="
& $gitExe add index.html skt_cards_data.js data/ground_truth_skt_202611.json data/ground_truth_kt_202611.json PROJECT_MEMORY.md scripts/ scratch/

Write-Host "=== Committing ==="
& $gitExe commit -m "feat: enforce document-only truth for affiliate card promotions and purge unofficial coupon pack text"

Write-Host "=== Pushing to GitHub with PAT ==="
$pat = "$env:GH_PAT"
$authUrl = "https://${pat}@github.com/honesticoofficial-sketch/phone-price.git"
$cleanUrl = "https://github.com/honesticoofficial-sketch/phone-price.git"

try {
    & $gitExe remote set-url origin $authUrl
    & $gitExe push origin main
    Write-Host "SUCCESS: Push to origin main completed!"
} finally {
    & $gitExe remote set-url origin $cleanUrl
    Write-Host "CLEANUP: Remote origin restored to clean URL!"
}

