$git = "C:\Program Files\Git\cmd\git.exe"
$repoPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price"
Set-Location $repoPath

$token = "$env:GH_PAT"
$cleanUrl = "https://github.com/honesticoofficial-sketch/phone-price.git"
$authUrl = "https://$token@github.com/honesticoofficial-sketch/phone-price.git"

try {
    & $git remote set-url origin $authUrl
    & $git push origin main
    Write-Host "Push completed successfully."
} finally {
    & $git remote set-url origin $cleanUrl
    Write-Host "Remote URL securely reset to clean URL."
}

