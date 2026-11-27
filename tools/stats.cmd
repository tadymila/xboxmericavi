@echo off
rem Live fps / frame-time graph from the running game's log.
rem Usage: tools\stats.cmd [log name], default xboxmericavi.log
set "LOG=%~1"
if "%LOG%"=="" set "LOG=xboxmericavi.log"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0stats.ps1" -Log "%LOG%"
