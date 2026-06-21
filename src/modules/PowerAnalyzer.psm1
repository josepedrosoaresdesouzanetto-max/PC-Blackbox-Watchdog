function Get-ActivePowerPlan {
    try {
        $text = powercfg /getactivescheme 2>$null
        return ($text -join " ")
    }
    catch { return $null }
}

function Get-ACPowerState {
    try {
        $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
        if (-not $battery) { return "Desktop/sem bateria detectada" }
        return @($battery | Select-Object Name, BatteryStatus, EstimatedChargeRemaining)
    }
    catch { return "Estado AC/bateria nao disponivel" }
}

function Get-PowerSnapshot {
    [ordered]@{
        active_power_plan = Get-ActivePowerPlan
        ac_battery_state = Get-ACPowerState
    }
}

Export-ModuleMember -Function *
