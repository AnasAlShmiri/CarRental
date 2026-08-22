@echo off
setlocal EnableExtensions
cd /d "%~dp0"

where dotnet >nul 2>&1
if errorlevel 1 (
    echo .NET SDK was not found in PATH.
    echo Install the .NET 10 SDK, restart the terminal, and run this file again.
    pause
    exit /b 1
)

echo Starting CarRental API on http://localhost:5109 ...
start "CarRental API" "%~dp0Run-API.cmd"

echo Waiting for API to become ready ...
for /l %%I in (1,1,30) do (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -UseBasicParsing -Uri 'http://localhost:5109/health' -TimeoutSec 2 | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
    if not errorlevel 1 goto ApiReady
    timeout /t 1 /nobreak >nul
)

echo API did not become ready within 30 seconds.
echo Check the API window for the error message.
pause
exit /b 1

:ApiReady
echo API is ready.
echo Starting CarRental MVC on http://localhost:5110 ...
start "CarRental MVC" "%~dp0Run-MVC.cmd"
timeout /t 3 /nobreak >nul
start "" "http://localhost:5110"

endlocal
exit /b 0
