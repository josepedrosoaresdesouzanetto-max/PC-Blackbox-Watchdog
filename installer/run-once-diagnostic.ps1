[CmdletBinding()]
param(
    [string]$Root = "C:\PC-Blackbox",
    [int]$Days = 7
)

$script = Join-Path $Root "app\PCBlackbox.Analyzer.ps1"
if (-not (Test-Path $script)) { $script = Join-Path $Root "src\PCBlackbox.Analyzer.ps1" }
if (-not (Test-Path $script)) {
    $script = Join-Path $PSScriptRoot "app\PCBlackbox.Analyzer.ps1"
    if (-not (Test-Path $script)) { $script = Join-Path $PSScriptRoot "src\PCBlackbox.Analyzer.ps1" }
    if ($Root -eq "C:\PC-Blackbox" -and -not (Test-Path $Root)) { $Root = $PSScriptRoot }
}

Write-Host "Executando diagnóstico manual dos últimos $Days dias..."
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script -Root $Root -ManualDays $Days
Write-Host "Relatórios em: $Root\reports"
