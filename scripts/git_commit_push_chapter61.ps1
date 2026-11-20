$git = "C:\Program Files\Git\cmd\git.exe"
$repoPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price"
Set-Location $repoPath

# Add modified and new files
& $git add PROJECT_MEMORY.md index.html scripts/verify_dynamic_orientation_renders.ps1

# Commit
& $git commit -m "feat(affiliate-cards): dynamic orientation layout for vertical and horizontal card plates (Chapter 61)"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Commit succeeded. Preparing secure push..."
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
} else {
    Write-Host "Nothing to commit or commit failed."
}

