$c = [System.IO.File]::ReadAllText('C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html', [System.Text.Encoding]::UTF8)

$p1 = $c.IndexOf('id="cardPlateBox"')
Write-Host $c.Substring($p1 - 100, 700)
