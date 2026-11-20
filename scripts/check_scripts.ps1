$c = [System.IO.File]::ReadAllText('C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html', [System.Text.Encoding]::UTF8)
$m = [regex]::Matches($c, '<script[^>]*src=[^>]*>')
foreach ($match in $m) { Write-Host $match.Value }
