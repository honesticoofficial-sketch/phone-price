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

Write-Host "=== Drawing1 XML Rels ==="
$d1Rels = Get-ZipXml("xl/drawings/_rels/drawing1.xml.rels")
if ($d1Rels) {
    foreach ($rel in $d1Rels.Relationships.Relationship) {
        Write-Host "Id: $($rel.Id), Type: $($rel.Type), Target: $($rel.Target)"
    }
}

Write-Host "`n=== Drawing1 Elements ==="
$d1Xml = Get-ZipXml("xl/drawings/drawing1.xml")
if ($d1Xml) {
    # Check all twoCellAnchor and oneCellAnchor
    $anchors = @()
    if ($d1Xml.wsDr.twoCellAnchor) { $anchors += $d1Xml.wsDr.twoCellAnchor }
    if ($d1Xml.wsDr.oneCellAnchor) { $anchors += $d1Xml.wsDr.oneCellAnchor }
    
    foreach ($a in $anchors) {
        $fromCol = $a.from.col
        $fromRow = $a.from.row
        $picName = $a.pic.nvPicPr.cNvPr.name
        $blipId = $a.pic.blipFill.blip.embed
        Write-Host "Anchor from Col: $fromCol, Row: $fromRow, Pic: $picName, Blip: $blipId"
    }
}

# Also inspect sheet1 cell contents!
$s1Xml = Get-ZipXml("xl/worksheets/sheet1.xml")
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

Write-Host "`n=== Sheet1 Cell Contents ==="
if ($s1Xml) {
    foreach ($row in $s1Xml.worksheet.sheetData.row) {
        $rowNum = $row.r
        foreach ($c in $row.c) {
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

$zip.Dispose()
