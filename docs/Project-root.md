# FemboyOS/FemboyKernel Project Root

## Introduction

This document is talking about FemboyOS (Operating System) and FemboyKernel (Kernel) source code root. Explaning the structure of FemboyOS/FemboyKernel.

```
femboykernel/
├── boot/           # Bootloader code
│   ├── boot.asm    # Main bootloader
│   └── gdt.asm     # GDT setup
├── kernel/         # Kernel source code
│   ├── main.asm    # Kernel entry point
│   ├── memory.asm  # Memory management
│   ├── interrupts.asm # Interrupt handlers
│   ├── pci.asm     # PCI bus functions
│   ├── ahci.asm    # SATA/AHCI driver
│   ├── smart.asm   # SMART monitoring
│   ├── ramtest.asm # RAM testing functions
│   ├── cpu.asm     # CPU information
│   ├── thermal.asm # Temperature monitoring
│   └── cli.asm     # Command interface
├── drivers/        # Hardware drivers
│   ├── vga.asm     # VGA text output
│   └── keyboard.asm # Keyboard input
├── include/        # Assembly include files
│   ├── constants.inc # System constants
│   ├── macros.inc   # Useful macros
│   └── structs.inc  # Data structures
├── build/          # Build output
└── scripts/        # Build scripts
    ├── Makefile    # Build system
    └── kernel.ld   # Linker script
```