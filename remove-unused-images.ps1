# Moves unreferenced images out of the repo into a backup folder next to it.
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
$unused = @($files | Where-Object { -not $used.ContainsKey($_.Name) })
$liveCount = $files.Count - $unused.Count
$unusedMB = [math]::Round((($unused | Measure-Object -Property Length -Sum).Sum / 1MB), 1)

Write-Host ""
Write-Host ("Live images kept:     " + $liveCount)
Write-Host ("Unused images found:  " + $unused.Count + "  (" + $unusedMB + " MB)")
Write-Host ""
if ($unused.Count -eq 0) { Write-Host "Nothing to move." -ForegroundColor Green; exit 0 }

$stamp = Get-Date -Format 'yyyy-MM-dd'
$dest = Join-Path (Split-Path $root -Parent) ('unused-images-backup-' + $stamp)
Write-Host ("They will be moved to: " + $dest)
Write-Host ""
$answer = Read-Host "Type YES to move them out of the repo"
if ($answer -ne 'YES') { Write-Host "Cancelled. Nothing changed." -ForegroundColor Yellow; exit 0 }

if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest | Out-Null }
$moved = 0
foreach ($f in $unused) {
    try { Move-Item -LiteralPath $f.FullName -Destination (Join-Path $dest $f.Name) -ErrorAction Stop; $moved++ }
    catch { Write-Host ("FAILED: " + $f.Name) -ForegroundColor Red }
}
Write-Host ""
Write-Host ("Moved: " + $moved + " files to " + $dest) -ForegroundColor Green
Write-Host ("Still in images: " + (Get-ChildItem -LiteralPath $imgDir -File).Count)
Write-Host ""
Write-Host "Next: in GitHub Desktop, commit the deletions and push." -ForegroundColor Green
