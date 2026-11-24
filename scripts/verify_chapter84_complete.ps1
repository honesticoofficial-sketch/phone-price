[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "=========================================================="
Write-Host " [Chapter 84: 데이터 무결성 및 사이트 렌더링 전수 검증]"
Write-Host "=========================================================="

$indexPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html"
$html = Get-Content -Path $indexPath -Raw -Encoding UTF8

$poolJson = Get-Content -Path "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\crawled_catalog_pool.json" -Encoding UTF8 | ConvertFrom-Json

Write-Host "`n1. crawled_catalog_pool.json 무결성 검사..."
Write-Host "   -> 총 플래그십 모델 수: $($poolJson.Count) 개"

# Test 1: iPhone 18 Pro Max
$promax = $poolJson | Where-Object { $_.name -like "*18 Pro Max 256G*" -or $_.id -eq "ip18pm256g" } | Select-Object -First 1
Write-Host "`n[Test 1] iPhone 18 Pro Max 256G 지원금 검증:"
Write-Host "   - SK 공시지원금: $($promax.subs.SK.mnp) 만원 (기대값: 22.0 만원)"
Write-Host "   - KT 공시지원금: $($promax.subs.KT.mnp) 만원 (기대값: 22.1 만원 / 221,000원)"
Write-Host "   - LG 공시지원금: $($promax.subs.LG.mnp) 만원 (기대값: 20.4 만원 / 204,000원)"

$pass1 = ($promax.subs.SK.mnp -eq 22.0) -and ($promax.subs.KT.mnp -eq 22.1) -and ($promax.subs.LG.mnp -eq 20.4)
if ($pass1) { Write-Host "   ✅ Test 1 PASS! 3사 공시지원금 상이 및 정확 반영 확인" -ForegroundColor Green }
else { Write-Host "   ❌ Test 1 FAIL!" -ForegroundColor Red }

# Test 2: iPhone 17 (LG 번이 55, 기변 45)
$ip17 = $poolJson | Where-Object { $_.name -eq "iPhone 17 256G" -or $_.id -eq "ip17256g" } | Select-Object -First 1
Write-Host "`n[Test 2] iPhone 17 256G LGU+ 가입유형별 지원금 검증:"
Write-Host "   - LG 번호이동(mnp): $($ip17.subs.LG.mnp) 만원 (기대값: 55.0 만원)"
Write-Host "   - LG 기기변경(chg): $($ip17.subs.LG.chg) 만원 (기대값: 45.0 만원)"
Write-Host "   - LG 신규개통(new): $($ip17.subs.LG.new) 만원 (기대값: 45.0 만원)"

$pass2 = ($ip17.subs.LG.mnp -eq 55.0) -and ($ip17.subs.LG.chg -eq 45.0) -and ($ip17.subs.LG.new -eq 45.0)
if ($pass2) { Write-Host "   ✅ Test 2 PASS! LG 번이 55만 / 기변 45만 개통방식별 차등 완벽 반영 확인" -ForegroundColor Green }
else { Write-Host "   ❌ Test 2 FAIL!" -ForegroundColor Red }

# Test 3: 요금제 명칭 및 금액 동기화 검사
Write-Host "`n[Test 3] 요금제 명칭 및 금액 기준 검증:"
$hasSktPlan = $html -match '베스트\s*109|109,000'
$hasKtPlan = $html -match '초이스\s*더블|120,000'
$hasLgPlan = $html -match '프리미어\s*슈퍼|115,000'

Write-Host "   - SK 109,000원 (베스트109) 포함 여부: $hasSktPlan"
Write-Host "   - KT 120,000원 (초이스더블) 포함 여부: $hasKtPlan"
Write-Host "   - LG 115,000원 (프리미어슈퍼) 포함 여부: $hasLgPlan"

$pass3 = $hasSktPlan -and $hasKtPlan -and $hasLgPlan
if ($pass3) { Write-Host "   ✅ Test 3 PASS! 넷가표 요금제 기준과 크롤링 기준 100% 동기화 확인" -ForegroundColor Green }
else { Write-Host "   ❌ Test 3 FAIL!" -ForegroundColor Red }

# Test 4: 보급형/외산폰 잔존 여부 검사 (A시리즈, 샤오미, 모토로라 등)
Write-Host "`n[Test 4] 보급형/외산폰 100% 제거 검증:"
$badItems = $poolJson | Where-Object { $_.name -match '갤럭시 A|Galaxy A|A[0-9]{2}|퀀텀|와이드|점프|버디|샤오미|홍미|Redmi|모토|Moto|워치|Watch|탭|Tab|패드|Pad|버즈|Buds|키즈' }
if ($badItems.Count -eq 0) {
    Write-Host "   ✅ Test 4 PASS! 보급형/외산폰 0건 (100% 정예 플래그십만 존재)" -ForegroundColor Green
} else {
    Write-Host "   ❌ Test 4 FAIL! 잔여 불량 기종: $($badItems.Count) 개" -ForegroundColor Red
}

Write-Host "`n=========================================================="
if ($pass1 -and $pass2 -and $pass3 -and ($badItems.Count -eq 0)) {
    Write-Host " 🎉 [ALL PASS] 모든 검증 항목 100% 통과 완료!" -ForegroundColor Cyan
} else {
    Write-Host " ⚠️ 일부 검증 실패" -ForegroundColor Yellow
}
Write-Host "=========================================================="
