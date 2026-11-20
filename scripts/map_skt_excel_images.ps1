Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Drawing

$excelPath = "C:\Users\User01\.gemini\antigravity\brain\af18e558-85da-49ae-9eb0-4c9b6d7b02ae\.user_uploaded\media_1795149673650_8a07059c.xlsx"
$scratchDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\skt_excel_images"

# Extract drawings and sheets xml
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

# Inspect workbook.xml to see sheet names
$wbXml = Get-ZipXml("xl/workbook.xml")
$sheets = @()
foreach ($s in $wbXml.workbook.sheets.sheet) {
    $sheets += [PSCustomObject]@{
        Name = $s.name
        SheetId = $s.sheetId
        Id = $s.id
    }
}
Write-Host "Workbook Sheets:"
$sheets | Format-Table -AutoSize

# Inspect sharedStrings.xml
$sstXml = Get-ZipXml("xl/sharedStrings.xml")
$sharedStrings = @()
if ($sstXml) {
    foreach ($si in $sstXml.sst.si) {
        $sharedStrings += $si.t
    }
}
Write-Host "Total shared strings: $($sharedStrings.Count)"

# For each sheet (sheet1, sheet2, etc.)
for ($i = 1; $i -le 3; $i++) {
    $sheetName = "xl/worksheets/sheet$i.xml"
    $relsName = "xl/worksheets/_rels/sheet$i.xml.rels"
    $sheetXml = Get-ZipXml($sheetName)
    if (-not $sheetXml) { continue }
    
    $relsXml = Get-ZipXml($relsName)
    $drawingRel = $relsXml.Relationships.Relationship | Where-Object { $_.Type -like "*drawing" }
    Write-Host "`n=== Sheet $i (Drawing: $($drawingRel.Target)) ==="
    
    if ($drawingRel) {
        $drawingPath = "xl/drawings/" + ([System.IO.Path]::GetFileName($drawingRel.Target))
        $drawingRelsPath = "xl/drawings/_rels/" + ([System.IO.Path]::GetFileName($drawingRel.Target)) + ".rels"
        
        $drawingXml = Get-ZipXml($drawingPath)
        $drawingRelsXml = Get-ZipXml($drawingRelsPath)
        
        # Build relId -> image file map
        $relMap = @{}
        foreach ($rel in $drawingRelsXml.Relationships.Relationship) {
            $relMap[$rel.Id] = [System.IO.Path]::GetFileName($rel.Target)
        }
        
        # Now find anchors in drawingXml
        # In drawing xml, anchors can be xdr:twoCellAnchor or xdr:oneCellAnchor
        $ns = New-Object System.Xml.XmlNamespaceManager($drawingXml.NameTable)
        $ns.AddNamespace("xdr", "http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing")
        $ns.AddNamespace("a", "http://schemas.openxmlformats.org/drawingml/2006/main")
        $ns.AddNamespace("r", "http://schemas.openxmlformats.org/officeDocument/2006/relationships")
        
        $anchors = $drawingXml.SelectNodes("//xdr:twoCellAnchor | //xdr:oneCellAnchor", $ns)
        Write-Host "Found $($anchors.Count) anchors in $drawingPath"
        
        foreach ($anchor in $anchors) {
            $fromCol = $anchor.SelectSingleNode("xdr:from/xdr:col", $ns).InnerText
            $fromRow = $anchor.SelectSingleNode("xdr:from/xdr:row", $ns).InnerText
            $toCol = $anchor.SelectSingleNode("xdr:to/xdr:col", $ns).InnerText
            $toRow = $anchor.SelectSingleNode("xdr:to/xdr:row", $ns).InnerText
            
            $blip = $anchor.SelectSingleNode(".//a:blip", $ns)
            $embedId = $blip.GetAttribute("r:embed")
            $imgName = $relMap[$embedId]
            
            Write-Host "Anchor at From(Col:$fromCol, Row:$fromRow) To(Col:$toCol, Row:$toRow) -> RelId: $embedId, Image: $imgName"
        }
    }
}

$zip.Dispose()
