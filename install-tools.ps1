# FemboyKernel Tools Installer for Windows
# This script helps install the required build tools

param(
    [switch]$UseChocolatey,
    [switch]$UseWinget,
    [switch]$Manual
)

Write-Host "FemboyKernel Build Tools Installer" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green
Write-Host ""

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to check if command exists
function Test-Command($command) {
    try {
        Get-Command $command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

if ($UseChocolatey) {
    Write-Host "Installing tools via Chocolatey..." -ForegroundColor Cyan
    
    if (!(Test-Command "choco")) {
        Write-Host "Chocolatey not found. Installing Chocolatey first..." -ForegroundColor Yellow
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }
    
    Write-Host "Installing NASM..." -ForegroundColor Gray
    choco install nasm -y
    
    Write-Host "Installing MinGW..." -ForegroundColor Gray
    choco install mingw -y
    
    Write-Host "Installing QEMU..." -ForegroundColor Gray
    choco install qemu -y
    
} elseif ($UseWinget) {
    Write-Host "Installing tools via winget..." -ForegroundColor Cyan
    
    if (!(Test-Command "winget")) {
        Write-Host "winget not found. Please install App Installer from Microsoft Store." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Installing NASM..." -ForegroundColor Gray
    winget install NASM.NASM
    
    Write-Host "Installing MSYS2 (includes MinGW)..." -ForegroundColor Gray
    winget install MSYS2.MSYS2
    
    Write-Host "Installing QEMU..." -ForegroundColor Gray
    winget install SoftwareFreedomConservancy.QEMU
    
} elseif ($Manual) {
    Write-Host "Manual installation instructions:" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "1. NASM Assembler:" -ForegroundColor Yellow
    Write-Host "   Download from: https://www.nasm.us/pub/nasm/releasebuilds/" -ForegroundColor Gray
    Write-Host "   Get the latest Windows version (e.g., nasm-2.16.01-win64.zip)" -ForegroundColor Gray
    Write-Host "   Extract to C:\nasm and add C:\nasm to your PATH" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "2. MSYS2 (for MinGW and make):" -ForegroundColor Yellow
    Write-Host "   Download from: https://www.msys2.org/" -ForegroundColor Gray
    Write-Host "   Install and then run in MSYS2 terminal:" -ForegroundColor Gray
    Write-Host "     pacman -S mingw-w64-x86_64-toolchain" -ForegroundColor Gray
    Write-Host "     pacman -S make" -ForegroundColor Gray
    Write-Host "   Add C:\msys64\mingw64\bin to your PATH" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "3. QEMU (for testing):" -ForegroundColor Yellow
    Write-Host "   Download from: https://www.qemu.org/download/#windows" -ForegroundColor Gray
    Write-Host "   Install and add to PATH" -ForegroundColor Gray
    Write-Host ""
    
} else {
    Write-Host "Choose an installation method:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Chocolatey (recommended for automated install)" -ForegroundColor Cyan
    Write-Host "   .\install-tools.ps1 -UseChocolatey" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Winget (Windows Package Manager)" -ForegroundColor Cyan
    Write-Host "   .\install-tools.ps1 -UseWinget" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Manual installation" -ForegroundColor Cyan
    Write-Host "   .\install-tools.ps1 -Manual" -ForegroundColor Gray
    Write-Host ""
    exit 0
}

Write-Host ""
Write-Host "Installation completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Restart your command prompt/PowerShell" -ForegroundColor Gray
Write-Host "2. Navigate to the FemboyKernel directory" -ForegroundColor Gray
Write-Host "3. Run: .\build.ps1" -ForegroundColor Gray
Write-Host ""

# Check if tools are available
Write-Host "Checking installed tools..." -ForegroundColor Cyan

$tools = @("nasm", "ld", "qemu-system-x86_64")
foreach ($tool in $tools) {
    if (Test-Command $tool) {
        Write-Host "[OK] $tool found" -ForegroundColor Green
    } else {
        Write-Host "[MISSING] $tool not found (may need to restart terminal)" -ForegroundColor Red
    }
}
