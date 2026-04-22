param(
    [string]$UpstreamUrl = "https://github.com/berry-lang/berry.git"
)

$ErrorActionPreference = "Stop"

try {
    git remote get-url upstream | Out-Null
} catch {
    git remote add upstream $UpstreamUrl
}

git fetch upstream
git remote -v | Select-String '^upstream'
