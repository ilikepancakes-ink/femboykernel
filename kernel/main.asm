; FemboyOS Main Entry Point
; 32-bit kernel with command line interface
extern compositor_init
extern network_init
extern network_command

; Global symbols for network module
global input_buffer
global strcmp
global print_string
global newline
global print_char
global print_number

; Constants
VGA_MEMORY equ 0xB8000
VGA_WIDTH equ 80
VGA_HEIGHT equ 25
VGA_COLOR equ 0x0F  ; White on black

; Simple filesystem (much smaller)
MAX_FILES equ 4

_start:
    ; Kernel entry point

    ; Clear screen
    call clear_screen

    ; Initialize simple filesystem
    mov dword [file_count], 2  ; Start with 2 default files

    ; Initialize network stack
    call network_init

    ; Print welcome message
    mov esi, welcome_msg
    call print_string
    call newline
    call newline

    ; Debug: print that we reached command loop
    mov esi, debug_msg
    call print_string
    call newline

    ; Start command loop
    jmp command_loop

debug_msg db 'Reached command loop initialization', 0

; Clear the entire screen
clear_screen:
    mov edi, VGA_MEMORY
    mov eax, 0x0F200F20  ; Two spaces with white on black
    mov ecx, (VGA_WIDTH * VGA_HEIGHT) / 2
    rep stosd

    ; Reset cursor position
    mov dword [cursor_x], 0
    mov dword [cursor_y], 0
    ret

; Print a null-terminated string
; ESI = pointer to string
print_string:
    pusha
.loop:
    lodsb                ; Load byte from [ESI] into AL
    test al, al          ; Check if null terminator
    jz .done
    call print_char
    jmp .loop
.done:
    popa
    ret

; Print a single character
; AL = character to print
print_char:
    pusha

    ; Check for newline
    cmp al, 10
    je .newline

    ; Calculate VGA memory position
    mov ebx, [cursor_y]
    imul ebx, VGA_WIDTH
    add ebx, [cursor_x]
    shl ebx, 1           ; Multiply by 2 (char + attribute)
    add ebx, VGA_MEMORY

    ; Write character and attribute
    mov [ebx], al
    mov byte [ebx + 1], VGA_COLOR

    ; Advance cursor
    inc dword [cursor_x]
    cmp dword [cursor_x], VGA_WIDTH
    jl .done

.newline:
    mov dword [cursor_x], 0
    inc dword [cursor_y]

    ; Check if we need to scroll
    cmp dword [cursor_y], VGA_HEIGHT
    jl .done
    call scroll_screen
    dec dword [cursor_y]

.done:
    popa
    ret

; Move to next line
newline:
    mov dword [cursor_x], 0
    inc dword [cursor_y]

    ; Check if we need to scroll
    cmp dword [cursor_y], VGA_HEIGHT
    jl .done
    call scroll_screen
    dec dword [cursor_y]
.done:
    ret

; Scroll screen up by one line
scroll_screen:
    pusha

    ; Move all lines up
    mov esi, VGA_MEMORY + (VGA_WIDTH * 2)  ; Source: line 1
    mov edi, VGA_MEMORY                    ; Dest: line 0
    mov ecx, VGA_WIDTH * (VGA_HEIGHT - 1)  ; Copy all but last line
    rep movsw

    ; Clear last line
    mov edi, VGA_MEMORY + (VGA_WIDTH * (VGA_HEIGHT - 1) * 2)
    mov eax, 0x0F200F20  ; Two spaces
    mov ecx, VGA_WIDTH / 2
    rep stosd

    popa
    ret

; Main command loop
command_loop:
    ; Print prompt
    mov esi, prompt_msg
    call print_string

    ; Clear input buffer
    mov dword [input_pos], 0
    mov edi, input_buffer
    mov ecx, 256
    xor eax, eax
    rep stosb

    ; Read command
    call read_line

    ; Process command
    call process_command

    ; Repeat
    jmp command_loop

; Read a line of input from keyboard
read_line:
    pusha
.loop:
    ; Wait for keyboard input
    call wait_for_key

    ; Check for Enter key
    cmp al, 13
    je .enter

    ; Check for Backspace
    cmp al, 8
    je .backspace

    ; Check if printable character
    cmp al, 32
    jl .loop
    cmp al, 126
    jg .loop

    ; Check buffer space
    mov ebx, [input_pos]
    cmp ebx, 255
    jge .loop

    ; Add to buffer
    mov edi, input_buffer
    add edi, ebx
    mov [edi], al
    inc dword [input_pos]

    ; Echo character
    call print_char
    jmp .loop

.backspace:
    ; Check if buffer is empty
    cmp dword [input_pos], 0
    je .loop

    ; Remove from buffer
    dec dword [input_pos]
    mov ebx, [input_pos]
    mov byte [input_buffer + ebx], 0

    ; Move cursor back and clear character
    dec dword [cursor_x]
    mov al, ' '
    call print_char
    dec dword [cursor_x]
    jmp .loop

.enter:
    call newline
    popa
    ret

; Wait for a key press and return it in AL
wait_for_key:
    pusha
.wait:
    ; Check keyboard status
    in al, 0x64
    test al, 1
    jz .wait

    ; Read scancode
    in al, 0x60

    ; Convert scancode to ASCII (simplified)
    call scancode_to_ascii
    mov [esp + 28], al  ; Store in AL on stack

    popa
    ret

; Convert scancode to ASCII (simplified mapping)
scancode_to_ascii:
    ; Check for key release (bit 7 set)
    test al, 0x80
    jnz .key_release

    ; Key press - check for shift keys first
    cmp al, 0x2A        ; Left Shift press
    je .left_shift_press
    cmp al, 0x36        ; Right Shift press
    je .right_shift_press

    ; Simple scancode to ASCII mapping
    cmp al, 0x1C        ; Enter
    je .enter
    cmp al, 0x0E        ; Backspace
    je .backspace
    cmp al, 0x39        ; Space
    je .space

    ; Letters (a-z)
    cmp al, 0x1E        ; A
    je .a
    cmp al, 0x30        ; B
    je .b
    cmp al, 0x2E        ; C
    je .c
    cmp al, 0x20        ; D
    je .d
    cmp al, 0x12        ; E
    je .e
    cmp al, 0x21        ; F
    je .f
    cmp al, 0x22        ; G
    je .g
    cmp al, 0x23        ; H
    je .h
    cmp al, 0x17        ; I
    je .i
    cmp al, 0x24        ; J
    je .j
    cmp al, 0x25        ; K
    je .k
    cmp al, 0x26        ; L
    je .l
    cmp al, 0x32        ; M
    je .m
    cmp al, 0x31        ; N
    je .n
    cmp al, 0x18        ; O
    je .o
    cmp al, 0x19        ; P
    je .p
    cmp al, 0x10        ; Q
    je .q
    cmp al, 0x13        ; R
    je .r
    cmp al, 0x1F        ; S
    je .s
    cmp al, 0x14        ; T
    je .t
    cmp al, 0x16        ; U
    je .u
    cmp al, 0x2F        ; V
    je .v
    cmp al, 0x11        ; W
    je .w
    cmp al, 0x2D        ; X
    je .x
    cmp al, 0x15        ; Y
    je .y
    cmp al, 0x2C        ; Z
    je .z

    ; Numbers (0-9)
    cmp al, 0x0B        ; 0
    je .num0
    cmp al, 0x02        ; 1
    je .num1
    cmp al, 0x03        ; 2
    je .num2
    cmp al, 0x04        ; 3
    je .num3
    cmp al, 0x05        ; 4
    je .num4
    cmp al, 0x06        ; 5
    je .num5
    cmp al, 0x07        ; 6
    je .num6
    cmp al, 0x08        ; 7
    je .num7
    cmp al, 0x09        ; 8
    je .num8
    cmp al, 0x0A        ; 9
    je .num9

    ; Punctuation
    cmp al, 0x34        ; Period (.)
    je .period
    cmp al, 0x33        ; Comma (,)
    je .comma
    cmp al, 0x35        ; Slash (/)
    je .slash
    cmp al, 0x27        ; Semicolon (;)
    je .semicolon
    cmp al, 0x28        ; Apostrophe (')
    je .apostrophe

.key_release:
    ; Handle key releases
    and al, 0x7F        ; Remove release bit
    cmp al, 0x2A        ; Left Shift release
    je .left_shift_release
    cmp al, 0x36        ; Right Shift release
    je .right_shift_release
    ; Ignore other key releases
    mov al, 0
    ret

.left_shift_press:
    mov byte [shift_pressed], 1
    mov al, 0
    ret

.right_shift_press:
    mov byte [shift_pressed], 1
    mov al, 0
    ret

.left_shift_release:
    mov byte [shift_pressed], 0
    mov al, 0
    ret

.right_shift_release:
    mov byte [shift_pressed], 0
    mov al, 0
    ret

.invalid:
    mov al, 0
    ret

.enter:
    mov al, 13
    ret
.backspace:
    mov al, 8
    ret
.space:
    mov al, 32
    ret
.a: cmp byte [shift_pressed], 1
    je .A_upper
    mov al, 'a'
    ret
.A_upper: mov al, 'A'
    ret
.b: cmp byte [shift_pressed], 1
    je .B_upper
    mov al, 'b'
    ret
.B_upper: mov al, 'B'
    ret
.c: cmp byte [shift_pressed], 1
    je .C_upper
    mov al, 'c'
    ret
.C_upper: mov al, 'C'
    ret
.d: cmp byte [shift_pressed], 1
    je .D_upper
    mov al, 'd'
    ret
.D_upper: mov al, 'D'
    ret
.e: cmp byte [shift_pressed], 1
    je .E_upper
    mov al, 'e'
    ret
.E_upper: mov al, 'E'
    ret
.f: cmp byte [shift_pressed], 1
    je .F_upper
    mov al, 'f'
    ret
.F_upper: mov al, 'F'
    ret
.g: cmp byte [shift_pressed], 1
    je .G_upper
    mov al, 'g'
    ret
.G_upper: mov al, 'G'
    ret
.h: cmp byte [shift_pressed], 1
    je .H_upper
    mov al, 'h'
    ret
.H_upper: mov al, 'H'
    ret
.i: cmp byte [shift_pressed], 1
    je .I_upper
    mov al, 'i'
    ret
.I_upper: mov al, 'I'
    ret
.j: cmp byte [shift_pressed], 1
    je .J_upper
    mov al, 'j'
    ret
.J_upper: mov al, 'J'
    ret
.k: cmp byte [shift_pressed], 1
    je .K_upper
    mov al, 'k'
    ret
.K_upper: mov al, 'K'
    ret
.l: cmp byte [shift_pressed], 1
    je .L_upper
    mov al, 'l'
    ret
.L_upper: mov al, 'L'
    ret
.m: cmp byte [shift_pressed], 1
    je .M_upper
    mov al, 'm'
    ret
.M_upper: mov al, 'M'
    ret
.n: cmp byte [shift_pressed], 1
    je .N_upper
    mov al, 'n'
    ret
.N_upper: mov al, 'N'
    ret
.o: cmp byte [shift_pressed], 1
    je .O_upper
    mov al, 'o'
    ret
.O_upper: mov al, 'O'
    ret
.p: cmp byte [shift_pressed], 1
    je .P_upper
    mov al, 'p'
    ret
.P_upper: mov al, 'P'
    ret
.q: cmp byte [shift_pressed], 1
    je .Q_upper
    mov al, 'q'
    ret
.Q_upper: mov al, 'Q'
    ret
.r: cmp byte [shift_pressed], 1
    je .R_upper
    mov al, 'r'
    ret
.R_upper: mov al, 'R'
    ret
.s: cmp byte [shift_pressed], 1
    je .S_upper
    mov al, 's'
    ret
.S_upper: mov al, 'S'
    ret
.t: cmp byte [shift_pressed], 1
    je .T_upper
    mov al, 't'
    ret
.T_upper: mov al, 'T'
    ret
.u: cmp byte [shift_pressed], 1
    je .U_upper
    mov al, 'u'
    ret
.U_upper: mov al, 'U'
    ret
.v: cmp byte [shift_pressed], 1
    je .V_upper
    mov al, 'v'
    ret
.V_upper: mov al, 'V'
    ret
.w: cmp byte [shift_pressed], 1
    je .W_upper
    mov al, 'w'
    ret
.W_upper: mov al, 'W'
    ret
.x: cmp byte [shift_pressed], 1
    je .X_upper
    mov al, 'x'
    ret
.X_upper: mov al, 'X'
    ret
.y: cmp byte [shift_pressed], 1
    je .Y_upper
    mov al, 'y'
    ret
.Y_upper: mov al, 'Y'
    ret
.z: cmp byte [shift_pressed], 1
    je .Z_upper
    mov al, 'z'
    ret
.Z_upper: mov al, 'Z'
    ret

; Numbers
.num0: mov al, '0'
    ret
.num1: mov al, '1'
    ret
.num2: mov al, '2'
    ret
.num3: mov al, '3'
    ret
.num4: mov al, '4'
    ret
.num5: mov al, '5'
    ret
.num6: mov al, '6'
    ret
.num7: mov al, '7'
    ret
.num8: mov al, '8'
    ret
.num9: mov al, '9'
    ret

; Punctuation
.period: mov al, '.'
    ret
.comma: mov al, ','
    ret
.slash: mov al, '/'
    ret
.semicolon: mov al, ';'
    ret
.apostrophe: mov al, "'"
    ret

; Process the command in input_buffer
process_command:
    pusha

    ; Check if empty command
    cmp byte [input_buffer], 0
    je .done

    ; Check for "help" command
    mov esi, input_buffer
    mov edi, cmd_help
    call strcmp
    test eax, eax
    jz .help_cmd

    ; Check for "clear" command
    mov esi, input_buffer
    mov edi, cmd_clear
    call strcmp
    test eax, eax
    jz .clear_cmd

    ; Check for "version" command
    mov esi, input_buffer
    mov edi, cmd_version
    call strcmp
    test eax, eax
    jz .version_cmd

    ; Check for "listdisk" command
    mov esi, input_buffer
    mov edi, cmd_listdisk
    call strcmp
    test eax, eax
    jz .listdisk_cmd

    ; Check for "sysinfo" command
    mov esi, input_buffer
    mov edi, cmd_sysinfo
    call strcmp
    test eax, eax
    jz .sysinfo_cmd

    ; Check for "ls" command
    mov esi, input_buffer
    mov edi, cmd_ls
    call strcmp
    test eax, eax
    jz .ls_cmd

    ; Check for "dir" command (alias for ls)
    mov esi, input_buffer
    mov edi, cmd_dir
    call strcmp
    test eax, eax
    jz .ls_cmd

    ; Check for "pwd" command
    mov esi, input_buffer
    mov edi, cmd_pwd
    call strcmp
    test eax, eax
    jz .pwd_cmd

    ; Check for "date" command
    mov esi, input_buffer
    mov edi, cmd_date
    call strcmp
    test eax, eax
    jz .date_cmd

    ; Check for "time" command
    mov esi, input_buffer
    mov edi, cmd_time
    call strcmp
    test eax, eax
    jz .time_cmd

    ; Check for "uptime" command
    mov esi, input_buffer
    mov edi, cmd_uptime
    call strcmp
    test eax, eax
    jz .uptime_cmd

    ; Check for "whoami" command
    mov esi, input_buffer
    mov edi, cmd_whoami
    call strcmp
    test eax, eax
    jz .whoami_cmd

    ; Check for "echo" command
    mov esi, input_buffer
    mov edi, cmd_echo
    call strcmp
    test eax, eax
    jz .echo_cmd

    ; Check for "reboot" command
    mov esi, input_buffer
    mov edi, cmd_reboot
    call strcmp
    test eax, eax
    jz .reboot_cmd

    ; Check for "shutdown" command
    mov esi, input_buffer
    mov edi, cmd_shutdown
    call strcmp
    test eax, eax
    jz .shutdown_cmd

    ; Check for "touch" command
    mov esi, input_buffer
    mov edi, cmd_touch
    call strcmp
    test eax, eax
    jz .touch_cmd

    ; Check for "cat" command
    mov esi, input_buffer
    mov edi, cmd_cat
    call strcmp
    test eax, eax
    jz .cat_cmd

    ; Check for "rm" command
    mov esi, input_buffer
    mov edi, cmd_rm
    call strcmp
    test eax, eax
    jz .rm_cmd

    ; Check for "mkdir" command
    mov esi, input_buffer
    mov edi, cmd_mkdir
    call strcmp
    test eax, eax
    jz .mkdir_cmd

    ; Check for "write" command
    mov esi, input_buffer
    mov edi, cmd_write
    call strcmp
    test eax, eax
    jz .write_cmd

    ; Check for "setupGUI" command
    mov esi, input_buffer
    mov edi, cmd_setupgui
    call strcmp
    test eax, eax
    jz .setupgui_cmd

    ; Check for "GUI" command
    mov esi, input_buffer
    mov edi, cmd_gui
    call strcmp
    test eax, eax
    jz .gui_cmd

    ; Check for "network" command
    mov esi, input_buffer
    mov edi, cmd_network
    call strcmp
    test eax, eax
    jz .network_cmd

    ; Unknown command
    mov esi, unknown_msg
    call print_string
    call newline
    jmp .done

.help_cmd:
    mov esi, help_msg
    call print_string
    call newline
    jmp .done

.clear_cmd:
    call clear_screen
    jmp .done

.version_cmd:
    mov esi, version_msg
    call print_string
    call newline
    jmp .done

.listdisk_cmd:
    call list_disks
    jmp .done

.sysinfo_cmd:
    call show_sysinfo
    jmp .done

.ls_cmd:
    call list_files
    jmp .done

.pwd_cmd:
    call print_working_directory
    jmp .done

.date_cmd:
    call show_date
    jmp .done

.time_cmd:
    call show_time
    jmp .done

.uptime_cmd:
    call show_uptime
    jmp .done

.whoami_cmd:
    call show_whoami
    jmp .done

.echo_cmd:
    call echo_command
    jmp .done

.reboot_cmd:
    call reboot_system
    jmp .done

.shutdown_cmd:
    call shutdown_system
    jmp .done

.touch_cmd:
    call touch_file
    jmp .done

.cat_cmd:
    call cat_file
    jmp .done

.rm_cmd:
    call remove_file
    jmp .done

.mkdir_cmd:
    call make_directory
    jmp .done

.write_cmd:
    call write_file
    jmp .done

.setupgui_cmd:
    call setup_gui_mode
    jmp .done

.gui_cmd:
    call start_gui_mode
    jmp .done

.network_cmd:
    call network_command
    jmp .done

.done:
    popa
    ret

; Compare two null-terminated strings
; ESI = string1, EDI = string2
; Returns 0 in EAX if equal, non-zero if different
strcmp:
    pusha
.loop:
    mov al, [esi]
    mov bl, [edi]
    cmp al, bl
    jne .not_equal
    test al, al
    jz .equal
    inc esi
    inc edi
    jmp .loop
.equal:
    mov dword [esp + 28], 0  ; Set EAX to 0
    popa
    ret
.not_equal:
    mov dword [esp + 28], 1  ; Set EAX to 1
    popa
    ret

; List available disk drives
list_disks:
    pusha

    mov esi, listdisk_header
    call print_string
    call newline
    call newline

    ; Check floppy drives (0x00, 0x01)
    mov esi, floppy_msg
    call print_string
    call newline

    mov dl, 0x00  ; First floppy
    call check_drive
    test eax, eax
    jz .no_floppy_a
    mov esi, floppy_a_msg
    call print_string
    call newline
    jmp .check_floppy_b
.no_floppy_a:
    mov esi, floppy_a_none
    call print_string
    call newline

.check_floppy_b:
    mov dl, 0x01  ; Second floppy
    call check_drive
    test eax, eax
    jz .no_floppy_b
    mov esi, floppy_b_msg
    call print_string
    call newline
    jmp .check_hdd
.no_floppy_b:
    mov esi, floppy_b_none
    call print_string
    call newline

.check_hdd:
    call newline
    mov esi, hdd_msg
    call print_string
    call newline

    ; Check hard drives (0x80, 0x81, 0x82, 0x83)
    mov dl, 0x80  ; First hard drive
    call check_drive
    test eax, eax
    jz .no_hdd_0
    mov esi, hdd_0_msg
    call print_string
    call newline
    jmp .check_hdd_1
.no_hdd_0:
    mov esi, hdd_0_none
    call print_string
    call newline

.check_hdd_1:
    mov dl, 0x81  ; Second hard drive
    call check_drive
    test eax, eax
    jz .no_hdd_1
    mov esi, hdd_1_msg
    call print_string
    call newline
    jmp .done_disks
.no_hdd_1:
    mov esi, hdd_1_none
    call print_string
    call newline

.done_disks:
    call newline
    popa
    ret

; Check if a drive exists
; DL = drive number
; Returns 1 in EAX if drive exists, 0 if not
check_drive:
    pusha

    ; Try to get drive parameters
    mov ah, 0x08    ; Get drive parameters
    int 0x13
    jc .no_drive    ; Carry flag set = error

    ; Drive exists
    mov dword [esp + 28], 1  ; Set EAX to 1
    popa
    ret

.no_drive:
    mov dword [esp + 28], 0  ; Set EAX to 0
    popa
    ret

; Show system information (neofetch-like)
show_sysinfo:
    pusha

    ; ASCII art logo
    mov esi, sysinfo_logo1
    call print_string
    call newline
    mov esi, sysinfo_logo2
    call print_string
    call newline
    mov esi, sysinfo_logo3
    call print_string
    call newline
    mov esi, sysinfo_logo4
    call print_string
    call newline
    call newline

    ; System information
    mov esi, sysinfo_os
    call print_string
    call newline

    mov esi, sysinfo_kernel
    call print_string
    call newline

    mov esi, sysinfo_arch
    call print_string
    call newline

    mov esi, sysinfo_cpu
    call print_string
    call newline

    ; Get memory info
    call get_memory_info

    mov esi, sysinfo_uptime
    call print_string
    call newline

    call newline
    popa
    ret

; Get basic memory information
get_memory_info:
    pusha

    mov esi, sysinfo_memory
    call print_string

    ; Simple memory detection (basic)
    mov esi, memory_basic
    call print_string
    call newline

    popa
    ret

; List files (simplified)
list_files:
    pusha

    mov esi, ls_header
    call print_string
    call newline

    ; Show default files
    mov esi, ls_file1
    call print_string
    call newline
    mov esi, ls_file2
    call print_string
    call newline

    ; Show file count
    call newline
    mov esi, total_files_msg
    call print_string
    mov eax, [file_count]
    call print_number
    mov esi, files_found_suffix
    call print_string
    call newline

    popa
    ret

; Print working directory
print_working_directory:
    pusha
    mov esi, pwd_msg
    call print_string
    call newline
    popa
    ret

; Show current date
show_date:
    pusha

    ; Read year (assume 2000s)
    mov al, 0x09
    call cmos_read
    call bcd_to_bin
    movzx eax, al
    add eax, 2000     ; Add 2000 for 21st century
    push eax          ; Save full year

    ; Read month
    mov al, 0x08
    call cmos_read
    call bcd_to_bin
    movzx eax, al
    push eax          ; Save month

    ; Read day
    mov al, 0x07
    call cmos_read
    call bcd_to_bin
    movzx eax, al
    push eax          ; Save day

    ; Print "Date: "
    mov esi, date_prefix
    call print_string

    ; Print month
    pop eax
    call print_number

    mov al, '/'
    call print_char

    ; Print day
    pop eax
    call print_number

    mov al, '/'
    call print_char

    ; Print year
    pop eax
    call print_number

    call newline

    popa
    ret

; Show current time
show_time:
    pusha

    ; Read seconds
    mov al, 0x00
    call cmos_read
    call bcd_to_bin
    push eax          ; Save seconds

    ; Read minutes
    mov al, 0x02
    call cmos_read
    call bcd_to_bin
    push eax          ; Save minutes

    ; Read hours
    mov al, 0x04
    call cmos_read
    call bcd_to_bin
    push eax          ; Save hours

    ; Print "Time: "
    mov esi, time_prefix
    call print_string

    ; Print hours
    pop eax
    call print_number

    mov al, ':'
    call print_char

    ; Print minutes (with leading zero if necessary)
    pop eax  ; minutes
    push eax ; save for later
    cmp al, 10
    jl .leading_zero_min
    call print_number
    add esp, 4  ; remove saved
    jmp .print_sec

.leading_zero_min:
    mov al, '0'
    call print_char
    pop eax
    call print_number

.print_sec:
    mov al, ':'
    call print_char

    ; Print seconds
    pop eax  ; seconds
    cmp al, 10
    jl .leading_zero_sec
    call print_number
    jmp .done

.leading_zero_sec:
    mov al, '0'
    call print_char
    call print_number

.done:
    call newline

    popa
    ret

; Read from CMOS
; AL = index, returns AL = value
cmos_read:
    push dx
    out 0x70, al       ; Write index to CMOS address port
    in al, 0x71        ; Read data from CMOS data port
    pop dx
    ret

; Convert BCD to binary
; AL = BCD value, returns AL = binary
bcd_to_bin:
    push bx
    mov bl, al
    and bl, 0x0F      ; Lower digit
    shr al, 4         ; Higher digit
    mov bh, 10
    mul bh            ; AH = 0, AL = higher*10
    add al, bl        ; AL = higher*10 + lower
    pop bx
    ret

; Show system uptime
show_uptime:
    pusha
    mov esi, uptime_msg
    call print_string
    call newline
    popa
    ret

; Show current user
show_whoami:
    pusha
    mov esi, whoami_msg
    call print_string
    call newline
    popa
    ret

; Echo command (print arguments)
echo_command:
    pusha

    ; Skip "echo " part (5 characters)
    mov esi, input_buffer
    add esi, 5

    ; Check if there are arguments
    cmp byte [esi], 0
    je .no_args

    ; Print the arguments
    call print_string
    call newline
    jmp .done

.no_args:
    call newline  ; Just print empty line

.done:
    popa
    ret

; Reboot the system
reboot_system:
    pusha
    mov esi, reboot_msg
    call print_string
    call newline

    ; Wait a moment
    mov ecx, 0x1000000
.wait_loop:
    loop .wait_loop

    ; Triple fault to reboot (crude but effective)
    mov eax, 0
    mov [eax], eax  ; Write to null pointer

    popa
    ret

; Shutdown the system (halt)
shutdown_system:
    pusha
    mov esi, shutdown_msg
    call print_string
    call newline

    ; Disable interrupts and halt
    cli
    hlt

    popa
    ret

; Simple print number function
print_number:
    pusha

    ; Handle zero case
    test eax, eax
    jnz .not_zero
    mov al, '0'
    call print_char
    jmp .done

.not_zero:
    ; Convert to string (simple method)
    mov ebx, 10
    mov ecx, 0  ; Digit counter

.convert_loop:
    xor edx, edx
    div ebx
    add dl, '0'
    push edx
    inc ecx
    test eax, eax
    jnz .convert_loop

.print_loop:
    pop eax
    call print_char
    loop .print_loop

.done:
    popa
    ret

; Simplified filesystem commands (stubs)
touch_file:
    pusha
    mov esi, file_created_msg
    call print_string
    call newline
    popa
    ret

cat_file:
    pusha
    mov esi, cat_demo_msg
    call print_string
    call newline
    popa
    ret

write_file:
    pusha
    mov esi, file_written_msg
    call print_string
    call newline
    popa
    ret

; Remove file command (stub)
remove_file:
    pusha
    mov esi, rm_not_implemented
    call print_string
    call newline
    popa
    ret

; Make directory command (stub)
make_directory:
    pusha
    mov esi, mkdir_not_implemented
    call print_string
    call newline
    popa
    ret

; String data
welcome_msg db 'FemboyOS - V0.0.5', 0
prompt_msg db 'host@femboyOS> ', 0
unknown_msg db 'Unknown command. Type "help" for available commands.', 0
help_msg db 'Available commands:', 10, '  help, clear, version, sysinfo, listdisk', 10, '  ls/dir, pwd, date, time, uptime, whoami', 10, '  echo [text], reboot, shutdown', 10, '  touch [file], cat [file], write [file] [content]', 10, '  network [status|dhcp|devices] - Network management', 10, '  GUI - Start graphical interface', 10, '  setupGUI - Configure GUI mode', 0
version_msg db 'FemboyOS version 1.0 - 32-bit operating system', 0
cmd_help db 'help', 0
cmd_clear db 'clear', 0
cmd_version db 'version', 0
cmd_listdisk db 'listdisk', 0
cmd_sysinfo db 'sysinfo', 0
cmd_ls db 'ls', 0
cmd_dir db 'dir', 0
cmd_pwd db 'pwd', 0
cmd_date db 'date', 0
cmd_time db 'time', 0
cmd_uptime db 'uptime', 0
cmd_whoami db 'whoami', 0
cmd_echo db 'echo', 0
cmd_reboot db 'reboot', 0
cmd_shutdown db 'shutdown', 0
cmd_touch db 'touch', 0
cmd_cat db 'cat', 0
cmd_rm db 'rm', 0
cmd_mkdir db 'mkdir', 0
cmd_write db 'write', 0
cmd_setupgui db 'setupGUI', 0
cmd_gui db 'GUI', 0
cmd_network db 'network', 0

; Disk listing strings
listdisk_header db 'Available Storage Devices:', 0
floppy_msg db 'Floppy Drives:', 0
floppy_a_msg db '  A: - 3.5" Floppy Drive (1.44MB)', 0
floppy_a_none db '  A: - Not detected', 0
floppy_b_msg db '  B: - 3.5" Floppy Drive (1.44MB)', 0
floppy_b_none db '  B: - Not detected', 0
hdd_msg db 'Hard Drives:', 0
hdd_0_msg db '  C: - Primary Hard Drive', 0
hdd_0_none db '  C: - Not detected', 0
hdd_1_msg db '  D: - Secondary Hard Drive', 0
hdd_1_none db '  D: - Not detected', 0

; Sysinfo strings
sysinfo_logo1 db '    ___               _                ', 0
sysinfo_logo2 db '   / __\___ _ __ ___ | |__   ___  _   _ ', 0
sysinfo_logo3 db '  / _\/ _ \ "_ ` _ \| "_ \ / _ \| | | |', 0
sysinfo_logo4 db ' / / |  __/ | | | | | |_) | (_) | |_| |', 0
sysinfo_os db 'OS: FemboyOS V0.0.1', 0
sysinfo_kernel db 'Kernel: FemboyKernel V0.0.5 - 32-bit monolithic kernel', 0
sysinfo_arch db 'Architecture: x86 (i386)', 0
sysinfo_cpu db 'CPU: Intel/AMD x86 compatible', 0
sysinfo_memory db 'Memory: ', 0
memory_basic db '128MB (estimated)', 0
sysinfo_uptime db 'Uptime: Just booted!', 0

; New command strings
ls_header db 'Directory listing:', 0
ls_file1 db '  welcome.txt (35 bytes)', 0
ls_file2 db '  readme.txt (42 bytes)', 0
total_files_msg db 'Total: ', 0
files_found_suffix db ' files', 0
pwd_msg db '/root', 0
date_msg db 'Date: 2025-01-22 (simulated)', 0
date_prefix db 'Date: ', 0
time_msg db 'Time: 12:00:00 UTC (simulated)', 0
time_prefix db 'Time: ', 0
uptime_msg db 'System uptime: 0 days, 0 hours, 0 minutes', 0
whoami_msg db 'root', 0
reboot_msg db 'Rebooting system...', 0
shutdown_msg db 'System halted. Safe to power off.', 0

; Simplified filesystem messages
file_created_msg db 'File created (simulated).', 0
file_written_msg db 'File written (simulated).', 0
cat_demo_msg db 'This is demo file content. Real filesystem coming soon!', 0
rm_not_implemented db 'rm command not yet implemented.', 0
mkdir_not_implemented db 'mkdir command not yet implemented.', 0

; GUI setup messages
gui_setup_msg db 'Setting up GUI mode...', 0
gui_setup_complete db 'GUI mode configured. Starting GUI...', 0
gui_reboot_msg db 'Starting FemboyOS Desktop Environment...', 0
gui_starting_msg db 'Loading FemboyOS Desktop Environment...', 0
gui_exit_message db 'Exited GUI mode. Welcome back to CLI!', 0
simple_gui_title db '=== FemboyOS Desktop Environment ===', 0
simple_gui_msg1 db 'Welcome to the FemboyOS GUI!', 0
simple_gui_msg2 db 'This is a simple text-based desktop.', 0
simple_gui_exit db 'Returning to CLI in 3 seconds...', 0

; Setup GUI mode function
setup_gui_mode:
    pusha

    ; Print setup message
    mov esi, gui_setup_msg
    call print_string
    call newline

    ; Set GUI mode flag
    mov dword [gui_mode_flag], 1

    ; Print completion message
    mov esi, gui_setup_complete
    call print_string
    call newline

    ; Print reboot message
    mov esi, gui_reboot_msg
    call print_string
    call newline
    call newline

    ; Wait a moment
    mov ecx, 50000000
.wait_loop:
    dec ecx
    jnz .wait_loop

    ; Initialize C compositor
    ; call compositor_init

    ; After GUI exits, clear screen and return to CLI
    call clear_screen
    mov esi, gui_exit_message
    call print_string
    call newline

    popa
    ret

; Start GUI mode directly (call C compositor)
start_gui_mode:
    pusha

    ; Print starting message
    mov esi, gui_starting_msg
    call print_string
    call newline

    ; Simple test: print before C call
    mov esi, before_c_msg
    call print_string
    call newline

    ; Initialize C compositor
    call compositor_init

    ; Simple demo: call render a few times
    ; call compositor_render

    ; Simple delay (shorter for testing)
    mov ecx, 20000000
.wait_loop:
    dec ecx
    jnz .wait_loop

    ; Return to CLI
    call clear_screen
    mov esi, gui_exit_message
    call print_string
    call newline

    popa
    ret

before_c_msg db 'Before C call...', 0



; Variables
cursor_x dd 0
cursor_y dd 0
input_buffer times 256 db 0
input_pos dd 0
file_count dd 0
gui_mode_flag dd 0  ; 0 = CLI mode, 1 = GUI mode
shift_pressed db 0  ; 0 = not pressed, 1 = pressed

; C compositor functions (declared extern)
; extern compositor_init
; extern compositor_render
; extern compositor_handle_input

; Temporary implementation: simple text-based compositor stub
compositor_demo:
    pusha

    ; Clear screen
    call clear_screen

    ; Print demo message
    mov esi, compositor_msg
    call print_string
    call newline

    ; Simple delay
    mov ecx, 100000000
.delay_loop:
    dec ecx
    jnz .delay_loop

    popa
    ret

compositor_msg db 'C-based Compositor: Under Construction...', 0
