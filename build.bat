@echo off
echo Building FemboyKernel...

REM Create build directory
if not exist build mkdir build

echo Assembling bootloader...
nasm -f bin -o build\boot.bin boot\boot.asm
if errorlevel 1 goto error

echo Assembling kernel modules...
nasm -f elf64 -o build\main.o kernel\main.asm
if errorlevel 1 goto error

nasm -f elf64 -o build\memory.o kernel\memory.asm
if errorlevel 1 goto error

nasm -f elf64 -o build\interrupts.o kernel\interrupts.asm
if errorlevel 1 goto error

nasm -f elf64 -o build\pci.o kernel\pci.asm
if errorlevel 1 goto error

nasm -f elf64 -o build\ramtest.o kernel\ramtest.asm
if errorlevel 1 goto error

nasm -f elf64 -o build\cpu.o kernel\cpu.asm
if errorlevel 1 goto error

nasm -f elf64 -o build\cli.o kernel\cli.asm
if errorlevel 1 goto error

nasm -f elf64 -o build\ahci.o kernel\ahci.asm
if errorlevel 1 goto error

echo Assembling drivers...
nasm -f elf64 -o build\vga.o drivers\vga.asm
if errorlevel 1 goto error

nasm -f elf64 -o build\gdt.o boot\gdt.asm
if errorlevel 1 goto error

echo Linking kernel...
ld -T kernel\linker.ld -o build\kernel.bin build\main.o build\memory.o build\interrupts.o build\pci.o build\ramtest.o build\cpu.o build\cli.o build\ahci.o build\vga.o build\gdt.o
if errorlevel 1 goto error

echo Creating disk image...
REM Create 1.44MB floppy image
fsutil file createnew build\femboykernel.img 1474560
if errorlevel 1 goto error

echo.
echo Build completed successfully!
echo.
echo To create the final bootable image, you need the 'dd' command.
echo Install MSYS2 or WSL, then run:
echo   dd if=build/boot.bin of=build/femboykernel.img bs=512 count=1 conv=notrunc
echo   dd if=build/kernel.bin of=build/femboykernel.img bs=512 seek=1 conv=notrunc
echo.
echo To run with QEMU:
echo   qemu-system-x86_64 -drive format=raw,file=build/femboykernel.img -m 128M
echo.
goto end

:error
echo.
echo Build failed!
echo.
echo Make sure you have installed:
echo - NASM assembler
echo - MinGW-w64 (for ld linker)
echo.
echo See WINDOWS_SETUP.md for installation instructions.
exit /b 1

:end
