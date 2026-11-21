Add-Type -AssemblyName System.IO.Compression.FileSystem

$excelPath = "C:\Users\User01\Downloads\Telegram Desktop\2. 26.11월 제휴카드 안내_1호.xlsx"
$zip = [System.IO.Compression.ZipFile]::OpenRead($excelPath)

Write-Host "=== Sheets in Excel ==="
$wbXml = $null
$wbEntry = $zip.Entries | Where-Object { $_.FullName -eq "xl/workbook.xml" }
if ($wbEntry) {
    $r = New-Object System.IO.StreamReader($wbEntry.Open())
    $wbXml = [xml]$r.ReadToEnd()
    $r.Close()
    foreach ($sheet in $wbXml.workbook.sheets.sheet) {
        Write-Host "Sheet Name: $($sheet.name), SheetId: $($sheet.sheetId), rId: $($sheet.id)"
    }
}

# Check shared strings
$sstXml = $null
$sstEntry = $zip.Entries | Where-Object { $_.FullName -eq "xl/sharedStrings.xml" }
$sharedStrings = @()
if ($sstEntry) {
    $r = New-Object System.IO.StreamReader($sstEntry.Open())
    $sstXml = [xml]$r.ReadToEnd()
    $r.Close()
    foreach ($si in $sstXml.sst.si) {
        $text = ""
        if ($si.t) { $text = $si.t.InnerText }
        elseif ($si.r) {
            foreach ($sub in $si.r) { if ($sub.t) { $text += $sub.t.InnerText } }
        }
        $sharedStrings += $text
    }
    Write-Host "Total shared strings: $($sharedStrings.Count)"
}

# Search for QR or 이벤트 or 대상 or naver in shared strings
Write-Host "`n=== Matching Strings in SharedStrings ==="
for ($i = 0; $i -lt $sharedStrings.Count; $i++) {
    $str = $sharedStrings[$i]
    if ($str -match "QR|이벤트|무실적|0JM|대상.*확인|naver") {
        Write-Host "[$i]: $str"
    }
}

$zip.Dispose()
