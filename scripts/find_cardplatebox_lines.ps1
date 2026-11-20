$c = [System.IO.File]::ReadAllText('C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html', [System.Text.Encoding]::UTF8)

$lines = $c -split "`n"
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match 'id="cardPlateBox"') {
        Write-Host "Found cardPlateBox at line $($i+1):"
        for ($j = [Math]::Max(0, $i - 5); $j -le [Math]::Min($lines.Count - 1, $i + 15); $j++) {
            Write-Host "$($j+1): $($lines[$j])"
        }
        break
    }
}
