@echo off
setlocal EnableExtensions
cd /d "%~dp0"

echo Stopping CarRental services on ports 5109 and 5110 ...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ports = 5109,5110; foreach ($port in $ports) { Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue } }"

timeout /t 2 /nobreak >nul

echo CarRental API and MVC processes on the project ports have been stopped.
pause
exit /b 0
