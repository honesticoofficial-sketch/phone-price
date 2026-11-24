[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$jsonPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\crawled_subsidies_latest.json"
$data = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json

# Check if LGU+ has 18 Pro Max
$existingLgu18pm = $data.lgu | Where-Object { $_.model -match "18.*Pro.*Max" }
Write-Host "Existing LGU 18 Pro Max count: $($existingLgu18pm.Count)"

$newItems = @(
    @{ carrier = "LGU+"; manufacturer = "Apple"; model = "iPhone 18 Pro Max 256GB UIP18PM-256"; factoryPrice = 2200000; subsidy = 168000; date = "2026-09-12"; scrbType = "" },
    @{ carrier = "LGU+"; manufacturer = "Apple"; model = "iPhone 18 Pro Max 512GB UIP18PM-512"; factoryPrice = 2497000; subsidy = 168000; date = "2026-09-12"; scrbType = "" },
    @{ carrier = "LGU+"; manufacturer = "Apple"; model = "iPhone 18 Pro Max 1TB UIP18PM-1T"; factoryPrice = 3091000; subsidy = 168000; date = "2026-09-12"; scrbType = "" },
    @{ carrier = "LGU+"; manufacturer = "Apple"; model = "iPhone 18 Pro Max 2TB UIP18PM-2T"; factoryPrice = 3993000; subsidy = 168000; date = "2026-09-12"; scrbType = "" },
    @{ carrier = "LGU+"; manufacturer = "Apple"; model = "iPhone 18 Pro 256GB UIP18PR-256"; factoryPrice = 1991000; subsidy = 450000; date = "2026-09-12"; scrbType = "" },
    @{ carrier = "LGU+"; manufacturer = "Apple"; model = "iPhone 18 Pro 512GB UIP18PR-512"; factoryPrice = 2299000; subsidy = 450000; date = "2026-09-12"; scrbType = "" },
    @{ carrier = "LGU+"; manufacturer = "Apple"; model = "iPhone 18 Pro 2TB UIP18PR-2T"; factoryPrice = 3795000; subsidy = 450000; date = "2026-09-12"; scrbType = "" }
)

$lguList = [System.Collections.ArrayList]@($data.lgu)
foreach ($it in $newItems) {
    $exists = $lguList | Where-Object { $_.model -eq $it.model }
    if (-not $exists) {
        $lguList.Add($it) | Out-Null
        Write-Host "Added $($it.model)"
    }
}

$data.lgu = $lguList
$data | ConvertTo-Json -Depth 10 | Set-Content $jsonPath -Encoding UTF8
Write-Host "Updated crawled_subsidies_latest.json! Total LGU items: $($data.lgu.Count)"
