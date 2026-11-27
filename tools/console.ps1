# xboxmericavi console: what the game is doing right now, from its log.
# Read-only. One short line a second for the frame rate, the shader and
# pipeline work as it happens, warnings in yellow, errors in red.
param(
    [string]$Log = "xboxmericavi.log",
    [switch]$All
)
$ErrorActionPreference = "SilentlyContinue"
$dir  = Join-Path $env:LOCALAPPDATA "victory"
$path = if ([System.IO.Path]::IsPathRooted($Log)) { $Log } else { Join-Path $dir $Log }
$Host.UI.RawUI.WindowTitle = "xboxmericavi console - $Log"
try { $Host.UI.RawUI.BackgroundColor = "Black"; Clear-Host } catch {}

$frameRx = [regex]'([\d.]+) fps, ([\d.]+) ms/frame \(([\d.]+) preparing: copies ([\d.]+) ms [\d.]+ MB, textures ([\d.]+) ms [\d.]+ MB; ([\d.]+) on the GPU; ([\d.]+) copying back [\d.]+ MB\), (\d+) draws/frame, dropped (\d+) without a host pipeline \((\d+) being made\)'
$cacheRx = [regex]'hits=(\d+) misses=(\d+)'
$inv = [System.Globalization.CultureInfo]::InvariantCulture
$translated = 0

function Show($line) {
    $clean = $line -replace ([string][char]27 + "\[[0-9;]*m"), ""
    $time = if ($clean -match 'T(\d\d:\d\d:\d\d)') {
        ([datetime]::SpecifyKind([datetime]::ParseExact($Matches[1], "HH:mm:ss", $inv), "Utc").ToLocalTime()).ToString("HH:mm:ss")
    } else { (Get-Date).ToString("HH:mm:ss") }
    $m = $frameRx.Match($clean)
    if ($m.Success) {
        $fps = [double]::Parse($m.Groups[1].Value, $inv)
        $making = [int]$m.Groups[10].Value
        $color = if ($fps -ge 20) { "Green" } elseif ($fps -ge 8) { "Cyan" } else { "White" }
        $text = "{0}  {1,5:N1} fps {2,7:N1} ms | prep {3,6:N1}  gpu {4,6:N1}  back {5,6:N1} | {6,5} draws, {7,4} dropped" -f `
            $time, $fps, [double]::Parse($m.Groups[2].Value, $inv), [double]::Parse($m.Groups[3].Value, $inv),
            [double]::Parse($m.Groups[6].Value, $inv), [double]::Parse($m.Groups[7].Value, $inv),
            $m.Groups[8].Value, $m.Groups[9].Value
        Write-Host $text -ForegroundColor $color -NoNewline
        if ($making -gt 0) { Write-Host ("  | {0} pipelines being made" -f $making) -ForegroundColor Magenta } else { Write-Host "" }
        return
    }
    if ($clean -match 'shader translated') {
        $script:translated++
        if ($script:translated % 25 -eq 1) { Write-Host ("{0}  shaders translated this run: {1}" -f $time, $script:translated) -ForegroundColor DarkCyan }
        return
    }
    $c = $cacheRx.Match($clean)
    if ($c.Success) { Write-Host ("{0}  shader cache: {1} from the cache, {2} translated" -f $time, $c.Groups[1].Value, $c.Groups[2].Value) -ForegroundColor DarkCyan; return }
    if ($clean -match ' ERROR |panicked|unhandled exception') { Write-Host $clean -ForegroundColor Red; return }
    if ($clean -match ' WARN ') {
        $short = $clean -replace '^\S+\s+WARN\s+', ''
        if ($short.Length -gt 220) { $short = $short.Substring(0, 220) + "..." }
        Write-Host ("{0}  {1}" -f $time, $short) -ForegroundColor Yellow
        return
    }
    if ($All) { Write-Host $clean -ForegroundColor DarkGray }
}

Write-Host "xboxmericavi console: waiting for $path" -ForegroundColor Magenta
$pos = 0L
$partial = ""
while ($true) {
    if (-not (Test-Path $path)) { Start-Sleep -Milliseconds 500; continue }
    try {
        $fs = [System.IO.File]::Open($path, "Open", "Read", "ReadWrite, Delete")
        if ($fs.Length -lt $pos) {
            # A new run: the log started over.
            $pos = 0L; $partial = ""; $translated = 0
            Write-Host "---- new run ----" -ForegroundColor Magenta
        }
        if ($fs.Length -gt $pos) {
            [void]$fs.Seek($pos, "Begin")
            $reader = New-Object System.IO.StreamReader($fs, [System.Text.Encoding]::UTF8)
            $chunk = $reader.ReadToEnd()
            $pos = $fs.Length
            $reader.Close()
            $lines = ($partial + $chunk) -split "`r?`n"
            $partial = $lines[-1]
            foreach ($l in $lines[0..($lines.Count - 2)]) { if ($l) { Show $l } }
        } else {
            $fs.Close()
        }
    } catch {}
    Start-Sleep -Milliseconds 400
}
