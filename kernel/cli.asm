; Command Line Interface
; Interactive shell for system diagnostics

[BITS 64]

extern vga_print
extern vga_println
extern vga_print_char
extern vga_newline
extern vga_clear
extern get_cpu_info
extern get_memory_info
extern print_memory_map
extern run_ram_test
extern pci_list_devices

section .text

global command_loop
global process_command
global get_input
global parse_command

; Main command loop
command_loop:
    push rbp
    mov rbp, rsp
    
.loop:
    ; Print prompt
    mov rdi, prompt
    call vga_print
    
    ; Get user input
    call get_input
    
    ; Process command
    call process_command
    
    ; Continue loop
    jmp .loop
    
    mov rsp, rbp
    pop rbp
    ret

; Get user input from keyboard
get_input:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    push rdi
    
    ; Clear input buffer
    mov rdi, input_buffer
    mov rcx, INPUT_BUFFER_SIZE
    xor rax, rax
    rep stosb
    
    ; Reset input position
    mov qword [input_pos], 0
    mov rdi, input_buffer
    
.input_loop:
    ; Wait for keyboard input
    call wait_for_key
    
    ; Check for special keys
    cmp al, 13              ; Enter
    je .enter_pressed
    cmp al, 8               ; Backspace
    je .backspace_pressed
    cmp al, 27              ; Escape
    je .escape_pressed
    
    ; Check if printable character
    cmp al, 32
    jl .input_loop
    cmp al, 126
    jg .input_loop
    
    ; Check buffer space
    mov rbx, qword [input_pos]
    cmp rbx, INPUT_BUFFER_SIZE - 1
    jge .input_loop
    
    ; Store character
    mov [rdi + rbx], al
    inc qword [input_pos]
    
    ; Echo character
    call vga_print_char
    
    jmp .input_loop
    
.backspace_pressed:
    ; Check if we can backspace
    cmp qword [input_pos], 0
    je .input_loop
    
    ; Remove character
    dec qword [input_pos]
    mov rbx, qword [input_pos]
    mov byte [rdi + rbx], 0
    
    ; Visual backspace (move cursor back, print space, move back again)
    mov al, 8
    call vga_print_char
    mov al, ' '
    call vga_print_char
    mov al, 8
    call vga_print_char
    
    jmp .input_loop
    
.escape_pressed:
    ; Clear current input
    mov qword [input_pos], 0
    mov byte [input_buffer], 0
    call vga_newline
    jmp .done
    
.enter_pressed:
    ; Null-terminate input
    mov rbx, qword [input_pos]
    mov byte [rdi + rbx], 0
    call vga_newline
    
.done:
    pop rdi
    pop rcx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Wait for keyboard input (simplified)
wait_for_key:
    push rbp
    mov rbp, rsp
    push rbx
    
    ; For now, simulate keyboard input with a simple character
    ; In a real implementation, this would read from the keyboard controller
    
    ; Simple simulation - return 'h' for help, 'c' for cpuinfo, etc.
    ; This is just for demonstration
    mov al, 'h'             ; Simulate 'h' key press
    
    pop rbx
    mov rsp, rbp
    pop rbp
    ret

; Process the entered command
process_command:
    push rbp
    mov rbp, rsp
    push rax
    push rdi
    push rsi
    
    ; Skip empty commands
    cmp byte [input_buffer], 0
    je .done
    
    ; Parse command
    call parse_command
    
    ; Check for known commands
    mov rdi, input_buffer
    mov rsi, help_cmd
    call strcmp
    cmp rax, 0
    je .cmd_help
    
    mov rdi, input_buffer
    mov rsi, cpuinfo_cmd
    call strcmp
    cmp rax, 0
    je .cmd_cpuinfo
    
    mov rdi, input_buffer
    mov rsi, meminfo_cmd
    call strcmp
    cmp rax, 0
    je .cmd_meminfo
    
    mov rdi, input_buffer
    mov rsi, ramtest_cmd
    call strcmp
    cmp rax, 0
    je .cmd_ramtest
    
    mov rdi, input_buffer
    mov rsi, pci_cmd
    call strcmp
    cmp rax, 0
    je .cmd_pci
    
    mov rdi, input_buffer
    mov rsi, clear_cmd
    call strcmp
    cmp rax, 0
    je .cmd_clear
    
    mov rdi, input_buffer
    mov rsi, reboot_cmd
    call strcmp
    cmp rax, 0
    je .cmd_reboot
    
    ; Unknown command
    mov rdi, unknown_cmd_msg
    call vga_print
    mov rdi, input_buffer
    call vga_println
    jmp .done
    
.cmd_help:
    call show_help
    jmp .done
    
.cmd_cpuinfo:
    call get_cpu_info
    jmp .done
    
.cmd_meminfo:
    call get_memory_info
    call print_memory_map
    jmp .done
    
.cmd_ramtest:
    call run_ram_test
    jmp .done
    
.cmd_pci:
    call pci_list_devices
    jmp .done
    
.cmd_clear:
    call vga_clear
    jmp .done
    
.cmd_reboot:
    call reboot_system
    jmp .done
    
.done:
    pop rsi
    pop rdi
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Parse command (for now, just trim whitespace)
parse_command:
    push rbp
    mov rbp, rsp
    push rax
    push rdi
    push rsi
    
    ; Convert to lowercase and trim
    mov rdi, input_buffer
    
.lowercase_loop:
    mov al, [rdi]
    cmp al, 0
    je .done
    
    ; Convert to lowercase
    cmp al, 'A'
    jl .next_char
    cmp al, 'Z'
    jg .next_char
    add al, 32              ; Convert to lowercase
    mov [rdi], al
    
.next_char:
    inc rdi
    jmp .lowercase_loop
    
.done:
    pop rsi
    pop rdi
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; String compare function
; rdi = string1, rsi = string2
; Returns 0 in rax if equal, non-zero if different
strcmp:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    push rdi
    push rsi
    
.compare_loop:
    mov al, [rdi]
    mov bl, [rsi]
    
    cmp al, bl
    jne .not_equal
    
    cmp al, 0
    je .equal
    
    inc rdi
    inc rsi
    jmp .compare_loop
    
.equal:
    xor rax, rax
    jmp .done
    
.not_equal:
    mov rax, 1
    
.done:
    pop rsi
    pop rdi
    pop rcx
    pop rbx
    mov rsp, rbp
    pop rbp
    ret

; Show help information
show_help:
    push rbp
    mov rbp, rsp
    
    mov rdi, help_header
    call vga_println
    
    mov rdi, help_line1
    call vga_println
    
    mov rdi, help_line2
    call vga_println
    
    mov rdi, help_line3
    call vga_println
    
    mov rdi, help_line4
    call vga_println
    
    mov rdi, help_line5
    call vga_println
    
    mov rdi, help_line6
    call vga_println
    
    mov rdi, help_line7
    call vga_println
    
    mov rdi, help_line8
    call vga_println
    
    mov rsp, rbp
    pop rbp
    ret

; Reboot system
reboot_system:
    push rbp
    mov rbp, rsp
    
    mov rdi, reboot_msg
    call vga_println
    
    ; Wait a moment
    mov rcx, 0x1000000
.wait_loop:
    nop
    loop .wait_loop
    
    ; Reboot via keyboard controller
    mov al, 0xFE
    out 0x64, al
    
    ; If that doesn't work, try triple fault
    cli
    mov rax, 0
    mov cr3, rax            ; This should cause a triple fault
    
    ; Halt if all else fails
    hlt
    
    mov rsp, rbp
    pop rbp
    ret

section .data

prompt db 'femboykernel> ', 0

; Command strings
help_cmd db 'help', 0
cpuinfo_cmd db 'cpuinfo', 0
meminfo_cmd db 'meminfo', 0
ramtest_cmd db 'ramtest', 0
pci_cmd db 'pci', 0
clear_cmd db 'clear', 0
reboot_cmd db 'reboot', 0

; Messages
unknown_cmd_msg db 'Unknown command: ', 0
reboot_msg db 'Rebooting system...', 0

; Help text
help_header db 'Available commands:', 0
help_line1 db '  help     - Show this help message', 0
help_line2 db '  cpuinfo  - Display CPU information', 0
help_line3 db '  meminfo  - Display memory information', 0
help_line4 db '  ramtest  - Run comprehensive RAM tests', 0
help_line5 db '  pci      - List PCI devices', 0
help_line6 db '  clear    - Clear screen', 0
help_line7 db '  reboot   - Restart system', 0
help_line8 db '', 0

section .bss

INPUT_BUFFER_SIZE equ 256

input_buffer resb INPUT_BUFFER_SIZE
input_pos resq 1
