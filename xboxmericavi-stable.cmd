@echo off
setlocal
rem ==== xboxmericavi launcher ====
rem Set the path to YOUR OWN game executable here (not included in this repo):
if "%GAME_EXE%"=="" set "GAME_EXE=E:\GTA6.Xbox.v1.0.2.1\game_scarlett_master.exe"
cd /d "%~dp0"
set "PATH=%PATH%;%USERPROFILE%\.cargo\bin"
set "PRESET=STABLE"
set VICTORY_RELAY=0
set VICTORY_LATE_WAIT=0
set VICTORY_WIDE_BACK=1
set VICTORY_CARD_BUFFERS_MIN_MB=1
set VICTORY_CARD_BUFFERS_MB=1024
set VICTORY_TEXTURE_FRAME_MS=80
set VICTORY_TEXTURE_FRAME_MB=64
echo Building xboxmericavi (first build takes a few minutes)...
cargo build --release -p victory
if errorlevel 1 (echo BUILD FAILED & pause & exit /b 1)
if not exist "%LOCALAPPDATA%\victory" mkdir "%LOCALAPPDATA%\victory"
echo Starting (%PRESET%)... log: %LOCALAPPDATA%\victory\xboxmericavi.log
target\release\victory.exe run "%GAME_EXE%" --execute > "%LOCALAPPDATA%\victory\xboxmericavi.log" 2>&1
echo.
echo Game exited. Log: %LOCALAPPDATA%\victory\xboxmericavi.log
pause
