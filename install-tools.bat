@echo off
echo FemboyKernel Build Tools Installer
echo ==================================
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please run as administrator.
    pause
    exit /b 1
)

echo Installing Chocolatey package manager...
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"

if %errorLevel% neq 0 (
    echo Failed to install Chocolatey.
    pause
    exit /b 1
)

echo.
echo Refreshing environment variables...
call refreshenv

echo.
echo Installing NASM assembler...
choco install nasm -y

echo.
echo Installing MinGW (GNU toolchain)...
choco install mingw -y

echo.
echo Installing QEMU (virtual machine)...
choco install qemu -y

echo.
echo Installation completed!
echo.
echo Please restart your command prompt and run:
echo   build.bat
echo.
echo Or to test immediately:
echo   refreshenv
echo   build.bat
echo.
pause
