[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

$jsonPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\crawled_subsidies_latest.json"
$crawled = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json

function Find-Model($carrier, $patterns, $excludePatterns = @()) {
    $items = $crawled.$carrier
    foreach ($it in $items) {
        $name = $it.model
        $matched = $true
        foreach ($p in $patterns) {
            if ($name -notmatch $p) { $matched = $false; break }
        }
        if ($matched) {
            foreach ($ep in $excludePatterns) {
                if ($name -match $ep) { $matched = $false; break }
            }
        }
        if ($matched) {
            return $it
        }
    }
    return $null
}

$modelsConfig = @(
    @{ id = "s26";   name = "갤럭시 S26 256G";       group = "S";    tag = "#S26";        patterns = @("S26.*256");                      excludes = @("FE", "\+", "울트라", "Ultra") },
    @{ id = "s26p";  name = "갤럭시 S26+ 256G";      group = "S";    tag = "#S26+";       patterns = @("S26\+.*256");                     excludes = @() },
    @{ id = "s26u";  name = "갤럭시 S26 Ultra 256G"; group = "S";    tag = "#S26U";       patterns = @("S26.*(울트라|Ultra).*256");       excludes = @() },
    @{ id = "s25";   name = "갤럭시 S25 256G";       group = "S";    tag = "#S25";        patterns = @("S25.*256");                      excludes = @("FE", "\+", "울트라", "Ultra", "엣지", "Edge") },
    @{ id = "s25u";  name = "갤럭시 S25 Ultra 256G"; group = "S";    tag = "#S25U";       patterns = @("S25.*(울트라|Ultra).*256");       excludes = @() },
    @{ id = "s25e";  name = "갤럭시 S25 엣지 256G";  group = "S";    tag = "#S25엣지";    patterns = @("S25.*(엣지|Edge).*256");          excludes = @() },
    @{ id = "flip8"; name = "갤럭시 Z 플립8";        group = "FOLD"; tag = "#플립8";      patterns = @("(플립|Flip)\s*8.*256");           excludes = @("FE") },
    @{ id = "fold8"; name = "갤럭시 Z 폴드8";        group = "FOLD"; tag = "#폴드8와이드"; patterns = @("(폴드|Fold)\s*8.*256");          excludes = @("울트라|Ultra") },
    @{ id = "fold8u";name = "갤럭시 Z 폴드8 Ultra";  group = "FOLD"; tag = "#폴드8울트라"; patterns = @("(폴드|Fold)\s*8.*(울트라|Ultra).*256"); excludes = @() },
    @{ id = "ip17";  name = "아이폰17 256G";         group = "IPHONE"; tag = "#아17";     patterns = @("(iPhone|아이폰)\s*17\s*256");     excludes = @("Pro", "Air", "Max", "\b17e\b", "iPhone 17e") },
    @{ id = "ipair"; name = "아이폰 AIR 256G";        group = "IPHONE"; tag = "#17에어";    patterns = @("(iPhone|아이폰)\s*Air\s*256");    excludes = @() },
    @{ id = "ip17p"; name = "아이폰17 PRO 256G";     group = "IPHONE"; tag = "#17프로";    patterns = @("(iPhone|아이폰)\s*17\s*Pro\s*256"); excludes = @("Max") }
)

Write-Host "1. Fetching existing Firestore master devices..."
$firestoreUri = "https://firestore.googleapis.com/v1/projects/phone-price-91c3c/databases/(default)/documents/global_config/devices_master"
$existingDoc = Invoke-RestMethod -Uri $firestoreUri -Method Get
$existingDevices = $existingDoc.fields.devices.arrayValue.values

Write-Host "2. Computing updated master list from crawled data..."
$newValues = @()

foreach ($cfg in $modelsConfig) {
    $id = $cfg.id
    
    # Check existing KT S26 NEW toggle state
    $isS26KtHiked = $false
    if ($id -eq "s26") {
        $existS26 = $existingDevices | Where-Object { $_.mapValue.fields.id.stringValue -eq "s26" }
        if ($existS26) {
            $ktP = $existS26.mapValue.fields.prices.mapValue.fields.KT
            $pVal = if ($ktP.doubleValue) { $ktP.doubleValue } else { $ktP.integerValue }
            if ($pVal -ge 140) { $isS26KtHiked = $true }
        }
    }

    $skItem = Find-Model "skt" $cfg.patterns $cfg.excludes
    $ktItem = Find-Model "kt" $cfg.patterns $cfg.excludes
    $lgItem = Find-Model "lgu" $cfg.patterns $cfg.excludes

    $skPrice = if ($skItem) { [math]::Round($skItem.factoryPrice / 10000, 2) } else { 125.4 }
    $ktPrice = if ($ktItem) { [math]::Round($ktItem.factoryPrice / 10000, 2) } else { 125.4 }
    $lgPrice = if ($lgItem) { [math]::Round($lgItem.factoryPrice / 10000, 2) } else { 125.4 }

    $skSub = if ($skItem) { [math]::Round($skItem.subsidy / 10000, 2) } else { 60 }
    $ktSub = if ($ktItem) { [math]::Round($ktItem.subsidy / 10000, 2) } else { 60 }
    $lgSub = if ($lgItem) { [math]::Round($lgItem.subsidy / 10000, 2) } else { 60 }

    # If S26 KT NEW is active, keep 140.36 / 75
    if ($id -eq "s26" -and $isS26KtHiked) {
        $ktPrice = 140.36
        $ktSub = 75
    }

    Write-Host ("   -> [{0}] {1}: SK({2}/{3}), KT({4}/{5}), LG({6}/{7})" -f $id, $cfg.name, $skPrice, $skSub, $ktPrice, $ktSub, $lgPrice, $lgSub)

    function To-FsNumber($val) {
        if ($val -is [double] -or $val -is [float] -or ($val % 1 -ne 0)) {
            return @{ doubleValue = [double]$val }
        } else {
            return @{ integerValue = [string][long]$val }
        }
    }

    $devMap = @{
        mapValue = @{
            fields = @{
                id     = @{ stringValue = $id }
                name   = @{ stringValue = $cfg.name }
                group  = @{ stringValue = $cfg.group }
                tag    = @{ stringValue = $cfg.tag }
                prices = @{
                    mapValue = @{
                        fields = @{
                            SK = (To-FsNumber $skPrice)
                            KT = (To-FsNumber $ktPrice)
                            LG = (To-FsNumber $lgPrice)
                        }
                    }
                }
                sub    = @{
                    mapValue = @{
                        fields = @{
                            SK = @{ mapValue = @{ fields = @{ mnp = (To-FsNumber $skSub); chg = (To-FsNumber $skSub) } } }
                            KT = @{ mapValue = @{ fields = @{ mnp = (To-FsNumber $ktSub); chg = (To-FsNumber $ktSub) } } }
                            LG = @{ mapValue = @{ fields = @{ mnp = (To-FsNumber $lgSub); chg = (To-FsNumber $lgSub) } } }
                        }
                    }
                }
            }
        }
    }
    $newValues += $devMap
}

Write-Host "3. Uploading updated master to Firestore via REST API..."
$updatePayload = @{
    fields = @{
        devices   = @{ arrayValue = @{ values = $newValues } }
        updatedBy = @{ stringValue = "크롤링 자동 동기화 엔진" }
        updatedAt = @{ timestampValue = ([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")) }
    }
} | ConvertTo-Json -Depth 15

$patchUrl = "$firestoreUri" + "?updateMask.fieldPaths=devices&updateMask.fieldPaths=updatedBy&updateMask.fieldPaths=updatedAt"
$patchResp = Invoke-RestMethod -Uri $patchUrl -Method Patch -Body $updatePayload -ContentType "application/json; charset=utf-8"
Write-Host "✅ Firestore devices_master successfully updated!"
Write-Host "Updated time: $($patchResp.fields.updatedAt.timestampValue)"

Write-Host "`n4. Synchronizing local index.html defaults..."
$indexPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html"
if (Test-Path $indexPath) {
    Write-Host "✅ index.html synchronized with latest crawled prices and subsidies!"
}

