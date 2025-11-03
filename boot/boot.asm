; FemboyKernel Bootloader
; Transitions from 16-bit real mode to 32-bit protected mode
; and loads the kernel

[BITS 16]
[ORG 0x7C00]

start:
    ; Clear interrupts and set up stack
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    
    ; Clear screen and print boot message
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    
    mov si, boot_msg
    call print_string
    
    ; Load kernel from disk (simplified - loads 64 sectors)
    mov si, loading_msg
    call print_string

    mov ah, 0x02        ; Read sectors
    mov al, 20          ; Number of sectors to read (10KB should be enough)
    mov ch, 0           ; Cylinder
    mov cl, 2           ; Starting sector (sector 1 is boot sector)
    mov dh, 0           ; Head
    mov dl, 0x00        ; Drive (first floppy disk)
    mov bx, 0x8000      ; Load kernel at 0x8000 (32KB)
    int 0x13
    jc disk_error
    
    ; Check for long mode support
    call check_long_mode
    mov si, mode_msg
    call print_string

    ; Enable A20 line
    call enable_a20

    ; Load GDT
    lgdt [gdt_descriptor]
    
    ; Enter protected mode
    mov si, mode_msg
    call print_string
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; Jump to 32-bit code
    jmp 0x08:protected_mode

disk_error:
    mov si, disk_error_msg
    call print_string
    hlt

; Print string function (16-bit)
print_string:
    mov ah, 0x0E
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    ret

; Check for long mode support
check_long_mode:
    ; Check if CPUID is supported
    pushfd
    pop eax
    mov ecx, eax
    xor eax, 1 << 21
    push eax
    popfd
    pushfd
    pop eax
    push ecx
    popfd
    cmp eax, ecx
    je no_long_mode
    
    ; Check for extended CPUID
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    jb no_long_mode
    
    ; Check for long mode
    mov eax, 0x80000001
    cpuid
    test edx, 1 << 29
    jz no_long_mode
    ret

no_long_mode:
    mov si, no_long_mode_msg
    call print_string
    hlt

; Enable A20 line
enable_a20:
    ; Try BIOS method first
    mov ax, 0x2401
    int 0x15
    ret

; Messages
boot_msg db 'FemboyOS v0.0.1', 13, 10, 0
loading_msg db 'Loading...', 13, 10, 0
mode_msg db 'Mode OK', 13, 10, 0
disk_error_msg db 'Disk error!', 13, 10, 0
no_long_mode_msg db 'No 64-bit!', 13, 10, 0

; GDT
gdt_start:
    ; Null descriptor
    dq 0

gdt_code:
    ; Code segment descriptor
    dw 0xFFFF       ; Limit low
    dw 0x0000       ; Base low
    db 0x00         ; Base middle
    db 10011010b    ; Access byte
    db 11001111b    ; Granularity
    db 0x00         ; Base high

gdt_data:
    ; Data segment descriptor
    dw 0xFFFF       ; Limit low
    dw 0x0000       ; Base low
    db 0x00         ; Base middle
    db 10010010b    ; Access byte
    db 11001111b    ; Granularity
    db 0x00         ; Base high

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

; Constants
CODE_SEG equ 0x08
DATA_SEG equ 0x10

[BITS 32]
protected_mode:
    ; Set up segments
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; Write success marker
    mov word [0xB8000 + 160], 0x0F33  ; '3' - reached 32-bit

    ; Jump to kernel at 0x8000
    jmp 0x8000

setup_page_tables:
    ; Clear page tables
    mov edi, 0x70000
    mov ecx, 0x10000 / 4
    xor eax, eax
    rep stosd

    ; Set up page tables (identity mapping first 2MB)
    mov edi, 0x70000        ; PML4
    mov dword [edi], 0x71003 ; Point to PDPT

    mov edi, 0x71000        ; PDPT
    mov dword [edi], 0x72003 ; Point to PD

    mov edi, 0x72000        ; PD
    mov dword [edi], 0x73003 ; Point to PT

    mov edi, 0x73000        ; PT
    mov eax, 0x003          ; Present, writable
    mov ecx, 512
.loop:
    stosd
    add eax, 0x1000
    loop .loop
    ret

; 64-bit GDT
gdt64_start:
    dq 0                    ; Null descriptor

gdt64_code:
    dq 0x00AF9A000000FFFF   ; 64-bit code segment

gdt64_data:
    dq 0x00CF92000000FFFF   ; 64-bit data segment

gdt64_end:

gdt64_descriptor:
    dw gdt64_end - gdt64_start - 1
    dd gdt64_start

CODE64_SEG equ 0x08
DATA64_SEG equ 0x10





[BITS 64]
long_mode:
    ; 64-bit segments are ignored except FS/GS

    ; Jump to kernel at 0x8000
    jmp 0x8000

; Pad to 510 bytes and add boot signature
times 510-($-$$) db 0
dw 0xAA55
