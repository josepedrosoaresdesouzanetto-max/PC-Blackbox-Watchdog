@echo off
setlocal
title Desinstalador - PC-Blackbox-Watchdog

echo.
echo ============================================================
echo  PC-Blackbox-Watchdog - Desinstalador
echo ============================================================
echo.
echo Este desinstalador remove as tarefas agendadas.
echo Tambem remove o atalho do olhinho criado em Inicializar.
echo Ele so apaga logs se voce confirmar explicitamente.
echo.

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando permissao de Administrador...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

if exist "C:\PC-Blackbox\uninstall.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "C:\PC-Blackbox\uninstall.ps1"
) else (
    echo Nao encontrei C:\PC-Blackbox\uninstall.ps1
)

pause
