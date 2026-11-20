Add-Type -AssemblyName System.IO.Compression.FileSystem

$excelPath = "C:\Users\User01\.gemini\antigravity\brain\af18e558-85da-49ae-9eb0-4c9b6d7b02ae\.user_uploaded\media_1795149673650_8a07059c.xlsx"
$zip = [System.IO.Compression.ZipFile]::OpenRead($excelPath)

$e = $zip.Entries | Where-Object { $_.FullName -eq "xl/worksheets/_rels/sheet2.xml.rels" }
$r = New-Object System.IO.StreamReader($e.Open())
$relsXml = [xml]$r.ReadToEnd()
$r.Close()

Write-Host "=== All Hyperlinks Target URLs in Sheet 2 ==="
foreach ($rel in $relsXml.Relationships.Relationship) {
    if ($rel.Type -like "*hyperlink*") {
        Write-Host "$($rel.Id) -> $($rel.Target)"
    }
}

$zip.Dispose()
