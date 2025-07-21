; Interrupt Handlers
; Timer, keyboard, and exception handlers

[BITS 64]

extern vga_print
extern vga_println
extern vga_print_char
extern vga_newline
extern vga_clear
extern kernel_panic

section .text

global timer_handler
global keyboard_handler
global page_fault_handler
global general_protection_fault_handler
global init_keyboard
global init_pic

; Initialize keyboard
init_keyboard:
    push rbp
    mov rbp, rsp
    push rax
    
    ; Initialize PIC (Programmable Interrupt Controller)
    call init_pic
    
    ; Enable keyboard interrupt (IRQ1)
    in al, 0x21             ; Read current mask
    and al, 0xFD            ; Clear bit 1 (keyboard)
    out 0x21, al            ; Write back
    
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Initialize PIC
init_pic:
    push rbp
    mov rbp, rsp
    push rax
    
    ; Initialize master PIC
    mov al, 0x11            ; ICW1: Initialize + ICW4 needed
    out 0x20, al
    
    mov al, 0x20            ; ICW2: Master PIC vector offset (32)
    out 0x21, al
    
    mov al, 0x04            ; ICW3: Slave PIC on IRQ2
    out 0x21, al
    
    mov al, 0x01            ; ICW4: 8086 mode
    out 0x21, al
    
    ; Initialize slave PIC
    mov al, 0x11            ; ICW1: Initialize + ICW4 needed
    out 0xA0, al
    
    mov al, 0x28            ; ICW2: Slave PIC vector offset (40)
    out 0xA1, al
    
    mov al, 0x02            ; ICW3: Slave ID
    out 0xA1, al
    
    mov al, 0x01            ; ICW4: 8086 mode
    out 0xA1, al
    
    ; Mask all interrupts initially
    mov al, 0xFF
    out 0x21, al            ; Master PIC
    out 0xA1, al            ; Slave PIC
    
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Timer interrupt handler (IRQ0)
timer_handler:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
    
    ; Increment timer tick count
    inc qword [timer_ticks]
    
    ; Send EOI to PIC
    mov al, 0x20
    out 0x20, al
    
    ; Restore registers
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    
    iretq

; Keyboard interrupt handler (IRQ1)
keyboard_handler:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
    
    ; Read scancode from keyboard
    in al, 0x60
    
    ; Store scancode in buffer
    mov rbx, qword [kbd_buffer_write]
    mov [kbd_buffer + rbx], al
    inc rbx
    and rbx, KBD_BUFFER_SIZE - 1   ; Wrap around
    mov qword [kbd_buffer_write], rbx
    
    ; Convert scancode to ASCII (simplified)
    call scancode_to_ascii
    
    ; Store ASCII character if valid
    cmp al, 0
    je .no_ascii
    
    mov rbx, qword [ascii_buffer_write]
    mov [ascii_buffer + rbx], al
    inc rbx
    and rbx, ASCII_BUFFER_SIZE - 1
    mov qword [ascii_buffer_write], rbx
    
.no_ascii:
    ; Send EOI to PIC
    mov al, 0x20
    out 0x20, al
    
    ; Restore registers
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    
    iretq

; Convert scancode to ASCII
; Input: AL = scancode
; Output: AL = ASCII character (0 if no conversion)
scancode_to_ascii:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    
    ; Check if key release (bit 7 set)
    test al, 0x80
    jnz .key_release
    
    ; Key press - look up in scancode table
    mov rbx, rax
    and rbx, 0x7F           ; Remove release bit
    cmp rbx, SCANCODE_TABLE_SIZE
    jge .no_conversion
    
    mov al, [scancode_table + rbx]
    jmp .done
    
.key_release:
    ; Handle key releases if needed
    xor al, al              ; No ASCII for key release
    jmp .done
    
.no_conversion:
    xor al, al              ; No conversion available
    
.done:
    pop rcx
    pop rbx
    mov rsp, rbp
    pop rbp
    ret

; Page fault handler
page_fault_handler:
    push rax
    push rbx
    push rcx
    push rdx
    
    ; Get faulting address from CR2
    mov rax, cr2
    
    ; Get error code from stack
    mov rbx, [rsp + 32]     ; Error code is pushed by CPU
    
    ; Print page fault information
    mov rdi, page_fault_msg
    call vga_println
    
    mov rdi, fault_addr_msg
    call vga_print
    call print_hex_qword
    call vga_newline
    
    mov rdi, error_code_msg
    call vga_print
    mov rax, rbx
    call print_hex_qword
    call vga_newline
    
    ; Analyze error code
    test rbx, 1
    jz .not_present
    mov rdi, protection_violation_msg
    call vga_println
    jmp .analyze_done
    
.not_present:
    mov rdi, page_not_present_msg
    call vga_println
    
.analyze_done:
    test rbx, 2
    jz .read_fault
    mov rdi, write_fault_msg
    call vga_println
    jmp .rw_done
    
.read_fault:
    mov rdi, read_fault_msg
    call vga_println
    
.rw_done:
    test rbx, 4
    jz .kernel_fault
    mov rdi, user_fault_msg
    call vga_println
    jmp .user_done
    
.kernel_fault:
    mov rdi, kernel_fault_msg
    call vga_println
    
.user_done:
    ; Panic - we can't recover from page faults yet
    mov rdi, page_fault_panic_msg
    call kernel_panic

; General protection fault handler
general_protection_fault_handler:
    push rax
    push rbx
    
    ; Get error code
    mov rax, [rsp + 16]     ; Error code
    
    mov rdi, gpf_msg
    call vga_println
    
    mov rdi, error_code_msg
    call vga_print
    call print_hex_qword
    call vga_newline
    
    ; Panic
    mov rdi, gpf_panic_msg
    call kernel_panic

; Print 64-bit hex value
print_hex_qword:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    
    mov rdi, hex_prefix
    call vga_print
    
    mov rcx, 16
.digit_loop:
    rol rax, 4
    mov rbx, rax
    and rbx, 0xF
    
    cmp rbx, 10
    jl .digit
    add rbx, 'A' - 10
    jmp .print_digit
    
.digit:
    add rbx, '0'
    
.print_digit:
    push rax
    mov al, bl
    call vga_print_char
    pop rax
    
    loop .digit_loop
    
    pop rcx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

section .data

; Interrupt messages
page_fault_msg db 'PAGE FAULT!', 0
fault_addr_msg db 'Faulting address: ', 0
error_code_msg db 'Error code: ', 0
protection_violation_msg db 'Protection violation', 0
page_not_present_msg db 'Page not present', 0
write_fault_msg db 'Write fault', 0
read_fault_msg db 'Read fault', 0
user_fault_msg db 'User mode fault', 0
kernel_fault_msg db 'Kernel mode fault', 0
page_fault_panic_msg db 'Unhandled page fault', 0

gpf_msg db 'GENERAL PROTECTION FAULT!', 0
gpf_panic_msg db 'Unhandled general protection fault', 0

hex_prefix db '0x', 0

; Scancode to ASCII translation table (US QWERTY)
scancode_table:
    db 0, 27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 8, 9
    db 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', 13, 0
    db 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', "'", '`', 0, '\'
    db 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0, '*', 0, ' '
    ; Add more scancodes as needed...

SCANCODE_TABLE_SIZE equ $ - scancode_table

section .bss

; Timer
timer_ticks resq 1

; Keyboard buffers
KBD_BUFFER_SIZE equ 256
ASCII_BUFFER_SIZE equ 256

kbd_buffer resb KBD_BUFFER_SIZE
kbd_buffer_read resq 1
kbd_buffer_write resq 1

ascii_buffer resb ASCII_BUFFER_SIZE
ascii_buffer_read resq 1
ascii_buffer_write resq 1
