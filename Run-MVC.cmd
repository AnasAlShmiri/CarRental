@echo off
setlocal
cd /d "%~dp0CarRental.Web"
echo Starting CarRental MVC on http://localhost:5110 ...
dotnet run --launch-profile CarRental.Web
pause
