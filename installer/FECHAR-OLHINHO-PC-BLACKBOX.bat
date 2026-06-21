@echo off
setlocal
title Fechar Olhinho - PC-Blackbox-Watchdog

echo.
echo Fechando somente o olhinho visual do PC-Blackbox...
echo O agente de monitoramento NÃO será parado.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$flag='C:\PC-Blackbox\logs\state\status-icon-exit.flag'; New-Item -ItemType Directory -Force -Path (Split-Path -Parent $flag) | Out-Null; Set-Content -LiteralPath $flag -Value (Get-Date).ToString('o') -Encoding ASCII; Get-CimInstance Win32_Process -Filter \"Name = 'powershell.exe'\" | Where-Object { $_.CommandLine -like '*PCBlackbox.StatusIcon.ps1*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }"

echo.
echo Olhinho fechado. Se o ícone ainda aparecer na bandeja, passe o mouse nele ou abra/feche a setinha de ícones ocultos.
pause
