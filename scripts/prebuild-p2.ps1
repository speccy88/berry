param(
    [Parameter(Mandatory = $true)][string]$Python,
    [Parameter(Mandatory = $true)][string]$Coc,
    [Parameter(Mandatory = $true)][string]$Output,
    [Parameter(Mandatory = $true)][string]$Config,
    [Parameter(Mandatory = $true)][string]$SourcePaths
)

$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Force -Path $Output | Out-Null

$paths = $SourcePaths.Split(";") | Where-Object { $_ -ne "" }
& $Python $Coc -o $Output @paths -c $Config
