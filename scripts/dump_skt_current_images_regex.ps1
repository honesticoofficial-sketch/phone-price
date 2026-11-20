Add-Type -AssemblyName System.Drawing

$indexPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html"
$content = [System.IO.File]::ReadAllText($indexPath, [System.Text.Encoding]::UTF8)

$startMarker = "const SKT_AFFILIATE_CARDS = ["
$endMarker = "const KT_AFFILIATE_CARDS = ["

$p1 = $content.IndexOf($startMarker)
$p2 = $content.IndexOf($endMarker, $p1)

$sktBlock = $content.Substring($p1, $p2 - $p1)

$outDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\current_skt_images"
if (Test-Path $outDir) { Remove-Item $outDir -Recurse -Force }
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$lines = $sktBlock -split "`n"
$results = @()
$currCard = $null

foreach ($line in $lines) {
    if ($line -match 'id:\s*"([^"]+)"') {
        if ($currCard) { $results += $currCard }
        $currCard = [PSCustomObject]@{
            Id = $matches[1]
            CardName = ""
            Company = ""
            ImgUrl = ""
        }
    } elseif ($currCard) {
        if ($line -match 'cardName:\s*"([^"]+)"') {
            $currCard.CardName = $matches[1]
        } elseif ($line -match 'cardCompany:\s*"([^"]+)"') {
            $currCard.Company = $matches[1]
        } elseif ($line -match 'cardPlateImageUrl:\s*"([^"]+)"') {
            $currCard.ImgUrl = $matches[1]
        }
    }
}
if ($currCard) { $results += $currCard }

Write-Host "Found $($results.Count) SKT cards."
$idx = 0
$table = @()
foreach ($c in $results) {
    $idx++
    $w = 0; $h = 0; $ratio = 0
    if ($c.ImgUrl -like "data:image/*;base64,*") {
        $base64 = $c.ImgUrl -replace "^data:image/[^;]+;base64,", ""
        $bytes = [System.Convert]::FromBase64String($base64)
        $savePath = Join-Path $outDir "$($c.Id).png"
        [System.IO.File]::WriteAllBytes($savePath, $bytes)
        $bmp = [System.Drawing.Image]::FromFile($savePath)
        $w = $bmp.Width
        $h = $bmp.Height
        $ratio = [Math]::Round($w / $h, 2)
        $bmp.Dispose()
    }
    $table += [PSCustomObject]@{
        Index = $idx
        Id = $c.Id
        Company = $c.Company
        CardName = $c.CardName
        Width = $w
        Height = $h
        Ratio = $ratio
        ImgLen = $c.ImgUrl.Length
    }
}

$table | Format-Table -AutoSize
