[CmdletBinding()]
param(
    [string]$Root = "C:\PC-Blackbox",
    [switch]$OpenLatest
)

$reports = Get-ChildItem (Join-Path $Root "reports") -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
if (-not $reports) {
    Write-Host "Nenhum relatório encontrado. Rode run-once-diagnostic.ps1 ou aguarde o Analyzer pós-boot."
    exit 0
}

Write-Host "Relatorios recentes:"
$reports | Select-Object -First 10 FullName, LastWriteTime, Length | Format-Table -AutoSize
if ($OpenLatest) {
    Start-Process $reports[0].FullName
}
