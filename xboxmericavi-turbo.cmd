@echo off
setlocal
rem ==== xboxmericavi launcher ====
rem Set the path to YOUR OWN game executable here (not included in this repo):
if "%GAME_EXE%"=="" set "GAME_EXE=E:\GTA6.Xbox.v1.0.2.1\game_scarlett_master.exe"
cd /d "%~dp0"
set "PATH=%PATH%;%USERPROFILE%\.cargo\bin"
set "PRESET=TURBO (experimental)"
set VICTORY_RELAY=1
set VICTORY_LATE_WAIT=3
set VICTORY_WIDE_BACK=1
set VICTORY_CARD_BUFFERS_MIN_MB=1
set VICTORY_CARD_BUFFERS_MB=1024
set VICTORY_TEXTURE_FRAME_MS=80
set VICTORY_TEXTURE_FRAME_MB=64
set VICTORY_TEXTURE_NO_WAIT=1
rem xboxmericavi: no 3x texture budget during a backlog (it took 240 ms of the frame; textures take about a minute longer to load).
set VICTORY_TEXTURE_CATCHUP=0
set VICTORY_JOIN_COPIES=1
set VICTORY_UNWATCHED_FRAMES=2
set VICTORY_CARD_REHASH_RUNS=1
set VICTORY_LATE_WAIT_LISTS=256
rem New in victory-fork d510ee4 (upstream: ~6 -> 10 fps in the first rooms):
set VICTORY_ASYNC_SUBMIT=1
set VICTORY_QUEUE2=1
set VICTORY_JOIN_PARTS=1
set VICTORY_BACK_OWN_VIEW=1
set VICTORY_INDIRECT_WINDOW=1
set VICTORY_INDIRECT_GATHER=1
set VICTORY_COPY_PLAIN=1
rem New in victory-fork 52ac4ec, each measured upstream:
rem   preparing thread -9 ms, flights settle later -20 ms, texture pass on its own thread (+40% frames), lookup cache -14 ms
set VICTORY_PARALLEL_REFRESH=1
set VICTORY_SETTLE_ROOM=1
set VICTORY_HEAP_WORKER=1
set VICTORY_LOOKUP_CACHE=1
rem   water lit and boats float (the first boat mission fails without it)
rem off: suspected of the loading crash of 26 Nov (writes textures back into title memory)
rem set VICTORY_TEXTURE_BACK=1
echo Building xboxmericavi (first build takes a few minutes)...
cargo build --release -p victory
if errorlevel 1 (echo BUILD FAILED & pause & exit /b 1)
if not exist "%LOCALAPPDATA%\victory" mkdir "%LOCALAPPDATA%\victory"
start "xboxmericavi stats" "%~dp0xboxmericavi-stats.cmd" xboxmericavi-turbo.log
echo Starting (%PRESET%)... log: %LOCALAPPDATA%\victory\xboxmericavi-turbo.log
rem High CPU priority: the emulator is CPU-bound on 8-thread CPUs.
start "xboxmericavi" /b /wait /high target\release\victory.exe run "%GAME_EXE%" --execute > "%LOCALAPPDATA%\victory\xboxmericavi-turbo.log" 2>&1
echo.
echo Game exited. Log: %LOCALAPPDATA%\victory\xboxmericavi-turbo.log
pause
