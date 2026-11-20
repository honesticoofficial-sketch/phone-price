[System.Reflection.Assembly]::LoadWithPartialName('System.Runtime.WindowsRuntime') | Out-Null
[Windows.Data.Pdf.PdfDocument, Windows.Data.Pdf, ContentType = WindowsRuntime] | Out-Null
[Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime] | Out-Null
[Windows.Storage.StorageFolder, Windows.Storage, ContentType = WindowsRuntime] | Out-Null

function Await-AsyncOp($asyncOp) {
    $asTaskMethod = [System.WindowsRuntimeSystemExtensions].GetMethods() | 
        Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -match 'IAsyncOperation' } |
        Select-Object -First 1
    
    $genericMethod = $asTaskMethod.MakeGenericMethod($asyncOp.GetType().GetGenericArguments()[0])
    $task = $genericMethod.Invoke($null, @($asyncOp))
    $task.Wait()
    return $task.Result
}

function Await-AsyncAction($asyncAction) {
    $asTaskMethod = [System.WindowsRuntimeSystemExtensions].GetMethods() | 
        Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -match 'IAsyncAction' } |
        Select-Object -First 1
    $task = $asTaskMethod.Invoke($null, @($asyncAction))
    $task.Wait()
}

$pdfPath = "C:\Users\User01\.gemini\antigravity\brain\af18e558-85da-49ae-9eb0-4c9b6d7b02ae\.user_uploaded\media_1795153661234_0b7c7c83.pdf"
$outputDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\pdf_pages"
if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir -Force | Out-Null }

$file = Await-AsyncOp ([Windows.Storage.StorageFile]::GetFileFromPathAsync($pdfPath))
$doc = Await-AsyncOp ([Windows.Data.Pdf.PdfDocument]::LoadFromFileAsync($file))

Write-Host "Total PDF Pages: $($doc.PageCount)"

$folder = Await-AsyncOp ([Windows.Storage.StorageFolder]::GetFolderFromPathAsync($outputDir))

for ($i = 0; $i -lt $doc.PageCount; $i++) {
    $page = $doc.GetPage($i)
    $targetFile = Await-AsyncOp ($folder.CreateFileAsync("page_$($i + 1).png", [Windows.Storage.CreationCollisionOption]::ReplaceExisting))
    $stream = Await-AsyncOp ($targetFile.OpenAsync([Windows.Storage.FileAccessMode]::ReadWrite))
    
    $opt = [Windows.Data.Pdf.PdfPageRenderOptions]::new()
    $opt.DestinationWidth = [uint32]($page.Dimensions.ArtBox.Width * 2)
    
    Await-AsyncAction ($page.RenderToStreamAsync($stream, $opt))
    Await-AsyncAction ($stream.FlushAsync())
    $stream.Dispose()
    Write-Host "Rendered page $($i + 1)"
}
