; RUN: llc -mtriple=v850 -mcpu=v850e2m < %s | FileCheck %s
; RUN: llc -mtriple=v850 -mcpu=v850e1 < %s | FileCheck %s

;===----------------------------------------------------------------------===;
; Test PREPARE/DISPOSE CFI (Call Frame Information) for stack unwinding
;
; PREPARE instruction atomically saves multiple callee-saved registers:
;   - Saves registers in order: LP (r31), EP (r30), r29, r28, ..., r20
;   - Only registers specified in list12 are saved
;   - LP is saved first (at highest address, CFA-4)
;   - Each subsequent register is at CFA-8, CFA-12, etc.
;
; CFI directives must accurately describe where each register is saved
; so that debuggers and unwinders can correctly restore the call stack.
;===----------------------------------------------------------------------===;

;===----------------------------------------------------------------------===;
; Test 1: PREPARE with LP only (bit 1 = 2)
;
; list12 = 2 (0x002) -> only LP saved
; Stack layout after PREPARE:
;   CFA-4: LP (r31)
;   SP = CFA-4
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_prepare_lp_only:
; CHECK:       .cfi_startproc
; CHECK:       prepare 2, 0
; CHECK-NEXT:  .cfi_def_cfa_offset 4
; CHECK-NEXT:  .cfi_offset r31, -4
; CHECK:       dispose 0, 2
define i32 @test_prepare_lp_only(i32 %a) {
entry:
  %result = call i32 @external(i32 %a)
  ret i32 %result
}

;===----------------------------------------------------------------------===;
; Test 2: PREPARE with LP and r20 (bits 1,7 = 130)
;
; list12 = 130 (0x082) -> LP and r20 saved
; Stack layout after PREPARE:
;   CFA-4: LP (r31)
;   CFA-8: r20
;   SP = CFA-8
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_prepare_lp_r20:
; CHECK:       .cfi_startproc
; CHECK:       prepare 130, 0
; CHECK-NEXT:  .cfi_def_cfa_offset 8
; CHECK-NEXT:  .cfi_offset r31, -4
; CHECK-NEXT:  .cfi_offset r20, -8
; CHECK:       dispose 0, 130
define i32 @test_prepare_lp_r20(i32 %a) {
entry:
  %local = alloca i32
  store i32 %a, ptr %local
  %result = call i32 @external(i32 %a)
  %v = load i32, ptr %local
  %sum = add i32 %result, %v
  ret i32 %sum
}

;===----------------------------------------------------------------------===;
; Test 3: PREPARE with LP, r21, and r20 (bits 1,6,7 = 194)
;
; list12 = 194 (0x0C2) -> LP, r21, r20 saved
; Stack layout after PREPARE (registers in push order):
;   CFA-4:  LP (r31)
;   CFA-8:  r21
;   CFA-12: r20
;   SP = CFA-12
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_prepare_lp_r21_r20:
; CHECK:       .cfi_startproc
; CHECK:       prepare 194, 0
; CHECK-NEXT:  .cfi_def_cfa_offset 12
; CHECK-NEXT:  .cfi_offset r31, -4
; CHECK-NEXT:  .cfi_offset r21, -8
; CHECK-NEXT:  .cfi_offset r20, -12
; CHECK:       dispose 0, 194
define i32 @test_prepare_lp_r21_r20(i32 %a, i32 %b) {
entry:
  %local1 = alloca i32
  %local2 = alloca i32
  store i32 %a, ptr %local1
  store i32 %b, ptr %local2
  %result = call i32 @external(i32 %a)
  %v1 = load i32, ptr %local1
  %v2 = load i32, ptr %local2
  %sum = add i32 %result, %v1
  %sum2 = add i32 %sum, %v2
  ret i32 %sum2
}

;===----------------------------------------------------------------------===;
; Test 4: PREPARE with multiple registers including high-numbered ones
;
; When more callee-saved registers are needed, they appear in PREPARE order:
; LP (r31), EP (r30), r29, r28, r27, r26, r25, r24, r23, r22, r21, r20
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_prepare_many_regs:
; CHECK:       .cfi_startproc
; CHECK:       prepare {{[0-9]+}}, 0
; CHECK-NEXT:  .cfi_def_cfa_offset
; CHECK:       .cfi_offset r31, -4
; Multiple cfi_offset directives should follow in PREPARE order
; CHECK:       .cfi_offset r{{[0-9]+}}
; CHECK:       dispose
define i32 @test_prepare_many_regs(i32 %a, i32 %b, i32 %c, i32 %d) {
entry:
  ; Use multiple callee-saved registers by having many live values across calls
  %v1 = add i32 %a, %b
  %v2 = add i32 %c, %d
  %v3 = add i32 %v1, %v2
  %call1 = call i32 @external(i32 %v1)
  %call2 = call i32 @external(i32 %v2)
  %call3 = call i32 @external(i32 %v3)
  %result = add i32 %call1, %call2
  %final = add i32 %result, %call3
  ret i32 %final
}

;===----------------------------------------------------------------------===;
; Test 5: PREPARE followed by additional stack allocation
;
; After PREPARE saves registers, emitPrologue may allocate more stack
; for local variables. CFI should reflect the total CFA offset.
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_prepare_with_locals:
; CHECK:       .cfi_startproc
; CHECK:       prepare {{[0-9]+}}, 0
; CHECK-NEXT:  .cfi_def_cfa_offset [[CSR_SIZE:[0-9]+]]
; CHECK:       .cfi_offset r31, -4
; After additional stack allocation (uses addi for larger offsets):
; CHECK:       addi -{{[0-9]+}}, r3, r3
; CHECK-NEXT:  .cfi_def_cfa_offset
; CHECK:       dispose
define i32 @test_prepare_with_locals(i32 %a) {
entry:
  %arr = alloca [20 x i32], align 4
  %ptr = getelementptr [20 x i32], ptr %arr, i32 0, i32 0
  store i32 %a, ptr %ptr
  %result = call i32 @external(i32 %a)
  %v = load i32, ptr %ptr
  %sum = add i32 %result, %v
  ret i32 %sum
}

;===----------------------------------------------------------------------===;
; Test 6: Verify epilogue uses DISPOSE (no CFI needed in epilogue)
;
; LLVM convention: CFI state from prologue is used for unwinding.
; No cfi_restore or cfi_def_cfa directives in epilogue.
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_dispose_epilogue:
; CHECK:       .cfi_startproc
; CHECK:       prepare
; CHECK:       .cfi_def_cfa_offset
; CHECK:       .cfi_offset
; Epilogue should have DISPOSE but no CFI directives
; CHECK:       dispose {{[0-9]+}}, {{[0-9]+}}
; CHECK-NOT:   .cfi_restore
; CHECK-NOT:   .cfi_def_cfa
; CHECK:       .cfi_endproc
define i32 @test_dispose_epilogue(i32 %a) {
entry:
  %result = call i32 @external(i32 %a)
  ret i32 %result
}

;===----------------------------------------------------------------------===;
; Test 7: DISPOSE with return (DISPOSEr variant)
;
; DISPOSEr combines register restore and return in one instruction.
;===----------------------------------------------------------------------===;

; CHECK-LABEL: test_disposer:
; CHECK:       .cfi_startproc
; CHECK:       prepare 2, 0
; CHECK:       .cfi_def_cfa_offset 4
; CHECK:       .cfi_offset r31, -4
; DISPOSEr should be used when immediately followed by return
; CHECK:       dispose 0, 2, [r31]
; CHECK:       .cfi_endproc
define i32 @test_disposer(i32 %a) {
entry:
  %result = call i32 @external(i32 %a)
  ret i32 %result
}

declare i32 @external(i32)
