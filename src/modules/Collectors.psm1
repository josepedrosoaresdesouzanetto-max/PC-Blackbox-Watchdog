Import-Module (Join-Path $PSScriptRoot "Utils.psm1") -Force -DisableNameChecking

function Get-OSInfo {
    try { $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop } catch { $os = $null }
    $boot = $null
    if ($os -and $os.LastBootUpTime) {
        try {
            if ($os.LastBootUpTime -is [datetime]) { $boot = $os.LastBootUpTime }
            else { $boot = [Management.ManagementDateTimeConverter]::ToDateTime($os.LastBootUpTime) }
        } catch { $boot = $null }
    }
    [ordered]@{
        windows_caption = if ($os) { $os.Caption } else { $null }
        windows_version = if ($os) { $os.Version } else { $null }
        windows_build = if ($os) { $os.BuildNumber } else { $null }
        last_boot_time = if ($boot) { $boot.ToString("o") } else { $null }
        uptime_seconds = if ($boot) { [int]((Get-Date) - $boot).TotalSeconds } else { $null }
    }
}

function Get-CpuPercent {
    try { return [math]::Round((Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction Stop).CounterSamples.CookedValue, 2) }
    catch {
        try {
            $cpu = Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'" -ErrorAction Stop
            return [double]$cpu.PercentProcessorTime
        } catch { return $null }
    }
}

function Get-CpuFrequencyMhz {
    try { return [int](Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1 -ExpandProperty CurrentClockSpeed) }
    catch { return $null }
}

function Get-MemoryInfo {
    try { $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop } catch { $os = $null }
    if (-not $os) { return [ordered]@{} }
    $total = [double]$os.TotalVisibleMemorySize
    $free = [double]$os.FreePhysicalMemory
    $usedPct = if ($total -gt 0) { [math]::Round((($total - $free) / $total) * 100, 2) } else { $null }
    [ordered]@{
        ram_used_percent = $usedPct
        ram_free_mb = [math]::Round($free / 1024, 1)
        ram_total_mb = [math]::Round($total / 1024, 1)
        commit_charge_mb = $null
    }
}

function Get-DiskInfo {
    $drive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction SilentlyContinue
    $queue = $null; $reads = $null; $writes = $null
    try { $queue = [math]::Round((Get-Counter '\PhysicalDisk(_Total)\Current Disk Queue Length' -ErrorAction Stop).CounterSamples.CookedValue, 2) } catch { }
    try { $reads = [math]::Round((Get-Counter '\PhysicalDisk(_Total)\Disk Reads/sec' -ErrorAction Stop).CounterSamples.CookedValue, 2) } catch { }
    try { $writes = [math]::Round((Get-Counter '\PhysicalDisk(_Total)\Disk Writes/sec' -ErrorAction Stop).CounterSamples.CookedValue, 2) } catch { }
    [ordered]@{
        disk_c_size_gb = if ($drive.Size) { [math]::Round($drive.Size / 1GB, 2) } else { $null }
        disk_c_free_gb = if ($drive.FreeSpace) { [math]::Round($drive.FreeSpace / 1GB, 2) } else { $null }
        disk_c_free_percent = if ($drive.Size) { [math]::Round(($drive.FreeSpace / $drive.Size) * 100, 2) } else { $null }
        disk_queue = $queue
        disk_reads_per_sec = $reads
        disk_writes_per_sec = $writes
    }
}

function Get-TopProcesses {
    $procs = Get-Process -ErrorAction SilentlyContinue
    [ordered]@{
        top_cpu = @($procs | Sort-Object CPU -Descending | Select-Object -First 5 Name, Id, CPU, Path)
        top_ram = @($procs | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 Name, Id, @{n="WorkingSetMB";e={[math]::Round($_.WorkingSet64/1MB,1)}}, Path)
        top_io = @($procs | Sort-Object @{Expression={$_.IOReadBytes + $_.IOWriteBytes}} -Descending | Select-Object -First 5 Name, Id, @{n="IOMB";e={[math]::Round(($_.IOReadBytes+$_.IOWriteBytes)/1MB,1)}}, Path)
    }
}

function Get-SystemSample {
    param([string]$Mode = "normal")
    $osInfo = Get-OSInfo
    $mem = Get-MemoryInfo
    $disk = Get-DiskInfo
    $top = Get-TopProcesses
    [ordered]@{
        timestamp_local = Get-StandardTimestamp
        timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
        computer_name = $env:COMPUTERNAME
        user_name = [Environment]::UserName
        windows_version = $osInfo.windows_version
        windows_build = $osInfo.windows_build
        uptime_seconds = $osInfo.uptime_seconds
        last_boot_time = $osInfo.last_boot_time
        cpu_total_percent = Get-CpuPercent
        cpu_frequency_mhz = Get-CpuFrequencyMhz
        ram_used_percent = $mem.ram_used_percent
        ram_free_mb = $mem.ram_free_mb
        commit_charge_mb = $mem.commit_charge_mb
        disk_c_free_percent = $disk.disk_c_free_percent
        disk_c_free_gb = $disk.disk_c_free_gb
        disk_queue = $disk.disk_queue
        disk_reads_per_sec = $disk.disk_reads_per_sec
        disk_writes_per_sec = $disk.disk_writes_per_sec
        top_cpu_processes = $top.top_cpu
        top_ram_processes = $top.top_ram
        top_io_processes = $top.top_io
        mode = $Mode
    }
}

Export-ModuleMember -Function *
