@echo off
cd /d "%~dp0"

rem If these are missing we are almost certainly running from inside the
rem downloaded .zip, where Windows copies only the clicked file to a
rem temporary folder and leaves everything else behind.
if not exist "launcher\start-local-site.ps1" goto notextracted
if not exist "images\pnwinsects-local-images.tar" goto notextracted
if not exist "data\site.sql" goto notextracted
if not exist "bundle.env" goto notextracted

powershell -NoProfile -ExecutionPolicy Bypass -File "launcher\start-local-site.ps1"
goto :eof

:notextracted
echo.
echo  -----------------------------------------------------------
echo   This has not been unzipped yet, so most of the site is
echo   still inside the downloaded file.
echo.
echo   Close this window. Then find the file you downloaded,
echo   right-click the downloaded zip file, choose
echo   "Extract All...", and press Extract.
echo.
echo   Open the new folder that appears, and double-click
echo   "Start PNW Moths" in there instead.
echo  -----------------------------------------------------------
echo.
pause
