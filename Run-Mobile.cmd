@echo off
setlocal
cd /d "%~dp0CarRental.Mobile"
echo Installing Flutter packages...
flutter pub get
if errorlevel 1 (
  echo Flutter packages could not be installed.
  pause
  exit /b 1
)
echo Starting CarRental Mobile...
flutter run
pause
