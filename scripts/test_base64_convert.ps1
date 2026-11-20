$images = @{
    "lgu_nh_allone" = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\test_download_lgu\NH_LGU_Allone.png"
    "lgu_lotte_loca" = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\toss_lgu_imgs\lgu_loca.png"
    "lgu_lotte_light" = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\toss_lgu_imgs\lgu_loca.png"
    "lgu_lotte_dc" = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\test_download_lgu\LO_LGU_DC.png"
    "lgu_woori_36" = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\toss_lgu_imgs\woori_u_x.png"
    "lgu_hyundai_m3" = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\toss_lgu_imgs\lgu_hyundai_m3.png"
    "lgu_hana_family" = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\scratch\toss_lgu_imgs\uplus_family_hana.png"
}

foreach ($key in $images.Keys) {
    $path = $images[$key]
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $b64 = [Convert]::ToBase64String($bytes)
    Write-Host "$key -> Length: $($bytes.Length) bytes (Base64: $($b64.Length) chars)"
}
