[CmdletBinding()]
param(
    [string]$Root = "C:\PC-Blackbox",
    [int]$RefreshSeconds = 10
)

$ErrorActionPreference = "Continue"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$createdNew = $false
$mutexName = "PCBlackboxStatusIcon-$env:USERNAME"
$mutex = New-Object System.Threading.Mutex($true, $mutexName, [ref]$createdNew)
if (-not $createdNew) { exit 0 }

$script:CurrentStatus = $null
$script:LastBalloonStatus = $null
$script:Frame = 0
$script:LastStatusRefresh = [datetime]::MinValue
$script:ExitRequested = $false
$script:ExitFlagPath = Join-Path $Root "logs\state\status-icon-exit.flag"
if (Test-Path $script:ExitFlagPath) {
    Remove-Item -LiteralPath $script:ExitFlagPath -Force -ErrorAction SilentlyContinue
}

function Stop-StatusIcon {
    $script:ExitRequested = $true
    try {
        $exitDir = Split-Path -Parent $script:ExitFlagPath
        if ($exitDir) { New-Item -ItemType Directory -Force -Path $exitDir | Out-Null }
        Set-Content -LiteralPath $script:ExitFlagPath -Value ((Get-Date).ToString("o")) -Encoding ASCII
    }
    catch { }
    try { if ($timer) { $timer.Stop() } } catch { }
    try {
        if ($notify) {
            $notify.Visible = $false
            $notify.Dispose()
        }
    }
    catch { }
    [System.Windows.Forms.Application]::ExitThread()
    [System.Windows.Forms.Application]::Exit()
}

function Get-HeartbeatStatus {
    $heartbeatPath = Join-Path $Root "logs\state\heartbeat.json"
    $taskRows = @()
    try {
        $taskRows = Get-ScheduledTask -TaskName "PC-Blackbox-*" -ErrorAction SilentlyContinue |
            Select-Object TaskName, State
    }
    catch { $taskRows = @() }

    if (-not (Test-Path $heartbeatPath)) {
        return [pscustomobject]@{
            Level = "red"
            Title = "PC-Blackbox parado"
            Message = "heartbeat.json ainda não existe."
            AgeSeconds = $null
            HeartbeatPath = $heartbeatPath
            Tasks = $taskRows
        }
    }

    try {
        $heartbeat = Get-Content -Raw $heartbeatPath | ConvertFrom-Json
        $stamp = $null
        if ($heartbeat.timestamp_utc) {
            $stamp = [datetimeoffset]::Parse([string]$heartbeat.timestamp_utc).ToLocalTime()
        }
        elseif ($heartbeat.timestamp) {
            $stamp = [datetimeoffset]::Parse([string]$heartbeat.timestamp)
        }
        if (-not $stamp) { throw "Timestamp do heartbeat ausente." }

        $age = [int]([datetimeoffset]::Now - $stamp).TotalSeconds
        if ($age -le 180) {
            $level = "green"
            $title = "PC-Blackbox funcionando"
            $message = "Último heartbeat há $age segundos."
        }
        elseif ($age -le 600) {
            $level = "yellow"
            $title = "PC-Blackbox atrasado"
            $message = "Último heartbeat há $age segundos. Pode estar iniciando, ocupado ou parado há pouco tempo."
        }
        else {
            $level = "red"
            $title = "PC-Blackbox sem heartbeat recente"
            $message = "Último heartbeat há $age segundos. O agente pode não estar rodando."
        }

        return [pscustomobject]@{
            Level = $level
            Title = $title
            Message = $message
            AgeSeconds = $age
            HeartbeatPath = $heartbeatPath
            Tasks = $taskRows
        }
    }
    catch {
        return [pscustomobject]@{
            Level = "red"
            Title = "PC-Blackbox com leitura falhando"
            Message = "Não consegui ler o heartbeat: $($_.Exception.Message)"
            AgeSeconds = $null
            HeartbeatPath = $heartbeatPath
            Tasks = $taskRows
        }
    }
}

function Get-LevelColor {
    param([string]$Level)
    switch ($Level) {
        "green" { return [System.Drawing.Color]::FromArgb(42, 185, 95) }
        "yellow" { return [System.Drawing.Color]::FromArgb(238, 180, 34) }
        default { return [System.Drawing.Color]::FromArgb(220, 65, 65) }
    }
}

function New-EyeBitmap {
    param(
        [string]$Level,
        [int]$GazeX = 0,
        [int]$GazeY = 0,
        [double]$Open = 1.0,
        [int]$Size = 64
    )

    $bitmap = New-Object System.Drawing.Bitmap $Size,$Size
    $g = [System.Drawing.Graphics]::FromImage($bitmap)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)

    $scale = $Size / 64.0
    $iris = Get-LevelColor -Level $Level
    $openHeight = [Math]::Max(2, [int](20 * $Open * $scale))
    $centerX = [int](32 * $scale)
    $centerY = [int](32 * $scale)
    $left = [int](6 * $scale)
    $right = [int](58 * $scale)
    $top = $centerY - $openHeight
    $bottom = $centerY + $openHeight

    $eyePen = New-Object System.Drawing.Pen ([System.Drawing.Color]::White), ([Math]::Max(2, 5 * $scale))
    $shadowPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(85, 0, 0, 0)), ([Math]::Max(3, 7 * $scale))
    $irisBrush = New-Object System.Drawing.SolidBrush $iris
    $blackBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(18, 18, 18))
    $shineBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)

    $topPoints = @(
        (New-Object System.Drawing.Point $left,$centerY),
        (New-Object System.Drawing.Point ([int](18 * $scale)),$top),
        (New-Object System.Drawing.Point $centerX,([int]($top - 3 * $scale))),
        (New-Object System.Drawing.Point ([int](46 * $scale)),$top),
        (New-Object System.Drawing.Point $right,$centerY)
    )
    $bottomPoints = @(
        (New-Object System.Drawing.Point $left,$centerY),
        (New-Object System.Drawing.Point ([int](18 * $scale)),$bottom),
        (New-Object System.Drawing.Point $centerX,([int]($bottom + 3 * $scale))),
        (New-Object System.Drawing.Point ([int](46 * $scale)),$bottom),
        (New-Object System.Drawing.Point $right,$centerY)
    )

    $g.DrawCurve($shadowPen, $topPoints)
    $g.DrawCurve($shadowPen, $bottomPoints)
    $g.DrawCurve($eyePen, $topPoints)
    $g.DrawCurve($eyePen, $bottomPoints)

    if ($Open -gt 0.25) {
        $irisSize = [int](24 * $scale)
        $pupilSize = [int](10 * $scale)
        $irisX = [int]($centerX - ($irisSize / 2) + ($GazeX * $scale))
        $irisY = [int]($centerY - ($irisSize / 2) + ($GazeY * $scale))
        $g.FillEllipse($irisBrush, $irisX, $irisY, $irisSize, $irisSize)
        $g.FillEllipse($blackBrush, [int]($irisX + 7 * $scale), [int]($irisY + 7 * $scale), $pupilSize, $pupilSize)
        $g.FillEllipse($shineBrush, [int]($irisX + 5 * $scale), [int]($irisY + 3 * $scale), [int](6 * $scale), [int](6 * $scale))
    }

    $eyePen.Dispose()
    $shadowPen.Dispose()
    $irisBrush.Dispose()
    $blackBrush.Dispose()
    $shineBrush.Dispose()
    $g.Dispose()
    return $bitmap
}

function New-EyeIcon {
    param(
        [string]$Level,
        [int]$GazeX = 0,
        [int]$GazeY = 0,
        [double]$Open = 1.0
    )

    $bitmap = New-EyeBitmap -Level $Level -GazeX $GazeX -GazeY $GazeY -Open $Open -Size 64
    $iconHandle = $bitmap.GetHicon()
    $icon = [System.Drawing.Icon]::FromHandle($iconHandle)
    $bitmap.Dispose()
    return $icon
}

function Get-AnimationFrame {
    $script:Frame++
    $blink = (($script:Frame % 22) -in 0,1)
    $open = 1.0
    if ($blink) { $open = 0.12 }
    $positions = @(
        @{ X = -4; Y = 0 },
        @{ X = -2; Y = -1 },
        @{ X = 0; Y = 0 },
        @{ X = 3; Y = 1 },
        @{ X = 4; Y = 0 },
        @{ X = 1; Y = -1 },
        @{ X = 0; Y = 0 }
    )
    $pos = $positions[$script:Frame % $positions.Count]
    [pscustomobject]@{ X = $pos.X; Y = $pos.Y; Open = $open }
}

function Show-StatusWindow {
    $status = Get-HeartbeatStatus
    $tasksText = "Nenhuma tarefa PC-Blackbox encontrada."
    if ($status.Tasks -and $status.Tasks.Count -gt 0) {
        $tasksText = ($status.Tasks | ForEach-Object { "$($_.TaskName): $($_.State)" }) -join [Environment]::NewLine
    }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "PC-Blackbox Dashboard"
    $form.StartPosition = "CenterScreen"
    $form.Width = 620
    $form.Height = 390
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.BackColor = [System.Drawing.Color]::FromArgb(246, 248, 251)

    $accent = Get-LevelColor -Level $status.Level
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Left = 0
    $panel.Top = 0
    $panel.Width = 620
    $panel.Height = 96
    $panel.BackColor = $accent
    $form.Controls.Add($panel)

    $picture = New-Object System.Windows.Forms.PictureBox
    $picture.Width = 72
    $picture.Height = 72
    $picture.Left = 22
    $picture.Top = 12
    $picture.Image = (New-EyeBitmap -Level $status.Level -Size 72)
    $panel.Controls.Add($picture)

    $title = New-Object System.Windows.Forms.Label
    $title.Left = 110
    $title.Top = 18
    $title.Width = 460
    $title.Height = 30
    $title.ForeColor = [System.Drawing.Color]::White
    $title.Font = New-Object System.Drawing.Font("Segoe UI", 15, [System.Drawing.FontStyle]::Bold)
    $title.Text = $status.Title
    $panel.Controls.Add($title)

    $message = New-Object System.Windows.Forms.Label
    $message.Left = 112
    $message.Top = 52
    $message.Width = 460
    $message.Height = 24
    $message.ForeColor = [System.Drawing.Color]::White
    $message.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $message.Text = $status.Message
    $panel.Controls.Add($message)

    $scope = New-Object System.Windows.Forms.Label
    $scope.Left = 22
    $scope.Top = 112
    $scope.Width = 555
    $scope.Height = 44
    $scope.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $scope.Text = "Ferramenta feita para um problema específico: investigar desligamento inesperado, travamento, tela azul, LiveKernelEvent, WHEA, falha de GPU/disco e sinais antes de uma queda. Ela não corrige hardware automaticamente."
    $form.Controls.Add($scope)

    $tasks = New-Object System.Windows.Forms.TextBox
    $tasks.Left = 22
    $tasks.Top = 168
    $tasks.Width = 555
    $tasks.Height = 82
    $tasks.Multiline = $true
    $tasks.ReadOnly = $true
    $tasks.ScrollBars = "Vertical"
    $tasks.Font = New-Object System.Drawing.Font("Consolas", 9)
    $tasks.Text = $tasksText
    $form.Controls.Add($tasks)

    $openReports = New-Object System.Windows.Forms.Button
    $openReports.Left = 22
    $openReports.Top = 272
    $openReports.Width = 145
    $openReports.Text = "Abrir relatórios"
    $openReports.Add_Click({
        $path = Join-Path $Root "reports"
        if (Test-Path $path) { Start-Process explorer.exe $path }
    })
    $form.Controls.Add($openReports)

    $openRoot = New-Object System.Windows.Forms.Button
    $openRoot.Left = 178
    $openRoot.Top = 272
    $openRoot.Width = 145
    $openRoot.Text = "Abrir pasta"
    $openRoot.Add_Click({ if (Test-Path $Root) { Start-Process explorer.exe $Root } })
    $form.Controls.Add($openRoot)

    $startAgent = New-Object System.Windows.Forms.Button
    $startAgent.Left = 334
    $startAgent.Top = 272
    $startAgent.Width = 145
    $startAgent.Text = "Iniciar agente"
    $startAgent.Add_Click({
        try {
            Start-ScheduledTask -TaskName "PC-Blackbox-Agent" -ErrorAction Stop
            [System.Windows.Forms.MessageBox]::Show("Comando enviado para iniciar o agente.", "PC-Blackbox", "OK", "Information") | Out-Null
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Não consegui iniciar a tarefa. Tente abrir como Administrador.`r`n`r`n$($_.Exception.Message)", "PC-Blackbox", "OK", "Warning") | Out-Null
        }
    })
    $form.Controls.Add($startAgent)

    $close = New-Object System.Windows.Forms.Button
    $close.Left = 490
    $close.Top = 272
    $close.Width = 87
    $close.Text = "Fechar"
    $close.Add_Click({ $form.Close() })
    $form.Controls.Add($close)

    $footer = New-Object System.Windows.Forms.Label
    $footer.Left = 22
    $footer.Top = 324
    $footer.Width = 555
    $footer.Height = 20
    $footer.ForeColor = [System.Drawing.Color]::FromArgb(90, 90, 90)
    $footer.Text = "PC-Blackbox-Watchdog v1.0 - diagnóstico local, sem envio de dados para a internet."
    $form.Controls.Add($footer)

    $form.ShowDialog() | Out-Null
}

$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Visible = $true
$notify.ContextMenuStrip = New-Object System.Windows.Forms.ContextMenuStrip

$menuStatus = $notify.ContextMenuStrip.Items.Add("Carregando status...")
$menuStatus.Enabled = $false
[void]$notify.ContextMenuStrip.Items.Add("-")
$menuOpen = $notify.ContextMenuStrip.Items.Add("Abrir dashboard")
$menuRefresh = $notify.ContextMenuStrip.Items.Add("Atualizar agora")
$menuReports = $notify.ContextMenuStrip.Items.Add("Abrir relatórios")
$menuStart = $notify.ContextMenuStrip.Items.Add("Iniciar agente")
[void]$notify.ContextMenuStrip.Items.Add("-")
$menuExit = $notify.ContextMenuStrip.Items.Add("Sair do olhinho")

$menuOpen.Add_Click({ Show-StatusWindow })
$notify.Add_DoubleClick({ Show-StatusWindow })
$menuRefresh.Add_Click({ Update-TrayStatus -Force })
$menuReports.Add_Click({
    $path = Join-Path $Root "reports"
    if (Test-Path $path) { Start-Process explorer.exe $path }
})
$menuStart.Add_Click({
    try { Start-ScheduledTask -TaskName "PC-Blackbox-Agent" -ErrorAction Stop }
    catch { [System.Windows.Forms.MessageBox]::Show("Não consegui iniciar a tarefa: $($_.Exception.Message)", "PC-Blackbox", "OK", "Warning") | Out-Null }
    Update-TrayStatus -Force
})
$menuExit.Add_Click({
    Stop-StatusIcon
})

function Update-TrayStatus {
    param([switch]$Force)
    $now = Get-Date
    if ($Force -or -not $script:CurrentStatus -or (($now - $script:LastStatusRefresh).TotalSeconds -ge $RefreshSeconds)) {
        $status = Get-HeartbeatStatus
        $script:CurrentStatus = $status
        $script:LastStatusRefresh = $now
        $notify.Text = ($status.Title.Substring(0, [Math]::Min(63, $status.Title.Length)))
        $menuStatus.Text = $status.Title

        if ($script:LastBalloonStatus -and $script:LastBalloonStatus -ne $status.Level -and $status.Level -ne "green") {
            $notify.BalloonTipTitle = $status.Title
            $notify.BalloonTipText = $status.Message
            $notify.BalloonTipIcon = "Warning"
            $notify.ShowBalloonTip(5000)
        }
        $script:LastBalloonStatus = $status.Level
    }
}

function Update-AnimatedIcon {
    if (-not $script:CurrentStatus) { Update-TrayStatus -Force }
    $frame = Get-AnimationFrame
    if ($notify.Icon) { $notify.Icon.Dispose() }
    $notify.Icon = New-EyeIcon -Level $script:CurrentStatus.Level -GazeX $frame.X -GazeY $frame.Y -Open $frame.Open
}

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 650
$timer.Add_Tick({
    if ($script:ExitRequested -or (Test-Path $script:ExitFlagPath)) {
        Stop-StatusIcon
        return
    }
    Update-TrayStatus
    Update-AnimatedIcon
})

try {
    Update-TrayStatus -Force
    Update-AnimatedIcon
    $timer.Start()
    [System.Windows.Forms.Application]::Run()
}
finally {
    if ($notify) {
        $notify.Visible = $false
        $notify.Dispose()
    }
    if ($mutex -and $createdNew) {
        $mutex.ReleaseMutex()
        $mutex.Dispose()
    }
}
