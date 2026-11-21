$data = Get-Content 'C:\Users\User01\.gemini\antigravity\scratch\phone-price\data\ground_truth_skt_202611.json' -Raw | ConvertFrom-Json
$data | ForEach-Object {
    [PSCustomObject]@{
        name = $_.card_name
        company = $_.card_company
        apply_url = $_.urls.apply_url
        promo_url = $_.urls.promo_url
    }
} | Format-List
