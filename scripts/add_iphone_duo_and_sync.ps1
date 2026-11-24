[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

Write-Host "=========================================================="
Write-Host " [아이폰 듀오(iPhone Duo) 전 기종 카탈로그 & 넷가표 전면 탑재]"
Write-Host "=========================================================="

$root = "C:\Users\User01\.gemini\antigravity\scratch\phone-price"
$catalogPath = "$root\data\crawled_catalog_pool.json"
$subsidiesPath = "$root\data\crawled_subsidies_latest.json"
$indexPath = "$root\index.html"

# 1. crawled_catalog_pool.json 갱신
$pool = Get-Content $catalogPath -Raw -Encoding UTF8 | ConvertFrom-Json
$existingIds = $pool | ForEach-Object { $_.id }

$duoModels = @(
    @{
        id = "ipduo256g"
        name = "iPhone Duo 256G"
        prices = @{ SK = 330.0; KT = 330.0; LG = 330.0 }
        subs = @{
            SK = @{ mnp = 45.0; new = 45.0; chg = 45.0 }
            KT = @{ mnp = 45.0; new = 45.0; chg = 45.0 }
            LG = @{ mnp = 45.0; new = 45.0; chg = 45.0 }
        }
        tag = "#아이폰듀오"
        group = "IPHONE"
    },
    @{
        id = "ipduo512g"
        name = "iPhone Duo 512G"
        prices = @{ SK = 359.7; KT = 359.7; LG = 359.7 }
        subs = @{
            SK = @{ mnp = 45.0; new = 45.0; chg = 45.0 }
            KT = @{ mnp = 45.0; new = 45.0; chg = 45.0 }
            LG = @{ mnp = 45.0; new = 45.0; chg = 45.0 }
        }
        tag = "#아이폰듀오"
        group = "IPHONE"
    },
    @{
        id = "ipduo1t"
        name = "iPhone Duo 1T"
        prices = @{ SK = 419.1; KT = 419.1; LG = 419.1 }
        subs = @{
            SK = @{ mnp = 45.0; new = 45.0; chg = 45.0 }
            KT = @{ mnp = 45.0; new = 45.0; chg = 45.0 }
            LG = @{ mnp = 45.0; new = 45.0; chg = 45.0 }
        }
        tag = "#아이폰듀오"
        group = "IPHONE"
    },
    @{
        id = "ipduo2t"
        name = "iPhone Duo 2T"
        prices = @{ SK = 509.3; KT = 509.3; LG = 509.3 }
        subs = @{
            SK = @{ mnp = 45.0; new = 45.0; chg = 45.0 }
            KT = @{ mnp = 45.0; new = 45.0; chg = 45.0 }
            LG = @{ mnp = 45.0; new = 45.0; chg = 45.0 }
        }
        tag = "#아이폰듀오"
        group = "IPHONE"
    }
)

$updatedPoolList = @()
foreach ($item in $pool) {
    if ($item.id -notmatch '^ipduo') {
        $updatedPoolList += $item
    }
}
foreach ($duo in $duoModels) {
    $updatedPoolList += $duo
}

# 정렬
$updatedPoolList = $updatedPoolList | Sort-Object { $_.name }

$updatedPoolJson = $updatedPoolList | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($catalogPath, $updatedPoolJson, [System.Text.Encoding]::UTF8)
Write-Host "1. crawled_catalog_pool.json 업데이트 완료 (총 $($updatedPoolList.Count)개 모델, Duo 4종 포함)"

# 2. crawled_subsidies_latest.json 갱신
if (Test-Path $subsidiesPath) {
    $latest = Get-Content $subsidiesPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $latest.catalogPool = $updatedPoolList
    $latest.summary.totalDevices = $updatedPoolList.Count
    $latestJson = $latest | ConvertTo-Json -Depth 6
    [System.IO.File]::WriteAllText($subsidiesPath, $latestJson, [System.Text.Encoding]::UTF8)
    Write-Host "2. crawled_subsidies_latest.json 업데이트 완료"
}

# 3. index.html 업데이트
$indexHtml = [System.IO.File]::ReadAllText($indexPath, [System.Text.Encoding]::UTF8)

# 3-1. CRAWLED_CATALOG_POOL 치환
$poolCompactJson = $updatedPoolList | ConvertTo-Json -Depth 5 -Compress
$indexHtml = [regex]::Replace($indexHtml, 'const CRAWLED_CATALOG_POOL\s*=\s*\[[\s\S]*?\];', "const CRAWLED_CATALOG_POOL = $poolCompactJson;")
Write-Host "3-1. index.html CRAWLED_CATALOG_POOL 치환 완료"

# 3-2. handleCatalogSearch 검색어 동의어에 /듀오/g -> 'duo' 추가
if ($indexHtml -notmatch "replace\(/\uB4C0\uC624/g,\s*'duo'\)") {
    $indexHtml = $indexHtml.Replace(
        ".replace(/에어/g, 'air');",
        ".replace(/에어/g, 'air').replace(/듀오/g, 'duo');"
    )
    Write-Host "3-2. handleCatalogSearch 동의어 치환 추가 완료"
}

# 3-3. 태그 자동 생성기에 Duo 추가
if ($indexHtml -notmatch "name\.includes\('Duo'\)") {
    $tagTarget = "if (name.includes('아이폰') || name.includes('iPhone') || id.startsWith('ip')) {"
    $tagReplacement = @"
if (name.includes('아이폰') || name.includes('iPhone') || id.startsWith('ip')) {
          if (name.includes('Duo') || name.includes('듀오') || id.includes('duo')) {
            return '#아이폰듀오';
          }
"@
    $indexHtml = $indexHtml.Replace($tagTarget, $tagReplacement)
    Write-Host "3-3. 태그 생성기 #아이폰듀오 추가 완료"
}

# 3-4. crawledMaster 매핑 객체에 ipduo 추가
if ($indexHtml -notmatch "'ipduo':") {
    $cmTarget = "'ip17p': { prices: { SK: 178.2, KT: 178.2, LG: 178.2 }, sub: { SK: 45, KT: 45, LG: 45 } }"
    $cmReplacement = @"
'ip17p': { prices: { SK: 178.2, KT: 178.2, LG: 178.2 }, sub: { SK: 45, KT: 45, LG: 45 } },
          'ipduo': { prices: { SK: 330, KT: 330, LG: 330 }, sub: { SK: 45, KT: 45, LG: 45 } }
"@
    $indexHtml = $indexHtml.Replace($cmTarget, $cmReplacement)
    Write-Host "3-4. crawledMaster 매핑 객체 ipduo 추가 완료"
}

# 3-5. devices 기본 마스터 배열에 ipduo (아이폰Duo 256G) 추가
if ($indexHtml -notmatch "id:\s*'ipduo'") {
    $devTarget = @"
      {
        id: 'ip17p', group: 'IPHONE', tag: '#17프로', name: '아이폰17 PRO 256G',
"@
    $devReplacement = @"
      {
        id: 'ipduo', group: 'IPHONE', tag: '#아이폰듀오', name: '아이폰Duo 256G',
        prices: { SK: 330, KT: 330, LG: 330 },
        sub: { SK: { mnp: 45, chg: 45 }, KT: { mnp: 45, chg: 45 }, LG: { mnp: 45, chg: 45 } },
        rate: { SK: { mnp: 40, chg: 35 }, KT: { mnp: 45, chg: 40 }, LG: { mnp: 40, chg: 35 } },
        loc: {
          SK: { mnp: '도매', chg: '도매' },
          KT: { mnp: '도매', chg: '도매' },
          LG: { mnp: '도매', chg: '도매' }
        },
        ad: {
          SK: { mnp: '245', chg: '250', note: '', hidden: false },
          KT: { mnp: '240', chg: '245', note: '', hidden: false },
          LG: { mnp: '245', chg: '250', note: '', hidden: false }
        }
      },
      {
        id: 'ip17p', group: 'IPHONE', tag: '#17프로', name: '아이폰17 PRO 256G',
"@
    $indexHtml = $indexHtml.Replace($devTarget, $devReplacement)
    Write-Host "3-5. devices 마스터 배열에 아이폰Duo 256G 추가 완료"
}

# 3-6. poster 기본 목록 지원에 ipduo 추가
if ($indexHtml -match "defaultIds = \['s26', 's26u'") {
    $indexHtml = $indexHtml.Replace(
        "defaultIds = ['s26', 's26u', 'flip8', 'fold8', 'fold8u', 'ip17', 'ipair', 'ip17p'];",
        "defaultIds = ['s26', 's26u', 'flip8', 'fold8', 'fold8u', 'ip17', 'ipair', 'ip17p', 'ipduo'];"
    )
    Write-Host "3-6. poster 기본 목록 ipduo 추가 완료"
}

[System.IO.File]::WriteAllText($indexPath, $indexHtml, [System.Text.Encoding]::UTF8)
Write-Host "✅ index.html 전체 저장 완료!"
