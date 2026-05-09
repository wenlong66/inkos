@echo off
setlocal

cd /d "%~dp0"

echo Starting InkOS Studio...
call npx pnpm --config.verify-deps-before-run=false run start:studio
if errorlevel 1 (
  echo.
  echo Startup failed. Please check the output above.
  exit /b 1
)
