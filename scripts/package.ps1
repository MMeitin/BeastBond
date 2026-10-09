#requires -Version 5.1
<#
.SYNOPSIS
  Builds dist/BeastBond-<version>.zip, ready to upload to CurseForge or Wago by hand.
.PARAMETER Version
  Version string written into the .toc (default: the newest changelog heading).
#>
param([string]$Version)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

if (-not $Version) {
    $heading = Select-String -Path "$root\CHANGELOG.md" -Pattern '^## (\S+)' |
        Where-Object { $_.Matches[0].Groups[1].Value -ne "Unreleased" } | Select-Object -First 1
    $Version = $heading.Matches[0].Groups[1].Value
}

bash "$root/scripts/check-toc.sh"
if ($LASTEXITCODE -ne 0) { throw "toc check failed" }

$stage = Join-Path $root "dist\stage\BeastBond"
Remove-Item (Join-Path $root "dist") -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $stage | Out-Null

# Addon files only: the .toc, Lua, locale/data folders, license and changelog
$files = Get-Content "$root\BeastBond.toc" | Where-Object { $_ -and $_ -notmatch '^\s*##' }
foreach ($f in $files) {
    $dest = Join-Path $stage $f
    New-Item -ItemType Directory -Force (Split-Path -Parent $dest) | Out-Null
    Copy-Item (Join-Path $root $f) $dest
}
if (Test-Path "$root\Media") {
    New-Item -ItemType Directory -Force "$stage\Media" | Out-Null
    Copy-Item "$root\Media\*.tga" "$stage\Media"
}
Copy-Item "$root\LICENSE", "$root\CHANGELOG.md" $stage

# Stamp the version where the packager would
$toc = Join-Path $stage "BeastBond.toc"
$content = [System.IO.File]::ReadAllText("$root\BeastBond.toc").Replace("@project-version@", $Version)
[System.IO.File]::WriteAllText($toc, $content, (New-Object System.Text.UTF8Encoding($false)))

$zip = Join-Path $root "dist\BeastBond-$Version.zip"
# Compress-Archive (PS 5.1) writes backslash entry names that break on other platforms; write '/' entries ourselves.
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::Open($zip, "Create")
try {
    $base = (Join-Path $root "dist\stage").Length + 1
    foreach ($file in Get-ChildItem (Join-Path $root "dist\stage") -Recurse -File) {
        $entry = $file.FullName.Substring($base).Replace("\", "/")
        [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $entry)
    }
} finally { $archive.Dispose() }
Write-Host "Built $zip"
Get-ChildItem $stage -Recurse -File | ForEach-Object { "  " + $_.FullName.Substring($stage.Length + 1) }
