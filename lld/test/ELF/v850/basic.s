# REQUIRES: v850

# RUN: llvm-mc -filetype=obj -triple=v850-unknown-elf -mcpu=v850e2m %s -o %t.o
# RUN: ld.lld %t.o -o %t
# RUN: llvm-readelf -h %t | FileCheck %s --check-prefix=HEADER
# RUN: llvm-readelf -s %t | FileCheck %s --check-prefix=SYMBOLS

# HEADER: Machine: NEC v850

# SYMBOLS: foo
# SYMBOLS: main

    .text
    .globl foo
    .type foo, @function
foo:
    add 1, r6
    jmp [r31]
    .size foo, . - foo

    .globl main
    .type main, @function
main:
    prepare 2048, 0
    mov 42, r6
    jarl foo, r31
    mov r10, r6
    dispose 0, 2048, [r31]
    .size main, . - main

    .globl _start
    .type _start, @function
_start:
    jarl main, r31
    halt
    .size _start, . - _start
