Add-Type -AssemblyName System.Drawing

$testImages = @(
    "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\test_loca_lgu.png",
    "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\test_download_lgu\LO_LGU_DC.png",
    "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\test_download_lgu\NH_LGU_Allone.png",
    "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\toss_lgu_imgs\woori_u_x.png",
    "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\toss_lgu_imgs\lgu_hyundai_m3.png",
    "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\toss_lgu_imgs\uplus_family_hana.png"
)

foreach ($p in $testImages) {
    if (Test-Path $p) {
        $bmp = [System.Drawing.Bitmap]::FromFile($p)
        Write-Host "$([System.IO.Path]::GetFileName($p)): $($bmp.Width) x $($bmp.Height) (IsVertical: $($bmp.Height -gt $bmp.Width))"
        $bmp.Dispose()
    }
}
