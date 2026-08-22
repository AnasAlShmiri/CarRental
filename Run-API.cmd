@echo off
setlocal EnableExtensions
cd /d "%~dp0CarRental.API"

where dotnet >nul 2>&1
if errorlevel 1 (
    echo .NET SDK was not found in PATH.
    echo Install the .NET 10 SDK, restart the terminal, and run this file again.
    pause
    exit /b 1
)

echo Starting CarRental API on http://localhost:5109 ...
dotnet run --launch-profile http
pause
endlocal
