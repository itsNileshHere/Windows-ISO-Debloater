@echo off
title Windows ISO Debloater
color 0B
cd /d "%~dp0"

echo.
echo  ============================================================
echo   _       ___           __                   _________ ____  
echo  ^| ^|     / (_)___  ____/ /___ _      _______/  _/ ___// __ \ 
echo  ^| ^| /^| / / / __ \/ __  / __ \ ^| /^| / / ___/ / / \__ \/ / / / 
echo  ^| ^|/ ^|/ / / / / / /_/ / /_/ / ^|/ ^|/ (__  )_/ / ___/ / /_/ /  
echo  ^|__/^|__/_/_/ /_/\__,_/\____/^|__/^|__/____//___//____/\____/   
echo.
echo                    ISO DEBLOATER
echo  ============================================================
echo.
echo  [1] Launch GUI (Graphical Interface)
echo  [2] Launch Script (Interactive CLI)
echo  [3] Launch Script (All Defaults - No Prompts)
echo  [4] Dry Run (Preview Only)
echo  [5] Debug Mode (Shows Errors)
echo  [6] Exit
echo.
echo  ============================================================
echo.

set /p choice="  Select option (1-6): "

if "%choice%"=="1" goto GUI
if "%choice%"=="2" goto CLI
if "%choice%"=="3" goto DEFAULTS
if "%choice%"=="4" goto DRYRUN
if "%choice%"=="5" goto DEBUG
if "%choice%"=="6" exit

echo  Invalid choice. Press any key to try again...
pause >nul
goto :eof

:GUI
echo.
echo  Starting GUI...
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0GUI-Launcher.ps1"
goto END

:CLI
echo.
echo  Starting interactive script...
echo  (Requires Administrator privileges)
echo.
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -NoExit -File \"%~dp0isoDebloaterScript.ps1\"' -Verb RunAs"
goto END

:DEFAULTS
echo.
echo  Starting with all defaults (no prompts)...
echo  You will be asked to select an ISO file.
echo.
set /p isofile="  Enter ISO file path: "
set /p edition="  Enter edition (e.g. Windows 11 Pro): "
set /p outname="  Enter output ISO name (no extension): "
echo.
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -NoExit -File \"%~dp0isoDebloaterScript.ps1\" -noPrompt -isoPath \"%isofile%\" -winEdition \"%edition%\" -outputISO \"%outname%\" -profile minimal' -Verb RunAs"
goto END

:DRYRUN
echo.
echo  Starting dry run (preview mode)...
echo.
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -NoExit -File \"%~dp0isoDebloaterScript.ps1\" -dryRun' -Verb RunAs"
goto END

:DEBUG
echo.
echo  Starting in debug mode (window stays open on error)...
echo.
PowerShell -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0isoDebloaterScript.ps1"
goto END

:END
echo.
echo  Done. Press any key to exit...
pause >nul
