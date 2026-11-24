[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

Write-Host "=========================================================="
Write-Host " [통신 3사 고가요금제 크롤링 실측 데이터 전수 정밀 매핑]"
Write-Host " - SKT: 베스트109 (109,000원)"
Write-Host " - KT: 초이스더블 (120,000원)"
Write-Host " - LGU+: 프리미어 슈퍼 (115,000원)"
Write-Host "=========================================================="

$sktJson = Get-Content -Path "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\skt_pipeline_crawled.json" -Encoding UTF8 | ConvertFrom-Json
$ktJson = Get-Content -Path "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\kt_full_items.json" -Encoding UTF8 | ConvertFrom-Json
$lguJson = Get-Content -Path "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\lgu_pipeline_crawled.json" -Encoding UTF8 | ConvertFrom-Json
$existingPool = Get-Content -Path "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\crawled_catalog_pool.json" -Encoding UTF8 | ConvertFrom-Json

$updatedPool = @()

foreach ($item in $existingPool) {
    $name = $item.name.Trim()

    # ----------------------------------------------------
    # 1) SKT 베스트109 공식 실측 매칭
    # ----------------------------------------------------
    $sktMatch = $null
    if ($name -match '(?i)Duo') {
        $item.subs.SK.new = 45.0
        $item.subs.SK.mnp = 45.0
        $item.subs.SK.chg = 45.0
    } elseif ($name -match '(?i)18\s*Pro\s*Max') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)18\s*Pro\s*Max' } | Select-Object -First 1
    } elseif ($name -match '(?i)18\s*Pro') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)18\s*Pro' -and $_.model -notmatch '(?i)Pro\s*Max' } | Select-Object -First 1
    } elseif ($name -match '(?i)17\s*Pro\s*Max') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)17\s*Pro\s*Max' } | Select-Object -First 1
    } elseif ($name -match '(?i)17\s*Pro') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)17\s*Pro' -and $_.model -notmatch '(?i)Pro\s*Max' } | Select-Object -First 1
    } elseif ($name -match '(?i)17e') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)17e' } | Select-Object -First 1
    } elseif ($name -match '(?i)\b17\b') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)\b17\b' -and $_.model -notmatch '(?i)Pro|Air|17e' } | Select-Object -First 1
    } elseif ($name -match '(?i)16\s*Pro\s*Max') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)16\s*Pro\s*Max' } | Select-Object -First 1
    } elseif ($name -match '(?i)16\s*Pro') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)16\s*Pro' -and $_.model -notmatch '(?i)Pro\s*Max' } | Select-Object -First 1
    } elseif ($name -match '(?i)16e') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)16e' } | Select-Object -First 1
    } elseif ($name -match '(?i)\b16\b') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)\b16\b' -and $_.model -notmatch '(?i)Pro|Air|16e|Plus' } | Select-Object -First 1
    } elseif ($name -match '(?i)15\s*Pro\s*Max') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)15\s*Pro\s*Max' } | Select-Object -First 1
    } elseif ($name -match '(?i)15\s*Pro') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)15\s*Pro' -and $_.model -notmatch '(?i)Pro\s*Max' } | Select-Object -First 1
    } elseif ($name -match '(?i)15\s*Plus') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)15\s*Plus' } | Select-Object -First 1
    } elseif ($name -match '(?i)\b15\b') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)\b15\b' -and $_.model -notmatch '(?i)Pro|Plus' } | Select-Object -First 1
    } elseif ($name -match '(?i)S26\s*울트라|S26\s*Ultra') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)S26\s*울트라|S26\s*Ultra' } | Select-Object -First 1
    } elseif ($name -match '(?i)S26\+') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)S26\+' } | Select-Object -First 1
    } elseif ($name -match '(?i)S26\s*FE') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)S26\s*FE' } | Select-Object -First 1
    } elseif ($name -match '(?i)S26') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)S26' -and $_.model -notmatch '(?i)울트라|Ultra|\+|FE' } | Select-Object -First 1
    } elseif ($name -match '(?i)S25\s*울트라|S25\s*Ultra') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)S25\s*울트라|S25\s*Ultra' } | Select-Object -First 1
    } elseif ($name -match '(?i)S25\s*엣지|S25\s*Edge') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)S25\s*엣지|S25\s*Edge' } | Select-Object -First 1
    } elseif ($name -match '(?i)S25\+') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)S25\+' } | Select-Object -First 1
    } elseif ($name -match '(?i)S25\s*FE') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)S25\s*FE' } | Select-Object -First 1
    } elseif ($name -match '(?i)S25') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)S25' -and $_.model -notmatch '(?i)울트라|Ultra|\+|엣지|Edge|FE' } | Select-Object -First 1
    } elseif ($name -match '(?i)S24\s*울트라|S24\s*Ultra') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)S24\s*울트라|S24\s*Ultra' } | Select-Object -First 1
    } elseif ($name -match '(?i)폴드8\s*울트라|Fold8\s*Ultra') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)폴드8\s*울트라|Fold8\s*Ultra' } | Select-Object -First 1
    } elseif ($name -match '(?i)폴드8|Fold8') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)폴드8|Fold8' -and $_.model -notmatch '(?i)울트라|Ultra' } | Select-Object -First 1
    } elseif ($name -match '(?i)플립8|Flip8') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)플립8|Flip8' } | Select-Object -First 1
    } elseif ($name -match '(?i)폴드7|Fold7') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)폴드7|Fold7' } | Select-Object -First 1
    } elseif ($name -match '(?i)플립7\s*FE|Flip7\s*FE') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)플립7\s*FE|Flip7\s*FE' } | Select-Object -First 1
    } elseif ($name -match '(?i)플립7|Flip7') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)플립7|Flip7' -and $_.model -notmatch '(?i)FE' } | Select-Object -First 1
    } elseif ($name -match '(?i)플립6|Flip6') {
        $sktMatch = $sktJson | Where-Object { $_.model -match '(?i)플립6|Flip6' } | Select-Object -First 1
    }

    if ($sktMatch) {
        $item.subs.SK.new = [math]::Round($sktMatch.subsidies.NEW / 10000, 1)
        $item.subs.SK.mnp = [math]::Round($sktMatch.subsidies.MNP / 10000, 1)
        $item.subs.SK.chg = [math]::Round($sktMatch.subsidies.CHG / 10000, 1)
    }

    # ----------------------------------------------------
    # 2) KT 초이스더블 (120,000원) 공식 실측 매칭
    # ----------------------------------------------------
    $ktMatch = $null
    if ($name -match '(?i)Duo') {
        $item.subs.KT.new = 45.0
        $item.subs.KT.mnp = 45.0
        $item.subs.KT.chg = 45.0
    } elseif ($name -match '(?i)18\s*Pro\s*Max') {
        $ktMatch = $ktJson | Where-Object { $_.model -match '(?i)18\s*Pro\s*Max' } | Select-Object -First 1
    } elseif ($name -match '(?i)18\s*Pro') {
        $ktMatch = $ktJson | Where-Object { $_.model -match '(?i)18\s*Pro' -and $_.model -notmatch '(?i)Pro\s*Max' } | Select-Object -First 1
    } elseif ($name -match '(?i)17\s*Pro\s*Max') {
        $ktMatch = $ktJson | Where-Object { $_.model -match '(?i)17\s*Pro\s*Max' } | Select-Object -First 1
    } elseif ($name -match '(?i)17\s*Pro') {
        $ktMatch = $ktJson | Where-Object { $_.model -match '(?i)17\s*Pro' -and $_.model -notmatch '(?i)Pro\s*Max' } | Select-Object -First 1
    } elseif ($name -match '(?i)17e') {
        $ktMatch = $ktJson | Where-Object { $_.model -match '(?i)17e' } | Select-Object -First 1
    } elseif ($name -match '(?i)\b17\b') {
        $ktMatch = $ktJson | Where-Object { $_.model -match '(?i)\b17\b' -and $_.model -notmatch '(?i)Pro|Air|17e' } | Select-Object -First 1
    } elseif ($name -match '(?i)S26\s*울트라|S26\s*Ultra') {
        $ktMatch = $ktJson | Where-Object { $_.model -match '(?i)S26\s*울트라|S26\s*Ultra' } | Select-Object -First 1
    } elseif ($name -match '(?i)S26\+') {
        $ktMatch = $ktJson | Where-Object { $_.model -match '(?i)S26\+' } | Select-Object -First 1
    } elseif ($name -match '(?i)S26\s*FE') {
        $ktMatch = $ktJson | Where-Object { $_.model -match '(?i)S26\s*FE' } | Select-Object -First 1
    } elseif ($name -match '(?i)S26') {
        $ktMatch = $ktJson | Where-Object { $_.model -match '(?i)S26' -and $_.model -notmatch '(?i)울트라|Ultra|\+|FE' } | Select-Object -First 1
    } elseif ($name -match '(?i)S25\s*울트라|S25\s*Ultra') {
        $ktMatch = $ktJson | Where-Object { $_.model -match '(?i)S25\s*울트라|S25\s*Ultra' } | Select-Object -First 1
    } elseif ($name -match '(?i)S25\s*엣지|S25\s*Edge') {
        $ktMatch = $ktJson | Where-Object { $_.model -match '(?i)S25\s*엣지|S25\s*Edge' } | Select-Object -First 1
    } elseif ($name -match '(?i)S25\+') {
        $ktMatch = $ktJson | Where-Object { $_.model -match '(?i)S25\+' } | Select-Object -First 1
    } elseif ($name -match '(?i)S25\s*FE') {
        $ktMatch = $ktJson | Where-Object { $_.model -match '(?i)S25\s*FE' } | Select-Object -First 1
    } elseif ($name -match '(?i)S25') {
        $ktMatch = $ktJson | Where-Object { $_.model -match '(?i)S25' -and $_.model -notmatch '(?i)울트라|Ultra|\+|엣지|Edge|FE' } | Select-Object -First 1
    } elseif ($name -match '(?i)폴드8\s*울트라|Fold8\s*Ultra') {
        $ktMatch = $ktJson | Where-Object { $_.model -match '(?i)폴드8\s*울트라|Fold8\s*Ultra' } | Select-Object -First 1
    } elseif ($name -match '(?i)폴드8|Fold8') {
        $ktMatch = $ktJson | Where-Object { $_.model -match '(?i)폴드8|Fold8' -and $_.model -notmatch '(?i)울트라|Ultra' } | Select-Object -First 1
    } elseif ($name -match '(?i)플립8|Flip8') {
        $ktMatch = $ktJson | Where-Object { $_.model -match '(?i)플립8|Flip8' } | Select-Object -First 1
    } elseif ($name -match '(?i)폴드7|Fold7') {
        $ktMatch = $ktJson | Where-Object { $_.model -match '(?i)폴드7|Fold7' } | Select-Object -First 1
    } elseif ($name -match '(?i)플립7|Flip7') {
        $ktMatch = $ktJson | Where-Object { $_.model -match '(?i)플립7|Flip7' } | Select-Object -First 1
    }

    if ($ktMatch) {
        $subVal = [math]::Round($ktMatch.subsidy / 10000, 1)
        $item.subs.KT.new = $subVal
        $item.subs.KT.mnp = $subVal
        $item.subs.KT.chg = $subVal
    }

    # ----------------------------------------------------
    # 3) LGU+ 프리미어 슈퍼 (115,000원) 공식 실측 매칭
    # ----------------------------------------------------
    $lguMatch = $null
    if ($name -match '(?i)Duo') {
        $item.subs.LG.new = 45.0
        $item.subs.LG.mnp = 45.0
        $item.subs.LG.chg = 45.0
    } elseif ($name -match '(?i)18\s*Pro\s*Max') {
        $lguMatch = $lguJson | Where-Object { $_.model -match '(?i)18\s*Pro\s*Max' } | Select-Object -First 1
    } elseif ($name -match '(?i)18\s*Pro') {
        $lguMatch = $lguJson | Where-Object { $_.model -match '(?i)18\s*Pro' -and $_.model -notmatch '(?i)Pro\s*Max' } | Select-Object -First 1
    } elseif ($name -match '(?i)17\s*Pro\s*Max') {
        $lguMatch = $lguJson | Where-Object { $_.model -match '(?i)17\s*Pro\s*Max' } | Select-Object -First 1
    } elseif ($name -match '(?i)17\s*Pro') {
        $lguMatch = $lguJson | Where-Object { $_.model -match '(?i)17\s*Pro' -and $_.model -notmatch '(?i)Pro\s*Max' } | Select-Object -First 1
    } elseif ($name -match '(?i)Air') {
        $lguMatch = $lguJson | Where-Object { $_.model -match '(?i)Air' } | Select-Object -First 1
    } elseif ($name -match '(?i)\b17\b') {
        $lguMatch = $lguJson | Where-Object { $_.model -match '(?i)\b17\b' -and $_.model -notmatch '(?i)Pro|Air' } | Select-Object -First 1
    } elseif ($name -match '(?i)16\s*Pro\s*Max') {
        $lguMatch = $lguJson | Where-Object { $_.model -match '(?i)16\s*Pro\s*Max' } | Select-Object -First 1
    } elseif ($name -match '(?i)16\s*Pro') {
        $lguMatch = $lguJson | Where-Object { $_.model -match '(?i)16\s*Pro' -and $_.model -notmatch '(?i)Pro\s*Max' } | Select-Object -First 1
    } elseif ($name -match '(?i)16\s*Plus') {
        $lguMatch = $lguJson | Where-Object { $_.model -match '(?i)16\s*Plus' } | Select-Object -First 1
    } elseif ($name -match '(?i)16e') {
        $lguMatch = $lguJson | Where-Object { $_.model -match '(?i)16e' } | Select-Object -First 1
    } elseif ($name -match '(?i)\b16\b') {
        $lguMatch = $lguJson | Where-Object { $_.model -match '(?i)\b16\b' -and $_.model -notmatch '(?i)Pro|Air|16e|Plus' } | Select-Object -First 1
    } elseif ($name -match '(?i)S26\s*울트라|S26\s*Ultra') {
        $lguMatch = $lguJson | Where-Object { $_.model -match '(?i)S26\s*Ultra' } | Select-Object -First 1
    } elseif ($name -match '(?i)S26\+') {
        $lguMatch = $lguJson | Where-Object { $_.model -match '(?i)S26\+' } | Select-Object -First 1
    } elseif ($name -match '(?i)S26\s*FE') {
        $lguMatch = $lguJson | Where-Object { $_.model -match '(?i)S26\s*FE' } | Select-Object -First 1
    } elseif ($name -match '(?i)S26') {
        $lguMatch = $lguJson | Where-Object { $_.model -match '(?i)S26' -and $_.model -notmatch '(?i)Ultra|\+|FE' } | Select-Object -First 1
    } elseif ($name -match '(?i)S25\s*울트라|S25\s*Ultra') {
        $lguMatch = $lguJson | Where-Object { $_.model -match '(?i)S25\s*Ultra' } | Select-Object -First 1
    } elseif ($name -match '(?i)S25\s*엣지|S25\s*Edge') {
        $lguMatch = $lguJson | Where-Object { $_.model -match '(?i)S25\s*Edge' } | Select-Object -First 1
    } elseif ($name -match '(?i)S25\+') {
        $lguMatch = $lguJson | Where-Object { $_.model -match '(?i)S25\+' } | Select-Object -First 1
    } elseif ($name -match '(?i)S25\s*FE') {
        $lguMatch = $lguJson | Where-Object { $_.model -match '(?i)S25\s*FE' } | Select-Object -First 1
    } elseif ($name -match '(?i)S25') {
        $lguMatch = $lguJson | Where-Object { $_.model -match '(?i)S25' -and $_.model -notmatch '(?i)Ultra|\+|Edge|FE' } | Select-Object -First 1
    } elseif ($name -match '(?i)폴드8\s*울트라|Fold8\s*Ultra') {
        $lguMatch = $lguJson | Where-Object { $_.model -match '(?i)Fold8\s*Ultra' } | Select-Object -First 1
    } elseif ($name -match '(?i)폴드8|Fold8') {
        $lguMatch = $lguJson | Where-Object { $_.model -match '(?i)Fold8' -and $_.model -notmatch '(?i)Ultra' } | Select-Object -First 1
    } elseif ($name -match '(?i)플립8|Flip8') {
        $lguMatch = $lguJson | Where-Object { $_.model -match '(?i)Flip8' } | Select-Object -First 1
    } elseif ($name -match '(?i)폴드7|Fold7') {
        $lguMatch = $lguJson | Where-Object { $_.model -match '(?i)Fold7' } | Select-Object -First 1
    } elseif ($name -match '(?i)플립7|Flip7') {
        $lguMatch = $lguJson | Where-Object { $_.model -match '(?i)Flip7' } | Select-Object -First 1
    }

    if ($lguMatch) {
        $item.subs.LG.new = [math]::Round($lguMatch.subsidies.NEW / 10000, 1)
        $item.subs.LG.mnp = [math]::Round($lguMatch.subsidies.MNP / 10000, 1)
        $item.subs.LG.chg = [math]::Round($lguMatch.subsidies.CHG / 10000, 1)
    }

    $updatedPool += $item
}

# Save data/crawled_catalog_pool.json
$poolPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\crawled_catalog_pool.json"
$updatedPool | ConvertTo-Json -Depth 6 | Set-Content -Path $poolPath -Encoding UTF8

# Save data/crawled_subsidies_latest.json
$latestPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\crawled_subsidies_latest.json"
$latest = Get-Content -Path $latestPath -Encoding UTF8 | ConvertFrom-Json
$latest.catalogPool = $updatedPool
$latest | ConvertTo-Json -Depth 8 | Set-Content -Path $latestPath -Encoding UTF8

# Sync index.html
$indexPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html"
$indexHtml = Get-Content -Path $indexPath -Raw -Encoding UTF8
$poolJsonClean = ($updatedPool | ConvertTo-Json -Depth 6 -Compress)
$indexHtml = [regex]::Replace($indexHtml, 'const CRAWLED_CATALOG_POOL\s*=\s*\[[\s\S]*?\];', "const CRAWLED_CATALOG_POOL = $poolJsonClean;")
Set-Content -Path $indexPath -Value $indexHtml -Encoding UTF8

Write-Host "`n=== [정밀 매칭 완료 및 3사 공시지원금 실측 확인] ==="
$checkTargets = @(
    "iPhone 18 Pro Max 256G",
    "iPhone 18 Pro 256G",
    "iPhone 17 256G",
    "iPhone 17 Pro 256G",
    "iPhone 17 Pro Max 256G",
    "iPhone 16 Pro 256G",
    "갤럭시 S26 울트라 256G",
    "갤럭시 S26 256G",
    "갤럭시 S26 FE 256G",
    "갤럭시 S25 울트라 256G",
    "갤럭시 S25 엣지 256G",
    "갤럭시 S25 256G",
    "갤럭시 Z 폴드8 256G",
    "갤럭시 Z 플립8 256G"
)

$updatedPool | Where-Object { $checkTargets -contains $_.name } | 
    Select-Object name, `
        @{n="SK_NEW";e={$_.subs.SK.new}}, @{n="SK_MNP";e={$_.subs.SK.mnp}}, @{n="SK_CHG";e={$_.subs.SK.chg}}, `
        @{n="KT_MNP";e={$_.subs.KT.mnp}}, `
        @{n="LG_NEW";e={$_.subs.LG.new}}, @{n="LG_MNP";e={$_.subs.LG.mnp}}, @{n="LG_CHG";e={$_.subs.LG.chg}} | 
    Format-Table -AutoSize | Out-String | Write-Host
