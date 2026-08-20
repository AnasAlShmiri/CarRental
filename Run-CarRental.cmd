@echo off
setlocal
start "CarRental API" "%~dp0Run-API.cmd"
start "CarRental MVC" "%~dp0Run-MVC.cmd"
timeout /t 5 /nobreak >nul
start "" "http://localhost:5110"
