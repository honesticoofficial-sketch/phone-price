$items = @(
    @{ Name = "woori_u_x.png"; Url = "https://static.toss.im/assets/credit-card/credit-card-new/woori_U_X_%EC%9A%B0%EB%A6%AC%EC%B9%B4%EB%93%9C.png" },
    @{ Name = "lgu_hyundai_m3.png"; Url = "https://static.toss.im/assets/credit-card/1907.png" },
    @{ Name = "lgu_loca.png"; Url = "https://static.toss.im/assets/credit-card/2123.png" },
    @{ Name = "uplus_family_hana.png"; Url = "https://static.toss.im/assets/credit-card/1643.png" }
)

$outDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\toss_lgu_imgs"
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

foreach ($it in $items) {
    $outPath = Join-Path $outDir $it.Name
    Invoke-WebRequest -Uri $it.Url -OutFile $outPath -UserAgent "Mozilla/5.0"
    Write-Host "Downloaded $($it.Name) ($((Get-Item $outPath).Length) bytes)"
}
