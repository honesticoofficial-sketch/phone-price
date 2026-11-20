$ErrorActionPreference = "Stop"
$gitExe = "C:\Program Files\Git\bin\git.exe"

$repoDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price"
Set-Location $repoDir

# 1. Reset the commit that had the secrets
& $gitExe reset HEAD~1

# 2. Remove all tokens from all files in scripts
Get-ChildItem -Path "scripts" -Filter "*.ps1" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match "ghp_[A-Za-z0-9]+") {
        $clean = $content -replace "ghp_[A-Za-z0-9]+", "`$env:GH_PAT"
        Set-Content -Path $_.FullName -Value $clean -Encoding UTF8
        Write-Host "Sanitized: $($_.Name)"
    }
}

# 3. Check git status
& $gitExe status
