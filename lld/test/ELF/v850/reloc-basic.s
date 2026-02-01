# REQUIRES: v850

## Test basic V850 linking and relocations

# RUN: llvm-mc -filetype=obj -triple=v850-unknown-elf -mcpu=v850e2m %s -o %t.o
# RUN: ld.lld %t.o -o %t
# RUN: llvm-readelf -h %t | FileCheck %s --check-prefix=HEADER
# RUN: llvm-readelf -S %t | FileCheck %s --check-prefix=SECTIONS
# RUN: llvm-readelf -s %t | FileCheck %s --check-prefix=SYMBOLS

# HEADER: Machine: NEC v850

# SECTIONS: .text
# SECTIONS: .data

# SYMBOLS: _start
# SYMBOLS: target
# SYMBOLS: data_sym

    .text
    .globl _start
    .type _start, @function
_start:
    # 32-bit PC-relative branch to target (JARL32)
    jarl target, r31

    # 9-bit PC-relative conditional branch
    cmp r0, r6
    bnz .Lskip
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
    # 32-bit absolute data
    .long target
    # 16-bit value
    .short 0x1234
    # 8-bit value
    .byte 0x42
