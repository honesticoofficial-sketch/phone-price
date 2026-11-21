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

# Check sheet1 rels for hyperlinks or drawings
Write-Host "=== Sheet1 Rels ==="
$s1Rels = Get-ZipXml("xl/worksheets/_rels/sheet1.xml.rels")
if ($s1Rels) {
    foreach ($rel in $s1Rels.Relationships.Relationship) {
        Write-Host "Id: $($rel.Id), Type: $($rel.Type), Target: $($rel.Target)"
    }
}

# Check sheet2 rels for hyperlinks or drawings
Write-Host "`n=== Sheet2 Rels ==="
$s2Rels = Get-ZipXml("xl/worksheets/_rels/sheet2.xml.rels")
if ($s2Rels) {
    foreach ($rel in $s2Rels.Relationships.Relationship) {
        Write-Host "Id: $($rel.Id), Type: $($rel.Type), Target: $($rel.Target)"
    }
}

$zip.Dispose()
