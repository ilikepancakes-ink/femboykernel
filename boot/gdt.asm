; Global Descriptor Table and Interrupt Descriptor Table Setup
; 64-bit mode GDT and IDT configuration

[BITS 64]

section .text

global setup_gdt
global setup_idt

; External interrupt handlers
extern keyboard_handler
extern timer_handler
extern page_fault_handler
extern general_protection_fault_handler
extern kernel_panic

; Set up Global Descriptor Table for 64-bit mode
setup_gdt:
    push rbp
    mov rbp, rsp
    
    ; Load the GDT
    lgdt [gdt64_descriptor]
    
    ; Reload segment registers
    mov ax, 0x10        ; Data segment selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Far jump to reload CS
    push 0x08           ; Code segment selector
    lea rax, [.reload_cs]
    push rax
    retfq
    
.reload_cs:
    mov rsp, rbp
    pop rbp
    ret

; Set up Interrupt Descriptor Table
setup_idt:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    push rdx
    
    ; Clear IDT
    mov rdi, idt_table
    mov rcx, 256 * 16   ; 256 entries * 16 bytes each
    xor rax, rax
    rep stosb
    
    ; Set up exception handlers (0-31)
    mov rax, 0
    mov rbx, divide_by_zero_handler
    call set_idt_entry
    
    mov rax, 1
    mov rbx, debug_handler
    call set_idt_entry
    
    mov rax, 2
    mov rbx, nmi_handler
    call set_idt_entry
    
    mov rax, 3
    mov rbx, breakpoint_handler
    call set_idt_entry
    
    mov rax, 4
    mov rbx, overflow_handler
    call set_idt_entry
    
    mov rax, 5
    mov rbx, bound_range_exceeded_handler
    call set_idt_entry
    
    mov rax, 6
    mov rbx, invalid_opcode_handler
    call set_idt_entry
    
    mov rax, 7
    mov rbx, device_not_available_handler
    call set_idt_entry
    
    mov rax, 8
    mov rbx, double_fault_handler
    call set_idt_entry
    
    mov rax, 10
    mov rbx, invalid_tss_handler
    call set_idt_entry
    
    mov rax, 11
    mov rbx, segment_not_present_handler
    call set_idt_entry
    
    mov rax, 12
    mov rbx, stack_segment_fault_handler
    call set_idt_entry
    
    mov rax, 13
    mov rbx, general_protection_fault_handler
    call set_idt_entry
    
    mov rax, 14
    mov rbx, page_fault_handler
    call set_idt_entry
    
    ; Set up hardware interrupt handlers (32-47)
    mov rax, 32         ; Timer interrupt
    mov rbx, timer_handler
    call set_idt_entry
    
    mov rax, 33         ; Keyboard interrupt
    mov rbx, keyboard_handler
    call set_idt_entry
    
    ; Load IDT
    lidt [idt_descriptor]
    
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Set IDT entry
; rax = interrupt number
; rbx = handler address
set_idt_entry:
    push rbp
    mov rbp, rsp
    push rcx
    push rdx
    
    ; Calculate entry address
    mov rcx, rax
    shl rcx, 4          ; Each entry is 16 bytes
    add rcx, idt_table
    
    ; Set offset low (bits 0-15)
    mov [rcx], bx
    
    ; Set segment selector (bits 16-31)
    mov word [rcx + 2], 0x08    ; Code segment
    
    ; Set IST and attributes (bits 32-47)
    mov word [rcx + 4], 0x8E00  ; Present, DPL=0, Interrupt Gate
    
    ; Set offset middle (bits 48-63)
    shr rbx, 16
    mov [rcx + 6], bx
    
    ; Set offset high (bits 64-95)
    shr rbx, 16
    mov [rcx + 8], ebx
    
    ; Reserved (bits 96-127)
    mov dword [rcx + 12], 0
    
    pop rdx
    pop rcx
    mov rsp, rbp
    pop rbp
    ret

; Exception handlers
divide_by_zero_handler:
    push rax
    mov rax, divide_by_zero_msg
    call kernel_panic

debug_handler:
    iretq

nmi_handler:
    iretq

breakpoint_handler:
    iretq

overflow_handler:
    push rax
    mov rax, overflow_msg
    call kernel_panic

bound_range_exceeded_handler:
    push rax
    mov rax, bound_range_msg
    call kernel_panic

invalid_opcode_handler:
    push rax
    mov rax, invalid_opcode_msg
    call kernel_panic

device_not_available_handler:
    push rax
    mov rax, device_not_available_msg
    call kernel_panic

double_fault_handler:
    push rax
    mov rax, double_fault_msg
    call kernel_panic

invalid_tss_handler:
    push rax
    mov rax, invalid_tss_msg
    call kernel_panic

segment_not_present_handler:
    push rax
    mov rax, segment_not_present_msg
    call kernel_panic

stack_segment_fault_handler:
    push rax
    mov rax, stack_segment_fault_msg
    call kernel_panic

section .data

; 64-bit GDT
align 16
gdt64_table:
    ; Null descriptor
    dq 0
    
    ; Code segment (64-bit)
    dq 0x00AF9A000000FFFF
    
    ; Data segment (64-bit)
    dq 0x00CF92000000FFFF

gdt64_descriptor:
    dw gdt64_table_end - gdt64_table - 1
    dq gdt64_table

gdt64_table_end:

; IDT descriptor
idt_descriptor:
    dw 256 * 16 - 1     ; Limit
    dq idt_table        ; Base

; Exception messages
divide_by_zero_msg db 'Division by zero exception', 0
overflow_msg db 'Overflow exception', 0
bound_range_msg db 'Bound range exceeded exception', 0
invalid_opcode_msg db 'Invalid opcode exception', 0
device_not_available_msg db 'Device not available exception', 0
double_fault_msg db 'Double fault exception', 0
invalid_tss_msg db 'Invalid TSS exception', 0
segment_not_present_msg db 'Segment not present exception', 0
stack_segment_fault_msg db 'Stack segment fault exception', 0

section .bss

; IDT table (256 entries * 16 bytes each)
align 16
idt_table:
    resb 256 * 16
