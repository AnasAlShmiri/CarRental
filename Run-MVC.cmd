@echo off
setlocal EnableExtensions
cd /d "%~dp0CarRental.Web"

where dotnet >nul 2>&1
if errorlevel 1 (
    echo .NET SDK was not found in PATH.
    echo Install the .NET 10 SDK, restart the terminal, and run this file again.
    pause
    exit /b 1
)

echo Starting CarRental MVC on http://localhost:5110 ...
dotnet run --launch-profile CarRental.Web
pause
endlocal
