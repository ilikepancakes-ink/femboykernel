; CPU Information Module
; Uses CPUID instruction to gather processor information

[BITS 64]

extern vga_print
extern vga_println
extern vga_print_char
extern vga_newline
extern vga_clear
extern vga_newline

section .text

global get_cpu_info
global print_cpu_info
global get_cpu_vendor
global get_cpu_features
global get_cpu_cache_info

; Get and display CPU information
get_cpu_info:
    push rbp
    mov rbp, rsp
    
    call print_cpu_info
    
    mov rsp, rbp
    pop rbp
    ret

; Print comprehensive CPU information
print_cpu_info:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    push rdx
    
    mov rdi, cpu_info_header
    call vga_println
    
    ; Get and print CPU vendor
    call get_cpu_vendor
    mov rdi, vendor_msg
    call vga_print
    mov rdi, cpu_vendor_string
    call vga_println
    
    ; Get and print CPU brand string
    call get_cpu_brand
    mov rdi, brand_msg
    call vga_print
    mov rdi, cpu_brand_string
    call vga_println
    
    ; Get basic CPU info
    mov eax, 1
    cpuid
    
    ; Extract family, model, stepping
    mov rbx, rax
    
    ; Stepping (bits 0-3)
    mov rcx, rax
    and rcx, 0xF
    mov [cpu_stepping], rcx
    
    ; Model (bits 4-7)
    mov rcx, rax
    shr rcx, 4
    and rcx, 0xF
    mov [cpu_model], rcx
    
    ; Family (bits 8-11)
    mov rcx, rax
    shr rcx, 8
    and rcx, 0xF
    mov [cpu_family], rcx
    
    ; Extended model (bits 16-19)
    mov rcx, rax
    shr rcx, 16
    and rcx, 0xF
    mov [cpu_ext_model], rcx
    
    ; Extended family (bits 20-27)
    mov rcx, rax
    shr rcx, 20
    and rcx, 0xFF
    mov [cpu_ext_family], rcx
    
    ; Print family and model
    mov rdi, family_msg
    call vga_print
    mov rax, [cpu_family]
    call print_decimal
    call vga_newline
    
    mov rdi, model_msg
    call vga_print
    mov rax, [cpu_model]
    call print_decimal
    call vga_newline
    
    mov rdi, stepping_msg
    call vga_print
    mov rax, [cpu_stepping]
    call print_decimal
    call vga_newline
    
    ; Print CPU features
    call print_cpu_features
    
    ; Print cache information
    call print_cache_info
    
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Get CPU vendor string
get_cpu_vendor:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    
    ; CPUID function 0 returns vendor string
    mov eax, 0
    cpuid
    
    ; Store vendor string (EBX, EDX, ECX)
    mov rdi, cpu_vendor_string
    mov [rdi], ebx
    mov [rdi + 4], edx
    mov [rdi + 8], ecx
    mov byte [rdi + 12], 0      ; Null terminator
    
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Get CPU brand string
get_cpu_brand:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    
    ; Check if extended CPUID is available
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000004
    jl .no_brand
    
    ; Get brand string (functions 0x80000002-0x80000004)
    mov rdi, cpu_brand_string
    
    ; First part
    mov eax, 0x80000002
    cpuid
    mov [rdi], eax
    mov [rdi + 4], ebx
    mov [rdi + 8], ecx
    mov [rdi + 12], edx
    
    ; Second part
    mov eax, 0x80000003
    cpuid
    mov [rdi + 16], eax
    mov [rdi + 20], ebx
    mov [rdi + 24], ecx
    mov [rdi + 28], edx
    
    ; Third part
    mov eax, 0x80000004
    cpuid
    mov [rdi + 32], eax
    mov [rdi + 36], ebx
    mov [rdi + 40], ecx
    mov [rdi + 44], edx
    
    mov byte [rdi + 48], 0      ; Null terminator
    jmp .done
    
.no_brand:
    mov rdi, cpu_brand_string
    mov rsi, no_brand_msg
    call strcpy
    
.done:
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Print CPU features
print_cpu_features:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    push rdx
    
    mov rdi, features_msg
    call vga_println
    
    ; Get feature flags
    mov eax, 1
    cpuid
    
    ; Check common features
    ; FPU (bit 0)
    test edx, 1
    jz .no_fpu
    mov rdi, fpu_msg
    call vga_println
.no_fpu:
    
    ; MMX (bit 23)
    test edx, (1 << 23)
    jz .no_mmx
    mov rdi, mmx_msg
    call vga_println
.no_mmx:
    
    ; SSE (bit 25)
    test edx, (1 << 25)
    jz .no_sse
    mov rdi, sse_msg
    call vga_println
.no_sse:
    
    ; SSE2 (bit 26)
    test edx, (1 << 26)
    jz .no_sse2
    mov rdi, sse2_msg
    call vga_println
.no_sse2:
    
    ; SSE3 (bit 0 of ECX)
    test ecx, 1
    jz .no_sse3
    mov rdi, sse3_msg
    call vga_println
.no_sse3:
    
    ; SSSE3 (bit 9 of ECX)
    test ecx, (1 << 9)
    jz .no_ssse3
    mov rdi, ssse3_msg
    call vga_println
.no_ssse3:
    
    ; SSE4.1 (bit 19 of ECX)
    test ecx, (1 << 19)
    jz .no_sse41
    mov rdi, sse41_msg
    call vga_println
.no_sse41:
    
    ; SSE4.2 (bit 20 of ECX)
    test ecx, (1 << 20)
    jz .no_sse42
    mov rdi, sse42_msg
    call vga_println
.no_sse42:
    
    ; AVX (bit 28 of ECX)
    test ecx, (1 << 28)
    jz .no_avx
    mov rdi, avx_msg
    call vga_println
.no_avx:
    
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Print cache information
print_cache_info:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    push rdx
    
    mov rdi, cache_msg
    call vga_println
    
    ; Check if cache info is available
    mov eax, 0
    cpuid
    cmp eax, 2
    jl .no_cache_info
    
    ; Get cache information
    mov eax, 2
    cpuid
    
    ; For simplicity, just indicate cache info is available
    mov rdi, cache_available_msg
    call vga_println
    jmp .done
    
.no_cache_info:
    mov rdi, no_cache_info_msg
    call vga_println
    
.done:
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; String copy function
; rdi = destination, rsi = source
strcpy:
    push rbp
    mov rbp, rsp
    push rax
    push rdi
    push rsi
    
.copy_loop:
    mov al, [rsi]
    mov [rdi], al
    cmp al, 0
    je .done
    inc rsi
    inc rdi
    jmp .copy_loop
    
.done:
    pop rsi
    pop rdi
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

cpu_info_header db 'CPU Information:', 0
vendor_msg db 'Vendor: ', 0
brand_msg db 'Brand: ', 0
family_msg db 'Family: ', 0
model_msg db 'Model: ', 0
stepping_msg db 'Stepping: ', 0
features_msg db 'Features:', 0
cache_msg db 'Cache Information:', 0

; Feature strings
fpu_msg db '  - FPU (Floating Point Unit)', 0
mmx_msg db '  - MMX (MultiMedia eXtensions)', 0
sse_msg db '  - SSE (Streaming SIMD Extensions)', 0
sse2_msg db '  - SSE2', 0
sse3_msg db '  - SSE3', 0
ssse3_msg db '  - SSSE3 (Supplemental SSE3)', 0
sse41_msg db '  - SSE4.1', 0
sse42_msg db '  - SSE4.2', 0
avx_msg db '  - AVX (Advanced Vector Extensions)', 0

cache_available_msg db '  Cache information available', 0
no_cache_info_msg db '  Cache information not available', 0
no_brand_msg db 'Unknown', 0

section .bss

; CPU information storage
cpu_vendor_string resb 13
cpu_brand_string resb 49
cpu_family resq 1
cpu_model resq 1
cpu_stepping resq 1
cpu_ext_family resq 1
cpu_ext_model resq 1

decimal_buffer resb 21
