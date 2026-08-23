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

if not exist "%~dp0CarRental.API\CarRental.API.csproj" (
    echo CarRental.API project was not found.
    pause
    exit /b 1
)

if not exist "%~dp0CarRental.Web\CarRental.Web.csproj" (
    echo CarRental.Web project was not found.
    pause
    exit /b 1
)

call :IsHealthy "http://localhost:5109/health"
if not errorlevel 1 (
    echo CarRental API is already running on http://localhost:5109.
) else (
    echo Starting CarRental API on http://localhost:5109 ...
    start "CarRental API" cmd /k call "%~dp0Run-API.cmd"
    call :WaitForHealth "http://localhost:5109/health" "API"
    if errorlevel 1 exit /b 1
)

call :IsHealthy "http://localhost:5110/health"
if not errorlevel 1 (
    echo CarRental MVC is already running on http://localhost:5110.
) else (
    echo Starting CarRental MVC on http://localhost:5110 ...
    start "CarRental MVC" cmd /k call "%~dp0Run-MVC.cmd"
    call :WaitForHealth "http://localhost:5110/health" "MVC"
    if errorlevel 1 exit /b 1
)

echo.
echo CarRental is running:
echo   API/Swagger: http://localhost:5109/swagger/index.html
echo   MVC:         http://localhost:5110
start "" "http://localhost:5110"
start "" "http://localhost:5109/swagger/index.html"
exit /b 0

:IsHealthy
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { $r = Invoke-WebRequest -UseBasicParsing -Uri '%~1' -TimeoutSec 2; if ($r.StatusCode -eq 200) { exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>&1
exit /b %errorlevel%

:WaitForHealth
set "WAIT_URL=%~1"
set "WAIT_NAME=%~2"
echo Waiting for %WAIT_NAME% to become ready ...
for /l %%I in (1,1,30) do (
    call :IsHealthy "%WAIT_URL%"
    if not errorlevel 1 exit /b 0
    timeout /t 1 /nobreak >nul
)
echo %WAIT_NAME% did not become ready within 30 seconds.
echo Check the corresponding service window for the error message.
pause
exit /b 1
