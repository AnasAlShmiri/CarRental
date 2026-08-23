@echo off
setlocal EnableExtensions
cd /d "%~dp0"

where dotnet >nul 2>&1
if errorlevel 1 (
    echo .NET SDK was not found in PATH.
    pause
    exit /b 1
)

if not exist "%~dp0CarRental.slnx" (
    echo CarRental.slnx was not found.
    pause
    exit /b 1
)

echo Building the .NET solution...
dotnet build "%~dp0CarRental.slnx"
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
    echo Flutter SDK was not found. .NET checks passed; Flutter checks were skipped.
    pause
    exit /b 0
)

cd /d "%~dp0CarRental.Mobile"
echo Running Flutter analyzer...
call "%FLUTTER_CMD%" analyze --no-fatal-infos --no-fatal-warnings
if errorlevel 1 goto Failed

echo Running Flutter tests...
call "%FLUTTER_CMD%" test
if errorlevel 1 goto Failed

echo All build and automated checks passed.
pause
exit /b 0

:Failed
echo.
echo One or more checks failed. Review the message above.
pause
exit /b 1
