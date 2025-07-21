; Useful Macros
; Common assembly macros for the kernel

; Save all general-purpose registers
%macro SAVE_REGS 0
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
%endmacro

; Restore all general-purpose registers
%macro RESTORE_REGS 0
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
%endmacro

; Print a string literal
%macro PRINT_STRING 1
    mov rdi, %1
    call vga_println
%endmacro

; Print a character
%macro PRINT_CHAR 1
    mov al, %1
    call vga_print_char
%endmacro

; Halt with error message
%macro PANIC 1
    mov rdi, %1
    call kernel_panic
%endmacro

; I/O port operations
%macro OUTB 2
    mov al, %2
    mov dx, %1
    out dx, al
%endmacro

%macro INB 1
    mov dx, %1
    in al, dx
%endmacro

%macro OUTW 2
    mov ax, %2
    mov dx, %1
    out dx, ax
%endmacro

%macro INW 1
    mov dx, %1
    in ax, dx
%endmacro

%macro OUTD 2
    mov eax, %2
    mov dx, %1
    out dx, eax
%endmacro

%macro IND 1
    mov dx, %1
    in eax, dx
%endmacro
