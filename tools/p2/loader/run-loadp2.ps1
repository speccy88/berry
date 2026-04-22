param(
    [Parameter(Mandatory = $true)][string]$Loadp2,
    [Parameter(Mandatory = $true)][string]$Port,
    [Parameter(Mandatory = $true)][string]$Baud,
    [Parameter(Mandatory = $true)][string]$Flags,
    [Parameter(Mandatory = $true)][string]$Image
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $Image)) {
    throw "Missing image: $Image"
}

$flagArgs = @()
if ($Flags) {
    $flagArgs = $Flags.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)
}

& $Loadp2 -p $Port -b $Baud @flagArgs $Image
