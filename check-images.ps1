# Reports what is in .\images: renamed files, files still under old names, and leftovers.
$root = $PSScriptRoot
$imgDir = Join-Path $root 'images'
if (-not (Test-Path $imgDir)) { Write-Host "No images folder next to this script." -ForegroundColor Red; exit 1 }
$mapFile = Join-Path $root 'rename-map.tsv'
if (-not (Test-Path $mapFile)) { Write-Host "rename-map.tsv is missing - keep it next to this script." -ForegroundColor Red; exit 1 }

$oldNames = @{}; $newNames = @{}
foreach ($line in Get-Content -LiteralPath $mapFile) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $p = $line -split "`t"
    if ($p.Count -lt 2) { continue }
    $oldNames[(Split-Path $p[0] -Leaf)] = $true
    $newNames[(Split-Path $p[1] -Leaf)] = $true
}

$files = Get-ChildItem -LiteralPath $imgDir -File
$renamedOk = 0; $stillOld = 0; $leftovers = New-Object System.Collections.Generic.List[string]
foreach ($f in $files) {
    if ($newNames.ContainsKey($f.Name)) { $renamedOk++ }
    elseif ($oldNames.ContainsKey($f.Name)) { $stillOld++; $leftovers.Add($f.Name) }
    else { $leftovers.Add($f.Name) }
}
$stillOldNames = @($files | Where-Object { $oldNames.ContainsKey($_.Name) } | ForEach-Object { $_.Name })
$unmatched = @($files | Where-Object { -not $newNames.ContainsKey($_.Name) -and -not $oldNames.ContainsKey($_.Name) } | ForEach-Object { $_.Name })

Write-Host ""
Write-Host ("Total files in images:        " + $files.Count)
Write-Host ("Renamed (new names):          " + $renamedOk)
Write-Host ("Still using old names:        " + $stillOldNames.Count) -ForegroundColor Yellow
Write-Host ("Other files (not referenced): " + $unmatched.Count) -ForegroundColor Yellow
Write-Host ""
if ($stillOldNames.Count -gt 0) {
    Write-Host "First 10 files still on old names:" -ForegroundColor Yellow
    $stillOldNames | Select-Object -First 10 | ForEach-Object { Write-Host ("  " + $_) }
    Write-Host ""
}
if ($unmatched.Count -gt 0) {
    Write-Host "First 10 unreferenced files:" -ForegroundColor Yellow
    $unmatched | Select-Object -First 10 | ForEach-Object { Write-Host ("  " + $_) }
    Write-Host ""
}
$out = Join-Path $root 'unused-images.txt'
($stillOldNames + $unmatched) | Sort-Object | Set-Content -LiteralPath $out
Write-Host ("Full list written to: " + $out)
Write-Host ""
Write-Host "Nothing was changed. Send me the four numbers above." -ForegroundColor Green
