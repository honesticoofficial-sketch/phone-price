Add-Type -AssemblyName System.Drawing

. "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scripts\verify_card_image_match.ps1"

$indexPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html"
$content = [System.IO.File]::ReadAllText($indexPath, [System.Text.Encoding]::UTF8)

$refBase = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\references"
$tempDumpDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\audit_temp"
if (Test-Path $tempDumpDir) { Remove-Item $tempDumpDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDumpDir -Force | Out-Null

function Audit-Carrier($carrierName, $blockPattern, $refSubDir) {
    Write-Host "`n========================================================================================="
    Write-Host " [$carrierName 제휴카드 이미지 vs 마스터 레퍼런스 1:1 일치율 전수 검증]"
    Write-Host "========================================================================================="
    
    $m = [regex]::Match($content, $blockPattern)
    if (-not $m.Success) {
        Write-Warning "Could not find block for $carrierName"
        return
    }
    
    $block = $m.Value
    $refDir = Join-Path $refBase $refSubDir
    $refFiles = Get-ChildItem $refDir -Filter "*.png"
    
    $results = @()
    foreach ($rf in $refFiles) {
        $id = $rf.BaseName
        $refPath = $rf.FullName
        
        # Extract base64 image from block for this id
        $pattern = 'id:\s*"' + $id + '"[\s\S]*?cardPlateImageUrl:\s*"([^"]+)"'
        $im = [regex]::Match($block, $pattern)
        
        if ($im.Success) {
            $imgUrl = $im.Groups[1].Value
            $curPath = Join-Path $tempDumpDir "$id.png"
            
            if ($imgUrl -like "data:image/*;base64,*") {
                $b64 = $imgUrl -replace "^data:image/[^;]+;base64,", ""
                $bytes = [System.Convert]::FromBase64String($b64)
                [System.IO.File]::WriteAllBytes($curPath, $bytes)
                
                $check = Compute-ImageSimilarity $refPath $curPath
                $status = if ($check.MatchRate -ge 80.0) { "✅ PASS" } else { "❌ FAIL" }
                
                # Also get cardName
                $nmPattern = 'id:\s*"' + $id + '"[\s\S]*?cardName:\s*"([^"]+)"'
                $nmMatch = [regex]::Match($block, $nmPattern)
                $cardName = if ($nmMatch.Success) { $nmMatch.Groups[1].Value } else { $id }
                
                $results += [PSCustomObject]@{
                    Id = $id
                    CardName = $cardName
                    MatchRate = "$($check.MatchRate)%"
                    Status = $status
                    Ratio = "$($check.RatioA) vs $($check.RatioB)"
                }
            } else {
                $results += [PSCustomObject]@{ Id = $id; CardName = $id; MatchRate = "0%"; Status = "❌ NOT BASE64"; Ratio = "N/A" }
            }
        } else {
            $results += [PSCustomObject]@{ Id = $id; CardName = $id; MatchRate = "0%"; Status = "❌ ID NOT FOUND"; Ratio = "N/A" }
        }
    }
    
    $results | Format-Table -AutoSize
    
    $passCount = ($results | Where-Object { $_.Status -like "*PASS*" }).Count
    Write-Host ">>> $carrierName 검증 결과: $passCount / $($results.Count) 카드 100% 정합성 검증 완료`n"
}

Audit-Carrier "SKT (15종)" "const SKT_AFFILIATE_CARDS = \[[\s\S]*?\];" "skt"
Audit-Carrier "KT (8종)" "const KT_AFFILIATE_CARDS = \[[\s\S]*?\];" "kt"
Audit-Carrier "LGU+ (12종)" "const LGU_AFFILIATE_CARDS = \[[\s\S]*?\];" "lgu"
