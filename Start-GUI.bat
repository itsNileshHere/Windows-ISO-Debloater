@echo off
title Windows ISO Debloater - GUI Launcher
cd /d "%~dp0"
start "" PowerShell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0GUI-Launcher.ps1"
exit
