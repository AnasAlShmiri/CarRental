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

if not exist "%~dp0CarRental.slnx" (
    echo CarRental.slnx was not found.
    pause
    exit /b 1
)

echo Restoring .NET packages...
dotnet restore "%~dp0CarRental.slnx"
if errorlevel 1 goto Failed

echo Building the .NET solution...
dotnet build "%~dp0CarRental.slnx" --no-restore
if errorlevel 1 goto Failed

set "FLUTTER_CMD="
for /f "delims=" %%F in ('where flutter 2^>nul') do if not defined FLUTTER_CMD set "FLUTTER_CMD=%%F"
if not defined FLUTTER_CMD if exist "%~dp0flutter\bin\flutter.bat" set "FLUTTER_CMD=%~dp0flutter\bin\flutter.bat"
if not defined FLUTTER_CMD if exist "%USERPROFILE%\flutter\bin\flutter.bat" set "FLUTTER_CMD=%USERPROFILE%\flutter\bin\flutter.bat"
if not defined FLUTTER_CMD if exist "%USERPROFILE%\development\flutter\bin\flutter.bat" set "FLUTTER_CMD=%USERPROFILE%\development\flutter\bin\flutter.bat"
if not defined FLUTTER_CMD if exist "%LOCALAPPDATA%\Programs\flutter\bin\flutter.bat" set "FLUTTER_CMD=%LOCALAPPDATA%\Programs\flutter\bin\flutter.bat"
if not defined FLUTTER_CMD if exist "C:\src\flutter\bin\flutter.bat" set "FLUTTER_CMD=C:\src\flutter\bin\flutter.bat"
if not defined FLUTTER_CMD if exist "C:\flutter\bin\flutter.bat" set "FLUTTER_CMD=C:\flutter\bin\flutter.bat"

if not defined FLUTTER_CMD (
    echo Flutter SDK was not found. .NET setup is complete; Flutter setup was skipped.
    pause
    exit /b 0
)

echo Using Flutter: %FLUTTER_CMD%
cd /d "%~dp0CarRental.Mobile"
call "%FLUTTER_CMD%" pub get
if errorlevel 1 goto Failed

echo Project setup completed successfully.
pause
exit /b 0

:Failed
echo.
echo Project setup failed. Review the message above.
pause
exit /b 1
