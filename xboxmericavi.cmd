@echo off
setlocal
rem ==== xboxmericavi: QUALITY (Series X, sharper) ====
rem The settings of Codec's (CGBJ) Play-VIctory.cmd pareto-residency, from Pavl3000/cgbj-fork.
rem Series X: the console's full resolution; sharper, slower.
rem Set the path to YOUR OWN game executable here (not included in this repo):
if "%GAME_EXE%"=="" set "GAME_EXE=E:\GTA6.Xbox.v1.0.2.1\game_scarlett_master.exe"
for %%I in ("%GAME_EXE%") do set "VICTORY_GAME_DIR=%%~dpI"
cd /d "%~dp0"
set "PATH=%PATH%;%USERPROFILE%\.cargo\bin"
set "PRESET=QUALITY (Series X, sharper)"
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
set VICTORY_CARD_AWAKE=1
set VICTORY_SHOW_AFTER=1
set VICTORY_AMBIENT=0.8
set VICTORY_AMBIENT_AIR=1.5
set VICTORY_THIN=1
set VICTORY_JOIN_PARTS=8
set VICTORY_UPLOAD_AHEAD=1
set VICTORY_LEVELS_ON_DEMAND=1
set VICTORY_CARD_BUFFERS_MIN_KB=64
set VICTORY_CACHE_DIR=%LOCALAPPDATA%\VIctory\cache-pareto
rem The frame lines (info) feed the stats window.
set VICTORY_LOG=info
echo Building xboxmericavi (first build takes a few minutes)...
cargo build --release --locked -p victory
if errorlevel 1 (echo BUILD FAILED & pause & exit /b 1)
if not exist "%LOCALAPPDATA%\victory" mkdir "%LOCALAPPDATA%\victory"
start "xboxmericavi stats" "%~dp0xboxmericavi-stats.cmd" xboxmericavi.log
echo Starting (%PRESET%)... log: %LOCALAPPDATA%\victory\xboxmericavi.log
rem High CPU priority: the emulator is CPU-bound on 8-thread CPUs.
start "xboxmericavi" /b /wait /high target\release\victory.exe run "%GAME_EXE%" --console series-x --execute > "%LOCALAPPDATA%\victory\xboxmericavi.log" 2>&1
echo.
echo Game exited. Log: %LOCALAPPDATA%\victory\xboxmericavi.log
pause
