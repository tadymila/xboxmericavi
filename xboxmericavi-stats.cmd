@echo off
rem Live fps / frame-time graph from the running game's log.
rem Usage: xboxmericavi-stats.cmd [log name], default xboxmericavi-turbo.log
set "LOG=%~1"
if "%LOG%"=="" set "LOG=xboxmericavi-turbo.log"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\stats.ps1" -Log "%LOG%"
