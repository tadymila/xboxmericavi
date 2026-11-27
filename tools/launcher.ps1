# xboxmericavi launcher: pick your own game executable, then build and start.
# Runs xboxmericavi.cmd with GAME_EXE set; nothing else. Uses only your own files.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -Namespace Xm -Name Dpi -MemberDefinition '[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();'
[void][Xm.Dpi]::SetProcessDPIAware()
[System.Windows.Forms.Application]::EnableVisualStyles()

$root    = Split-Path -Parent $PSScriptRoot
$dataDir = Join-Path $env:LOCALAPPDATA "victory"
New-Item -ItemType Directory -Force -Path $dataDir | Out-Null
$cfgPath = Join-Path $dataDir "xboxmericavi-launcher.json"
$logName = "xboxmericavi.log"
$logPath = Join-Path $dataDir $logName
$cfg = @{ exe = "E:\GTA6.Xbox.v1.0.2.1\game_scarlett_master.exe" }
if (Test-Path $cfgPath) {
    try { $saved = Get-Content $cfgPath -Raw | ConvertFrom-Json; if ($saved.exe) { $cfg.exe = $saved.exe } } catch {}
}

# Colours: deep purple background, pink to lavender like the logo.
function Rgb($r, $g, $b) { [System.Drawing.Color]::FromArgb($r, $g, $b) }
$bg      = Rgb 18 12 28
$card    = Rgb 30 21 46
$field   = Rgb 42 30 62
$line    = Rgb 70 52 98
$fg      = Rgb 242 236 250
$muted   = Rgb 160 146 184
$pink    = Rgb 255 92 170
$pinkHi  = Rgb 255 128 190
$lav     = Rgb 168 130 255
$ok      = Rgb 120 220 160
$warn    = Rgb 255 190 110

function Font($size, $bold = $false) {
    $style = if ($bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
    New-Object System.Drawing.Font("Segoe UI", $size, $style)
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "xboxmericavi"
$form.ClientSize = New-Object System.Drawing.Size(640, 588)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.BackColor = $bg
$form.ForeColor = $fg
$form.Font = Font 10
$iconPath = Join-Path $root "branding\icon.ico"
$logo = $null
if (Test-Path $iconPath) {
    try {
        $form.Icon = New-Object System.Drawing.Icon($iconPath)
        $logo = (New-Object System.Drawing.Icon($iconPath, 256, 256)).ToBitmap()
    } catch {}
}

# Header: a pink-to-lavender band with the logo and the name.
$header = New-Object System.Windows.Forms.Panel
$header.Location = New-Object System.Drawing.Point(0, 0)
$header.Size = New-Object System.Drawing.Size(640, 230)
$header.Add_Paint({
    param($s, $e)
    $g = $e.Graphics
    $g.SmoothingMode = "AntiAlias"
    $g.TextRenderingHint = "ClearTypeGridFit"
    $rect = New-Object System.Drawing.Rectangle(0, 0, $s.Width, $s.Height)
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $pink, $lav, 0.0)
    $g.FillRectangle($brush, $rect)
    $shade = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, [System.Drawing.Color]::FromArgb(0, 0, 0, 0), [System.Drawing.Color]::FromArgb(90, 18, 12, 28), 90.0)
    $g.FillRectangle($shade, $rect)
    $g.InterpolationMode = "HighQualityBicubic"
    $x = 28
    if ($logo) { $g.DrawImage($logo, 14, 12, 206, 206); $x = 232 }
    $g.DrawString("xboxmericavi", (Font 30 $true), [System.Drawing.Brushes]::White, $x, 62)
    $g.DrawString("GTA VI (Xbox Series build) on your PC,`nfrom your own files", (Font 11), (New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(235, 255, 255, 255))), ($x + 4), 120)
})
$form.Controls.Add($header)

# A card with rounded corners for the game path.
function RoundedPath($r, $radius) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $radius * 2
    $p.AddArc($r.X, $r.Y, $d, $d, 180, 90)
    $p.AddArc($r.Right - $d, $r.Y, $d, $d, 270, 90)
    $p.AddArc($r.Right - $d, $r.Bottom - $d, $d, $d, 0, 90)
    $p.AddArc($r.X, $r.Bottom - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    $p
}
$panel = New-Object System.Windows.Forms.Panel
$panel.Location = New-Object System.Drawing.Point(20, 248)
$panel.Size = New-Object System.Drawing.Size(600, 104)
$panel.BackColor = $bg
$panel.Add_Paint({
    param($s, $e)
    $e.Graphics.SmoothingMode = "AntiAlias"
    $r = New-Object System.Drawing.Rectangle(0, 0, ($s.Width - 1), ($s.Height - 1))
    $path = RoundedPath $r 12
    $e.Graphics.FillPath((New-Object System.Drawing.SolidBrush($card)), $path)
    $e.Graphics.DrawPath((New-Object System.Drawing.Pen($line)), $path)
})
$form.Controls.Add($panel)

$lblExe = New-Object System.Windows.Forms.Label
$lblExe.Text = "GAME EXECUTABLE"
$lblExe.Font = Font 8.5 $true
$lblExe.ForeColor = $muted
$lblExe.BackColor = $card
$lblExe.Location = New-Object System.Drawing.Point(18, 14)
$lblExe.AutoSize = $true
$panel.Controls.Add($lblExe)

$txtExe = New-Object System.Windows.Forms.TextBox
$txtExe.Location = New-Object System.Drawing.Point(18, 40)
$txtExe.Size = New-Object System.Drawing.Size(450, 28)
$txtExe.BackColor = $field
$txtExe.ForeColor = $fg
$txtExe.BorderStyle = "FixedSingle"
$txtExe.Font = Font 10.5
$txtExe.Text = $cfg.exe
$panel.Controls.Add($txtExe)

$lblCheck = New-Object System.Windows.Forms.Label
$lblCheck.Location = New-Object System.Drawing.Point(18, 74)
$lblCheck.Size = New-Object System.Drawing.Size(560, 20)
$lblCheck.BackColor = $card
$lblCheck.Font = Font 9
$panel.Controls.Add($lblCheck)
$check = {
    $exe = $txtExe.Text.Trim('"', ' ')
    if ($exe -and (Test-Path $exe) -and ((Split-Path $exe -Leaf) -ieq "game_scarlett_master.exe")) {
        $lblCheck.Text = "Found your game."
        $lblCheck.ForeColor = $ok
    } elseif ($exe -and (Test-Path $exe)) {
        $lblCheck.Text = "Found, but expected game_scarlett_master.exe."
        $lblCheck.ForeColor = $warn
    } else {
        $lblCheck.Text = "Not found: pick your own game_scarlett_master.exe."
        $lblCheck.ForeColor = $warn
    }
}
$txtExe.Add_TextChanged($check)
& $check

function FlatButton($text, $x, $y, $w, $h, $back, $hover, $fore, $border) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text
    $b.Location = New-Object System.Drawing.Point($x, $y)
    $b.Size = New-Object System.Drawing.Size($w, $h)
    $b.FlatStyle = "Flat"
    $b.BackColor = $back
    $b.ForeColor = $fore
    $b.FlatAppearance.BorderColor = $border
    $b.FlatAppearance.BorderSize = 1
    $b.FlatAppearance.MouseOverBackColor = $hover
    $b.FlatAppearance.MouseDownBackColor = $hover
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    $b
}

$btnBrowse = FlatButton "Browse..." 478 38 104 30 $field $line $fg $line
$btnBrowse.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title = "Your own game_scarlett_master.exe"
    $dlg.Filter = "game_scarlett_master.exe|game_scarlett_master.exe|Executable (*.exe)|*.exe"
    if ($txtExe.Text -and (Test-Path (Split-Path $txtExe.Text -Parent))) { $dlg.InitialDirectory = Split-Path $txtExe.Text -Parent }
    if ($dlg.ShowDialog() -eq "OK") { $txtExe.Text = $dlg.FileName }
})
$panel.Controls.Add($btnBrowse)

# The last run, from its log: average fps of frames in the world (1,000+ draws).
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Location = New-Object System.Drawing.Point(22, 444)
$lblStatus.Size = New-Object System.Drawing.Size(600, 22)
$lblStatus.ForeColor = $muted
$lblStatus.Font = Font 9.5
$lblStatus.Text = "No run yet."
$form.Controls.Add($lblStatus)
if (Test-Path $logPath) {
    try {
        $rx = [regex]'([\d.]+) fps, ([\d.]+) ms/frame .*?, (\d+) draws/frame'
        $ms = @()
        foreach ($l in (Get-Content $logPath -Tail 4000)) {
            $m = $rx.Match($l)
            if ($m.Success -and [int]$m.Groups[3].Value -ge 1000) {
                $ms += [double]::Parse($m.Groups[2].Value, [System.Globalization.CultureInfo]::InvariantCulture)
            }
        }
        if ($ms.Count -gt 0) {
            $avg = ($ms | Measure-Object -Average).Average
            $when = (Get-Item $logPath).LastWriteTime.ToString("d.M. HH:mm")
            $lblStatus.Text = ("Last run ({0}): {1:N1} fps on average in the world ({2:N0} ms a frame)" -f $when, (1000 / $avg), $avg)
        }
    } catch {}
}

# The big button.
$btnStart = FlatButton "PLAY" 20 370 600 64 $pink $pinkHi ([System.Drawing.Color]::White) $pink
$btnStart.Font = Font 18 $true
$btnStart.Add_Click({
    $exe = $txtExe.Text.Trim('"', ' ')
    if (-not (Test-Path $exe)) {
        [System.Windows.Forms.MessageBox]::Show("Game executable not found:`n$exe", "xboxmericavi") | Out-Null
        return
    }
    @{ exe = $exe } | ConvertTo-Json | Set-Content $cfgPath
    $env:GAME_EXE = $exe
    Start-Process -FilePath (Join-Path $root "xboxmericavi.cmd") -WorkingDirectory $root
    $lblStatus.Text = "Building and starting... the first launch after a build is slow for a few minutes."
})
$form.Controls.Add($btnStart)

$btnStats = FlatButton "Live stats" 20 480 142 40 $card $field $fg $line
$btnStats.Add_Click({ Start-Process -FilePath (Join-Path $root "xboxmericavi-stats.cmd") -ArgumentList $logName -WorkingDirectory $root })
$form.Controls.Add($btnStats)
$btnCon = FlatButton "Console" 172 480 142 40 $card $field $fg $line
$btnCon.Add_Click({ Start-Process powershell -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$(Join-Path $root 'tools\console.ps1')`"", "-Log", $logName) })
$form.Controls.Add($btnCon)
$btnLogs = FlatButton "Logs folder" 324 480 142 40 $card $field $fg $line
$btnLogs.Add_Click({ Start-Process explorer.exe $dataDir })
$form.Controls.Add($btnLogs)
$btnGit = FlatButton "GitHub" 476 480 144 40 $card $field $fg $line
$btnGit.Add_Click({ Start-Process "https://github.com/tadymila/xboxmericavi" })
$form.Controls.Add($btnGit)

$foot = New-Object System.Windows.Forms.Label
$foot.Text = "Built on CGBJ (Codec) | VIctory-7900XTX (AvatarManz) | victory-fork | VIctory (Marvisak). GPL-3.0. No game files included."
$foot.Location = New-Object System.Drawing.Point(22, 538)
$foot.Size = New-Object System.Drawing.Size(600, 40)
$foot.ForeColor = Rgb 110 98 134
$foot.Font = Font 8.5
$form.Controls.Add($foot)

[void]$form.ShowDialog()
