$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

function Check-CardImages($filePath, $carrierName) {
    $content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
    $cardMatches = [regex]::Matches($content, '(?s)\{\s*id:\s*"([^"]+)",[\s\S]*?(?=\n  \{|\n\];|\Z)')
    
    $results = @()
    foreach ($m in $cardMatches) {
        $block = $m.Value
        $id = if ($block -match 'id:\s*"([^"]+)"') { $matches[1] } else { "" }
        $company = if ($block -match 'cardCompany:\s*"([^"]+)"') { $matches[1] } else { "" }
        $name = if ($block -match 'cardName:\s*"([^"]+)"') { $matches[1] } else { "" }
        $orientation = if ($block -match 'cardPlateOrientation:\s*"([^"]+)"') { $matches[1] } else { "" }
        $imgUrl = if ($block -match 'cardPlateImageUrl:\s*"([^"]+)"') { $matches[1] } else { "" }
        
        $width = 0
        $height = 0
        $ratio = 0
        $realType = "UNKNOWN"
        $isMismatch = $false
        
        if ($imgUrl -match '^data:image/[^;]+;base64,(.+)$') {
            try {
                $base64 = $matches[1]
                $bytes = [Convert]::FromBase64String($base64)
                $ms = New-Object System.IO.MemoryStream(,$bytes)
                $img = [System.Drawing.Image]::FromStream($ms)
                $width = $img.Width
                $height = $img.Height
                $ratio = [Math]::Round($width / $height, 2)
                $realType = if ($height -gt $width) { "vertical" } else { "horizontal" }
                $isMismatch = ($orientation -ne $realType)
                $img.Dispose()
                $ms.Dispose()
            } catch {}
        } elseif ($imgUrl -match '^https?://') {
            $realType = "REMOTE_URL"
        }
        
        $results += [PSCustomObject]@{
            Carrier = $carrierName
            Id = $id
            Company = $company
            Name = $name
            Orientation = $orientation
            Width = $width
            Height = $height
            Ratio = $ratio
            RealType = $realType
            IsMismatch = $isMismatch
            ImgType = if ($imgUrl -match '^data:') { "BASE64" } else { "URL" }
        }
    }
    return $results
}

$skt = Check-CardImages "C:\Users\User01\.gemini\antigravity\scratch\phone-price\skt_cards_data.js" "SKT"
$kt = Check-CardImages "C:\Users\User01\.gemini\antigravity\scratch\phone-price\kt_cards_data.js" "KT"
$lgu = Check-CardImages "C:\Users\User01\.gemini\antigravity\scratch\phone-price\lgu_cards_data.js" "LGU"

$all = $skt + $kt + $lgu
Write-Host "=================================================================="
Write-Host "총 분석 카드 수: $($all.Count)"
Write-Host "=================================================================="

Write-Host "`n[불일치 카드 (orientation != 실제 이미지 비율)]"
$mismatches = $all | Where-Object { $_.IsMismatch }
Write-Host "불일치 건수: $($mismatches.Count)"
foreach ($c in $mismatches) {
    Write-Host " ⚠️ [$($c.Carrier)] $($c.Id) ($($c.Name)): 설정=$($c.Orientation), 실제크기=$($c.Width)x$($c.Height) (실제=$($c.RealType), 비율=$($c.Ratio))"
}

Write-Host "`n[전체 카드 규격 요약]"
foreach ($c in $all) {
    Write-Host " - [$($c.Carrier)] $($c.Id): 설정=$($c.Orientation), 실제=$($c.Width)x$($c.Height) ($($c.RealType), $($c.ImgType))"
}
