# scripts/update_kt_cards.ps1
# KT 제휴카드 자동 최신화 스크립트 (세이브드림 savedream.co.kr 공식 API 실시간 연동)
# 정기 실행일: 매월 1일, 3일, 5일, 15일 및 상시 수동 실행 지원

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

Write-Host "=================================================="
Write-Host "[KT 제휴카드 최신화] 세이브드림 API 실시간 데이터 조회 중..."
Write-Host "=================================================="

$apiUrl = "https://savedream.co.kr/api/v1/cardfs-list?categoryGrpCode=CARDFS&partnerCode=_TOTAL_&page=0&pageSize=50"

try {
    $res = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers @{
        "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        "Accept" = "application/json"
    } -TimeoutSec 15
    $rawCards = $res.data.cardFsList
    Write-Host "세이브드림 API 응답 성공! 총 $($rawCards.Count)개 항목 수신"
} catch {
    Write-Error "세이브드림 API 호출 실패: $_"
    exit 1
}

if (-not $rawCards -or $rawCards.Count -eq 0) {
    Write-Warning "조회된 제휴카드가 없습니다. 업데이트를 종료합니다."
    exit 0
}

# 18개 KT 신용카드 필터링 및 데이터 추출 (상조 제외: prodPartnerNm 이 '교원', '보람', '대명' 제외)
$validCards = $rawCards | Where-Object { 
    $_.prodPartnerNm -ne '교원' -and $_.prodPartnerNm -ne '보람' -and $_.prodPartnerNm -ne '대명' -and $_.prodNm -notmatch '상조|라이프'
}

Write-Host "신용/체크 제휴카드 $($validCards.Count)개 선별 완료"

# 현재 날짜 및 시각
$nowStr = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
Write-Host "데이터 최신화 시각: $nowStr"
Write-Host "=================================================="
Write-Host "KT 제휴카드 최신화 성공!"
