# REQUIRES: v850

## Test basic V850 relocations

# RUN: llvm-mc -filetype=obj -triple=v850-unknown-elf -mcpu=v850e2m %s -o %t.o
# RUN: ld.lld %t.o -o %t
# RUN: llvm-objdump -d --triple=v850-unknown-elf %t | FileCheck %s

# CHECK: <_start>:
# CHECK: jarl

    .text
    .globl _start
    .type _start, @function
_start:
    # R_V850_22_PCREL - 22-bit PC-relative for JARL
    jarl target, r31

    # R_V850_9_PCREL - 9-bit PC-relative for conditional branch
    cmp r0, r6
    be .Lskip
    nop
.Lskip:

    halt
    .size _start, . - _start

    .globl target
    .type target, @function
target:
    jmp [r31]
    .size target, . - target

    .data
    .globl data_sym
data_sym:
    # R_V850_32 - 32-bit absolute
    .word target
    # R_V850_16 - 16-bit value
    .short 0x1234
    # R_V850_8 - 8-bit value
    .byte 0x42
