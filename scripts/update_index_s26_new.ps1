$path = "C:\Users\User01\.gemini\antigravity\scratch\phone-price\index.html"
$content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

$target = @"
        ad: {
          SK: { mnp: '5', chg: '-10', note: '', hidden: false },
          KT: { mnp: '-15', chg: '-15', note: '', hidden: false },
          LG: { mnp: '-20', chg: '-25', note: '*인상전', hidden: false }
        }
      },
"@

$replacement = @"
        ad: {
          SK: { mnp: '5', chg: '-10', note: '', hidden: false },
          KT: { mnp: '-15', chg: '-15', note: '', hidden: false },
          LG: { mnp: '-20', chg: '-25', note: '*인상전', hidden: false }
        }
      },
      {
        id: 's26_new', group: 'S', tag: '#S26', name: '갤럭시 S26 NEW',
        prices: { SK: 140.36, KT: 140.36, LG: 140.36 },
        sub: { SK: { mnp: 75, chg: 75 }, KT: { mnp: 75, chg: 75 }, LG: { mnp: 75, chg: 75 } },
        rate: { SK: { mnp: 59, chg: 62 }, KT: { mnp: 78, chg: 68 }, LG: { mnp: 83, chg: 79 } },
        loc: {
          SK: { mnp: '도매', chg: '도매' },
          KT: { mnp: '도매', chg: '도매' },
          LG: { mnp: '도매', chg: '도매' }
        },
        ad: {
          SK: { mnp: '0', chg: '0', note: '출고가인상', hidden: false },
          KT: { mnp: '0', chg: '0', note: '출고가인상', hidden: false },
          LG: { mnp: '0', chg: '0', note: '출고가인상', hidden: false }
        }
      },
"@

if ($content.Contains("id: 's26_new'")) {
    Write-Host "Already contains s26_new!"
} else {
    # Normalize CRLF for matching
    $targetNorm = $target.Replace("`r`n", "`n")
    $contentNorm = $content.Replace("`r`n", "`n")
    if ($contentNorm.Contains($targetNorm)) {
        $newContentNorm = $contentNorm.Replace($targetNorm, $replacement.Replace("`r`n", "`n"))
        [System.IO.File]::WriteAllText($path, $newContentNorm.Replace("`n", "`r`n"), [System.Text.Encoding]::UTF8)
        Write-Host "Successfully added s26_new to index.html!"
    } else {
        Write-Host "Target not found in contentNorm!"
    }
}
