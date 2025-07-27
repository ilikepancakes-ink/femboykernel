# Compiling FemboyOS/FemboyKernel

## Prerequisites

- QEMU (for testing in virtual environment)
- NASM (for compiling .ASM files)
- GCC (for compiling .C files)
- Make (for compiling using the automatic way)

## Building

There are several ways to build FemboyOS/FemboyKernel:

### Using Make

> [!TIP]
> You can also get information by running `make help`

To only compile FemboyOS/FemboyKernel, run:
```bash
make all
```

to compile FemboyOS/FemboyKernel and run it in QEMU, run:
```bash
make run
```

to compile (using debug) FemboyOS/FemboyKernel, run:
```bash
make debug
```

### Using Toolchain

> [!IMPORTANT]
> Install tools before using toolchain. You can install tools by `install-tools.bat` or `install-tools.ps1`.

To compile and link FemboyOS/FemboyKernel using toolchain, run `build.bat` or `build.ps1`