$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$childScript = Join-Path $repoRoot 'scripts/run-studio-child.ps1'
$logDir = Join-Path $repoRoot '.claude/studio'
$logStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$stdoutLog = Join-Path $logDir "studio-$logStamp.stdout.log"
$stderrLog = Join-Path $logDir "studio-$logStamp.stderr.log"
$pidFile = Join-Path $logDir 'studio.pid'
$port = 4567

function Test-StudioCommandLine {
  param([string]$CommandLine)

  $CommandLine -and
  $CommandLine -like "*$repoRoot*" -and (
    $CommandLine -like '*src/api/index.ts*' -or
    $CommandLine -like '*dist\api\index.js*'
  )
}

New-Item -ItemType Directory -Force -Path $logDir | Out-Null

& (Join-Path $repoRoot 'scripts/stop-studio.ps1') | Out-Null

$existingListener = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue |
  Select-Object -ExpandProperty OwningProcess -Unique |
  Select-Object -First 1
if ($existingListener) {
  $existingProcess = Get-CimInstance Win32_Process -Filter "ProcessId = $existingListener" -ErrorAction SilentlyContinue
  if (-not (Test-StudioCommandLine $existingProcess.CommandLine)) {
    throw "Port $port is already in use by another process (PID $existingListener)."
  }
}

if (Test-Path $pidFile) { Remove-Item $pidFile -Force }

Write-Host "Starting packages/studio on port $port..."

$process = Start-Process -FilePath 'powershell.exe' -ArgumentList @(
  '-NoProfile',
  '-ExecutionPolicy', 'Bypass',
  '-File', $childScript,
  '-RepoRoot', $repoRoot,
  '-Port', "$port"
) -WindowStyle Minimized -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog -PassThru
Set-Content -Path $pidFile -Value $process.Id

$deadline = (Get-Date).AddSeconds(60)
while ((Get-Date) -lt $deadline) {
  try {
    Invoke-WebRequest -Uri "http://127.0.0.1:$port" -UseBasicParsing | Out-Null
    $listenerPid = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue |
      Select-Object -ExpandProperty OwningProcess -Unique |
      Select-Object -First 1
    if ($listenerPid) {
      $listenerProcess = Get-CimInstance Win32_Process -Filter "ProcessId = $listenerPid" -ErrorAction SilentlyContinue
      if (Test-StudioCommandLine $listenerProcess.CommandLine) {
        Set-Content -Path $pidFile -Value $listenerPid
        Write-Host "packages/studio is running at http://localhost:$port"
        exit 0
      }

      throw "Port $port responded, but the listener PID $listenerPid is not packages/studio."
    }
  } catch {
    if ($_.Exception.Message -like 'Port * responded,*not packages/studio.*') {
      if (Get-Process -Id $process.Id -ErrorAction SilentlyContinue) {
        taskkill /PID $process.Id /T /F | Out-Null
      }
      if (Test-Path $pidFile) { Remove-Item $pidFile -Force }
      throw
    }

    Start-Sleep -Seconds 2
  }
}

if (Get-Process -Id $process.Id -ErrorAction SilentlyContinue) {
  taskkill /PID $process.Id /T /F | Out-Null
}
if (Test-Path $pidFile) { Remove-Item $pidFile -Force }

Write-Error "packages/studio did not become ready on port $port within 60 seconds. Logs: $stdoutLog ; $stderrLog"
