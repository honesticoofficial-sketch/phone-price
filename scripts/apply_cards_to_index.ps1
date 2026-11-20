[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

$workspace = "C:\Users\User01\.gemini\antigravity\scratch\phone-price"
$indexHtmlPath = Join-Path $workspace "index.html"
$backupPath = Join-Path $workspace "index.html.bak_20261120_cards"

# 1. 백업 생성
Write-Host "1. index.html 백업 생성 중..."
Copy-Item -Path $indexHtmlPath -Destination $backupPath -Force
Write-Host "   백업 완료: $backupPath"

# 2. 임시 JS 블록 로드
$sktJs = Get-Content (Join-Path $workspace "scratch\skt_cards_new.js") -Raw -Encoding UTF8
$ktJs = Get-Content (Join-Path $workspace "scratch\kt_cards_new.js") -Raw -Encoding UTF8
$lguJs = Get-Content (Join-Path $workspace "scratch\lgu_cards_new.js") -Raw -Encoding UTF8

$combinedCardsJs = "$sktJs`n`n$ktJs`n`n$lguJs"

# 3. index.html 읽기
Write-Host "2. index.html 읽기 및 카드 영역 교체 중..."
$lines = Get-Content $indexHtmlPath -Encoding UTF8

# 라인 7116까지 (0부터 7115 인덱스)
$beforeLines = $lines[0..7115]

# 라인 9277부터 끝까지 (9276 인덱스부터 끝)
$afterLines = $lines[9276..($lines.Count - 1)]

Write-Host "   Before lines count: $($beforeLines.Count)"
Write-Host "   After lines count: $($afterLines.Count)"
Write-Host "   After first line: $($afterLines[0]) (expecting empty line or comments)"
Write-Host "   After second line: $($afterLines[1]) (expecting const AFFILIATE_CARDS_BY_CARRIER = {)"

# 새 내용 결합
$newContent = ($beforeLines -join "`n") + "`n" + $combinedCardsJs + "`n" + ($afterLines -join "`n")

# index.html에 저장
Write-Host "3. index.html 덮어쓰기 저장 중..."
$newContent | Set-Content $indexHtmlPath -Encoding UTF8

Write-Host "4. 결과 검증 중..."
$verifyLines = Get-Content $indexHtmlPath -Encoding UTF8
Write-Host "   새 index.html 총 라인 수: $($verifyLines.Count)"

# 중요 라인 확인
for ($i = 0; $i -lt $verifyLines.Count; $i++) {
    $l = $verifyLines[$i]
    if ($l -match 'const SKT_AFFILIATE_CARDS =|const KT_AFFILIATE_CARDS =|const LGU_AFFILIATE_CARDS =|const AFFILIATE_CARDS_BY_CARRIER =') {
        Write-Host "   Line $($i+1): $($l.Trim())"
    }
}

Write-Host "반영 성공 완료!"
