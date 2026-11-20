$ErrorActionPreference = "Stop"
$gitExe = "C:\Program Files\Git\bin\git.exe"

$repoDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price"
Set-Location $repoDir

if (-not $env:GH_PAT) {
    Write-Host "ERROR: GH_PAT environment variable not set!"
    exit 1
}

# Double check that no files in scripts contain the token
$matched = Get-ChildItem -Path "scripts" -Filter "*.ps1" | Where-Object {
    (Get-Content $_.FullName -Raw) -match "ghp_[A-Za-z0-9]+"
}

if ($matched) {
    Write-Host "ERROR: Token still found in: $($matched.Name)"
    exit 1
}

Write-Host "Adding modified and script files..."
& $gitExe add index.html skt_cards_data.js data/ground_truth_skt_202611.json data/ground_truth_kt_202611.json PROJECT_MEMORY.md scripts/

Write-Host "Committing..."
& $gitExe commit -m "feat: enforce document-only truth for affiliate card promotions and purge unofficial coupon pack text"

Write-Host "Pushing to GitHub..."
$authUrl = "https://$($env:GH_PAT)@github.com/honesticoofficial-sketch/phone-price.git"
$cleanUrl = "https://github.com/honesticoofficial-sketch/phone-price.git"

try {
    & $gitExe remote set-url origin $authUrl
    & $gitExe push origin main
    Write-Host "SUCCESS: Push completed!"
} finally {
    & $gitExe remote set-url origin $cleanUrl
    Write-Host "CLEANUP: Remote origin restored to clean URL!"
}
