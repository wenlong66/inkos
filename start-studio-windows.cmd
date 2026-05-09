@echo off
setlocal

cd /d "%~dp0"

echo [1/2] Building InkOS...
call npx pnpm --config.verify-deps-before-run=false build
if errorlevel 1 goto :failed

echo [2/2] Starting InkOS Studio...
call npx pnpm --config.verify-deps-before-run=false run start:studio
if errorlevel 1 goto :failed

goto :eof

:failed
echo.
echo Startup failed. Please check the output above.
exit /b 1
