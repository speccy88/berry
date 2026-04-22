param(
    [string]$InstallDir = ".third_party_cache/catalina"
)

$ErrorActionPreference = "Stop"

if ((Test-Path (Join-Path $InstallDir "bin/catalina.exe")) -or (Test-Path (Join-Path $InstallDir "bin/catalina"))) {
    Write-Host "Catalina already present at $InstallDir"
    exit 0
}

Write-Host "Catalina is not installed in $InstallDir."
Write-Host ""
Write-Host "This repository no longer vendors Catalina."
Write-Host "Set CATALINA_DIR to an existing install, or set `$env:CATALINA_REPO and rerun this script."

if (-not $env:CATALINA_REPO) {
    exit 1
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $InstallDir) | Out-Null
git clone --depth 1 $env:CATALINA_REPO $InstallDir
