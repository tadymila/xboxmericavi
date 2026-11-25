@echo off
setlocal
rem ==== xboxmericavi launcher ====
rem Set the path to YOUR OWN game executable here (not included in this repo):
if "%GAME_EXE%"=="" set "GAME_EXE=E:\GTA6.Xbox.v1.0.2.1\game_scarlett_master.exe"
cd /d "%~dp0"
set "PATH=%PATH%;%USERPROFILE%\.cargo\bin"
set "PRESET=TURBO+RELAY2 (test)"
set VICTORY_RELAY=2
set VICTORY_LATE_WAIT=3
set VICTORY_WIDE_BACK=1
set VICTORY_CARD_BUFFERS_MIN_MB=1
set VICTORY_CARD_BUFFERS_MB=1024
set VICTORY_TEXTURE_FRAME_MS=80
set VICTORY_TEXTURE_FRAME_MB=64
set VICTORY_TEXTURE_NO_WAIT=1
set VICTORY_JOIN_COPIES=1
set VICTORY_UNWATCHED_FRAMES=2
set VICTORY_CARD_REHASH_RUNS=1
set VICTORY_LATE_WAIT_LISTS=256
echo Building xboxmericavi (first build takes a few minutes)...
cargo build --release -p victory
if errorlevel 1 (echo BUILD FAILED & pause & exit /b 1)
if not exist "%LOCALAPPDATA%\victory" mkdir "%LOCALAPPDATA%\victory"
start "xboxmericavi stats" "%~dp0xboxmericavi-stats.cmd" xboxmericavi-relay2.log
echo Starting (%PRESET%)... log: %LOCALAPPDATA%\victory\xboxmericavi-relay2.log
rem High CPU priority: the emulator is CPU-bound on 8-thread CPUs.
start "xboxmericavi" /b /wait /high target\release\victory.exe run "%GAME_EXE%" --execute > "%LOCALAPPDATA%\victory\xboxmericavi-relay2.log" 2>&1
echo.
echo Game exited. Log: %LOCALAPPDATA%\victory\xboxmericavi-relay2.log
pause
