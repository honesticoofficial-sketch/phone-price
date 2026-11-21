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

$s2Rels = Get-ZipXml("xl/worksheets/_rels/sheet2.xml.rels")
$relMap = @{}
if ($s2Rels) {
    foreach ($rel in $s2Rels.Relationships.Relationship) {
        $relMap[$rel.Id] = $rel.Target
    }
}

$s2Xml = Get-ZipXml("xl/worksheets/sheet2.xml")
if ($s2Xml.worksheet.hyperlinks) {
    Write-Host "=== Hyperlinks in Sheet 2 ==="
    foreach ($hl in $s2Xml.worksheet.hyperlinks.hyperlink) {
        $ref = $hl.ref
        $rId = $hl.id
        $target = $relMap[$rId]
        Write-Host "Cell $ref -> rId: $rId -> Target: $target"
    }
}

$zip.Dispose()
