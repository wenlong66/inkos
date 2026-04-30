@echo off
setlocal

cd /d "%~dp0"

echo [1/2] Building InkOS...
call npx pnpm build
if errorlevel 1 goto :failed

echo [2/2] Starting InkOS Studio...
call npx pnpm run start:studio
if errorlevel 1 goto :failed

goto :eof

:failed
echo.
echo Startup failed. Please check the output above.
exit /b 1
