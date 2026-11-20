$files = @(
    "C:\Users\User01\.gemini\antigravity\scratch\phone-price\skt_cards_data.js",
    "C:\Users\User01\.gemini\antigravity\scratch\phone-price\lgu_cards_data.js",
    "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html",
    "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\ground_truth_kt_202611.json",
    "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\ground_truth_skt_202611.json",
    "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\ground_truth_lgu_202611.json"
)

foreach ($f in $files) {
    if (Test-Path $f) {
        $lines = Get-Content $f
        Write-Host "=== FILE: $(Split-Path $f -Leaf) ==="
        for ($i=0; $i -lt $lines.Length; $i++) {
            $line = $lines[$i]
            if ($line -match "쿠폰|투썸|다이소|올리브영") {
                Write-Host "  Line $($i+1): $($line.Trim())"
            }
        }
    }
}
