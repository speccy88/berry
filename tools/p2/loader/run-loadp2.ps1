param(
    [Parameter(Mandatory = $true)][string]$Loadp2,
    [Parameter(Mandatory = $true)][string]$Port,
    [Parameter(Mandatory = $true)][string]$Baud,
    [Parameter(Mandatory = $true)][string]$Flags,
    [Parameter(Mandatory = $true)][string]$Image
)

$ErrorActionPreference = "Stop"

if (-not $Image.StartsWith("@") -and -not (Test-Path $Image)) {
    throw "Missing image: $Image"
}

$stale = Get-CimInstance Win32_Process |
    Where-Object {
        $_.CommandLine -match [regex]::Escape($Port) -and (
            $_.Name -match 'loadp2' -or
            $_.Name -match 'proploader' -or
            $_.Name -match 'tio' -or
            $_.CommandLine -match 'serial_terminal.py'
        )
    }
foreach ($proc in $stale) {
    Write-Host "[Loader] stopping stale terminal on $Port (pid $($proc.ProcessId))"
    Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue
}

$flagArgs = @()
if ($Flags) {
    $flagArgs = $Flags.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)
}

$interactive = $flagArgs -contains "-t" -or $flagArgs -contains "-T" -or $flagArgs -contains "-xTERM"
if ($interactive) {
    Write-Host "[Loader] Press Ctrl-D or Ctrl-C at an empty berry prompt to quit Berry."
    Write-Host "[Loader] Press Ctrl-] to leave loadp2 terminal mode directly."
}

& $Loadp2 -p $Port -b $Baud @flagArgs $Image
