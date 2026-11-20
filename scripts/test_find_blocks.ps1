$c = [System.IO.File]::ReadAllText('C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html', [System.Text.Encoding]::UTF8)
Write-Host "SKT block index:" $c.IndexOf('const SKT_AFFILIATE_CARDS = [')
Write-Host "KT block index:" $c.IndexOf('const KT_AFFILIATE_CARDS = [')
