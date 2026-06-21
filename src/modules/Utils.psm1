Set-StrictMode -Version 2.0

function Get-PCBlackboxRoot {
    if ($env:PCBLACKBOX_ROOT) { return $env:PCBLACKBOX_ROOT }
    return "C:\PC-Blackbox"
}

function Get-PCBlackboxConfig {
    param([string]$Root = (Get-PCBlackboxRoot))
    $path = Join-Path $Root "config\config.json"
    if (-not (Test-Path $path)) {
        $fallback = Join-Path (Split-Path -Parent $PSScriptRoot) "config\config.json"
        $path = $fallback
    }
    Get-Content -Raw -Path $path -Encoding UTF8 | ConvertFrom-Json
}

function New-PCBlackboxDirectories {
    param([string]$Root = (Get-PCBlackboxRoot))
    $dirs = @(
        $Root,
        (Join-Path $Root "logs"),
        (Join-Path $Root "logs\samples"),
        (Join-Path $Root "logs\events"),
        (Join-Path $Root "logs\alerts"),
        (Join-Path $Root "logs\state"),
        (Join-Path $Root "reports"),
        (Join-Path $Root "config"),
        (Join-Path $Root "app"),
        (Join-Path $Root "src"),
        (Join-Path $Root "modules"),
        (Join-Path $Root "docs"),
        (Join-Path $Root "assets"),
        (Join-Path $Root "shortcuts"),
        (Join-Path $Root "data"),
        (Join-Path $Root "data\state"),
        (Join-Path $Root "data\samples"),
        (Join-Path $Root "data\events"),
        (Join-Path $Root "data\alerts")
    )
    foreach ($dir in $dirs) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
}

function Get-StandardTimestamp {
    (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffzzz")
}

function ConvertTo-SafeJson {
    param([Parameter(ValueFromPipeline=$true)]$InputObject, [int]$Depth = 8)
    process {
        try {
            $InputObject | ConvertTo-Json -Depth $Depth -Compress
        }
        catch {
            @{ error = "Falha ao converter JSON"; message = $_.Exception.Message; timestamp = Get-StandardTimestamp } |
                ConvertTo-Json -Compress
        }
    }
}

function Write-TextSafe {
    param(
        [string]$Path,
        [string]$Text,
        [switch]$Append,
        [switch]$Flush
    )
    $dir = Split-Path -Parent $Path
    if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    $writer = New-Object System.IO.StreamWriter($Path, [bool]$Append, $encoding)
    try {
        $writer.Write($Text)
        if ($Flush) { $writer.Flush(); $writer.BaseStream.Flush() }
    }
    finally {
        $writer.Dispose()
    }
}

function Write-JsonLineSafe {
    param(
        [string]$Path,
        [object]$Object,
        [switch]$Flush
    )
    $json = $Object | ConvertTo-SafeJson -Depth 10
    Write-TextSafe -Path $Path -Text ($json + [Environment]::NewLine) -Append -Flush:$Flush
}

function Write-LogSafe {
    param(
        [string]$Path,
        [string]$Message,
        [string]$Level = "INFO"
    )
    $line = "[{0}] [{1}] {2}{3}" -f (Get-StandardTimestamp), $Level, $Message, [Environment]::NewLine
    Write-TextSafe -Path $Path -Text $line -Append -Flush
}

function Rotate-LogIfNeeded {
    param(
        [string]$Path,
        [int]$MaxSizeMb = 50
    )
    try {
        if (Test-Path $Path) {
            $file = Get-Item $Path
            if ($file.Length -gt ($MaxSizeMb * 1MB)) {
                $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
                Rename-Item -Path $Path -NewName ("{0}.{1}.old" -f $file.Name, $stamp) -Force
            }
        }
    }
    catch { }
}

function Remove-OldBlackboxLogs {
    param(
        [string]$Root = (Get-PCBlackboxRoot),
        [int]$Days = 14
    )
    try {
        $cutoff = (Get-Date).AddDays(-1 * $Days)
        Get-ChildItem -Path (Join-Path $Root "logs") -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt $cutoff } |
            ForEach-Object {
                try { Compress-Archive -Path $_.FullName -DestinationPath ($_.FullName + ".zip") -Force; Remove-Item $_.FullName -Force }
                catch { }
            }
    }
    catch { }
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Export-ModuleMember -Function *
