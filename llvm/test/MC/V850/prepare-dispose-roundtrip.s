; RUN: llvm-mc -triple=v850 -mcpu=v850e2m -filetype=obj %s -o %t.o
; RUN: llvm-objdump -d %t.o | FileCheck %s

; Assembler roundtrip test for PREPARE/DISPOSE instructions.
; Verifies that assembled machine code disassembles back to the
; original instruction, especially for the imm5{4}=0 case that
; previously conflicted with MOVHI encoding.

; CHECK-LABEL: <test_prepare_dispose>:
; CHECK: prepare	2, 0
; CHECK: prepare	2, 4
; CHECK: prepare	2049, 0
; CHECK: prepare	4095, 8
; CHECK: dispose	0, 2, [r31]
; CHECK: dispose	4, 2049, [r31]
.text
.globl test_prepare_dispose
test_prepare_dispose:
    prepare 2, 0
    prepare 2, 4
    prepare 2049, 0
    prepare 4095, 8
    dispose 0, 2, [r31]
    dispose 4, 2049, [r31]
