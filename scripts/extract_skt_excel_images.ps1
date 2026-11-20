Add-Type -AssemblyName System.IO.Compression.FileSystem

$excelPath = "C:\Users\User01\.gemini\antigravity\brain\af18e558-85da-49ae-9eb0-4c9b6d7b02ae\.user_uploaded\media_1795149673650_8a07059c.xlsx"
$outputDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\skt_excel_images"

if (Test-Path $outputDir) { Remove-Item $outputDir -Recurse -Force }
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

$zip = [System.IO.Compression.ZipFile]::OpenRead($excelPath)
$mediaEntries = $zip.Entries | Where-Object { $_.FullName -like "xl/media/*" }

Write-Host "Found $($mediaEntries.Count) media entries in SKT Excel."
foreach ($entry in $mediaEntries) {
    $targetFile = Join-Path $outputDir ([System.IO.Path]::GetFileName($entry.FullName))
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $targetFile, $true)
    Write-Host "Extracted: $($entry.FullName) -> $targetFile (Length: $($entry.Length) bytes)"
}

# Also inspect drawing rels
$drawingRels = $zip.Entries | Where-Object { $_.FullName -like "xl/drawings/_rels/*" -or $_.FullName -like "xl/worksheets/_rels/*" }
foreach ($rel in $drawingRels) {
    Write-Host "Drawing rel: $($rel.FullName)"
    $reader = New-Object System.IO.StreamReader($rel.Open())
    $content = $reader.ReadToEnd()
    $reader.Close()
    $relFile = Join-Path $outputDir ([System.IO.Path]::GetFileName($rel.FullName) + ".xml")
    [System.IO.File]::WriteAllText($relFile, $content)
}

$zip.Dispose()
Write-Host "SKT Excel extraction finished."
