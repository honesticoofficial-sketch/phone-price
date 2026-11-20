$c = [System.IO.File]::ReadAllText('C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html', [System.Text.Encoding]::UTF8)

$pQr = $c.IndexOf("발급신청 QR")
if ($pQr -gt 0) {
    Write-Host $c.Substring($pQr - 700, 450)
}
