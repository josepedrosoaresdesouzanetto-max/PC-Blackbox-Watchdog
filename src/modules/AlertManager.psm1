Import-Module (Join-Path $PSScriptRoot "Utils.psm1") -Force -DisableNameChecking
Import-Module (Join-Path $PSScriptRoot "StateManager.psm1") -Force -DisableNameChecking
Import-Module (Join-Path $PSScriptRoot "ReportBuilder.psm1") -Force -DisableNameChecking

function Invoke-UrgentAlert {
    param(
        [string]$Root = (Get-PCBlackboxRoot),
        [string]$AlertType,
        [string]$RiskLevel,
        [string]$Title,
        [string]$Message,
        [string]$Evidence,
        [string]$Recommendation,
        [string]$Source,
        [int]$EventId,
        [datetime]$Timestamp = (Get-Date),
        [object]$LastSample,
        [object[]]$RecentEvents = @()
    )
    try {
        New-PCBlackboxDirectories -Root $Root
        $key = "{0}-{1}-{2}" -f $RiskLevel, $Source, $EventId
        $cooldown = if ($RiskLevel -match "critico|crítico") { 120 } else { 300 }
        if (-not (Test-AlertCooldown -Root $Root -AlertKey $key -CooldownSeconds $cooldown)) { return $false }

        $alert = [ordered]@{
            Timestamp = $Timestamp.ToString("o")
            AlertType = $AlertType
            RiskLevel = $RiskLevel
            Title = $Title
            Message = $Message
            Evidence = $Evidence
            Recommendation = $Recommendation
            Source = $Source
            EventId = $EventId
        }

        $alertPath = Join-Path $Root "logs\alerts\urgent-alerts.jsonl"
        Write-JsonLineSafe -Path $alertPath -Object $alert -Flush
        Write-TextSafe -Path (Join-Path $Root "ALERTA-URGENTE.txt") -Text (($alert | ConvertTo-SafeJson -Depth 6) + [Environment]::NewLine) -Flush

        $partialPath = $null
        if ($RiskLevel -match "alto|critico|crítico") {
            $partialPath = New-PartialAlertReport -Root $Root -Alert $alert -LastSample $LastSample -RecentEvents $RecentEvents
            Write-State -Root $Root -Name "last-partial-report" -State ([ordered]@{ path = $partialPath; timestamp = Get-StandardTimestamp })
        }

        Set-AlertCooldown -Root $Root -AlertKey $key
        if ($RiskLevel -match "critico|crítico") {
            Set-ModeState -Root $Root -Mode "emergencia" -Until (Get-Date).AddMinutes(10)
        }
        elseif ($RiskLevel -match "alto") {
            Set-ModeState -Root $Root -Mode "alerta" -Until (Get-Date).AddMinutes(10)
        }

        # Visual alerts are best-effort only. Evidence has already been saved.
        try {
            if ($RiskLevel -match "critico|crítico") {
                [console]::beep(1200, 500)
                Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
                [System.Windows.Forms.MessageBox]::Show($Message, $Title, "OK", "Warning") | Out-Null
            }
        }
        catch {
            Write-LogSafe -Path (Join-Path $Root "logs\alerts\alert-error.log") -Message $_.Exception.Message -Level "ERROR"
        }
        return $true
    }
    catch {
        Write-LogSafe -Path (Join-Path $Root "logs\alerts\alert-error.log") -Message $_.Exception.Message -Level "ERROR"
        return $false
    }
}

Export-ModuleMember -Function *
