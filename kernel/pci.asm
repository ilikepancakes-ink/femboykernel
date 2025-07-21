; PCI Bus Enumeration and Device Discovery
; Scans PCI buses and identifies connected devices

[BITS 64]

extern vga_print
extern vga_println
extern vga_print_char
extern vga_newline
extern vga_clear

section .text

; PCI Configuration Space Access
PCI_CONFIG_ADDRESS equ 0xCF8
PCI_CONFIG_DATA equ 0xCFC

global init_pci
global pci_scan_bus
global pci_read_config_dword
global pci_write_config_dword
global pci_get_device_info
global pci_list_devices

; Initialize PCI subsystem
init_pci:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    
    ; Clear device list
    mov rcx, MAX_PCI_DEVICES
    mov rdi, pci_devices
    xor rax, rax
.clear_loop:
    mov [rdi], rax
    add rdi, 8
    loop .clear_loop
    
    ; Reset device count
    mov qword [pci_device_count], 0
    
    ; Scan all PCI buses
    call pci_scan_all_buses
    
    pop rcx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Scan all PCI buses (0-255)
pci_scan_all_buses:
    push rbp
    mov rbp, rsp
    push rax
    
    mov rax, 0              ; Start with bus 0
.bus_loop:
    call pci_scan_bus
    inc rax
    cmp rax, 256
    jl .bus_loop
    
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Scan a single PCI bus
; rax = bus number
pci_scan_bus:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    push rdx
    
    mov rbx, rax            ; Save bus number
    mov rcx, 0              ; Device number
    
.device_loop:
    mov rdx, 0              ; Function number
    
.function_loop:
    ; Check if device exists
    mov rax, rbx            ; Bus
    shl rax, 8
    or rax, rcx             ; Device
    shl rax, 3
    or rax, rdx             ; Function
    
    call pci_read_vendor_id
    cmp rax, 0xFFFF
    je .next_function
    cmp rax, 0x0000
    je .next_function
    
    ; Device exists, add to list
    call pci_add_device
    
.next_function:
    inc rdx
    cmp rdx, 8
    jl .function_loop
    
    inc rcx
    cmp rcx, 32
    jl .device_loop
    
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Read vendor ID for a device
; rax = bus/device/function (BDF)
; Returns vendor ID in rax
pci_read_vendor_id:
    push rbp
    mov rbp, rsp
    push rbx
    
    mov rbx, rax
    mov rax, 0              ; Offset 0 (Vendor ID)
    call pci_read_config_dword
    and rax, 0xFFFF         ; Extract vendor ID
    
    pop rbx
    mov rsp, rbp
    pop rbp
    ret

; Add device to device list
; rbx = bus, rcx = device, rdx = function
pci_add_device:
    push rbp
    mov rbp, rsp
    push rax
    push rdi
    push rsi
    
    ; Check if we have space
    mov rax, qword [pci_device_count]
    cmp rax, MAX_PCI_DEVICES
    jge .no_space
    
    ; Calculate device entry address
    mov rdi, rax
    shl rdi, 5              ; Each entry is 32 bytes
    add rdi, pci_devices
    
    ; Store BDF
    mov rax, rbx
    shl rax, 8
    or rax, rcx
    shl rax, 3
    or rax, rdx
    mov [rdi], rax          ; BDF at offset 0
    
    ; Read and store vendor/device ID
    mov rax, 0
    call pci_read_config_dword
    mov [rdi + 8], rax      ; Vendor/Device ID at offset 8
    
    ; Read and store class/subclass
    mov rax, 8              ; Offset 8 (Class/Subclass)
    call pci_read_config_dword
    mov [rdi + 16], rax     ; Class info at offset 16
    
    ; Read and store header type
    mov rax, 12             ; Offset 12 (Header type)
    call pci_read_config_dword
    mov [rdi + 24], rax     ; Header type at offset 24
    
    ; Increment device count
    inc qword [pci_device_count]
    
.no_space:
    pop rsi
    pop rdi
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Read PCI configuration dword
; rbx = bus, rcx = device, rdx = function, rax = offset
; Returns value in rax
pci_read_config_dword:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    push rdx
    
    ; Build configuration address
    ; Bit 31: Enable bit
    ; Bits 23-16: Bus number
    ; Bits 15-11: Device number
    ; Bits 10-8: Function number
    ; Bits 7-2: Register offset
    ; Bits 1-0: Always 00
    
    push rax                ; Save offset
    
    mov rax, 1
    shl rax, 31             ; Enable bit
    
    shl rbx, 16             ; Bus number
    or rax, rbx
    
    shl rcx, 11             ; Device number
    or rax, rcx
    
    shl rdx, 8              ; Function number
    or rax, rdx
    
    pop rbx                 ; Restore offset
    and rbx, 0xFC           ; Align to dword
    or rax, rbx
    
    ; Write address to CONFIG_ADDRESS
    mov dx, PCI_CONFIG_ADDRESS
    out dx, eax
    
    ; Read data from CONFIG_DATA
    mov dx, PCI_CONFIG_DATA
    in eax, dx
    
    pop rdx
    pop rcx
    pop rbx
    mov rsp, rbp
    pop rbp
    ret

; Write PCI configuration dword
; rbx = bus, rcx = device, rdx = function, rax = offset, rsi = value
pci_write_config_dword:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    push rdx
    
    ; Build configuration address (same as read)
    push rax                ; Save offset
    push rsi                ; Save value
    
    mov rax, 1
    shl rax, 31             ; Enable bit
    
    shl rbx, 16             ; Bus number
    or rax, rbx
    
    shl rcx, 11             ; Device number
    or rax, rcx
    
    shl rdx, 8              ; Function number
    or rax, rdx
    
    pop rsi                 ; Restore value
    pop rbx                 ; Restore offset
    and rbx, 0xFC           ; Align to dword
    or rax, rbx
    
    ; Write address to CONFIG_ADDRESS
    mov dx, PCI_CONFIG_ADDRESS
    out dx, eax
    
    ; Write data to CONFIG_DATA
    mov dx, PCI_CONFIG_DATA
    mov eax, esi
    out dx, eax
    
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; List all discovered PCI devices
pci_list_devices:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    push rdi
    
    mov rdi, pci_header_msg
    call vga_println
    
    mov rax, qword [pci_device_count]
    cmp rax, 0
    je .no_devices
    
    mov rcx, 0              ; Device index
    
.device_loop:
    ; Calculate device entry address
    mov rdi, rcx
    shl rdi, 5              ; Each entry is 32 bytes
    add rdi, pci_devices
    
    ; Print device info
    call print_device_info
    
    inc rcx
    cmp rcx, qword [pci_device_count]
    jl .device_loop
    
    jmp .done
    
.no_devices:
    mov rdi, no_devices_msg
    call vga_println
    
.done:
    pop rdi
    pop rcx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Print device information
; rdi = device entry pointer
print_device_info:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    
    ; Extract BDF
    mov rax, [rdi]          ; BDF
    mov rbx, rax
    and rbx, 0x7            ; Function
    shr rax, 3
    mov rcx, rax
    and rcx, 0x1F           ; Device
    shr rax, 5              ; Bus
    
    ; Print BDF
    call print_hex_byte     ; Bus
    mov al, ':'
    call vga_print_char
    mov rax, rcx
    call print_hex_byte     ; Device
    mov al, '.'
    call vga_print_char
    mov rax, rbx
    call print_hex_byte     ; Function
    
    mov rdi, separator_msg
    call vga_print
    
    ; Print vendor/device ID
    mov rax, [rdi + 8]      ; Vendor/Device ID
    mov rbx, rax
    and rax, 0xFFFF         ; Vendor ID
    call print_hex_word
    mov al, ':'
    call vga_print_char
    shr rbx, 16             ; Device ID
    mov rax, rbx
    call print_hex_word
    
    mov rdi, separator_msg
    call vga_print
    
    ; Print class code
    mov rax, [rdi + 16]     ; Class info
    shr rax, 24             ; Class code
    call print_hex_byte
    
    call vga_newline
    
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Print hex byte (AL)
print_hex_byte:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    
    mov rbx, rax
    shr rax, 4
    and rax, 0xF
    call print_hex_digit
    
    mov rax, rbx
    and rax, 0xF
    call print_hex_digit
    
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Print hex word (AX)
print_hex_word:
    push rbp
    mov rbp, rsp
    push rax
    
    mov al, ah
    call print_hex_byte
    pop rax
    call print_hex_byte
    
    mov rsp, rbp
    pop rbp
    ret

; Print hex digit (AL = 0-15)
print_hex_digit:
    push rbp
    mov rbp, rsp
    
    cmp al, 10
    jl .digit
    add al, 'A' - 10
    jmp .print
.digit:
    add al, '0'
.print:
    call vga_print_char
    
    mov rsp, rbp
    pop rbp
    ret

section .data

pci_header_msg db 'PCI Devices:', 0
no_devices_msg db 'No PCI devices found.', 0
separator_msg db ' - ', 0

section .bss

; PCI device storage
MAX_PCI_DEVICES equ 256

; Device entry structure (32 bytes each):
; Offset 0: BDF (Bus/Device/Function)
; Offset 8: Vendor/Device ID
; Offset 16: Class/Subclass/Prog IF/Revision
; Offset 24: Header Type/BIST/Latency Timer/Cache Line Size
pci_devices:
    resb MAX_PCI_DEVICES * 32

pci_device_count:
    resq 1
