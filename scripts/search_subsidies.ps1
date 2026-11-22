param (
    [Parameter(Mandatory=$false)]
    [string]$Query = ""
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$jsonPath = Join-Path $PSScriptRoot "..\data\crawled_subsidies_latest.json"
$specialPath = Join-Path $PSScriptRoot "..\data\special_models.json"

if (-not (Test-Path $jsonPath)) {
    Write-Host "크롤링 데이터가 없습니다."
    exit 1
}

$data = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json

$all = @()
$data.skt | ForEach-Object { $all += [PSCustomObject]@{ Carrier = "SKT"; Model = $_.model; FactoryPrice = $_.factoryPrice; Subsidy = $_.subsidy; Date = $_.date; Type = "크롤링" } }
$data.kt | ForEach-Object { $all += [PSCustomObject]@{ Carrier = "KT"; Model = $_.model; FactoryPrice = $_.factoryPrice; Subsidy = $_.subsidy; Date = $_.date; Type = "크롤링" } }
$data.lgu | ForEach-Object { $all += [PSCustomObject]@{ Carrier = "LGU+"; Model = $_.model; FactoryPrice = $_.factoryPrice; Subsidy = $_.subsidy; Date = $_.date; Type = "크롤링" } }

# 특수 등록 모델 로드
if (Test-Path $specialPath) {
    $specialData = Get-Content $specialPath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($sm in $specialData.specialModels) {
        foreach ($c in $sm.carriers) {
            $all += [PSCustomObject]@{
                Carrier = $c
                Model = "$($sm.model) [특수관리]"
                FactoryPrice = $sm.factoryPrice
                Subsidy = $sm.subsidy.mnp
                Date = $sm.createdDate
                Type = "특수등록"
            }
        }
    }
}

# 중복 정리
$unique = $all | Sort-Object Carrier, Model, FactoryPrice, Subsidy -Unique

if ($Query) {
    $filtered = $unique | Where-Object { $_.Model -like "*$Query*" }
} else {
    $filtered = $unique
}

if ($filtered.Count -eq 0) {
    Write-Host "'$Query' 검색 결과가 없습니다."
} else {
    Write-Host "총 $($filtered.Count)건 검색됨 (키워드: '$Query'):`n"
    $filtered | Sort-Object Model, Carrier | Format-Table -AutoSize Carrier, Model, @{Name="출고가"; Expression={"$("{0:N0}" -f $_.FactoryPrice)원"}}, @{Name="공시지원금"; Expression={"$("{0:N0}" -f $_.Subsidy)원"}}, Date, Type | Out-String -Width 140 | Write-Host
}
