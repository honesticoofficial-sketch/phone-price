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

# Build a fast cell map: "ColRow" -> text
$cellMap = @{}
foreach ($row in $sheet2Xml.worksheet.sheetData.row) {
    foreach ($c in $row.c) {
        $val = $c.v
        if ($c.t -eq "s" -and $val -ne $null) {
            $val = $sharedStrings[[int]$val]
        }
        $cellMap[$c.r] = $val
    }
}

$cols = @('C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R')
foreach ($col in $cols) {
    $cardName = $cellMap["${col}3"]
    if (-not $cardName) { $cardName = $cellMap["${col}4"] }
    if ($cardName) {
        Write-Host "========================================="
        Write-Host "[$col] $cardName"
        # Check rows 10 to 30
        for ($r = 10; $r -le 26; $r++) {
            $label = $cellMap["B$r"]
            $val = $cellMap["${col}$r"]
            if ($val -and $val.Trim() -ne "" -and $val.Trim() -ne "-" -and $val.Trim() -ne "0") {
                $clean = $val -replace "`r`n", " " -replace "`n", " "
                Write-Host "  Row $r [$label]: $clean"
            }
        }
    }
}

$zip.Dispose()
