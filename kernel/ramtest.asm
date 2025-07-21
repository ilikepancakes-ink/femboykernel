; RAM Testing Module
; Comprehensive memory testing with various patterns

[BITS 64]

extern vga_print
extern vga_println
extern vga_print_char
extern vga_newline
extern vga_clear

section .text

global run_ram_test
global test_memory_pattern
global test_walking_bits
global test_address_lines
global test_data_lines

; Run comprehensive RAM test
run_ram_test:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    push rdx
    
    mov rdi, ram_test_start_msg
    call vga_println
    
    ; Test parameters
    mov rax, 0x200000           ; Start at 2MB (avoid kernel area)
    mov rbx, 0x2000000          ; Test 32MB
    
    ; Initialize test statistics
    mov qword [test_errors], 0
    mov qword [test_passes], 0
    
    ; Test 1: Pattern test with 0x55555555
    mov rdi, pattern_test_msg
    call vga_print
    mov rcx, 0x5555555555555555
    call test_memory_pattern
    call print_test_result
    
    ; Test 2: Pattern test with 0xAAAAAAAA
    mov rdi, pattern_test_msg2
    call vga_print
    mov rcx, 0xAAAAAAAAAAAAAAAA
    call test_memory_pattern
    call print_test_result
    
    ; Test 3: Pattern test with 0x00000000
    mov rdi, zero_test_msg
    call vga_print
    mov rcx, 0x0000000000000000
    call test_memory_pattern
    call print_test_result
    
    ; Test 4: Pattern test with 0xFFFFFFFF
    mov rdi, ones_test_msg
    call vga_print
    mov rcx, 0xFFFFFFFFFFFFFFFF
    call test_memory_pattern
    call print_test_result
    
    ; Test 5: Walking bits test
    mov rdi, walking_bits_msg
    call vga_print
    call test_walking_bits
    call print_test_result
    
    ; Test 6: Address line test
    mov rdi, address_test_msg
    call vga_print
    call test_address_lines
    call print_test_result
    
    ; Test 7: Data line test
    mov rdi, data_test_msg
    call vga_print
    call test_data_lines
    call print_test_result
    
    ; Print final results
    call print_final_results
    
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Test memory with specific pattern
; rax = start address, rbx = size, rcx = pattern
test_memory_pattern:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    
    mov rdi, rax                ; Start address
    mov rsi, rbx                ; Size
    shr rsi, 3                  ; Convert to qwords
    
    ; Write pattern
.write_loop:
    mov [rdi], rcx
    add rdi, 8
    dec rsi
    jnz .write_loop
    
    ; Read and verify pattern
    mov rdi, rax                ; Reset to start
    mov rsi, rbx                ; Reset size
    shr rsi, 3                  ; Convert to qwords
    
.verify_loop:
    mov rdx, [rdi]
    cmp rdx, rcx
    je .match
    
    ; Error found
    inc qword [test_errors]
    call report_error
    
.match:
    add rdi, 8
    dec rsi
    jnz .verify_loop
    
    ; Test passed
    inc qword [test_passes]
    
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Walking bits test
test_walking_bits:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    
    mov rdi, 0x200000           ; Test address
    mov rcx, 1                  ; Walking bit pattern
    
.bit_loop:
    ; Write walking bit pattern
    mov [rdi], rcx
    
    ; Read back and verify
    mov rax, [rdi]
    cmp rax, rcx
    je .bit_ok
    
    ; Error found
    inc qword [test_errors]
    call report_error
    jmp .next_bit
    
.bit_ok:
    inc qword [test_passes]
    
.next_bit:
    shl rcx, 1                  ; Shift bit left
    cmp rcx, 0                  ; Check for overflow
    jne .bit_loop
    
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Address line test
test_address_lines:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    
    ; Test address lines by writing unique patterns to power-of-2 addresses
    mov rcx, 12                 ; Start with bit 12 (4KB)
    mov rax, 0x200000           ; Base address
    
.addr_loop:
    mov rdi, rax
    mov rbx, 1
    shl rbx, cl                 ; Calculate offset
    add rdi, rbx                ; Target address
    
    ; Write unique pattern based on address line
    mov rdx, rcx
    shl rdx, 8
    or rdx, 0x5A5A5A5A
    mov [rdi], rdx
    
    ; Verify the pattern
    mov rsi, [rdi]
    cmp rsi, rdx
    je .addr_ok
    
    ; Error found
    inc qword [test_errors]
    call report_error
    jmp .next_addr
    
.addr_ok:
    inc qword [test_passes]
    
.next_addr:
    inc rcx
    cmp rcx, 24                 ; Test up to bit 24 (16MB)
    jl .addr_loop
    
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Data line test
test_data_lines:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    
    mov rdi, 0x200000           ; Test address
    mov rcx, 0                  ; Bit counter
    
.data_loop:
    ; Test each data line
    mov rax, 1
    shl rax, cl                 ; Create test pattern
    
    ; Write pattern
    mov [rdi], rax
    
    ; Read back and verify
    mov rbx, [rdi]
    cmp rbx, rax
    je .data_ok
    
    ; Error found
    inc qword [test_errors]
    call report_error
    jmp .next_data
    
.data_ok:
    inc qword [test_passes]
    
.next_data:
    inc rcx
    cmp rcx, 64                 ; Test all 64 data lines
    jl .data_loop
    
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Report memory error
; rdi = address, rdx = expected, rax = actual
report_error:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    
    ; Only report first few errors to avoid spam
    cmp qword [test_errors], 5
    jg .skip_report
    
    mov rdi, error_msg
    call vga_print
    
    ; Print address
    mov rax, rdi
    call print_hex_qword
    
    mov rdi, expected_msg
    call vga_print
    
    ; Print expected value
    mov rax, rdx
    call print_hex_qword
    
    mov rdi, actual_msg
    call vga_print
    
    ; Print actual value
    call print_hex_qword
    
    call vga_newline
    
.skip_report:
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Print test result
print_test_result:
    push rbp
    mov rbp, rsp
    
    cmp qword [test_errors], 0
    je .passed
    
    mov rdi, failed_msg
    call vga_println
    jmp .done
    
.passed:
    mov rdi, passed_msg
    call vga_println
    
.done:
    mov rsp, rbp
    pop rbp
    ret

; Print final test results
print_final_results:
    push rbp
    mov rbp, rsp
    
    mov rdi, separator
    call vga_println
    
    mov rdi, final_results_msg
    call vga_println
    
    mov rdi, total_passes_msg
    call vga_print
    mov rax, qword [test_passes]
    call print_decimal
    call vga_newline
    
    mov rdi, total_errors_msg
    call vga_print
    mov rax, qword [test_errors]
    call print_decimal
    call vga_newline
    
    cmp qword [test_errors], 0
    je .all_passed
    
    mov rdi, test_failed_msg
    call vga_println
    jmp .done
    
.all_passed:
    mov rdi, test_passed_msg
    call vga_println
    
.done:
    mov rsp, rbp
    pop rbp
    ret

; Print 64-bit hex value (simplified version)
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

; Print decimal number (simplified version)
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

ram_test_start_msg db 'Starting comprehensive RAM test...', 0
pattern_test_msg db 'Pattern test (0x5555): ', 0
pattern_test_msg2 db 'Pattern test (0xAAAA): ', 0
zero_test_msg db 'Zero pattern test: ', 0
ones_test_msg db 'Ones pattern test: ', 0
walking_bits_msg db 'Walking bits test: ', 0
address_test_msg db 'Address line test: ', 0
data_test_msg db 'Data line test: ', 0

passed_msg db '[PASS]', 0
failed_msg db '[FAIL]', 0

error_msg db 'Error at ', 0
expected_msg db ', expected ', 0
actual_msg db ', got ', 0

separator db '================================', 0
final_results_msg db 'RAM Test Results:', 0
total_passes_msg db 'Total passes: ', 0
total_errors_msg db 'Total errors: ', 0
test_passed_msg db 'All RAM tests PASSED!', 0
test_failed_msg db 'RAM tests FAILED!', 0

hex_prefix db '0x', 0

section .bss

test_errors resq 1
test_passes resq 1
decimal_buffer resb 21
