Add-Type -AssemblyName System.IO.Compression.FileSystem

$excelPath = "C:\Users\User01\Downloads\Telegram Desktop\2. 26.11월 제휴카드 안내_1호.xlsx"
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

$sstEntry = $zip.Entries | Where-Object { $_.FullName -eq "xl/sharedStrings.xml" }
$sharedStrings = @()
if ($sstEntry) {
    $r = New-Object System.IO.StreamReader($sstEntry.Open())
    $sstXml = [xml]$r.ReadToEnd()
    $r.Close()
    foreach ($si in $sstXml.sst.si) {
        $text = ""
        if ($si.t) { $text = $si.t.InnerText }
        elseif ($si.r) { foreach ($sub in $si.r) { if ($sub.t) { $text += $sub.t.InnerText } } }
        $sharedStrings += $text
    }
}

$s2Xml = Get-ZipXml("xl/worksheets/sheet2.xml")

foreach ($row in $s2Xml.worksheet.sheetData.row) {
    $rNum = [int]$row.r
    if ($rNum -in @(36, 37, 38)) {
        $cols = @()
        foreach ($c in $row.c) {
            $val = $c.v
            $content = $val
            if ($c.t -eq "s" -and $val -ne $null) {
                $content = $sharedStrings[[int]$val]
            }
            $cols += "$($c.r): $content"
        }
        Write-Host "Row $rNum -> $($cols -join ' | ')"
    }
}

$zip.Dispose()
