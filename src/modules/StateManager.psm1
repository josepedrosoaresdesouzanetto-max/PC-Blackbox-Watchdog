Import-Module (Join-Path $PSScriptRoot "Utils.psm1") -Force -DisableNameChecking

function Get-StatePath {
    param([string]$Root = (Get-PCBlackboxRoot), [string]$Name)
    Join-Path $Root ("logs\state\{0}.json" -f $Name)
}

function Read-State {
    param([string]$Root = (Get-PCBlackboxRoot), [string]$Name, $Default = @{})
    $path = Get-StatePath -Root $Root -Name $Name
    if (Test-Path $path) {
        try { return (Get-Content -Raw -Path $path -Encoding UTF8 | ConvertFrom-Json) }
        catch { return $Default }
    }
    return $Default
}

function Write-State {
    param([string]$Root = (Get-PCBlackboxRoot), [string]$Name, [object]$State)
    $path = Get-StatePath -Root $Root -Name $Name
    Write-TextSafe -Path $path -Text (($State | ConvertTo-SafeJson -Depth 10) + [Environment]::NewLine) -Flush
}

function Update-Heartbeat {
    param([string]$Root = (Get-PCBlackboxRoot), [object]$Sample)
    $hb = [ordered]@{
        timestamp = Get-StandardTimestamp
        timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
        process_id = $PID
        sample_timestamp = $Sample.timestamp_local
        mode = $Sample.mode
    }
    Write-State -Root $Root -Name "heartbeat" -State $hb
}

function Get-RecordState {
    param([string]$Root = (Get-PCBlackboxRoot))
    $state = Read-State -Root $Root -Name "record-ids" -Default ([pscustomobject]@{})
    return $state
}

function Set-RecordId {
    param([string]$Root = (Get-PCBlackboxRoot), [string]$Key, [long]$RecordId)
    $state = Get-RecordState -Root $Root
    $hash = @{}
    $state.PSObject.Properties | ForEach-Object { $hash[$_.Name] = $_.Value }
    $hash[$Key] = $RecordId
    Write-State -Root $Root -Name "record-ids" -State $hash
}

function Get-RecordId {
    param([string]$Root = (Get-PCBlackboxRoot), [string]$Key)
    $state = Get-RecordState -Root $Root
    if ($state.PSObject.Properties.Name -contains $Key) { return [long]$state.$Key }
    return 0
}

function Set-ModeState {
    param([string]$Root = (Get-PCBlackboxRoot), [string]$Mode, [datetime]$Until)
    Write-State -Root $Root -Name "mode" -State ([ordered]@{ mode = $Mode; until = $Until.ToString("o"); updated = Get-StandardTimestamp })
}

function Get-ModeState {
    param([string]$Root = (Get-PCBlackboxRoot))
    $state = Read-State -Root $Root -Name "mode" -Default ([pscustomobject]@{ mode = "normal"; until = (Get-Date).AddSeconds(-1).ToString("o") })
    try {
        if ([datetime]$state.until -lt (Get-Date)) { return "normal" }
        return [string]$state.mode
    }
    catch { return "normal" }
}

function Test-AlertCooldown {
    param(
        [string]$Root = (Get-PCBlackboxRoot),
        [string]$AlertKey,
        [int]$CooldownSeconds
    )
    $state = Read-State -Root $Root -Name "alert-cooldown" -Default ([pscustomobject]@{})
    if ($state.PSObject.Properties.Name -contains $AlertKey) {
        try {
            $last = [datetime]$state.$AlertKey
            if (((Get-Date) - $last).TotalSeconds -lt $CooldownSeconds) { return $false }
        }
        catch { }
    }
    return $true
}

function Set-AlertCooldown {
    param([string]$Root = (Get-PCBlackboxRoot), [string]$AlertKey)
    $state = Read-State -Root $Root -Name "alert-cooldown" -Default ([pscustomobject]@{})
    $hash = @{}
    $state.PSObject.Properties | ForEach-Object { $hash[$_.Name] = $_.Value }
    $hash[$AlertKey] = (Get-Date).ToString("o")
    Write-State -Root $Root -Name "alert-cooldown" -State $hash
}

Export-ModuleMember -Function *
