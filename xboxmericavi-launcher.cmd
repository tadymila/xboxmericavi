@echo off
rem Opens the xboxmericavi launcher window (presets, game path, live stats).
start "" powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0tools\launcher.ps1"
