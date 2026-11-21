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

Write-Host "=== Drawing2 XML Rels ==="
$d2Rels = Get-ZipXml("xl/drawings/_rels/drawing2.xml.rels")
$relMap = @{}
if ($d2Rels) {
    foreach ($rel in $d2Rels.Relationships.Relationship) {
        $relMap[$rel.Id] = $rel.Target
    }
}

Write-Host "=== Drawing2 Elements Placement in Sheet 2 ==="
$d2Xml = Get-ZipXml("xl/drawings/drawing2.xml")
if ($d2Xml) {
    $anchors = @()
    if ($d2Xml.wsDr.twoCellAnchor) { $anchors += $d2Xml.wsDr.twoCellAnchor }
    if ($d2Xml.wsDr.oneCellAnchor) { $anchors += $d2Xml.wsDr.oneCellAnchor }
    
    foreach ($a in $anchors) {
        $fromCol = [int]$a.from.col
        $fromRow = [int]$a.from.row
        $picName = $a.pic.nvPicPr.cNvPr.name
        $blipId = $a.pic.blipFill.blip.embed
        $targetImg = $relMap[$blipId]
        Write-Host "Row $fromRow, Col $fromCol -> Pic: $picName -> Blip: $blipId -> File: $targetImg"
    }
}

$zip.Dispose()
