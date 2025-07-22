; FemboyOS GUI System - Assembly Implementation
; Simple text-mode GUI with windows and desktop

; VGA Constants
VGA_MEMORY equ 0xB8000
VGA_WIDTH equ 80
VGA_HEIGHT equ 25

; Colors
COLOR_BLACK equ 0
COLOR_BLUE equ 1
COLOR_GREEN equ 2
COLOR_CYAN equ 3
COLOR_RED equ 4
COLOR_MAGENTA equ 5
COLOR_BROWN equ 6
COLOR_LIGHT_GRAY equ 7
COLOR_DARK_GRAY equ 8
COLOR_LIGHT_BLUE equ 9
COLOR_LIGHT_GREEN equ 10
COLOR_LIGHT_CYAN equ 11
COLOR_LIGHT_RED equ 12
COLOR_LIGHT_MAGENTA equ 13
COLOR_YELLOW equ 14
COLOR_WHITE equ 15

; Main GUI demo function
call_gui_demo:
    pusha

    ; Initialize GUI
    call gui_init

    ; Draw desktop
    call gui_draw_desktop

    ; Create some demo windows
    call gui_create_demo_windows

    ; Add instruction text
    call gui_draw_instructions

    ; Simple wait instead of complex loop
    call gui_simple_wait

    popa
    ret

; Draw instructions for user
gui_draw_instructions:
    pusha

    ; Draw instruction at bottom of screen
    mov esi, instruction_msg
    mov edi, 2
    mov ebx, VGA_HEIGHT - 4
    call gui_draw_string_at

    popa
    ret

; Initialize GUI system
gui_init:
    pusha
    
    ; Clear screen with blue background
    call gui_clear_screen
    
    popa
    ret

; Clear screen with desktop color
gui_clear_screen:
    pusha
    
    mov edi, VGA_MEMORY
    mov eax, 0x1F201F20  ; Two spaces with white on blue
    mov ecx, (VGA_WIDTH * VGA_HEIGHT) / 2
    rep stosd
    
    popa
    ret

; Draw desktop background and title
gui_draw_desktop:
    pusha
    
    ; Clear screen first
    call gui_clear_screen
    
    ; Draw title bar at top
    mov edi, VGA_MEMORY
    mov eax, 0x4F204F20  ; Spaces with white on red (title bar)
    mov ecx, VGA_WIDTH / 2
    rep stosd
    
    ; Draw desktop title
    mov esi, desktop_title_msg
    mov edi, 2
    mov ebx, 0
    call gui_draw_string_at
    
    ; Draw taskbar at bottom
    mov edi, VGA_MEMORY + ((VGA_HEIGHT - 2) * VGA_WIDTH * 2)
    mov eax, 0x8F208F20  ; Spaces with white on dark gray
    mov ecx, VGA_WIDTH
    rep stosw
    
    ; Draw start button
    mov esi, start_button_msg
    mov edi, 1
    mov ebx, VGA_HEIGHT - 2
    call gui_draw_string_at
    
    ; Draw clock
    mov esi, clock_msg
    mov edi, VGA_WIDTH - 8
    mov ebx, VGA_HEIGHT - 2
    call gui_draw_string_at
    
    popa
    ret

; Draw string at specific position
; ESI = string, EDI = x, EBX = y
gui_draw_string_at:
    pusha
    
    ; Calculate position in VGA memory
    mov eax, ebx        ; y coordinate
    mov ecx, VGA_WIDTH
    mul ecx             ; y * width
    add eax, edi        ; + x coordinate
    shl eax, 1          ; * 2 (each char is 2 bytes)
    add eax, VGA_MEMORY ; + VGA base
    mov edi, eax        ; EDI = target position
    
.draw_loop:
    mov al, [esi]       ; Get character
    test al, al         ; Check for null terminator
    jz .done
    
    mov ah, 0x1F        ; White on blue
    stosw               ; Store character + attribute
    inc esi             ; Next character
    jmp .draw_loop
    
.done:
    popa
    ret

; Create demo windows (simplified)
gui_create_demo_windows:
    pusha

    ; Just draw simple text instead of complex windows
    mov esi, welcome_msg1
    mov edi, 10
    mov ebx, 5
    call gui_draw_string_at

    mov esi, welcome_msg2
    mov edi, 10
    mov ebx, 6
    call gui_draw_string_at

    mov esi, sysinfo_msg1
    mov edi, 10
    mov ebx, 8
    call gui_draw_string_at

    popa
    ret

; Draw a window
; EDI = x, EBX = y, ECX = width, EDX = height, ESI = title
gui_draw_window:
    pusha
    
    ; Save parameters
    mov [window_x], edi
    mov [window_y], ebx
    mov [window_width], ecx
    mov [window_height], edx
    mov [window_title_ptr], esi
    
    ; Draw window background
    mov eax, [window_y]
    mov ebx, [window_height]
    add ebx, eax        ; end_y = y + height
    
.row_loop:
    cmp eax, ebx
    jge .draw_border
    
    ; Draw one row of background
    push eax
    push ebx
    
    mov edi, [window_x]
    mov ebx, eax        ; current y
    mov ecx, [window_width]
    
.col_loop:
    cmp ecx, 0
    jle .next_row
    
    ; Calculate VGA position
    push eax
    push ecx
    push edi
    
    mov eax, ebx        ; y
    mov ecx, VGA_WIDTH
    mul ecx
    add eax, edi        ; + x
    shl eax, 1
    add eax, VGA_MEMORY
    
    mov word [eax], 0x7020  ; Space with black on light gray
    
    pop edi
    pop ecx
    pop eax
    
    inc edi
    dec ecx
    jmp .col_loop
    
.next_row:
    pop ebx
    pop eax
    inc eax
    jmp .row_loop
    
.draw_border:
    ; Draw title bar
    mov edi, [window_x]
    mov ebx, [window_y]
    mov esi, [window_title_ptr]
    call gui_draw_string_at
    
    popa
    ret

; Simple wait function - just wait for any key press
gui_simple_wait:
    pusha

    ; Draw status message
    mov esi, gui_active_msg
    mov edi, 2
    mov ebx, VGA_HEIGHT - 3
    call gui_draw_string_at

    ; Simple delay (5 seconds) then return
    mov ecx, 200000000
.delay_loop:
    dec ecx
    jnz .delay_loop

    popa
    ret

; GUI strings
desktop_title_msg db 'FemboyOS Desktop Environment v0.1', 0
start_button_msg db '[Start]', 0
clock_msg db '12:00', 0
instruction_msg db 'Press ESC to return to CLI', 0
gui_active_msg db 'GUI Active - Waiting for input...', 0
key_received_msg db 'Key pressed!', 0

window1_title db 'Welcome to FemboyOS!', 0
window2_title db 'System Info', 0

welcome_msg1 db 'Welcome to the future!', 0
welcome_msg2 db 'Press ESC to return to CLI', 0

sysinfo_msg1 db 'CPU: x86', 0
sysinfo_msg2 db 'RAM: 128MB', 0

; Window parameters (temporary storage)
window_x dd 0
window_y dd 0
window_width dd 0
window_height dd 0
window_title_ptr dd 0
