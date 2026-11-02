# Renames every image in .\images to the new year-title pattern.
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
if (-not (Test-Path (Join-Path $root 'images'))) {
    Write-Host "No images folder next to this script. Put rename-images.bat in your news-articles-backup folder." -ForegroundColor Red
    exit 1
}
$mapFile = Join-Path $root 'rename-map.tsv'
if (-not (Test-Path $mapFile)) { Write-Host "rename-map.tsv is missing." -ForegroundColor Red; exit 1 }

$renamed = 0; $skipped = 0; $missing = 0; $failed = 0
foreach ($line in Get-Content -LiteralPath $mapFile) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $parts = $line -split "`t"
    if ($parts.Count -lt 2) { continue }
    $old = Join-Path $root $parts[0]
    $new = Join-Path $root $parts[1]
    if (Test-Path -LiteralPath $new) { $skipped++; continue }
    if (Test-Path -LiteralPath $old) {
        try { Move-Item -LiteralPath $old -Destination $new -ErrorAction Stop; $renamed++ }
        catch { Write-Host ("FAILED: " + $parts[0]) -ForegroundColor Red; $failed++ }
    } else { $missing++ }
}
Write-Host ""
Write-Host ("Renamed: {0}   Already new: {1}   Not found: {2}   Failed: {3}" -f $renamed, $skipped, $missing, $failed)
if ($renamed -gt 0) {
    Write-Host ""
    Write-Host "Next: replace index.html and data\news_articles.json with the ones from the ZIP," -ForegroundColor Green
    Write-Host "then commit and push in GitHub Desktop." -ForegroundColor Green
}
