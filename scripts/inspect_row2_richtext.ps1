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
$cols = @("D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R")

Write-Host "=== Row 2 Full Text ==="
foreach ($row in $sheet2Xml.worksheet.sheetData.row) {
    if ([int]$row.r -eq 2) {
        foreach ($c in $row.c) {
            $colLetter = $c.r -replace '\d', ''
            if ($cols -contains $colLetter) {
                $idx = [int]$c.v
                Write-Host "Col $colLetter : $($sharedStrings[$idx])"
            }
        }
    }
}

$zip.Dispose()
