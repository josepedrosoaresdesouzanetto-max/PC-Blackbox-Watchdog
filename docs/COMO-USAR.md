# Como usar

## Instalar

1. Abra PowerShell como Administrador.
2. Entre na pasta `PC-Blackbox-Watchdog`.
3. Rode:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1
```

## Verificar tarefas

```powershell
Get-ScheduledTask -TaskName "PC-Blackbox-*"
```

## Rodar diagnostico manual

```powershell
C:\PC-Blackbox\run-once-diagnostic.ps1
```

## Abrir relatorios

```powershell
C:\PC-Blackbox\src\PCBlackbox.Report.ps1
```

## Ver ultimo alerta urgente

Abra:

```text
C:\PC-Blackbox\ALERTA-URGENTE.txt
```

## Saber se houve relatorio parcial antes da queda

Veja:

```text
C:\PC-Blackbox\reports\ALERTA-CRITICO-*.txt
```

Se nao existir, pode ser porque nao houve sinal detectavel ou porque o desligamento foi seco instantaneo.
