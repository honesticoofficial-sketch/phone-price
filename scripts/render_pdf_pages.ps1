$pdfPath = "C:\Users\User01\.gemini\antigravity\brain\af18e558-85da-49ae-9eb0-4c9b6d7b02ae\.user_uploaded\media_1795153661234_0b7c7c83.pdf"
$outputDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\pdf_pages"
if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir -Force | Out-Null }

[Windows.Data.Pdf.PdfDocument, Windows.Data.Pdf, ContentType = WindowsRuntime] | Out-Null
[Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime] | Out-Null
[Windows.Storage.StorageFolder, Windows.Storage, ContentType = WindowsRuntime] | Out-Null

$asyncOp = [Windows.Storage.StorageFile]::GetFileFromPathAsync($pdfPath)
while ($asyncOp.Status -eq 'Started') { Start-Sleep -Milliseconds 50 }
$file = $asyncOp.GetResults()

$asyncDoc = [Windows.Data.Pdf.PdfDocument]::LoadFromFileAsync($file)
while ($asyncDoc.Status -eq 'Started') { Start-Sleep -Milliseconds 50 }
$doc = $asyncDoc.GetResults()

Write-Host "Total PDF Pages: $($doc.PageCount)"

$storageFolderAsync = [Windows.Storage.StorageFolder]::GetFolderFromPathAsync($outputDir)
while ($storageFolderAsync.Status -eq 'Started') { Start-Sleep -Milliseconds 20 }
$storageFolder = $storageFolderAsync.GetResults()

for ($i = 0; $i -lt $doc.PageCount; $i++) {
    $page = $doc.GetPage($i)
    $fileName = "page_$($i + 1).png"
    
    $createFileAsync = $storageFolder.CreateFileAsync($fileName, [Windows.Storage.CreationCollisionOption]::ReplaceExisting)
    while ($createFileAsync.Status -eq 'Started') { Start-Sleep -Milliseconds 20 }
    $targetFile = $createFileAsync.GetResults()
    
    $streamAsync = $targetFile.OpenAsync([Windows.Storage.FileAccessMode]::ReadWrite)
    while ($streamAsync.Status -eq 'Started') { Start-Sleep -Milliseconds 20 }
    $stream = $streamAsync.GetResults()
    
    $renderOptions = [Windows.Data.Pdf.PdfPageRenderOptions]::new()
    $renderOptions.DestinationWidth = [uint32]($page.Dimensions.ArtBox.Width * 2)
    
    $renderAsync = $page.RenderToStreamAsync($stream, $renderOptions)
    while ($renderAsync.Status -eq 'Started') { Start-Sleep -Milliseconds 50 }
    
    $flushAsync = $stream.FlushAsync()
    while ($flushAsync.Status -eq 'Started') { Start-Sleep -Milliseconds 20 }
    $stream.Dispose()
    Write-Host "Rendered page $($i + 1)"
}
