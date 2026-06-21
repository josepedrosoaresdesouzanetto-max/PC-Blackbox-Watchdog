@echo off
setlocal
title Verificar PC-Blackbox-Watchdog

echo.
echo ============================================================
echo  Verificando PC-Blackbox-Watchdog
echo ============================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "Write-Host 'Tarefas agendadas:'; Get-ScheduledTask -TaskName 'PC-Blackbox-*' -ErrorAction SilentlyContinue | Select-Object TaskName,State | Format-Table -AutoSize; Write-Host ''; Write-Host 'Heartbeat:'; if (Test-Path 'C:\PC-Blackbox\logs\state\heartbeat.json') { Get-Content 'C:\PC-Blackbox\logs\state\heartbeat.json' -Raw } else { Write-Host 'heartbeat.json ainda não encontrado.' }; Write-Host ''; Write-Host 'Últimos logs de amostras:'; if (Test-Path 'C:\PC-Blackbox\logs\samples') { Get-ChildItem 'C:\PC-Blackbox\logs\samples' | Sort-Object LastWriteTime -Descending | Select-Object -First 5 Name,LastWriteTime,Length | Format-Table -AutoSize } else { Write-Host 'Pasta de samples ainda não encontrada.' }"

pause
