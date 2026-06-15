@echo off
REM Autotask AI Skills Installer - Windows Batch Launcher
REM This launches the PowerShell installer script

echo.
echo Autotask AI Skills Installer
echo ============================
echo.

REM Check if PowerShell is available
where powershell.exe >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: PowerShell is required but not found.
    echo Please install PowerShell or run install.ps1 directly.
    pause
    exit /b 1
)

REM Pass all arguments to PowerShell script
powershell.exe -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*

pause
