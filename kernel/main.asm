; FemboyKernel Main Entry Point
; 64-bit kernel initialization and main loop

[BITS 64]

global _start

section .text

_start:
    ; Kernel entry point - ultra simple test

    ; Just write one character to prove we reached the kernel
    mov word [0xB8000], 0x0F4B  ; 'K' in white on red

    ; Infinite loop
    jmp $

