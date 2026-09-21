@echo off
REM Double-click me. Wraps the PowerShell script so Windows' execution policy
REM doesn't block it.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0START-HERE.ps1" %*
echo.
pause
