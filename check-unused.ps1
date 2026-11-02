# Reports unreferenced images in .\images and checks whether they duplicate a live image.
$root = $PSScriptRoot
$imgDir = Join-Path $root 'images'
$mapFile = Join-Path $root 'rename-map.tsv'
if (-not (Test-Path $imgDir)) { Write-Host "No images folder next to this script." -ForegroundColor Red; exit 1 }
if (-not (Test-Path $mapFile)) { Write-Host "rename-map.tsv is missing." -ForegroundColor Red; exit 1 }

$used = @{}
foreach ($line in Get-Content -LiteralPath $mapFile) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $p = $line -split "`t"
    if ($p.Count -lt 2) { continue }
    $used[(Split-Path $p[1] -Leaf)] = $true
}

$files = Get-ChildItem -LiteralPath $imgDir -File
$live = @($files | Where-Object { $used.ContainsKey($_.Name) })
$unused = @($files | Where-Object { -not $used.ContainsKey($_.Name) })
Write-Host ""
Write-Host ("Live images:   " + $live.Count)
Write-Host ("Unused images: " + $unused.Count)
$unusedMB = [math]::Round((($unused | Measure-Object -Property Length -Sum).Sum / 1MB), 1)
Write-Host ("Unused size:   " + $unusedMB + " MB")
Write-Host ""
Write-Host "Hashing to check for exact duplicates (this takes a minute)..."
$liveHash = @{}
foreach ($f in $live) {
    $h = (Get-FileHash -LiteralPath $f.FullName -Algorithm MD5).Hash
    if (-not $liveHash.ContainsKey($h)) { $liveHash[$h] = $f.Name }
}
$dupes = 0; $uniq = 0
$report = New-Object System.Collections.Generic.List[string]
foreach ($f in $unused) {
    $h = (Get-FileHash -LiteralPath $f.FullName -Algorithm MD5).Hash
    if ($liveHash.ContainsKey($h)) { $dupes++; $report.Add($f.Name + "`tDUPLICATE of " + $liveHash[$h]) }
    else { $uniq++; $report.Add($f.Name + "`tUNIQUE (no live copy)") }
}
Write-Host ""
Write-Host ("Exact duplicates of a live image: " + $dupes) -ForegroundColor Green
Write-Host ("Unique images (no live copy):     " + $uniq) -ForegroundColor Yellow
$out = Join-Path $root 'unused-images-report.txt'
$report | Set-Content -LiteralPath $out
Write-Host ""
Write-Host ("Full list: " + $out)
Write-Host "Nothing was deleted or moved." -ForegroundColor Green
