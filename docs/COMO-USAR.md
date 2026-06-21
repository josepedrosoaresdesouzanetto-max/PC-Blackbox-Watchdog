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

## Rodar diagnóstico manual

```powershell
C:\PC-Blackbox\run-once-diagnostic.ps1
```

## Abrir relatórios

```powershell
C:\PC-Blackbox\src\PCBlackbox.Report.ps1
```

## Ver último alerta urgente

Abra:

```text
C:\PC-Blackbox\ALERTA-URGENTE.txt
```

## Saber se houve relatório parcial antes da queda

Veja:

```text
C:\PC-Blackbox\reports\ALERTA-CRITICO-*.txt
```

Se não existir, pode ser porque não houve sinal detectável ou porque o desligamento foi seco instantâneo.
