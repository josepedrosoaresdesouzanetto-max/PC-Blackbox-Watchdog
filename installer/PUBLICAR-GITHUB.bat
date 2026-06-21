@echo off
setlocal
title Publicar no GitHub - PC-Blackbox-Watchdog

cd /d "%~dp0.."

echo.
echo ============================================================
echo  Publicar PC-Blackbox-Watchdog no GitHub
echo ============================================================
echo.
echo Requisitos:
echo  - GitHub CLI instalado
echo  - Login feito com: gh auth login
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0PUBLICAR-GITHUB.ps1"
pause
