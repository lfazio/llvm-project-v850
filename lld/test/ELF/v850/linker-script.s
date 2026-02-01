# REQUIRES: v850

## Test V850 linker script with sections and symbols

# RUN: llvm-mc -filetype=obj -triple=v850-unknown-elf -mcpu=v850e2m %s -o %t.o
# RUN: ld.lld -T %S/Inputs/v850.ld %t.o -o %t.elf
# RUN: llvm-readelf -h %t.elf | FileCheck %s --check-prefix=HEADER
# RUN: llvm-readelf -S %t.elf | FileCheck %s --check-prefix=SECTIONS
# RUN: llvm-readelf -s %t.elf | FileCheck %s --check-prefix=SYMBOLS

# HEADER: Machine: NEC v850

## Verify expected sections exist
# SECTIONS: .vectors
# SECTIONS: .text
# SECTIONS: .bss

## Verify linker-defined symbols exist (using DAG for unordered match)
# SYMBOLS-DAG: __stack_end
# SYMBOLS-DAG: __bss_start
# SYMBOLS-DAG: __bss_end
# SYMBOLS-DAG: __gp
# SYMBOLS-DAG: __ep

    .section .vectors, "ax"
    .globl _reset
_reset:
    jr      _start

    .section .text
    .globl _start
    .type _start, @function
_start:
    # Initialize stack - use movhi/movea with symbol directly
    movhi   __stack_end, r0, sp
    movea   __stack_end, sp, sp

    # Initialize GP
    movhi   __gp, r0, gp
    movea   __gp, gp, gp

    # Initialize EP
    movhi   __ep, r0, ep
    movea   __ep, ep, ep

    # Call main
    jarl    main, lp

    # Exit
    halt
    .size _start, . - _start

    .globl main
    .type main, @function
main:
    mov     42, r10
    jmp     [lp]
    .size main, . - main

    .section .bss, "aw", @nobits
    .globl bss_var
bss_var:
    .space 4

    .section .sdata, "aw"
    .globl small_data
small_data:
    .long 0x12345678
