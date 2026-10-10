@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "launcher\start-local-site.ps1"
