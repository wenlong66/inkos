param(
  [Parameter(Mandatory = $true)]
  [string]$RepoRoot,
  [int]$Port = 4567
)

$ErrorActionPreference = 'Stop'
$studioDir = Join-Path $RepoRoot 'packages/studio'

Set-Location $studioDir
$env:INKOS_STUDIO_PORT = "$Port"

npx tsx src/api/index.ts $RepoRoot
