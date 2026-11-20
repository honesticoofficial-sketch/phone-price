Add-Type -AssemblyName System.Drawing

$imgDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\skt_excel_images"
$files = Get-ChildItem $imgDir -Include *.png, *.jpeg, *.jpg -Recurse

$results = @()
foreach ($f in $files) {
    try {
        $img = [System.Drawing.Image]::FromFile($f.FullName)
        $ratio = [Math]::Round($img.Width / $img.Height, 2)
        $results += [PSCustomObject]@{
            Name = $f.Name
            SizeKB = [Math]::Round($f.Length / 1024, 1)
            Width = $img.Width
            Height = $img.Height
            Ratio = $ratio
        }
        $img.Dispose()
    } catch {}
}

$results | Sort-Object Ratio | Format-Table -AutoSize
