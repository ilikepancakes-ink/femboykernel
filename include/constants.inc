; System Constants
; Common constants used throughout the kernel

; Memory constants
PAGE_SIZE equ 4096
KERNEL_BASE equ 0x100000

; VGA constants
VGA_BUFFER equ 0xB8000
VGA_WIDTH equ 80
VGA_HEIGHT equ 25

; PCI constants
PCI_CONFIG_ADDRESS equ 0xCF8
PCI_CONFIG_DATA equ 0xCFC

; Interrupt vectors
IRQ_TIMER equ 32
IRQ_KEYBOARD equ 33

; SMART constants
SMART_READ_DATA equ 0xD0
SMART_ENABLE_OPERATIONS equ 0xD8
SMART_RETURN_STATUS equ 0xDA

; CPU MSR constants
MSR_IA32_THERM_STATUS equ 0x19C
MSR_IA32_TEMPERATURE_TARGET equ 0x1A2

; Error codes
E_OK equ 0
E_NOMEM equ 1
E_INVAL equ 2
E_IO equ 3
E_NOTFOUND equ 4
