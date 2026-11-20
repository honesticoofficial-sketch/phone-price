Add-Type -AssemblyName System.IO.Compression.FileSystem

$excelPath = "C:\Users\User01\.gemini\antigravity\brain\af18e558-85da-49ae-9eb0-4c9b6d7b02ae\.user_uploaded\media_1795149673650_8a07059c.xlsx"
$zip = [System.IO.Compression.ZipFile]::OpenRead($excelPath)

function Get-ZipXml($path) {
    $e = $zip.Entries | Where-Object { $_.FullName -eq $path }
    if ($e) {
        $r = New-Object System.IO.StreamReader($e.Open())
        $xml = [xml]$r.ReadToEnd()
        $r.Close()
        return $xml
    }
    return $null
}

$sstXml = Get-ZipXml("xl/sharedStrings.xml")
$sharedStrings = @()
if ($sstXml) {
    foreach ($si in $sstXml.sst.si) {
        $text = ""
        if ($si.t) { $text = $si.t.InnerText }
        elseif ($si.r) {
            foreach ($r in $si.r) {
                if ($r.t) { $text += $r.t.InnerText }
            }
        }
        $sharedStrings += $text
    }
}

$sheet2Xml = Get-ZipXml("xl/worksheets/sheet2.xml")

Write-Host "=== Scanning All Rows for Col E (현대카드 라이트할부) and Col P (현대카드 요금할인) ==="
foreach ($row in $sheet2Xml.worksheet.sheetData.row) {
    $rowNum = [int]$row.r
    foreach ($c in $row.c) {
        if ($c.r -like "E*" -or $c.r -like "P*") {
            $val = $c.v
            $content = $val
            if ($c.t -eq "s" -and $val -ne $null) {
                $content = $sharedStrings[[int]$val]
            }
            if ($content -and $content.Trim().Length -gt 0) {
                $clean = $content -replace "`r`n", " " -replace "`n", " "
                Write-Host "Row $rowNum ($($c.r)): $clean"
            }
        }
    }
}

$zip.Dispose()
