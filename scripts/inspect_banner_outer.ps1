$c = [System.IO.File]::ReadAllText('C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html', [System.Text.Encoding]::UTF8)

$pPlate = $c.IndexOf("cardPlateBox")
if ($pPlate -gt 0) {
    Write-Host $c.Substring($pPlate - 1000, 700)
}
