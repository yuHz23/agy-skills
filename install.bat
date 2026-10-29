@echo off
setlocal

echo AGY-SKILLS global installer
echo This installs settings for the current Windows user. Administrator access is not needed.
echo.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
set "INSTALL_EXIT=%ERRORLEVEL%"

if not "%INSTALL_EXIT%"=="0" (
    echo.
    echo Installation stopped with exit code %INSTALL_EXIT%.
) else (
    echo.
    echo Installation complete. Restart Antigravity CLI.
)

echo.
pause
exit /b %INSTALL_EXIT%
