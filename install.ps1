[CmdletBinding()]
param(
    [string]$InstallRoot = "C:\PC-Blackbox",
    [switch]$SkipScheduledTasks,
    [switch]$SkipInitialDiagnostic,
    [switch]$SkipStatusIcon
)

$ErrorActionPreference = "Stop"
$sourceRoot = $PSScriptRoot
$installLog = Join-Path $InstallRoot "install.log"
$version = "1.0.2"

function Resolve-SourceDir {
    param(
        [string]$Preferred,
        [string]$Fallback
    )
    $preferredPath = Join-Path $sourceRoot $Preferred
    if (Test-Path $preferredPath) { return $preferredPath }
    return (Join-Path $sourceRoot $Fallback)
}

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
function LogInstall($msg) {
    New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null
    "[{0}] {1}" -f (Get-Date), $msg | Out-File $installLog -Append -Encoding UTF8
}

if (-not (Test-IsAdmin) -and -not $SkipScheduledTasks) {
    throw "Execute install.ps1 como Administrador."
}

LogInstall "Instalacao/upgrade v$version iniciada. Origem: $sourceRoot"
$dirs = @(
    "app",
    "assets",
    "config",
    "docs",
    "modules",
    "shortcuts",
    "logs",
    "logs\samples",
    "logs\events",
    "logs\alerts",
    "logs\state",
    "reports",
    "data",
    "data\state",
    "data\samples",
    "data\events",
    "data\alerts",
    "src"
)
New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null
foreach ($d in $dirs) { New-Item -ItemType Directory -Force -Path (Join-Path $InstallRoot $d) | Out-Null }

$sourceConfig = Resolve-SourceDir -Preferred "src\config" -Fallback "config"
$sourceApp = Resolve-SourceDir -Preferred "src\app" -Fallback "src"
$sourceModules = Resolve-SourceDir -Preferred "src\modules" -Fallback "modules"
$sourceInstaller = Resolve-SourceDir -Preferred "installer" -Fallback "."

Copy-Item -Path (Join-Path $sourceConfig "*") -Destination (Join-Path $InstallRoot "config") -Recurse -Force
Copy-Item -Path (Join-Path $sourceApp "*") -Destination (Join-Path $InstallRoot "app") -Recurse -Force
Copy-Item -Path (Join-Path $sourceApp "*") -Destination (Join-Path $InstallRoot "src") -Recurse -Force
Copy-Item -Path (Join-Path $sourceModules "*") -Destination (Join-Path $InstallRoot "modules") -Recurse -Force
Copy-Item -Path (Join-Path $sourceRoot "docs\*") -Destination (Join-Path $InstallRoot "docs") -Recurse -Force
if (Test-Path (Join-Path $sourceRoot "assets")) {
    Copy-Item -Path (Join-Path $sourceRoot "assets\*") -Destination (Join-Path $InstallRoot "assets") -Recurse -Force
}
Copy-Item -Path (Join-Path $sourceRoot "README.md") -Destination $InstallRoot -Force
Copy-Item -Path (Join-Path $sourceInstaller "ABRIR-OLHINHO-PC-BLACKBOX.bat") -Destination $InstallRoot -Force
Copy-Item -Path (Join-Path $sourceInstaller "INSTALAR-PC-BLACKBOX.bat") -Destination $InstallRoot -Force
Copy-Item -Path (Join-Path $sourceInstaller "DESINSTALAR-PC-BLACKBOX.bat") -Destination $InstallRoot -Force
Copy-Item -Path (Join-Path $sourceInstaller "VERIFICAR-SE-ESTA-RODANDO.bat") -Destination $InstallRoot -Force
Copy-Item -Path (Join-Path $sourceInstaller "FECHAR-OLHINHO-PC-BLACKBOX.bat") -Destination $InstallRoot -Force
Copy-Item -Path (Join-Path $sourceInstaller "run-once-diagnostic.ps1") -Destination $InstallRoot -Force
Copy-Item -Path (Join-Path $sourceInstaller "uninstall.ps1") -Destination $InstallRoot -Force
if (Test-Path (Join-Path $sourceRoot "VERSION")) {
    Copy-Item -Path (Join-Path $sourceRoot "VERSION") -Destination $InstallRoot -Force
}
LogInstall "Arquivos copiados."

$ps = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
if (-not $SkipScheduledTasks) {
    $agentAction = New-ScheduledTaskAction -Execute $ps -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$InstallRoot\app\PCBlackbox.Agent.ps1`" -Root `"$InstallRoot`""
    $analyzerAction = New-ScheduledTaskAction -Execute $ps -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$InstallRoot\app\PCBlackbox.Analyzer.ps1`" -Root `"$InstallRoot`""
    $notifierAction = New-ScheduledTaskAction -Execute $ps -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$InstallRoot\app\PCBlackbox.Notifier.ps1`" -Root `"$InstallRoot`""

    $bootTrigger = New-ScheduledTaskTrigger -AtStartup
    $logonTrigger = New-ScheduledTaskTrigger -AtLogOn
    $analyzerTrigger = New-ScheduledTaskTrigger -AtLogOn
    $analyzerTrigger.Delay = "PT3M"

    $settings = New-ScheduledTaskSettingsSet -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) -MultipleInstances IgnoreNew -Priority 7 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

    try { Unregister-ScheduledTask -TaskName "PC-Blackbox-Agent" -Confirm:$false -ErrorAction SilentlyContinue } catch {}
    try { Unregister-ScheduledTask -TaskName "PC-Blackbox-PostBoot-Analyzer" -Confirm:$false -ErrorAction SilentlyContinue } catch {}
    try { Unregister-ScheduledTask -TaskName "PC-Blackbox-Notifier" -Confirm:$false -ErrorAction SilentlyContinue } catch {}
    try { Unregister-ScheduledTask -TaskName "PC-Blackbox-StatusIcon" -Confirm:$false -ErrorAction SilentlyContinue } catch {}

    Register-ScheduledTask -TaskName "PC-Blackbox-Agent" -Action $agentAction -Trigger @($bootTrigger,$logonTrigger) -Settings $settings -RunLevel Highest -Description "PC Blackbox continuous watchdog agent" | Out-Null
    Register-ScheduledTask -TaskName "PC-Blackbox-PostBoot-Analyzer" -Action $analyzerAction -Trigger $analyzerTrigger -Settings $settings -RunLevel Highest -Description "PC Blackbox post-boot analyzer" | Out-Null
    Register-ScheduledTask -TaskName "PC-Blackbox-Notifier" -Action $notifierAction -Trigger $logonTrigger -Settings $settings -Description "PC Blackbox user-context notifier" | Out-Null
    LogInstall "Tarefas agendadas criadas."

    try {
        Start-ScheduledTask -TaskName "PC-Blackbox-Agent" -ErrorAction Stop
        Start-ScheduledTask -TaskName "PC-Blackbox-Notifier" -ErrorAction SilentlyContinue
        LogInstall "Agente e notificador iniciados apos instalacao/upgrade."
    }
    catch {
        LogInstall "Aviso: nao consegui iniciar o agente automaticamente: $($_.Exception.Message)"
    }
}
else {
    LogInstall "Criacao de tarefas agendadas pulada por parametro de teste."
}

try {
    if ($SkipStatusIcon) { throw "Olhinho pulado por parametro de teste." }
    $startup = [Environment]::GetFolderPath("Startup")
    $shortcutPath = Join-Path $startup "PC-Blackbox Olhinho.lnk"
    $shortcutArgs = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$InstallRoot\app\PCBlackbox.StatusIcon.ps1`" -Root `"$InstallRoot`""
    $wsh = New-Object -ComObject WScript.Shell
    $shortcut = $wsh.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $ps
    $shortcut.Arguments = $shortcutArgs
    $shortcut.WorkingDirectory = $InstallRoot
    $shortcut.Description = "Olhinho visual do PC-Blackbox"
    $iconPath = Join-Path $InstallRoot "assets\pc-blackbox-eye.ico"
    if (Test-Path $iconPath) { $shortcut.IconLocation = $iconPath }
    $shortcut.Save()
    Start-Process -FilePath $ps -ArgumentList $shortcutArgs -WindowStyle Hidden
    LogInstall "Olhinho visual criado em Inicializar: $shortcutPath"
}
catch {
    LogInstall "Aviso: nao consegui criar/iniciar o olhinho visual: $($_.Exception.Message)"
}

try {
    $shortcutsDir = Join-Path $InstallRoot "shortcuts"
    $wsh = New-Object -ComObject WScript.Shell
    $installerShortcut = $wsh.CreateShortcut((Join-Path $shortcutsDir "Instalar ou Reparar PC-Blackbox.lnk"))
    $installerShortcut.TargetPath = Join-Path $InstallRoot "INSTALAR-PC-BLACKBOX.bat"
    $installerShortcut.WorkingDirectory = $InstallRoot
    $installerShortcut.Description = "Instalar ou reparar o PC-Blackbox-Watchdog"
    $installerIcon = Join-Path $InstallRoot "assets\install-eye.ico"
    if (Test-Path $installerIcon) { $installerShortcut.IconLocation = $installerIcon }
    $installerShortcut.Save()

    $uninstallerShortcut = $wsh.CreateShortcut((Join-Path $shortcutsDir "Desinstalar PC-Blackbox.lnk"))
    $uninstallerShortcut.TargetPath = Join-Path $InstallRoot "DESINSTALAR-PC-BLACKBOX.bat"
    $uninstallerShortcut.WorkingDirectory = $InstallRoot
    $uninstallerShortcut.Description = "Desinstalar o PC-Blackbox-Watchdog"
    $uninstallerIcon = Join-Path $InstallRoot "assets\uninstall-eye.ico"
    if (Test-Path $uninstallerIcon) { $uninstallerShortcut.IconLocation = $uninstallerIcon }
    $uninstallerShortcut.Save()
    LogInstall "Atalhos profissionais criados em $shortcutsDir."
}
catch {
    LogInstall "Aviso: nao consegui criar atalhos com icone: $($_.Exception.Message)"
}

if (-not $SkipInitialDiagnostic) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $InstallRoot "run-once-diagnostic.ps1") -Root $InstallRoot | Out-File $installLog -Append -Encoding UTF8
}
else {
    LogInstall "Diagnostico inicial pulado por parametro de teste."
}
LogInstall "Instalacao/upgrade v$version concluida. Relatorios em $InstallRoot\reports."
Write-Host "Instalacao/upgrade v$version concluida."
Write-Host "Relatorios: $InstallRoot\reports"
Write-Host "Logs continuos: $InstallRoot\logs\samples"
Write-Host "Alerta urgente: $InstallRoot\ALERTA-URGENTE.txt"
