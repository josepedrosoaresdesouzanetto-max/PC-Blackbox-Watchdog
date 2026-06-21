[CmdletBinding()]
param(
    [string]$Root = "C:\PC-Blackbox",
    [switch]$RunOnce
)

$ErrorActionPreference = "Continue"
$env:PCBLACKBOX_ROOT = $Root
$ModuleDir = Join-Path $Root "modules"
if (-not (Test-Path $ModuleDir)) { $ModuleDir = Join-Path (Split-Path -Parent (Split-Path -Parent $PSCommandPath)) "modules" }

Import-Module (Join-Path $ModuleDir "Utils.psm1") -Force -DisableNameChecking
Import-Module (Join-Path $ModuleDir "Collectors.psm1") -Force -DisableNameChecking
Import-Module (Join-Path $ModuleDir "HardwareSignals.psm1") -Force -DisableNameChecking
Import-Module (Join-Path $ModuleDir "PowerAnalyzer.psm1") -Force -DisableNameChecking
Import-Module (Join-Path $ModuleDir "StateManager.psm1") -Force -DisableNameChecking
Import-Module (Join-Path $ModuleDir "EventLogWatcher.psm1") -Force -DisableNameChecking
Import-Module (Join-Path $ModuleDir "AlertManager.psm1") -Force -DisableNameChecking

New-PCBlackboxDirectories -Root $Root
$config = Get-PCBlackboxConfig -Root $Root
$errorLog = Join-Path $Root "logs\agent-error.log"
$lockPath = Join-Path $Root "logs\state\agent.lock"

function Test-AgentLock {
    if (Test-Path $lockPath) {
        try {
            $old = Get-Content -Raw $lockPath | ConvertFrom-Json
            $proc = Get-Process -Id $old.process_id -ErrorAction SilentlyContinue
            if ($proc) { return $false }
        }
        catch { }
    }
    Write-TextSafe -Path $lockPath -Text ((@{ process_id = $PID; started = Get-StandardTimestamp } | ConvertTo-SafeJson) + "`r`n") -Flush
    return $true
}

if (-not (Test-AgentLock)) {
    Write-LogSafe -Path $errorLog -Level "WARN" -Message "Outra instancia do agente parece estar em execucao. Encerrando esta instancia."
    exit 0
}

function Test-GamingQuietMode {
    param([object]$Config)
    try {
        if (-not [bool]$Config.gaming_mode_suppress_temperature_popup) { return $false }
        $names = @($Config.gaming_mode_process_names)
        if (-not $names -or $names.Count -eq 0) { return $false }
        $running = @(Get-Process -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ProcessName)
        foreach ($name in $names) {
            if ($running -contains $name) { return $true }
        }
    }
    catch { }
    return $false
}

function Write-SilentTemperatureAlert {
    param(
        [string]$Root,
        [string]$Device,
        [double]$Temperature,
        [double]$Threshold,
        [object]$Sample,
        [object]$Config
    )
    try {
        if (-not [bool]$Config.gaming_mode_silent_temperature_log) { return }
        $cooldown = [int]$Config.gaming_mode_temperature_silent_log_cooldown_seconds
        if ($cooldown -le 0) { $cooldown = 1800 }
        $key = "gaming-temp-silent-$Device"
        if (-not (Test-AlertCooldown -Root $Root -AlertKey $key -CooldownSeconds $cooldown)) { return }
        $entry = [ordered]@{
            Timestamp = Get-StandardTimestamp
            AlertType = "temperatura"
            RiskLevel = "silencioso"
            Title = "PC Blackbox: temperatura alta em modo gamer"
            Message = "Temperatura alta registrada sem popup/beep porque modo gamer esta ativo."
            Device = $Device
            TemperatureCelsius = $Temperature
            ThresholdCelsius = $Threshold
            SampleTimestamp = $Sample.timestamp_local
        }
        Write-JsonLineSafe -Path (Join-Path $Root "logs\alerts\suppressed-temperature-alerts.jsonl") -Object $entry -Flush
        Set-AlertCooldown -Root $Root -AlertKey $key
    }
    catch {
        Write-LogSafe -Path (Join-Path $Root "logs\alerts\alert-error.log") -Message $_.Exception.Message -Level "ERROR"
    }
}

try {
    $normalInterval = [int]$config.sample_interval_seconds_normal
    $alertInterval = [int]$config.sample_interval_seconds_alert
    $emergencyInterval = [int]$config.sample_interval_seconds_emergency
    $emergencyUntil = Get-Date

    while ($true) {
        try {
            $mode = Get-ModeState -Root $Root
            $sample = Get-SystemSample -Mode $mode
            $power = Get-PowerSnapshot
            $temps = Get-TemperatureSignals
            $smart = Get-SmartBasicStatus
            $sample.power = $power
            $sample.temperatures = $temps
            $sample.smart = $smart

            $samplePath = Join-Path $Root ("logs\samples\samples-{0}.jsonl" -f (Get-Date -Format "yyyy-MM-dd"))
            Rotate-LogIfNeeded -Path $samplePath -MaxSizeMb ([int]$config.max_log_size_mb)
            Write-JsonLineSafe -Path $samplePath -Object $sample -Flush:([bool]$config.flush_after_critical_write)
            Write-State -Root $Root -Name "last-state" -State $sample
            Update-Heartbeat -Root $Root -Sample $sample
            Write-State -Root $Root -Name "last-sample" -State ([ordered]@{ timestamp = $sample.timestamp_local; path = $samplePath })

            $events = Get-NewWatchedEvents -Root $Root -FallbackStart (Get-Date).AddMinutes(-5)
            if ($events.Count -gt 0) {
                $eventPath = Join-Path $Root ("logs\events\events-{0}.jsonl" -f (Get-Date -Format "yyyy-MM-dd"))
                foreach ($evt in $events) { Write-JsonLineSafe -Path $eventPath -Object $evt -Flush }
                Invoke-EventAlerts -Root $Root -Events $events -LastSample $sample
            }

            $gamingQuiet = Test-GamingQuietMode -Config $config
            if ($temps.cpu_temp_celsius -and $temps.cpu_temp_celsius -ge [double]$config.cpu_temp_critical_celsius) {
                $cpuEmergency = $temps.cpu_temp_celsius -ge [double]$config.cpu_temp_emergency_celsius
                if ($gamingQuiet -and -not $cpuEmergency) {
                    Write-SilentTemperatureAlert -Root $Root -Device "CPU" -Temperature ([double]$temps.cpu_temp_celsius) -Threshold ([double]$config.cpu_temp_critical_celsius) -Sample $sample -Config $config
                }
                else {
                    Invoke-UrgentAlert -Root $Root -AlertType "temperatura" -RiskLevel "critico" -Title "PC Blackbox: temperatura CPU critica" -Message "ALERTA CRITICO: temperatura muito alta detectada. O PC pode desligar para se proteger. Feche jogos ou programas pesados agora e verifique a refrigeracao." -Evidence ("CPU temp: {0} C" -f $temps.cpu_temp_celsius) -Recommendation "Salve seu trabalho, reduza carga e verifique refrigeracao." -Source "HardwareSignals" -EventId 9501 -LastSample $sample | Out-Null
                }
            }
            if ($temps.gpu_temp_celsius -and $temps.gpu_temp_celsius -ge [double]$config.gpu_temp_critical_celsius) {
                $gpuEmergency = $temps.gpu_temp_celsius -ge [double]$config.gpu_temp_emergency_celsius
                if ($gamingQuiet -and -not $gpuEmergency) {
                    Write-SilentTemperatureAlert -Root $Root -Device "GPU" -Temperature ([double]$temps.gpu_temp_celsius) -Threshold ([double]$config.gpu_temp_critical_celsius) -Sample $sample -Config $config
                }
                else {
                    Invoke-UrgentAlert -Root $Root -AlertType "temperatura" -RiskLevel "critico" -Title "PC Blackbox: temperatura GPU critica" -Message "ALERTA CRITICO: temperatura da GPU muito alta detectada. Se nao estiver jogando ou renderizando, investigue driver, ventoinhas e fluxo de ar." -Evidence ("GPU temp: {0} C" -f $temps.gpu_temp_celsius) -Recommendation "Salve seu trabalho, reduza carga e verifique refrigeracao/driver de video." -Source "HardwareSignals" -EventId 9504 -LastSample $sample | Out-Null
                }
            }
            if ($sample.cpu_total_percent -and $sample.cpu_total_percent -ge [double]$config.cpu_alert_percent) {
                Invoke-UrgentAlert -Root $Root -AlertType "recurso" -RiskLevel "alto" -Title "PC Blackbox: CPU muito alta" -Message "CPU acima do limite configurado. Salve seu trabalho e veja os processos no relatorio." -Evidence ("CPU: {0}%" -f $sample.cpu_total_percent) -Recommendation "Feche programas pesados e observe se ha travamento." -Source "Collectors" -EventId 9502 -LastSample $sample | Out-Null
            }
            if ($sample.ram_used_percent -and $sample.ram_used_percent -ge [double]$config.ram_alert_percent) {
                Invoke-UrgentAlert -Root $Root -AlertType "recurso" -RiskLevel "alto" -Title "PC Blackbox: RAM muito alta" -Message "RAM acima do limite configurado. Salve seu trabalho e veja os processos no relatorio." -Evidence ("RAM: {0}%" -f $sample.ram_used_percent) -Recommendation "Feche programas pesados e observe se ha travamento." -Source "Collectors" -EventId 9503 -LastSample $sample | Out-Null
            }

            Remove-OldBlackboxLogs -Root $Root -Days ([int]$config.max_days_to_keep_logs)
        }
        catch {
            Write-LogSafe -Path $errorLog -Level "ERROR" -Message $_.Exception.Message
        }

        if ($RunOnce) { break }
        $currentMode = Get-ModeState -Root $Root
        if ($currentMode -eq "emergencia") {
            if ($emergencyUntil -lt (Get-Date)) { $emergencyUntil = (Get-Date).AddSeconds([int]$config.emergency_fast_duration_seconds) }
            $sleep = if ((Get-Date) -lt $emergencyUntil) { $emergencyInterval } else { $alertInterval }
        }
        elseif ($currentMode -eq "alerta") { $sleep = $alertInterval }
        else { $sleep = $normalInterval; $emergencyUntil = Get-Date }
        Start-Sleep -Seconds $sleep
    }
}
finally {
    try { Remove-Item $lockPath -Force -ErrorAction SilentlyContinue } catch { }
}
