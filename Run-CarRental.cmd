@echo off
setlocal
cd /d "%~dp0"

echo Starting CarRental API on http://localhost:5109 ...
start "CarRental API" "%~dp0Run-API.cmd"

echo Waiting for API to become ready ...
for /l %%I in (1,1,30) do (
    curl.exe --silent --fail http://localhost:5109/health >nul 2>&1
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
