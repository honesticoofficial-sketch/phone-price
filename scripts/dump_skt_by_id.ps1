Add-Type -AssemblyName System.Drawing

$indexPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html"
$content = [System.IO.File]::ReadAllText($indexPath, [System.Text.Encoding]::UTF8)

$p1 = $content.IndexOf("const SKT_AFFILIATE_CARDS = [")
$p2 = $content.IndexOf("const KT_AFFILIATE_CARDS = [")
$sktBlock = $content.Substring($p1, $p2 - $p1)

$outDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\current_skt_images"
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

$cardIds = @(
    "skt_samsung_premium",
    "skt_hyundai_m3",
    "skt_nh_tlight",
    "skt_samsung_tlight",
    "skt_hana_tdown",
    "skt_woori_tlight",
    "skt_kb_tlight",
    "skt_lotte_tlight",
    "skt_shinhan_tlight",
    "skt_shinhan_pineapple",
    "skt_shinhan_tlife",
    "skt_kb_teconomy",
    "skt_hyundai_m3_bill",
    "skt_lotte_tello",
    "skt_samsung_tnana"
)

$table = @()
foreach ($id in $cardIds) {
    # Match cardPlateImageUrl for this id
    $pattern = 'id:\s*"' + $id + '"[\s\S]*?cardPlateImageUrl:\s*"([^"]+)"'
    $m = [regex]::Match($sktBlock, $pattern)
    if ($m.Success) {
        $imgUrl = $m.Groups[1].Value
        $w = 0; $h = 0; $ratio = 0
        if ($imgUrl -like "data:image/*;base64,*") {
            $base64 = $imgUrl -replace "^data:image/[^;]+;base64,", ""
            $bytes = [System.Convert]::FromBase64String($base64)
            $savePath = Join-Path $outDir "$id.png"
            [System.IO.File]::WriteAllBytes($savePath, $bytes)
            $bmp = [System.Drawing.Image]::FromFile($savePath)
            $w = $bmp.Width
            $h = $bmp.Height
            $ratio = [Math]::Round($w / $h, 2)
            $bmp.Dispose()
        }
        $table += [PSCustomObject]@{
            Id = $id
            Width = $w
            Height = $h
            Ratio = $ratio
            ImgLen = $imgUrl.Length
        }
    } else {
        Write-Warning "Could not match $id"
    }
}

$table | Format-Table -AutoSize
