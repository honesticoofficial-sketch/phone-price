Add-Type -AssemblyName System.Drawing

. "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scripts\verify_card_image_match.ps1"

$refDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\references\skt"
$currentDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\current_skt_images"

$cards = @(
    @{ Id="skt_samsung_premium"; Name="삼성카드 T PREMIUM" },
    @{ Id="skt_hyundai_m3"; Name="현대카드 M3 T라이트2" },
    @{ Id="skt_nh_tlight"; Name="NH카드 T라이트" },
    @{ Id="skt_samsung_tlight"; Name="삼성카드 T라이트" },
    @{ Id="skt_hana_tdown"; Name="하나카드 T다운" },
    @{ Id="skt_woori_tlight"; Name="우리카드 T라이트" },
    @{ Id="skt_kb_tlight"; Name="T라이트 KB국민카드" },
    @{ Id="skt_lotte_tlight"; Name="롯데카드 T 라이트" },
    @{ Id="skt_shinhan_tlight"; Name="신한카드 T라이트" },
    @{ Id="skt_shinhan_pineapple"; Name="신한카드 파인애플" },
    @{ Id="skt_shinhan_tlife"; Name="신한카드 T&LIFE" },
    @{ Id="skt_kb_teconomy"; Name="T-economy KB국민카드" },
    @{ Id="skt_hyundai_m3_bill"; Name="현대카드 M3 통신할인형2.0" },
    @{ Id="skt_lotte_tello"; Name="TELLO NE 롯데카드" },
    @{ Id="skt_samsung_tnana"; Name="삼성카드 T나는혜택" }
)

Write-Host "`n========================================================================================="
Write-Host " [SKT 제휴카드 15종 현행 이미지 vs 원본 정답지 1:1 일치율 감사 리포트]"
Write-Host "========================================================================================="

$results = @()
foreach ($c in $cards) {
    $refPath = Join-Path $refDir "$($c.Id).png"
    $curPath = Join-Path $currentDir "$($c.Id).png"
    
    $check = Compute-ImageSimilarity $refPath $curPath
    $status = if ($check.MatchRate -ge 80.0) { "✅ PASS" } else { "❌ MISMATCH (FAIL)" }
    
    $results += [PSCustomObject]@{
        Id = $c.Id
        CardName = $c.Name
        MatchRate = "$($check.MatchRate)%"
        Status = $status
        Reason = if ($check.Reason) { $check.Reason } else { "OK" }
    }
}

$results | Format-Table -AutoSize
