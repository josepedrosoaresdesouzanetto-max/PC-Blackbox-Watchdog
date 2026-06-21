[CmdletBinding()]
param(
    [string]$Root = "C:\PC-Blackbox",
    [int]$ManualDays = 0
)

$ErrorActionPreference = "Continue"
$env:PCBLACKBOX_ROOT = $Root
$ModuleDir = Join-Path $Root "modules"
if (-not (Test-Path $ModuleDir)) { $ModuleDir = Join-Path (Split-Path -Parent (Split-Path -Parent $PSCommandPath)) "modules" }

Import-Module (Join-Path $ModuleDir "Utils.psm1") -Force -DisableNameChecking
Import-Module (Join-Path $ModuleDir "StateManager.psm1") -Force -DisableNameChecking
Import-Module (Join-Path $ModuleDir "EventLogAnalyzer.psm1") -Force -DisableNameChecking
Import-Module (Join-Path $ModuleDir "CrashDumpAnalyzer.psm1") -Force -DisableNameChecking
Import-Module (Join-Path $ModuleDir "ReliabilityAnalyzer.psm1") -Force -DisableNameChecking
Import-Module (Join-Path $ModuleDir "ReportBuilder.psm1") -Force -DisableNameChecking

New-PCBlackboxDirectories -Root $Root
$log = Join-Path $Root "logs\analyzer.log"

function Get-RecentSamples {
    param([string]$Root, [int]$Minutes = 60)
    $files = Get-ChildItem (Join-Path $Root "logs\samples") -Filter *.jsonl -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 3
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($file in $files) {
        try {
            Get-Content $file.FullName -Tail 500 -ErrorAction SilentlyContinue | ForEach-Object {
                if ($_ -and $_.Trim()) {
                    try { $rows.Add(($_ | ConvertFrom-Json)) } catch { }
                }
            }
        }
        catch { }
    }
    $rows | Sort-Object timestamp_local | Select-Object -Last 120
}

try {
    try { $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop } catch { $os = $null }
    $boot = $null
    if ($os -and $os.LastBootUpTime) {
        try {
            if ($os.LastBootUpTime -is [datetime]) { $boot = $os.LastBootUpTime }
            else { $boot = [Management.ManagementDateTimeConverter]::ToDateTime($os.LastBootUpTime) }
        } catch { $boot = $null }
    }
    if (-not $boot) {
        $tick = [math]::Abs([Environment]::TickCount)
        $boot = (Get-Date).AddMilliseconds(-1 * $tick)
    }
    $heartbeat = Read-State -Root $Root -Name "heartbeat" -Default ([pscustomobject]@{})
    $lastSampleState = Read-State -Root $Root -Name "last-sample" -Default ([pscustomobject]@{})
    $partialState = Read-State -Root $Root -Name "last-partial-report" -Default ([pscustomobject]@{})

    $start = if ($ManualDays -gt 0) { (Get-Date).AddDays(-1 * $ManualDays) } else { $boot.AddMinutes(-30) }
    $end = if ($ManualDays -gt 0) { Get-Date } else { $boot.AddMinutes(15) }
    $events = @(Get-EventsInWindow -StartTime $start -EndTime $end)
    $samples = @(Get-RecentSamples -Root $Root)
    $dumps = (Get-CrashDumpSummary).dump_files
    $reliability = @(Get-ReliabilitySummary -StartTime $start -EndTime (Get-Date))

    $lastSampleTime = $null
    if ($lastSampleState.timestamp) { try { $lastSampleTime = [datetime]$lastSampleState.timestamp } catch { } }
    $gapSeconds = if ($lastSampleTime) { [math]::Round(($boot - $lastSampleTime).TotalSeconds, 1) } else { $null }

    $kernelPower = @($events | Where-Object { $_.ProviderName -eq "Microsoft-Windows-Kernel-Power" -and $_.Id -eq 41 })
    $unexpected = ($kernelPower.Count -gt 0 -or ($gapSeconds -and $gapSeconds -gt 120))

    $state = [ordered]@{
        last_boot_time = $boot.ToString("o")
        suspected_shutdown_time = if ($lastSampleTime) { $lastSampleTime.ToString("o") } else { $boot.ToString("o") }
        unexpected_shutdown_detected = $unexpected
        heartbeat_missing = ($gapSeconds -and $gapSeconds -gt 120)
        last_sample_timestamp_before_crash = if ($lastSampleTime) { $lastSampleTime.ToString("o") } else { $null }
        seconds_between_last_sample_and_boot_gap = $gapSeconds
        partial_alert_report_path = $partialState.path
    }

    $diagnosis = Invoke-DiagnosisScoring -Events $events -Samples $samples -State $state
    $paths = New-PostBootReports -Root $Root -Diagnosis $diagnosis -Events $events -Samples $samples -Dumps $dumps -ReliabilityRecords $reliability -State $state
    Write-LogSafe -Path $log -Message ("Relatorios gerados: {0}" -f ($paths | ConvertTo-SafeJson))
    $paths | ConvertTo-SafeJson -Depth 5
}
catch {
    Write-LogSafe -Path $log -Level "ERROR" -Message $_.Exception.Message
    throw
}
