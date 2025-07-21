; AHCI/SATA Driver
; Basic SATA controller driver for disk access

[BITS 64]

extern vga_print
extern vga_println
extern vga_print_char
extern vga_newline
extern vga_clear
extern pci_read_config_dword

section .text

; AHCI constants
AHCI_CLASS_CODE equ 0x010601
SATA_SIG_ATA equ 0x00000101
SATA_SIG_ATAPI equ 0xEB140101
SATA_SIG_SEMB equ 0xC33C0101
SATA_SIG_PM equ 0x96690101

; ATA commands
ATA_CMD_READ_DMA equ 0xC8
ATA_CMD_WRITE_DMA equ 0xCA
ATA_CMD_IDENTIFY equ 0xEC
ATA_CMD_SMART equ 0xB0

global init_ahci
global find_ahci_controller
global probe_ahci_ports
global ahci_identify_device
global ahci_read_smart

; Initialize AHCI subsystem
init_ahci:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    
    ; Find AHCI controller
    call find_ahci_controller
    cmp rax, 0
    je .no_controller
    
    ; Store controller info
    mov qword [ahci_controller_bdf], rax
    
    ; Get AHCI base address
    call get_ahci_base
    mov qword [ahci_base], rax
    
    ; Initialize controller
    call init_ahci_controller
    
    ; Probe ports for devices
    call probe_ahci_ports
    
    jmp .done
    
.no_controller:
    mov rdi, no_ahci_msg
    call vga_println
    
.done:
    pop rcx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Find AHCI controller via PCI scan
find_ahci_controller:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    
    ; Scan PCI devices for AHCI controller
    mov rbx, 0              ; Bus
    
.bus_loop:
    mov rcx, 0              ; Device
    
.device_loop:
    mov rdx, 0              ; Function
    
.function_loop:
    ; Read class code
    mov rax, 8              ; Offset 8 (class code)
    call pci_read_config_dword
    shr rax, 8              ; Remove revision ID
    
    cmp rax, AHCI_CLASS_CODE
    je .found_ahci
    
    ; Try next function
    inc rdx
    cmp rdx, 8
    jl .function_loop
    
    ; Try next device
    inc rcx
    cmp rcx, 32
    jl .device_loop
    
    ; Try next bus
    inc rbx
    cmp rbx, 256
    jl .bus_loop
    
    ; Not found
    xor rax, rax
    jmp .done
    
.found_ahci:
    ; Calculate BDF
    mov rax, rbx
    shl rax, 8
    or rax, rcx
    shl rax, 3
    or rax, rdx
    
.done:
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    mov rsp, rbp
    pop rbp
    ret

; Get AHCI base address from PCI config
get_ahci_base:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    push rdx
    
    ; Extract BDF
    mov rax, qword [ahci_controller_bdf]
    mov rbx, rax
    and rbx, 0x7            ; Function
    shr rax, 3
    mov rcx, rax
    and rcx, 0x1F           ; Device
    shr rax, 5              ; Bus
    
    ; Read BAR5 (AHCI base address)
    mov rax, 0x24           ; BAR5 offset
    call pci_read_config_dword
    and rax, 0xFFFFFFF0     ; Clear flags
    
    pop rdx
    pop rcx
    pop rbx
    mov rsp, rbp
    pop rbp
    ret

; Initialize AHCI controller
init_ahci_controller:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rdi
    
    mov rdi, qword [ahci_base]
    
    ; Enable AHCI mode
    mov rax, [rdi + 0x04]   ; GHC register
    or rax, 0x80000000      ; Set AE bit
    mov [rdi + 0x04], rax
    
    ; Reset controller
    or rax, 0x00000001      ; Set HR bit
    mov [rdi + 0x04], rax
    
    ; Wait for reset to complete
.wait_reset:
    mov rax, [rdi + 0x04]
    test rax, 0x00000001
    jnz .wait_reset
    
    ; Re-enable AHCI mode
    mov rax, [rdi + 0x04]
    or rax, 0x80000000
    mov [rdi + 0x04], rax
    
    pop rdi
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Probe AHCI ports for connected devices
probe_ahci_ports:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    push rdi
    
    mov rdi, qword [ahci_base]
    
    ; Read ports implemented register
    mov rax, [rdi + 0x0C]
    mov rbx, rax
    
    ; Check each port
    mov rcx, 0
    
.port_loop:
    test rbx, 1
    jz .next_port
    
    ; Port is implemented, check if device connected
    call check_port_device
    
.next_port:
    shr rbx, 1
    inc rcx
    cmp rcx, 32
    jl .port_loop
    
    pop rdi
    pop rcx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Check if device is connected to port
; rcx = port number
check_port_device:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rdx
    push rdi
    
    mov rdi, qword [ahci_base]
    
    ; Calculate port offset (0x100 + port * 0x80)
    mov rax, rcx
    shl rax, 7              ; port * 128
    add rax, 0x100
    add rdi, rax
    
    ; Read port status
    mov rax, [rdi + 0x28]   ; SSTS register
    and rax, 0x0F           ; DET field
    cmp rax, 0x03           ; Device present and communication established
    jne .no_device
    
    ; Read signature
    mov rax, [rdi + 0x24]   ; SIG register
    
    ; Determine device type
    cmp rax, SATA_SIG_ATA
    je .ata_device
    cmp rax, SATA_SIG_ATAPI
    je .atapi_device
    
    ; Unknown device
    mov rdi, unknown_device_msg
    call vga_print
    jmp .print_port
    
.ata_device:
    mov rdi, ata_device_msg
    call vga_print
    
    ; Store device info
    mov rax, qword [sata_device_count]
    cmp rax, MAX_SATA_DEVICES
    jge .print_port
    
    mov rbx, rax
    shl rbx, 3              ; Each entry is 8 bytes
    add rbx, sata_devices
    mov [rbx], rcx          ; Store port number
    inc qword [sata_device_count]
    
    jmp .print_port
    
.atapi_device:
    mov rdi, atapi_device_msg
    call vga_print
    jmp .print_port
    
.no_device:
    jmp .done
    
.print_port:
    ; Print port number
    mov rax, rcx
    call print_decimal
    call vga_newline
    
.done:
    pop rdi
    pop rdx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Identify ATA device
; rcx = port number
ahci_identify_device:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rdi
    
    ; For now, just print that we're identifying the device
    mov rdi, identify_msg
    call vga_print
    mov rax, rcx
    call print_decimal
    call vga_newline
    
    ; In a full implementation, this would:
    ; 1. Set up command table
    ; 2. Issue IDENTIFY DEVICE command
    ; 3. Parse the returned data
    ; 4. Extract device information (model, serial, capacity, etc.)
    
    pop rdi
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Read SMART data from device
; rcx = port number
ahci_read_smart:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rdi
    
    mov rdi, smart_read_msg
    call vga_print
    mov rax, rcx
    call print_decimal
    call vga_newline
    
    ; In a full implementation, this would:
    ; 1. Check if SMART is supported
    ; 2. Enable SMART if needed
    ; 3. Read SMART attributes
    ; 4. Parse and display health information
    
    pop rdi
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Print decimal number
print_decimal:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    
    cmp rax, 0
    jne .not_zero
    mov al, '0'
    call vga_print_char
    jmp .done
    
.not_zero:
    mov rdi, decimal_buffer + 20
    mov byte [rdi], 0
    dec rdi
    
    mov rbx, 10
    
.convert_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rdi], dl
    dec rdi
    
    cmp rax, 0
    jne .convert_loop
    
    inc rdi
    call vga_print
    
.done:
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

section .data

no_ahci_msg db 'No AHCI controller found', 0
ata_device_msg db 'ATA device found on port ', 0
atapi_device_msg db 'ATAPI device found on port ', 0
unknown_device_msg db 'Unknown device found on port ', 0
identify_msg db 'Identifying device on port ', 0
smart_read_msg db 'Reading SMART data from port ', 0

section .bss

; AHCI controller information
ahci_controller_bdf resq 1
ahci_base resq 1

; SATA device list
MAX_SATA_DEVICES equ 8
sata_devices resq MAX_SATA_DEVICES
sata_device_count resq 1

decimal_buffer resb 21
