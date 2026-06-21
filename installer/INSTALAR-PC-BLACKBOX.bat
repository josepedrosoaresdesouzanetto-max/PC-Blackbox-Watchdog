@echo off
setlocal
title Instalador - PC-Blackbox-Watchdog

cd /d "%~dp0"
set "PROJECT_ROOT=%~dp0.."
set "INSTALL_SCRIPT=%PROJECT_ROOT%\install.ps1"

echo.
echo ============================================================
echo  PC-Blackbox-Watchdog - Instalador automático
echo ============================================================
echo.
echo Este instalador vai:
echo  - Pedir permissão de Administrador via UAC
echo  - Instalar em C:\PC-Blackbox
echo  - Criar tarefas agendadas de monitoramento
echo  - Criar interface visual com olhinho animado
echo  - Criar atalhos com ícone em C:\PC-Blackbox\shortcuts
echo  - Rodar um diagnóstico inicial
echo.
echo Ele NÃO altera BIOS, TPM, Secure Boot, BitLocker ou drivers.
echo Ele preserva logs e relatórios existentes em upgrades/reparos.
echo.

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando permissão de Administrador...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo Permissão de Administrador confirmada.
echo Iniciando instalação...
echo.

if not exist "%INSTALL_SCRIPT%" (
    echo ERRO: Não encontrei o instalador principal:
    echo %INSTALL_SCRIPT%
    echo.
    echo Abra a pasta raiz do projeto e confirme se existe install.ps1.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%INSTALL_SCRIPT%"
if %errorlevel% neq 0 (
    echo.
    echo ============================================================
    echo  INSTALACAO FALHOU
    echo ============================================================
    echo.
    echo O PowerShell retornou erro %errorlevel%.
    echo Nada de BIOS, TPM, Secure Boot ou drivers foi alterado.
    echo.
    pause
    exit /b %errorlevel%
)

echo.
echo ============================================================
echo  Instalador finalizado
echo ============================================================
echo.
echo PC-Blackbox v1.0.1 instalado/reparado em:
echo C:\PC-Blackbox
echo.
echo Relatórios:
echo C:\PC-Blackbox\reports
echo.
echo Logs contínuos:
echo C:\PC-Blackbox\logs\samples
echo.
pause
