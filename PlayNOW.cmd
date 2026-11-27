@echo off
rem PlayNOW: start the game right away, no build (the exe from the last PLAY / xboxmericavi.cmd).
rem The game path is the one the launcher remembers, else xboxmericavi.cmd's default.
setlocal
cd /d "%~dp0"
if not exist "target\release\victory.exe" (echo No build yet: run xboxmericavi.cmd or the launcher's PLAY once. & pause & exit /b 1)
set "CFG=%LOCALAPPDATA%\victory\xboxmericavi-launcher.json"
if "%GAME_EXE%"=="" if exist "%CFG%" for /f "usebackq delims=" %%E in (`powershell -NoProfile -Command "(Get-Content -Raw '%CFG%' | ConvertFrom-Json).exe"`) do set "GAME_EXE=%%E"
set XM_NOBUILD=1
call "%~dp0xboxmericavi.cmd"
