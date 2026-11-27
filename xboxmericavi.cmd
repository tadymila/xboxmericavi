@echo off
setlocal
rem ==== xboxmericavi ====
rem Set the path to YOUR OWN game executable here (not included in this repo):
if "%GAME_EXE%"=="" set "GAME_EXE=E:\GTA6.Xbox.v1.0.2.1\game_scarlett_master.exe"
for %%I in ("%GAME_EXE%") do set "VICTORY_GAME_DIR=%%~dpI"
cd /d "%~dp0"
set "PATH=%PATH%;%USERPROFILE%\.cargo\bin"
set "PRESET=xboxmericavi (Series X, 1080p output)"
rem avatarmanz/VIctory-7900XTX scripts\play.ps1 settings:
set VICTORY_TEXTURE_NO_WAIT=1
set VICTORY_RELAY=2
set VICTORY_WIDE_BACK=1
set VICTORY_CARD_REHASH_RUNS=1
set VICTORY_JOIN_COPIES=1
set VICTORY_INDIRECT_WINDOW=1
set VICTORY_RELAY_COPY=1
set VICTORY_CARD_STEPS=2
set VICTORY_INDIRECT_BATCH=2
set VICTORY_MAP_THREADS=1
set VICTORY_TITLE_PRIORITIES=0
set VICTORY_CARD_AWAKE=1
set VICTORY_SHOW_AFTER=1
set VICTORY_AMBIENT=0.8
set VICTORY_D3D12_DRED=light
set VICTORY_THIN=1
set VICTORY_JOIN_PARTS=8
set VICTORY_UPLOAD_AHEAD=1
set VICTORY_LAND_ECHO=0
set VICTORY_UNDER_WIDE=0
rem Its renderer patches 1, 2, 5, 6 and 7 (off by default upstream while tested;
rem together about 57 -> 45 ms a frame there, all of it CPU time we lack most):
set VICTORY_PORT_CONSTANTS=1
set VICTORY_PORT_DESCRIPTORS=1
set VICTORY_PORT_CBV=1
set VICTORY_PORT_GUARD=1
set VICTORY_PORT_JOURNAL=1
rem Series X profile drawn to a 1080p output (upstream: 40 ms, faster than Series S's 43 ms).
set VICTORY_OUTPUT=1920x1080
rem The frame lines (info) feed the console and the stats window.
set VICTORY_LOG=info
echo Building xboxmericavi (first build takes a few minutes)...
cargo build --release --locked -p victory
if errorlevel 1 (echo BUILD FAILED & pause & exit /b 1)
if not exist "%LOCALAPPDATA%\victory" mkdir "%LOCALAPPDATA%\victory"
start "xboxmericavi stats" "%~dp0xboxmericavi-stats.cmd" xboxmericavi.log
rem The console: what the game does right now (frame rate, shaders, pipelines, warnings).
start "xboxmericavi console" powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\console.ps1" -Log xboxmericavi.log
echo Starting (%PRESET%)... log: %LOCALAPPDATA%\victory\xboxmericavi.log
rem High CPU priority: the emulator is CPU-bound on 8-thread CPUs.
start "xboxmericavi" /b /wait /high target\release\victory.exe run "%GAME_EXE%" --console series-x --execute > "%LOCALAPPDATA%\victory\xboxmericavi.log" 2>&1
echo.
echo Game exited. Log: %LOCALAPPDATA%\victory\xboxmericavi.log
pause
