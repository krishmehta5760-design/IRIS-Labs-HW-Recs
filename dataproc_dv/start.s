# Complete this file by writing the necessary startup code to properly initialize the system before transferring control to main. Do try to write it by yourself rather than copying it from uart_dv
# RISC-V startup code for data_proc integration
# Initializes the system before jumping to main()

.section .text
.globl _start

_start:
    # Initialize stack pointer to top of RAM
    la sp, _heap_start
    addi sp, sp, 1024       # Stack grows downward from heap_start + 1024
    
    # Copy .data section from FLASH to RAM
    la a0, _sidata          # Source address in FLASH
    la a1, _sdata           # Destination address in RAM
    la a2, _edata           # End of .data section
    
copy_data_loop:
    bge a1, a2, zero_bss    # If we've copied everything, jump to zero_bss
    lw  t0, 0(a0)           # Load word from FLASH
    sw  t0, 0(a1)           # Store word to RAM
    addi a0, a0, 4          # Increment source pointer
    addi a1, a1, 4          # Increment destination pointer
    j copy_data_loop        # Repeat

zero_bss:
    # Zero out .bss section (uninitialized data)
    la a0, _sbss            # Start of .bss
    la a1, _ebss            # End of .bss
    
zero_bss_loop:
    bge a0, a1, call_main   # If we've zeroed everything, jump to main
    sw  zero, 0(a0)         # Store zero
    addi a0, a0, 4          # Increment pointer
    j zero_bss_loop         # Repeat

call_main:
    # Call main() function
    call main               # Jump to C main function
    # Note: main should never return, but if it does...

hang:
    # Infinite loop (should never reach here)
    j hang
