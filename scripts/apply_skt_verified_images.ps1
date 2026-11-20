Add-Type -AssemblyName System.Drawing

$indexPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html"
$content = [System.IO.File]::ReadAllText($indexPath, [System.Text.Encoding]::UTF8)

$refDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\references\skt"

$cardsToUpdate = @(
    @{ Id="skt_samsung_premium"; Orient="horizontal" },
    @{ Id="skt_hyundai_m3"; Orient="vertical" },
    @{ Id="skt_nh_tlight"; Orient="horizontal" },
    @{ Id="skt_samsung_tlight"; Orient="horizontal" },
    @{ Id="skt_hana_tdown"; Orient="horizontal" },
    @{ Id="skt_woori_tlight"; Orient="vertical" },
    @{ Id="skt_kb_tlight"; Orient="horizontal" },
    @{ Id="skt_lotte_tlight"; Orient="horizontal" },
    @{ Id="skt_shinhan_tlight"; Orient="horizontal" },
    @{ Id="skt_shinhan_pineapple"; Orient="horizontal" },
    @{ Id="skt_shinhan_tlife"; Orient="vertical" },
    @{ Id="skt_kb_teconomy"; Orient="horizontal" },
    @{ Id="skt_hyundai_m3_bill"; Orient="vertical" },
    @{ Id="skt_lotte_tello"; Orient="vertical" },
    @{ Id="skt_samsung_tnana"; Orient="vertical" }
)

Write-Host "Updating SKT cards in index.html with verified reference images..."

foreach ($c in $cardsToUpdate) {
    $refFile = Join-Path $refDir "$($c.Id).png"
    if (Test-Path $refFile) {
        $bytes = [System.IO.File]::ReadAllBytes($refFile)
        $b64 = [System.Convert]::ToBase64String($bytes)
        $dataUri = "data:image/png;base64,$b64"
        
        # Regex to match cardPlateImageUrl for this card
        # Find { id: "skt_xxx" ... cardPlateImageUrl: "..."
        $pattern = '(\{\s*id:\s*"' + $c.Id + '"[\s\S]*?cardPlateImageUrl:\s*")[^"]*("[\s\S]*?cardPlateOrientation:\s*")[^"]*(")'
        
        if ($content -match $pattern) {
            $content = [regex]::Replace($content, $pattern, "${1}$dataUri${2}$($c.Orient)${3}")
            Write-Host "  Replaced for $($c.Id) (Orientation: $($c.Orient), Image Size: $($bytes.Length) bytes)"
        } else {
            Write-Warning "  Could not match pattern for $($c.Id)"
        }
    }
}

[System.IO.File]::WriteAllText($indexPath, $content, [System.Text.Encoding]::UTF8)
Write-Host "index.html updated successfully with 15 SKT authentic card images!"
