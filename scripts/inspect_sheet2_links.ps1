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

Write-Host "=== Rows 30 to 45 in Col H ==="
foreach ($row in $sheet2Xml.worksheet.sheetData.row) {
    $rowNum = [int]$row.r
    if ($rowNum -ge 20 -and $rowNum -le 50) {
        foreach ($c in $row.c) {
            if ($c.r -like "H*") {
                $val = $c.v
                $content = $val
                if ($c.t -eq "s" -and $val -ne $null) {
                    $content = $sharedStrings[[int]$val]
                }
                if ($content) {
                    Write-Host "Row $rowNum (Cell $($c.r)): $content"
                }
            }
        }
    }
}

# Also check hyperlinks
if ($sheet2Xml.worksheet.hyperlinks) {
    Write-Host "`n=== Hyperlinks in Sheet 2 ==="
    foreach ($hl in $sheet2Xml.worksheet.hyperlinks.hyperlink) {
        Write-Host "Ref: $($hl.ref), rId: $($hl.id)"
    }
}

$zip.Dispose()
