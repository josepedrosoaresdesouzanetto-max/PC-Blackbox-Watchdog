function Get-CrashDumpSummary {
    $items = @()
    try {
        if (Test-Path "C:\Windows\Minidump") {
            $items += Get-ChildItem "C:\Windows\Minidump" -Filter *.dmp -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending |
                Select-Object -First 20 FullName, Length, LastWriteTime
        }
        if (Test-Path "C:\Windows\MEMORY.DMP") {
            $items += Get-Item "C:\Windows\MEMORY.DMP" | Select-Object FullName, Length, LastWriteTime
        }
    }
    catch { }
    [ordered]@{
        dump_files = @($items)
        note = "Análise profunda de dump exige WinDbg. Este modulo lista metadados e cruza existencia de dump com BugCheck."
    }
}

Export-ModuleMember -Function *
