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
    echo Run this file from the repository root or restore the complete project.
    pause
    exit /b 1
)

set "ASPNETCORE_ENVIRONMENT=Development"
set "ASPNETCORE_URLS=http://localhost:5109"

echo Starting CarRental API on http://localhost:5109 ...
echo Press Ctrl+C to stop the API.
dotnet run --project "%~dp0CarRental.API\CarRental.API.csproj" --no-launch-profile
set "EXIT_CODE=%errorlevel%"

if not "%EXIT_CODE%"=="0" (
    echo.
    echo API stopped with exit code %EXIT_CODE%.
)
pause
exit /b %EXIT_CODE%
endlocal
