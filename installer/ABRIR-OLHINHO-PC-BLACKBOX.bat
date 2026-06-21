@echo off
setlocal
title Olhinho - PC-Blackbox-Watchdog

if exist "C:\PC-Blackbox\app\PCBlackbox.StatusIcon.ps1" (
    start "" powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\PC-Blackbox\app\PCBlackbox.StatusIcon.ps1" -Root "C:\PC-Blackbox"
) else if exist "C:\PC-Blackbox\src\PCBlackbox.StatusIcon.ps1" (
    start "" powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\PC-Blackbox\src\PCBlackbox.StatusIcon.ps1" -Root "C:\PC-Blackbox"
) else (
    echo Não encontrei o script do olhinho em C:\PC-Blackbox\app ou C:\PC-Blackbox\src
    echo Reinstale ou atualize o PC-Blackbox.
    pause
)
