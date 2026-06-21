function Get-ReliabilitySummary {
    param([datetime]$StartTime = (Get-Date).AddDays(-7), [datetime]$EndTime = (Get-Date))
    try {
        @(Get-CimInstance Win32_ReliabilityRecords -ErrorAction Stop |
            Where-Object { $_.TimeGenerated -ge $StartTime -and $_.TimeGenerated -le $EndTime -and ($_.Message -match "LiveKernelEvent|parou de funcionar|falha|crash|erro|Windows Error Reporting") } |
            Select-Object TimeGenerated, SourceName, ProductName, EventIdentifier, Message)
    }
    catch { @() }
}

Export-ModuleMember -Function *
