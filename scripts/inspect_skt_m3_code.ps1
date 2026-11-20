$skt = Get-Content "C:\Users\User01\.gemini\antigravity\scratch\phone-price\skt_cards_data.js" -Raw

# Inspect skt_hyundai_m3 block
$pos1 = $skt.IndexOf('id: "skt_hyundai_m3",')
Write-Host "skt_hyundai_m3 position: $pos1"
if ($pos1 -ge 0) {
    $sub1 = $skt.Substring($pos1, 2000)
    Write-Host $sub1
}
