Import-Module (Join-Path $PSScriptRoot "Utils.psm1") -Force -DisableNameChecking

function New-PartialAlertReport {
    param(
        [string]$Root = (Get-PCBlackboxRoot),
        [object]$Alert,
        [object]$LastSample,
        [object[]]$RecentEvents
    )
    $stamp = Get-Date -Format "yyyy-MM-dd-HH-mm"
    $path = Join-Path $Root ("reports\ALERTA-CRITICO-{0}.txt" -f $stamp)
    $text = @"
RELATORIO PARCIAL DE ALERTA CRITICO
Horario do alerta: $($Alert.Timestamp)
Tipo do alerta: $($Alert.AlertType)
Nivel de risco: $($Alert.RiskLevel)
Evento detectado: $($Alert.Source) ID $($Alert.EventId)

Evidencia:
$($Alert.Evidence)

Ultimas metricas disponiveis:
$($LastSample | ConvertTo-SafeJson -Depth 6)

Ultimos eventos criticos:
$($RecentEvents | ConvertTo-SafeJson -Depth 6)

Recomendacao imediata:
$($Alert.Recommendation)

Aviso:
Salve seu trabalho agora. Este relatorio foi gerado enquanto o Windows ainda estava em execucao. Se o PC desligar em seguida, ele pode ajudar a entender o que aconteceu antes da queda.

Limitacao:
Nenhum programa garante aviso antes de desligamento seco instantaneo causado por fonte, tomada, cabo, placa-mae ou queda eletrica.
"@
    Write-TextSafe -Path $path -Text $text -Flush
    return $path
}

function New-PostBootReports {
    param(
        [string]$Root = (Get-PCBlackboxRoot),
        [object]$Diagnosis,
        [object[]]$Events,
        [object[]]$Samples,
        [object[]]$Dumps,
        [object[]]$ReliabilityRecords,
        [object]$State
    )
    $stamp = Get-Date -Format "yyyy-MM-dd-HH-mm"
    $simplePath = Join-Path $Root ("reports\RELATORIO-SIMPLES-{0}.txt" -f $stamp)
    $jsonPath = Join-Path $Root ("reports\RELATORIO-TECNICO-{0}.json" -f $stamp)
    $htmlPath = Join-Path $Root ("reports\RELATORIO-{0}.html" -f $stamp)

    $simple = @"
RELATORIO SIMPLES POS-BOOT
Data: $(Get-Date)

Resumo simples:
$($Diagnosis.summary)

O que aconteceu:
$($Diagnosis.what_happened)

Horario aproximado:
$($Diagnosis.suspected_shutdown_time)

Diagnostico provavel:
$($Diagnosis.diagnosis)

Confianca:
$($Diagnosis.confidence_score)%

Nivel de risco:
$($Diagnosis.risk_level)

Explicacao:
$($Diagnosis.explanation)

Evidencias encontradas:
$($Diagnosis.evidence -join "`r`n")

Ultima amostra salva antes da falha:
$($Diagnosis.last_sample_timestamp_before_crash)

Relatorio parcial antes da queda:
$($Diagnosis.partial_alert_report_path)

O que fazer agora:
$($Diagnosis.recommended_tests -join "`r`n")

O que nao fazer:
- Nao concluir que Kernel-Power 41 prova fonte ruim.
- Nao formatar sem evidencias.
- Nao atualizar BIOS por impulso.
- Nao ignorar WHEA, BugCheck, disco ou temperatura se aparecerem.

Limitacoes:
Nenhum programa consegue garantir aviso antes de desligamento seco instantaneo. O diagnostico aponta causa provavel com base em evidencias, nao certeza absoluta.
"@
    Write-TextSafe -Path $simplePath -Text $simple -Flush

    try { $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop } catch { $os = $null }
    $technical = [ordered]@{
        machine_name = $env:COMPUTERNAME
        user_name = [Environment]::UserName
        windows_version = if ($os) { $os.Version } else { $null }
        windows_build = if ($os) { $os.BuildNumber } else { $null }
        last_boot_time = $State.last_boot_time
        suspected_shutdown_time = $Diagnosis.suspected_shutdown_time
        unexpected_shutdown_detected = $Diagnosis.unexpected_shutdown_detected
        events_found = $Events
        last_samples_before_crash = $Samples
        last_sample_timestamp_before_crash = $Diagnosis.last_sample_timestamp_before_crash
        seconds_between_last_sample_and_boot_gap = $Diagnosis.seconds_between_last_sample_and_boot_gap
        partial_alert_report_found = [bool]$Diagnosis.partial_alert_report_path
        partial_alert_report_path = $Diagnosis.partial_alert_report_path
        minidump_files = $Dumps
        reliability_records = $ReliabilityRecords
        diagnosis = $Diagnosis.diagnosis
        confidence_score = $Diagnosis.confidence_score
        risk_level = $Diagnosis.risk_level
        recommended_tests = $Diagnosis.recommended_tests
        limitations = @("Desligamento seco instantaneo pode nao gerar alerta previo.", "Kernel-Power 41 nao aponta causa sozinho.", "Sensores podem nao estar disponiveis pelo Windows.")
    }
    Write-TextSafe -Path $jsonPath -Text (($technical | ConvertTo-SafeJson -Depth 12) + [Environment]::NewLine) -Flush

    $rows = ($Events | ForEach-Object { "<tr><td>$($_.TimeCreated)</td><td>$($_.ProviderName)</td><td>$($_.Id)</td><td>$([System.Web.HttpUtility]::HtmlEncode($_.Message))</td></tr>" }) -join "`n"
    $sampleRows = ($Samples | ForEach-Object { "<tr><td>$($_.timestamp_local)</td><td>$($_.cpu_total_percent)</td><td>$($_.ram_used_percent)</td><td>$($_.disk_c_free_percent)</td><td>$($_.mode)</td></tr>" }) -join "`n"
    $html = @"
<!doctype html><html><head><meta charset="utf-8"><title>PC Blackbox Report</title>
<style>body{font-family:Segoe UI,Arial,sans-serif;margin:24px;background:#f6f8fb;color:#172033}.card{background:white;border-radius:10px;padding:16px;margin:12px 0;box-shadow:0 1px 5px #ccd}table{border-collapse:collapse;width:100%;background:white}td,th{border:1px solid #ddd;padding:6px;vertical-align:top}th{background:#eef2f7}.risk{font-weight:bold}</style>
</head><body>
<h1>PC-Blackbox-Watchdog</h1>
<div class="card"><h2>Resumo</h2><p>$($Diagnosis.summary)</p><p class="risk">Risco: $($Diagnosis.risk_level) | Confianca: $($Diagnosis.confidence_score)%</p></div>
<div class="card"><h2>Diagnostico</h2><p>$($Diagnosis.diagnosis)</p><p>$($Diagnosis.explanation)</p></div>
<div class="card"><h2>Relatorio parcial antes da queda</h2><p>$($Diagnosis.partial_alert_report_path)</p></div>
<h2>Eventos</h2><table><tr><th>Hora</th><th>Fonte</th><th>ID</th><th>Mensagem</th></tr>$rows</table>
<h2>Ultimas amostras</h2><table><tr><th>Hora</th><th>CPU %</th><th>RAM %</th><th>Disco C livre %</th><th>Modo</th></tr>$sampleRows</table>
<div class="card"><h2>Limitacoes</h2><p>Nenhum programa consegue garantir aviso antes de desligamento seco instantaneo causado por fonte, tomada, cabo, placa-mae ou queda eletrica.</p></div>
</body></html>
"@
    Write-TextSafe -Path $htmlPath -Text $html -Flush

    [ordered]@{ simple = $simplePath; technical = $jsonPath; html = $htmlPath }
}

Export-ModuleMember -Function *
