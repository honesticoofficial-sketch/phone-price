$items = @(
    @{ Name = "NH_LGU_Allone.png"; Url = "https://vertical.pstatic.net/vertical-cardad/creatives/NH/10664/NH_10664_20260619-091553_hor.png" },
    @{ Name = "WR_LGU_Card.png"; Url = "https://vertical.pstatic.net/vertical-cardad/creatives/WR/10045/WR_10045_20210305-164718_hor.png" },
    @{ Name = "LO_LGU_DC.png"; Url = "https://vertical.pstatic.net/vertical-cardad/creatives/LO/10739/LO_10739_20261106-093523_ver.png" },
    @{ Name = "HD_LGU_Card.png"; Url = "https://vertical.pstatic.net/vertical-cardad/creatives/HD/10322/HD_10322_20250212-112347_ver.png" }
)

$outDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\test_download_lgu"
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

foreach ($it in $items) {
    $outPath = Join-Path $outDir $it.Name
    try {
        Invoke-WebRequest -Uri $it.Url -OutFile $outPath -UserAgent "Mozilla/5.0"
        Write-Host "Downloaded $($it.Name) ($((Get-Item $outPath).Length) bytes)"
    } catch {
        Write-Host "Failed $($it.Name): $_"
    }
}
