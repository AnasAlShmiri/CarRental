@echo off
setlocal EnableExtensions
cd /d "%~dp0CarRental.Mobile"

set "FLUTTER_CMD="
for /f "delims=" %%F in ('where flutter 2^>nul') do if not defined FLUTTER_CMD set "FLUTTER_CMD=%%F"

if not defined FLUTTER_CMD if exist "%~dp0flutter\bin\flutter.bat" set "FLUTTER_CMD=%~dp0flutter\bin\flutter.bat"
if not defined FLUTTER_CMD if exist "%USERPROFILE%\flutter\bin\flutter.bat" set "FLUTTER_CMD=%USERPROFILE%\flutter\bin\flutter.bat"
if not defined FLUTTER_CMD if exist "%USERPROFILE%\development\flutter\bin\flutter.bat" set "FLUTTER_CMD=%USERPROFILE%\development\flutter\bin\flutter.bat"
if not defined FLUTTER_CMD if exist "%LOCALAPPDATA%\Programs\flutter\bin\flutter.bat" set "FLUTTER_CMD=%LOCALAPPDATA%\Programs\flutter\bin\flutter.bat"
if not defined FLUTTER_CMD if exist "C:\src\flutter\bin\flutter.bat" set "FLUTTER_CMD=C:\src\flutter\bin\flutter.bat"
if not defined FLUTTER_CMD if exist "C:\flutter\bin\flutter.bat" set "FLUTTER_CMD=C:\flutter\bin\flutter.bat"

if not defined FLUTTER_CMD (
  echo Flutter SDK was not found.
  echo Install Flutter, or add its bin folder to PATH, then run this file again.
  echo Expected executable: flutter.bat
  pause
  exit /b 1
)

echo Using Flutter: %FLUTTER_CMD%
echo Installing Flutter packages...
call "%FLUTTER_CMD%" pub get
if errorlevel 1 (
  echo Flutter packages could not be installed.
  pause
  exit /b 1
)

echo Starting CarRental Mobile...
call "%FLUTTER_CMD%" run
pause
