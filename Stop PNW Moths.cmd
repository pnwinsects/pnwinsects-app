@echo off
cd /d "%~dp0"

if not exist "launcher\stop-local-site.ps1" goto notextracted

powershell -NoProfile -ExecutionPolicy Bypass -File "launcher\stop-local-site.ps1"
goto :eof

:notextracted
echo.
echo  -----------------------------------------------------------
echo   This has not been unzipped yet. Close this window,
echo   right-click the downloaded file, choose "Extract All...",
echo   and work in the folder that appears instead.
echo  -----------------------------------------------------------
echo.
pause
