$imgDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\skt_excel_images"
$htmlPath = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\skt_excel_images_catalog.html"

$files = Get-ChildItem $imgDir -Include *.png, *.jpeg, *.jpg -Recurse | Sort-Object { [int]($_.BaseName -replace '\D','') }

$html = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>SKT Excel Images Catalog</title>
<style>
  body { font-family: sans-serif; background: #f0f2f5; padding: 20px; }
  .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 16px; }
  .card { background: white; border-radius: 8px; padding: 12px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); text-align: center; }
  img { max-width: 100%; max-height: 180px; object-fit: contain; border-radius: 4px; background: #eee; }
  .meta { font-size: 13px; color: #555; margin-top: 8px; font-weight: bold; }
</style>
</head>
<body>
<h1>SKT 11월 엑셀 공문 내 미디어 전체 목록 (총 $($files.Count)개)</h1>
<div class="grid">
"@

foreach ($f in $files) {
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $b64 = [System.Convert]::ToBase64String($bytes)
    $ext = $f.Extension.TrimStart('.').ToLower()
    if ($ext -eq "jpg") { $ext = "jpeg" }
    $mime = "image/$ext"
    
    $html += @"
  <div class="card">
    <img src="data:$mime;base64,$b64" />
    <div class="meta">$($f.Name) ($([Math]::Round($f.Length/1024, 1)) KB)</div>
  </div>
"@
}

$html += @"
</div>
</body>
</html>
"@

[System.IO.File]::WriteAllText($htmlPath, $html, [System.Text.Encoding]::UTF8)
Write-Host "Created catalog at: $htmlPath"
