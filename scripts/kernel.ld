/* Linker script for FemboyKernel */

ENTRY(_start)

SECTIONS
{
    /* Kernel starts at 0x10000 (64KB) */
    . = 0x10000;
    
    /* Text section (code) */
    .text ALIGN(4K) : {
        *(.text)
        *(.text.*)
    }
    
    /* Read-only data */
    .rodata ALIGN(4K) : {
        *(.rodata)
        *(.rodata.*)
    }
    
    /* Initialized data */
    .data ALIGN(4K) : {
        *(.data)
        *(.data.*)
    }
    
    /* Uninitialized data */
    .bss ALIGN(4K) : {
        *(COMMON)
        *(.bss)
        *(.bss.*)
    }
    
    /* Stack section */
    .stack ALIGN(4K) : {
        . += 0x4000; /* 16KB stack */
    }
    
    /* End of kernel */
    kernel_end = .;
}
