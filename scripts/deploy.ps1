#requires -Version 5.1
<#
.SYNOPSIS
  Copy the addon into the WoW AddOns folder for in-game testing.
.PARAMETER Dest
  Target <client>\Interface\AddOns\BeastBond folder. If omitted, uses $env:BEASTBOND_DEST,
  then the first line of scripts/.deploy-dest (ignored by git).
#>
param([string]$Dest)

$ErrorActionPreference = "Stop"
$src = Split-Path -Parent $PSScriptRoot

if (-not $Dest) { $Dest = $env:BEASTBOND_DEST }
$destFile = Join-Path $PSScriptRoot ".deploy-dest"
if (-not $Dest -and (Test-Path $destFile)) { $Dest = (Get-Content $destFile -TotalCount 1).Trim() }
if (-not $Dest) {
    throw "No destination. Pass -Dest '<client>\Interface\AddOns\BeastBond', set `$env:BEASTBOND_DEST, or put the path in scripts/.deploy-dest."
}

if ((Split-Path -Leaf $Dest) -ne "BeastBond") {
    throw "Refusing to mirror into '$Dest': folder must be named BeastBond (/MIR deletes extra files)."
}
if (-not (Test-Path (Split-Path -Parent $Dest))) {
    throw "AddOns folder not found: $(Split-Path -Parent $Dest)"
}

# /MIR removes stale files (renamed/deleted modules) in the destination.
robocopy $src $Dest *.lua *.toc /S /MIR /XD .git .github scripts .release | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy failed ($LASTEXITCODE)" }

$branch = git -C $src branch --show-current
Write-Host "Deployed '$branch' -> $Dest. Now /reload in game."
