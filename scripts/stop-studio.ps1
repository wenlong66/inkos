$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$logDir = Join-Path $repoRoot '.claude/studio'
$pidFile = Join-Path $logDir 'studio.pid'

Write-Host 'Stopping packages/studio...'

function Stop-StudioProcess {
  param([int]$ProcessId)

  taskkill /PID $ProcessId /T /F | Out-Null
  return $LASTEXITCODE -eq 0
}

$stopped = $false
if (Test-Path $pidFile) {
  $recordedPid = (Get-Content $pidFile | Select-Object -First 1).Trim()
  if ($recordedPid) {
    $process = Get-CimInstance Win32_Process -Filter "ProcessId = $recordedPid" -ErrorAction SilentlyContinue
    if (
      $process -and
      $process.CommandLine -and
      $process.CommandLine -like "*$repoRoot*" -and
      ($process.CommandLine -like '*src/api/index.ts*' -or $process.CommandLine -like '*dist\api\index.js*')
    ) {
      Write-Host "Stopping PID $recordedPid..."
      if (Stop-StudioProcess $recordedPid) {
        $stopped = $true
      }
    }
  }
  Remove-Item $pidFile -Force
}

if (-not $stopped) {
  $matchingProcesses = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -and
    $_.CommandLine -like "*$repoRoot*" -and
    ($_.CommandLine -like '*src/api/index.ts*' -or $_.CommandLine -like '*dist\api\index.js*')
  }

  foreach ($process in $matchingProcesses) {
    Write-Host "Stopping PID $($process.ProcessId)..."
    if (Stop-StudioProcess $process.ProcessId) {
      $stopped = $true
    }
  }
}

if (-not $stopped) {
  Write-Host 'packages/studio is not running.'
  exit 0
}

Write-Host 'packages/studio stopped.'
