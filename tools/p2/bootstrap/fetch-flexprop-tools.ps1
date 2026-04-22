param(
    [string]$InstallDir = ".third_party_cache/flexprop"
)

$ErrorActionPreference = "Stop"

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
$binDir = Join-Path $InstallDir "bin"
$includeDir = Join-Path $InstallDir "include"
New-Item -ItemType Directory -Force -Path $binDir | Out-Null

if ((Test-Path (Join-Path $binDir "flexcc.exe")) -and (Test-Path (Join-Path $binDir "loadp2.exe")) -and (Test-Path (Join-Path $includeDir "stddef.h"))) {
    Write-Host "FlexProp already present at $InstallDir"
    exit 0
}

if (-not $env:FLEXPROP_ZIP_URL) {
    Write-Host "Set `$env:FLEXPROP_ZIP_URL to a FlexProp release zip URL and rerun this script."
    Write-Host "The extracted tree should provide bin/*.exe and include/*."
    exit 1
}

$zipPath = Join-Path $env:TEMP "flexprop-tools.zip"
$extractPath = Join-Path $env:TEMP "flexprop-tools-extract"
Remove-Item -Recurse -Force $extractPath -ErrorAction SilentlyContinue
Invoke-WebRequest -Uri $env:FLEXPROP_ZIP_URL -OutFile $zipPath
Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

$sourceRoot = Get-ChildItem $extractPath | Select-Object -First 1
Copy-Item -Recurse -Force (Join-Path $sourceRoot.FullName "bin") $InstallDir
Copy-Item -Recurse -Force (Join-Path $sourceRoot.FullName "include") $InstallDir

Write-Host "FlexProp installed to $InstallDir"
