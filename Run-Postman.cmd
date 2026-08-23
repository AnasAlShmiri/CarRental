@echo off
setlocal EnableExtensions
cd /d "%~dp0"

where npx >nul 2>&1
if errorlevel 1 (
    echo Node.js and npx were not found in PATH.
    echo Install Node.js, restart the terminal, and run this file again.
    pause
    exit /b 1
)

if not exist "%~dp0docs\CarRental.postman_collection.json" (
    echo Postman collection was not found.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { $r = Invoke-WebRequest -UseBasicParsing -Uri 'http://localhost:5109/health' -TimeoutSec 2; if ($r.StatusCode -eq 200) { exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>&1
if errorlevel 1 (
    echo API is not running on http://localhost:5109.
    echo Start Run-CarRental.cmd or Run-API.cmd first.
    pause
    exit /b 1
)

if not defined CARRENTAL_ADMIN_PASSWORD set /p "CARRENTAL_ADMIN_PASSWORD=Enter the development admin password: "
if not defined CARRENTAL_ADMIN_PASSWORD (
    echo An admin password is required to run the collection.
    pause
    exit /b 1
)

echo Running CarRental Postman collection...
call npx --yes newman run "%~dp0docs\CarRental.postman_collection.json" --env-var "adminPassword=%CARRENTAL_ADMIN_PASSWORD%"
set "EXIT_CODE=%errorlevel%"

if "%EXIT_CODE%"=="0" (
    echo Postman collection completed successfully.
) else (
    echo Postman collection failed with exit code %EXIT_CODE%.
)
pause
exit /b %EXIT_CODE%
