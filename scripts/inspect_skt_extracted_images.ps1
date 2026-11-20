Add-Type -AssemblyName System.Drawing

$imgDir = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\skt_excel_images"

$cards = @(
    @{ Col=3; Name="삼성카드 T프리미엄"; Img="image28.png" },
    @{ Col=4; Name="현대카드 M3 T라이트2"; Img="image19.png" },
    @{ Col=5; Name="우리카드 T라이트"; Img="image20.png" },
    @{ Col=6; Name="롯데카드 T라이트"; Img="image21.png" },
    @{ Col=7; Name="하나카드 T다운"; Img="???" },
    @{ Col=8; Name="신한카드 T라이트"; Img="image31.png" },
    @{ Col=9; Name="KB국민카드 T라이트"; Img="image22.png" },
    @{ Col=10; Name="BC바로 T라이트"; Img="image42.png" },
    @{ Col=11; Name="NH농협 T라이트"; Img="image25.png" },
    @{ Col=12; Name="신한카드 파인애플"; Img="image41.png" },
    @{ Col=13; Name="신한카드 T&LIFE"; Img="image37.png" },
    @{ Col=14; Name="KB국민카드 T이코노미"; Img="image26.png" },
    @{ Col=15; Name="현대카드 M3 통신할인형2.0"; Img="image23.png" },
    @{ Col=16; Name="롯데카드 TELLO NE"; Img="image45.png" },
    @{ Col=17; Name="하나카드 T나는혜택"; Img="image24.png" }
)

Write-Host "=== SKT Excel Extracted Images Inspection ==="
foreach ($c in $cards) {
    $imgPath = Join-Path $imgDir $c.Img
    if (Test-Path $imgPath) {
        $bmp = [System.Drawing.Image]::FromFile($imgPath)
        Write-Host "Col $($c.Col) [$($c.Name)] -> $($c.Img) : $($bmp.Width) x $($bmp.Height) (Ratio: $([Math]::Round($bmp.Width / $bmp.Height, 2)))"
        $bmp.Dispose()
    } else {
        Write-Host "Col $($c.Col) [$($c.Name)] -> MISSING / NEED TO FIND"
    }
}
