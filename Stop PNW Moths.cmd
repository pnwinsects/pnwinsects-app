@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "launcher\stop-local-site.ps1"
