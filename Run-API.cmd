@echo off
setlocal
cd /d "%~dp0CarRental.API"
echo Starting CarRental API on http://localhost:5109 ...
dotnet run --launch-profile http
pause
