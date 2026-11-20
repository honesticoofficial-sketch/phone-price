$query = [System.Uri]::EscapeDataString("SKT T-down 하나카드")
$url = "https://search.naver.com/search.naver?where=nexearch&query=$query"

$resp = Invoke-WebRequest -Uri $url -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" -UseBasicParsing

Write-Host "Page Length: $($resp.Content.Length)"
$matches = [regex]::Matches($resp.Content, 'https://[^\s"''<>]+\.(?:png|jpg|jpeg)')
$cardImgs = @()
foreach ($m in $matches) {
    if ($m.Value -match 'card|dthumb|img|pstatic' -and $m.Value -notmatch 'icon|logo|banner|favicon|profile|sp_') {
        $cardImgs += $m.Value
    }
}
$cardImgs | Select-Object -Unique
