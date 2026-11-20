Add-Type -AssemblyName System.IO.Compression.FileSystem

$excelPath = "C:\Users\User01\.gemini\antigravity\brain\af18e558-85da-49ae-9eb0-4c9b6d7b02ae\.user_uploaded\media_1795149673650_8a07059c.xlsx"
$zip = [System.IO.Compression.ZipFile]::OpenRead($excelPath)

$drawingXmlEntry = $zip.Entries | Where-Object { $_.FullName -eq "xl/drawings/drawing2.xml" }
$r = New-Object System.IO.StreamReader($drawingXmlEntry.Open())
$drawingXml = [xml]$r.ReadToEnd()
$r.Close()

$drawingRelsEntry = $zip.Entries | Where-Object { $_.FullName -eq "xl/drawings/_rels/drawing2.xml.rels" }
$r = New-Object System.IO.StreamReader($drawingRelsEntry.Open())
$relsXml = [xml]$r.ReadToEnd()
$r.Close()

$relMap = @{}
foreach ($rel in $relsXml.Relationships.Relationship) {
    $relMap[$rel.Id] = [System.IO.Path]::GetFileName($rel.Target)
}

$ns = New-Object System.Xml.XmlNamespaceManager($drawingXml.NameTable)
$ns.AddNamespace("xdr", "http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing")
$ns.AddNamespace("a", "http://schemas.openxmlformats.org/drawingml/2006/main")
$ns.AddNamespace("r", "http://schemas.openxmlformats.org/officeDocument/2006/relationships")

$anchors = $drawingXml.SelectNodes("//xdr:twoCellAnchor | //xdr:oneCellAnchor", $ns)
foreach ($anchor in $anchors) {
    $fromCol = $anchor.SelectSingleNode("xdr:from/xdr:col", $ns).InnerText
    $fromRow = $anchor.SelectSingleNode("xdr:from/xdr:row", $ns).InnerText
    $blip = $anchor.SelectSingleNode(".//a:blip", $ns)
    $embedId = if ($blip) { $blip.GetAttribute("r:embed") } else { $null }
    $img = if ($embedId) { $relMap[$embedId] } else { $null }
    Write-Host "From Col: $fromCol, Row: $fromRow -> Rel: $embedId, Img: $img"
}

$zip.Dispose()
