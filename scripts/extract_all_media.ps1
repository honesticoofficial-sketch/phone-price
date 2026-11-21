Add-Type -AssemblyName System.IO.Compression.FileSystem

$excelPath = "C:\Users\User01\Downloads\Telegram Desktop\2. 26.11월 제휴카드 안내_1호.xlsx"
$outputDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\skt_qr_images"

if (Test-Path $outputDir) { Remove-Item $outputDir -Recurse -Force }
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

$zip = [System.IO.Compression.ZipFile]::OpenRead($excelPath)
$mediaEntries = $zip.Entries | Where-Object { $_.FullName -like "xl/media/image*.png" -or $_.FullName -like "xl/media/image*.jpeg" }

foreach ($m in $mediaEntries) {
    $dest = Join-Path $outputDir ([System.IO.Path]::GetFileName($m.FullName))
    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($m, $dest, $true)
    Write-Host "Extracted $($m.FullName) -> $dest"
}

$zip.Dispose()
Write-Host "Extraction complete."
