$html = Get-Content "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html" -Raw

function Check-Snippet($name, $pattern) {
    if ($html -match $pattern) {
        Write-Host "FOUND: $name"
    } else {
        Write-Host "NOT FOUND: $name"
    }
}

Check-Snippet "SKT M3 HighlightBadge" 'SKT x 현대카드 쿠폰팩 프로모션 \(투썸/다이소/CU/올리브영/포인트샵 쿠폰 월 최대 22,700원\) & 최대 35,000원 할인 & 24/36개월 자유할부'
Check-Snippet "SKT M3 Bill HighlightBadge" 'SKT x 현대카드 쿠폰팩 프로모션 \(투썸/다이소/CU/올리브영/포인트샵 쿠폰 월 최대 22,700원\) & 매월 최대 35,000원 통신요금 자동이체 할인'
Check-Snippet "KT M3 HighlightBadge" '월 최대 35,000원 청구할인 & 현대카드 쿠폰팩 & 최대 35,000원 할인 & 24/36개월 자유할부'
