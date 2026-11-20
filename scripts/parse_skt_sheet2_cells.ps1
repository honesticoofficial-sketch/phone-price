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

# shared strings
$sstXml = Get-ZipXml("xl/sharedStrings.xml")
$sharedStrings = @()
if ($sstXml) {
    foreach ($si in $sstXml.sst.si) {
        # si can have t directly or multiple r/t
        $text = ""
        if ($si.t) { $text = $si.t }
        elseif ($si.r) {
            foreach ($r in $si.r) { $text += $r.t }
        }
        $sharedStrings += $text
    }
}

$sheet2Xml = Get-ZipXml("xl/worksheets/sheet2.xml")

# Parse rows 1 to 10
foreach ($row in $sheet2Xml.worksheet.sheetData.row) {
    $rowNum = [int]$row.r
    if ($rowNum -le 10) {
        Write-Host "--- Row $rowNum ---"
        foreach ($c in $row.c) {
            $ref = $c.r
            $val = $c.v
            $t = $c.t
            $content = $val
            if ($t -eq "s" -and $val -ne $null) {
                $idx = [int]$val
                $content = $sharedStrings[$idx]
            }
            if ($content) {
                # Clean up newlines for display
                $disp = $content -replace "`r`n", " " -replace "`n", " "
                Write-Host "  Cell $ref : $disp"
            }
        }
    }
}

$zip.Dispose()
