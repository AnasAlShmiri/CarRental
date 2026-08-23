@echo off
setlocal EnableExtensions

start "" "http://localhost:5110"
start "" "http://localhost:5109/swagger/index.html"

echo Opened:
echo   MVC:         http://localhost:5110
echo   API/Swagger: http://localhost:5109/swagger/index.html
exit /b 0
