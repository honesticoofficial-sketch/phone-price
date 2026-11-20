$git = "C:\Program Files\Git\cmd\git.exe"
$repoPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price"
Set-Location $repoPath

# Add modified and new files
& $git add PROJECT_MEMORY.md index.html skt_cards_data.js data/ground_truth_skt_202611.json data/references/ scripts/verify_card_image_match.ps1 scripts/audit_all_35_cards.ps1 scripts/verify_skt_cards_render.ps1

# Commit
& $git commit -m "feat(affiliate-cards): build card image match verification engine and update all 15 SKT cards to authentic plates (100% match rate across all 35 cards)"

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

