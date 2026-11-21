$ErrorActionPreference = "Stop"
$root = "C:\Users\User01\.gemini\antigravity\scratch\phone-price"

$indexHtmlPath = "$root\index.html"
$htmlText = [System.IO.File]::ReadAllText($indexHtmlPath, [System.Text.Encoding]::UTF8)

# Read 3 updated card data files
$sktCards = [System.IO.File]::ReadAllText("$root\skt_cards_data.js", [System.Text.Encoding]::UTF8).Trim() -replace "\r\n", "`n"
$ktCards = [System.IO.File]::ReadAllText("$root\kt_cards_data.js", [System.Text.Encoding]::UTF8).Trim() -replace "\r\n", "`n"
$lguCards = [System.IO.File]::ReadAllText("$root\lgu_cards_data.js", [System.Text.Encoding]::UTF8).Trim() -replace "\r\n", "`n"

$sktMarker = 'const SKT_AFFILIATE_CARDS = ['
$carrierMarker = 'const AFFILIATE_CARDS_BY_CARRIER = {'

$sktIdx = $htmlText.IndexOf($sktMarker)
$carrierIdx = $htmlText.IndexOf($carrierMarker)

if ($sktIdx -lt 0 -or $carrierIdx -lt 0) {
    throw "Markers not found"
}

$before = $htmlText.Substring(0, $sktIdx)
$after = $htmlText.Substring($carrierIdx)

$newCardsBlock = $sktCards + "`n`n" + $ktCards + "`n`n" + $lguCards + "`n`n"
$finalHtml = $before + $newCardsBlock + $after

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($indexHtmlPath, $finalHtml, $utf8NoBom)
Write-Host "index.html successfully updated with new authentic event URLs!"
