function Convert-KelvinTenthsToCelsius {
    param([double]$Value)
    [math]::Round(($Value / 10) - 273.15, 1)
}

function Get-TemperatureSignals {
    $messages = @()
    $cpuTemp = $null
    try {
        $zones = Get-CimInstance -Namespace root\wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop
        if ($zones) {
            $cpuTemp = ($zones | ForEach-Object { Convert-KelvinTenthsToCelsius $_.CurrentTemperature } | Measure-Object -Maximum).Maximum
        }
    }
    catch {
        $messages += "Sensor de temperatura não disponível pelo Windows. Use HWiNFO, LibreHardwareMonitor ou ferramenta da placa-mãe para confirmar temperatura."
    }

    [ordered]@{
        cpu_temp_celsius = $cpuTemp
        gpu_temp_celsius = $null
        disk_temp_celsius = $null
        sensor_messages = $messages
        optional_integrations = "HWiNFO/LibreHardwareMonitor não são obrigatórios; se instalados, confirme temperaturas por eles."
    }
}

function Get-SmartBasicStatus {
    try {
        return @(Get-PhysicalDisk -ErrorAction Stop | Select-Object FriendlyName, HealthStatus, OperationalStatus, Size)
    }
    catch { return @() }
}

Export-ModuleMember -Function *
