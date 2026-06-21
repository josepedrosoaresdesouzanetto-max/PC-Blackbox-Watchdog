function Get-BlackboxEventFilters {
    @(
        @{ LogName="System"; ProviderName="Microsoft-Windows-Kernel-Power"; Id=41 },
        @{ LogName="System"; ProviderName="EventLog"; Id=6008 },
        @{ LogName="System"; ProviderName="EventLog"; Id=6005 },
        @{ LogName="System"; ProviderName="EventLog"; Id=6006 },
        @{ LogName="System"; ProviderName="EventLog"; Id=6009 },
        @{ LogName="System"; ProviderName="Microsoft-Windows-Kernel-General"; Id=12 },
        @{ LogName="System"; ProviderName="Microsoft-Windows-Kernel-General"; Id=13 },
        @{ LogName="System"; Id=1001 },
        @{ LogName="System"; ProviderName="volmgr"; Id=161 },
        @{ LogName="System"; ProviderName="volmgr"; Id=162 },
        @{ LogName="System"; ProviderName="Microsoft-Windows-WHEA-Logger"; Id=1 },
        @{ LogName="System"; ProviderName="Microsoft-Windows-WHEA-Logger"; Id=17 },
        @{ LogName="System"; ProviderName="Microsoft-Windows-WHEA-Logger"; Id=18 },
        @{ LogName="System"; ProviderName="Microsoft-Windows-WHEA-Logger"; Id=19 },
        @{ LogName="System"; ProviderName="Microsoft-Windows-WHEA-Logger"; Id=46 },
        @{ LogName="System"; ProviderName="Microsoft-Windows-WHEA-Logger"; Id=47 },
        @{ LogName="System"; ProviderName="Display"; Id=4101 },
        @{ LogName="System"; ProviderName="Disk"; Id=7 },
        @{ LogName="System"; ProviderName="Disk"; Id=11 },
        @{ LogName="System"; ProviderName="Disk"; Id=51 },
        @{ LogName="System"; ProviderName="Disk"; Id=153 },
        @{ LogName="System"; ProviderName="Ntfs"; Id=55 },
        @{ LogName="System"; ProviderName="storahci"; Id=129 },
        @{ LogName="System"; ProviderName="stornvme"; Id=129 },
        @{ LogName="Application"; ProviderName="Application Error"; Id=1000 },
        @{ LogName="Application"; ProviderName="Windows Error Reporting"; Id=1001 },
        @{ LogName="Application"; ProviderName="Application Hang"; Id=1002 }
    )
}

function Get-EventsInWindow {
    param([datetime]$StartTime, [datetime]$EndTime = (Get-Date))
    $result = New-Object System.Collections.Generic.List[object]
    foreach ($filter in Get-BlackboxEventFilters) {
        try {
            $hash = @{ LogName=$filter.LogName; Id=$filter.Id; StartTime=$StartTime; EndTime=$EndTime }
            if ($filter.ProviderName) { $hash.ProviderName = $filter.ProviderName }
            Get-WinEvent -FilterHashtable $hash -ErrorAction SilentlyContinue | ForEach-Object {
                $result.Add([pscustomobject]@{
                    TimeCreated = $_.TimeCreated
                    LogName = $_.LogName
                    ProviderName = $_.ProviderName
                    Id = $_.Id
                    LevelDisplayName = $_.LevelDisplayName
                    RecordId = $_.RecordId
                    Message = $_.Message
                })
            }
        }
        catch { }
    }
    $result | Sort-Object TimeCreated
}

function Get-EventRisk {
    param($Event)
    $msg = [string]$Event.Message
    if ($Event.ProviderName -eq "Microsoft-Windows-WHEA-Logger" -and $Event.Id -in 18,47) { return "critico" }
    if ($Event.Id -eq 1001 -and $Event.LogName -eq "System") { return "critico" }
    if ($Event.ProviderName -eq "Disk" -and $Event.Id -eq 7) { return "critico" }
    if ($Event.ProviderName -eq "Ntfs" -and $Event.Id -eq 55) { return "critico" }
    if ($Event.ProviderName -eq "Display" -and $Event.Id -eq 4101) { return "alto" }
    if ($Event.ProviderName -match "stornvme|storahci" -and $Event.Id -eq 129) { return "alto" }
    if ($Event.ProviderName -eq "Disk" -and $Event.Id -in 51,153) { return "alto" }
    if ($Event.ProviderName -eq "Microsoft-Windows-WHEA-Logger" -and $Event.Id -in 17,19) { return "alto" }
    if ($msg -match "LiveKernelEvent|TDR|nvlddmkm|amdkmdag|amdwddmg|igdkmdn64|dxgkrnl|Display driver stopped responding") { return "alto" }
    if ($Event.ProviderName -eq "Microsoft-Windows-Kernel-Power" -and $Event.Id -eq 41) { return "atencao" }
    return "informativo"
}

function Get-AlertMessageForEvent {
    param($Event)
    if ($Event.ProviderName -eq "Microsoft-Windows-WHEA-Logger" -and $Event.Id -in 18,47) {
        return "ALERTA CRITICO: erro WHEA detectado. Isso pode indicar instabilidade de hardware, CPU, RAM, placa-mae, PCIe ou energia. Salve seu trabalho agora e evite continuar forcando o PC."
    }
    if ($Event.ProviderName -eq "Disk" -or $Event.ProviderName -eq "Ntfs") {
        return "ALERTA CRITICO: erro grave de disco detectado. Faca backup dos arquivos importantes o quanto antes. Evite desligamentos forcados."
    }
    if ($Event.ProviderName -eq "Display" -or $Event.Message -match "TDR|nvlddmkm|amdkmdag|amdwddmg|LiveKernelEvent") {
        return "ALERTA DE ALTO RISCO: falha no driver de video detectada. Pode causar tela preta, travamento ou reinicializacao. Salve seu trabalho agora."
    }
    if ($Event.ProviderName -eq "Microsoft-Windows-Kernel-Power" -and $Event.Id -eq 41) {
        return "AVISO: o Windows registrou desligamento inesperado anteriormente. Isso nao identifica a causa sozinho, mas indica que o sistema nao encerrou corretamente."
    }
    return "Alerta de estabilidade detectado pelo PC-Blackbox-Watchdog."
}

function Invoke-DiagnosisScoring {
    param([object[]]$Events, [object[]]$Samples, [object]$State)
    $evidence = New-Object System.Collections.Generic.List[string]
    $diagnosis = "Dados insuficientes para concluir"
    $confidence = 30
    $risk = "medio"
    $what = "Nenhum padrao unico e definitivo foi identificado."

    if ($Events | Where-Object { $_.ProviderName -eq "Microsoft-Windows-WHEA-Logger" -and $_.Id -eq 18 }) {
        $diagnosis = "hardware critico ou instabilidade eletrica"
        $confidence = 85; $risk = "critico"; $what = "Erro WHEA critico perto da falha."
        $evidence.Add("WHEA-Logger 18 perto da falha.")
    }
    elseif ($Events | Where-Object { $_.LogName -eq "System" -and $_.Id -eq 1001 }) {
        $diagnosis = "tela azul ou falha critica de driver/sistema/RAM"
        $confidence = 80; $risk = "alto"; $what = "BugCheck 1001 encontrado."
        $evidence.Add("BugCheck 1001 indica BSOD registrada.")
    }
    elseif ($Events | Where-Object { $_.ProviderName -eq "Display" -and $_.Id -eq 4101 }) {
        $diagnosis = "possivel GPU ou driver de video"
        $confidence = 65; $risk = "alto"; $what = "Evento Display 4101 encontrado."
        $evidence.Add("Display 4101/TDR perto da falha.")
    }
    elseif ($Events | Where-Object { ($_.ProviderName -in @("Disk","Ntfs","storahci","stornvme")) -and ($_.Id -in 7,51,55,129,153) }) {
        $diagnosis = "possivel SSD/HD/controladora/cabo/driver de armazenamento"
        $confidence = 65; $risk = "alto"; $what = "Eventos de armazenamento foram encontrados."
        $evidence.Add("Eventos de disco/storage perto da falha.")
    }
    elseif (($Events | Where-Object { $_.ProviderName -eq "Microsoft-Windows-Kernel-Power" -and $_.Id -eq 41 }) -and -not ($Events | Where-Object { $_.ProviderName -eq "Microsoft-Windows-WHEA-Logger" -or $_.Id -eq 1001 })) {
        $diagnosis = "desligamento bruto, energia, fonte, tomada, temperatura, placa-mae ou travamento seco"
        $confidence = 55; $risk = "medio"; $what = "Kernel-Power 41 sem BugCheck/WHEA."
        $evidence.Add("Kernel-Power 41 prova desligamento incorreto, mas nao aponta causa sozinho.")
    }
    elseif ($State.heartbeat_missing) {
        $diagnosis = "possivel perda fisica de energia ou travamento seco sem tempo de registro"
        $confidence = 55; $risk = "medio"; $what = "Heartbeat interrompido sem evento conclusivo."
        $evidence.Add("Ultimo heartbeat parou antes do boot atual.")
    }

    [ordered]@{
        summary = $what
        what_happened = $what
        suspected_shutdown_time = $State.suspected_shutdown_time
        unexpected_shutdown_detected = [bool]$State.unexpected_shutdown_detected
        diagnosis = $diagnosis
        confidence_score = $confidence
        risk_level = $risk
        explanation = "Este diagnostico cruza logs continuos, eventos do Windows e estado pos-boot. Ele aponta uma causa provavel, nao certeza absoluta."
        evidence = $evidence
        last_sample_timestamp_before_crash = $State.last_sample_timestamp_before_crash
        seconds_between_last_sample_and_boot_gap = $State.seconds_between_last_sample_and_boot_gap
        partial_alert_report_path = $State.partial_alert_report_path
        recommended_tests = @(
            "Se Kernel-Power 41 aparecer sozinho: testar tomada direta, cabo, filtro de linha, fonte e carga pesada.",
            "Se WHEA aparecer: testar RAM/CPU/placa-mae/PCIe/energia e temperaturas.",
            "Se BugCheck aparecer: analisar minidump com WinDbg.",
            "Se Display/LiveKernelEvent aparecer: investigar driver e temperatura da GPU.",
            "Se Disk/Ntfs/storage aparecer: fazer backup e verificar saude do disco."
        )
    }
}

Export-ModuleMember -Function *
