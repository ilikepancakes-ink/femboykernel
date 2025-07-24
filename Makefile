# FemboyKernel Makefile

# Tools
ASM = nasm
CC = /mingw64/bin/gcc
LD = /mingw64/bin/ld.exe
QEMU = qemu-system-x86_64

# Directories
BOOT_DIR = boot
KERNEL_DIR = kernel
DRIVERS_DIR = drivers
INCLUDE_DIR = include
SCRIPTS_DIR = scripts
BUILD_DIR = build
GUI_DIR = gui

# Flags
ASM_FLAGS = -f elf32
CC_FLAGS = -m32 -ffreestanding -fno-stack-protector -fno-builtin -nostdlib -nostdinc -Wall -Wextra
LD_FLAGS = -T $(SCRIPTS_DIR)/kernel.ld

# Source files
BOOT_SOURCES = $(BOOT_DIR)/boot.asm
KERNEL_SOURCES = $(KERNEL_DIR)/main.asm
GUI_ASM_SOURCES = $(GUI_DIR)/gui.asm

# Object files
KERNEL_OBJECTS = $(patsubst %.asm,$(BUILD_DIR)/%.o,$(notdir $(KERNEL_SOURCES)))
GUI_ASM_OBJECTS = $(patsubst %.asm,$(BUILD_DIR)/%.o,$(notdir $(GUI_ASM_SOURCES)))

ALL_OBJECTS = $(KERNEL_OBJECTS) $(GUI_ASM_OBJECTS)

# Targets
.PHONY: all clean run debug

all: $(BUILD_DIR)/femboykernel.img

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Bootloader
$(BUILD_DIR)/boot.bin: $(BOOT_SOURCES) | $(BUILD_DIR)
	$(ASM) -f bin -o $@ $<

# Kernel objects
$(BUILD_DIR)/main.o: $(KERNEL_DIR)/main.asm | $(BUILD_DIR)
	$(ASM) $(ASM_FLAGS) -o $@ $<

$(BUILD_DIR)/memory.o: $(KERNEL_DIR)/memory.asm | $(BUILD_DIR)
	$(ASM) $(ASM_FLAGS) -o $@ $<

$(BUILD_DIR)/interrupts.o: $(KERNEL_DIR)/interrupts.asm | $(BUILD_DIR)
	$(ASM) $(ASM_FLAGS) -o $@ $<

$(BUILD_DIR)/pci.o: $(KERNEL_DIR)/pci.asm | $(BUILD_DIR)
	$(ASM) $(ASM_FLAGS) -o $@ $<

$(BUILD_DIR)/ramtest.o: $(KERNEL_DIR)/ramtest.asm | $(BUILD_DIR)
	$(ASM) $(ASM_FLAGS) -o $@ $<

$(BUILD_DIR)/cpu.o: $(KERNEL_DIR)/cpu.asm | $(BUILD_DIR)
	$(ASM) $(ASM_FLAGS) -o $@ $<

$(BUILD_DIR)/cli.o: $(KERNEL_DIR)/cli.asm | $(BUILD_DIR)
	$(ASM) $(ASM_FLAGS) -o $@ $<

# Driver objects
$(BUILD_DIR)/vga.o: $(DRIVERS_DIR)/vga.asm | $(BUILD_DIR)
	$(ASM) $(ASM_FLAGS) -o $@ $<

# GDT object
$(BUILD_DIR)/gdt.o: $(BOOT_DIR)/gdt.asm | $(BUILD_DIR)
	$(ASM) $(ASM_FLAGS) -o $@ $<

# GUI Assembly objects
$(BUILD_DIR)/gui.o: $(GUI_DIR)/gui.asm | $(BUILD_DIR)
	$(ASM) $(ASM_FLAGS) -o $@ $<

# Create kernel binary (includes GUI)
$(BUILD_DIR)/kernel.bin: $(KERNEL_DIR)/main.asm $(GUI_DIR)/gui.asm | $(BUILD_DIR)
	nasm -f bin -o $@ $<

# Create disk image
$(BUILD_DIR)/femboykernel.img: $(BUILD_DIR)/boot.bin $(BUILD_DIR)/kernel.bin | $(BUILD_DIR)
	# Create 1.44MB floppy image
	dd if=/dev/zero of=$@ bs=512 count=2880 2>/dev/null || dd if=/dev/zero of=$@ bs=512 count=2880
	# Write bootloader to first sector
	dd if=$(BUILD_DIR)/boot.bin of=$@ bs=512 count=1 conv=notrunc 2>/dev/null || dd if=$(BUILD_DIR)/boot.bin of=$@ bs=512 count=1 conv=notrunc
	# Write kernel starting at sector 2
	dd if=$(BUILD_DIR)/kernel.bin of=$@ bs=512 seek=1 conv=notrunc 2>/dev/null || dd if=$(BUILD_DIR)/kernel.bin of=$@ bs=512 seek=1 conv=notrunc

# Run in QEMU
run: $(BUILD_DIR)/femboykernel.img
	$(QEMU) -fda $< -m 128M -boot a

# Debug in QEMU
debug: $(BUILD_DIR)/femboykernel.img
	$(QEMU) -fda $< -m 128M -boot a -s -S

# Run with verbose output
verbose: $(BUILD_DIR)/femboykernel.img
	$(QEMU) -fda $< -m 128M -boot a -d int,cpu_reset

# Clean build files
clean:
	rm -rf $(BUILD_DIR)

# Help
help:
	@echo "FemboyKernel Build System"
	@echo "========================"
	@echo ""
	@echo "Targets:"
	@echo "  all     - Build the complete kernel image"
	@echo "  run     - Build and run in QEMU"
	@echo "  debug   - Build and run in QEMU with GDB server"
	@echo "  clean   - Remove all build files"
	@echo "  help    - Show this help message"
	@echo ""
