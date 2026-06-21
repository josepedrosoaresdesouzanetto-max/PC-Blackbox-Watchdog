[CmdletBinding()]
param(
    [string]$InstallRoot = "C:\PC-Blackbox"
)

$log = Join-Path $InstallRoot "uninstall.log"
function LogUninstall($msg) {
    New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null
    "[{0}] {1}" -f (Get-Date), $msg | Out-File $log -Append -Encoding UTF8
}

LogUninstall "Remoção iniciada. Isto remove apenas tarefas e, se confirmado, arquivos do projeto."
foreach ($name in "PC-Blackbox-Agent","PC-Blackbox-PostBoot-Analyzer","PC-Blackbox-Notifier","PC-Blackbox-StatusIcon") {
    try {
        Unregister-ScheduledTask -TaskName $name -Confirm:$false -ErrorAction SilentlyContinue
        LogUninstall "Tarefa removida: $name"
    } catch { LogUninstall "Falha ao remover tarefa ${name}: $($_.Exception.Message)" }
}

try {
    $shortcutPath = Join-Path ([Environment]::GetFolderPath("Startup")) "PC-Blackbox Olhinho.lnk"
    if (Test-Path $shortcutPath) {
        Remove-Item -LiteralPath $shortcutPath -Force
        LogUninstall "Atalho do olhinho removido: $shortcutPath"
    }
}
catch {
    LogUninstall "Falha ao remover atalho do olhinho: $($_.Exception.Message)"
}

$answer = Read-Host "Deseja apagar também logs e relatórios em $InstallRoot? Digite APAGAR para confirmar"
if ($answer -eq "APAGAR") {
    Remove-Item -Path $InstallRoot -Recurse -Force
    Write-Host "Arquivos removidos."
} else {
    LogUninstall "Usuário optou por manter logs e arquivos."
    Write-Host "Tarefas removidas. Logs mantidos em $InstallRoot."
}
