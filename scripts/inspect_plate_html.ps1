$c = [System.IO.File]::ReadAllText('C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html', [System.Text.Encoding]::UTF8)

$p1 = $c.IndexOf("function renderCardPreview(")
$pPlate = $c.IndexOf("cardPlateImageUrl", $p1)
Write-Host "cardPlateImageUrl in renderCardPreview found at: $pPlate"
if ($pPlate -gt 0) {
    Write-Host $c.Substring($pPlate - 300, 1500)
}
