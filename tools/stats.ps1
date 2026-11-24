# xboxmericavi live stats: reads the VIctory log while the game runs and
# draws frame time, fps and where each frame's time goes. Read-only.
param(
    [string]$Log = "xboxmericavi-turbo.log",
    [int]$History = 60
)
$ErrorActionPreference = "SilentlyContinue"
$dir  = Join-Path $env:LOCALAPPDATA "victory"
$path = if ([System.IO.Path]::IsPathRooted($Log)) { $Log } else { Join-Path $dir $Log }
$csv  = Join-Path $dir ("stats-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".csv")
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "xboxmericavi stats - $Log"
$spark = [char[]]@(0x2581,0x2582,0x2583,0x2584,0x2585,0x2586,0x2587,0x2588)
$rx = [regex]'([\d.]+) fps, ([\d.]+) ms/frame \(([\d.]+) preparing: copies ([\d.]+) ms [\d.]+ MB, textures ([\d.]+) ms [\d.]+ MB; ([\d.]+) on the GPU; ([\d.]+) copying back ([\d.]+) MB\), (\d+) draws/frame, dropped (\d+)'
$samples = New-Object System.Collections.Generic.List[object]
"time,fps,ms,preparing,copies,textures,gpu,copyback,copyback_mb,draws,dropped" | Set-Content $csv

Write-Host "Waiting for $path ..." -ForegroundColor DarkGray
# Let the launcher open (and empty) the log first.
Start-Sleep -Seconds 4
while (-not (Test-Path $path)) { Start-Sleep -Milliseconds 500 }
$fs = [System.IO.File]::Open($path, 'Open', 'Read', 'ReadWrite')
$sr = New-Object System.IO.StreamReader($fs)
Clear-Host

function Bar([double]$v, [double]$max, [int]$width, [ConsoleColor]$color, [string]$label) {
    $n = if ($max -gt 0) { [int][Math]::Round([Math]::Min($v / $max, 1) * $width) } else { 0 }
    Write-Host ("{0,-14}" -f $label) -NoNewline
    Write-Host ("#" * $n) -ForegroundColor $color -NoNewline
    Write-Host ("." * ($width - $n)) -ForegroundColor DarkGray -NoNewline
    Write-Host (" {0,7:N1} ms" -f $v)
}

while ($true) {
    $got = $false
    if ($fs.Length -lt $fs.Position) { $sr.DiscardBufferedData(); $fs.Position = 0 }  # log started anew
    while ($null -ne ($line = $sr.ReadLine())) {
        $m = $rx.Match($line)
        if (-not $m.Success) { continue }
        $g = $m.Groups
        $s = [pscustomobject]@{
            fps = [double]$g[1].Value; ms = [double]$g[2].Value; prep = [double]$g[3].Value
            copies = [double]$g[4].Value; tex = [double]$g[5].Value; gpu = [double]$g[6].Value
            back = [double]$g[7].Value; backmb = [double]$g[8].Value; draws = [int]$g[9].Value; dropped = [int]$g[10].Value
        }
        if ($s.draws -lt 50) { continue }   # loading screens and menus
        $samples.Add($s); $got = $true
        if ($samples.Count -gt $History) { $samples.RemoveAt(0) }
        ("{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10}" -f (Get-Date -Format s), $s.fps, $s.ms, $s.prep, $s.copies, $s.tex, $s.gpu, $s.back, $s.backmb, $s.draws, $s.dropped) | Add-Content $csv
    }
    if ($got -and $samples.Count -gt 0) {
        $last = $samples[$samples.Count - 1]
        $ms = $samples | ForEach-Object { $_.ms }
        $min = ($ms | Measure-Object -Minimum).Minimum
        $max = ($ms | Measure-Object -Maximum).Maximum
        $avg = ($ms | Measure-Object -Average).Average
        $line = -join ($ms | ForEach-Object {
            $i = if ($max -gt $min) { [int][Math]::Floor(($_ - $min) / ($max - $min) * 7.999) } else { 0 }
            $spark[$i] })
        [Console]::SetCursorPosition(0, 0)
        Write-Host "  xboxmericavi - live stats                                    " -ForegroundColor Magenta
        Write-Host "  ----------------------------------------------------------" -ForegroundColor DarkMagenta
        $c = if ($last.ms -le 150) { 'Green' } elseif ($last.ms -le 250) { 'Yellow' } else { 'Red' }
        Write-Host ("  NOW  {0,5:N1} fps   {1,6:N1} ms/frame   {2,5} draws   dropped {3,-5}      " -f $last.fps, $last.ms, $last.draws, $last.dropped) -ForegroundColor $c
        Write-Host ("  AVG  {0,5:N1} fps   {1,6:N1} ms   best {2,6:N1} ms   worst {3,6:N1} ms     " -f (1000 / $avg), $avg, $min, $max)
        Write-Host ""
        Write-Host "  frame time, last $($samples.Count) samples (low = fast):          "
        Write-Host ("  " + $line.PadRight($History)) -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  where the last frame went (threads overlap, so parts can sum past the total):"
        $scale = [Math]::Max($last.ms, 1)
        Bar $last.prep   $scale 40 Yellow   "  preparing"
        Bar $last.copies $scale 40 DarkYellow "    copies"
        Bar $last.tex    $scale 40 DarkYellow "    textures"
        Bar $last.gpu    $scale 40 Green    "  on the GPU"
        Bar $last.back   $scale 40 Red      "  copying back"
        Write-Host ""
        Write-Host "  CSV: $csv" -ForegroundColor DarkGray
        Write-Host "  Ctrl+C to close this window (the game keeps running)." -ForegroundColor DarkGray
    }
    Start-Sleep -Milliseconds 700
}
