$c = [System.IO.File]::ReadAllText('C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html', [System.Text.Encoding]::UTF8)

# Find function renderCardPreview
$p1 = $c.IndexOf("function renderCardPreview(")
Write-Host "renderCardPreview found at: $p1"
if ($p1 -gt 0) {
    Write-Host $c.Substring($p1, 1500)
}
