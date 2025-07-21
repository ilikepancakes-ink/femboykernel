# FemboyKernel Build Script for Windows PowerShell

Write-Host "Building FemboyKernel..." -ForegroundColor Green

# Create build directory
if (!(Test-Path "build")) {
    New-Item -ItemType Directory -Path "build" | Out-Null
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

# Check for required tools
$tools = @("nasm", "ld")
$missing = @()

foreach ($tool in $tools) {
    if (!(Test-Command $tool)) {
        $missing += $tool
    }
}

if ($missing.Count -gt 0) {
    Write-Host "Missing required tools: $($missing -join ', ')" -ForegroundColor Red
    Write-Host "Please install NASM and MinGW-w64. See WINDOWS_SETUP.md for instructions." -ForegroundColor Yellow
    exit 1
}

try {
    Write-Host "Assembling bootloader..." -ForegroundColor Cyan
    & nasm -f bin -o build\boot.bin boot\boot.asm
    if ($LASTEXITCODE -ne 0) { throw "Bootloader assembly failed" }

    Write-Host "Assembling kernel modules..." -ForegroundColor Cyan
    
    $kernelSources = @(
        "kernel\main.asm",
        "kernel\memory.asm", 
        "kernel\interrupts.asm",
        "kernel\pci.asm",
        "kernel\ramtest.asm",
        "kernel\cpu.asm",
        "kernel\cli.asm",
        "kernel\ahci.asm"
    )
    
    foreach ($source in $kernelSources) {
        $basename = [System.IO.Path]::GetFileNameWithoutExtension($source)
        Write-Host "  - $basename.asm" -ForegroundColor Gray
        & nasm -f elf64 -o "build\$basename.o" $source
        if ($LASTEXITCODE -ne 0) { throw "Failed to assemble $source" }
    }

    Write-Host "Assembling drivers..." -ForegroundColor Cyan
    & nasm -f elf64 -o build\vga.o drivers\vga.asm
    if ($LASTEXITCODE -ne 0) { throw "VGA driver assembly failed" }

    & nasm -f elf64 -o build\gdt.o boot\gdt.asm
    if ($LASTEXITCODE -ne 0) { throw "GDT assembly failed" }

    Write-Host "Linking kernel..." -ForegroundColor Cyan
    $objects = @(
        "build\main.o",
        "build\memory.o",
        "build\interrupts.o", 
        "build\pci.o",
        "build\ramtest.o",
        "build\cpu.o",
        "build\cli.o",
        "build\ahci.o",
        "build\vga.o",
        "build\gdt.o"
    )
    
    & ld -T scripts\kernel.ld -o build\kernel.bin $objects
    if ($LASTEXITCODE -ne 0) { throw "Kernel linking failed" }

    Write-Host "Creating disk image..." -ForegroundColor Cyan
    # Create 1.44MB floppy image
    $imageSize = 1474560
    $image = New-Object byte[] $imageSize
    [System.IO.File]::WriteAllBytes("build\femboykernel.img", $image)

    Write-Host ""
    Write-Host "Build completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To create the final bootable image, you need to copy the boot sector and kernel:" -ForegroundColor Yellow
    Write-Host "If you have WSL or MSYS2 with dd command:" -ForegroundColor Gray
    Write-Host "  dd if=build/boot.bin of=build/femboykernel.img bs=512 count=1 conv=notrunc" -ForegroundColor Gray
    Write-Host "  dd if=build/kernel.bin of=build/femboykernel.img bs=512 seek=1 conv=notrunc" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To run with QEMU:" -ForegroundColor Yellow
    Write-Host "  qemu-system-x86_64 -drive format=raw,file=build/femboykernel.img -m 128M" -ForegroundColor Gray
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "Build failed: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Make sure you have installed:" -ForegroundColor Yellow
    Write-Host "- NASM assembler" -ForegroundColor Gray
    Write-Host "- MinGW-w64 (for ld linker)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "See WINDOWS_SETUP.md for installation instructions." -ForegroundColor Yellow
    exit 1
}
