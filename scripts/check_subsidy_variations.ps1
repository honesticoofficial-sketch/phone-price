[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$dataPath = Join-Path $PSScriptRoot "..\data\crawled_subsidies_latest.json"
$specialPath = Join-Path $PSScriptRoot "..\data\special_models.json"

Write-Host "=========================================================="
Write-Host "       공시지원금 / 출고가 변동 및 특수모델 점검 보고서"
Write-Host "==========================================================`n"

if (-not (Test-Path $dataPath)) {
    Write-Host "[오류] 최신 크롤링 데이터가 없습니다. scripts/crawl_carrier_subsidies.ps1을 먼저 실행하세요."
    exit 1
}

$crawled = Get-Content $dataPath -Raw -Encoding UTF8 | ConvertFrom-Json

# 1. 특수 모델 자동 점검 (S26 NEW 등)
Write-Host "▶ [1] 특수 관리 모델 점검 (자동 삭제 조건 모니터링)"
Write-Host "----------------------------------------------------------"
if (Test-Path $specialPath) {
    $specialData = Get-Content $specialPath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($sm in $specialData.specialModels) {
        Write-Host "모델명: $($sm.model)"
        Write-Host "현재 설정: 출고가 $("{0:N0}" -f $sm.factoryPrice)원 / 공시 $("{0:N0}" -f $sm.subsidy.mnp)원"
        
        if ($sm.autoRetireRule -and $sm.autoRetireRule.enabled) {
            $targetPrice = $sm.autoRetireRule.targetFactoryPrice
            Write-Host "자동 삭제 조건: 3사 S26 일반모델 공식 출고가가 모두 $("{0:N0}" -f $targetPrice)원으로 변경 시"
            
            # 크롤링 데이터에서 S26 일반모델 출고가 확인
            $sktS26 = $crawled.skt | Where-Object { $_.model -like "*S26 256*" } | Select-Object -First 1
            $ktS26 = $crawled.kt | Where-Object { $_.model -like "*S26*" -and $_.model -notlike "*Ultra*" -and $_.model -notlike "*+*" } | Select-Object -First 1
            $lguS26 = $crawled.lgu | Where-Object { $_.model -like "*S26 256*" } | Select-Object -First 1

            $sktPrice = if ($sktS26) { $sktS26.factoryPrice } else { 0 }
            $ktPrice = if ($ktS26) { $ktS26.factoryPrice } else { 0 }
            $lguPrice = if ($lguS26) { $lguS26.factoryPrice } else { 0 }

            Write-Host "  - SKT 공식 출고가 : $("{0:N0}" -f $sktPrice)원"
            Write-Host "  - KT 공식 출고가  : $("{0:N0}" -f $ktPrice)원"
            Write-Host "  - LGU+ 공식 출고가: $("{0:N0}" -f $lguPrice)원"

            $allMatched = ($sktPrice -eq $targetPrice) -and ($lguPrice -eq $targetPrice)
            if ($allMatched) {
                Write-Host "`n[★ 알림] 통신사 공식 출고가가 $("{0:N0}" -f $targetPrice)원으로 모두 변경되었습니다!" -ForegroundColor Green
                Write-Host ">> 조건 만족: S26 NEW 모델을 자동 삭제/정리할 수 있습니다.`n"
            } else {
                Write-Host "`n[상태] 아직 3사 출고가가 $("{0:N0}" -f $targetPrice)원으로 일괄 변경되지 않았습니다." -ForegroundColor Yellow
                Write-Host ">> 결과: S26 NEW 특수 모델을 별도 목록에 안전하게 계속 유지합니다.`n"
            }
        }
    }
}

Write-Host "=========================================================="
