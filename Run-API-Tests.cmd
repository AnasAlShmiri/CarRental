@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "BASH_CMD="
for /f "delims=" %%F in ('where bash 2^>nul') do if not defined BASH_CMD set "BASH_CMD=%%F"
if not defined BASH_CMD if exist "C:\Program Files\Git\bin\bash.exe" set "BASH_CMD=C:\Program Files\Git\bin\bash.exe"
if not defined BASH_CMD if exist "C:\Program Files\Git\usr\bin\bash.exe" set "BASH_CMD=C:\Program Files\Git\usr\bin\bash.exe"

if not defined BASH_CMD (
    echo Bash was not found.
    echo Install Git for Windows or run tests/test_api.sh from Git Bash or WSL.
    pause
    exit /b 1
)

set "PYTHON_CMD="
where python3 >nul 2>&1
if not errorlevel 1 set "PYTHON_CMD=python3"
if not defined PYTHON_CMD (
    where python >nul 2>&1
    if not errorlevel 1 set "PYTHON_CMD=python"
)
if not defined PYTHON_CMD (
    echo Python was not found.
    echo Install Python and ensure python3 or python is available in PATH.
    pause
    exit /b 1
)

set "UPLOADS_DIR=CarRental.API/wwwroot/uploads"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { $r = Invoke-WebRequest -UseBasicParsing -Uri 'http://localhost:5109/health' -TimeoutSec 2; if ($r.StatusCode -eq 200) { exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>&1
if errorlevel 1 (
    echo API is not running on http://localhost:5109.
    echo Start Run-CarRental.cmd or Run-API.cmd first.
    pause
    exit /b 1
)

echo Running HTTP API tests...
set "PYTHON_CMD=%PYTHON_CMD%"
call "%BASH_CMD%" "%~dp0tests\test_api.sh"
set "EXIT_CODE=%errorlevel%"

if "%EXIT_CODE%"=="0" (
    echo HTTP API tests completed successfully.
) else (
    echo HTTP API tests failed with exit code %EXIT_CODE%.
)
pause
exit /b %EXIT_CODE%
