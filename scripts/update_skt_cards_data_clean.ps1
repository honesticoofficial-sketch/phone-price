$sktDataPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\skt_cards_data.js"
$text = [System.IO.File]::ReadAllText($sktDataPath, [System.Text.Encoding]::UTF8)

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

Write-Host "Updating cards in skt_cards_data.js..."

foreach ($c in $cardsToUpdate) {
    $refFile = Join-Path $refDir "$($c.Id).png"
    if (-not (Test-Path $refFile)) {
        Write-Warning "Missing ref: $($c.Id)"
        continue
    }

    $bytes = [System.IO.File]::ReadAllBytes($refFile)
    $b64 = [System.Convert]::ToBase64String($bytes)
    $newUri = "data:image/png;base64,$b64"

    # Find the position of id: "skt_xxx"
    $idNeedle = 'id: "' + $c.Id + '"'
    $posId = $text.IndexOf($idNeedle)
    if ($posId -lt 0) {
        Write-Warning "Could not find $idNeedle"
        continue
    }

    # Find the next card or end of array to restrict scope
    $nextCardPos = $text.IndexOf('id: "skt_', $posId + 10)
    if ($nextCardPos -lt 0) { $nextCardPos = $text.Length }

    $cardChunk = $text.Substring($posId, $nextCardPos - $posId)

    # In this chunk, replace cardPlateImageUrl: "..."
    $imgRegex = [regex]'cardPlateImageUrl:\s*"[^"]*"'
    if ($imgRegex.IsMatch($cardChunk)) {
        $newChunk = $imgRegex.Replace($cardChunk, "cardPlateImageUrl: `"$newUri`"", 1)
        
        # Also replace or insert cardPlateOrientation
        $orientRegex = [regex]'cardPlateOrientation:\s*"[^"]*"'
        if ($orientRegex.IsMatch($newChunk)) {
            $newChunk = $orientRegex.Replace($newChunk, "cardPlateOrientation: `"$($c.Orient)`"", 1)
        } else {
            # Insert before cardPlateImageUrl
            $newChunk = $newChunk -replace 'cardPlateImageUrl:', "cardPlateOrientation: `"$($c.Orient)`",`r`n    cardPlateImageUrl:"
        }

        # Put back into text
        $text = $text.Substring(0, $posId) + $newChunk + $text.Substring($nextCardPos)
        Write-Host "  Successfully updated $($c.Id) (Orientation: $($c.Orient), Size: $($bytes.Length) bytes)"
    } else {
        Write-Warning "Could not find cardPlateImageUrl in chunk for $($c.Id)"
    }
}

[System.IO.File]::WriteAllText($sktDataPath, $text, [System.Text.Encoding]::UTF8)
Write-Host "skt_cards_data.js completely updated!"
