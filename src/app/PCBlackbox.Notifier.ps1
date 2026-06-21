[CmdletBinding()]
param(
    [string]$Root = "C:\PC-Blackbox"
)

$ErrorActionPreference = "Continue"
$alertFile = Join-Path $Root "logs\alerts\urgent-alerts.jsonl"
$stateFile = Join-Path $Root "logs\state\notifier-offset.txt"
$errorLog = Join-Path $Root "logs\alerts\notifier-error.log"
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $stateFile), (Split-Path -Parent $errorLog) | Out-Null

$offset = 0
if (Test-Path $stateFile) { try { $offset = [int64](Get-Content -Raw $stateFile) } catch { $offset = 0 } }

while ($true) {
    try {
        if (Test-Path $alertFile) {
            $file = Get-Item $alertFile
            if ($file.Length -lt $offset) { $offset = 0 }
            $fs = [System.IO.File]::Open($alertFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
            try {
                $fs.Seek($offset, [System.IO.SeekOrigin]::Begin) | Out-Null
                $reader = New-Object System.IO.StreamReader($fs)
                while (-not $reader.EndOfStream) {
                    $line = $reader.ReadLine()
                    if ($line) {
                        try {
                            $alert = $line | ConvertFrom-Json
                            if ($alert.RiskLevel -match "critico|crítico|alto") {
                                try { [console]::beep(1000, 300) } catch { }
                                try {
                                    Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
                                    [System.Windows.Forms.MessageBox]::Show([string]$alert.Message, [string]$alert.Title, "OK", "Warning") | Out-Null
                                } catch { }
                            }
                        }
                        catch { }
                    }
                }
                $offset = $fs.Position
                Set-Content -Path $stateFile -Value $offset -Encoding ASCII
            }
            finally { $fs.Dispose() }
        }
    }
    catch {
        "[{0}] {1}" -f (Get-Date), $_.Exception.Message | Out-File $errorLog -Append -Encoding UTF8
    }
    Start-Sleep -Seconds 2
}
