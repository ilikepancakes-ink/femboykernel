; Memory Management System
; Physical and virtual memory management with paging

[BITS 64]

extern vga_print
extern vga_println
extern vga_print_char
extern vga_newline
extern vga_clear

section .text

; Memory constants
PAGE_SIZE equ 4096
PAGE_PRESENT equ 1
PAGE_WRITABLE equ 2
PAGE_USER equ 4

global init_memory
global get_memory_info
global detect_memory
global print_memory_map

; Initialize memory management
init_memory:
    push rbp
    mov rbp, rsp
    
    ; Detect available memory
    call detect_memory
    
    ; Initialize physical memory allocator
    call init_physical_allocator
    
    ; Set up kernel page tables
    call setup_kernel_paging
    
    mov rsp, rbp
    pop rbp
    ret

; Detect system memory using E820 memory map
detect_memory:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    
    ; For now, we'll use a simplified approach
    ; In a real implementation, you'd parse the E820 map from the bootloader
    
    ; Assume 128MB of RAM for this example
    mov qword [total_memory], 128 * 1024 * 1024
    mov qword [available_memory], 120 * 1024 * 1024  ; Reserve some for kernel
    
    ; Set up memory regions
    mov qword [memory_regions], 1
    mov qword [memory_region_0_base], 0x100000      ; Start at 1MB
    mov qword [memory_region_0_size], 127 * 1024 * 1024  ; 127MB
    mov qword [memory_region_0_type], 1             ; Available RAM
    
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Initialize physical memory allocator
init_physical_allocator:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    
    ; Simple bitmap allocator
    ; Each bit represents one 4KB page
    
    ; Calculate number of pages
    mov rax, qword [total_memory]
    shr rax, 12                     ; Divide by 4096
    mov qword [total_pages], rax
    
    ; Calculate bitmap size (1 bit per page)
    add rax, 7                      ; Round up
    shr rax, 3                      ; Divide by 8 (bits per byte)
    mov qword [bitmap_size], rax
    
    ; Clear bitmap (all pages initially free)
    mov rdi, page_bitmap
    mov rcx, rax
    xor rax, rax
    rep stosb
    
    ; Mark first 1MB as used (BIOS, bootloader, etc.)
    mov rcx, 256                    ; 1MB / 4KB = 256 pages
    mov rdi, page_bitmap
.mark_used:
    mov al, [rdi]
    or al, 1
    mov [rdi], al
    inc rdi
    loop .mark_used
    
    pop rcx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Set up kernel paging
setup_kernel_paging:
    push rbp
    mov rbp, rsp
    
    ; For now, we'll use the identity mapping set up by the bootloader
    ; In a full implementation, you'd set up proper kernel virtual memory
    
    mov rsp, rbp
    pop rbp
    ret

; Allocate a physical page
; Returns physical address in rax, or 0 if no pages available
alloc_physical_page:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    push rdx
    push rdi
    
    ; Search for free page in bitmap
    mov rdi, page_bitmap
    mov rcx, qword [bitmap_size]
    mov rbx, 0                      ; Page number
    
.search_loop:
    mov al, [rdi]
    cmp al, 0xFF                    ; All bits set?
    jne .found_byte
    
    add rbx, 8                      ; Skip 8 pages
    inc rdi
    loop .search_loop
    
    ; No free pages
    xor rax, rax
    jmp .done
    
.found_byte:
    ; Find free bit in this byte
    mov rdx, 0                      ; Bit index
    
.bit_loop:
    bt rax, rdx                     ; Test bit
    jnc .found_bit
    inc rdx
    cmp rdx, 8
    jl .bit_loop
    
    ; This shouldn't happen
    xor rax, rax
    jmp .done
    
.found_bit:
    ; Mark page as used
    bts [rdi], rdx
    
    ; Calculate physical address
    add rbx, rdx                    ; Total page number
    mov rax, rbx
    shl rax, 12                     ; Multiply by 4096
    
.done:
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    mov rsp, rbp
    pop rbp
    ret

; Free a physical page
; rax = physical address
free_physical_page:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    push rdx
    push rdi
    
    ; Calculate page number
    shr rax, 12                     ; Divide by 4096
    mov rbx, rax
    
    ; Calculate byte and bit position
    mov rcx, rbx
    shr rcx, 3                      ; Byte index
    and rbx, 7                      ; Bit index
    
    ; Clear bit in bitmap
    mov rdi, page_bitmap
    add rdi, rcx
    btr [rdi], rbx
    
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    mov rsp, rbp
    pop rbp
    ret

; Get memory information
get_memory_info:
    push rbp
    mov rbp, rsp
    
    mov rdi, memory_info_msg
    call vga_println
    
    ; Print total memory
    mov rdi, total_mem_msg
    call vga_print
    mov rax, qword [total_memory]
    call print_memory_size
    call vga_newline
    
    ; Print available memory
    mov rdi, avail_mem_msg
    call vga_print
    mov rax, qword [available_memory]
    call print_memory_size
    call vga_newline
    
    ; Print total pages
    mov rdi, total_pages_msg
    call vga_print
    mov rax, qword [total_pages]
    call print_decimal
    call vga_newline
    
    mov rsp, rbp
    pop rbp
    ret

; Print memory size in human-readable format
; rax = size in bytes
print_memory_size:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    push rdx
    
    ; Check if >= 1GB
    mov rbx, 1024 * 1024 * 1024
    cmp rax, rbx
    jl .check_mb
    
    xor rdx, rdx
    div rbx
    call print_decimal
    mov rdi, gb_suffix
    call vga_print
    jmp .done
    
.check_mb:
    ; Check if >= 1MB
    mov rbx, 1024 * 1024
    cmp rax, rbx
    jl .check_kb
    
    xor rdx, rdx
    div rbx
    call print_decimal
    mov rdi, mb_suffix
    call vga_print
    jmp .done
    
.check_kb:
    ; Check if >= 1KB
    mov rbx, 1024
    cmp rax, rbx
    jl .bytes
    
    xor rdx, rdx
    div rbx
    call print_decimal
    mov rdi, kb_suffix
    call vga_print
    jmp .done
    
.bytes:
    call print_decimal
    mov rdi, bytes_suffix
    call vga_print
    
.done:
    pop rdx
    pop rcx
    pop rbx
    mov rsp, rbp
    pop rbp
    ret

; Print decimal number
; rax = number
print_decimal:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    
    ; Handle zero case
    cmp rax, 0
    jne .not_zero
    mov al, '0'
    call vga_print_char
    jmp .done
    
.not_zero:
    ; Convert to string (reverse order)
    mov rdi, decimal_buffer + 20    ; End of buffer
    mov byte [rdi], 0               ; Null terminator
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
    
    ; Print the string
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

; Print memory map
print_memory_map:
    push rbp
    mov rbp, rsp
    
    mov rdi, memory_map_msg
    call vga_println
    
    ; For now, just print our simple memory region
    mov rdi, region_msg
    call vga_print
    mov rax, qword [memory_region_0_base]
    call print_hex_qword
    mov rdi, to_msg
    call vga_print
    mov rax, qword [memory_region_0_base]
    add rax, qword [memory_region_0_size]
    call print_hex_qword
    mov rdi, type_msg
    call vga_print
    mov rax, qword [memory_region_0_type]
    call print_decimal
    call vga_newline
    
    mov rsp, rbp
    pop rbp
    ret

; Print 64-bit hex value
; rax = value
print_hex_qword:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    
    mov rdi, hex_prefix
    call vga_print
    
    mov rcx, 16                     ; 16 hex digits
    
.digit_loop:
    rol rax, 4                      ; Rotate left 4 bits
    mov rbx, rax
    and rbx, 0xF                    ; Get lowest 4 bits
    
    cmp rbx, 10
    jl .digit
    add rbx, 'A' - 10
    jmp .print_digit
    
.digit:
    add rbx, '0'
    
.print_digit:
    mov al, bl
    call vga_print_char
    
    loop .digit_loop
    
    pop rcx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

section .data

memory_info_msg db 'Memory Information:', 0
total_mem_msg db 'Total Memory: ', 0
avail_mem_msg db 'Available Memory: ', 0
total_pages_msg db 'Total Pages: ', 0
memory_map_msg db 'Memory Map:', 0
region_msg db 'Region: ', 0
to_msg db ' - ', 0
type_msg db ' (Type: ', 0

gb_suffix db ' GB', 0
mb_suffix db ' MB', 0
kb_suffix db ' KB', 0
bytes_suffix db ' bytes', 0
hex_prefix db '0x', 0

section .bss

; Memory information
total_memory resq 1
available_memory resq 1
total_pages resq 1
bitmap_size resq 1

; Memory regions (simplified E820-style)
memory_regions resq 1
memory_region_0_base resq 1
memory_region_0_size resq 1
memory_region_0_type resq 1

; Page allocation bitmap (supports up to 32MB of RAM with 4KB pages)
page_bitmap resb 8192

; Temporary buffer for decimal conversion
decimal_buffer resb 21
