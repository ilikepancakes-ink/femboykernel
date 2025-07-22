# FemboyOS 

A OS written from scratch in assembly language with advanced hardware management and diagnostic capabilities.

## Project Structure

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

## Building

```bash
make all
```

## Running

Use QEMU to test the kernel:
```bash
make run
```

## Features

### Core System
- [x] Basic project structure
- [ ] Bootloader (16-bit -> 32-bit -> 64-bit transition)
- [ ] Kernel entry point with proper initialization
- [ ] GDT/IDT setup for x64 mode
- [ ] Memory management with paging
- [ ] Interrupt handling system

### Hardware Management
- [ ] PCI bus enumeration and device discovery
- [ ] AHCI/SATA controller driver
- [ ] Disk enumeration and identification
- [ ] SMART monitoring and health checks
- [ ] CPU information via CPUID
- [ ] Thermal monitoring (CPU temperature)

### Diagnostic Functions
- [ ] Comprehensive RAM testing with multiple patterns
- [ ] Storage device health monitoring
- [ ] Hardware inventory and reporting
- [ ] Performance monitoring
- [ ] Error detection and logging

### User Interface
- [ ] VGA text output system
- [ ] Command-line interface
- [ ] Interactive diagnostic menu
- [ ] Real-time status display

## Commands

Once booted, the kernel provides these diagnostic commands:
- `disks` - List all storage devices
- `smart <device>` - Show SMART data for device
- `ramtest` - Run comprehensive RAM tests
- `cpuinfo` - Display CPU information
- `thermal` - Show CPU temperature
- `pci` - List PCI devices
- `meminfo` - Display memory information
- `help` - Show all commands

## Requirements

- NASM assembler
- GNU ld linker
- QEMU (for testing)
- Make
