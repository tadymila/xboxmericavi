# xboxmericavi launcher: pick a preset and your own game executable, then
# build and start. Runs the preset's .cmd with GAME_EXE set; nothing else.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$root = Split-Path -Parent $PSScriptRoot
$dataDir = Join-Path $env:LOCALAPPDATA "victory"
New-Item -ItemType Directory -Force -Path $dataDir | Out-Null
$cfgPath = Join-Path $dataDir "xboxmericavi-launcher.json"
$cfg = @{ exe = "E:\GTA6.Xbox.v1.0.2.1\game_scarlett_master.exe"; preset = "TURBO" }
if (Test-Path $cfgPath) {
    try { $saved = Get-Content $cfgPath -Raw | ConvertFrom-Json; $cfg.exe = $saved.exe; $cfg.preset = $saved.preset } catch {}
}

$presets = [ordered]@{
    "TURBO"   = @{ cmd = "xboxmericavi-turbo.cmd"; log = "xboxmericavi-turbo.log"; info = "Fastest (recommended): the game runs as a Series S, fewer pixels." }
    "QUALITY" = @{ cmd = "xboxmericavi.cmd";       log = "xboxmericavi.log";       info = "Sharper: the game runs as a Series X, full resolution, slower." }
}

$pink = [System.Drawing.Color]::FromArgb(255, 79, 163)
$bg   = [System.Drawing.Color]::FromArgb(24, 16, 34)
$fg   = [System.Drawing.Color]::FromArgb(240, 232, 250)

$form = New-Object System.Windows.Forms.Form
$form.Text = "xboxmericavi launcher"
$form.Size = New-Object System.Drawing.Size(620, 430)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = $bg
$form.ForeColor = $fg
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

$title = New-Object System.Windows.Forms.Label
$title.Text = "xboxmericavi"
$title.Font = New-Object System.Drawing.Font("Segoe UI", 22, [System.Drawing.FontStyle]::Bold)
$title.ForeColor = $pink
$title.Location = New-Object System.Drawing.Point(20, 12)
$title.AutoSize = $true
$form.Controls.Add($title)

$sub = New-Object System.Windows.Forms.Label
$sub.Text = "Performance fork of victory-fork / VIctory. Uses your own game files only."
$sub.Location = New-Object System.Drawing.Point(22, 58)
$sub.AutoSize = $true
$form.Controls.Add($sub)

$lblExe = New-Object System.Windows.Forms.Label
$lblExe.Text = "Game executable (game_scarlett_master.exe):"
$lblExe.Location = New-Object System.Drawing.Point(22, 98)
$lblExe.AutoSize = $true
$form.Controls.Add($lblExe)

$txtExe = New-Object System.Windows.Forms.TextBox
$txtExe.Location = New-Object System.Drawing.Point(22, 122)
$txtExe.Size = New-Object System.Drawing.Size(470, 26)
$txtExe.Text = $cfg.exe
$form.Controls.Add($txtExe)

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Browse..."
$btnBrowse.Location = New-Object System.Drawing.Point(500, 120)
$btnBrowse.Size = New-Object System.Drawing.Size(90, 30)
$btnBrowse.FlatStyle = "Flat"
$btnBrowse.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "Game executable (*.exe)|*.exe"
    if ($dlg.ShowDialog() -eq "OK") { $txtExe.Text = $dlg.FileName }
})
$form.Controls.Add($btnBrowse)

$lblPreset = New-Object System.Windows.Forms.Label
$lblPreset.Text = "Preset:"
$lblPreset.Location = New-Object System.Drawing.Point(22, 168)
$lblPreset.AutoSize = $true
$form.Controls.Add($lblPreset)

$cmbPreset = New-Object System.Windows.Forms.ComboBox
$cmbPreset.DropDownStyle = "DropDownList"
$cmbPreset.Location = New-Object System.Drawing.Point(22, 192)
$cmbPreset.Size = New-Object System.Drawing.Size(160, 28)
foreach ($k in $presets.Keys) { [void]$cmbPreset.Items.Add($k) }
$cmbPreset.SelectedItem = if ($presets.Contains($cfg.preset)) { $cfg.preset } else { "TURBO" }
$form.Controls.Add($cmbPreset)

$lblInfo = New-Object System.Windows.Forms.Label
$lblInfo.Location = New-Object System.Drawing.Point(195, 196)
$lblInfo.Size = New-Object System.Drawing.Size(400, 44)
$form.Controls.Add($lblInfo)
$update = { $lblInfo.Text = $presets[$cmbPreset.SelectedItem].info }
$cmbPreset.Add_SelectedIndexChanged($update)
& $update

$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "BUILD && START"
$btnStart.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$btnStart.BackColor = $pink
$btnStart.ForeColor = [System.Drawing.Color]::White
$btnStart.FlatStyle = "Flat"
$btnStart.Location = New-Object System.Drawing.Point(22, 250)
$btnStart.Size = New-Object System.Drawing.Size(568, 52)
$btnStart.Add_Click({
    $exe = $txtExe.Text.Trim('"', ' ')
    if (-not (Test-Path $exe)) {
        [System.Windows.Forms.MessageBox]::Show("Game executable not found:`n$exe", "xboxmericavi") | Out-Null
        return
    }
    $preset = $cmbPreset.SelectedItem
    @{ exe = $exe; preset = $preset } | ConvertTo-Json | Set-Content $cfgPath
    $env:GAME_EXE = $exe
    Start-Process -FilePath (Join-Path $root $presets[$preset].cmd) -WorkingDirectory $root
})
$form.Controls.Add($btnStart)

function SmallButton($text, $x, $action) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text
    $b.Location = New-Object System.Drawing.Point($x, 318)
    $b.Size = New-Object System.Drawing.Size(180, 34)
    $b.FlatStyle = "Flat"
    $b.Add_Click($action)
    $form.Controls.Add($b)
}
SmallButton "Live stats" 22 {
    Start-Process -FilePath (Join-Path $root "xboxmericavi-stats.cmd") -ArgumentList $presets[$cmbPreset.SelectedItem].log -WorkingDirectory $root
}
SmallButton "Open logs folder" 216 { Start-Process explorer.exe $dataDir }
SmallButton "GitHub page" 410 { Start-Process "https://github.com/tadymila/xboxmericavi" }

[void]$form.ShowDialog()
