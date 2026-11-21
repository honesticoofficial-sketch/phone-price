$dir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\skt_qr_images"
Get-ChildItem $dir | Select-Object Name, Length, Extension | Format-Table -AutoSize
