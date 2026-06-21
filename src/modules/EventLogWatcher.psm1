Import-Module (Join-Path $PSScriptRoot "Utils.psm1") -Force -DisableNameChecking
Import-Module (Join-Path $PSScriptRoot "StateManager.psm1") -Force -DisableNameChecking
Import-Module (Join-Path $PSScriptRoot "EventLogAnalyzer.psm1") -Force -DisableNameChecking
Import-Module (Join-Path $PSScriptRoot "AlertManager.psm1") -Force -DisableNameChecking

function New-BlackboxEventLogWatcher {
    <#
    Best-effort wrapper para System.Diagnostics.Eventing.Reader.EventLogWatcher.
    O Agent usa polling otimizado como fallback porque ele e mais previsivel em
    PowerShell 5.1 e evita perder eventos se callbacks falharem.
    #>
    param(
        [string]$LogName = "System",
        [string]$XPath = "*[System[(Level=1 or Level=2 or Level=3)]]"
    )
    try {
        Add-Type -AssemblyName System.Core -ErrorAction SilentlyContinue
        $query = New-Object System.Diagnostics.Eventing.Reader.EventLogQuery($LogName, [System.Diagnostics.Eventing.Reader.PathType]::LogName, $XPath)
        $watcher = New-Object System.Diagnostics.Eventing.Reader.EventLogWatcher($query)
        return $watcher
    }
    catch {
        return $null
    }
}

function Get-NewWatchedEvents {
    param([string]$Root = (Get-PCBlackboxRoot), [datetime]$FallbackStart = (Get-Date).AddMinutes(-5))
    $events = New-Object System.Collections.Generic.List[object]
    foreach ($filter in Get-BlackboxEventFilters) {
        $key = "{0}-{1}-{2}" -f $filter.LogName, $filter.ProviderName, $filter.Id
        $lastId = Get-RecordId -Root $Root -Key $key
        try {
            $hash = @{ LogName=$filter.LogName; Id=$filter.Id; StartTime=$FallbackStart }
            if ($filter.ProviderName) { $hash.ProviderName = $filter.ProviderName }
            $new = Get-WinEvent -FilterHashtable $hash -ErrorAction SilentlyContinue |
                Where-Object { $_.RecordId -gt $lastId } |
                Sort-Object RecordId
            foreach ($e in $new) {
                $obj = [pscustomobject]@{
                    TimeCreated = $e.TimeCreated
                    LogName = $e.LogName
                    ProviderName = $e.ProviderName
                    Id = $e.Id
                    LevelDisplayName = $e.LevelDisplayName
                    RecordId = $e.RecordId
                    Message = $e.Message
                }
                $events.Add($obj)
                Set-RecordId -Root $Root -Key $key -RecordId ([long]$e.RecordId)
            }
        }
        catch { }
    }
    $events
}

function Invoke-EventAlerts {
    param([string]$Root = (Get-PCBlackboxRoot), [object[]]$Events, [object]$LastSample)
    foreach ($e in $Events) {
        $risk = Get-EventRisk -Event $e
        if ($risk -in @("critico","alto","atencao")) {
            Invoke-UrgentAlert -Root $Root `
                -AlertType "evento" `
                -RiskLevel $risk `
                -Title ("PC Blackbox: {0} ID {1}" -f $e.ProviderName, $e.Id) `
                -Message (Get-AlertMessageForEvent -Event $e) `
                -Evidence $e.Message `
                -Recommendation "Salve seu trabalho e consulte o relatorio em C:\PC-Blackbox\reports." `
                -Source $e.ProviderName `
                -EventId $e.Id `
                -Timestamp $e.TimeCreated `
                -LastSample $LastSample `
                -RecentEvents $Events | Out-Null
        }
    }
}

Export-ModuleMember -Function *
