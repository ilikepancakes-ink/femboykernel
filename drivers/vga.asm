; VGA Text Mode Driver
; Provides text output functions for the kernel

[BITS 64]

section .text

; VGA constants
VGA_BUFFER equ 0xB8000
VGA_WIDTH equ 80
VGA_HEIGHT equ 25
VGA_SIZE equ VGA_WIDTH * VGA_HEIGHT

; Color constants
VGA_COLOR_BLACK equ 0
VGA_COLOR_BLUE equ 1
VGA_COLOR_GREEN equ 2
VGA_COLOR_CYAN equ 3
VGA_COLOR_RED equ 4
VGA_COLOR_MAGENTA equ 5
VGA_COLOR_BROWN equ 6
VGA_COLOR_LIGHT_GREY equ 7
VGA_COLOR_DARK_GREY equ 8
VGA_COLOR_LIGHT_BLUE equ 9
VGA_COLOR_LIGHT_GREEN equ 10
VGA_COLOR_LIGHT_CYAN equ 11
VGA_COLOR_LIGHT_RED equ 12
VGA_COLOR_LIGHT_MAGENTA equ 13
VGA_COLOR_LIGHT_BROWN equ 14
VGA_COLOR_WHITE equ 15

; Default color (white on black)
DEFAULT_COLOR equ (VGA_COLOR_BLACK << 4) | VGA_COLOR_WHITE

global vga_init
global vga_clear
global vga_print
global vga_println
global vga_print_char
global vga_set_color
global vga_scroll
global vga_newline

; Initialize VGA driver
vga_init:
    push rbp
    mov rbp, rsp
    
    ; Reset cursor position
    mov qword [cursor_x], 0
    mov qword [cursor_y], 0
    
    ; Set default color
    mov byte [current_color], DEFAULT_COLOR
    
    ; Update hardware cursor
    call update_cursor
    
    mov rsp, rbp
    pop rbp
    ret

; Clear screen
vga_clear:
    push rbp
    mov rbp, rsp
    push rax
    push rcx
    push rdi
    
    ; Calculate clear character (space with current color)
    mov al, byte [current_color]
    shl ax, 8
    or ax, ' '
    
    ; Clear entire screen
    mov rdi, VGA_BUFFER
    mov rcx, VGA_SIZE
    rep stosw
    
    ; Reset cursor
    mov qword [cursor_x], 0
    mov qword [cursor_y], 0
    call update_cursor
    
    pop rdi
    pop rcx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Print null-terminated string
; rdi = string pointer
vga_print:
    push rbp
    mov rbp, rsp
    push rax
    push rdi
    
.loop:
    mov al, [rdi]
    cmp al, 0
    je .done
    
    call vga_print_char
    inc rdi
    jmp .loop
    
.done:
    pop rdi
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Print string with newline
; rdi = string pointer
vga_println:
    push rbp
    mov rbp, rsp
    
    call vga_print
    call vga_newline
    
    mov rsp, rbp
    pop rbp
    ret

; Print single character
; al = character
vga_print_char:
    push rbp
    mov rbp, rsp
    push rax
    push rbx
    push rcx
    push rdx
    
    ; Handle special characters
    cmp al, 10          ; Newline
    je .newline
    cmp al, 13          ; Carriage return
    je .carriage_return
    cmp al, 8           ; Backspace
    je .backspace
    cmp al, 9           ; Tab
    je .tab
    
    ; Regular character
    jmp .print_char
    
.newline:
    call vga_newline
    jmp .done
    
.carriage_return:
    mov qword [cursor_x], 0
    call update_cursor
    jmp .done
    
.backspace:
    cmp qword [cursor_x], 0
    je .done
    dec qword [cursor_x]
    call update_cursor
    jmp .done
    
.tab:
    ; Align to next 4-character boundary
    mov rax, qword [cursor_x]
    add rax, 4
    and rax, ~3
    mov qword [cursor_x], rax
    cmp rax, VGA_WIDTH
    jl .tab_done
    call vga_newline
.tab_done:
    call update_cursor
    jmp .done
    
.print_char:
    ; Calculate position in buffer
    mov rax, qword [cursor_y]
    mov rbx, VGA_WIDTH
    mul rbx
    add rax, qword [cursor_x]
    shl rax, 1              ; Each character is 2 bytes
    add rax, VGA_BUFFER
    
    ; Write character and color
    mov [rax], al
    mov bl, byte [current_color]
    mov [rax + 1], bl
    
    ; Advance cursor
    inc qword [cursor_x]
    cmp qword [cursor_x], VGA_WIDTH
    jl .update_cursor
    call vga_newline
    jmp .done
    
.update_cursor:
    call update_cursor
    
.done:
    pop rdx
    pop rcx
    pop rbx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Move to next line
vga_newline:
    push rbp
    mov rbp, rsp
    
    mov qword [cursor_x], 0
    inc qword [cursor_y]
    
    ; Check if we need to scroll
    cmp qword [cursor_y], VGA_HEIGHT
    jl .no_scroll
    
    call vga_scroll
    dec qword [cursor_y]
    
.no_scroll:
    call update_cursor
    
    mov rsp, rbp
    pop rbp
    ret

; Scroll screen up one line
vga_scroll:
    push rbp
    mov rbp, rsp
    push rax
    push rcx
    push rdi
    push rsi
    
    ; Move all lines up
    mov rsi, VGA_BUFFER + (VGA_WIDTH * 2)  ; Source: line 1
    mov rdi, VGA_BUFFER                     ; Dest: line 0
    mov rcx, VGA_WIDTH * (VGA_HEIGHT - 1)  ; Copy all but last line
    rep movsw
    
    ; Clear last line
    mov al, byte [current_color]
    shl ax, 8
    or ax, ' '
    mov rcx, VGA_WIDTH
    rep stosw
    
    pop rsi
    pop rdi
    pop rcx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; Set text color
; al = color
vga_set_color:
    push rbp
    mov rbp, rsp
    
    mov byte [current_color], al
    
    mov rsp, rbp
    pop rbp
    ret

; Update hardware cursor position
update_cursor:
    push rbp
    mov rbp, rsp
    push rax
    push rdx
    
    ; Calculate cursor position
    mov rax, qword [cursor_y]
    mov rdx, VGA_WIDTH
    mul rdx
    add rax, qword [cursor_x]
    
    ; Send low byte
    mov dx, 0x3D4
    mov al, 0x0F
    out dx, al
    mov dx, 0x3D5
    mov rax, qword [cursor_y]
    mov rdx, VGA_WIDTH
    mul rdx
    add rax, qword [cursor_x]
    out dx, al
    
    ; Send high byte
    mov dx, 0x3D4
    mov al, 0x0E
    out dx, al
    mov dx, 0x3D5
    mov rax, qword [cursor_y]
    mov rdx, VGA_WIDTH
    mul rdx
    add rax, qword [cursor_x]
    shr rax, 8
    out dx, al
    
    pop rdx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

section .data

; Current cursor position
cursor_x dq 0
cursor_y dq 0

; Current text color
current_color db DEFAULT_COLOR
